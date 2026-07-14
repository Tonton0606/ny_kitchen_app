# docs/SESSION_MANAGEMENT.md
# N.Y Kitchen — Session Management

> See: DECISIONS.md ADR-013

---

## Purpose
Define how user sessions are created, maintained, and terminated.

---

## Session Storage
- Session data stored in memory (AuthProvider) during active use.
- Persistent session token: PENDING REVIEW — SharedPreferences or secure storage.
- Session is cleared completely on logout.

## Session Expiration
- Automatic logout after inactivity period: PENDING REVIEW (e.g., 30 minutes).
- Session expiration must generate an Activity Log entry.

## Session Data Stored
- User ID
- Username
- Role (Admin or Cashier)
- Login timestamp
- Device information

## Session Termination
- Explicit logout: Confirmation dialog → clear session → Activity Log → return to /login.
- Session expiration: Clear session → Activity Log → return to /login.
- Account deactivated by Admin: Session invalidated on next route check.

## Rules
- Sensitive session data must be cleared completely on logout.
- Sessions must not persist across application restarts (unless remember-me is explicitly designed).
- Do not store the Supabase service-role key in session data.

---

## Open Questions
- [ ] Should sessions persist across app restarts? (e.g., remember-me feature)
- [ ] Session expiration duration (ADR-013)
- [ ] Storage method for persistent sessions (SharedPreferences vs secure_storage)

---

## TODO
- [ ] Confirm session design before Phase 4
