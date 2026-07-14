# docs/AUTHENTICATION.md
# N.Y Kitchen — Authentication

> Source of Truth: PROJECT_BLUEPRINT.md Section 14
> See: DECISIONS.md ADR-013

---

## Purpose
Document the authentication strategy, login flow, and account security mechanisms.

---

## Authentication Method
- Username and password (local SQLite authentication).
- No external OAuth or social login in initial version.

## Login Requirements
- Username: Required, case-sensitive (TBD), must exist in users table.
- Password: Required, verified against stored password hash.

## Password Hashing (Pending Review)
- Algorithm: PENDING REVIEW — bcrypt or argon2 (see ADR-013).
- Minimum password length: TODO — Define minimum (e.g., 8 characters).
- Passwords are hashed before storage. Plain-text passwords are never stored.

## Failed Login Policy
- Failed login counter incremented on every failed attempt.
- Counter is reset on successful login.
- Account lockout threshold: PENDING REVIEW (e.g., 5 failed attempts).
- Locked accounts display a user-friendly message.
- The system must NEVER reveal whether a username exists.
- Error message: "Invalid username or password." (always)

## Account Lockout
- Locked accounts cannot log in.
- Admin can unlock accounts via User Management.
- Lockout event generates an Activity Log entry.

## Session Management
- See: docs/SESSION_MANAGEMENT.md
- Sessions expire after inactivity (duration TBD).
- Logout clears session and generates Activity Log entry.

## Role-Based Routing Post-Login
- Admin → /admin/dashboard
- Cashier → /cashier/orders

---

## Security Considerations
- Never reveal username existence in error messages.
- Always log failed login attempts.
- Always log account lockout events.
- Always log successful logins.

---

## Open Questions
- [ ] Password hashing algorithm (ADR-013)
- [ ] Minimum password length
- [ ] Failed login lockout threshold
- [ ] Session expiration duration

---

## TODO
- [ ] Confirm all open questions before Phase 4
