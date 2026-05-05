# PowerShell Automation Library

**Lab:** IAMPAM.LAB | **Ticket:** REQ0042001 | **Status:** ✅ Complete | **Last Updated:** April 2026

---

Lab work produces runbooks and documentation. Good engineering produces reusable tools. This automation library takes the provisioning and remediation workflows executed in the Fairmont Manufacturing IAM operations labs and packages them as production-ready PowerShell scripts — parameterized, documented, error-handled, and audit-ready.

These scripts are not one-time lab artifacts. They are operational templates built to the same standard you would expect in an enterprise IAM engineering team — with pre-flight validation, independent error handling, CSV audit export, and Entra Connect sync integration built in from the start.

---

## Library Overview

| Script | Purpose |
|---|---|
| `fm-bulk-user-provisioning.ps1` | Bulk AD user creation for the full 10-user Fairmont cohort |
| `fm-bulk-user-rollback.ps1` | Bulk or targeted rollback of provisioned users |
| `fm-single-user-provision.ps1` | Single user provisioning for late hires or failed batch users |
| `fm-single-user-remediate.ps1` | Targeted remediation — group fix, disable, unlock, password reset, remove |

All scripts require the ActiveDirectory module and are designed to run from MGMT01 as `adm-t0-administrator`.

---

## fm-bulk-user-provisioning.ps1

### What It Does

Provisions all 10 Fairmont Manufacturing employees in a single parameterized run. Each user is processed independently — a failure on one user does not stop the remaining batch.

Per user the script executes three steps in sequence:

1. Create the AD user account in `OU=IAM-PAM-Users`
2. Assign the department AD group — ENG-Users, FIN-Users, FIN-Approvers, FIN-Auditors, IT-Admins, or SEC-Analysts
3. Add to `AAD-Sync-Users` — the Entra Connect scope group that controls cloud synchronization eligibility

### Pre-Flight Validation

Before any users are created the script validates:

- Domain controller is reachable
- Target OU exists
- `AAD-Sync-Users` group exists — aborts if missing since users cannot sync to Entra without it
- All 6 department groups exist — aborts if any are missing

### Error Handling

Each step uses independent try/catch blocks. Results are tracked per user across three boolean states: `UserCreated`, `GroupAssigned`, `SyncGroupAdded`. The script flags any user where `SyncGroupAdded = False` as a critical failure because that user will not sync to Entra ID regardless of whether the account was created successfully.

### Audit Output

Results are exported to a timestamped CSV at `C:\Logs\FM-Onboarding-REQ0042001-[timestamp].csv` covering every user with their ticket number, department, group, and all three outcome states.

### Usage

```powershell
.\fm-bulk-user-provisioning.ps1

# With custom log path and ticket number
.\fm-bulk-user-provisioning.ps1 -LogPath "D:\Logs" -TicketNumber "REQ0042001"
```

---

## fm-bulk-user-rollback.ps1

### What It Does

Provides two rollback scenarios for reversing Fairmont Manufacturing user provisioning — targeted single user rollback or full batch rollback of all 10 users.

### Scenario A — Targeted Single User Rollback

Two actions available per user:

**FixGroup** — adds the user to a specified group. Used to fix a failed group assignment or restore `AAD-Sync-Users` membership for a user who is not syncing to Entra.

**RemoveUser** — permanently removes a single user. Sequence is enforced:
1. Remove from `AAD-Sync-Users` first — ensures Entra deprovisions the account on next sync
2. Remove from Active Directory
3. Trigger Entra Connect delta sync

### Scenario B — Full Bulk Rollback

Removes all 10 FM users in the correct sequence:
1. Remove all users from `AAD-Sync-Users` first
2. Trigger Entra sync — cloud deprovision begins
3. Remove all users from Active Directory
4. Trigger final Entra sync — confirm no orphan cloud accounts remain
5. Provide Vault and Delinea cleanup guidance for manual follow-up

### Safety Controls

Both scenarios require the operator to type `CONFIRM` before any destructive action executes — preventing accidental runs.

### Usage

```powershell
# Fix group assignment for a single user
.\fm-bulk-user-rollback.ps1 -Scenario A -SAM fm.kira.vanthorpe -Action FixGroup -Group ENG-Users

# Remove a single user completely
.\fm-bulk-user-rollback.ps1 -Scenario A -SAM fm.kira.vanthorpe -Action RemoveUser

# Full bulk rollback of all 10 FM users
.\fm-bulk-user-rollback.ps1 -Scenario B
```

