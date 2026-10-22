# AI_DEVELOPMENT_RULES.md

> **Session entry requirement (2026-10-22):** Follow root `AGENTS.md` and read `AI_SESSION_HANDOFF.md` completely. Ask whether the current collaborator is Ralston Villamin, MJ Daz, or Hancr Gonzales before project work; reuse an explicit answer within the same conversation. This is self-reported attribution, not authentication. Then follow the project reading order below.

> 2026-10-20 reconciliation: Current defense work is tracked in docs/SECURITY_IMPLEMENTATION_PLAN.md and SECURITY_DEFENSE_RECORD.md. Distinguish observed implementation from older Provider/go_router and phase proposals below. Never infer current security passes from historical DONE labels.
# N.Y Kitchen — AI Development Rules

> **Authority Level: HIGH**
> These rules govern all AI agent behavior throughout the project.
> They are subordinate only to `PROJECT_BLUEPRINT.md` and `RULES.md`.

---

## Mandatory Pre-Task Reading Order

Before performing any task, every AI agent must read the following files **in this order**:

1. `PROJECT_BLUEPRINT.md` — Master source of truth
2. `RULES.md` — Immutable project rules
3. `PROJECT_STATE.md` — Current project phase and status
4. Relevant `docs/` files for the specific feature being worked on
5. `DECISIONS.md` — Existing architectural decisions
6. `ai/CONTEXT.md` — Stable project facts

Skipping this reading order is not permitted.

---

## 1. Scope and Blueprint Rules

- **Always read `PROJECT_BLUEPRINT.md` before implementing any feature.**
- **Never violate the approved project scope.**
- **Never introduce Inventory Management** under any circumstances unless explicitly approved and reflected in `PROJECT_BLUEPRINT.md`.
- Do not add modules, features, or capabilities not listed in the blueprint.
- Do not rename approved modules without architectural review.
- Escalate scope questions to `DECISIONS.md` rather than silently expanding scope.
- Never contradict `PROJECT_BLUEPRINT.md`.

---

## 2. Role and Access Rules

- **Preserve Admin and Cashier role separation at all times.**
- The Cashier must never gain access to Administrator modules.
- Do not introduce additional roles without explicit approval.
- Role checks must be enforced at the application logic layer, not only in the UI.
- Unauthorized access attempts must generate an Activity Log entry.

---

## 3. Offline-First Rules

- **Maintain offline-first operation throughout all development phases.**
- **Keep SQLite as the primary local database.**
- The application must never depend on internet connectivity for core operations:
  - Order processing
  - Transaction saving
  - Receipt generation
  - Menu access
  - Activity logging
  - Local user authentication
  - Account access

---

## 4. Supabase Rules

- **Use Supabase only for approved cloud functionality** (backup, sync, remote access, future analytics).
- Never make core application features dependent on Supabase availability.
- **Never expose the Supabase service-role key in Flutter code.**
- **Never commit Supabase credentials to source control.**
- Use environment-based configuration for all cloud credentials.
- Document all Supabase integration decisions in `docs/SUPABASE_ARCHITECTURE.md` and `DECISIONS.md`.

---

## 5. Security Rules

- **Prioritize the CIA Triad in every design decision:**
  - Confidentiality: Only authorized users access protected data.
  - Integrity: Data cannot be modified without authorization.
  - Availability: The system functions reliably offline.
- **Apply OWASP secure development principles** throughout all phases.
- **Follow ISO/IEC 25010 quality requirements** for all implementations.
- Use parameterized queries exclusively. Direct SQL string concatenation is prohibited.
- Hash all passwords before storage. Plain-text passwords are prohibited.
- Validate all user input on both the UI and logic layers.
- Never expose sensitive error details or system internals to end users.
- Never rely on hidden UI controls for security enforcement.
- Apply least-privilege principles to all data access.
- Never use security-through-obscurity as the only protection mechanism.

---

## 6. Data Integrity Rules

