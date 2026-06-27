#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Fairmont Manufacturing — Single User Remediation Script

.DESCRIPTION
    Remediates a single Fairmont Manufacturing user account.

    Actions available:
        FixGroup      — Add user to a specified AD group
                        If group is AAD-Sync-Users this fixes Entra sync scope
        RemoveGroup   — Remove user from a specified AD group
        DisableUser   — Disable the user account (keeps it in AD and Entra sync)
        EnableUser    — Re-enable a previously disabled account
        RemoveUser    — Permanently delete from AD
                        Removes from AAD-Sync-Users FIRST for clean Entra deprovision
        ResetPassword — Reset user password
        UnlockAccount — Unlock a locked user account

    IMPORTANT: AAD-Sync-Users controls Entra Connect sync scope.
    RemoveUser removes the user from AAD-Sync-Users before AD deletion
    to ensure Entra ID cleanly deprovisions the account on next sync.

    If a user was provisioned but NOT added to AAD-Sync-Users:
        Use: -Action FixGroup -Group AAD-Sync-Users

.NOTES
    Author:      Edward E. Spence
    Environment: IAMPAM.LAB
    Sync Group:  AAD-Sync-Users (controls Entra Connect scope)
    Run From:    MGMT01 as adm-t0-administrator
    Repo:        fairmont-manufacturing-iam-operations

.PARAMETER SAM
    SamAccountName. Example: fm.kira.vanthorpe

.PARAMETER Action
    FixGroup | RemoveGroup | DisableUser | EnableUser | RemoveUser | ResetPassword | UnlockAccount

.PARAMETER Group
    Required for FixGroup and RemoveGroup.
    Use AAD-Sync-Users to fix Entra sync scope for a user.

.PARAMETER TicketNumber
    Ticket number for audit trail.

.PARAMETER LogPath
    Optional. Default: C:\Logs

.EXAMPLE
    # Fix Entra sync scope (user not syncing to Entra)
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action FixGroup -Group AAD-Sync-Users -TicketNumber REQ0042001

.EXAMPLE
    # Fix department group assignment
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action FixGroup -Group ENG-Users -TicketNumber REQ0042001

.EXAMPLE
    # Disable a user
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action DisableUser -TicketNumber INC0042001

.EXAMPLE
    # Remove a user permanently
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action RemoveUser -TicketNumber INC0042001

.EXAMPLE
    # Reset password
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action ResetPassword -TicketNumber INC0042001

.EXAMPLE
    # Unlock account
    .\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action UnlockAccount -TicketNumber INC0042001
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [string]$SAM,

    [Parameter(Mandatory = $true)]
    [ValidateSet("FixGroup","RemoveGroup","DisableUser","EnableUser","RemoveUser","ResetPassword","UnlockAccount")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Group,

    [Parameter(Mandatory = $true)]
    [string]$TicketNumber,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs"
)

# ============================================================
# CONFIGURATION
# ============================================================

$SyncGroup = "AAD-Sync-Users"

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
}

$LogFile   = "$LogPath\FM-Remediate-$TicketNumber-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Fairmont Manufacturing — Single User Remediation" -ForegroundColor Yellow
Write-Host " Ticket  : $TicketNumber" -ForegroundColor Yellow
Write-Host " User    : $SAM" -ForegroundColor Yellow
Write-Host " Action  : $Action" -ForegroundColor Yellow
if ($Group) { Write-Host " Group   : $Group" -ForegroundColor Yellow }
Write-Host " Started : $StartTime" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# PARAMETER VALIDATION
# ============================================================

if ($Action -in @("FixGroup","RemoveGroup") -and -not $Group) {
    Write-Host "❌ Action $Action requires -Group parameter." -ForegroundColor Red
    Write-Host "   To fix Entra sync: -Group AAD-Sync-Users" -ForegroundColor Yellow
    exit 1
}

# ============================================================
# VERIFY USER EXISTS
# ============================================================

Write-Host "--- Verifying User ---" -ForegroundColor Yellow
Write-Host ""

$adUser = Get-ADUser -Filter {SamAccountName -eq $SAM} -Properties * -ErrorAction SilentlyContinue

