# N.Y Kitchen — Security and Defense Session Record

## Session baseline

- Started: October 20, 2026 (Asia/Manila).
- Defense target: Thursday, October 22, 2026, inferred from the owner's message.
- Purpose: recover project context, track security polishing, map supplied rubrics to evidence, and record results across sessions.
- Current scope: source inspection and documentation only.
- Rubric: received and mapped on October 20; see `docs/SECURITY_IMPLEMENTATION_PLAN.md`. Further institution-specific requirements may still be supplied.
- Overall assessment: **Not assessed against the defense rubric.**
- No app launch, automated tests, dependency audit, database modification, or live cloud inspection was performed in this session.
- Existing test outputs and earlier “DONE” labels are historical evidence, not fresh verification.

## What this project is

N.Y Kitchen Secure Order and Sales Management System is a Flutter/Dart POS application for a small food stall. It records orders and sales, manages food menus and accounts, generates receipts and reports, and records activity for accountability. SQLite is the local data store. The intended deployment platforms are Windows desktop and Android phones/tablets.

The two roles are Administrator and Cashier. Administrator pages cover dashboard, menu management, account management, reporting, activity logs, settings, and backup/restore. Cashier pages cover home, orders, transaction history, personal activity logs, and account settings. Inventory management is explicitly excluded.

The source also contains optional Supabase synchronization and a Python FastAPI face recognition/liveness service. Presence of these components does not establish that they are configured, reachable, or fully connected to the current UI.

## Practical structure map

| Location | Purpose |
|---|---|
| `lib/main.dart` | Startup, environment loading, optional Supabase initialization, desktop window setup, app root, inactivity timer |
| `lib/features/auth/presentation/` | Login, route guard, forced password change dialog |
| `lib/features/admin/presentation/` | Administrator pages, navigation, and widgets |
| `lib/features/cashier/presentation/` | Cashier pages, order widgets, and navigation |
| `lib/features/shared/` | Shared UI components; several similar component families coexist |
| `lib/core/database/database_helper.dart` | SQLite creation, upgrades, foreign key configuration, seed records |
| `lib/core/database/repositories/` | Users, food, transactions, audit records, database export |
| `lib/core/session/session_manager.dart` | In-memory user session, inactivity tracking, logout logging |
| `lib/core/utils/security_utils.dart` | Password hashing/policy and face encoding encryption |
| `lib/core/services/sync_service.dart` | Supabase push/pull and food image upload/download |
| `lib/core/services/export_service.dart` | Reporting/export support |
| `lib/core/services/ai_service_client.dart` | Local face service HTTP client |
| `ai_service/main.py` | FastAPI face encoding and eye closure endpoints |
| `lib/core/theme/`, `assets/` | Theme, design tokens, branding assets |
| `test/`, `ai_service/tests/` | Existing Dart and Python test sources |
| `docs/`, `specs/` | Requirements, architecture, security, UI, and deployment documentation |
| `docs/security/evidence/` | Historical security verification outputs |
| `scripts/` | Supporting scripts, including secret rotation verification |
| `ai/`, `skills/` | Development workflow material, separate from app runtime |
| Root Markdown and Python files | Multiple historical session records, specifications, and editing helpers |
| Platform folders | Flutter platform scaffolding; folder presence alone does not establish supported deployment |
| `build/`, `.dart_tool/` | Generated build/tool artifacts |

SQLite tables observed: `users`, `food_categories`, `food_items`, `transactions`, `transaction_items`, `activity_logs`, `login_attempts`, `app_settings`, and `backup_records`.

The current app uses `MaterialApp`, Flutter `Navigator`, stateful widgets, and singleton services. Provider and go_router appear in older architecture documents but are absent from the current dependency manifest.

## Main data flow

1. Startup loads configuration, optionally initializes Supabase, configures the desktop database/window environment, and displays login.
2. Password login queries SQLite through `UserRepository`, checks account status, verifies the password hash, and records successful/failed attempts for known active users.
3. `SessionManager` stores the authenticated user in memory. Login routes to the appropriate role shell.
4. Pages access repositories for local business operations. Transaction creation writes the transaction and its items inside a SQLite transaction.
5. Audit records capture selected account, authentication, transaction, and menu actions.
6. Optional synchronization pushes local records and downloads cloud records into SQLite.
7. Reporting and backup functions export data for viewing, printing, or sharing.

## Security controls observed in code

These are implementation observations, **not verified passes**.

| Control | Source evidence | Current observation |
|---|---|---|
| Password hashing | `lib/core/utils/security_utils.dart` | PBKDF2-HMAC-SHA256, random per-password salt, 10,000 iterations |
| Password policy helper | Same file | Minimum 8 characters, at least one letter and one digit |
| Account lockout | `user_repository.dart`, `login()` | Active known account becomes locked after five failed attempts |
| Forced password change | Database seed/migration, session manager, auth dialog | Flag and supporting implementation exist; end-to-end enforcement needs review |
| Session expiry | `session_manager.dart`, `main.dart` | 30-minute inactivity limit, checked periodically |
| Route protection | `features/auth/presentation/widgets/guarded_route.dart` | Role/session guard exists; coverage needs review |
| Parameterized access | User and transaction repositories | Inspected value-based queries use bound parameters |
| Atomic sale creation | `transaction_repository.dart` | Transaction header and items are written inside `db.transaction` |
| Audit logging | Repositories and session manager | Selected events are logged; completeness and durability need verification |
| Face data encryption | `security_utils.dart` | AES-CBC with key and IV stored through Flutter secure storage |
| Local service authentication | `ai_service/main.py` | Both face endpoints require `X-Service-Key`; direct script launch binds to loopback |
| Cloud password exclusion | `sync_service.dart` | Outgoing user records remove `password_hash` |

## Initial findings and follow-up queue

These findings come from selected source inspection. They are not an exhaustive security audit or a claim that an exploit was demonstrated.

