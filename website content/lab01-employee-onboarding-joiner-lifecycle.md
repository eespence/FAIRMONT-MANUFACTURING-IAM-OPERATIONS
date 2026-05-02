# Employee Onboarding — JOINER Lifecycle

**Lab:** IAMPAM.LAB | **Ticket:** REQ0042001 | **Status:** ✅ Complete | **Last Updated:** April 2026

---

Enterprise identity onboarding is not just creating user accounts. It is a coordinated lifecycle operation that spans Active Directory provisioning, cloud identity synchronization, least privilege validation, audit logging, and federated cloud access — all executed in the correct sequence with full error handling and audit evidence.

This lab simulates the JOINER phase of the identity lifecycle for Fairmount Manufacturing LLC — a fictional aerospace components manufacturer operating under CMMC Level 2 compliance requirements. 10 employees are onboarded across Engineering, Finance, and IT/Security using real enterprise infrastructure.

---

## Business Scenario

**Organization:** Fairmount Manufacturing LLC
**Industry:** Aerospace Components Manufacturing
**Compliance:** CMMC Level 2
**Ticket:** REQ0042001 — New Employee Onboarding — Bulk Provisioning
**Submitted By:** HR Director — Marcus Webb

> Fairmount Manufacturing is onboarding 10 employees across Engineering, Finance, and IT/Security. All accounts must be provisioned in Active Directory, synchronized to Entra ID, granted group-based access, and validated across PAM platforms before start date.

---

## Architecture Flow

```text
User → Active Directory → AAD-Sync-Users → Entra ID → Controlled Access → Splunk Audit
```

---

## Onboarding Scope

| Department | Users | Groups |
|---|---|---|
| Engineering | 4 | ENG-Users |
| Finance | 4 | FIN-Users, FIN-Approvers, FIN-Auditors |
| IT / Security | 2 | IT-Admins, SEC-Analysts |

---

## Phase 1 — Active Directory Provisioning

Bulk provisioning was performed using PowerShell with independent try/catch error handling — ensuring a failure on one user does not stop the remaining batch. Each user is tracked across three states: UserCreated, GroupAdded, and SyncScoped. Results are exported to CSV for audit evidence.

Key script behaviors:
- Each user wrapped in an independent try/catch block
- Group assignment only runs if user creation succeeded
- Every user added to `AAD-Sync-Users` to scope Entra synchronization
- Full results table printed on completion
- CSV exported to `C:\Logs\FM-Onboarding-REQ0042001.csv`

[ SCREENSHOT: lab01_01_bulk_user_provisioning_success ]

---

## Phase 2 — Entra ID Synchronization

After all users were created and added to `AAD-Sync-Users`, Entra Connect delta sync was triggered from ID-SYNC01.

`AAD-Sync-Users` is the architectural control group that determines which on-prem identities are eligible for cloud synchronization — preventing unintended identities from reaching Entra ID and giving the IAM team explicit control over cloud onboarding scope.

All 10 FM users were validated in Entra with correct display names, UPNs, and group membership confirmed.

[ SCREENSHOT: lab01_02_entra_delta_sync ]

[ SCREENSHOT: lab01_03_entra_users_synced ]

---

## Phase 3 — AAD-Sync-Users Scope Control

`AAD-Sync-Users` was validated to confirm all 10 FM users are scoped for Entra synchronization and no unintended identities were included.

This is a core architectural decision — privileged tier accounts are intentionally excluded from this group and never synchronized to Entra ID by design.

---

## Phase 4 — Access Denial Validation

Least privilege was validated by confirming standard Fairmount users cannot access privileged Linux systems or restricted Vault secret paths.

**SSH to RHEL01 as a standard FM user:**
```text
Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)
```

This is expected — SSH on RHEL01 is restricted via `AllowGroups rhel-admins`. FM standard users are not members of `rhel-admins` and cannot access privileged Linux systems. This confirms least privilege enforcement is working correctly across the environment.

[ SCREENSHOT: lab01_10_ssh_denied ]

[ SCREENSHOT: lab01_11_vault_access_denied ]

---

## Phase 5 — Splunk Audit Validation

Splunk was used to confirm all provisioning activity is logged and auditable using Windows Security Event Logs from DC01.

**User creation confirmed — Event ID 4720:**
All 10 FM users confirmed created by `adm-t0-administrator`.

[ SCREENSHOT: lab01_15_splunk_user_creation ]

**Group membership confirmed — Event ID 4728:**
Rex field extraction was required to parse the Message field and surface the `Added_User` from raw event data — reflecting real-world SIEM engineering where logs must be normalized to produce investigation-ready output. All users confirmed in correct departmental groups and `AAD-Sync-Users`.

[ SCREENSHOT: lab01_16_splunk_group_membership ]

---

## Phase 6 — AWS SAML Federation Validation

AWS SAML access was validated for `fm.seren.holwick` as the IT-Admins representative identity. The browser was redirected to `profile.aws.amazon.com` confirming AWS accepted the SAML assertion and recognized the identity through the Entra ID identity plane. Entra ID Sign-in logs confirmed successful interactive authentication on 4/17/2026.

**Note:** AWS SAML federation events are not captured in `index=wineventlog`. Capturing these events in Splunk would require Entra ID Sign-in log forwarding via Azure Monitor and Event Hub — outside the current lab scope and documented as a future logging integration enhancement.

[ SCREENSHOT: lab01_17_entra_signin_fm.seren.holwick ]

[ SCREENSHOT: lab01_18_aws_saml_fm.seren.holwick ]

---

## CMMC Level 2 Alignment

| Practice | Control | Evidence |
|---|---|---|
| AC.1.001 | Limit system access to authorized users | AD group-based access control |
| AC.2.006 | Use non-privileged accounts | Standard FM users have no admin rights |
| AC.2.007 | Limit privileged account use | IT-Admins only for elevated access |
| IA.3.083 | Use multifactor authentication | Entra ID identity plane and federated controls |
| AU.2.041 | Audit user management actions | Splunk Event ID 4720 and 4728 visibility |

---

## Ticket Resolution

**Ticket:** REQ0042001 — **Status:** Resolved

All 10 Fairmount Manufacturing employee accounts provisioned in Active Directory, synchronized to Microsoft Entra ID, and group-based access control enforced per department. Least privilege validated — standard users denied privileged system access. All provisioning activity confirmed in Splunk. AWS federated access confirmed for IT-Admins. Provisioning results exported to CSV for audit evidence.

---

## Why This Matters

Most organizations onboard employees through manual processes with no audit trail and no validation that access controls were actually applied correctly. This lab demonstrates a repeatable, automated, auditable onboarding workflow — from AD account creation to cloud identity synchronization to SIEM confirmation. Every step is documented, validated, and traceable.

---

👉 **[View Full Lab on GitHub](https://github.com/eespence/fairmount-manufacturing-iam-operations)**

---

**E.E. Spence — IAM/PAM Engineering | Fairmount Manufacturing LLC**