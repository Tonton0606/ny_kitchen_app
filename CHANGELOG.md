# Changelog
# N.Y Kitchen Secure Order and Sales Management System

All notable changes to this project will be documented in this file.

This file follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

---

## [Unreleased]

### Added — 2026-10-22

- Added a read-only Supabase RLS/grant diagnostic query with secret-safe condition indicators; it omits policy expressions and business rows.

### Security notes — 2026-10-22

- Recorded the user-provided `42501` write-denial trace and the current architecture gap: local SQLite POS authentication does not establish a Supabase Auth identity, while `x-device-secret` is only a custom header unless explicitly verified by server-side policy logic.
- No permissive RLS policy was added. Secure multi-table sync requires a reviewed cloud identity and policy design; the Ubuntu backend currently supports one-way sales replication only.
- Expanded dashboard output confirms the seven policies are PERMISSIVE, each `USING` condition calls `check_device_secret`, and the displayed anon/authenticated SELECT/INSERT/UPDATE grants are true. The owner later reported that the local device-secret setting differed from the helper and changed it privately; sync still reports an error, so the precise current request failure remains unverified.

### Fixed — 2026-10-22

- Wrapped Admin and Cashier cloud-sync `RadioListTile` groups in transparent Material surfaces so card decorations do not obscure selection and ink effects.
- The top status bar now displays the sanitized sync status after a manual attempt, including affected table names and safe database error codes.
- Manual and automatic sync now fail visibly when a Supabase table upload/download fails; status includes the affected table and safe database error code.
- Supabase upserts no longer request returned rows, avoiding an unnecessary SELECT policy requirement.
- Sync operations are serialized and overlapping full-sync requests share one operation. Ubuntu mode now awaits a single one-way upload during full sync.
- Environment configuration can come from process variables, the current working directory `.env`, or a `.env` beside the desktop executable. Automatic mode shows its current status in the app.
- Live Supabase schema/RLS reachability and mobile credential provisioning remain unverified; no test suite or live cloud request was run for this change.

### Fixed — 2026-10-23

- New offline sales and line items use installation-scoped 64-bit IDs and unique receipt suffixes. Supabase sync detects legacy sale-ID collisions and rekeys the locally retained sale and its items before writing; cross-device recovery is implemented but not yet verified.
- Supabase sync status may now identify a not-null column by name for SQLSTATE `23502`, while keeping the failing row and other server details out of user-visible messages.
- User sync now downloads only profile columns, preserves existing device-local auth state, and creates an unguessable local-only hash for a newly imported account; an Admin must reset that account's password on each device.
- Added read-only schema diagnostics and a proposed nullability migration. Supabase confirmed `public.users.password_hash` is NOT NULL; migration application and live sync remain pending.

### Documentation — 2026-10-20

- Read the supplied security rubric without modifying it; created `docs/SECURITY_IMPLEMENTATION_PLAN.md` with all 20 criteria, risk ratings, controls, acceptance tests, tool decisions, privacy/recovery planning and a defense script.
- Corrected primary architecture/authentication/authorization/session/backup/security/testing/presentation guides and README. Marked older proposed layouts, routing, cloud designs and historical results explicitly.
- Updated project state, TODO, decisions and session history. No application changes, package installation, VM setup, active scanning or test execution.

- Added `SECURITY_DEFENSE_RECORD.md` with the project map, observed controls, initial security findings, documentation conflicts, and a pending rubric evidence table. Application code was not changed or tested in this session.

### Added