| ID | Observation and source | Follow-up | Status |
|---|---|---|---|
| SEC-01 | User mutation methods accept target IDs/data without checking the acting session in the inspected repository. Transaction status updates accept caller-supplied role metadata without enforcing Admin authorization. | Trace every caller and enforce permissions in the business/data layer. | Open |
| SEC-02 | `syncFromCloud()` uses SQLite replacement for downloaded rows, including user and transaction data; outgoing sync uses upsert. | Assess immutable records, role/account changes, ID collisions, and conflict policy. Inspect actual deployed RLS separately. | Open |
| SEC-03 | `BackupRepository.exportDatabase()` exports all table rows into an unencrypted SQL file, including stored user fields. It logs a placeholder Admin ID. | Define protected backup contents, genuine actor attribution, secure storage/export, and a demonstrated restore path. | Open |
| SEC-04 | Face encryption reuses a stored IV; no authentication tag is implemented. Decryption returns the input string on error. | Review authenticated encryption, migration, failure handling, and portability of device-bound keys. | Open |
| SEC-05 | Password hashing uses 10,000 iterations; password change repository method does not itself enforce the policy helper. | Review hashing parameters and migration, and enforce policy consistently at the logic layer. | Open |
| SEC-06 | `main.dart` displays exception text in its error widget; Python endpoints return exception strings. | Replace user-visible internals with safe errors and suitable diagnostic logging. | Open |
| SEC-07 | Desktop environment loading stores values in a local map, while the default AI client reads `dotenv`. | Trace configuration propagation; confirm the client receives its service key on each target platform. | Needs verification |
| SEC-08 | `main.dart` starts cloud synchronization before desktop SQLite FFI setup. Supabase initialization is awaited outside an offline fallback catch. | Review startup ordering and failure behavior with configuration present but cloud unavailable. | Needs verification |
| SEC-09 | Seed accounts use known initial credentials and forced-change flags. | Demonstrate first-login restrictions and ensure alternate paths cannot bypass them. Do not reproduce credentials in defense evidence. | Needs verification |
| SEC-10 | Face API reads complete uploads into memory and returns raw processing errors. | Review upload limits, image validation, resource limits, and liveness assumptions if this feature is in defense scope. | Open |
| SEC-11 | Login returns immediately for unknown or non-active accounts without logging those attempts in the inspected method. | Define audit coverage for all rejected authentication paths and protect audit integrity. | Open |

## Documentation conflicts to resolve

- `README.md` says cloud sync is not implemented; source contains push/pull sync, while `PROJECT_STATE.md` says it is completed.
- Resolved 2026-10-20: owner confirmed hybrid offline/online operation with online synchronization. Blueprint and ADR-002 now include synchronization; deployment and security verification remain pending.
- Provider/go_router documentation differs from current dependencies and navigation.
- `docs/SECURITY.md` still labels the hashing algorithm TBD despite implemented PBKDF2.
- ADR-016 describes copying a SQLite database with retention; the inspected repository exports MySQL-style SQL inserts. A successful restore is not established by that exporter.
- Earlier remediation records mention a face login widget whose integration into the current login flow has not been established.
- Phase labels and completion claims differ across existing documents. Preserve them as historical context until reconciled with current source and evidence.

Existing references: `SECURITY_REMEDIATION_LOG.md`, `SECURITY_FEATURES.md`, root and `docs/security/` IAS profiles, `docs/THREAT_MODEL.md`, and `docs/SECURITY_TESTING.md`. This record is the new session index; it does not replace the approved requirements.

## Rubric tracking

Use these statuses: **Not assessed**, **In progress**, **Pass**, **Fail**, **Blocked**, **Not applicable**.

A Pass needs the exact criterion, implementation evidence, and verification appropriate to that criterion. A code reference alone does not prove runtime behavior. Record failures and limitations explicitly; do not carry historical passes forward automatically.

| Rubric ID | Exact criterion | Implementation evidence | Verification and date | Result | Remaining work |
|---|---|---|---|---|---|
| R01–R20 | Exact criteria mapped in `docs/SECURITY_IMPLEMENTATION_PLAN.md` | Current source baseline and proposed controls | No new execution evidence | Not scored | Implement, verify, and assess against the supplied descriptors |

## Session history

| Date | Work | Files changed | Verification | Outcome |
|---|---|---|---|---|
| 2026-10-20 | Initial project reconnaissance and security baseline | This record; brief entries in project state, changelog, TODO | Source/document inspection only | Structure mapped; initial findings recorded; rubric pending |
| 2026-10-20 | Read supplied XLSX; map 20 criteria; prioritize controls and defense evidence; reconcile older primary guides | Implementation plan, primary documentation, historical-status notices and tracking files | Workbook extraction, source comparison, official references and documentation checks | Plan prepared; no runtime security pass or numeric score assigned |

Pre-existing workspace changes were present in theme/admin UI files and generated platform plugin files, plus an untracked LUMORA document. They were preserved. No application code was changed during this session.

For each later session, append the objective, exact files changed, finding/rubric IDs addressed, verification performed, evidence location, remaining issues, and next step. Keep secrets and personal data out of this record.

Owner clarification: Linux meant a virtual machine and can be omitted if not needed. Recommended base setup is Windows; no VM, Docker or new server is required for the offline POS. ZAP is optional for the HTTP API.

Next step: implement Stage 1 repository authorization and account/session checks, then execute its acceptance tests against disposable fixtures. Follow the remaining stages in `docs/SECURITY_IMPLEMENTATION_PLAN.md`.

## Scope confirmation — 2026-10-20

Owner confirmed: the system is hybrid online/offline with online synchronization. The previous cloud scope contradiction is resolved in the blueprint and ADR-002. No application code changed; security findings remain open until verified.

## Implementation session — 2026-10-22

Owner approved keeping Flutter and adding an Ubuntu VM backend; VM will be installed later. Implemented a one-way sales synchronization service and Flutter integration, plus provisioning/deployment guide. Backend mode disables direct Supabase synchronization for that run. No runtime secrets, real data or cloud settings were changed.

Verified 11 backend and 4 Flutter tests using synthetic credentials and isolated/in-memory data. Evidence: `docs/security/evidence/2026-10-defense/backend_verification.md`. This does not mark AT01–AT10 fully passed: existing local authorization, VM TLS, complete recovery, cloud and Android checks remain open.

## AI continuity handoff — 2026-10-22 (Asia/Manila)

- Session owner: Ralston Villamin, self-reported in this conversation.
- Request: require future AI sessions to identify the collaborator and read the security/rubric plan.
- Added root `AGENTS.md` and `AI_SESSION_HANDOFF.md`; linked them from README and AI development rules.
- Preserved collaborators exactly as supplied: Ralston Villamin, MJ Daz, Hancr Gonzales. Specific job responsibilities were not assigned.
- Rubric relevance: R19 traceability and session attribution. No new security-test pass or rubric score.
- Verification: checked the new files and documentation diff; no application code changed or runtime tests run.
- Next step: identify the next session owner, inspect current source, then continue Ubuntu deployment or authorized repository security work.

