#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Fairmount Manufacturing LLC — Bulk User Rollback Script
    Ticket: REQ0042001

.DESCRIPTION
    Provides two rollback scenarios for Fairmount Manufacturing user provisioning:

    Scenario A — Targeted Single User Rollback
        Removes or remediates a specific user without affecting other accounts.
        Options:
            - Fix group assignment only
            - Remove single user completely from AD and AAD-Sync-Users

    Scenario B — Full Bulk Rollback
        Removes all 10 Fairmount Manufacturing users from:
            - AAD-Sync-Users (sync scope — removed FIRST)
            - Active Directory
        Triggers Entra Connect delta sync to remove orphan cloud accounts.

    IMPORTANT: AAD-Sync-Users controls Entra Connect sync scope.
    Users must be removed from AAD-Sync-Users BEFORE AD deletion
    to ensure Entra ID deprovisions them correctly on next sync.

.NOTES
    Author:      Edward E. Spence
    Environment: IAMPAM.LAB
    Domain:      iampam.lab
    Sync Group:  AAD-Sync-Users (CRITICAL — remove from this BEFORE AD deletion)
    Run From:    MGMT01 as adm-t0-administrator
    Repo:        fairmount-manufacturing-iam-operations

.PARAMETER Scenario
    A = Targeted single user rollback
    B = Full bulk rollback of all FM users

.PARAMETER SAM
    Required for Scenario A. SamAccountName of the user to remediate.

.PARAMETER Action
    Required for Scenario A.
    FixGroup   = Fix group assignment only
    RemoveUser = Remove the user completely from AD and AAD-Sync-Users

.PARAMETER Group
    Required for Scenario A with Action FixGroup.

.PARAMETER LogPath
    Optional. Default: C:\Logs

.PARAMETER TicketNumber
    Optional. Default: REQ0042001

.EXAMPLE
    .\fm-bulk-user-rollback.ps1 -Scenario A -SAM fm.kira.vanthorpe -Action FixGroup -Group ENG-Users

.EXAMPLE
    .\fm-bulk-user-rollback.ps1 -Scenario A -SAM fm.kira.vanthorpe -Action RemoveUser

.EXAMPLE
    .\fm-bulk-user-rollback.ps1 -Scenario B
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("A","B")]
    [string]$Scenario,

    [Parameter(Mandatory = $false)]
    [string]$SAM,

    [Parameter(Mandatory = $false)]
    [ValidateSet("FixGroup","RemoveUser")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Group,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs",

    [Parameter(Mandatory = $false)]
    [string]$TicketNumber = "REQ0042001"
)

# ============================================================
# CONFIGURATION
# ============================================================

$SyncGroup = "AAD-Sync-Users"

$AllFMUsers = @(
    @{SAM="fm.kira.vanthorpe";  Group="ENG-Users";     Dept="Engineering"},
    @{SAM="fm.dalen.wescroft";  Group="ENG-Users";     Dept="Engineering"},
    @{SAM="fm.mira.ashbridge";  Group="ENG-Users";     Dept="Engineering"},
    @{SAM="fm.torin.calloway";  Group="ENG-Users";     Dept="Engineering"},
    @{SAM="fm.brenli.harwick";  Group="FIN-Users";     Dept="Finance"},
    @{SAM="fm.casen.morrow";    Group="FIN-Users";     Dept="Finance"},
    @{SAM="fm.lyris.dunvale";   Group="FIN-Approvers"; Dept="Finance"},
    @{SAM="fm.orin.tressler";   Group="FIN-Auditors";  Dept="Finance"},
    @{SAM="fm.seren.holwick";   Group="IT-Admins";     Dept="IT-Security"},
    @{SAM="fm.zael.cortbridge"; Group="SEC-Analysts";  Dept="IT-Security"}
)

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
}

$LogFile   = "$LogPath\FM-Rollback-$TicketNumber-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$Results   = @()
$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Fairmount Manufacturing — User Rollback Script" -ForegroundColor Yellow
Write-Host " Ticket   : $TicketNumber" -ForegroundColor Yellow
Write-Host " Scenario : $Scenario" -ForegroundColor Yellow
Write-Host " Started  : $StartTime" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# PARAMETER VALIDATION
# ============================================================

