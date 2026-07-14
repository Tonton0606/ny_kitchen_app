# docs/CIA_TRIAD.md
# N.Y Kitchen — CIA Triad Implementation

> Source of Truth: PROJECT_BLUEPRINT.md Section 13.2

---

## Purpose
Document how the CIA Triad (Confidentiality, Integrity, Availability) is implemented in N.Y Kitchen.

---

## Confidentiality

**Goal:** Sensitive information is accessible only by authorized users.

| Control | Implementation |
|---|---|
| Role-Based Access Control | Admin and Cashier roles with enforced separation |
| Password Hashing | Passwords never stored as plain text |
| Protected Sessions | Session data cleared on logout |
| Restricted Modules | Admin routes blocked to Cashier |
| Secure Login | Username + password required |
| Route Guards | go_router + service layer enforcement |

**Verification:**
- [ ] Cashier cannot access Admin dashboard (to verify in Phase 4)
- [ ] Passwords not visible in database (to verify in Phase 3)
- [ ] Session cleared completely on logout (to verify in Phase 4)

---

## Integrity

**Goal:** Information cannot be modified without authorization.

| Control | Implementation |
|---|---|
| Parameterized Queries | Prevents SQL injection |
| Input Validation | All user input validated on UI and logic layers |
| Automatic Activity Logs | All important actions logged automatically |
| Read-Only Audit Logs | Activity logs cannot be modified through the interface |
| Transaction Preservation | Completed transactions never deleted |
| Void/Refund Controls | Require Admin authorization + reason + Activity Log |
| Data Validation | Prices, quantities, roles, statuses validated |

**Verification:**
- [ ] SQL injection attempts fail gracefully (to verify in Phase 10)
- [ ] Activity logs cannot be edited (to verify in Phase 8)
- [ ] Completed transactions cannot be deleted (to verify in Phase 6)

---

## Availability

**Goal:** Authorized users can access the system whenever needed.

| Control | Implementation |
|---|---|
| Offline Operation | All core features work without internet |
| Local SQLite Database | Data stored and accessible locally |
| Backup and Restore | Database can be recovered from backup |
| Error Recovery | Application handles errors gracefully without crashing |
| Stable Performance | Responsive UI with appropriate loading states |
| Cross-Platform Support | Android Phone, Tablet, Windows Desktop |

**Verification:**
- [ ] App works without internet connection (to verify in Phase 3+)
- [ ] Backup and restore successful (to verify in Phase 3)
- [ ] No crashes on invalid input (to verify in Phase 10)

---

## TODO
- [ ] Complete CIA Triad review checklist during Phase 10