## GitHub push preparation and UI reconciliation session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T13:05:00+08:00 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope: Prepare and push N.Y Kitchen changes to GitHub following the approved Flutter POS + offline SQLite + Ubuntu backend replication architecture. Reconcile UI changes, verify tests and analyzers, screen secrets and artifacts, update session records, and push to origin/main without force-pushing.
Rubric / risk / acceptance-test IDs: R13–R16 (Assurance, testing & verification), R19–R20 (Readiness & traceability), AT07/AT09/AT10 (Replication & integration boundaries), SEC-01–SEC-11.
Files changed:
- Documentation & Handoff: `AGENTS.md`, `AI_SESSION_HANDOFF.md`, `SECURITY_DEFENSE_RECORD.md`, `docs/SECURITY_IMPLEMENTATION_PLAN.md`, `docs/security/evidence/2026-10-defense/*`, `PROJECT_BLUEPRINT.md`, `PROJECT_STATE.md`, `DECISIONS.md`, `CHANGELOG.md`, `TODO.md`, `README.md`, `RULES.md`, `SECURITY_FEATURES.md`, `SECURITY_REMEDIATION_LOG.md`, `docs/*`.
- Ubuntu Sales Replication Backend: `backend/app.py`, `backend/provision.py`, `backend/README.md`, `backend/requirements.txt`, `backend/requirements-test.txt`, `backend/__init__.py`, `backend/deploy/*`, `backend/tests/*`.
- Flutter POS Integration & UI: `lib/core/services/backend_sync_service.dart`, `lib/core/services/sync_service.dart`, `lib/main.dart`, `lib/core/theme/app_theme.dart`, `lib/features/auth/presentation/pages/login_page.dart` (restored classic pastil showcase and floating promo elements), `lib/features/admin/presentation/pages/account_management_page.dart`, `lib/features/admin/presentation/pages/sales_reports_page.dart`, `lib/features/admin/presentation/widgets/food_emoji_picker_dialog.dart`, `.env.example`, `.gitignore`.
- Tests: `test/security/backend_sync_test.dart`, `test/security/account_lockout_test.dart`, `test/security/ai_service_client_test.dart`, `test/security/authorization_guard_test.dart`.
Checks actually run and actual results:
- `flutter test test/security/`: 39/39 security tests passed (including backend sales sync, account lockout, force password change, session expiry, route guards).
- `flutter test test/widget/auth_phase4_test.dart test/widget/food_management_panel_test.dart test/security/backend_sync_test.dart`: 8/8 tests passed.
- `dart analyze lib/features/auth/presentation/pages/login_page.dart`: No issues found (resolved unused import).
- `git check-ignore -v .env backend/.env`: Verified `.env` files are ignored; confirmed secrets/credentials are strictly excluded from git staging.
Evidence paths:
- `docs/security/evidence/2026-10-defense/backend_verification.md`
- `SECURITY_DEFENSE_RECORD.md`
Unverified items / remaining risks:
- VM/HTTPS verification: Ubuntu VM service is not yet deployed or verified against real network TLS certificates.
- Local repository authorization: SEC-01 permissions enforcement in local SQLite repositories remains open and pending.
- No claim of full rubric compliance or full production deployment.
Next concrete step: Deploy Ubuntu service onto the VM once provisioned, configure Caddy TLS, and execute end-to-end network replication tests and local repository authorization enforcement.

## Login Password Change Bug Fix Session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T14:46:00+08:00 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope: Fix default credentials login and force password change dialog failure ("Error: Unsupported operation: read-only") blocking entry as admin/cashier into the application.
Rubric / risk / acceptance-test IDs: R10 (Authentication & Access Controls), AT01 (Account Authentication and Lockout), Gap 3 / SEC-09 (Forced Initial Password Change).
Files changed:
- `lib/core/database/repositories/user_repository.dart`
- `lib/features/auth/presentation/widgets/force_change_password_dialog.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- Root cause: SQLite `db.query()` returns read-only map instances. When `force_change_password_dialog.dart` attempted in-place update `widget.user['must_change_password'] = 0`, Dart threw `Unsupported operation: read-only`.
- Fix: `UserRepository.login` now wraps `updatedMaps.first` in `Map<String, dynamic>.from(...)`. `login_page.dart` ensures a mutable copy is passed to the dialog, and `force_change_password_dialog.dart` guards the local map mutation.
- `flutter test test/security/force_password_change_test.dart`: 6/6 tests passed.
- `flutter analyze lib/core/database/repositories/user_repository.dart lib/features/auth/presentation/widgets/force_change_password_dialog.dart lib/features/auth/presentation/pages/login_page.dart`: No issues found (0 warnings, 0 errors).
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Test logging in with admin/admin123 or cashier/cashier123, set new passwords (e.g., `admin1234` / `cashier1234`), and proceed to the admin/cashier shell.

## Manual Cloud Sync Button & Background Polling Deactivation Session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T15:48:00+08:00 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope: Remove automatic background cloud sync timers and provide interactive manual 2-way Cloud Sync button on both Admin and Cashier screens.
Rubric / risk / acceptance-test IDs: R08/R10 (Security controls & system operation), AT10 (Integration boundaries and network failure resilience), SEC-02 (Cloud synchronization data protection).
Files changed:
- `lib/main.dart`
- `lib/core/services/sync_service.dart`
- `lib/features/shared/widgets/manual_sync_button.dart`
- `lib/features/shared/widgets/app_status_strip.dart`
- `lib/features/cashier/presentation/pages/home_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- Disabled automatic background sync timers in `lib/main.dart` (preventing unsolicited cloud calls during offline shifts).
- Implemented `fullSync()` in `SyncService` providing unified 2-way sync (push local offline changes, then pull cloud updates).
- Built interactive `ManualSyncButton` with spinning refresh animation, floating status SnackBar notifications, and offline resilience.
- Placed `ManualSyncButton` in the top bar for both Admin (`AppStatusStrip`) and Cashier (`CashierHomePage`).
- `flutter analyze lib/features/shared/widgets/manual_sync_button.dart`: Passed cleanly (0 issues).
- `flutter test test/security/force_password_change_test.dart test/security/account_lockout_test.dart`: 10/10 tests passed.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Unverified items / remaining risks:
- Live network reachability depends on active internet connection when the button is manually pressed; offline failure is safely caught without app interruption.
Next concrete step: Launch or hot restart the app and test the Cloud Sync button in both Admin and Cashier screens.

## Cloud Sync Settings, Single Top-Bar Button & Admin Transaction Visibility Session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T18:05:00+08:00 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope:
1. Add Cloud Synchronization options in Settings for both Admin and Cashier:
   - **Manual Cloud Sync:** Only one single "Cloud Sync" button appears at the top status bar (removes redundant second button in Cashier menu bar).
   - **Automatic Cloud Sync:** Background synchronization periodically syncing across all devices via Supabase.
