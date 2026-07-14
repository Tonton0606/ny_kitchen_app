# docs/THREAT_MODEL.md
# N.Y Kitchen — Threat Model

---

## Purpose
Document identified threats and mitigations for N.Y Kitchen.

---

## Threat Actors
- Malicious Cashier attempting to access Admin features
- External attacker with physical device access
- Insider misuse by Admin
- Automated script injection attacks

## Identified Threats

| ID | Threat | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| T-001 | Cashier accesses Admin routes | High | Medium | Route guards + service-layer checks + Activity Log |
| T-002 | Brute force login attack | High | Medium | Account lockout after N failed attempts |
| T-003 | SQL injection via input fields | High | Low | Parameterized queries on all database operations |
| T-004 | Plain-text password storage | Critical | Low | Password hashing required |
| T-005 | Activity log tampering | High | Low | Immutable logs, no UI-accessible delete |
| T-006 | Transaction deletion | High | Low | No delete query on completed transactions |
| T-007 | Supabase key exposure | Critical | Low | Never embed service-role key in Flutter client |
| T-008 | Credential exposure in source control | Critical | Medium | .gitignore + .aiignore, environment variables |
| T-009 | Unauthorized receipt reprint | Medium | Low | Reprint generates Activity Log |
| T-010 | Data loss from failed restore | High | Low | Preserve existing database until restore confirmed |

---

## Residual Risks (To Be Documented)
- [ ] Physical device theft and offline data access
- [ ] Database file access on rooted/compromised device
- [ ] Backup file security

---

## TODO
- [ ] Complete formal threat model review during Phase 10
- [ ] Update mitigations as implementation progresses
