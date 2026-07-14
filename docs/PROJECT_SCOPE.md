# docs/PROJECT_SCOPE.md
# N.Y Kitchen — Project Scope

> Source of Truth: `PROJECT_BLUEPRINT.md` Section 4
> Do not expand scope without explicit approval and blueprint update.

---

## Purpose
Define the approved scope of the N.Y Kitchen application to prevent scope creep and guide all development decisions.

---

## In Scope

### Modules
- Secure Login
- Admin Dashboard
- Food Menu Management (replaces Inventory Management)
- Sales Processing (Order Processing)
- Receipt Printing
- Transaction History
- User Management (Admin and Cashier accounts)
- Activity Logs (Read-Only Audit Trail)
- Reports
- Account Settings
- Backup and Restore

### User Roles
- Administrator — Full system control
- Cashier — Order processing only

### Platforms
- Android Phone
- Android Tablet
- Windows Desktop

### Payment Methods
- Cash
- GCash
- Maya
- Credit Card
- Debit Card

---

## Out of Scope (Intentionally Excluded)

- Inventory Management
- Supplier Management
- Customer Accounts / Loyalty Programs
- Delivery Tracking
- Online Ordering
- Cloud Database (Supabase is future/optional only)
- Multi-branch Support
- Employee Payroll
- Accounting System

---

## Security Considerations
- Scope boundaries prevent unintended feature creep that could introduce security risks.
- Any scope change must go through a documented review process before implementation.

---

## Open Questions
- [ ] Confirm Supabase cloud sync scope with project owner (see `DECISIONS.md` ADR-002)

---

## TODO
- [ ] Get scope sign-off from supervisor before Phase 1 prototype begins