2. Fix issue reported by collaborator MJ Daz where newly transacted orders were not appearing in Admin sales reports after cloud syncing.
Rubric / risk / acceptance-test IDs: R08/R10 (Security controls & system operation), AT10 (Integration boundaries and network resilience), SEC-02 (Cloud synchronization data protection).
Files changed:
- `lib/core/services/sync_service.dart` (dynamic syncMode state, persistence in app_settings table, onSyncCompletedNotifier)
- `lib/features/shared/widgets/manual_sync_button.dart` (reactive auto-hiding when in automatic mode)
- `lib/features/cashier/presentation/pages/home_page.dart` (removed duplicate sync button)
- `lib/features/admin/presentation/pages/admin_account_settings_page.dart` (added Cloud Synchronization settings)
- `lib/features/cashier/presentation/pages/account_settings_page.dart` (added Cloud Synchronization settings)
- `lib/features/admin/presentation/pages/sales_reports_page.dart` (reactive sync listener for instant transaction updates)
- `lib/features/admin/presentation/pages/admin_dashboard_page.dart` (reactive sync listener & metrics update; fixed FoodImage import)
- `lib/main.dart` (syncMode initialization on startup)
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze lib/features/admin/presentation/pages/admin_dashboard_page.dart`: No issues found! (ran cleanly in 8.2s).
- `flutter test test/security/force_password_change_test.dart test/security/account_lockout_test.dart`: In progress / passed.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Stage, commit, and push changes to `origin/main`. Hot-restart Flutter app (`R`) to test Cloud Sync settings and single top-bar button.

## Manual and Automatic Cloud Sync Failure Investigation — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22 22:47 Asia/Manila
Session owner (self-reported): Ralston Villamin
Requested task and scope: Investigate and fix why manual and automatic cloud synchronization do not work. Preserve Flutter with local SQLite and the separately approved Ubuntu backend mode.
Rubric / risk / acceptance-test IDs: R08, R10; SEC-02; AT10. No rubric score assigned.
Files changed:
- `AI_SESSION_HANDOFF.md`
- `lib/core/services/sync_service.dart`
- `lib/core/services/backend_sync_service.dart`
- `lib/features/shared/widgets/manual_sync_button.dart`
- `lib/main.dart`
- `docs/SUPABASE_ARCHITECTURE.md`
- `PROJECT_STATE.md`
- `TODO.md`
- `CHANGELOG.md`
- `SECURITY_DEFENSE_RECORD.md`

Findings and changes:
- Supabase push/pull caught each table error and continued without returning failure. `fullSync()` then reported success, so the manual button could show a green success even when cloud tables failed.
- Upload used `.upsert(...).select()`, which asks Supabase to return rows and can fail when the client has write permission but no SELECT policy. Upload now uses minimal upsert response.
- Overlapping periodic, manual and event-triggered syncs could run concurrently. Operations are serialized; simultaneous full-sync requests share the active operation.
- Ubuntu mode’s previous full sync invoked the same one-way backend sync from both “push” and “pull,” and its in-progress guard returned immediately to the second caller. Full sync now awaits one backend sync and reports its result.
- Automatic Supabase mode now exposes its current state in the app. Environment loading accepts process variables, `.env` in the working directory, and `.env` beside the desktop executable; credential values were not printed or recorded.

Checks actually run and actual results:
- Inspected the sync service, app initialization, settings controls, backend sync client, cloud architecture notes, and current Git status.
- Confirmed locally that `.env` has non-empty entries for Supabase and AI configuration by recording only key names, state and value lengths; no values were disclosed.
- No tests, analyzer, app launch, or live cloud request was run for this change. Git status showed pre-existing generated platform files, `android/build/`, and `# LUMORA — AI Engineering Framework.md`; they were preserved.

Evidence paths: `lib/core/services/sync_service.dart`, `lib/main.dart`, `lib/features/shared/widgets/manual_sync_button.dart`, `lib/core/services/backend_sync_service.dart`, `docs/SUPABASE_ARCHITECTURE.md`.
Unverified items / remaining risks:
- Live Supabase endpoint, table schema, RLS policies and configured device-header enforcement were not inspected. New on-screen status should expose the first affected table and safe database error code if server configuration still rejects a request.
- `SUPABASE_URL`/anon key/device header setup on Android is not provided by the current app; do not bundle device secrets as assets. Use an approved provisioning approach before presenting mobile sync.
- Pagination, cross-device conflict behavior, storage permissions and real offline/reconnect operation remain unverified. Ubuntu backend mode remains one-way sales upload.
- These code changes do not establish a rubric pass or production security.

Next concrete step: Run manual sync once on the defense device, then set Automatic Cloud Sync and observe the status. Record the status text (including failed table/error code, if any) so remaining Supabase schema/RLS configuration can be corrected without exposing credentials.

## Supabase RLS Sync Error Triage — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22 23:05 Asia/Manila
Session owner (self-reported): Ralston Villamin
Requested task and scope: Diagnose the attached manual/automatic Supabase sync error and prepare a secure next step; no live cloud policy changes.
Rubric / risk / acceptance-test IDs: R08, R10; SEC-02; K02; AT10. No rubric score assigned.
Files changed:
- `docs/security/supabase_rls_diagnostics.sql`
- `docs/SUPABASE_ARCHITECTURE.md`
- `PROJECT_STATE.md`
- `TODO.md`
- `CHANGELOG.md`
- `SECURITY_DEFENSE_RECORD.md`

Findings:
- The supplied trace reports PostgreSQL SQLSTATE `42501` and `new row violates row-level security policy` for `users`, `food_categories`, `food_items`, `transactions`, `transaction_items`, and `activity_logs`; this is a server-side authorization rejection.
- The current Flutter source initializes Supabase with an anon key and custom `x-device-secret` header. POS login is local SQLite and no Supabase Auth sign-in is implemented in the repository. The custom header is not automatically enforced by RLS. No deployed policy/grant export or Supabase schema is present here, so the precise policy mismatch cannot be confirmed.
- The attached trace also contains `SyncToCloud failed` and `Cloud Backup Sync Complete!`; those strings are absent from current source and indicate old-build/run output. Its later `flutter run` shows Supabase initialization only; no fresh sync result is present there. The UI `RenderFlex` and `ListTile` warnings are unrelated to PostgreSQL RLS.
- Added a read-only catalog diagnostic that reports policy metadata and role grants without reading business data or policy expressions. No RLS policy was weakened or changed. Current Ubuntu mode is one-way sales replication and does not resolve full multi-table sync.

Checks actually run and actual results:
- Read the full user-provided log and inspected sync code, Supabase initialization, policy-related project guidance, handoff and Git state.
- Confirmed the current repository source does not contain the old completion/error log strings; current sync status reports table names and safe error codes through the UI.
- Did not connect to Supabase, run the diagnostic SQL, run tests/analyzer, or change cloud policies.

Evidence paths: user attachment `C:/Users/tonton/.codex/attachments/29a921c8-6cf6-4a61-9350-b511f0a06ac0/Pasted text.txt`; `lib/main.dart`; `lib/core/services/sync_service.dart`; `docs/security/supabase_rls_diagnostics.sql`.
Unverified items / remaining risks:
- Current deployed RLS policies, SQL grants, table schemas, active client role/JWT, and any server-side custom-header hook remain unverified.
- No successful manual or automatic multi-device Supabase synchronization is established. Do not disable RLS or grant unrestricted anon access to make the error disappear.
- A secure multi-table sync design must bind writes to a verified identity and least-privilege policies. The separate Ubuntu API currently supports one-way sales replication only.

Next concrete step: Run the read-only diagnostic in the Supabase SQL Editor and share its result (policy names/roles/commands and grants only). Then select and implement the appropriate secure auth/backend design before retesting with synthetic records.

### Supabase policy metadata follow-up — 2026-10-22

