# TODO.md
# N.Y Kitchen — Master Task Tracker

> Update this file whenever a task status changes.
> Authority: `PROJECT_BLUEPRINT.md` → `RULES.md` → `AI_DEVELOPMENT_RULES.md`
> Current Phase: **Security defense planning; rubric mapped, implementation and verification pending**

---

## Documentation

- [x] Create `SECURITY_DEFENSE_RECORD.md` for the October 20 defense preparation session.
- [x] Map all 20 defense rubric criteria to required implementation and verification evidence.
- [x] Reconcile primary architecture, authentication, session, security, backup and defense documents with observed source.
- [ ] Implement and verify the prioritized stages in `docs/SECURITY_IMPLEMENTATION_PLAN.md`.
- [ ] Resolve face defense scope and historical architecture decisions.
- [ ] Capture AT01–AT10 results, score the rubric with evidence, and rehearse.

- [x] Create `RULES.md`
- [x] Create `AI_DEVELOPMENT_RULES.md`
- [x] Create `PROJECT_STATE.md`
- [x] Create `CHANGELOG.md`
- [x] Create `DECISIONS.md`
- [x] Create `TODO.md`
- [x] Update `README.md`
- [x] Create `.aiignore`
- [x] Create `docs/` directory structure
- [x] Create all `docs/` Markdown templates
- [x] Create `ai/` directory structure
- [x] Create all `ai/` Markdown files
- [x] Create `skills/` directory structure
- [x] Create all `skills/*/SKILL.md` files
- [x] Create `skills/REGISTRY.md`
- [x] Create `skills/CONTRIBUTING.md`
- [x] Confirm password hashing algorithm
- [x] Confirm session expiration policy
- [x] Confirm account lockout threshold
- [ ] **Review and approve all generated documentation** (Owner/Supervisor)
- [x] Confirm hybrid offline/online synchronization scope (owner confirmation, 2026-10-20; ADR-002).

---

## Architecture

- [x] Finalize folder structure in `docs/FOLDER_STRUCTURE.md`
- [ ] Confirm state management choice (Provider) — record in `DECISIONS.md`
- [ ] Confirm navigation choice (go_router) — record in `DECISIONS.md`
- [x] Confirm receipt generation packages (printing, pdf)
- [ ] Confirm chart library (fl_chart)
- [x] Confirm SQLite package (drift or sqflite)
- [ ] Design database schema — document in `docs/SQLITE_ARCHITECTURE.md`
- [ ] Define data synchronization strategy — document in `docs/DATA_SYNCHRONIZATION.md`
- [ ] Define sync conflict resolution policy — document in `docs/SYNC_CONFLICT_POLICY.md`
- [ ] Define backup strategy for Android and Windows — document in `docs/BACKUP_STRATEGY.md`

---

## UI/UX (Phase 1 — Static Prototype)

- [x] Set up Figma project and link to `docs/FIGMA_INTEGRATION.md`
- [x] Define design tokens in `docs/DESIGN_SYSTEM.md`
- [x] Create Login Screen (branded, responsive, role selector, show/hide password, remember me)
- [x] Create Admin Dashboard (stat cards, chart, recent transactions, top selling, activities)
- [x] Create Sales Reports (4 tabs, summary cards, transaction table, search, export, print)
- [x] Create Food Management (CRUD table, search, add/edit/delete dialogs)
- [x] Create Account Management (CRUD table, search, add/edit/disable/reset password dialogs)
- [x] Create Activity Logs (audit table, search, role/date filter, export)
- [x] Create Account Settings (profile, theme switch, about, version, save button)
- [x] Create Cashier Home / New Order (3-panel desktop layout)
- [x] Create Cashier Transaction History
- [x] Create Cashier Account Settings
- [x] Create confirmation dialog components (logout, delete)
- [ ] Create Backup & Restore mockup
- [ ] Create Unauthorized Page mockup
- [x] Create loading state components
- [x] Create empty state components
- [x] Create error state components
- [ ] Create receipt preview mockup
- [ ] Create dark and light theme mockups
- [ ] Client review and approval of Phase 1 prototype

---

## Flutter Foundations (Phase 1 prototype; backend architecture deferred)

> Material 3 theme, feature folders, and shared presentation widgets exist for the prototype.
> State management, routing, models, repositories, services, and backend integration remain deferred until approval.

- [x] Set up feature-first folder structure
- [x] Configure Material 3 theme (light prototype)
- [ ] Configure go_router navigation
- [x] Create shared widgets
- [ ] Create domain models
- [ ] Create repository interfaces
- [ ] Create service layer

