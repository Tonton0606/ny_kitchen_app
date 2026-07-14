# docs/SECURITY.md
# N.Y Kitchen — Security Framework Overview

> Source of Truth: PROJECT_BLUEPRINT.md Section 13
> Security is the HIGHEST project priority.

---

## Purpose
Provide a consolidated overview of the N.Y Kitchen security framework. See specialized documents for details.

---

## Security Standards Applied
- CIA Triad (docs/CIA_TRIAD.md)
- OWASP Secure Coding Principles (docs/OWASP_CHECKLIST.md)
- ISO/IEC 25010 Software Quality Model (docs/ISO25010_EVALUATION.md)

## Security Layers

### Authentication Layer
- Username + password login.
- Password hashing (algorithm TBD).
- Failed login tracking and account lockout.
- See: docs/AUTHENTICATION.md

### Authorization Layer
- Role-Based Access Control (Admin and Cashier).
- Route guards and service-layer checks.
- See: docs/AUTHORIZATION.md

### Data Integrity Layer
- Parameterized SQLite queries.
- Input validation on UI and logic layers.
- Read-only activity logs.
- Immutable completed transactions.
- See: docs/VALIDATION_RULES.md

### Audit and Logging Layer
- Automatic Activity Log for all tracked events.
- Security event monitoring.
- See: docs/ACTIVITY_LOGS.md

### Secure Configuration
- No hardcoded credentials.
- No Supabase service-role key in client.
- Environment-based configuration.
- Debug mode disabled in production.

---

## Key Security Rules
1. Never store plain-text passwords.
2. Never expose sensitive error details to users.
3. Never use raw SQL string concatenation.
4. Never rely on UI controls alone for authorization.
5. Never commit credentials to source control.
6. Activity logs are permanently immutable.
7. Completed transactions are never permanently deleted.

---

## TODO
- [ ] Complete CIA Triad review (Phase 10)
- [ ] Complete OWASP checklist (Phase 10)
- [ ] Complete ISO/IEC 25010 evaluation (Phase 10)
- [ ] Conduct security testing (Phase 10)