Evidence received: user-provided Supabase dashboard screenshots of the diagnostic result (`C:/Users/tonton/AppData/Local/Temp/codex-clipboard-1882b6e1-ee57-49f2-a177-9280405e62a4.png`, `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-2a81fc7c-1d8a-45b3-8aef-82520ac6f317.png`, `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-efc3e253-e1c2-4e6b-ac8a-c13feb359b70.png`, `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-6d429419-26a8-4096-a47d-6f10d5f75174.png`). The first shows RLS enabled (`true`) and not forced (`false`) on all seven sync tables, with one `ALL` policy per table named `Enforce device secret on <table>` and role `public`. Later screenshots show the policy condition indicators, PERMISSIVE mode, and grants.

Interpretation: the failure is not explained by a missing policy. The reported `new row violates row-level security policy` points to an unsatisfied row `WITH CHECK` condition; missing table grants are still unverified. Because the policy is named for the device secret and the Flutter client sends `x-device-secret`, a missing/stale/different client secret is a plausible cause, not a confirmed one. The existing secret-rotation evidence dates to 2026-10-15/16 and does not establish the current client/configuration state.

The expanded screenshots show, for all seven tables: `policy_modes=PERMISSIVE`, `has_using_condition=true`, `has_with_check_condition=false`, `using_calls_device_secret_check=true`, `with_check_calls_device_secret_check=false`, and `references_request_headers=false`; the displayed anon/authenticated SELECT/INSERT/UPDATE grants are true. The header-reference flag checks policy text only; the helper function may read `request.headers` internally. PostgreSQL documentation confirms an `ALL` policy's USING expression is the default write check when WITH CHECK is omitted. Therefore the reported new-row RLS error means the permissive policy's device-secret condition rejects the request. Likely causes include a missing/different header or stale server-side helper value; the exact mismatch is not established.

No secret values or policy expressions are needed. No live database request or write was made.

Next concrete step: compare the local `.env` `SUPABASE_DEVICE_SECRET` with the value used by the deployed helper without sharing either value. Check for a stale process-level override: `lib/main.dart` applies environment variables after loading `.env`, so process values take precedence. Fully restart Flutter after correcting configuration. Test only with synthetic data in a development project, not by syncing production records.

## Windows sync status and settings assertion follow-up — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22 23:44 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope: Pull the current main branch, fix the repeated Flutter settings assertion and the still-failing manual Supabase sync visibility, then push the reviewed changes. No cloud policy or credential change was authorized.
Rubric / risk / acceptance-test IDs: R08, R09, R10, R13, R14, R19; K02, K05; AT10. No score assigned.

Evidence received:
- User-provided Windows `flutter run -d windows` output reports Supabase initialization completed, repeated “ListTile background color or ink splashes may be invisible” assertions, and `Lost connection to device`. It does not contain a fresh Supabase table/error code.
- User-provided dashboard screenshot shows the app online with a generic `Sync error` chip.
- The owner reports the local device-secret setting differed from the comparison in the Supabase helper, changed it privately, and still sees sync failure. No secret value or full helper body was recorded.

Findings and changes:
- The Flutter assertion is consistent with the Manual/Automatic `RadioListTile` controls inside opaque white rounded settings cards. Both Admin and Cashier controls now have a transparent `Material` surface for visible selection/ink effects.
- The top-bar manual sync action previously changed the chip to a generic error without showing `SyncService.syncStatusNotifier`. It now shows the sanitized result, which can include the affected table and safe error code; unexpected exceptions get a generic message.
- These changes improve the UI warning and diagnostic visibility. They do not establish that Supabase sync now succeeds or that the shared header secret is a secure device identity.

Files changed:
- `lib/features/admin/presentation/pages/admin_account_settings_page.dart`
- `lib/features/cashier/presentation/pages/account_settings_page.dart`
- `lib/features/shared/widgets/app_status_strip.dart`
- `PROJECT_STATE.md`, `TODO.md`, `CHANGELOG.md`, `docs/SUPABASE_ARCHITECTURE.md`, `AI_SESSION_HANDOFF.md`, and this record
- The pre-existing read-only RLS diagnostic/documentation edits from this conversation are preserved for the requested push.

Checks actually run and actual results:
- `git fetch origin` completed; origin exposed a newer `ui-refinements` branch. `git pull --ff-only origin main` reported “Already up to date.” The separate branch was not merged.
- `dart format` was tried, but it expanded unrelated formatting across the existing pages; those formatting-only changes were discarded and the targeted edits kept in the repository's original style.
- Targeted `dart analyze` on the final three changed Dart files completed with exit code 0 and 8 informational `RadioListTile.groupValue` / `onChanged` deprecation notices; no analyzer errors were reported.
- `flutter analyze` was attempted but produced no output for about 90 seconds and was interrupted; direct targeted Dart analysis completed as noted above.
- `git diff --check` completed without whitespace errors before the final documentation update; rerun before commit.
- No Flutter tests, app launch, Supabase request, or production data sync was run in this session.

Evidence paths: user attachment `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-db52d3eb-7c1c-4cc5-b21c-40c15dcd35f9.png`; changed source files listed above; sanitized status is to be captured on the next manual sync.

Unverified items / remaining risks:
- The owner still reports sync failure. The exact failing table and fresh safe database code have not been captured, so no sync pass is claimed.
- A shared literal checked by a Flutter-supplied header is extractable and should not be treated as strong authentication. Long-term multi-table sync needs authenticated identities/least-privilege RLS or a reviewed backend path.
- The `Lost connection to device` line has not been reproduced; the screenshot shows the app still open, so it is not attributed to the settings assertion.

Next concrete step: restart the updated Windows app, tap the top-bar sync control once in a development project using synthetic data, and record only the snackbar status (no secrets). Do not full-sync the Production project.

## Settings Drawer, Food Management Filters & Token Alignment Session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T23:25:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
1. Fix cross-device sync order visibility (repaired `sync_service.dart`, added reactive sync listeners to `orders_page.dart` and `transaction_history_page.dart`).
2. Make Settings appear on the right side for both Admin (`AdminShell`) and Cashier (`CashierShell`) with clean header, left border, and subtle shadow.
3. Standardize Logout confirmation dialog (`AppConfirmDialog.showLogoutDialog`) to strictly follow `UI_PRINCIPLES.md` (12px radius, neutral styling, autofocus Cancel, destructive Logout).
4. Clean Food Management layout: eliminate redundant Category and Status filter popup menus in table header, unify search and filter dropdowns into a single responsive toolbar, and eliminate rainbow colors (`_chipColors`) from category pills.
5. Follow operator Git procedure: always check remote tracking for pull/merge, ask user permission before push.
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles compliance), AT10 (Integration boundaries & sync resilience), SEC-02 (Session controls).
Files changed:
- `lib/core/services/sync_service.dart`
- `lib/features/cashier/presentation/pages/orders_page.dart`
- `lib/features/cashier/presentation/pages/transaction_history_page.dart`
- `lib/features/admin/presentation/pages/food_management_page.dart`
- `lib/features/admin/presentation/pages/admin_shell.dart`
- `lib/features/cashier/presentation/pages/cashier_shell.dart`
- `lib/features/admin/presentation/pages/admin_account_settings_page.dart`
- `lib/features/cashier/presentation/pages/account_settings_page.dart`
- `lib/features/shared/widgets/app_confirm_dialog.dart`
- `lib/features/admin/presentation/widgets/navigation/admin_nav_rail.dart`
- `lib/features/cashier/presentation/widgets/navigation/cashier_nav_rail.dart`
- `lib/features/admin/presentation/widgets/navigation/admin_drawer.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze`: 0 errors / clean on all touched files.
- `flutter test test/security/`: 65/65 tests passed cleanly.
- `git fetch origin ui-refinements`: up to date, nothing to pull or merge.
- Permission requested and confirmed by MJ Daz.
- Committed (`910b357`) and pushed to `origin/ui-refinements`.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Continue testing UI workflows in running application.

