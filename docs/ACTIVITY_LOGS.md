# docs/ACTIVITY_LOGS.md
# N.Y Kitchen — Activity Logs

> Source of Truth: PROJECT_BLUEPRINT.md Section 7.7

---

## Purpose
Document the Activity Log system that provides an immutable audit trail for all tracked events.

---

## Principles
- Activity Logs are PERMANENT and IMMUTABLE through the normal application interface.
- No UPDATE or DELETE operations are permitted on activity_logs through the application.
- All tracked events must generate an automatic Activity Log entry.
- The Activity Log module is read-only for all users including Administrators.

---

## Logged Events

| Module | Events |
|---|---|
| Authentication | Login success, Login failed, Account locked, Logout, Session expired |
| Transactions | Order completed, Transaction voided, Transaction refunded, Receipt printed, Receipt reprinted |
| Menu Management | Food item added, Food item edited, Food item archived, Category added, Category renamed |
| User Management | User created, User edited, User activated, User deactivated, Password reset, Account unlocked, Role changed |
| Settings | Business info updated, Receipt settings updated, Printer settings updated |
| Backup | Backup created, Backup restored, Backup deleted |
| Security | Unauthorized access attempt, Locked account login attempt |

---

## Log Entry Structure

| Field | Description |
|---|---|
| id | Auto-increment primary key |
| user_id | ID of user performing the action (nullable for system events) |
| username | Snapshot of username at time of log |
| role | Snapshot of role at time of log |
| module | Module category (auth, transactions, menu, etc.) |
| action | Short action description |
| status | success or failed |
| description | Detailed description of the event |
| device_info | Device identifier |
| created_at | ISO8601 timestamp |

---

## Activity Log Viewer (Admin Only)
- Read-only table view.
- Search by date range.
- Filter by user, role, module, status.
- Export to PDF.
- Export to CSV.

---

## Security Rules
- No UPDATE queries on activity_logs allowed through the application.
- No DELETE queries on activity_logs allowed through the application.
- Logs must survive backup and restore operations.
- All unauthorized access attempts must be logged immediately.

---

## TODO
- [ ] Implement Activity Log service in Phase 8
- [ ] Ensure all event triggers are wired before Phase 10
