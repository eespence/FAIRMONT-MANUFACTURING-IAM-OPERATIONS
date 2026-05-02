@'
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Fairmont Manufacturing LLC — Bulk User Provisioning Script
    Ticket: REQ0042001

.DESCRIPTION
    Provisions 10 Fairmont Manufacturing employee accounts in Active Directory
    across Engineering, Finance, and IT/Security departments.

    Each user is:
        1. Created in OU=IAM-PAM-Users
        2. Assigned to their department AD group
        3. Added to AAD-Sync-Users for Entra Connect synchronization

    AAD-Sync-Users is the Entra Connect group filter scope.
    Users NOT in AAD-Sync-Users will NOT sync to Entra ID regardless of OU.

    Each user is processed independently with try/catch error handling.
    A failure on one user does not stop remaining users from being provisioned.
    All outcomes are logged to console and exported to CSV for audit evidence.

.NOTES
    Author:      Edward E. Spence
    Environment: IAMPAM.LAB
    Domain:      iampam.lab
    OU Target:   OU=IAM-PAM-Users,DC=iampam,DC=lab
    Sync Group:  AAD-Sync-Users (CRITICAL — controls Entra Connect scope)
    Run From:    MGMT01 as adm-t0-administrator
    Repo:        fairmont-manufacturing-iam-operations

.PARAMETER LogPath
    Optional. Directory for log output. Default: C:\Logs

.PARAMETER TicketNumber
    Optional. Ticket reference for log file naming. Default: REQ0042001

.EXAMPLE
    .\fm-bulk-user-provisioning.ps1

.EXAMPLE
    .\fm-bulk-user-provisioning.ps1 -LogPath "D:\Logs" -TicketNumber "REQ0042001"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs",

    [Parameter(Mandatory = $false)]
    [string]$TicketNumber = "REQ0042001"
)

# ============================================================
# CONFIGURATION
# ============================================================

$OU        = "OU=IAM-PAM-Users,DC=iampam,DC=lab"
$Domain    = "fairmontmanufacturing.onmicrosoft.com"
$SyncGroup = "AAD-Sync-Users"
$Password  = ConvertTo-SecureString "Welcome@Fairmont2026!" -AsPlainText -Force

# User roster — all names are entirely fictional
$Users = @(
    @{Name="FM - Kira Vanthorpe";  SamAccount="fm.kira.vanthorpe";  UPN="fm.kira.vanthorpe@$Domain";  DeptGroup="ENG-Users";     Dept="Engineering"},
    @{Name="FM - Dalen Wescroft";  SamAccount="fm.dalen.wescroft";  UPN="fm.dalen.wescroft@$Domain";  DeptGroup="ENG-Users";     Dept="Engineering"},
    @{Name="FM - Mira Ashbridge";  SamAccount="fm.mira.ashbridge";  UPN="fm.mira.ashbridge@$Domain";  DeptGroup="ENG-Users";     Dept="Engineering"},
    @{Name="FM - Torin Calloway";  SamAccount="fm.torin.calloway";  UPN="fm.torin.calloway@$Domain";  DeptGroup="ENG-Users";     Dept="Engineering"},
    @{Name="FM - Brenli Harwick";  SamAccount="fm.brenli.harwick";  UPN="fm.brenli.harwick@$Domain";  DeptGroup="FIN-Users";     Dept="Finance"},
    @{Name="FM - Casen Morrow";    SamAccount="fm.casen.morrow";    UPN="fm.casen.morrow@$Domain";    DeptGroup="FIN-Users";     Dept="Finance"},
    @{Name="FM - Lyris Dunvale";   SamAccount="fm.lyris.dunvale";   UPN="fm.lyris.dunvale@$Domain";   DeptGroup="FIN-Approvers"; Dept="Finance"},
    @{Name="FM - Orin Tressler";   SamAccount="fm.orin.tressler";   UPN="fm.orin.tressler@$Domain";   DeptGroup="FIN-Auditors";  Dept="Finance"},
    @{Name="FM - Seren Holwick";   SamAccount="fm.seren.holwick";   UPN="fm.seren.holwick@$Domain";   DeptGroup="IT-Admins";     Dept="IT-Security"},
    @{Name="FM - Zael Cortbridge"; SamAccount="fm.zael.cortbridge"; UPN="fm.zael.cortbridge@$Domain"; DeptGroup="SEC-Analysts";  Dept="IT-Security"}
)

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
    Write-Host "Created log directory: $LogPath" -ForegroundColor Cyan
}

$LogFile   = "$LogPath\FM-Onboarding-$TicketNumber-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$Results   = @()
$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Fairmount Manufacturing — Bulk User Provisioning" -ForegroundColor Cyan
Write-Host " Ticket     : $TicketNumber" -ForegroundColor Cyan
Write-Host " Started    : $StartTime" -ForegroundColor Cyan
Write-Host " Target OU  : $OU" -ForegroundColor Cyan
Write-Host " Sync Group : $SyncGroup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================

