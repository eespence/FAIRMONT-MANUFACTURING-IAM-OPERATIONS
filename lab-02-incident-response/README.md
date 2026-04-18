← [Back to Main README](../README.md)

![Active Directory](https://img.shields.io/badge/Active_Directory-0078D4?style=flat&logo=microsoft&logoColor=white)
![Microsoft Entra ID](https://img.shields.io/badge/Microsoft_Entra_ID-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![HashiCorp Vault](https://img.shields.io/badge/HashiCorp_Vault-1.16-black?style=flat&logo=vault&logoColor=white)
![Delinea Secret Server](https://img.shields.io/badge/Delinea-Secret_Server-purple?style=flat)
![Splunk](https://img.shields.io/badge/Splunk-000000?style=flat&logo=splunk&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-SAML_Federation-FF9900?style=flat&logo=amazonaws&logoColor=white)
![CMMC](https://img.shields.io/badge/CMMC-Level_2-blue?style=flat)

# Lab 02 — Incident Response (DETECT → RESPOND → VALIDATE)

**Author:** Edward E. Spence
**Organization:** Fairmount Manufacturing LLC
**Lab:** IAMPAM.LAB
**Version:** 1.1
**Status:** ✅ Complete

---

## ⚠️ Simulation Notice

This lab simulates a real-world security incident involving anomalous administrative activity within a hybrid identity environment. All identities and events are fictional but executed on real infrastructure including Active Directory, Splunk SIEM, and Group Policy.

---

## 🎯 Objective

This lab simulates a real-world identity security incident involving anomalous privileged account behavior. The goal is to demonstrate the ability to detect, investigate, contain, and validate identity-based threats using SIEM visibility and IAM controls.

---

## 🧠 Scenario Overview

**Ticket:** INC0043102
**Severity:** High
**Type:** Suspicious Privileged Activity

Splunk detected abnormal login behavior from the privileged account:

```text
adm-t1-serveradmin
```

Activity included:

* Authentication attempts from unauthorized systems
* Failed logon activity from CLIENT01
* Privileged logon events requiring investigation

---

## 🔐 Security Focus

* Privileged account misuse detection
* SIEM-driven investigation workflow
* RBAC enforcement under incident conditions
* Identity-based containment actions
* Full audit visibility and traceability

---

## 🔄 Incident Workflow

```text
Detection → Investigation → Containment → Validation → Audit
```

---

## 🛠️ Tools & Technologies

* Active Directory Domain Services
* Microsoft Entra ID
* Splunk Enterprise (SIEM01)
* HashiCorp Vault
* Delinea Secret Server
* PowerShell
* Group Policy

---

## 🏗️ Architectural Design Note — Privileged Accounts and Entra ID

> **By design, privileged tier accounts (Tier 0, Tier 1, Tier 2) in this environment are intentionally excluded from Microsoft Entra ID synchronization.**

This is a deliberate security architecture decision aligned with Microsoft's Enterprise Access Model and PAM best practices:

- **Tier 0** accounts (`adm-t0-*`) — Domain and identity plane administrators. Exist only in on-premises Active Directory. Never synchronized to Entra ID.
- **Tier 1** accounts (`adm-t1-*`) — Server and workload administrators. Exist only in on-premises Active Directory. Never synchronized to Entra ID.
- **Tier 2** accounts (`adm-t2-*`) — Workstation administrators. Exist only in on-premises Active Directory. Never synchronized to Entra ID.

Synchronizing privileged accounts to Entra ID would expose them to cloud-based attack surfaces including token theft, OAuth abuse, and identity plane compromise. Keeping privileged accounts strictly on-premises enforces:

- Hard boundary between cloud and privileged identity planes
- Elimination of cloud-based lateral movement paths for privileged identities
- Compliance with least privilege and separation of duties principles

**Containment actions for privileged accounts (disable, group removal, credential reset) are performed entirely within Active Directory and do not require Entra ID synchronization.** The on-premises AD remains the authoritative identity source for all privileged tiers.

---

## 🔍 What This Lab Demonstrates

* Detection of suspicious privileged activity using Splunk
* Investigation of Windows Event Logs (4624, 4625, 4672)
* Identification of attack source (CLIENT01)
* Enforcement of IAM controls (disable, remove, reset)
* Validation of containment effectiveness
* Understanding of GPO impact on access control

---

## ⚠️ Engineering Note — Controlled Policy Adjustment

During containment, a temporary adjustment was made to:

```text
GPO-Tier1-Logon-Restrictions
```

This allowed **PAM-Tier0-Admins** interactive access to MGMT01 to perform administrative validation.

This simulates a real-world:

> Break-glass administrative access scenario

Default security posture enforces:

* Tier 0 → Identity systems only
* Tier 1 → Servers
* Tier 2 → Workstations

This change should be reverted after incident validation to maintain proper tier isolation.

---

## 📸 Lab Execution Summary

**Phase 1 — Detection**
Splunk identified anomalous login behavior for `adm-t1-serveradmin` across Event IDs 4624, 4625, and 4672.

![Suspicious Login Activity](screenshots/lab02_01_suspicious_logins.png)

**Phase 2 — Investigation**
Login source identified as CLIENT01. Privilege escalation activity confirmed.

![Login Source Analysis](screenshots/lab02_02_login_source.png)
![Privilege Escalation](screenshots/lab02_03_privilege_escalation.png)

**Phase 3 — Containment**
Account disabled, removed from IT-Admins, and credentials reset within Active Directory.

![Account Disabled](screenshots/lab02_04_account_disabled.png)
![Group Removal](screenshots/lab02_05_group_removal.png)
![Password Reset](screenshots/lab02_06_password_reset.png)

**Phase 4 — Validation**
Post-containment Splunk query confirmed no further privileged logon events.

![Post Containment](screenshots/lab02_07_post_containment.png)

---

## 📊 MITRE ATT&CK Alignment

| Technique | Description |
| --------- | ----------- |
| T1078 | Valid Accounts |
| T1550 | Use of Alternate Authentication Material |
| T1021 | Remote Services |

---

## 🛡️ CMMC Level 2 Alignment

| Practice | Control | Evidence |
|---|---|---|
| AU.2.041 | Audit user management actions | Splunk Event ID 4624, 4625, 4672 visibility |
| AU.2.042 | Review and analyze audit logs | Splunk SPL investigation queries |
| IR.2.092 | Establish incident handling capability | Structured detection, investigation, containment, validation workflow |
| IR.2.093 | Track and document incidents | INC0043102 ticket with full audit trail |
| AC.2.007 | Limit privileged account use | adm-t1-serveradmin removed from IT-Admins |
| IA.3.083 | Use multifactor authentication | Entra ID identity plane enforced for standard user identities |

---

## 📊 Validation Checklist

- Suspicious login detected ✔
- Source identified ✔
- Privilege escalation analyzed ✔
- Account disabled ✔
- Group membership removed ✔
- Credentials reset ✔
- Post-containment validation confirmed ✔

---

## 🧠 Key Takeaways

* Identity is a primary attack surface
* SIEM enables rapid detection of anomalies
* Privileged access must be tightly controlled
* RBAC enforcement reduces blast radius
* Validation is critical in incident response
* Policy design directly impacts security posture
* Privileged tier accounts are intentionally excluded from Entra ID synchronization — containment is performed entirely within on-premises Active Directory by design

---

## Ticket Resolution

**Ticket:** INC0043102
**Status:** Resolved
**Resolution:** Anomalous privileged account activity detected for `adm-t1-serveradmin` via Splunk SIEM. Investigation confirmed unauthorized login attempts originating from CLIENT01 with elevated privilege usage. Account was disabled, removed from IT-Admins group, and credentials were reset within Active Directory. No Entra ID synchronization was required as privileged tier accounts are intentionally excluded from cloud identity synchronization per enterprise PAM architecture. Post-containment validation confirmed no further privileged logon events. RBAC enforcement verified. No lateral movement detected. Incident fully contained and documented.

---

## Next Lab

[Back to Main README](../README.md)

---

**E.E. Spence — Identity Engineering | IAMPAM.LAB**