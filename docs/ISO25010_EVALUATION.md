# docs/ISO25010_EVALUATION.md

> 2026-10-20 reconciliation: Use SECURITY_IMPLEMENTATION_PLAN.md R16 and AT01–AT10 for measurable evidence. Checklist entries below are evaluation targets, not verified properties. Local audit records alone do not prove non-repudiation, and no certification is claimed.
# N.Y Kitchen — ISO/IEC 25010:2023 Quality Evaluation

> Source of Truth: PROJECT_BLUEPRINT.md Section 13.4

---

## Purpose
Evaluate N.Y Kitchen against the updated ISO/IEC 25010:2023 Systems and software Quality Requirements and Evaluation (SQuaRE) — Product quality model.

---

## Quality Characteristics

### Functional Suitability
*Completeness, correctness, and appropriateness of functions.*
- [ ] Ordering: All food items can be added to order and checked out (Functional completeness)
- [ ] Sales: Transactions are saved accurately (Functional correctness)
- [ ] Roles: Features accurately facilitate intended tasks for Admin and Cashier (Functional appropriateness)

### Performance Efficiency
*Time behavior, resource utilization, and capacity.*
- [ ] Login completes within 2 seconds (Time behavior)
- [ ] Menu loading completes within 2 seconds (Time behavior)
- [ ] Works efficiently with limited device resources (Resource utilization)

### Compatibility
*Co-existence and interoperability.*
- [ ] Functions correctly alongside other apps on Android (Co-existence)
- [ ] Database structures can interoperate for future backup sync (Interoperability)

### Interaction Capability
*Appropriateness recognizability, learnability, operability, user error protection, user engagement.*
- [ ] Interface is usable without training for basic operations (Learnability)
- [ ] Navigation is consistent and predictable (Operability)
- [ ] Touch targets are at least 48dp on mobile (Operability)
- [ ] Prevent cashiers from accidental voiding (User error protection)
- [ ] Modern UI/UX encourages continued interaction (User engagement)

### Reliability
*Faultlessness, availability, fault tolerance, recoverability.*
- [ ] No data loss on unexpected errors (Fault tolerance)
- [ ] Works 100% offline (Availability)
- [ ] Application recovers gracefully from errors and can restore backups (Recoverability)

### Security
*Confidentiality, integrity, non-repudiation, accountability, authenticity, resistance.*
- [ ] Passwords are hashed and sessions are managed (Confidentiality & Authenticity)
- [ ] Activity logs are immutable (Integrity & Non-repudiation)
- [ ] Every action is logged with user and timestamp (Accountability)
- [ ] Input is validated to prevent injection (Resistance)

### Maintainability
*Modularity, reusability, analysability, modifiability, testability.*
- [ ] Feature-first architecture is followed (Modularity)
- [ ] No duplicated logic or widgets (Reusability)
- [ ] High widget test coverage (Testability)
- [ ] Architecture decisions are documented for easy updates (Analysability)

### Flexibility
*Adaptability, scalability, installability, replaceability.*
- [ ] Single Flutter codebase supports Android and Windows (Adaptability)
- [ ] Easily installed via standard package formats (Installability)

### Safety
*Operational constraint, risk identification, fail safe, hazard warning, safe integration.*
- [ ] System reverts to safe state on critical errors (Fail safe)
- [ ] Warning dialogues on destructive actions like deletion or voiding (Hazard warning)

---

## TODO
- [ ] Conduct formal ISO/IEC 25010:2023 evaluation during Phase 10
- [ ] Document evaluation score and identified gaps
