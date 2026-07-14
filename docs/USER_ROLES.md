# docs/USER_ROLES.md
# N.Y Kitchen — User Roles

> Source of Truth: PROJECT_BLUEPRINT.md Section 5
> Only two roles exist. No additional roles may be added without explicit approval.

---

## Purpose
Define the responsibilities, permissions, and restrictions for each user role.

---

## Administrator

### Responsibilities
- Monitor daily business operations
- Manage food menu items and categories
- Create and manage user accounts
- Review all transactions
- View security events
- Generate reports
- Configure application settings
- Create and restore database backups

### Permitted Modules
- Dashboard
- Transactions (full access)
- Menu Management
- User Management
- Activity Logs
- Reports
- Account Settings
- Backup and Restore
- Logout

### Permissions
- Full CRUD on food menu and categories
- Full CRUD on user accounts
- View all transactions
- Void and refund transactions (with reason and Activity Log)
- View all Activity Logs
- Print and export reports
- Configure business information and receipt settings

### Restrictions
- Cannot modify Activity Logs
- Cannot permanently delete completed transactions
- Cannot deactivate the final active Admin account

---

## Cashier

### Responsibilities
- Process customer orders
- Print receipts
- View personal transaction history

### Permitted Modules
- Home / New Order
- Transaction History (own only)
- Account Settings
- Logout

### Permissions
- Search and filter food items
- Add food to current order
- Modify current order (quantity, remove, notes)
- Complete payment and checkout
- Print receipt
- Reprint authorized receipts (with Activity Log)
- Change own password

### Restrictions
- Cannot access Admin Dashboard analytics
- Cannot manage user accounts
- Cannot modify menu items
- Cannot view Activity Logs
- Cannot view reports
- Cannot perform backup or restore
- Cannot delete completed transactions
- Cannot void or refund without Admin authorization
- Cannot access protected Admin routes

---

## Security Notes
- Role assignments are stored in SQLite and verified at every route access.
- Role-based access is enforced at the router layer AND the service layer.
- Unauthorized access attempts must generate an Activity Log entry.

---

## Open Questions
- [ ] Define Admin authorization workflow for void/refund (in-person confirmation vs PIN?)