- `RULES.md` — Immutable project rules governing all development.
- `AI_DEVELOPMENT_RULES.md` — Mandatory AI agent operating rules.
- `PROJECT_STATE.md` — Project state tracker for all development phases.
- `CHANGELOG.md` — This changelog file.
- `TODO.md` — Categorized task tracker.
- `DECISIONS.md` — Architecture Decision Record index and templates.
- `.aiignore` — AI exclusion configuration.
- `docs/` directory with 57 Markdown documentation templates.
- `ai/` directory with 9 AI collaboration Markdown files.
- `skills/` directory with 43 project-specific SKILL.md files.
- `skills/REGISTRY.md` — Skills registry table.
- `skills/CONTRIBUTING.md` — Skills contribution guide.
- `skills/_templates/skill-template/SKILL.md` — Standard skill template.
- `docs/OPEN_SOURCE_REVIEW.md` — Documentation of the open source review, import decisions, and security constraints.
- `docs/FIGMA_INTEGRATION.md` — Documentation of Figma workspace links and design handoff process.
- **SQLite Database Architecture**: Implemented `DatabaseHelper` singleton utilizing `sqflite` to manage 9 tables with schema specifications aligned with `docs/SQLITE_ARCHITECTURE.md`.
- **Database Seeding**: Added initial seeding logic to auto-create 'admin' account, default 'food_categories', and baseline 'food_items' upon database creation.
- **Data Repositories**: Created `UserRepository` handling authentication/login checks against SQLite, and `FoodRepository` for CRUD operations on food items.
- **Backend UI Integration**: 
  - Updated `LoginPage` to query `UserRepository` for actual database credentials instead of static checks.
  - Rewired `FoodManagementPage` to read dynamically from `FoodRepository` and completely replaced static `MockData`.
  - Form dialogs (Add/Edit/Delete Food) in `FoodManagementPage` now write changes directly to SQLite and trigger a UI reload upon success.
  - Rewired `AccountManagementPage` to perform CRUD operations on actual SQLite users via `UserRepository` instead of mock arrays.
  - Connected Cashier POS (`CashierHomePage`) to live `FoodRepository` for menu items and implemented live `TransactionRepository` checkouts that write to the `transactions` and `transaction_items` tables.
  - Connected Kitchen Flow (`OrdersPage`) to poll live active transactions allowing true state progression (`Taken` -> `Preparing` -> `Ready` -> `Served`).
- Cashier Module Phase 1 Static UI Prototype (Home/Order, History, Settings).
- Admin Module Phase 1 Static UI Prototype (Dashboard, Sales Reports, Food Management, Account Management, Activity Logs, Settings).
- **Phase 5 Cloud Synchronization**:
  - Implemented `supabase_flutter` for background data backups.
  - Implemented secure `.env` storage for Supabase keys.
  - Built `SyncService` for SQLite-to-Supabase disaster recovery.
  - Enforced Device-Level authentication via `x-device-secret` and custom RLS policies in PostgreSQL.
- **Phase 6 UI/UX Polish**:
  - Integrated `window_manager` to provide a borderless application window on desktop platforms.
  - Created a `CustomTitleBar` with a drag area, minimize, maximize, and close controls.
- Login Screen static prototype with mock role selection.
- **Mock Data**: Extended with 15 food items, 8 transactions, 5 users, 10 activity logs, 5 top-selling foods, 10 hourly revenue data points.
- **Login Page**: Enhanced with desktop side-by-side branding layout, polished Material 3 card design, role selector with icons, improved form fields with filled styling.

### Changed

- `README.md` — Updated with project overview, platforms, architecture summary, and documentation links.
- `DECISIONS.md` — Resolved pending ADRs 011, 013, 015, and 016.
- `PROJECT_STATE.md` — Updated to reflect resolution of ADRs and creation of Open Source Review documentation.
- **Admin Shell**: Improved Navigation Rail with compact mode for tablet, responsive drawer for mobile, logout now navigates to login page.
- **Admin Dashboard**: Added trend indicators to stat cards, period filter chips, hourly bar chart visualization, ranked top-selling foods with revenue, enhanced recent activities with status icons.
- **Sales Reports**: Added 4 summary cards per tab (Revenue, Avg Order, Orders, Completion Rate), added Items column to transactions table, improved status badges.
- **Food Management**: Complete CRUD dialogs with image placeholder, category dropdown, price input, availability toggle, prefilled edit dialog, search/filter functionality.
- **Account Management**: Complete dialogs for Add Cashier, Edit, Reset Password, Disable/Enable with proper form fields and confirmation messaging, search/filter functionality.
- **Activity Logs**: Added search by user/action/module, role filter dropdown, date filter dropdown, role and module colored badges, monospace IP styling.
- **Account Settings**: Added profile picture with camera icon overlay, role badge, theme switch with dark mode icon, about section, save button with feedback.
- **Admin design merge**: Consolidated the polished Material 3 login, admin navigation, dashboard, reports, food, account, activity-log, and settings UI into the Phase 1 prototype.
- **Cashier UI**: Refined cashier navigation, ordering, active orders, and settings presentation while retaining mock data only.

