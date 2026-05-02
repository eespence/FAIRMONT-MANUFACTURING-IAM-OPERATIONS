#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Fairmont Manufacturing LLC — Single User Provisioning Script

.DESCRIPTION
    Provisions a single Fairmont Manufacturing employee account in Active Directory.

    Each user is:
        1. Created in OU=IAM-PAM-Users
        2. Assigned to their department AD group
        3. Added to AAD-Sync-Users for Entra Connect synchronization

    AAD-Sync-Users is the Entra Connect group filter scope.
    Users NOT in AAD-Sync-Users will NOT sync to Entra ID regardless of OU.

    Use this script for:
        - Late hire onboarding after the bulk cohort run
        - Retrying a specific user that failed during bulk provisioning
        - Adding a new Fairmont employee outside of a bulk onboarding event

.NOTES
    Author:      Edward E. Spence
    Environment: IAMPAM.LAB
    Domain:      iampam.lab
    OU Target:   OU=IAM-PAM-Users,DC=iampam,DC=lab
    Sync Group:  AAD-Sync-Users (CRITICAL — controls Entra Connect scope)
    Run From:    MGMT01 as adm-t0-administrator
    Repo:        fairmont-manufacturing-iam-operations

.PARAMETER DisplayName
    Full display name. Example: "FM - Kira Vanthorpe"

.PARAMETER SAM
    SamAccountName. Example: fm.kira.vanthorpe

.PARAMETER UPN
    UserPrincipalName. Example: fm.kira.vanthorpe@iampam.lab

.PARAMETER Group
    Department AD group.
    Valid: ENG-Users, FIN-Users, FIN-Approvers, FIN-Auditors, IT-Admins, SEC-Analysts

.PARAMETER Department
    Department label for logging. Example: Engineering

.PARAMETER TicketNumber
    Service request ticket number. Example: REQ0042015

.PARAMETER LogPath
    Optional. Default: C:\Logs

.EXAMPLE
    .\fm-single-user-provision.ps1 `
        -DisplayName "FM - Kira Vanthorpe" `
        -SAM "fm.kira.vanthorpe" `
        -UPN "fm.kira.vanthorpe@iampam.lab" `
        -Group "ENG-Users" `
        -Department "Engineering" `
        -TicketNumber "REQ0042015"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [string]$SAM,

    [Parameter(Mandatory = $true)]
    [string]$UPN,

    [Parameter(Mandatory = $true)]
    [ValidateSet("ENG-Users","FIN-Users","FIN-Approvers","FIN-Auditors","IT-Admins","SEC-Analysts")]
    [string]$Group,

    [Parameter(Mandatory = $true)]
    [string]$Department,

    [Parameter(Mandatory = $true)]
    [string]$TicketNumber,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs"
)

# ============================================================
# CONFIGURATION
# ============================================================

$OU        = "OU=IAM-PAM-Users,DC=iampam,DC=lab"
$SyncGroup = "AAD-Sync-Users"
$Password  = ConvertTo-SecureString "Welcome@Fairmont2026!" -AsPlainText -Force

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
}

$LogFile   = "$LogPath\FM-SingleProvision-$TicketNumber-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Fairmont Manufacturing — Single User Provisioning" -ForegroundColor Cyan
Write-Host " Ticket     : $TicketNumber" -ForegroundColor Cyan
Write-Host " User       : $SAM" -ForegroundColor Cyan
Write-Host " Department : $Department" -ForegroundColor Cyan
Write-Host " Group      : $Group" -ForegroundColor Cyan
Write-Host " Sync Group : $SyncGroup" -ForegroundColor Cyan
Write-Host " Started    : $StartTime" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================

Write-Host "--- Pre-Flight Checks ---" -ForegroundColor Yellow
Write-Host ""

try {
    $dc = Get-ADDomainController -Discover -ErrorAction Stop
    Write-Host "✅ Domain Controller: $($dc.Name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Cannot reach domain controller. Aborting." -ForegroundColor Red
    exit 1
}

