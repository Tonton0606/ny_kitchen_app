# docs/FUNCTIONAL_REQUIREMENTS.md
# N.Y Kitchen — Functional Requirements

> Source of Truth: `PROJECT_BLUEPRINT.md` Sections 5-17

---

## Purpose
List all functional requirements derived from the approved project blueprint. These define what the system must do.

---

## Authentication
- FR-AUTH-001: The system must require username and password for login.
- FR-AUTH-002: Passwords must be hashed before storage.
- FR-AUTH-003: Failed login attempts must be counted and logged.
- FR-AUTH-004: Accounts must be locked after exceeding the failed login threshold.
- FR-AUTH-005: Locked accounts must display a user-friendly message.
- FR-AUTH-006: The system must never reveal whether a username exists on failed login.
- FR-AUTH-007: Session must expire after inactivity (threshold TBD).
- FR-AUTH-008: Logout must generate an Activity Log entry.

## Admin Dashboard
- FR-DASH-001: Display today's, weekly, monthly, and annual revenue.
- FR-DASH-002: Display transaction summary (completed, voided, refunded, average order value).
- FR-DASH-003: Display business analytics (best-selling food, category, peak hour, top cashier).
- FR-DASH-004: Display security summary (logins, failed attempts, locked accounts, recent events).
- FR-DASH-005: Display recent activities.

## Menu Management
- FR-MENU-001: Admin can add food items with image, name, category, description, price, and availability.
- FR-MENU-002: Admin can edit food items.
- FR-MENU-003: Admin can archive food items (not delete if used in transactions).
- FR-MENU-004: Admin can toggle food availability.
- FR-MENU-005: Admin can manage food categories (add, rename, enable, disable).
- FR-MENU-006: Archived items remain on historical receipts but cannot be added to new orders.
- FR-MENU-007: All menu changes must generate Activity Log entries.

## Order Processing
- FR-ORDER-001: Cashier can search and filter food items.
- FR-ORDER-002: Cashier can add items to the current order.
- FR-ORDER-003: Cashier can adjust quantities and remove items.
- FR-ORDER-004: Cashier can add order notes.
- FR-ORDER-005: System must validate that the order contains at least one item before checkout.
- FR-ORDER-006: Cashier selects payment method from approved options.
- FR-ORDER-007: System generates receipt after successful payment.
- FR-ORDER-008: System saves transaction to SQLite after successful checkout.
- FR-ORDER-009: System generates Activity Log after transaction completion.

## Receipt
- FR-RCPT-001: Receipts must include business info, transaction info, ordered items, payment summary, and footer.
- FR-RCPT-002: Every receipt must have a unique receipt number.
- FR-RCPT-003: Receipts can be previewed before printing.
- FR-RCPT-004: Receipts can be reprinted by authorized users.
- FR-RCPT-005: Every reprint must generate an Activity Log entry.

## Transactions
- FR-TXN-001: Completed transactions must never be permanently deleted.
- FR-TXN-002: Admin can void transactions (requires reason + Activity Log).
- FR-TXN-003: Admin can refund transactions (requires reason + Activity Log).
- FR-TXN-004: Cashier can view own transaction history.
- FR-TXN-005: Admin can view all transaction history with filters.

## User Management
- FR-USER-001: Admin can create user accounts (Admin or Cashier).
- FR-USER-002: Admin can edit user information.
- FR-USER-003: Admin can activate and deactivate accounts.
- FR-USER-004: Admin can reset passwords.
- FR-USER-005: Admin can unlock locked accounts.
- FR-USER-006: Admin can change user roles.
- FR-USER-007: The final active Admin account cannot deactivate itself.
- FR-USER-008: All user management actions must generate Activity Log entries.

## Activity Logs
- FR-LOG-001: All tracked events must generate automatic Activity Log entries.
- FR-LOG-002: Activity Logs must be read-only through the application interface.
- FR-LOG-003: Admin can search and filter Activity Logs.
- FR-LOG-004: Admin can export Activity Logs (PDF, CSV).

## Reports
- FR-RPT-001: Admin can view daily, weekly, monthly, and annual sales reports.
- FR-RPT-002: Admin can view best-selling foods and categories report.
- FR-RPT-003: Admin can view cashier performance report.
- FR-RPT-004: Admin can view security/login summary report.
- FR-RPT-005: Admin can export reports (PDF, CSV).

## Backup and Restore
- FR-BKP-001: Admin can create manual database backups.
- FR-BKP-002: Admin can view backup history.
- FR-BKP-003: Admin can restore from a backup.
- FR-BKP-004: All backup and restore actions must generate Activity Log entries.
- FR-BKP-005: The existing database must be preserved until restoration is confirmed successful.

---

## TODO
- [ ] Confirm failed login lockout threshold (ADR-013)
- [ ] Confirm session expiration duration (ADR-013)