### Fixed

- All `withOpacity` deprecation warnings replaced with `withValues(alpha:)`.
- All `background`/`onBackground` theme deprecations replaced with `surface`/`onSurface`.
- All `activeColor` deprecation warnings on SwitchListTile replaced with `activeTrackColor`.
- All `value` deprecation warnings on DropdownButtonFormField replaced with `initialValue`.
- All `__` and `___` unnecessary underscore warnings resolved.
- String concatenation warnings resolved using interpolation.
- Removed unused `_initState` method from SalesReportsPage.
- Removed unused imports from admin navigation files.
- Removed unused local variables from ActivityLogsPage.
- Fixed invalid `const` modifiers in `Text` and `Column` widgets using dynamic `Theme.of(context)` styles across admin pages.
- Resolved bracket closure syntax error in `AdminDashboardPage`.
- Resolved unused `app_colors.dart` imports across multiple modules.
- Fixed `curly_braces_in_flow_control_structures` warnings in `ActivityLogsPage`.
- Applied Material 3 design polish to `LoginPage`, replacing hardcoded `AppColors` with `Theme.of(context).colorScheme` and enhancing the desktop split layout with branded visuals.
- Added mounted guards around order status updates and undo actions after dialog navigation.
- Wrapped cashier account-settings tiles in a transparent `Material` surface so ListTile ink feedback is visible.
- Completed LUMORA Phase 4 validation: `flutter analyze` reports zero issues and all 26 widget tests pass.

### Security

- Phase 4 security implementation is tracked in `SECURITY_FEATURES.md`: local SQLite authentication, `crypto` SHA-256 password hashing, in-memory sessions, and five-attempt account lockout.

### Deprecated

*Nothing deprecated.*

### Removed

*Nothing removed.*

---

## [0.0.1] — 2026-07-14 — Documentation Setup

### Added

- Initial Flutter project scaffolding (generated by Flutter SDK).
- `PROJECT_BLUEPRINT.md` — Master project blueprint and single source of truth.
- Phase 1 documentation and AI operating system setup.

---

*This changelog will be updated as phases are completed and features are implemented.*
*Do not add feature entries until the corresponding implementation exists and is verified.*

### Scope confirmation — 2026-10-20

- Owner confirmed hybrid offline/online operation with online synchronization. Updated blueprint, rules, ADR-002, README, cloud/architecture plan, TODO and session record. No application behavior changed.

## 2026-10-22 — Ubuntu backend preparation

- Added device-authenticated sales replication API with separate Admin reads, append-only revision history, strict payloads, size/rate limits and audit events. Added offline provisioning and systemd/Caddy deployment templates.
- Added Flutter HTTPS client with acknowledged checkpoints, retry from local SQLite, explicit exclusive backend mode and status footer. Moved desktop database platform setup before sync startup; caught optional Supabase initialization failures.
- Verified 11 backend tests and 4 Flutter sync tests on synthetic fixtures. VM deployment and existing local permission findings remain pending. See `backend/README.md` and the new verification record.

## 2026-10-22 — AI session handoff

- Added mandatory root AI entry instructions and a detailed handoff covering session attribution, approved Flutter/Ubuntu architecture, rubric mapping, verified results, limitations and next steps.
- Linked README and AI development rules; updated session/state/task records. Requested by Ralston Villamin (self-reported). Documentation only.
