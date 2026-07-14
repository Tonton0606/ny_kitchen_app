# docs/DATA_RETENTION.md
# N.Y Kitchen — Data Retention Policy

---

## Purpose
Define how long different types of data must be retained and how they may be removed.

---

## Retention Rules

| Data Type | Retention | Deletion Allowed? |
|---|---|---|
| Completed Transactions | Permanent | Never permanently deleted |
| Voided Transactions | Permanent (status change only) | Never permanently deleted |
| Refunded Transactions | Permanent (status change only) | Never permanently deleted |
| Activity Logs | Permanent | Never deletable through normal interface |
| Login Attempts | Retain for audit — period TBD | Admin may clear after defined retention period |
| Food Items | Retain if in transactions (archived) | Never deleted if in historical transactions |
| User Accounts | Retain for audit trail | Deactivate only, not delete |
| Backups | Retain until explicitly deleted by Admin | Admin can delete old backup files |
| App Settings | Retained | Admin can change values |

---

## Rules
- Completed transactions must never be permanently deleted.
- Activity logs must never be deleted through the normal interface.
- Archiving is the approved method for retiring food items and user accounts.
- Food records must not be deleted if they exist in transaction_items.

---

## TODO
- [ ] Define login_attempts retention period
- [ ] Confirm legal/regulatory data retention requirements with project owner (if applicable)
