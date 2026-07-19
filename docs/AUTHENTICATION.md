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

## Password Hashing (Current Implementation)
- Algorithm: SHA-256 with the project-wide salt via Dart `crypto` and `SecurityUtils`.
- This is the current Phase 4 implementation; a stronger password KDF remains a production security review item.
- Minimum password length: TODO — Define minimum (e.g., 8 characters).
- Passwords are hashed before storage. Plain-text passwords are never stored.

## Failed Login Policy
- Failed login counter incremented on every failed attempt.
- Counter is reset on successful login.
- Account lockout threshold: 5 failed attempts; the repository sets `status = 'locked'`.
- Locked accounts display a user-friendly message.
- The system must NEVER reveal whether a username exists.
- Error message: "Invalid username or password." (always)

## Account Lockout
- Locked accounts cannot log in.
- Admin can unlock accounts via User Management.
- Lockout event logging is planned but is not currently wired by `UserRepository`.

## Session Management
- See: docs/SESSION_MANAGEMENT.md
- Sessions are currently in-memory through `SessionManager`; inactivity expiration is not implemented.
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
- [x] Current password hashing algorithm documented (SHA-256 via `crypto`)
- [ ] Minimum password length
- [x] Failed login lockout threshold documented (5 attempts)
- [ ] Session expiration duration and implementation

---

## TODO
- [ ] Resolve remaining authentication hardening gaps before production use