if (-not $adUser) {
    Write-Host "❌ User not found in AD: $SAM" -ForegroundColor Red
    Write-Host "   Use fm-single-user-provision.ps1 to create this user first." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ User found: $SAM" -ForegroundColor Green
Write-Host "   Display Name : $($adUser.Name)" -ForegroundColor White
Write-Host "   UPN          : $($adUser.UserPrincipalName)" -ForegroundColor White
Write-Host "   Enabled      : $($adUser.Enabled)" -ForegroundColor White
Write-Host "   Locked Out   : $($adUser.LockedOut)" -ForegroundColor White

# Check sync group membership
$inSyncGroup = Get-ADGroupMember -Identity $SyncGroup -ErrorAction SilentlyContinue |
               Where-Object { $_.SamAccountName -eq $SAM }
Write-Host "   In $SyncGroup : $($null -ne $inSyncGroup)" -ForegroundColor $(if ($inSyncGroup) { "Green" } else { "Red" })
Write-Host ""

# ============================================================
# RESULT OBJECT
# ============================================================

$result = [PSCustomObject]@{
    Ticket    = $TicketNumber
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    SAM       = $SAM
    Action    = $Action
    Group     = $Group
    Success   = $false
    Error     = ""
    Notes     = ""
}

# ============================================================
# REMEDIATION ACTIONS
# ============================================================

switch ($Action) {

    "FixGroup" {
        Write-Host "--- Action: Fix Group Assignment → $Group ---" -ForegroundColor Cyan
        Write-Host ""

        # Validate group exists
        try {
            Get-ADGroup -Identity $Group -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "❌ Group not found: $Group. Aborting." -ForegroundColor Red
            exit 1
        }

        try {
            $isMember = Get-ADGroupMember -Identity $Group -ErrorAction Stop |
                        Where-Object { $_.SamAccountName -eq $SAM }

            if ($isMember) {
                Write-Host "  ⚠️  Already member of $Group — no action needed" -ForegroundColor Yellow
                $result.Success = $true
                $result.Notes   = "Already a member"
            }
            else {
                Add-ADGroupMember -Identity $Group -Members $SAM -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Added to $Group" -ForegroundColor Green

                if ($Group -eq $SyncGroup) {
                    Write-Host ""
                    Write-Host "  ✅ Entra sync scope restored for $SAM" -ForegroundColor Green
                    Write-Host "  Triggering delta sync..." -ForegroundColor Cyan
                    try {
                        Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
                            Import-Module ADSync
                            Start-ADSyncSyncCycle -PolicyType Delta
                        } -ErrorAction Stop
                        Write-Host "  ✅ Delta sync triggered" -ForegroundColor Green
                        Write-Host "  ⚠️  Wait 2-5 minutes then verify $SAM appears in Entra ID" -ForegroundColor Yellow
                        $result.Notes = "Entra sync triggered after adding to $SyncGroup"
                    }
                    catch {
                        Write-Host "  ❌ Sync trigger failed — trigger manually on ID-SYNC01" -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            $result.Error = "Group fix failed: $_"
            Write-Host "  ❌ Failed: $_" -ForegroundColor Red
        }
    }

    "RemoveGroup" {
        Write-Host "--- Action: Remove from Group → $Group ---" -ForegroundColor Cyan
        Write-Host ""

        if ($Group -eq $SyncGroup) {
            Write-Host "  ⚠️  Removing from $SyncGroup will stop this user from syncing to Entra ID." -ForegroundColor Yellow
            Write-Host "      This does NOT delete the user from Entra — it stops future syncs only." -ForegroundColor Yellow
            Write-Host ""
        }

        try {
            $isMember = Get-ADGroupMember -Identity $Group -ErrorAction Stop |
                        Where-Object { $_.SamAccountName -eq $SAM }

            if (-not $isMember) {
                Write-Host "  ⚠️  Not a member of $Group — no action needed" -ForegroundColor Yellow
                $result.Success = $true
                $result.Notes   = "Not a member"
            }
            else {
                Remove-ADGroupMember -Identity $Group -Members $SAM -Confirm:$false -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Removed from $Group" -ForegroundColor Green
                if ($Group -eq $SyncGroup) {
                    Write-Host "  ⚠️  Delinea: Verify access is revoked on next group sync" -ForegroundColor Yellow
                }
            }
        }
        catch {
            $result.Error = "Remove group failed: $_"
            Write-Host "  ❌ Failed: $_" -ForegroundColor Red
        }
    }

    "DisableUser" {
        Write-Host "--- Action: Disable User Account ---" -ForegroundColor Cyan
        Write-Host ""

        if (-not $adUser.Enabled) {
            Write-Host "  ⚠️  Account already disabled" -ForegroundColor Yellow
            $result.Success = $true
            $result.Notes   = "Already disabled"
        }
        else {
            try {
                Disable-ADAccount -Identity $SAM -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Account disabled: $SAM" -ForegroundColor Green
                Write-Host "  ⚠️  User cannot authenticate but account remains in AD and Entra" -ForegroundColor Yellow
                Write-Host "  ⚠️  Entra will reflect disabled state after next sync" -ForegroundColor Yellow
            }
            catch {
                $result.Error = "Disable failed: $_"
                Write-Host "  ❌ Failed: $_" -ForegroundColor Red
            }
        }
    }

    "EnableUser" {
        Write-Host "--- Action: Enable User Account ---" -ForegroundColor Cyan
        Write-Host ""

        if ($adUser.Enabled) {
            Write-Host "  ⚠️  Account already enabled" -ForegroundColor Yellow
            $result.Success = $true
            $result.Notes   = "Already enabled"
        }
        else {
            try {
                Enable-ADAccount -Identity $SAM -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Account enabled: $SAM" -ForegroundColor Green
            }
            catch {
                $result.Error = "Enable failed: $_"
                Write-Host "  ❌ Failed: $_" -ForegroundColor Red
            }
        }
    }

    "RemoveUser" {
        Write-Host "--- Action: Remove User Permanently ---" -ForegroundColor Red
        Write-Host ""
        Write-Host "  ⚠️  This permanently deletes $SAM from Active Directory." -ForegroundColor Red
        Write-Host "      AAD-Sync-Users removal happens FIRST for clean Entra deprovision." -ForegroundColor Red
        Write-Host ""
        $confirm = Read-Host "  Type CONFIRM to proceed"

        if ($confirm -ne "CONFIRM") {
            Write-Host "  ⚠️  Aborted. No changes made." -ForegroundColor Yellow
            $result.Notes = "Aborted by operator"
        }
        else {
            # Step 1 — Remove from AAD-Sync-Users FIRST
            Write-Host ""
            Write-Host "  Step 1: Removing from $SyncGroup..." -ForegroundColor Cyan
            try {
                $inSync = Get-ADGroupMember -Identity $SyncGroup -ErrorAction Stop |
                          Where-Object { $_.SamAccountName -eq $SAM }
                if ($inSync) {
                    Remove-ADGroupMember -Identity $SyncGroup -Members $SAM -Confirm:$false -ErrorAction Stop
                    Write-Host "  ✅ Removed from $SyncGroup" -ForegroundColor Green
                }
                else {
                    Write-Host "  ⚠️  Not in $SyncGroup — skipping" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "  ❌ Failed to remove from $SyncGroup — $_" -ForegroundColor Red
            }

            # Step 2 — Trigger sync to deprovision from Entra
            Write-Host ""
            Write-Host "  Step 2: Triggering Entra sync (deprovision)..." -ForegroundColor Cyan
            try {
                Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
                    Import-Module ADSync
                    Start-ADSyncSyncCycle -PolicyType Delta
                } -ErrorAction Stop
                Write-Host "  ✅ Delta sync triggered" -ForegroundColor Green
                Write-Host "  Waiting 15 seconds before AD deletion..." -ForegroundColor Yellow
                Start-Sleep -Seconds 15
            }
            catch {
                Write-Host "  ❌ Sync trigger failed — proceeding with AD deletion" -ForegroundColor Red
            }

            # Step 3 — Remove from AD
            Write-Host ""
            Write-Host "  Step 3: Removing from Active Directory..." -ForegroundColor Cyan
            try {
                Remove-ADUser -Identity $SAM -Confirm:$false -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ User removed from AD: $SAM" -ForegroundColor Green
                Write-Host ""
                Write-Host "  ⚠️  Vault: Secrets are department-level. No deletion required." -ForegroundColor Yellow
                Write-Host "  ⚠️  Delinea: Verify $SAM no longer appears in folder access lists." -ForegroundColor Yellow

                # Final sync
                Write-Host ""
                Write-Host "  Step 4: Final Entra sync..." -ForegroundColor Cyan
                try {
                    Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
                        Import-Module ADSync
                        Start-ADSyncSyncCycle -PolicyType Delta
                    } -ErrorAction Stop
                    Write-Host "  ✅ Final sync triggered" -ForegroundColor Green
                    Write-Host "  ⚠️  Verify $SAM no longer in Entra:" -ForegroundColor Yellow
                    Write-Host "     https://entra.microsoft.com → Users → Search: $SAM" -ForegroundColor Cyan
                    $result.Notes = "AAD-Sync-Users removed, AD deleted, Entra syncs triggered"
                }
                catch {
                    Write-Host "  ❌ Final sync failed — trigger manually on ID-SYNC01" -ForegroundColor Red
                }
            }
            catch {
                $result.Error = "AD removal failed: $_"
                Write-Host "  ❌ Failed to remove from AD: $_" -ForegroundColor Red
            }
        }
    }

    "ResetPassword" {
        Write-Host "--- Action: Reset Password ---" -ForegroundColor Cyan
        Write-Host ""

        $NewPassword = ConvertTo-SecureString "Welcome@Fairmount2026!" -AsPlainText -Force

        try {
            Set-ADAccountPassword -Identity $SAM -NewPassword $NewPassword -Reset -ErrorAction Stop
            Set-ADUser -Identity $SAM -ChangePasswordAtLogon $true -ErrorAction Stop
            $result.Success = $true
            Write-Host "  ✅ Password reset for: $SAM" -ForegroundColor Green
            Write-Host "     Temp password: Welcome@Fairmount2026!" -ForegroundColor White
            Write-Host "     Must change at next logon" -ForegroundColor White
        }
        catch {
            $result.Error = "Password reset failed: $_"
            Write-Host "  ❌ Failed: $_" -ForegroundColor Red
        }
    }

    "UnlockAccount" {
        Write-Host "--- Action: Unlock Account ---" -ForegroundColor Cyan
        Write-Host ""

        if (-not $adUser.LockedOut) {
            Write-Host "  ⚠️  Account is not locked — no action needed" -ForegroundColor Yellow
            $result.Success = $true
            $result.Notes   = "Not locked"
        }
        else {
            try {
                Unlock-ADAccount -Identity $SAM -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Account unlocked: $SAM" -ForegroundColor Green
            }
            catch {
                $result.Error = "Unlock failed: $_"
                Write-Host "  ❌ Failed: $_" -ForegroundColor Red
            }
        }
    }
}

# ============================================================
# SUMMARY AND EXPORT
# ============================================================

$EndTime  = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " REMEDIATION SUMMARY — $TicketNumber" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " User     : $SAM"
Write-Host " Action   : $Action"
if ($Group) { Write-Host " Group    : $Group" }
Write-Host " Success  : $($result.Success)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
if ($result.Error) { Write-Host " Error    : $($result.Error)" -ForegroundColor Red }
if ($result.Notes) { Write-Host " Notes    : $($result.Notes)" -ForegroundColor Yellow }
Write-Host " Duration : $([math]::Round($Duration, 2)) seconds"
Write-Host " Log File : $LogFile"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
try {
    $result | Export-Csv -Path $LogFile -NoTypeInformation -ErrorAction Stop
    Write-Host "✅ Results exported to: $LogFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Export failed: $_" -ForegroundColor Red
}

Write-Host ""
if ($result.Success) {
    Write-Host "✅ Remediation completed successfully." -ForegroundColor Green
}
else {
    Write-Host "❌ Remediation failed or aborted. Review errors above." -ForegroundColor Red
}
Write-Host ""