- **Preserve historical transactions.** Completed transactions must never be permanently deleted.
- **Keep activity logs immutable through the normal application interface.**
- Every important action (login, logout, transaction, menu change, backup, user management) must automatically generate an Activity Log entry.
- Void and refund operations require Administrator authorization.
- Food records must not be deleted if they exist in historical transactions; use archiving instead.
- Backup restore must not overwrite the existing database until success is confirmed.

---

## 7. Architecture Rules

- **Use feature-first Flutter architecture.**
- **Use Material 3** as the UI foundation. Do not replace it.
- **Maintain responsive support** for Android Phone, Android Tablet, and Windows Desktop.
- Use the Repository Pattern for data access.
- Use a Service Layer between the UI and data layers.
- Use Provider for state management (confirm before changing).
- Use go_router for navigation (confirm before changing).
- **Avoid duplicate widgets, services, models, and logic.** Prefer reusable components.
- Follow the naming conventions defined in `docs/NAMING_CONVENTIONS.md`.
- Follow the folder structure defined in `docs/FOLDER_STRUCTURE.md`.
- Confirm all architectural decisions in `DECISIONS.md` before implementation.

---

## 8. UI Rules

- Use the design system defined in `docs/DESIGN_SYSTEM.md`.
- Follow the color palette: Yellow, Red, White, Black (Material 3 compatible).
- Maintain accessible color contrast ratios.
- Provide loading states, empty states, error states, and unauthorized pages.
- Implement confirmation dialogs for destructive actions.
- Follow the responsive guidelines in `docs/RESPONSIVE_GUIDELINES.md`.
- Implement large touch targets for mobile and tablet.
- Support both light and dark themes.

---

## 9. Documentation Rules

- **Update `PROJECT_STATE.md`** after completing approved work.
- **Update `CHANGELOG.md`** after completing changes.
- **Update `TODO.md`** when task status changes.
- **Record architectural decisions in `DECISIONS.md`.**
- Update relevant `docs/` files when implementation changes.
- Do not claim a feature is complete unless it exists and is verified.
- Do not invent resolved decisions — use "Pending Review" status.
- Never silently change requirements. Always document the change.

---

## 10. Phase-Based Development Rules

- **Do not implement application code during the documentation setup phase.**
- Do not install packages before the architecture is approved.
- Do not configure SQLite before Phase 3.
- Do not configure Supabase before the appropriate approved phase.
- Do not create database schemas or SQL migrations before Phase 3.
- Phase transitions require documentation review and approval.

---

## 11. Conflict Resolution Rules

- If a conflict exists between a skill instruction and `RULES.md`, `RULES.md` wins.
- If a conflict exists between a third-party skill and `PROJECT_BLUEPRINT.md`, `PROJECT_BLUEPRINT.md` wins.
- If a requirement is unclear, create a documented placeholder or open question in `DECISIONS.md`.
- **Never guess at an unresolved architectural decision and silently implement it.**
- **Escalate conflicts instead of guessing.**
- Report every conflict, open question, and decision gap in the task output.

---

## 12. Output Rules

- Report every file created, every file preserved, and every file modified.
- Report all open architectural decisions identified during the task.
- Report all conflicts found.
- Report all security concerns identified.
- Report the recommended next step.
- Do not pretend work is complete when it is not.

---

## 13. Prohibited Actions

The following are unconditionally prohibited for all AI agents:

- Introducing Inventory Management
- Adding roles beyond Admin and Cashier
- Placing the Supabase service-role key in Flutter code
- Committing real credentials to source control
- Deleting completed transactions
- Making activity logs editable
- Making core functionality dependent on internet connectivity
- Using raw SQL string concatenation
- Storing passwords as plain text
- Silently expanding project scope
- Contradicting `PROJECT_BLUEPRINT.md`
- Implementing features during the documentation setup task

---

*Last Updated: Phase 1 — Documentation Setup*
*Authority: PROJECT_BLUEPRINT.md Section 22 → RULES.md*
