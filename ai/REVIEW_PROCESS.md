# ai/REVIEW_PROCESS.md
# N.Y Kitchen — Review Process

---

## Purpose
Define the review requirements for all code, architecture, UI, and documentation changes.

---

## Architecture Review
- Required before: New architectural patterns, new packages, significant structural changes.
- Reviewer: Senior Architect agent.
- Output: Decision recorded in DECISIONS.md.
- Gate: Must be completed before implementation begins.

## Security Review
- Required before: Authentication implementation, database access, credential handling, route guards.
- Reviewer: Security Engineer agent.
- Output: Security concerns documented in docs/SECURITY.md and DECISIONS.md.
- Gate: Must pass security review before Phase 4 begins.

## UI Review
- Required before: Phase 1 prototype delivery to client.
- Reviewer: UI/UX Designer + Project Manager.
- Output: Client approval or revision notes.
- Gate: Client must approve Phase 1 before Phase 2 begins.

## Code Review
- Required before: Merging any feature into the main codebase.
- Reviewer: Code Reviewer agent + Senior Architect.
- Checklist:
  - Follows coding standards (docs/CODING_STANDARDS.md)
  - Follows naming conventions (docs/NAMING_CONVENTIONS.md)
  - No hardcoded credentials
  - No raw SQL string concatenation
  - Tests written and passing

## QA Review
- Required before: Phase sign-off.
- Reviewer: QA Engineer.
- Output: QA Checklist completed (docs/QA_CHECKLIST.md).
- Gate: All QA items must pass before phase sign-off.

## Documentation Review
- Required before: Phase transitions.
- Reviewer: Documentation Specialist.
- Checklist:
  - PROJECT_STATE.md updated
  - CHANGELOG.md updated
  - TODO.md updated
  - Relevant docs/ files updated
  - No documentation contradicts implementation

## Approval Before Merging
- Architecture review approved.
- Security review approved.
- Code review approved.
- QA review approved.
- Documentation review approved.
- Project Manager sign-off on scope compliance.
