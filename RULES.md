# RULES.md
# N.Y Kitchen — Immutable Project Rules

> **Authority Level: HIGHEST**
> These rules cannot be overridden by any skill, agent, or developer instruction.
> All changes must be explicitly approved by the project owner and reflected in PROJECT_BLUEPRINT.md first.

---

## 1. Source of Truth

- `PROJECT_BLUEPRINT.md` is the **single source of truth** for all project decisions.
- Read `PROJECT_BLUEPRINT.md` before performing any task.
- No rule, skill, agent instruction, or personal preference may contradict `PROJECT_BLUEPRINT.md`.
- Any apparent contradiction must be escalated — never silently resolved.

---

## 2. Scope Rules

- **Never introduce Inventory Management** unless explicitly approved in writing by the project owner and reflected in `PROJECT_BLUEPRINT.md`.
- **Only two user roles are permitted:** Administrator and Cashier.
- Do not add new roles (e.g., Super Admin, Manager, Owner) without explicit approval.
- Do not add modules that are not listed in the approved project scope.
- Scope expansion must be documented in `DECISIONS.md` and reviewed before implementation.

---

## 3. Technology Rules

- **Flutter and Dart** are the only approved application technologies.
- **Material 3** is the approved UI foundation. Do not replace it with other design systems.
- **SQLite** is the primary local database. It must never be removed.
- **Supabase** is an optional cloud platform for future approved features only.
- Do not make the application dependent on continuous internet connectivity.
- Do not replace SQLite with Supabase as the sole database.
- State management uses **Provider** (subject to architectural review before change).
- Navigation uses **go_router** (subject to architectural review before change).

---

## 4. Platform Rules

- The application must support **Android Phone**, **Android Tablet**, and **Windows Desktop**.
- Responsive design is mandatory.
- Do not drop platform support without explicit approval.

---

## 5. Offline-First Rules

- The application must function completely offline.
- Loss of internet access must never stop:
  - Local login for provisioned users
  - Order processing
  - Transaction saving
  - Receipt generation
  - Menu access
  - Activity logging
  - Local reporting
  - Account access based on local authorization

---

## 6. Security Rules

- **Security is the highest project priority.**
- Apply the CIA Triad throughout all development phases.
- Follow OWASP Secure Coding Principles.
- Evaluate quality using ISO/IEC 25010.
- Never store passwords as plain text. Always use hashing.
- Never expose sensitive error details to end users.
- Validate all user input on both UI and logic layers.
- Use parameterized queries. Never use raw SQL string concatenation.
- Do not rely on hidden UI controls for authorization enforcement.
- Enforce authorization at the application logic layer, not only at the UI layer.

---

## 7. Credential Rules

- **Supabase credentials must never be committed to source control.**
- **The Supabase service-role key must never be placed inside the Flutter client.**
- Store secrets outside the application codebase using environment configuration.
- Never upload plain-text passwords to Supabase or any external service.
- Never synchronize sensitive secrets through the sync pipeline.
- Document credential rotation procedures in `docs/SUPABASE_ARCHITECTURE.md`.

---

## 8. Data Integrity Rules

- **Completed transactions must never be permanently deleted.**
- Void and refund operations require Administrator authorization and an Activity Log entry.
- **Activity logs must not be editable or deletable through the normal application interface.**
- Historical transaction records must be preserved.
- Food records must not be permanently deleted if they exist in historical transactions.
- Archived food items remain visible on old receipts but cannot be selected for new orders.
- Backup restore must preserve existing data until a successful restoration is confirmed.

---

## 9. Supabase Rules

- Enable Row-Level Security (RLS) on all protected Supabase tables.
- Use least-privilege access for all Supabase operations.
- Separate development and production Supabase environments.
- Do not permit cloud sync to overwrite immutable transactions without review.
- Log all sensitive cloud actions.
- Protect personally identifiable information in cloud storage.

---

## 10. Documentation Rules

- Documentation must be updated whenever implementation changes.
- `PROJECT_STATE.md` must be updated after approved work.
- `CHANGELOG.md` must be updated after completed changes.
- `TODO.md` must be updated when task status changes.
- Architectural decisions must be recorded in `DECISIONS.md`.
- Do not claim a feature is complete unless it actually exists in the codebase.
- Do not invent resolved decisions. Use Pending Review for unresolved items.

---

## 11. Phase Rules

- **No implementation is allowed during the documentation setup task (Phase 1 preparation).**
- Do not write Flutter feature code before completing documentation and receiving approval.
- Do not install packages before architecture is approved.
- Do not configure SQLite or Supabase before the appropriate phase begins.
- Do not create database schemas or SQL migrations before Phase 3.

---

## 12. Agent and AI Rules

- Read `RULES.md` before performing any task.
- Read the relevant specialized documentation in `docs/` before modifying a feature.
- Never silently change requirements.
- Escalate conflicts instead of guessing.
- Record all architectural decisions in `DECISIONS.md`.
- Do not expand scope beyond what is approved in `PROJECT_BLUEPRINT.md`.

---

*Last Updated: Phase 1 — Documentation Setup*
*Authority: PROJECT_BLUEPRINT.md Section 22*
