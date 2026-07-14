# docs/MODULES.md
# N.Y Kitchen — Module Reference

> Source of Truth: PROJECT_BLUEPRINT.md Sections 6 and 7

---

## Purpose
List and describe all approved application modules. No additional modules may be introduced without blueprint approval.

---

## Cashier Modules
| Module | Description |
|---|---|
| Home / New Order | POS interface for processing customer orders |
| Transaction History | View own completed transactions and reprint receipts |
| Account Settings | View profile, change password, theme, session info |
| Logout | Confirm and end session with Activity Log |

## Admin Modules
| Module | Description |
|---|---|
| Dashboard | Business analytics, revenue, security summary |
| Transactions | Full access to all sales records, void, refund |
| Menu Management | Manage food items, categories, availability |
| User Management | Create and manage Admin and Cashier accounts |
| Activity Logs | Read-only audit trail viewer with export |
| Reports | Sales, business, and security reports |
| Account Settings | Business info, receipt settings, theme, security |
| Backup and Restore | Manual backup and restore of SQLite database |
| Logout | Confirm and end session with Activity Log |

---

## TODO
- [ ] Create detailed screen specifications for each module before Phase 1 prototype