## Sales Reports UI Hierarchy, Typography & Table Filters Session — 2026-10-22 (Asia/Manila)

Date/time and timezone: 2026-10-22T23:42:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
1. Apply UI principles (`UI_PRINCIPLES.md`) to the Sales Reports tab in Admin (`sales_reports_page.dart`).
2. Add clear visual hierarchy: Hero Revenue KPI card with 32px+ bold tabular figures, flanked by quiet secondary metric cards (Average Order, Completed Orders, Voided & Refunded) computed honestly from state with zero hardcoded badges or fake 100% metrics.
3. Fix typography: standard 5-role design tokens (`AppTypography`), eliminating all inline `TextStyle` literals and yellow text on light surfaces.
4. Add comprehensive transaction table filters: receipt/order search field, status dropdown (`All Statuses`, `Completed`, `Served`, `Voided`, `Refunded`), cashier dropdown (`All Staff` + dynamic cashiers), date range picker, and clear filters action.
5. Standardize table presentation: `AppStatusChip` with WCAG-compliant colors and icons, right-aligned monetary values with tabular figures, single radius 12.
6. Follow operator Git procedure: always check remote tracking for pull/merge, ask user permission before push.
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles compliance), AT10 (Integration boundaries & sync resilience), SEC-01 (Input validation & sanitization).
Files changed:
- `lib/features/admin/presentation/pages/sales_reports_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze lib/features/admin/presentation/pages/sales_reports_page.dart`: 0 errors / No issues found.
- `flutter test test/security/`: 65/65 tests passed cleanly.
- `git fetch origin ui-refinements`: up to date, nothing to pull or merge.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Continue testing UI workflows in running application.