Write-Host "--- Running Pre-Flight Checks ---" -ForegroundColor Yellow
Write-Host ""

try {
    $dc = Get-ADDomainController -Discover -ErrorAction Stop
    Write-Host "✅ Domain Controller found: $($dc.Name)" -ForegroundColor Green
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
    Write-Host "❌ Target OU not found: $OU. Aborting." -ForegroundColor Red
    exit 1
}

try {
    Get-ADGroup -Identity $SyncGroup -ErrorAction Stop | Out-Null
    Write-Host "✅ Sync group found: $SyncGroup" -ForegroundColor Green
}
catch {
    Write-Host "❌ CRITICAL: Sync group not found: $SyncGroup. Aborting." -ForegroundColor Red
    exit 1
}

$RequiredGroups = @("ENG-Users","FIN-Users","FIN-Approvers","FIN-Auditors","IT-Admins","SEC-Analysts")
$GroupCheckFailed = $false

foreach ($grp in $RequiredGroups) {
    try {
        Get-ADGroup -Identity $grp -ErrorAction Stop | Out-Null
        Write-Host "✅ Group found: $grp" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Group missing: $grp" -ForegroundColor Red
        $GroupCheckFailed = $true
    }
}

if ($GroupCheckFailed) {
    Write-Host ""
    Write-Host "❌ One or more required groups are missing. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ All pre-flight checks passed. Starting provisioning..." -ForegroundColor Green
Write-Host ""

# ============================================================
# USER PROVISIONING
# ============================================================

Write-Host "--- Provisioning Users ---" -ForegroundColor Yellow
Write-Host ""

foreach ($user in $Users) {

    # Extract values to local variables for safe use in AD filter blocks
    $userName      = $user.Name
    $userSam       = $user.SamAccount
    $userUPN       = $user.UPN
    $userGroup     = $user.DeptGroup
    $userDept      = $user.Dept

    $result = [PSCustomObject]@{
        Ticket         = $TicketNumber
        Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Department     = $userDept
        SAM            = $userSam
        UPN            = $userUPN
        Group          = $userGroup
        UserCreated    = $false
        GroupAssigned  = $false
        SyncGroupAdded = $false
        Error          = ""
    }

    Write-Host "Processing: $userSam [$userDept]" -ForegroundColor White

    # --- Step 1: Create AD User ---
    try {
        $existing = Get-ADUser -Filter "SamAccountName -eq '$userSam'" -ErrorAction SilentlyContinue

        if ($existing) {
            Write-Host "  ⚠️  User already exists: $userSam — skipping creation" -ForegroundColor Yellow
            $result.UserCreated = $true
            $result.Error = "User already existed — creation skipped"
        }
        else {
            New-ADUser `
                -Name              $userName `
                -SamAccountName    $userSam `
                -UserPrincipalName $userUPN `
                -Path              $OU `
                -AccountPassword   $Password `
                -Enabled           $true `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            $result.UserCreated = $true
            Write-Host "  ✅ User created: $userSam" -ForegroundColor Green
        }
    }
    catch {
        $result.Error = "User creation failed: $_"
        Write-Host "  ❌ User creation failed: $userSam — $_" -ForegroundColor Red
    }

    # --- Step 2: Assign Department Group ---
    if ($result.UserCreated) {
        try {
            $isMember = Get-ADGroupMember -Identity $userGroup -ErrorAction Stop |
                        Where-Object { $_.SamAccountName -eq $userSam }

            if ($isMember) {
                Write-Host "  ⚠️  Already member of $userGroup — skipping" -ForegroundColor Yellow
                $result.GroupAssigned = $true
            }
            else {
                Add-ADGroupMember -Identity $userGroup -Members $userSam -ErrorAction Stop
                $result.GroupAssigned = $true
                Write-Host "  ✅ Added to group: $userGroup" -ForegroundColor Green
            }
        }
        catch {
            $result.Error += " | Group assignment failed: $_"
            Write-Host "  ❌ Group assignment failed for $userSam — $_" -ForegroundColor Red
        }
    }

    # --- Step 3: Add to AAD-Sync-Users ---
    if ($result.UserCreated) {
        try {
            $inSyncGroup = Get-ADGroupMember -Identity $SyncGroup -ErrorAction Stop |
                           Where-Object { $_.SamAccountName -eq $userSam }

            if ($inSyncGroup) {
                Write-Host "  ⚠️  Already in $SyncGroup — skipping" -ForegroundColor Yellow
                $result.SyncGroupAdded = $true
            }
            else {
                Add-ADGroupMember -Identity $SyncGroup -Members $userSam -ErrorAction Stop
                $result.SyncGroupAdded = $true
                Write-Host "  ✅ Added to sync group: $SyncGroup" -ForegroundColor Green
            }
        }
        catch {
            $result.Error += " | AAD-Sync-Users assignment failed: $_"
            Write-Host "  ❌ CRITICAL: Failed to add $userSam to $SyncGroup — $_" -ForegroundColor Red
            Write-Host "     This user will NOT sync to Entra ID until added manually." -ForegroundColor Red
        }
    }

    $Results += $result
    Write-Host ""
}

# ============================================================
# TRIGGER ENTRA CONNECT DELTA SYNC
# ============================================================

Write-Host "--- Triggering Entra Connect Delta Sync ---" -ForegroundColor Cyan
Write-Host ""

try {
    Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
        Import-Module ADSync
        Start-ADSyncSyncCycle -PolicyType Delta
    } -ErrorAction Stop
    Write-Host "✅ Delta sync triggered on ID-SYNC01" -ForegroundColor Green
    Write-Host "   Wait 2-5 minutes then verify users appear in Entra ID" -ForegroundColor Yellow
    Write-Host "   https://entra.microsoft.com → Users → All Users → Search: fm." -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Entra sync trigger failed — trigger manually on ID-SYNC01:" -ForegroundColor Red
    Write-Host "   Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Cyan
}

# ============================================================
# RESULTS SUMMARY
# ============================================================

$EndTime       = Get-Date
$Duration      = ($EndTime - $StartTime).TotalSeconds
$TotalUsers    = $Results.Count
$Created       = ($Results | Where-Object { $_.UserCreated -eq $true }).Count
$GroupAssigned = ($Results | Where-Object { $_.GroupAssigned -eq $true }).Count
$SyncAdded     = ($Results | Where-Object { $_.SyncGroupAdded -eq $true }).Count
$Failed        = ($Results | Where-Object { $_.UserCreated -eq $false }).Count
$SyncFailed    = ($Results | Where-Object { $_.SyncGroupAdded -eq $false -and $_.UserCreated -eq $true }).Count

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PROVISIONING SUMMARY — $TicketNumber" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Total Processed      : $TotalUsers"
Write-Host " Users Created        : $Created" -ForegroundColor $(if ($Created -eq $TotalUsers) { "Green" } else { "Red" })
Write-Host " Groups Assigned      : $GroupAssigned" -ForegroundColor $(if ($GroupAssigned -eq $TotalUsers) { "Green" } else { "Red" })
Write-Host " Added to Sync Group  : $SyncAdded" -ForegroundColor $(if ($SyncAdded -eq $TotalUsers) { "Green" } else { "Red" })
Write-Host " User Failures        : $Failed" -ForegroundColor $(if ($Failed -gt 0) { "Red" } else { "Green" })
Write-Host " Sync Group Failures  : $SyncFailed" -ForegroundColor $(if ($SyncFailed -gt 0) { "Red" } else { "Red" })
Write-Host " Duration             : $([math]::Round($Duration, 2)) seconds"
Write-Host " Log File             : $LogFile"
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$Results | Format-Table Timestamp, Department, SAM, Group, UserCreated, GroupAssigned, SyncGroupAdded -AutoSize

# ============================================================
# EXPORT RESULTS TO CSV
# ============================================================

New-Item -ItemType Directory -Force -Path $LogPath | Out-Null

try {
    $Results | Export-Csv -Path $LogFile -NoTypeInformation -ErrorAction Stop
    Write-Host "✅ Results exported to: $LogFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to export results: $_" -ForegroundColor Red
}

# ============================================================
# FAILURE ALERTS
# ============================================================

if ($Failed -gt 0) {
    Write-Host ""
    Write-Host "⚠️  WARNING: $Failed user(s) failed creation." -ForegroundColor Red
    Write-Host "    Use fm-single-user-provision.ps1 to retry individual users." -ForegroundColor Yellow
    $Results | Where-Object { $_.UserCreated -eq $false } |
        Select-Object SAM, Group, Error | Format-Table -AutoSize
}

if ($SyncFailed -gt 0) {
    Write-Host ""
    Write-Host "⚠️  CRITICAL: $SyncFailed user(s) were NOT added to $SyncGroup." -ForegroundColor Red
    Write-Host "    These users will NOT sync to Entra ID." -ForegroundColor Red
    Write-Host "    Run: fm-single-user-remediate.ps1 -Action FixGroup -Group AAD-Sync-Users" -ForegroundColor Yellow
    $Results | Where-Object { $_.SyncGroupAdded -eq $false -and $_.UserCreated -eq $true } |
        Select-Object SAM, Error | Format-Table -AutoSize
}

if ($Failed -eq 0 -and $SyncFailed -eq 0) {
    Write-Host ""
    Write-Host "✅ All users provisioned and added to Entra sync scope." -ForegroundColor Green
    Write-Host "   Proceed to Phase 2 — verify users appear in Entra ID." -ForegroundColor Green
    Write-Host ""
}
'@ | Set-Content -Path "C:\Scripts\Fairmont\fm-bulk-user-provisioning.ps1" -Encoding UTF8