---

## fm-single-user-provision.ps1

### What It Does

Provisions a single Fairmont Manufacturing employee — designed for three use cases:

- Late hire onboarding after the bulk cohort run
- Retrying a specific user that failed during bulk provisioning
- Adding a new employee outside of a scheduled bulk event

Executes the same three-step sequence as the bulk script — create user, assign group, add to `AAD-Sync-Users` — then automatically triggers Entra Connect delta sync.

### Pre-Flight Validation

Validates domain controller reachability, target OU, department group, and `AAD-Sync-Users` group before any action is taken. UPN format is also validated against the expected Fairmont pattern.

### Next Steps Guidance

On successful completion the script outputs a checklist of validation steps including Entra ID verification URL, Vault LDAP group mapping check, Delinea folder access verification, and the Splunk SPL query to confirm the user creation event was captured.

### Usage

```powershell
.\fm-single-user-provision.ps1 `
    -DisplayName "FM - Kira Vanthorpe" `
    -SAM "fm.kira.vanthorpe" `
    -UPN "fm.kira.vanthorpe@fairmontmanufacturing.onmicrosoft.com" `
    -Group "ENG-Users" `
    -Department "Engineering" `
    -TicketNumber "REQ0042015"
```

---

## fm-single-user-remediate.ps1

### What It Does

The most versatile script in the library. Performs targeted remediation on a single user account with 7 available actions:

| Action | What It Does |
|---|---|
| `FixGroup` | Adds user to a specified group. If group is `AAD-Sync-Users` — automatically triggers Entra sync after adding |
| `RemoveGroup` | Removes user from a specified group with Entra sync impact warning if removing from `AAD-Sync-Users` |
| `DisableUser` | Disables the account — keeps it in AD and Entra sync scope |
| `EnableUser` | Re-enables a previously disabled account |
| `RemoveUser` | Permanently deletes — removes from `AAD-Sync-Users` first, triggers sync, waits, then deletes from AD, triggers final sync |
| `ResetPassword` | Resets to temporary password with forced change at next logon |
| `UnlockAccount` | Unlocks a locked account |

### Pre-Flight Validation

Before any action the script verifies the user exists in AD and displays current account state — enabled status, locked status, and `AAD-Sync-Users` membership — giving the operator full context before proceeding.

### Usage

```powershell
# Fix Entra sync scope — user not syncing to Entra ID
.\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action FixGroup -Group AAD-Sync-Users -TicketNumber REQ0042001

# Disable a user account
.\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action DisableUser -TicketNumber INC0043102

# Reset password
.\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action ResetPassword -TicketNumber INC0043102

# Permanently remove a user
.\fm-single-user-remediate.ps1 -SAM fm.kira.vanthorpe -Action RemoveUser -TicketNumber INC0043102
```

---

## Design Principles

Every script in this library follows the same engineering standards:

**Pre-flight validation** — environment prerequisites are validated before any changes are made. Scripts abort cleanly if critical dependencies are missing rather than failing midway through execution.

**Independent error handling** — each operation uses its own try/catch block. A failure in one step is captured and logged without stopping subsequent operations unless a hard dependency requires it.

**AAD-Sync-Users awareness** — every script that touches user provisioning or removal explicitly handles `AAD-Sync-Users` membership. The scripts understand that removing a user from AD without first removing them from `AAD-Sync-Users` leaves an orphan account in Entra ID.

**Audit trail** — every run produces a timestamped CSV log at `C:\Logs\` capturing ticket number, user, action, and outcome. All logs are named with the ticket number for traceability.

**Operator safety** — destructive actions require explicit `CONFIRM` input before executing. Scripts never delete silently.

---

## Why This Matters

Manual IAM operations are slow, error-prone, and leave no audit trail. These scripts demonstrate that IAM engineering is not just about knowing the tools — it is about building automation that enforces consistency, captures evidence, and handles failure gracefully. Every script here can be adapted for a real enterprise environment by updating the OU paths, domain names, and user roster.

---

👉 **[View Automation Library on GitHub](https://github.com/eespence/fairmont-manufacturing-iam-operations/tree/main/automation)**

---

**E.E. Spence — IAM/PAM Engineering | Fairmont Manufacturing LLC**