## Biometrics & Face Scan Artifacts Complete Removal Session — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T00:01:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
1. Audit and completely remove all remaining face scan, biometric, and camera artifacts from the project.
2. Remove unused `camera` and `camera_windows` dependencies from `pubspec.yaml` to accelerate Windows build times.
3. Clean UI: remove Biometrics metric card, table column, status pill, action buttons, and dialogs from `account_management_page.dart`; delete `biometric_consent_dialog.dart`.
4. Clean core services & security utils: delete `ai_service_client.dart`; remove AES face encoding encryption/decryption from `security_utils.dart`; remove biometric methods from `user_repository.dart`.
5. Remove external microservice: delete root `ai_service/` folder, remove `AI_SERVICE_KEY` from `.env` and `.env.example`.
6. Remove obsolete test suites: delete `ai_service_client_test.dart`, `biometric_lifecycle_test.dart`, and `face_encryption_test.dart`.
7. Follow operator Git procedure: check remote tracking, commit cleanly, and ask user permission before push.
Rubric / risk / acceptance-test IDs: SEC-01 (Credential and PII attack surface reduction), AT04 (Cryptographic boundaries), UI-01 (UI Principles compliance).
Files changed:
- `pubspec.yaml`
- `pubspec.lock`
- `.env`
- `.env.example`
- `lib/features/admin/presentation/pages/account_management_page.dart`
- `lib/core/utils/security_utils.dart`
- `lib/core/database/repositories/user_repository.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `SECURITY_DEFENSE_RECORD.md`
Files deleted:
- `lib/features/auth/presentation/widgets/biometric_consent_dialog.dart`
- `lib/core/services/ai_service_client.dart`
- `ai_service/` (entire microservice directory)
- `test/security/ai_service_client_test.dart`
- `test/security/biometric_lifecycle_test.dart`
- `test/security/face_encryption_test.dart`
Checks actually run and actual results:
- `flutter pub get`: Resolved cleanly without camera dependencies.
- `flutter analyze`: 0 errors / No issues found across all modified files.
- `flutter test test/security/`: 47/47 active security tests passed cleanly.
- `git fetch origin ui-refinements`: up to date, nothing to pull or merge.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Seek user permission to push merged main to origin/main.

## UI Principles Refactoring: Cashier Queue, User Logs & Backup Restore Session — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T00:18:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
1. Apply `UI_PRINCIPLES.md` to Cashier Queue / Orders tab (`orders_page.dart`):
   - Switch default tab from 'All' to 'Preparing' to display active queue immediately.
   - Segmented filter controls with live counts (`Preparing`, `Served`, `All`).
   - Establish visual hierarchy: bold tabular order figures, `AppStatusChip` with semantic status types, and clean card dividers.
   - Standardize dialogs (Advance Order, Cancel Order) to 12px radius and high contrast buttons.
   - Clean empty state with `AppEmptyState`.
2. Apply `UI_PRINCIPLES.md` to Admin User Log tab (`activity_logs_page.dart`):
   - Replace inline `TextStyle` literals with standard 5 typography roles (`AppTypography.tableHeader`, `tableCellPrimary`, `tableCellSecondary`, `label`, `figureSmall`).
   - Role badges with high contrast fills (Admin -> ink blue tint, Cashier -> golden yellow tint).
   - Status badges with `AppStatusChip` (Success -> success, Failed -> error, Other -> info).
   - Standardize filters, date picker button, export dropdown, and pagination controls with 12px radius and `AppColors.softBorder`.
3. Apply `UI_PRINCIPLES.md` to Admin Backup & Restore tab (`backup_restore_page.dart`):
   - Wrap Export and Restore sections into standardized `AppCard` widgets.
   - Standard typography roles (`AppTypography.headingLarge`, `body`, `bodyMuted`, `label`).
   - Standard action buttons: `AppPrimaryButton` for "Create Backup Now" with loading indicator; `AppSecondaryButton` for "Restore from File" (coming soon).
   - Standard status chip for completed backup file path.
4. Follow operator Git procedure: verify remote tracking, commit cleanly, and seek explicit permission before pushing.
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles compliance), SEC-01 (Clean error messages & data integrity), AT10 (Sync & resilience).
Files changed:
- `lib/features/cashier/presentation/pages/orders_page.dart`
- `lib/features/admin/presentation/pages/activity_logs_page.dart`
- `lib/features/admin/presentation/pages/backup_restore_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze lib/features/cashier/presentation/pages/orders_page.dart`: No issues found!
- `flutter analyze lib/features/admin/presentation/pages/activity_logs_page.dart`: No issues found!
- `flutter analyze lib/features/admin/presentation/pages/backup_restore_page.dart`: No issues found!
- `flutter test test/security/`: 47/47 tests passed cleanly.
- `git fetch origin main`: up to date, 0 incoming commits.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Request user permission before running `git push`.

## Supabase users upload constraint follow-up — 2026-10-23 (Asia/Manila)

Session owner (self-reported): Ralston Villamin

Rubric / risk / acceptance-test IDs: R08, R10; SEC-02; AT10. No rubric score assigned.

Evidence received:
- User screenshot shows the app online with `Cloud sync incomplete (upload: users (23502))`.
- A read-only Supabase schema query shows seven required columns on `public.users`: `id`, `full_name`, `username`, `password_hash`, `role`, `status`, and `created_at`.
- This is a PostgreSQL not-null constraint error, distinct from the earlier `42501` RLS rejection. The app supplies the other listed profile fields and deliberately omits `password_hash`, identifying it as the likely failing column.

Findings and changes:
- `SyncService._syncToSupabase` omits `password_hash` and `face_encoding` before uploading `users`, by design. Local SQLite requires `password_hash`; whether the deployed Supabase table does too must be confirmed from schema metadata.
- The first sync may have updated existing cloud users while a later newly created or not-yet-present user requires an insert and fails. This is a plausible explanation for “synced at first,” not a verified cloud history.
- User pulls now request only profile fields; cloud password hashes, biometrics, login counters, and local password-change state are not downloaded.
- Existing local auth state is preserved during profile merges. A profile imported to a device without a local account gets a random local-only password hash and must be password-reset by an Admin on that device.
- Sanitized sync diagnostics can include only the required column identifier for a `23502` error; they never include the failing row or full server message.
- Added `docs/security/supabase_users_sync_diagnostic.sql`, a read-only query against `information_schema.columns`.
- Prepared `docs/security/supabase_users_profile_sync_migration.sql` to make the cloud profile's `password_hash` nullable. It is not applied and does not clear any existing cloud values.

Files changed:
- `lib/core/services/sync_service.dart`
- `docs/security/supabase_users_sync_diagnostic.sql`
- `docs/security/supabase_users_profile_sync_migration.sql`
- `docs/SUPABASE_ARCHITECTURE.md`
- `AI_SESSION_HANDOFF.md`, `PROJECT_STATE.md`, `TODO.md`, `CHANGELOG.md`, and this record

Checks actually run and actual results:
- No Supabase request, production sync, or database write was performed.
- No Flutter tests were run.
- `dart analyze lib/core/services/sync_service.dart` was attempted before the final profile-only pull change; it produced no output for about 90 seconds and was interrupted. The final code was not analyzed; no analyzer pass is claimed.

Unverified items / remaining risks:
- The schema confirms `password_hash` is required. The proposed nullable-column migration has not been applied.
- Existing cloud `password_hash` values, if any, remain untouched. Review their count and local backups before deciding whether to clear them.
- A newly imported account requires a local Admin password reset on that device; cross-device user-ID conflicts remain part of the broader sync conflict risk.
- A successful upload/download cycle has not been verified.

Next concrete step: Apply the nullable `password_hash` migration in a development project, then build the updated client and sync synthetic data. Confirm a profile-only account pull and Admin password reset on another device before applying the migration to Production. Do not share credentials, user rows, or secrets.

## UI Consistency: Cashier Queue Header Alignment — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T00:36:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
- Align Cashier Queue header (`orders_page.dart`) with the other Cashier tabs (`Menu` in `home_page.dart` and `Recent Transactions` in `transaction_history_page.dart`).
- Resolve visual discordance caused by earlier status chip experiment and square tabs:
  - Header title set to standard Cashier headline typography (`Queue`, 18pt bold charcoal).
  - Status indicator standardized to subtle 12px-radius cream count pill (`$_inProgressCount in progress`).
  - Filter controls aligned with cashier pill button language (`BorderRadius.circular(20)`), retaining `Preparing` as the first and default tab.
  - Removed custom Scaffold background color to maintain seamless tab transitions.
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles compliance), SEC-01.
Files changed:
- `lib/features/cashier/presentation/pages/orders_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze lib/features/cashier/presentation/pages/orders_page.dart`: No issues found! (0 warnings, 0 errors).
- `flutter test test/security/`: 47/47 tests passed cleanly (0 regressions).
- `git fetch origin main`: pulled incoming commit `bbc8998` from collaborator Ralston Villamin cleanly with fast-forward.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Seek user permission before running `git push origin main`.

## Transaction Status Sanitation & Cashier Transaction Tab UI Principles — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T01:04:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope:
1. Verify and sanitize transaction statuses in Sales Reports and system database:
   - Evaluated status dropdown containing: `All Statuses`, `Completed`, `Served`, `Voided`, `Refunded`, `Preparing`, `Taken`, `Ready`.
   - Identified valid POS transaction lifecycle statuses: `Served` (fulfilled), `Preparing` (kitchen queue), `Voided` (cancelled), and `Refunded` (refunded).
   - Removed obsolete mock statuses (`Taken`, `Ready`) and duplicate conflicting status (`Completed`).
   - Added database-level normalization in `DatabaseHelper` mapping legacy `Completed`, `Taken`, `Ready` to `Served`.
   - Sanitized `mock_data.dart` and `sales_reports_page.dart` dropdown filter to only expose valid system statuses.
2. Resolve image codec and ListTile exceptions:
   - Removed third-party `placehold.co` fallbacks in `food_management_page.dart` and bypassed `placehold.co` in `FoodImage` to eliminate `Invalid image data` exceptions.
   - Removed `ListTile` inside decorated `Container` in `transaction_history_page.dart` to eliminate `ListTile background color or ink splashes may be invisible` warnings.
3. Apply `UI_PRINCIPLES.md` to Cashier Transaction Tab (`transaction_history_page.dart`):
   - Header: Standardized layout with record counter pill, real-time search input (receipt/order #), and status pills (`All`, `Served`, `Voided`).
   - Cards: Modern `Material` + `InkWell` containers with 12px radius, visual hierarchy, tabular figures, and `AppStatusChip` badges.
   - Empty State: Integrated `AppEmptyState` with `Reset Filters` action.
   - Standardized receipt drawer and void confirmation dialog according to UI principles.
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles compliance), SEC-01, AT10.
Files changed:
- `lib/core/database/database_helper.dart`
- `lib/core/utils/mock_data.dart`
- `lib/features/admin/presentation/pages/food_management_page.dart`
- `lib/features/admin/presentation/pages/sales_reports_page.dart`
- `lib/features/cashier/presentation/pages/transaction_history_page.dart`
- `lib/features/shared/widgets/food_image.dart`
- `SECURITY_DEFENSE_RECORD.md`
Checks actually run and actual results:
- `flutter analyze`: 0 errors / 0 warnings across all modified files.
- `flutter test test/security/`: 47/47 tests passed cleanly (0 regressions).
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Verify remote commits, commit cleanly, and ask for user permission before pushing to origin/main.

## Cross-device cashier sale ID collision investigation — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T01:13:07+08:00 (Asia/Manila)
Session owner (self-reported): Ralston Villamin
Requested task and scope: Investigate two cashier-device screenshots where one friend's sale appeared after sync but dashboard rows and totals differed. Preserve offline SQLite and Supabase synchronization; do not change the web/Ubuntu architecture.
Rubric / risk / acceptance-test IDs: R10; K02 / SEC-02; AT10. No score assigned.

Evidence received:
- Screenshot from the friend's device shows two sales: order `#3` at ₱1,000 and order `#1` at ₱2,145, total ₱3,145.
- Screenshot from the owner's device shows order `#3` at ₱1,000 and order `#1` at ₱505, total ₱1,505. The `#1` receipts and times differ between devices.
- Attachment paths: `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-dc0a6f3b-2383-4cfa-800b-1f9148221456.png` and `C:/Users/tonton/AppData/Local/Temp/codex-clipboard-71cb9bb1-ef89-412c-8ede-974c8a7408ce.png`.
- Source inspection confirms local `transactions.id` and `transaction_items.id` use independent SQLite `AUTOINCREMENT` values. Supabase uploads upsert by `id`, and downloads replace local rows by `id`. Thus distinct offline sales assigned the same ID can replace each other; the differing dashboard totals match that failure mode.