try {
    Get-ADOrganizationalUnit -Identity $OU -ErrorAction Stop | Out-Null
    Write-Host "✅ Target OU exists: $OU" -ForegroundColor Green
}
catch {
    Write-Host "❌ Target OU not found. Aborting." -ForegroundColor Red
    exit 1
}

try {
    Get-ADGroup -Identity $Group -ErrorAction Stop | Out-Null
    Write-Host "✅ Department group found: $Group" -ForegroundColor Green
}
catch {
    Write-Host "❌ Department group not found: $Group. Aborting." -ForegroundColor Red
    exit 1
}

try {
    Get-ADGroup -Identity $SyncGroup -ErrorAction Stop | Out-Null
    Write-Host "✅ Sync group found: $SyncGroup" -ForegroundColor Green
}
catch {
    Write-Host "❌ CRITICAL: Sync group not found: $SyncGroup" -ForegroundColor Red
    Write-Host "   User will be created but will NOT sync to Entra ID. Aborting." -ForegroundColor Red
    exit 1
}

if ($UPN -notmatch "^fm\..+\..+@iampam\.lab$") {
    Write-Host "⚠️  UPN format warning: $UPN — verify this is correct" -ForegroundColor Yellow
}
else {
    Write-Host "✅ UPN format valid: $UPN" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ All pre-flight checks passed." -ForegroundColor Green
Write-Host ""

# ============================================================
# PROVISIONING
# ============================================================

$result = [PSCustomObject]@{
    Ticket         = $TicketNumber
    Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Department     = $Department
    SAM            = $SAM
    UPN            = $UPN
    Group          = $Group
    UserCreated    = $false
    GroupAssigned  = $false
    SyncGroupAdded = $false
    Error          = ""
}

# --- Step 1: Create User ---
Write-Host "--- Step 1: Creating User ---" -ForegroundColor Yellow
Write-Host ""

try {
    $existing = Get-ADUser -Filter {SamAccountName -eq $SAM} -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  ⚠️  User already exists: $SAM — skipping creation" -ForegroundColor Yellow
        $result.UserCreated = $true
        $result.Error = "User already existed"
    }
    else {
        New-ADUser `
            -Name              $DisplayName `
            -SamAccountName    $SAM `
            -UserPrincipalName $UPN `
            -Path              $OU `
            -AccountPassword   $Password `
            -Enabled           $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        $result.UserCreated = $true
        Write-Host "  ✅ User created: $SAM" -ForegroundColor Green
    }
}
catch {
    $result.Error = "User creation failed: $_"
    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
}

# --- Step 2: Assign Department Group ---
if ($result.UserCreated) {
    Write-Host ""
    Write-Host "--- Step 2: Assigning Department Group ---" -ForegroundColor Yellow
    Write-Host ""

    try {
        $isMember = Get-ADGroupMember -Identity $Group -ErrorAction Stop |
                    Where-Object { $_.SamAccountName -eq $SAM }
        if ($isMember) {
            Write-Host "  ⚠️  Already member of $Group" -ForegroundColor Yellow
            $result.GroupAssigned = $true
        }
        else {
            Add-ADGroupMember -Identity $Group -Members $SAM -ErrorAction Stop
            $result.GroupAssigned = $true
            Write-Host "  ✅ Added to: $Group" -ForegroundColor Green
        }
    }
    catch {
        $result.Error += " | Group assignment failed: $_"
        Write-Host "  ❌ Failed: $_" -ForegroundColor Red
    }
}

