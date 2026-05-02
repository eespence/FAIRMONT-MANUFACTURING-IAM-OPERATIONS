# Incident Response — Anomalous Admin Behavior

**Lab:** IAMPAM.LAB | **Ticket:** INC0043102 | **Status:** ✅ Complete | **Last Updated:** April 2026

---

Identity is one of the most targeted attack surfaces in enterprise environments. When a privileged account starts behaving anomalously — logging in from unexpected systems, generating failed authentication events, or accessing resources outside its normal pattern — the response needs to be fast, structured, and fully auditable.

This lab simulates a real-world identity security incident at Fairmount Manufacturing LLC. Splunk detected suspicious privileged account activity for `adm-t1-serveradmin` — a Tier 1 server administrator account that began generating anomalous login behavior including authentication attempts from an unauthorized system. The full IR lifecycle was executed — detection, investigation, containment, and validation.

---

## Incident Overview

**Organization:** Fairmount Manufacturing LLC
**Ticket:** INC0043102
**Severity:** High
**Type:** Suspicious Privileged Activity
**Account:** `adm-t1-serveradmin`

> Splunk detected anomalous login behavior from a privileged account including authentication attempts from unexpected systems and elevated privilege usage.

---

## Incident Workflow

```text
Detection → Investigation → Containment → Validation → Audit
```

---

## Architectural Note — Privileged Accounts and Entra ID

Privileged tier accounts in this environment are intentionally excluded from Microsoft Entra ID synchronization. This is a deliberate security architecture decision aligned with Microsoft's Enterprise Access Model:

- **Tier 1** accounts (`adm-t1-*`) — Server administrators. On-premises AD only. Never synced to Entra ID.

This means all containment actions — account disable, group removal, credential reset — are performed entirely within Active Directory. No Entra ID synchronization is required or appropriate for privileged tier accounts.

---

## Phase 1 — Detection

Splunk identified anomalous login behavior for `adm-t1-serveradmin` across Windows Security Event IDs 4624, 4625, and 4672 — covering successful logins, failed logins, and privileged logon events respectively.

**2,135 events** were returned — with a highlighted row showing a failed logon from CLIENT01 at an unexpected source IP confirming unauthorized access was attempted.

[ SCREENSHOT: lab02_01_suspicious_logins ]

---

## Phase 2 — Investigation

### Login Source Identified

Failed logons were traced to CLIENT01 — a Tier 2 workstation that `adm-t1-serveradmin` should never be authenticating from. This cross-tier authentication attempt is a direct violation of the tier isolation model enforced by Group Policy.

[ SCREENSHOT: lab02_02_login_source ]

### Privilege Escalation Activity Confirmed

Privileged logon events confirmed the account has elevated access and was actively using it during the suspicious activity window.

[ SCREENSHOT: lab02_03_privilege_escalation ]

---

## Phase 3 — Containment

All containment actions were performed within Active Directory on MGMT01 as `adm-t0-administrator`.

### Account Disabled

```powershell
Disable-ADAccount -Identity "adm-t1-serveradmin"
```

Verified: `Enabled = False`

[ SCREENSHOT: lab02_04_account_disabled ]

### Group Membership Removed

```powershell
Remove-ADGroupMember -Identity "IT-Admins" -Members "adm-t1-serveradmin" -Confirm:$false
```

Verified: No results returned confirming removal from IT-Admins.

[ SCREENSHOT: lab02_05_group_removal ]

### Credentials Reset

```powershell
Set-ADAccountPassword -Identity "adm-t1-serveradmin" `
    -NewPassword (ConvertTo-SecureString "Incident@Reset2026!" -AsPlainText -Force) `
    -Reset

Set-ADUser -Identity "adm-t1-serveradmin" -ChangePasswordAtLogon $true
```

[ SCREENSHOT: lab02_06_password_reset ]

---

## Phase 4 — Validation

Post-containment Splunk query confirmed no further privileged logon events for `adm-t1-serveradmin` within the one-hour window following containment:

- No new Event ID 4672 — privileged logon events
- Remaining Event ID 4624 events limited to DC01 via Logon Type 3 — network authentication consistent with background system processes not interactive sessions
- No lateral movement detected

[ SCREENSHOT: lab02_07_post_containment ]

---

## MITRE ATT&CK Alignment

| Technique | Description |
|---|---|
| T1078 | Valid Accounts |
| T1550 | Use of Alternate Authentication Material |
| T1021 | Remote Services |

---

## CMMC Level 2 Alignment

| Practice | Control | Evidence |
|---|---|---|
| AU.2.041 | Audit user management actions | Splunk Event ID 4624 4625 4672 visibility |
| AU.2.042 | Review and analyze audit logs | SPL investigation queries |
| IR.2.092 | Establish incident handling capability | Full IR lifecycle — detect investigate contain validate |
| IR.2.093 | Track and document incidents | INC0043102 full audit trail |
| AC.2.007 | Limit privileged account use | adm-t1-serveradmin removed from IT-Admins |

---

## Ticket Resolution

**Ticket:** INC0043102 — **Status:** Resolved

Anomalous privileged account activity detected for `adm-t1-serveradmin` via Splunk SIEM. Investigation confirmed unauthorized login attempts originating from CLIENT01 with elevated privilege usage. Account disabled, removed from IT-Admins, and credentials reset within Active Directory. No Entra ID synchronization required — privileged tier accounts are intentionally excluded from cloud identity synchronization per enterprise PAM architecture. Post-containment validation confirmed no further privileged logon events. No lateral movement detected. Incident fully contained and documented.

---

## Why This Matters

A privileged account authenticating from a Tier 2 workstation is not just a policy violation — it is a potential indicator of credential theft, pass-the-hash, or insider threat. Without SIEM visibility this activity goes undetected. Without a structured IR workflow the response is slow and incomplete. This lab demonstrates that detection, investigation, containment, and validation can be executed in a repeatable, auditable workflow — exactly what enterprise incident response requires.

---

👉 **[View Full Lab on GitHub](https://github.com/eespence/fairmount-manufacturing-iam-operations)**

---

**E.E. Spence — IAM/PAM Engineering | Fairmount Manufacturing LLC**