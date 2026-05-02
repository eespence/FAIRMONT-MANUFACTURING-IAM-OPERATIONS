← [Back to Main README](../README.md)

![Active Directory](https://img.shields.io/badge/Active_Directory-0078D4?style=flat&logo=microsoft&logoColor=white)
![Microsoft Entra ID](https://img.shields.io/badge/Microsoft_Entra_ID-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![HashiCorp Vault](https://img.shields.io/badge/HashiCorp_Vault-1.16-black?style=flat&logo=vault&logoColor=white)
![Delinea Secret Server](https://img.shields.io/badge/Delinea-Secret_Server-purple?style=flat)
![Splunk](https://img.shields.io/badge/Splunk-000000?style=flat&logo=splunk&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-SAML_Federation-FF9900?style=flat&logo=amazonaws&logoColor=white)
![CMMC](https://img.shields.io/badge/CMMC-Level_2-blue?style=flat)

**Status:** ✅ Complete

# Lab 01 — Employee Onboarding
## Fairmont Manufacturing LLC — IAM/PAM Operations

**Author:** Edward E. Spence
**Organization:** Fairmont Manufacturing LLC
**Lab:** IAMPAM.LAB
**Repo:** fairmont-manufacturing-iam-operations
**Version:** 1.5
**Last Updated:** 2026-04-09

---

## ⚠️ Simulation Notice

This lab simulates an enterprise Identity and Access Management onboarding workflow. All users, ticket numbers, and organizational data are fictional and created for demonstration purposes. The infrastructure used to execute the workflow is real and includes Active Directory, Microsoft Entra ID, HashiCorp Vault, Delinea Secret Server, Splunk SIEM, and AWS SAML federation.

---

## Identity Lifecycle Context

This lab represents the **JOINER phase** of the Identity Lifecycle:

* Identity creation — Active Directory account provisioning
* Access assignment — Group-based access control enforcement
* Identity synchronization — Entra ID hybrid identity alignment
* Privileged access governance — Vault and Delinea secret control
* Audit and monitoring validation — Splunk activity confirmation

---

## 🎯 Business Scenario

**Organization:** Fairmont Manufacturing LLC
**Industry:** Aerospace Components Manufacturing
**Compliance Context:** CMMC Level 2
**Ticket:** REQ0042001
**Request Type:** New Employee Onboarding — Bulk Provisioning
**Priority:** High
**Submitted By:** HR Director — Marcus Webb
**Assigned To:** IAM Engineering Team

**Ticket Summary:**

> Fairmont Manufacturing is onboarding a new cohort of 10 employees across three departments — Engineering, Finance, and IT/Security. All accounts must be provisioned in Active Directory, synchronized to Microsoft Entra ID, granted appropriate group-based access, and validated across PAM platforms before start date. Secrets must be vaulted in HashiCorp Vault and Delinea Secret Server. All provisioning activity must be logged and visible in Splunk.

Provision 10 employees across Engineering, Finance, and IT/Security with:

- Active Directory accounts
- Entra ID synchronization
- Vault access policies
- Delinea PAM access
- Splunk audit visibility
- AWS federated access

---

## Security Model

* Access is enforced via Active Directory group membership
* Privileged access is controlled through Vault policies and Delinea RBAC
* Standard Fairmount users are not members of rhel-admins and cannot access Linux systems
* This confirms least privilege enforcement across the environment
* Known limitation: SSH access is identity-based not source-restricted at network layer

---

## Onboarding Scope

### Engineering Department — ENG-Users

| Display Name        | SAM Account        | UPN                                                        | Group     |
| ------------------- | ------------------ | ---------------------------------------------------------- | --------- |
| FM - Kira Vanthorpe | fm.kira.vanthorpe  | fm.kira.vanthorpe@fairmontmanufacturing.onmicrosoft.com    | ENG-Users |
| FM - Dalen Wescroft | fm.dalen.wescroft  | fm.dalen.wescroft@fairmontmanufacturing.onmicrosoft.com    | ENG-Users |
| FM - Mira Ashbridge | fm.mira.ashbridge  | fm.mira.ashbridge@fairmontmanufacturing.onmicrosoft.com    | ENG-Users |
| FM - Torin Calloway | fm.torin.calloway  | fm.torin.calloway@fairmontmanufacturing.onmicrosoft.com    | ENG-Users |

### Finance Department — FIN

| Display Name        | SAM Account        | UPN                                                        | Group         |
| ------------------- | ------------------ | ---------------------------------------------------------- | ------------- |
| FM - Brenli Harwick | fm.brenli.harwick  | fm.brenli.harwick@fairmontmanufacturing.onmicrosoft.com    | FIN-Users     |
| FM - Casen Morrow   | fm.casen.morrow    | fm.casen.morrow@fairmontmanufacturing.onmicrosoft.com      | FIN-Users     |
| FM - Lyris Dunvale  | fm.lyris.dunvale   | fm.lyris.dunvale@fairmontmanufacturing.onmicrosoft.com     | FIN-Approvers |
| FM - Orin Tressler  | fm.orin.tressler   | fm.orin.tressler@fairmontmanufacturing.onmicrosoft.com     | FIN-Auditors  |

### IT / Security Department

| Display Name         | SAM Account         | UPN                                                         | Group        |
| -------------------- | ------------------- | ----------------------------------------------------------- | ------------ |
| FM - Seren Holwick   | fm.seren.holwick    | fm.seren.holwick@fairmontmanufacturing.onmicrosoft.com      | IT-Admins    |
| FM - Zael Cortbridge | fm.zael.cortbridge  | fm.zael.cortbridge@fairmontmanufacturing.onmicrosoft.com    | SEC-Analysts |

---

## Environment

**Domain:** IAMPAM.LAB
**Network:** 172.31.100.0/24
**OU Target:** IAMPAM.LAB/IAM-PAM-Users
**Entra Tenant:** FairmontManufacturing.onmicrosoft.com
**Admin Workstation:** MGMT01 (172.31.100.20)

| System     | Role                    | IP            |
| ---------- | ----------------------- | ------------- |
| DC01       | Domain Controller       | 172.31.100.10 |
| MGMT01     | PAW / Admin Workstation | 172.31.100.20 |
| ID-SYNC01  | Entra Connect Sync      | 172.31.100.25 |
| SIEM01     | Splunk Enterprise       | 172.31.100.60 |
| PAMVAULT01 | HashiCorp Vault         | 172.31.100.70 |
| DELINEA01  | Delinea Secret Server   | 172.31.100.80 |
| RHEL01     | Privileged Linux Server | 172.31.100.90 |

---

## Architecture Flow

```text
User → Active Directory → AAD-Sync-Users → Entra ID → Vault / Delinea → Controlled Access → Splunk Audit
```

---

## Tools in Scope

| Tool                  | Purpose                                      |
| --------------------- | -------------------------------------------- |
| Active Directory      | User creation and group assignment           |
| Microsoft Entra ID    | Cloud identity sync and access validation    |
| HashiCorp Vault       | Secret storage and policy assignment         |
| Delinea Secret Server | Privileged access vaulting and governance    |
| Splunk                | Audit logging and onboarding activity review |
| AWS SAML              | Federated access validation                  |
| PowerShell            | Bulk user creation automation                |

---

## ✅ Pre-Checks (MANDATORY)

Run or validate the following before execution:

```powershell
# 1. Domain connectivity to DC01 (LDAP)
Test-NetConnection -ComputerName 172.31.100.10 -Port 389

# 2. Required AD groups exist
Get-ADGroup -Filter * | Where-Object {
    $_.Name -in @(
        "ENG-Users",
        "FIN-Users",
        "FIN-Approvers",
        "FIN-Auditors",
        "IT-Admins",
        "SEC-Analysts",
        "AAD-Sync-Users"
    )
} | Select-Object Name

# 3. Entra Connect delta sync from ID-SYNC01
Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}

# 4. Splunk receiver connectivity
Test-NetConnection -ComputerName 172.31.100.60 -Port 9997

# 5. Vault status
vault status

# 6. Delinea web reachability
Invoke-WebRequest -Uri "https://delinea01.iampam.lab/SecretServer" -UseBasicParsing

# 7. AWS federation check is performed interactively after Entra sync
```

---

## Phase 1 — Active Directory Provisioning

All work in this phase is performed from **MGMT01** as `adm-t0-administrator`.

### Step 01 — Bulk User Creation With Error Handling (PowerShell)

Bulk provisioning was performed with PowerShell and error handling rather than manual one-by-one creation. This ensures failed users do not stop the batch and that each result is logged for remediation. Each user is also added to `AAD-Sync-Users` to scope them for Entra ID synchronization.

```powershell
$users = @(
    @{Name="FM - Kira Vanthorpe";  SAM="fm.kira.vanthorpe";  UPN="fm.kira.vanthorpe@fairmontmanufacturing.onmicrosoft.com";  Group="ENG-Users"},
    @{Name="FM - Dalen Wescroft";  SAM="fm.dalen.wescroft";  UPN="fm.dalen.wescroft@fairmontmanufacturing.onmicrosoft.com";  Group="ENG-Users"},
    @{Name="FM - Mira Ashbridge";  SAM="fm.mira.ashbridge";  UPN="fm.mira.ashbridge@fairmontmanufacturing.onmicrosoft.com";  Group="ENG-Users"},
    @{Name="FM - Torin Calloway";  SAM="fm.torin.calloway";  UPN="fm.torin.calloway@fairmontmanufacturing.onmicrosoft.com";  Group="ENG-Users"},
    @{Name="FM - Brenli Harwick";  SAM="fm.brenli.harwick";  UPN="fm.brenli.harwick@fairmontmanufacturing.onmicrosoft.com";  Group="FIN-Users"},
    @{Name="FM - Casen Morrow";    SAM="fm.casen.morrow";    UPN="fm.casen.morrow@fairmontmanufacturing.onmicrosoft.com";    Group="FIN-Users"},
    @{Name="FM - Lyris Dunvale";   SAM="fm.lyris.dunvale";   UPN="fm.lyris.dunvale@fairmontmanufacturing.onmicrosoft.com";   Group="FIN-Approvers"},
    @{Name="FM - Orin Tressler";   SAM="fm.orin.tressler";   UPN="fm.orin.tressler@fairmontmanufacturing.onmicrosoft.com";   Group="FIN-Auditors"},
    @{Name="FM - Seren Holwick";   SAM="fm.seren.holwick";   UPN="fm.seren.holwick@fairmontmanufacturing.onmicrosoft.com";   Group="IT-Admins"},
    @{Name="FM - Zael Cortbridge"; SAM="fm.zael.cortbridge"; UPN="fm.zael.cortbridge@fairmontmanufacturing.onmicrosoft.com"; Group="SEC-Analysts"}
)

$OU = "OU=IAM-PAM-Users,DC=iampam,DC=lab"
$Password = ConvertTo-SecureString "Welcome@Fairmont2026!" -AsPlainText -Force
$Results = @()

foreach ($user in $users) {
    $result = [PSCustomObject]@{
        SAM         = $user.SAM
        Group       = $user.Group
        UserCreated = $false
        GroupAdded  = $false
        SyncScoped  = $false
        Error       = ""
    }

    # Step 1 — Create user
    try {
        New-ADUser `
            -Name $user.Name `
            -SamAccountName $user.SAM `
            -UserPrincipalName $user.UPN `
            -Path $OU `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        $result.UserCreated = $true
    }
    catch {
        $result.Error = "User creation failed: $_"
    }

    # Step 2 — Assign departmental group and AAD-Sync-Users only if user was created
    if ($result.UserCreated) {
        try {
            Add-ADGroupMember -Identity $user.Group -Members $user.SAM -ErrorAction Stop
            $result.GroupAdded = $true
        }
        catch {
            $result.Error += " | Group assignment failed: $_"
        }

        try {
            Add-ADGroupMember -Identity "AAD-Sync-Users" -Members $user.SAM -ErrorAction Stop
            $result.SyncScoped = $true
        }
        catch {
            $result.Error += " | Sync scope assignment failed: $_"
        }
    }

    $Results += $result
}

# Output results summary
$Results | Format-Table -AutoSize

# Create log directory if it does not exist
New-Item -ItemType Directory -Force -Path "C:\Logs" | Out-Null

# Export results to file for audit
$Results | Export-Csv -Path "C:\Logs\FM-Onboarding-REQ0042001.csv" -NoTypeInformation
Write-Host "Results exported to C:\Logs\FM-Onboarding-REQ0042001.csv" -ForegroundColor Cyan
```

**What this script does:**

* Each user is wrapped in an independent try/catch block
* A failure on one user does not stop remaining users from being provisioned
* Group assignment only runs if user creation succeeded
* Each user is added to `AAD-Sync-Users` to control Entra ID synchronization scope
* All outcomes are captured in a results object tracking UserCreated, GroupAdded, and SyncScoped
* A summary table is printed at the end showing success/failure per user
* Results are exported to a CSV file for audit evidence

### Step 02 — Review Provisioning Results

After the script completes, check the summary table output. Any user showing `UserCreated = False`, `GroupAdded = False`, or `SyncScoped = False` requires individual remediation.

```powershell
Import-Csv "C:\Logs\FM-Onboarding-REQ0042001.csv" |
Where-Object { $_.UserCreated -eq "False" -or $_.GroupAdded -eq "False" -or $_.SyncScoped -eq "False" } |
Format-Table -AutoSize
```

### Step 03 — Verify All Users Created

```powershell
Get-ADUser -Filter {SamAccountName -like "fm.*"} -Properties DisplayName, Enabled |
Select-Object Name, SamAccountName, Enabled |
Sort-Object SamAccountName
```

Expected: 10 accounts returned, all Enabled = True


![Bulk User Provisioning Success](screenshots/lab01_01_bulk_user_provisioning_success.png)

### Step 04 — Verify Group Assignments

```powershell
Get-ADGroupMember -Identity "ENG-Users"     | Where-Object {$_.SamAccountName -like "fm.*"}
Get-ADGroupMember -Identity "FIN-Users"     | Where-Object {$_.SamAccountName -like "fm.*"}
Get-ADGroupMember -Identity "FIN-Approvers" | Where-Object {$_.SamAccountName -like "fm.*"}
Get-ADGroupMember -Identity "FIN-Auditors"  | Where-Object {$_.SamAccountName -like "fm.*"}
Get-ADGroupMember -Identity "IT-Admins"     | Where-Object {$_.SamAccountName -like "fm.*"}
Get-ADGroupMember -Identity "SEC-Analysts"  | Where-Object {$_.SamAccountName -like "fm.*"}
```

---

## Phase 2 — Entra ID Synchronization

After users were created and added to `AAD-Sync-Users`, Entra Connect delta sync was triggered from ID-SYNC01.

### Step 05 — Trigger Delta Sync

From MGMT01:

```powershell
Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}
```

Wait 2-5 minutes then validate.

![Entra Delta Sync](screenshots/lab01_02_entra_delta_sync.png)

### Step 06 — Validate Users in Entra

Navigate to:
`https://entra.microsoft.com` → Users → All Users

Search `fm.` and confirm all 10 users appear with:
- Correct display names
- UPN: `fm.firstname.lastname@fairmontmanufacturing.onmicrosoft.com`
- Source: Windows Server AD

![Entra Users Synced](screenshots/lab01_03_entra_users_synced.png)

### Step 07 — Validate Entra Group Membership

Navigate to: `Entra ID → Groups`

Confirm FM users appear in correct groups:
- ENG-Users → 4 FM users
- FIN-Users → 2 FM users
- FIN-Approvers → 1 FM user
- FIN-Auditors → 1 FM user
- IT-Admins → 1 FM user
- SEC-Analysts → 1 FM user

---

## Phase 3 — AAD-Sync-Users Scope Control (CRITICAL)

`AAD-Sync-Users` is the architectural control group that determines which on-prem identities are eligible for synchronization into Entra ID. This is a core design decision in the lab and was explicitly validated during onboarding.

```powershell
Get-ADGroupMember -Identity "AAD-Sync-Users" | Select-Object Name, SamAccountName
```

This prevents unintended identities from syncing and gives the IAM team explicit control over cloud onboarding scope.

---

## Phase 4 — HashiCorp Vault LDAP Integration

All Vault commands run from MGMT01 via SSH to PAMVAULT01:

```bash
ssh adm-t1-serveradmin@172.31.100.70
```

### Step 08 — Enable and Configure LDAP Authentication

Vault was configured to authenticate against Active Directory through LDAP.

```bash
vault auth enable ldap

vault write auth/ldap/config \
    url="ldap://172.31.100.10" \
    userdn="OU=IAM-PAM-Users,DC=iampam,DC=lab" \
    groupdn="OU=IAM-PAM-Groups,DC=iampam,DC=lab" \
    binddn="CN=adm-t0-administrator,OU=Tier0,OU=PAM,DC=iampam,DC=lab" \
    bindpass="<adm-t0-administrator password>" \
    groupattr="member" \
    userattr="sAMAccountName"
```

⚠️ **Credential Security Note:**
Replace `<adm-t0-administrator password>` with the actual password at execution time.
Never store credentials in plain text in documentation or commit them to a repository.
In a production environment use a dedicated service account with least privilege bind permissions rather than an administrator account.

![Vault LDAP Configured](screenshots/lab01_04_vault_ldap_configured.png)
![Vault LDAP Configured Settings](screenshots/lab01_05_vault_ldap_configured_settings.png)

---

## Phase 5 — Vault RBAC Mapping

### Step 09 — Create Vault Policies

Standard user policy:

```bash
vault policy write fairmont-users - <<EOF
path "secret/data/fairmount/*" {
  capabilities = ["read", "list"]
}
EOF
```

IT-Admins elevated policy:

```bash
vault policy write fairmont-it-admins - <<EOF
path "secret/data/fairmont/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
```

### Step 10 — Map AD Groups to Vault Policies

Vault policies were created and mapped to AD groups to enforce least privilege.

```bash
vault write auth/ldap/groups/IT-Admins    policies=fairmount-it-admins
vault write auth/ldap/groups/ENG-Users    policies=fairmount-users
vault write auth/ldap/groups/FIN-Users    policies=fairmount-users
vault write auth/ldap/groups/SEC-Analysts policies=fairmount-users
```

![Vault Policies Created](screenshots/lab01_06_vault_policies_created.png)
![Vault Group Mapping](screenshots/lab01_07_vault_group_mapping.png)

---

## Phase 6 — Secret Management

### Step 11 — Create Department Secrets

Department-aligned service account credentials were stored as secrets.

```bash
vault kv put secret/fairmont/engineering \
    app_api_key="ENG-2026-FM-API-001" \
    shared_service_account="svc.eng.fairmont"

vault kv put secret/fairmont/finance \
    reporting_key="FIN-2026-FM-RPT-001" \
    audit_service_account="svc.fin.fairmont"

vault kv put secret/fairmont/it \
    admin_token="IT-2026-FM-ADM-001" \
    monitoring_key="svc.it.fairmont"
```

### Step 12 — Validate Secret Access

Validation included successfully reading expected secrets.

```bash
vault kv get secret/fairmont/engineering
vault kv get secret/fairmont/finance
vault kv get secret/fairmont/it
```

![Vault Secrets Created](screenshots/lab01_08_vault_secrets_created.png)
![Vault Secret Read](screenshots/lab01_09_vault_secret_read.png)

---

## Phase 7 — Access Denial Validation

### Step 13 — Confirm Standard Users Cannot Access Privileged Linux Systems

Least privilege was validated by attempting access outside of approved roles.

From MGMT01, attempt SSH as a standard Fairmount user:

```bash
ssh fm.kira.vanthorpe@rhel01.iampam.lab
```

Expected result:

```text
Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)
```

**Why this is expected:**

SSH on RHEL01 is restricted via `AllowGroups rhel-admins`. Fairmont standard users are not members of `rhel-admins` and cannot access privileged Linux systems. This confirms least privilege enforcement is working correctly.

### Step 14 — Confirm Vault Path Isolation

Standard users attempting to access restricted paths should be denied:

```bash
vault kv get secret/fairmont/it
```

Expected for ENG or FIN users: permission denied. Only IT-Admins with the `fairmont-it-admins` policy can read this path.

![SSH Access Denied](screenshots/lab01_10_ssh_denied.png)
![Vault Access Denied](screenshots/lab01_11_vault_access_denied.png)

---

## Phase 8 — Delinea Secret Server PAM Setup

Navigate to `https://delinea01.iampam.lab` from MGMT01.

### Step 15 — Create Fairmont Folder Structure

Navigate to: Secrets → Folders

Department folders were created in Delinea Secret Server and aligned to the Fairmount structure:

- `Fairmont Manufacturing`
  - `Fairmont Manufacturing/Engineering`
  - `Fairmont Manufacturing/Finance`
  - `Fairmont Manufacturing/IT-Security`

![Delinea Folders](screenshots/lab01_12_delinea_folders.png)

---

## Phase 9 — Secret Segmentation in Delinea

### Step 16 — Create Department Secrets

Secrets were placed into the correct department folders.

**Engineering folder:**
- Secret Name: `FM Engineering Service Account`
- Username: `svc.eng.fairmont`
- Password: (generate)

**Finance folder:**
- Secret Name: `FM Finance Reporting Account`
- Username: `svc.fin.fairmont`
- Password: (generate)

**IT-Security folder:**
- Secret Name: `FM IT Admin Account`
- Username: `svc.it.fairmont`
- Password: (generate)

![Engineering Folder Secret](screenshots/lab01_13A_engineering_folder_svc.eng.fairmount.png)
![Finance Folder Secret](screenshots/lab01_13B_finance_folder_svc.fin.fairmount.png)
![IT Security Folder Secret](screenshots/lab01_13C_it_security_folder_svc.it.fairmount.png)

---

## Phase 10 — Delinea RBAC Enforcement

### Step 17 — Assign Group Permissions

Folder-level permissions were assigned using local Delinea groups that mirror the AD structure. Due to Delinea single-user licensing limitations, live multi-user login validation was not possible, but the RBAC design and enforcement were fully implemented.

| Group         | Folder                | Access Level |
| ------------- | --------------------- | ------------ |
| ENG-Users     | Engineering           | Read         |
| FIN-Users     | Finance               | Read         |
| FIN-Approvers | Finance               | Read         |
| FIN-Auditors  | Finance               | Read         |
| IT-Admins     | IT-Security           | Owner        |
| SEC-Analysts  | All Fairmount folders | Read         |

**Note:** Due to licensing constraints in the lab environment, direct Active Directory integration within Delinea Secret Server could not be completed at this stage. To maintain architectural accuracy, AD group structure was replicated within Delinea using local groups. These groups mirror the Active Directory identity model and are used to enforce RBAC at the folder and secret level. This approach simulates real-world identity-to-resource mapping, ensuring that once AD integration is enabled, group synchronization can occur without requiring redesign of access controls.

Expected access behavior:
- ENG-Users → Engineering only
- FIN-Users → Finance only
- IT-Admins → Elevated access
- SEC-Analysts → Read-only security visibility

![Engineering Folder Permissions](screenshots/lab01_14A_engineering_permissions.png)
![Finance Folder Permissions](screenshots/lab01_14B_finance_permissions.png)
![IT Security Folder Permissions](screenshots/lab01_14C_it_security_permissions.png)

---

## Phase 11 — Splunk Audit Validation

Splunk was used to validate both user creation (JOINER lifecycle) and group membership assignment (RBAC enforcement) using Windows Security Event Logs.

### Step 18 — User Creation Validation (Event ID 4720)

On SIEM01:

```spl
index=wineventlog EventCode=4720
| search Account_Name="fm.*"
| table _time, Account_Name, Subject_Account_Name
| sort _time
```

This confirms that all Fairmount users were successfully created in Active Directory by the privileged administrator account.


![Splunk User Creation](screenshots/lab01_15_splunk_user_creation.png)

### Step 19 — Group Membership Validation (Event ID 4728)

```spl
index=wineventlog EventCode=4728 (Group_Name="ENG-Users" OR Group_Name="FIN-Users" OR Group_Name="FIN-Approvers" OR Group_Name="FIN-Auditors" OR Group_Name="IT-Admins" OR Group_Name="SEC-Analysts" OR Group_Name="AAD-Sync-Users")
| rex field=Message "(?i)Member Name:\s+CN=(?<Added_User>[^,]+)"
| table _time, Group_Name, Added_User, Account_Name
| sort _time
```

This validates that each user was added to the correct RBAC group, including departmental groups and the `AAD-Sync-Users` scoping group used for Entra synchronization. The `Added_User` field is extracted directly from the Windows event message to clearly show which identity was assigned to each group.

![Splunk Group Membership](screenshots/lab01_16_splunk_group_membership.png)

### Validation Outcome

All 10 Fairmont users were successfully created and assigned to the correct groups. All actions were performed by the privileged account `adm-t0-administrator`. Splunk visibility confirms that identity lifecycle events are logged, RBAC enforcement is auditable, and the onboarding workflow is traceable end-to-end.

### 🧠 Engineering Note

Windows Event ID 4728 does not expose clean user fields by default. The rex extraction was required to parse the Message field and surface the actual user (Added_User) being added to the group. This reflects real-world SIEM engineering where raw logs must be normalized to produce meaningful, investigation-ready data.

---

## Phase 12 — AWS SAML Access Validation

### Step 20 — Validate Federated Access for IT-Admins

AWS SAML access was validated for the IT-Admins path after identity provisioning and Entra
synchronization. Validation was performed using `fm.seren.holwick` as the IT-Admins
representative identity.

**Validation approach:**

- The AWS SSO User Access URL was used to initiate SAML authentication via Entra ID
- `fm.seren.holwick` successfully authenticated through the Entra ID identity plane
- The browser was redirected to `profile.aws.amazon.com` confirming AWS accepted the
SAML assertion and recognized the identity as `fm.seren.holwick@fairmontmanufacturing.onmicrosoft.com`
- AWS initiated account setup for the identity confirming role mapping is enforced
through the identity plane
- Entra ID Sign-in logs confirmed successful interactive authentication for
`fm.seren.holwick` on 4/17/2026

**Note on Splunk visibility:**
AWS SAML federation events are not captured in `index=wineventlog` as this index only
receives Windows Security Event logs from DC01. Capturing AWS SSO sign-in events in
Splunk would require Entra ID Sign-in log forwarding via Azure Monitor and Event Hub —
this is outside the current lab scope and represents a future logging integration
enhancement.

![Entra Sign-in Success](screenshots/lab01_17_entra_signin_fm.seren.holwick.png)
![AWS SAML Federation](screenshots/lab01_18_aws_saml_fm.seren.holwick.png)

---

## 🔐 RBAC Validation

Because Delinea Secret Server was limited to a single active user under lab licensing,
RBAC validation was performed through:

- Group creation
- Folder-to-group permission assignment
- Secret segregation by department
- Expected access path modeling

This preserves architectural correctness while documenting the licensing limitation honestly.

---

## Rollback Procedures

### Scenario A — Single User Remediation

Use this when a single user needs targeted remediation or rollback.

```powershell
$SAM = "fm.kira.vanthorpe"
$PrimaryGroup = "ENG-Users"

try {
    Remove-ADGroupMember -Identity "AAD-Sync-Users" -Members $SAM -Confirm:$false -ErrorAction Stop
}
catch {
    Write-Host "Failed removing $SAM from AAD-Sync-Users: $_"
}

try {
    Remove-ADGroupMember -Identity $PrimaryGroup -Members $SAM -Confirm:$false -ErrorAction Stop
}
catch {
    Write-Host "Failed removing $SAM from $PrimaryGroup: $_"
}

try {
    Remove-ADUser -Identity $SAM -Confirm:$false -ErrorAction Stop
    Write-Host "✅ Removed user: $SAM" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to remove $SAM — $_" -ForegroundColor Red
}

Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}
```

**Vault and Delinea consideration for single user removal:**

Vault secrets in this lab are stored at department level (`secret/fairmont/engineering`, `secret/fairmont/finance`, `secret/fairmont/it`) not at individual user level. Removing a single user from AD does not require Vault secret deletion. Confirm the removed user no longer has an active Vault token by checking Vault audit logs. For Delinea, since access is group-based, removing the user from the AD group is sufficient — Delinea will reflect the change on next group sync.

---

### Scenario B — Full Bulk Rollback (All Users)

Use this when the entire Fairmont onboarding batch must be reversed.

```powershell
$users = @(
    "fm.kira.vanthorpe",
    "fm.dalen.wescroft",
    "fm.mira.ashbridge",
    "fm.torin.calloway",
    "fm.brenli.harwick",
    "fm.casen.morrow",
    "fm.lyris.dunvale",
    "fm.orin.tressler",
    "fm.seren.holwick",
    "fm.zael.cortbridge"
)

foreach ($user in $users) {
    try {
        Remove-ADGroupMember -Identity "AAD-Sync-Users" -Members $user -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Host "Could not remove $user from AAD-Sync-Users: $_"
    }

    try {
        Remove-ADUser -Identity $user -Confirm:$false -ErrorAction Stop
        Write-Host "✅ Removed: $user" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Could not remove $user — $_ (may not exist)" -ForegroundColor Yellow
    }
}

Invoke-Command -ComputerName ID-SYNC01 -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}
```

**Optional post-rollback cleanup:**
- Remove Vault secrets if onboarding is cancelled:

```bash
vault kv delete secret/fairmont/engineering
vault kv delete secret/fairmont/finance
vault kv delete secret/fairmont/it
```

- Remove Delinea secrets or folders if no longer needed: Navigate to each Fairmont folder in Delinea and delete secrets and folders manually.
- Verify Entra accounts are removed after delta sync: Navigate to `https://entra.microsoft.com` → Users → All Users and search `fm.` to confirm no accounts remain.

---

## Validation Checklist

- AD users created ✔
- Users added to departmental groups ✔
- Users added to `AAD-Sync-Users` ✔
- Provisioning results CSV exported ✔
- All users enabled and in correct OU ✔
- Entra delta sync triggered ✔
- All 10 users visible in Entra ✔
- Entra group membership confirmed ✔
- Vault LDAP auth enabled and configured ✔
- Vault policies created ✔
- AD groups mapped to Vault policies ✔
- Vault secrets created per department ✔
- Unauthorized SSH denied ✔
- Unauthorized Vault secret access denied ✔
- Delinea folder structure created ✔
- Delinea secrets mapped ✔
- Delinea folder permissions assigned ✔
- Splunk audit queries validated ✔
- AWS federation path validated ✔

---

## CMMC Level 2 Alignment

| Practice   | Control                                   | Evidence                                           |
| ---------- | ----------------------------------------- | -------------------------------------------------- |
| AC.1.001   | Limit system access to authorized users   | AD group-based access control                      |
| AC.2.006   | Use non-privileged accounts               | Standard Fairmount users have no admin rights      |
| AC.2.007   | Limit privileged account use              | IT-Admins only for elevated access                 |
| IA.3.083   | Use multifactor authentication            | Entra ID identity plane and federated controls     |
| AU.2.041   | Audit user management actions             | Splunk Event ID 4720 and 4728 visibility           |
| CM.2.061   | Establish baseline configurations         | Vault policies and Delinea RBAC model              |

---

## Engineering Notes

- `AAD-Sync-Users` is required to control which on-prem identities are synchronized to Entra ID
- The Entra UPN namespace must be routable and aligned to the tenant namespace (`fairmontmanufacturing.onmicrosoft.com`)
- All user creation performed from MGMT01 per PAW model
- `fm.` prefix ensures lab users are clearly distinguishable from existing accounts
- All user names are entirely fictional — no real individuals referenced
- Password set to `Welcome@Fairmont2026!` with forced change at next logon
- Error handling in the creation script ensures partial failures do not go undetected
- Provisioning results are exported to CSV for audit trail — now tracks UserCreated, GroupAdded, and SyncScoped
- Vault LDAP binddn must match actual adm-t0-administrator OU path in your environment
- Vault policies scoped to `secret/fairmont/*` to isolate Fairmount secrets
- Delinea folder structure mirrors department hierarchy for clean RBAC
- Vault LDAP integration depends on a valid bind account and correct OU paths
- Standard users are intentionally denied SSH access to privileged Linux systems to validate least privilege
- Privileged service accounts are stored as secrets, not used as interactive user identities
- Delinea licensing imposed a single-user limitation, so RBAC enforcement was validated through configuration and design rather than live multi-user testing
- Group-based access control was intentionally mirrored across AD, Vault, and Delinea to keep the architecture consistent
- Entra sync may take 2-5 minutes after delta sync trigger
- Removing AD users does not immediately remove Entra accounts — always re-run delta sync after any rollback

---

## Ticket Resolution

**Ticket:** REQ0042001
**Status:** Resolved
**Resolution:** All 10 Fairmont Manufacturing employee accounts provisioned across Active Directory, Microsoft Entra ID, HashiCorp Vault, and Delinea Secret Server. Group-based access control enforced per department. All users scoped for Entra synchronization via AAD-Sync-Users. Vault LDAP integration maps AD group membership to secret access policies. Delinea RBAC enforced at folder level. Least privilege validated — standard users denied privileged system and secret access. All provisioning activity logged and confirmed in Splunk. AWS federated access confirmed for IT-Admins. Provisioning results exported to CSV for audit evidence. Accounts ready for employee start date.

---

## Final Outcome

```text
User → Group → AAD-Sync-Users → Entra ID → Vault / Delinea → Controlled Access → Splunk Audit
```

This lab demonstrates a complete JOINER lifecycle implementation with IAM, PAM, audit validation, and cloud identity synchronization.

---

## Next Lab

[Lab 02 — Incident Response: Anomalous Admin Behavior](../lab-02-incident-response/lab-02-incident-response.md)

---

**E.E. Spence — IAM/PAM Engineering | Fairmont Manufacturing LLC**