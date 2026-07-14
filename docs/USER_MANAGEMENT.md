# docs/USER_MANAGEMENT.md
# N.Y Kitchen — User Management

> Source of Truth: PROJECT_BLUEPRINT.md Section 7.6

---

## Purpose
Document all user account management features and rules.

---

## Admin Operations
- Add User (Admin or Cashier)
- Edit User (name, username, role)
- Activate User
- Deactivate User
- Reset Password (Admin sets new password, user must change on first login — TBD)
- Unlock Account (for locked accounts)
- Change User Role

## User Record Fields
| Field | Notes |
|---|---|
| Full Name | Required |
| Username | Required, unique |
| Password Hash | Required, hashed — never plain-text |
| Role | admin or cashier |
| Status | active, inactive, locked |
| Last Login | ISO8601 timestamp |
| Failed Login Count | Reset on successful login |
| Created At | ISO8601 timestamp |

## Rules
- The final active Administrator account CANNOT be deactivated.
- Every user management action automatically generates an Activity Log.
- Passwords are NEVER stored as plain text.
- Deactivating a user does NOT delete the user record.
- Deactivated users cannot log in.

---

## TODO
- [ ] Define password reset workflow (Admin-set vs email vs temporary password)
- [ ] Implement user management module in Phase 7