---

## Responsive Design (Phase 1 prototype)

- [x] Implement mobile layout (drawer nav, single column, bottom sheet)
- [x] Implement tablet layout (compact sidebar, floating checkout)
- [x] Implement desktop layout (3-panel POS, sidebar nav)
- [ ] Convert tables to card layouts on mobile

---

## Accessibility

- [ ] Define accessibility requirements in `docs/ACCESSIBILITY.md`
- [ ] Plan WCAG contrast requirements for color palette
- [ ] Plan large touch targets (` 48dp) for mobile
- [ ] Plan semantic labels for screen readers
- [ ] Test accessibility in Phase 10

---

## SQLite (Phase 3)

- [ ] Select SQLite package (sqflite or drift)
- [ ] Design `users` table
- [ ] Design `food_categories` table
- [ ] Design `food_items` table
- [ ] Design `transactions` table
- [ ] Design `transaction_items` table
- [ ] Design `activity_logs` table
- [ ] Design `login_attempts` table
- [ ] Design `app_settings` table
- [ ] Design `backup_records` table
- [ ] Implement database initialization
- [ ] Implement migration strategy
- [ ] Verify parameterized queries on all operations

---

## Supabase cloud sync — implementation present; verification pending

- [x] Owner approved hybrid offline/online sync with SQLite local storage.
- [x] Add manual and saved-preference automatic push/pull paths.
- [x] Report table-level failures and serialize sync operations.
- [ ] Capture the sanitized table/error code from the top-bar snackbar after a manual sync; the owner changed a mismatched local device-secret setting, but sync still reports failure.
- [ ] Resolve reported `42501` RLS denials by inspecting deployed policy/grant metadata and choosing a cloud identity path; do not grant unrestricted `anon` writes or disable RLS.
- [ ] Confirm configured Supabase project reachability using an approved development session.
- [ ] Inspect deployed schema, least-privilege RLS and device-header enforcement.
- [ ] Provide safe configuration/provisioning for Android; never package device secrets as assets.
- [ ] Demonstrate online sync, offline operation and reconnect with synthetic records.

---

## Synchronization follow-up

- [x] Add device-scoped sale/item IDs and legacy transaction-ID collision recovery; runtime verification remains pending.
- [ ] Run `docs/security/supabase_transaction_id_diagnostic.sql` in development and confirm transaction and item IDs are `bigint` before deploying the new client.
- [ ] Re-test the two-device case with synthetic sales; confirm both distinct receipts, totals, and line items remain visible after repeated manual and automatic sync.
- [ ] Define and verify conflict handling for non-transaction synchronized tables and concurrent status changes.
- [ ] Verify Supabase pagination and behavior above the API's row limit.
- [ ] Verify image upload/download policies and safe retry behavior.
- [ ] Capture manual and automatic sync outcomes for the defense evidence record.

---

## Authentication (Phase 4)

- [ ] Implement login screen logic
- [x] Implement current password hashing (`crypto` SHA-256; stronger KDF review remains pending)
- [ ] Implement failed login counter
- [x] Implement account lockout (5 failed attempts)
- [x] Implement in-memory session management
- [ ] Implement session expiration (12 hours inactivity)
- [ ] Implement automatic logout
- [ ] Implement role-based route protection
- [ ] Implement unauthorized page redirect

---

## Authorization

- [ ] Define route guards in `docs/AUTHORIZATION.md`
- [ ] Implement Admin route guards
- [ ] Implement Cashier route guards
- [ ] Test role bypass attempts

---

## Session Management

- [ ] Define session expiration policy
- [ ] Implement session token storage
- [ ] Implement session expiration check
- [ ] Implement logout session cleanup
- [ ] Test session timeout behavior

---

## Security

- [ ] Review CIA Triad implementation against `docs/CIA_TRIAD.md`
- [ ] Complete OWASP checklist in `docs/OWASP_CHECKLIST.md`
- [ ] Complete ISO/IEC 25010 evaluation in `docs/ISO25010_EVALUATION.md`
- [ ] Complete threat model in `docs/THREAT_MODEL.md`
- [ ] Verify no plain-text passwords stored
- [ ] Verify parameterized queries throughout
- [ ] Verify activity logs are immutable
- [ ] Verify no secrets committed to source control
- [ ] Perform security testing per `docs/SECURITY_TESTING.md`

---

## Activity Logs (Phase 8)

- [ ] Implement automatic logging for all tracked events:
  - [ ] Login (success and failure)
  - [ ] Logout
  - [ ] Transaction completed
  - [ ] Transaction voided
  - [ ] Transaction refunded
  - [ ] Menu item added
  - [ ] Menu item edited
  - [ ] Menu item archived
  - [ ] User created
  - [ ] User edited
  - [ ] User deactivated
  - [ ] Password reset
  - [ ] Backup created
  - [ ] Backup restored
  - [ ] Unauthorized access attempt
- [ ] Implement read-only log viewer
- [ ] Implement log search and filters
- [ ] Implement log export (PDF, CSV)

---

## Transactions (Phase 6)

- [ ] Implement order creation
- [ ] Implement food item selection
- [ ] Implement quantity management
- [ ] Implement payment method selection
- [ ] Implement checkout process
- [ ] Implement receipt generation
- [ ] Implement receipt printing
- [ ] Implement transaction history
- [ ] Implement void transaction (Admin only)
- [ ] Implement refund transaction (Admin only)
- [ ] Verify completed transactions cannot be deleted

---

## Menu Management (Phase 5)

- [ ] Implement category CRUD
- [ ] Implement food item CRUD
- [ ] Implement food image handling (local storage, path-based)
- [ ] Implement food availability toggle
- [ ] Implement food archiving
- [ ] Verify archived food items appear on old receipts
- [ ] Verify archived food items cannot be added to new orders

---

## User Management (Phase 7)

- [ ] Implement add user
- [ ] Implement edit user
- [ ] Implement activate/deactivate user
- [ ] Implement reset password
- [ ] Implement unlock account
- [ ] Implement change user role
- [ ] Verify final active Admin cannot deactivate itself

---

## Receipts (Phase 6)

- [ ] Define receipt format in `docs/RECEIPT_SYSTEM.md`
- [ ] Implement receipt number generation (unique)
- [ ] Implement receipt rendering (business info, items, totals)
- [ ] Implement receipt preview
- [ ] Implement receipt printing
- [ ] Implement receipt reprint (with Activity Log)
- [ ] Implement receipt storage (local PDF — future)

---

## Reports (Phase 9)

- [ ] Implement daily sales report
- [ ] Implement weekly sales report
- [ ] Implement monthly sales report
- [ ] Implement annual sales report
- [ ] Implement best-selling foods report
- [ ] Implement cashier performance report
- [ ] Implement login/security summary report
- [ ] Implement report export (PDF, CSV)

---

## Backup and Restore

- [ ] Define backup strategy in `docs/BACKUP_STRATEGY.md`
- [ ] Implement manual backup
- [ ] Implement backup history view
- [ ] Implement backup restore
- [ ] Implement backup Activity Log
- [ ] Verify database preserved until restore succeeds
- [ ] Test backup on Android
- [ ] Test backup on Windows

---

## Testing

- [ ] Write unit tests for validation rules
- [ ] Write unit tests for password hashing
- [ ] Write unit tests for transaction logic
- [ ] Write widget tests for major screens
- [ ] Write integration tests for checkout flow
- [ ] Write integration tests for login flow
- [ ] Write security tests per `docs/SECURITY_TESTING.md`
- [ ] Test offline behavior
- [ ] Test on Android phone
- [ ] Test on Android tablet
- [ ] Test on Windows desktop

---

## QA

- [ ] Complete QA checklist in `docs/QA_CHECKLIST.md`
- [ ] Complete test cases in `docs/TEST_CASES.md`
- [ ] Verify responsive layouts on all target devices
- [ ] Verify all validation rules
- [ ] Verify all activity log triggers
- [ ] Verify role-based access enforcement

---

## Performance

- [ ] Define performance targets in `docs/PERFORMANCE_PLAN.md`
- [ ] Profile login flow
- [ ] Profile transaction save
- [ ] Profile menu loading
- [ ] Profile report generation
- [ ] Optimize SQLite queries

---

## Android Deployment (Phase 11)

- [ ] Configure Android signing
- [ ] Configure minSdk and targetSdk
- [ ] Build release APK
- [ ] Test release build on Android phone
- [ ] Test release build on Android tablet
- [ ] Document deployment steps in `docs/ANDROID_DEPLOYMENT.md`

---

## Windows Deployment (Phase 11)

- [ ] Configure Windows build
- [ ] Build Windows installer
- [ ] Test on Windows desktop
- [ ] Document deployment steps in `docs/WINDOWS_DEPLOYMENT.md`

---

## Supabase Deployment and validation

- [ ] Confirm development/production project separation and apply reviewed RLS policies.
- [ ] Configure deployment environment variables without embedding client secrets.
- [ ] Document deployment steps in `docs/SUPABASE_DEPLOYMENT.md`
- [x] Inspect `public.users` required columns; the 2026-10-23 result showed `password_hash` NOT NULL. **Superseded:** the owner-supplied `main` / `PRODUCTION` SQL Editor result on 2026-10-24 shows `password_hash` exists and is nullable (`YES`). The reason for the schema change is unknown; no migration application by this assistant is claimed.
- [ ] Confirm the current schema and migration provenance in the intended development project; validate profile upload/pull with synthetic data before Production use. Do not apply the prepared nullable-column migration based only on the stale 2026-10-23 result.
- [x] Compare Production `transactions` and `transaction_items` with local SQLite by ID and content using read-only queries. Every local ID exists in Production; 10 cloud-only transactions and 11 cloud-only items remain.
- [ ] Resolve 14 transaction status conflicts before any Supabase sync: 13 cloud `Served` versus local `Ready`/`Taken`/`Preparing`, and one cloud `Voided` versus local `Preparing`. A Supabase full sync upserts all local rows and could overwrite cloud statuses.
- [ ] Configure Flutter for Ubuntu using the local `.env` and a current device token, then validate one authenticated upload. The first cycle includes all 41 historical local sales; Ubuntu does not pull the cloud-only rows.
- [ ] Before starting the POS, inspect the target terminal's sync mode. This workspace had `SYNC_BACKEND` unset and saved sync mode `automatic`; its current default starts a Supabase full sync on startup and every 15 seconds. No POS process was running here when checked.
- [ ] Review the live Production RLS policy's effective write checks. The 2026-10-24 screenshot showed RLS enabled/not forced, one permissive `ALL` policy per sync table with a `check_device_secret` call in `USING`, no explicit `WITH CHECK` expression, and anon/authenticated SELECT/INSERT/UPDATE grants. Check PostgreSQL's default check behavior, inspect the policy function and verify effective INSERT/UPDATE authorization before claiming safe sync.
- [ ] Verify new-device account provisioning: cloud profiles do not transfer passwords; an Admin must reset each imported account's local password on that device.

---

## Presentation (Phase 11)

- [ ] Prepare demo script per `docs/CLIENT_DEMO_PLAN.md`
- [ ] Prepare final defense slides per `docs/DEFENSE_PLAN.md`
- [ ] Record demo video (optional)
- [ ] Prepare presentation per `docs/PRESENTATION.md`

---

## Final Defense (Phase 11)

- [ ] Complete all features
- [ ] Complete all testing
- [ ] Complete all documentation
- [ ] Prepare defense presentation
- [ ] Practice demo walkthrough
- [ ] Prepare Q&A responses for security topics
- [ ] Prepare Q&A responses for architecture decisions

## Ubuntu backend — deployment status updated 2026-10-24

- [x] Prepare isolated sales API, provisioner and Ubuntu deployment configuration.
- [x] Connect Flutter backend mode with safe retries and no concurrent Supabase sync.
- [x] Run targeted backend and Flutter tests (11 + 4 passed).
- [x] Deploy Ubuntu VM backend; owner-supplied screenshots show systemd API/Caddy active, UFW scoped to the host-only subnet, and Windows HTTPS health checks succeeding with the local Caddy root trusted.
- [x] Owner-operated direct API demo: one synthetic sale from Windows PowerShell returned HTTP 200, `accepted=1`, `new_revisions=1` through Caddy. This proves the manual HTTPS API path, not Flutter synchronization; see `docs/security/evidence/2026-10-defense/backend_verification.md`.
- [ ] Demonstrate real Flutter offline/reconnect sync and server role denial.
- [x] Run `pip-audit` against the deployed VM's resolved Python packages; the owner-supplied output reported “No known vulnerabilities found” for that scan snapshot.
- [ ] Verify Flutter/Dart/Android HTTPS trust, credential rotation/revocation, server recovery and reboot persistence over the running VM.
- [ ] Resolve local repository authorization findings separately.

## AI session continuity

- [x] Add root `AGENTS.md` and required `AI_SESSION_HANDOFF.md`.
- [x] Record current self-reported session owner: Ralston Villamin.
- [ ] Keep the handoff and evidence status current after future implementation sessions.