# --- Step 3: Add to AAD-Sync-Users ---
if ($result.UserCreated) {
    Write-Host ""
    Write-Host "--- Step 3: Adding to Entra Sync Scope ($SyncGroup) ---" -ForegroundColor Yellow
    Write-Host ""

    try {
        $inSync = Get-ADGroupMember -Identity $SyncGroup -ErrorAction Stop |
                  Where-Object { $_.SamAccountName -eq $SAM }
        if ($inSync) {
            Write-Host "  ⚠️  Already in $SyncGroup" -ForegroundColor Yellow
            $result.SyncGroupAdded = $true
        }
        else {
            Add-ADGroupMember -Identity $SyncGroup -Members $SAM -ErrorAction Stop
            $result.SyncGroupAdded = $true
            Write-Host "  ✅ Added to $SyncGroup — user will sync to Entra ID" -ForegroundColor Green
        }
    }
    catch {
        $result.Error += " | AAD-Sync-Users failed: $_"
        Write-Host "  ❌ CRITICAL: Failed to add to $SyncGroup — $_" -ForegroundColor Red
        Write-Host "     User will NOT sync to Entra ID until fixed." -ForegroundColor Red
        Write-Host "     Run fm-single-user-remediate.ps1 -Action FixGroup -Group AAD-Sync-Users" -ForegroundColor Yellow
    }
}

# --- Step 4: Trigger Delta Sync ---
if ($result.SyncGroupAdded) {
    Write-Host ""
    Write-Host "--- Step 4: Triggering Entra Connect Delta Sync ---" -ForegroundColor Cyan
    Write-Host ""

    try {
        Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
            Import-Module ADSync
            Start-ADSyncSyncCycle -PolicyType Delta
        } -ErrorAction Stop
        Write-Host "  ✅ Delta sync triggered" -ForegroundColor Green
        Write-Host "  ⚠️  Wait 2-5 minutes then verify $SAM appears in Entra ID" -ForegroundColor Yellow
    }
    catch {
        Write-Host "  ❌ Sync trigger failed — trigger manually on ID-SYNC01" -ForegroundColor Red
    }
}

# ============================================================
# NEXT STEPS
# ============================================================

Write-Host ""
Write-Host "--- Next Steps ---" -ForegroundColor Cyan
Write-Host ""

if ($result.UserCreated -and $result.GroupAssigned -and $result.SyncGroupAdded) {
    Write-Host "  ✅ User fully provisioned. Verify the following:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. Entra ID user appears (allow 2-5 min):" -ForegroundColor White
    Write-Host "     https://entra.microsoft.com → Users → Search: $SAM" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. Vault LDAP group mapping covers $Group`:" -ForegroundColor White
    Write-Host "     vault read auth/ldap/groups/$Group" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Delinea folder access assigned to $Group`:" -ForegroundColor White
    Write-Host "     https://delinea01.iampam.lab → Folders → Fairmount Manufacturing" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  4. Splunk captured user creation:" -ForegroundColor White
    Write-Host "     index=wineventlog EventCode=4720 | search Account_Name=`"$SAM`"" -ForegroundColor Cyan
}
else {
    Write-Host "  ⚠️  Provisioning incomplete. Review errors above." -ForegroundColor Red
    Write-Host "     Run fm-single-user-remediate.ps1 to fix." -ForegroundColor Yellow
}

# ============================================================
# SUMMARY AND EXPORT
# ============================================================

$EndTime  = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SUMMARY — $TicketNumber" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " User           : $SAM"
Write-Host " UserCreated    : $($result.UserCreated)" -ForegroundColor $(if ($result.UserCreated) { "Green" } else { "Red" })
Write-Host " GroupAssigned  : $($result.GroupAssigned)" -ForegroundColor $(if ($result.GroupAssigned) { "Green" } else { "Red" })
Write-Host " SyncGroupAdded : $($result.SyncGroupAdded)" -ForegroundColor $(if ($result.SyncGroupAdded) { "Green" } else { "Red" })
if ($result.Error) { Write-Host " Notes          : $($result.Error)" -ForegroundColor Yellow }
Write-Host " Duration       : $([math]::Round($Duration, 2)) seconds"
Write-Host " Log File       : $LogFile"
Write-Host "============================================================" -ForegroundColor Cyan
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