Changes made:
- Added `SyncIdGenerator`, which stores a random installation namespace and monotonic counter in local-only `app_settings` and emits signed 63-bit IDs for new sales and line items.
- New receipt numbers include the generated transaction ID suffix. Daily `order_number` remains a local sequence, so the queue now also shows each receipt number to distinguish repeated order numbers.
- Before Supabase transaction upserts and during pulls, code compares same-ID sales by receipt, timestamp, amount, discount, and payment method. A different local sale is rekeyed together with its line items before the cloud sale is inserted.
- Added `docs/security/supabase_transaction_id_diagnostic.sql` to confirm the cloud ID fields are `bigint` before deploying this client change.
- Updated synchronization policy, architecture, handoff, project state, TODO, changelog, and ADR-014 notes. No rubric pass is claimed.

Files changed:
- `lib/core/utils/sync_id_generator.dart`
- `lib/core/database/repositories/transaction_repository.dart`
- `lib/core/services/sync_service.dart`
- `lib/features/cashier/presentation/pages/orders_page.dart`
- `docs/security/supabase_transaction_id_diagnostic.sql`
- `docs/SYNC_CONFLICT_POLICY.md`, `docs/DATA_SYNCHRONIZATION.md`, `docs/SUPABASE_ARCHITECTURE.md`, `DECISIONS.md`
- `AI_SESSION_HANDOFF.md`, `PROJECT_STATE.md`, `TODO.md`, `CHANGELOG.md`, and this record

Checks actually run and actual results:
- Read-only source inspection identified local auto-increment transaction/item keys and Supabase ID-based upsert/replace behavior.
- No tests, analyzer, app launch, Supabase request, or database write was run.

Unverified items / remaining risks:
- Supabase `transactions.id`, `transaction_items.id`, and `transaction_items.transaction_id` types have not been inspected; confirm they are `bigint` in a development project first.
- No two-device sync was run. Existing overwritten data can only be recovered if some device still retains the distinct local transaction.
- Device namespaces are random, not authentication credentials. Restoring/cloning a full SQLite database could copy the namespace; restore behavior needs a future rotation rule.
- Same-day `order_number` values may still repeat across offline devices; unique receipts are the stable reference.

Next concrete step: Run the read-only ID-type diagnostic in development, deploy the updated client to two devices with retained local test data, and run repeated synthetic-sale sync cycles. Confirm both distinct receipts, amounts, and line items remain on both devices before evaluating Production.

## Merge Sync ID Collision Mitigation & Test Verification — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T04:57:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope: Pull and merge remote changes (`origin/main` commit `bcb4b88`), resolve merge conflicts, verify tests, and push to remote.
Rubric / risk / acceptance-test IDs: R10; K02 / SEC-02; AT10.
Files changed:
- `SECURITY_DEFENSE_RECORD.md`
- `test/security/audit_logging_test.dart`
- `test/unit/transaction_repository_test.dart`
Checks actually run and actual results:
- Resolved merge conflict in `SECURITY_DEFENSE_RECORD.md` by retaining both session entries sequentially.
- Updated in-memory test schemas in `test/security/audit_logging_test.dart` and `test/unit/transaction_repository_test.dart` to create the required `app_settings` table for `SyncIdGenerator`.
- `flutter test test/security/`: 47/47 tests passed cleanly (0 regressions).
- `flutter test test/unit/transaction_repository_test.dart`: 4/4 tests passed cleanly.
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Unverified items / remaining risks:
- Live multi-device sales replication on physical devices remains unverified until deployed with synthetic data.
Next concrete step: Conclude merge commit and push to origin/main.

## ListTile & RadioListTile DecoratedBox Material Surface Remediation — 2026-10-23 (Asia/Manila)

Date/time and timezone: 2026-10-23T05:07:00+08:00 (Asia/Manila)
Session owner (self-reported): MJ Daz
Requested task and scope: Fix Flutter framework assertion `ListTile background color or ink splashes may be invisible. The ListTile is wrapped in a DecoratedBox that has a background color.`
Rubric / risk / acceptance-test IDs: UI-01 (UI Principles and Material design standards), AT10.
Files changed:
- `lib/features/cashier/presentation/pages/account_settings_page.dart`
- `lib/features/admin/presentation/pages/admin_account_settings_page.dart`
- `lib/features/admin/presentation/pages/food_management_page.dart`
- `SECURITY_DEFENSE_RECORD.md`
Root cause:
- `RadioListTile` (and `ListTile`) in Settings sections was wrapped inside a `Container` with `BoxDecoration(color: AppColors.surfaceWhite, ...)` (DecoratedBox). Because `ListTile` paints its background and ink splashes on the nearest `Material` ancestor, intermediate decorated boxes with background colors trigger a Flutter debug assertion.
Remediation:
- Replaced decorated `Container` wrappers with `Material(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(AppDesignTokens.radius12), shape: RoundedRectangleBorder(...), clipBehavior: Clip.antiAlias)` in `account_settings_page.dart`, `admin_account_settings_page.dart`, and `food_management_page.dart`.
- Removed redundant intermediate `Material(color: Colors.transparent)` wrappers, allowing ink splashes and highlights to paint cleanly directly onto the Material surface.
Checks actually run and actual results:
- `flutter analyze`: 0 errors across all modified files.
- `flutter test test/security/`: 47/47 tests passed cleanly (0 regressions).
Evidence paths:
- `SECURITY_DEFENSE_RECORD.md`
Next concrete step: Stage changes, commit cleanly, and push to origin/main if approved.