if ($Scenario -eq "A") {
    if (-not $SAM) {
        Write-Host "❌ Scenario A requires -SAM parameter." -ForegroundColor Red
        exit 1
    }
    if (-not $Action) {
        Write-Host "❌ Scenario A requires -Action parameter. Options: FixGroup | RemoveUser" -ForegroundColor Red
        exit 1
    }
    if ($Action -eq "FixGroup" -and -not $Group) {
        Write-Host "❌ Action FixGroup requires -Group parameter." -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# SCENARIO A — TARGETED SINGLE USER ROLLBACK
# ============================================================

if ($Scenario -eq "A") {

    Write-Host "--- Scenario A: Targeted Single User Rollback ---" -ForegroundColor Yellow
    Write-Host " User   : $SAM" -ForegroundColor White
    Write-Host " Action : $Action" -ForegroundColor White
    if ($Group) { Write-Host " Group  : $Group" -ForegroundColor White }
    Write-Host ""

    $adUser = Get-ADUser -Filter {SamAccountName -eq $SAM} -ErrorAction SilentlyContinue

    if (-not $adUser) {
        Write-Host "⚠️  User not found in AD: $SAM — no action required" -ForegroundColor Yellow
        $Results += [PSCustomObject]@{
            Ticket   = $TicketNumber
            Timestamp= Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Scenario = "A"
            SAM      = $SAM
            Action   = $Action
            Success  = $false
            Error    = "User not found in AD"
        }
    }
    else {

        if ($Action -eq "FixGroup") {

            $result = [PSCustomObject]@{
                Ticket    = $TicketNumber
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Scenario  = "A"
                SAM       = $SAM
                Action    = "FixGroup → $Group"
                Success   = $false
                Error     = ""
            }

            # Fix department group
            try {
                $isMember = Get-ADGroupMember -Identity $Group -ErrorAction Stop |
                            Where-Object { $_.SamAccountName -eq $SAM }
                if ($isMember) {
                    Write-Host "  ⚠️  Already member of $Group" -ForegroundColor Yellow
                    $result.Success = $true
                    $result.Error   = "Already a member"
                }
                else {
                    Add-ADGroupMember -Identity $Group -Members $SAM -ErrorAction Stop
                    $result.Success = $true
                    Write-Host "  ✅ Added to $Group" -ForegroundColor Green
                }
            }
            catch {
                $result.Error = "Group fix failed: $_"
                Write-Host "  ❌ Failed: $_" -ForegroundColor Red
            }

            # Also ensure in AAD-Sync-Users
            try {
                $inSync = Get-ADGroupMember -Identity $SyncGroup -ErrorAction Stop |
                          Where-Object { $_.SamAccountName -eq $SAM }
                if (-not $inSync) {
                    Add-ADGroupMember -Identity $SyncGroup -Members $SAM -ErrorAction Stop
                    Write-Host "  ✅ Also added to $SyncGroup (required for Entra sync)" -ForegroundColor Green
                }
                else {
                    Write-Host "  ✅ Already in $SyncGroup" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  ❌ Failed to add to $SyncGroup — $_ (user will not sync to Entra)" -ForegroundColor Red
            }

            $Results += $result
        }

        if ($Action -eq "RemoveUser") {

            Write-Host "⚠️  WARNING: This permanently removes $SAM from AD and Entra sync scope." -ForegroundColor Red
            $confirm = Read-Host "Type CONFIRM to proceed"

            $result = [PSCustomObject]@{
                Ticket    = $TicketNumber
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Scenario  = "A"
                SAM       = $SAM
                Action    = "RemoveUser"
                Success   = $false
                Error     = ""
            }

            if ($confirm -eq "CONFIRM") {

                # Step 1 — Remove from AAD-Sync-Users FIRST
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

                # Step 2 — Remove from AD
                try {
                    Remove-ADUser -Identity $SAM -Confirm:$false -ErrorAction Stop
                    $result.Success = $true
                    Write-Host "  ✅ User removed from AD: $SAM" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "  ⚠️  Vault: Secrets are department-level. No Vault deletion required." -ForegroundColor Yellow
                    Write-Host "  ⚠️  Delinea: Group-based access. Verify user no longer appears in folder access." -ForegroundColor Yellow
                }
                catch {
                    $result.Error = "AD removal failed: $_"
                    Write-Host "  ❌ Failed to remove from AD: $_" -ForegroundColor Red
                }

                # Step 3 — Trigger Entra sync
                if ($result.Success) {
                    Write-Host ""
                    Write-Host "--- Triggering Entra Delta Sync ---" -ForegroundColor Cyan
                    try {
                        Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
                            Import-Module ADSync
                            Start-ADSyncSyncCycle -PolicyType Delta
                        } -ErrorAction Stop
                        Write-Host "  ✅ Delta sync triggered" -ForegroundColor Green
                        Write-Host "  ⚠️  Wait 2-5 minutes then verify $SAM no longer in Entra ID" -ForegroundColor Yellow
                        $result.Error = "Entra sync triggered"
                    }
                    catch {
                        Write-Host "  ❌ Entra sync failed — trigger manually on ID-SYNC01" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "⚠️  Aborted. No changes made." -ForegroundColor Yellow
                $result.Error = "Aborted by operator"
            }

            $Results += $result
        }
    }
}

# ============================================================
# SCENARIO B — FULL BULK ROLLBACK
# ============================================================

if ($Scenario -eq "B") {

    Write-Host "--- Scenario B: Full Bulk Rollback ---" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  This removes ALL 10 FM users from AAD-Sync-Users and Active Directory." -ForegroundColor Red
    Write-Host "    Users to be removed:" -ForegroundColor Red
    $AllFMUsers | ForEach-Object { Write-Host "      - $($_.SAM) [$($_.Dept)]" -ForegroundColor Red }
    Write-Host ""
    $confirm = Read-Host "Type CONFIRM to proceed"

    if ($confirm -ne "CONFIRM") {
        Write-Host "⚠️  Full rollback aborted. No changes made." -ForegroundColor Yellow
        exit 0
    }

    Write-Host ""

    # --- Step 1: Remove from AAD-Sync-Users FIRST ---
    Write-Host "--- Step 1: Removing from AAD-Sync-Users ---" -ForegroundColor Yellow
    Write-Host "    (Must happen before AD deletion for clean Entra deprovision)" -ForegroundColor White
    Write-Host ""

    foreach ($user in $AllFMUsers) {
        try {
            $inSync = Get-ADGroupMember -Identity $SyncGroup -ErrorAction Stop |
                      Where-Object { $_.SamAccountName -eq $user.SAM }
            if ($inSync) {
                Remove-ADGroupMember -Identity $SyncGroup -Members $user.SAM -Confirm:$false -ErrorAction Stop
                Write-Host "  ✅ Removed from $SyncGroup`: $($user.SAM)" -ForegroundColor Green
            }
            else {
                Write-Host "  ⚠️  Not in $SyncGroup`: $($user.SAM)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ❌ Failed to remove $($user.SAM) from $SyncGroup — $_" -ForegroundColor Red
        }
    }

    # --- Step 2: Trigger sync to deprovision from Entra ---
    Write-Host ""
    Write-Host "--- Step 2: Triggering Entra Sync (Deprovision from Cloud) ---" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
            Import-Module ADSync
            Start-ADSyncSyncCycle -PolicyType Delta
        } -ErrorAction Stop
        Write-Host "  ✅ Delta sync triggered — Entra will deprovision users" -ForegroundColor Green
        Write-Host "  ⚠️  Wait 2-5 minutes before proceeding to AD deletion" -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    catch {
        Write-Host "  ❌ Entra sync failed — trigger manually then wait before continuing" -ForegroundColor Red
    }

    # --- Step 3: Remove from AD ---
    Write-Host ""
    Write-Host "--- Step 3: Removing Users from Active Directory ---" -ForegroundColor Yellow
    Write-Host ""

    foreach ($user in $AllFMUsers) {
        $result = [PSCustomObject]@{
            Ticket    = $TicketNumber
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Scenario  = "B"
            SAM       = $user.SAM
            Action    = "RemoveUser"
            Success   = $false
            Error     = ""
        }

        try {
            $exists = Get-ADUser -Filter {SamAccountName -eq $user.SAM} -ErrorAction SilentlyContinue
            if (-not $exists) {
                Write-Host "  ⚠️  Not found (may not have been created): $($user.SAM)" -ForegroundColor Yellow
                $result.Success = $true
                $result.Error   = "Not found in AD"
            }
            else {
                Remove-ADUser -Identity $user.SAM -Confirm:$false -ErrorAction Stop
                $result.Success = $true
                Write-Host "  ✅ Removed from AD: $($user.SAM)" -ForegroundColor Green
            }
        }
        catch {
            $result.Error = "AD removal failed: $_"
            Write-Host "  ❌ Failed: $($user.SAM) — $_" -ForegroundColor Red
        }

        $Results += $result
    }

    # --- Vault cleanup guidance ---
    Write-Host ""
    Write-Host "--- Vault Secret Cleanup Required (Manual) ---" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Run on PAMVAULT01:" -ForegroundColor White
    Write-Host "  vault kv delete secret/fairmount/engineering" -ForegroundColor Cyan
    Write-Host "  vault kv delete secret/fairmount/finance" -ForegroundColor Cyan
    Write-Host "  vault kv delete secret/fairmount/it" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Remove LDAP group mappings if no longer needed:" -ForegroundColor White
    Write-Host "  vault delete auth/ldap/groups/IT-Admins" -ForegroundColor Cyan
    Write-Host "  vault delete auth/ldap/groups/ENG-Users" -ForegroundColor Cyan
    Write-Host "  vault delete auth/ldap/groups/FIN-Users" -ForegroundColor Cyan
    Write-Host "  vault delete auth/ldap/groups/SEC-Analysts" -ForegroundColor Cyan
    Write-Host ""

    # --- Delinea cleanup guidance ---
    Write-Host "--- Delinea Cleanup Required (Manual) ---" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Navigate to https://delinea01.iampam.lab and delete:" -ForegroundColor White
    Write-Host "  1. Secrets in Fairmount Manufacturing/Engineering" -ForegroundColor White
    Write-Host "  2. Secrets in Fairmount Manufacturing/Finance" -ForegroundColor White
    Write-Host "  3. Secrets in Fairmount Manufacturing/IT-Security" -ForegroundColor White
    Write-Host "  4. Fairmount Manufacturing parent folder" -ForegroundColor White
    Write-Host ""

    # --- Final Entra verification sync ---
    Write-Host "--- Final Entra Connect Sync ---" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
            Import-Module ADSync
            Start-ADSyncSyncCycle -PolicyType Delta
        } -ErrorAction Stop
        Write-Host "  ✅ Final delta sync triggered" -ForegroundColor Green
        Write-Host "  ⚠️  Verify no fm.* accounts remain in Entra ID:" -ForegroundColor Yellow
        Write-Host "     https://entra.microsoft.com → Users → All Users → Search: fm." -ForegroundColor Cyan
    }
    catch {
        Write-Host "  ❌ Final sync failed — trigger manually on ID-SYNC01" -ForegroundColor Red
    }
}

# ============================================================
# RESULTS SUMMARY
# ============================================================

$EndTime  = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds
$Success  = ($Results | Where-Object { $_.Success -eq $true }).Count
$Failed   = ($Results | Where-Object { $_.Success -eq $false }).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " ROLLBACK SUMMARY — $TicketNumber — Scenario $Scenario" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Actions Processed : $($Results.Count)"
Write-Host " Successful        : $Success" -ForegroundColor Green
Write-Host " Failed            : $Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
Write-Host " Duration          : $([math]::Round($Duration, 2)) seconds"
Write-Host " Log File          : $LogFile"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

$Results | Format-Table Timestamp, Scenario, SAM, Action, Success, Error -AutoSize

New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
try {
    $Results | Export-Csv -Path $LogFile -NoTypeInformation -ErrorAction Stop
    Write-Host "✅ Results exported to: $LogFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to export results: $_" -ForegroundColor Red
}

Write-Host ""
if ($Failed -gt 0) {
    Write-Host "⚠️  Some actions failed. Review log: $LogFile" -ForegroundColor Red
}
else {
    Write-Host "✅ Rollback completed successfully." -ForegroundColor Green
}
Write-Host ""
