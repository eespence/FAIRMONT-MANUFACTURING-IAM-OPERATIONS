# Vault & Delinea PAM Governance

**Lab:** IAMPAM.LAB | **Ticket:** REQ0042001 | **Status:** ✅ Complete | **Last Updated:** April 2026

---

Provisioning user accounts is only half of the onboarding equation. The other half is ensuring those identities can only access the secrets and privileged resources they are authorized to use — nothing more. This is where Privileged Access Management governance begins.

This article covers the PAM governance layer of the Fairmont Manufacturing onboarding workflow — HashiCorp Vault LDAP integration, RBAC policy mapping, department secret creation, and Delinea Secret Server folder-based access control. Together these controls ensure that privileged credentials are stored securely, accessed only through policy-enforced paths, and governed by the same group-based model as the rest of the identity architecture.

---

## Business Context

**Organization:** Fairmont Manufacturing LLC
**Ticket:** REQ0042001 — New Employee Onboarding
**Compliance:** CMMC Level 2

Secrets must be vaulted in HashiCorp Vault and Delinea Secret Server. Access must be enforced per department. No user should be able to access secrets outside their authorized scope.

---

## Architecture

```text
Active Directory Groups → Vault LDAP → Policy Mapping → Secret Paths
Active Directory Groups → Delinea Local Groups → Folder Permissions → Department Secrets
```

---

## Phase 1 — HashiCorp Vault LDAP Integration

Vault was configured to authenticate against Active Directory through LDAP — enabling AD group membership to drive Vault secret access policies directly without requiring separate Vault user management.

Key configuration:
- URL: `ldap://172.31.100.10` — DC01 as the LDAP source
- userdn scoped to `OU=IAM-PAM-Users`
- groupdn scoped to `OU=IAM-PAM-Groups`
- binddn using `adm-t0-administrator` — production deployments should use a dedicated least-privilege service account
- `userattr = sAMAccountName` — AD usernames map directly to Vault identities

[ SCREENSHOT: lab01_04_vault_ldap_configured ]

[ SCREENSHOT: lab01_05_vault_ldap_configured_settings ]

---

## Phase 2 — Vault RBAC Policy Mapping

Two Vault policies were created to enforce least privilege secret access:

**fairmont-users** — standard department users:
- Capabilities: `read` and `list` on `secret/data/fairmount/*`

**fairmont-it-admins** — IT-Admins elevated access:
- Capabilities: `create`, `read`, `update`, `delete`, `list` on `secret/data/fairmount/*`

AD groups were then mapped to these policies:

| AD Group | Vault Policy |
|---|---|
| IT-Admins | fairmont-it-admins |
| ENG-Users | fairmont-users |
| FIN-Users | fairmont-users |
| SEC-Analysts | fairmont-users |

This means group membership in Active Directory directly controls what a user can do in Vault — no separate access management required.

[ SCREENSHOT: lab01_06_vault_policies_created ]

[ SCREENSHOT: lab01_07_vault_group_mapping ]

---

## Phase 3 — Department Secret Creation

Department-aligned service account credentials were stored as secrets in Vault at scoped paths:

- `secret/fairmont/engineering` — ENG API key and service account
- `secret/fairmont/finance` — FIN reporting key and audit service account
- `secret/fairmont/it` — IT admin token and monitoring key

Secrets are stored at department level — not at individual user level. This means removing a single user from AD does not require Vault secret deletion — only group membership controls access.

[ SCREENSHOT: lab01_08_vault_secrets_created ]

[ SCREENSHOT: lab01_09_vault_secret_read ]

---

## Phase 4 — Delinea Secret Server PAM Setup

Department folders were created in Delinea Secret Server aligned to the Fairmount organizational structure:

- `Fairmont Manufacturing/Engineering`
- `Fairmont Manufacturing/Finance`
- `Fairmont Manufacturing/IT-Security`

[ SCREENSHOT: lab01_12_delinea_folders ]

---

## Phase 5 — Secret Segmentation in Delinea

Service account credentials were placed into the correct department folders:

| Folder | Secret Name | Username |
|---|---|---|
| Engineering | FM Engineering Service Account | svc.eng.fairmont |
| Finance | FM Finance Reporting Account | svc.fin.fairmont |
| IT-Security | FM IT Admin Account | svc.it.fairmont |

[ SCREENSHOT: lab01_13A_engineering_folder_svc.eng.fairmont ]

[ SCREENSHOT: lab01_13B_finance_folder_svc.fin.fairmont ]

[ SCREENSHOT: lab01_13C_it_security_folder_svc.it.fairmont ]

---

## Phase 6 — Delinea RBAC Enforcement

Folder-level permissions were assigned enforcing department-aligned access control:

| Group | Folder | Access Level |
|---|---|---|
| ENG-Users | Engineering | Read |
| FIN-Users | Finance | Read |
| FIN-Approvers | Finance | Read |
| FIN-Auditors | Finance | Read |
| IT-Admins | IT-Security | Owner |
| SEC-Analysts | All Fairmont folders | Read |

**Licensing Note:** Due to single-user licensing constraints in the lab environment, direct Active Directory integration with Delinea Secret Server could not be completed. AD group structure was replicated using local Delinea groups to maintain architectural accuracy. This ensures that once AD integration is enabled, group synchronization can occur without requiring redesign of access controls — preserving full architectural integrity.

[ SCREENSHOT: lab01_14A_engineering_permissions ]

[ SCREENSHOT: lab01_14B_finance_permissions ]

[ SCREENSHOT: lab01_14C_it_security_permissions ]

---

## CMMC Level 2 Alignment

| Practice | Control | Evidence |
|---|---|---|
| AC.2.007 | Limit privileged account use | IT-Admins only for elevated Vault access |
| CM.2.061 | Establish baseline configurations | Vault policies and Delinea RBAC model |
| AU.2.041 | Audit user management actions | Vault audit logging for credential access |

---

## Why This Matters

Without PAM governance, privileged credentials are stored wherever is convenient — shared drives, email threads, sticky notes. Any compromise of those storage locations exposes every privileged account in the environment simultaneously. This implementation ensures department secrets are stored in a controlled, policy-enforced vault — accessed only by authorized identities through group membership — and governed by the same RBAC model that controls everything else in the identity architecture.

---

👉 **[View Full Lab on GitHub](https://github.com/eespence/fairmount-manufacturing-iam-operations)**

---

**E.E. Spence — IAM/PAM Engineering | Fairmont Manufacturing LLC**