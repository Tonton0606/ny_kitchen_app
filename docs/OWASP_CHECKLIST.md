# docs/OWASP_CHECKLIST.md
# N.Y Kitchen — OWASP Security Checklist

> Source of Truth: PROJECT_BLUEPRINT.md Section 13.3

---

## Purpose
Track OWASP Secure Coding Principles compliance for N.Y Kitchen.

---

## Checklist

### A01: Broken Access Control
- [ ] Admin routes are protected and inaccessible to Cashier
- [ ] Role checks enforced at service layer, not only UI
- [ ] Unauthorized access redirects to /unauthorized
- [ ] Unauthorized access is logged in Activity Logs

### A02: Cryptographic Failures
- [ ] Passwords are never stored as plain text
- [ ] A strong hashing algorithm is used (bcrypt/argon2 — TBD)
- [ ] No sensitive data in logs
- [ ] Supabase service-role key never in Flutter client
- [ ] No credentials committed to source control

### A03: Injection
- [ ] All SQLite queries use parameterized statements
- [ ] No raw SQL string concatenation anywhere in the codebase
- [ ] Search inputs sanitized before use

### A04: Insecure Design
- [ ] Authorization enforced at logic layer, not only UI
- [ ] Void/refund requires Admin authorization
- [ ] Final Admin cannot deactivate itself
- [ ] Completed transactions are preserved

### A05: Security Misconfiguration
- [ ] Debug mode disabled in production builds
- [ ] No test credentials in production
- [ ] No hardcoded credentials in source code
- [ ] Development and production environments separated

### A07: Identification and Authentication Failures
- [ ] Failed login counter implemented
- [ ] Account lockout after threshold exceeded
- [ ] Error message never reveals username existence
- [ ] Session expires after inactivity

### A09: Security Logging and Monitoring Failures
- [ ] All important events generate Activity Log entries
- [ ] Failed logins are logged
- [ ] Account lockouts are logged
- [ ] Unauthorized access attempts are logged
- [ ] Activity logs are immutable

---

## TODO
- [ ] Complete full OWASP checklist review during Phase 10
- [ ] Document any exceptions or accepted risks
