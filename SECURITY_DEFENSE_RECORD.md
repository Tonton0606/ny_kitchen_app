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
