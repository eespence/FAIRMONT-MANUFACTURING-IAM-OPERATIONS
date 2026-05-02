![Active Directory](https://img.shields.io/badge/Active_Directory-0078D4?style=flat&logo=microsoft&logoColor=white)
![Microsoft Entra ID](https://img.shields.io/badge/Microsoft_Entra_ID-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![HashiCorp Vault](https://img.shields.io/badge/HashiCorp_Vault-1.16-black?style=flat&logo=vault&logoColor=white)
![Delinea Secret Server](https://img.shields.io/badge/Delinea-Secret_Server-purple?style=flat)
![Splunk](https://img.shields.io/badge/Splunk-000000?style=flat&logo=splunk&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-SAML_Federation-FF9900?style=flat&logo=amazonaws&logoColor=white)
![CMMC](https://img.shields.io/badge/CMMC-Level_2-blue?style=flat)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=flat&logo=powershell&logoColor=white)

# fairmont-manufacturing-iam-operations

**Author:** Edward E. Spence
**Organization:** Fairmont Manufacturing LLC
**Lab Environment:** IAMPAM.LAB
**Status:** 🟢 Active — Labs In Progress

---

## ⚠️ Simulation Notice

All labs in this repository simulate enterprise Identity and Access Management and Privileged Access Management workflows. All users, ticket numbers, and organizational data are entirely fictional and created for demonstration purposes only. The infrastructure used to execute these workflows is real and fully operational within the IAMPAM.LAB environment.

---

## 🎯 About This Repository

This repository documents hands-on IAM/PAM engineering operations built on a fully operational enterprise lab environment. Each lab simulates a real-world scenario that an IAM/PAM engineer would encounter in production — from identity lifecycle management to security incident response.

This is not a certification study guide. Every lab is executed on real infrastructure and validated end to end with screenshots, audit logs, and documented outcomes.

In addition to lab documentation, this repository includes a standalone automation library of reusable PowerShell scripts built from the lab workflows. These scripts are production-ready templates for bulk provisioning, single user remediation, and full rollback operations — demonstrating that the engineering work done in the labs translates directly into reusable operational tooling.

---

## 🏗️ Lab Environment — IAMPAM.LAB

**Domain:** IAMPAM.LAB
**Network:** 172.31.100.0/24
**Entra Tenant:** FairmontManufacturing.onmicrosoft.com
**Compliance Context:** CMMC Level 2

| System | Role | IP |
|---|---|---|
| DC01 | Domain Controller | 172.31.100.10 |
| MGMT01 | PAW / Admin Workstation | 172.31.100.20 |
| ID-SYNC01 | Entra Connect Sync | 172.31.100.25 |
| SIEM01 | Splunk Enterprise | 172.31.100.60 |
| PAMVAULT01 | HashiCorp Vault | 172.31.100.70 |
| DELINEA01 | Delinea Secret Server | 172.31.100.80 |
| RHEL01 | Privileged Linux Server | 172.31.100.90 |

---

## 🔐 Privileged Account Architecture

Privileged tier accounts in this environment are intentionally excluded from Microsoft Entra ID synchronization. This is a deliberate security architecture decision aligned with Microsoft's Enterprise Access Model:

- **Tier 0** (`adm-t0-*`) — Domain and identity plane administrators. On-premises AD only. Never synced to Entra ID.
- **Tier 1** (`adm-t1-*`) — Server and workload administrators. On-premises AD only. Never synced to Entra ID.
- **Tier 2** (`adm-t2-*`) — Workstation administrators. On-premises AD only. Never synced to Entra ID.

Standard user identities (`fm.*`) are synchronized to Entra ID via the `AAD-Sync-Users` scoping group and are subject to cloud identity governance, SAML federation, and Entra-based access controls.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Active Directory | Identity creation, group-based access control, tier enforcement |
| Microsoft Entra ID | Cloud identity synchronization, SAML federation, sign-in governance |
| HashiCorp Vault | Secret storage, LDAP authentication, policy-based access control |
| Delinea Secret Server | PAM vaulting, folder-based RBAC, privileged credential governance |
| Splunk Enterprise | SIEM — audit logging, event investigation, threat detection |
| AWS SAML | Federated cloud access for privileged identity groups |
| PowerShell | Automation — bulk provisioning, containment, rollback |
| Group Policy | Tier isolation enforcement, logon restrictions |

---

## ⚙️ Automation Library

The `automation/` folder contains standalone reusable PowerShell scripts extracted and refined from the lab workflows. These are production-ready operational templates that can be adapted for real enterprise environments.

| Script | Purpose |
|---|---|
| `fm-bulk-user-provisioning.ps1` | Bulk AD user creation with error handling, group assignment, AAD-Sync-Users scoping, and CSV audit export |
| `fm-bulk-user-rollback.ps1` | Full batch rollback — removes all provisioned users from AD groups, AAD-Sync-Users, and deletes accounts with Entra delta sync |
| `fm-single-user-provision.ps1` | Single user provisioning template with targeted group assignment and sync scoping |
| `fm-single-user-remediate.ps1` | Single user remediation — targeted group removal, account disable or delete, and Entra sync trigger |

👉 [View Automation Scripts](automation/)

---

## 📁 Lab Index

### ✅ Lab 01 — Employee Onboarding (JOINER Phase)
**Ticket:** REQ0042001 | **Status:** ✅ Complete

Provision 10 new Fairmont Manufacturing employees across Engineering, Finance, and IT/Security. Covers full identity lifecycle from AD account creation through Entra ID synchronization, Vault secret access, Delinea PAM governance, least privilege validation, Splunk audit confirmation, and AWS SAML federation.

**Key Skills Demonstrated:**
- Bulk AD provisioning with PowerShell error handling
- AAD-Sync-Users scope control for Entra ID
- Vault LDAP integration and RBAC policy mapping
- Delinea folder-based secret governance
- Splunk SIEM audit validation with rex field extraction
- AWS SAML federated access validation

👉 [View Lab 01 README](lab-01-onboarding/README.md)

---

### ✅ Lab 02 — Incident Response: Anomalous Admin Behavior
**Ticket:** INC0043102 | **Status:** ✅ Complete

Detect, investigate, contain, and validate a suspicious privileged account activity incident. `adm-t1-serveradmin` exhibited anomalous login behavior including unauthorized authentication attempts from CLIENT01 and elevated privilege usage. Full incident response lifecycle executed using Splunk SIEM, Active Directory, and PowerShell IAM controls.

**Key Skills Demonstrated:**
- SIEM-driven threat detection using Windows Event IDs 4624, 4625, 4672
- Attack source identification and investigation
- IAM-based containment — account disable, group removal, credential reset
- Post-containment validation via Splunk
- MITRE ATT&CK alignment — T1078, T1550, T1021
- Break-glass GPO scenario documentation

👉 [View Lab 02 README](lab-02-incident-response/README.md)

---

## 🛡️ CMMC Level 2 Coverage

| Practice | Control | Lab Coverage |
|---|---|---|
| AC.1.001 | Limit system access to authorized users | Lab 01 — AD group-based access control |
| AC.2.006 | Use non-privileged accounts | Lab 01 — Standard FM users have no admin rights |
| AC.2.007 | Limit privileged account use | Lab 01 & 02 — IT-Admins only, adm-t1 contained |
| IA.3.083 | Use multifactor authentication | Lab 01 — Entra ID identity plane and federated controls |
| AU.2.041 | Audit user management actions | Lab 01 & 02 — Splunk Event ID visibility |
| AU.2.042 | Review and analyze audit logs | Lab 02 — SPL investigation queries |
| IR.2.092 | Establish incident handling capability | Lab 02 — Full IR lifecycle |
| IR.2.093 | Track and document incidents | Lab 02 — INC0043102 full audit trail |
| CM.2.061 | Establish baseline configurations | Lab 01 — Vault policies and Delinea RBAC |

---

## 🗂️ Repository Structure

```text
fairmont-manufacturing-iam-operations/
├── README.md                                    ← You are here
├── automation/                                  ← Reusable PowerShell scripts
│   ├── fm-bulk-user-provisioning.ps1
│   ├── fm-bulk-user-rollback.ps1
│   ├── fm-single-user-provision.ps1
│   └── fm-single-user-remediate.ps1
├── lab-01-onboarding/
│   ├── README.md
│   ├── lab-01-employee-onboarding.md
│   └── screenshots/
│       ├── lab01_01_bulk_user_provisioning_success.png
│       ├── lab01_02_entra_delta_sync.png
│       ├── lab01_03_entra_users_synced.png
│       ├── lab01_04_vault_ldap_configured.png
│       ├── lab01_05_vault_ldap_configured_settings.png
│       ├── lab01_06_vault_policies_created.png
│       ├── lab01_07_vault_group_mapping.png
│       ├── lab01_08_vault_secrets_created.png
│       ├── lab01_09_vault_secret_read.png
│       ├── lab01_10_ssh_denied.png
│       ├── lab01_11_vault_access_denied.png
│       ├── lab01_12_delinea_folders.png
│       ├── lab01_13A_engineering_folder_svc.eng.fairmount.png
│       ├── lab01_13B_finance_folder_svc.fin.fairmount.png
│       ├── lab01_13C_it_security_folder_svc.it.fairmount.png
│       ├── lab01_14A_engineering_permissions.png
│       ├── lab01_14B_finance_permissions.png
│       ├── lab01_14C_it_security_permissions.png
│       ├── lab01_15_splunk_user_creation.png
│       ├── lab01_16_splunk_group_membership.png
│       ├── lab01_17_entra_signin_fm.seren.holwick.png
│       └── lab01_18_aws_saml_fm.seren.holwick.png
├── lab-02-incident-response/
│   ├── README.md
│   ├── lab-02-incident-response.md
│   └── screenshots/
│       ├── lab02_01_suspicious_logins.png
│       ├── lab02_02_login_source.png
│       ├── lab02_03_privilege_escalation.png
│       ├── lab02_04_account_disabled.png
│       ├── lab02_05_group_removal.png
│       ├── lab02_06_password_reset.png
│       └── lab02_07_post_containment.png
```

---

## 🔮 What's Next

| Lab | Scenario | Status |
|---|---|---|
| Lab 03 | Access Review & Certification | 🔄 In Development |
| Lab 04 | Privileged Account Lifecycle — MOVER Phase | 🔄 In Development |
| Lab 05 | LEAVER — Account Offboarding & Deprovisioning | 🔄 In Development |

---

**E.E. Spence — Identity Engineering | IAMPAM.LAB**