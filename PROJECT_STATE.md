# PROJECT_STATE.md
# N.Y Kitchen — Project State Tracker

> 2026-10-24 update: Owner-supplied read-only Supabase `main` / `PRODUCTION` screenshots show `transactions` = 51 rows and `transaction_items` = 64; `public.users.password_hash` exists and is nullable (`YES`), superseding the 2026-10-23 required-column observation. A separate local SQLite snapshot had 41 transactions and 53 items; these aggregate counts do not identify specific missing or duplicate sales. RLS is enabled but not forced on the seven sync tables; each shows a permissive `ALL` policy with a `check_device_secret` call in `USING`, no explicit `WITH CHECK` expression, and anon/authenticated SELECT/INSERT/UPDATE grants. Check PostgreSQL's default check behavior and the policy function before concluding whether writes are correctly authorized. Do not full-sync Production until record identities are reconciled. No cloud write/sync was performed in this session.

> 2026-10-24 update: Owner-supplied Ubuntu VirtualBox screenshots show the backend deployed at `/opt/ny-kitchen/backend`, API/Caddy active, UFW SSH/HTTPS rules limited to the host-only `/24`, and a successful Windows HTTPS health request to `nykitchen.test` after trusting the matching local Caddy root. `pip-audit` reported no known vulnerabilities in that resolved environment at the time. Flutter/Dart/Android trust, device sales upload, offline/reconnect, denial, rotation/revocation, reboot and restore remain unverified.

> 2026-10-24 local configuration check: In this workspace, `SYNC_BACKEND` was unset and the saved local sync mode was `automatic`; the current default starts a Supabase full sync on app startup and repeats every 15 seconds. No POS process was running here when checked. Inspect the target terminal and reconcile records before launching against Production; this observation does not describe other devices.

> 2026-10-22 update: Rubric remains mapped in `docs/SECURITY_IMPLEMENTATION_PLAN.md`. User screenshots confirm RLS is enabled, all seven device-secret policies are PERMISSIVE, and anon/authenticated table grants are present. The owner privately found and changed a local/device-secret mismatch, but reports sync still fails. No successful sync is claimed; capture the sanitized table/error status after a manual attempt.

> 2026-10-23 update: The latest screenshot reports `Cloud sync incomplete (upload: users (23502))`. Supabase schema metadata confirms `public.users.password_hash` is NOT NULL; the client intentionally omits it. Code now selects profile columns only, preserves existing local auth state, and creates a random local-only hash for newly imported profiles. A reviewed nullability migration is prepared but not applied; live sync remains unverified.

> 2026-10-23 update: Two cashier-device screenshots show different sales sharing local transaction/order ID `#1`; amounts, receipts, and dashboard totals differ while the same `#3` appears on both. Local `AUTOINCREMENT` IDs are independent, but Supabase upserts by `id`, so a row can overwrite another device's sale. Code now generates installation-scoped 63-bit sale/item IDs, unique receipt suffixes, and repairs legacy same-ID/different-sale collisions while the local copy remains. This change is unverified; first confirm the Supabase ID columns are `bigint` in development and repeat the two-device test.

> This file must be updated after every approved work session.
> Do not claim features are complete unless they have been implemented and verified.
> Authority: `PROJECT_BLUEPRINT.md` → `RULES.md` → `AI_DEVELOPMENT_RULES.md`

---

## Project Information

| Field | Value |
|---|---|
| **Project Name** | N.Y Kitchen Secure Order and Sales Management System |
| **Current Phase** | Security defense preparation and cloud synchronization repair |
| **Current Status** | Flutter/SQLite retained; Supabase Production schema and counts observed read-only; reconcile records and review RLS before sync; Ubuntu service deployed and Windows health check observed; Flutter end-to-end sync remains unverified |
| **Last Updated** | 2026-10-24 |
| **Updated By** | Ralston Villamin session (self-reported) |

---

## Phase Completion Tracker

| Track | Status | Completion |
|---|---|---:|
| Project Phase 3 — SQLite integration | Implemented; targeted tests pending | 100% implementation |
| Project Phase 4 — Authentication and security | Implemented; targeted security tests completed | 100% implementation |
| Blueprint Phase 5 — Menu management | Implemented in the current SQLite-backed UI | 100% implementation |
| Supabase hybrid sync | Push/pull implementation present; failure reporting and serialization improved; live configuration/RLS unverified | Implemented, not runtime-verified |
| Phase 6 — UI/UX Polish | Implemented premium aesthetics and responsive layout | 100% implementation |

The percentages describe implementation scope, not production readiness. Security and offline test coverage remain explicit gates.

---

## Completed

### Documentation
- [x] `PROJECT_BLUEPRINT.md` — Master blueprint exists and reviewed
- [x] `RULES.md` — Immutable rules created
- [x] `AI_DEVELOPMENT_RULES.md` — AI operating rules created
- [x] `PROJECT_STATE.md` — Project state tracker created
- [x] `CHANGELOG.md` — Changelog initialized
- [x] `TODO.md` — Task tracker created
- [x] `DECISIONS.md` — Architecture Decision Record index created
- [x] `README.md` — (Existing, preserved and updated)
- [x] `.aiignore` — AI exclusion file created
- [x] `docs/` directory structure created
- [x] `ai/` directory structure created
- [x] `skills/` directory structure created
- [x] All `docs/` Markdown templates created
- [x] All `ai/` Markdown files created
- [x] All `skills/*/SKILL.md` files created
- [x] `skills/REGISTRY.md` populated
- [x] `skills/CONTRIBUTING.md` created
- [x] `skills/_templates/skill-template/SKILL.md` created

### Login Page
- [x] N.Y Kitchen branding with logo
- [x] Welcome Back title
- [x] Username field with icon
- [x] Password field with show/hide toggle
- [x] Remember Me checkbox
- [x] Forgot Password link
- [x] Role selector (Admin / Cashier) for presentation
- [x] Login button with full-width styling
- [x] Version number (v1.0.0)
- [x] Footer copyright
- [x] Responsive layout (desktop side-by-side, mobile centered card)
- [x] Desktop branding display for large screens

### Admin Module — Navigation
- [x] Navigation Rail (Desktop) with logo, menu items, logout at bottom
- [x] Compact Navigation Rail (Tablet)
- [x] Navigation Drawer (Mobile)
- [x] Logout confirmation dialog (Material 3 styled)
- [x] Logout navigates back to Login page

### Phase 4: Authentication & Security [Completed]
- [x] Integrate SQLite `users` table for `admin` and `cashier` login credentials.
- [x] Secure password storage using PBKDF2-HMAC-SHA256 (10,000 iterations) with randomized per-user salts.
- [x] Manage offline session states (Implemented `SessionManager` singleton with 30-minute expiration).
- [x] Route users into the local Admin or Cashier shell based on the authenticated role.
- [x] Add declarative route guards (`GuardedRoute`) and global inactivity listeners to enforce session/role security.
- [x] Enforce lockout policy for consecutive failed login attempts (5 attempts triggers `status = 'locked'`).
- [x] Provide a method to securely change/reset passwords (Integrated into Account Settings and Account Management pages).
- [x] Integrate native image picking for local food images.
- [x] Implement Food Category CRUD/archive management in SQLite.

### Cloud Synchronization [Implementation present; verification pending]
- [x] Integrate the Supabase client and load configuration from process environment or local `.env` files.
- [x] Keep SQLite as the primary local store and preserve offline operation.
- [x] Implement manual and saved-preference automatic push/pull paths.
- [ ] Verify deployed Supabase schema and least-privilege RLS policies.
- [ ] Verify a real-device offline/reconnect round trip and conflict behavior.
- [ ] Provide safe mobile cloud configuration; do not bundle device secrets in Flutter assets.

> The project blueprint currently names Project Phase 5 as Menu Management. This implementation has the menu/category/image foundation in place. The Supabase work above is a separate future cloud-sync track and must not be treated as completed Project Phase 5 work.

### Phase 6: UI/UX Polish [Completed]
- [x] Implement borderless desktop window with `window_manager`.
- [x] Create a custom title bar with minimize, maximize, and close buttons.
- [x] Refine responsive layout for various screens (nav rails, title bar breakpoints).
- [x] Implement premium design aesthetics (colors, gradients, typography, micro-animations).
- [x] Polish UI components (stat cards, charts, badges).

### Admin Dashboard
- [x] Today's Revenue stat card (with trend indicator)
- [x] Today's Orders stat card (with trend indicator)
- [x] Monthly Revenue stat card (with trend indicator)
- [x] Active Cashiers stat card (with shift info)
- [x] Sales Trend chart placeholder (hourly bar chart visualization)
- [x] Recent Transactions table (5 rows, status badges)
- [x] Top Selling Foods list (ranked with revenue data)
- [x] Recent Activities list (with status indicators)
- [x] Period filter chips (Today / Week / Month)

### Sales Reports
- [x] Tab bar: Today, Weekly, Monthly, Annual
- [x] Revenue summary cards per period (Total Revenue, Avg Order, Total Orders, Completion Rate)
- [x] Search field by receipt number
- [x] Date filter button
- [x] Transactions table with full columns (Receipt No, Date, Cashier, Items, Payment, Total, Status)
- [x] Export button (UI only)
- [x] Print button (UI only)

### Food Management
- [x] Food table with columns: Image, Name, Category, Price, Status, Actions
- [x] Search filter by name/category
- [x] Add Food dialog with image placeholder, name, category dropdown, price, availability toggle
- [x] Edit Food dialog with prefilled fields and image preview
- [x] Delete confirmation dialog with warning
- [x] Status badges (Available / Unavailable)
- [x] Action buttons (Edit, Delete) with color-coded containers

### Account Management
- [x] Users table with columns: Avatar, Name, Username, Role, Status, Actions
- [x] Search filter by name/username
- [x] Add Cashier dialog with name, username, password, role fields
- [x] Edit dialog with name, username, role dropdown
- [x] Reset Password dialog with new/confirm password fields
- [x] Disable/Enable confirmation dialog
- [x] Role badges (Admin / Cashier)
- [x] Status badges (Active / Disabled)
- [x] Action buttons (Edit, Reset Password, Disable/Enable)

### Activity Logs
- [x] Audit table with columns: Timestamp, User, Role, Module, Action, Status, Device, IP Address
- [x] Search by user, action, or module
- [x] Role filter dropdown (All, Admin, Cashier, None)
- [x] Date filter dropdown (All, Today)
- [x] Export Logs button (UI only)
- [x] Status badges (Success / Failed)
- [x] Role badges with color coding
- [x] IP address styled with monospace font

### Account Settings
- [x] Profile picture with camera edit icon overlay
- [x] Display name and role badge
- [x] Full Name text field
- [x] Username text field
- [x] Save Changes button (with SnackBar feedback)
- [x] Dark Theme switch with icon
- [x] About Application section with version

### Cashier Module (Previously Completed)
- [x] Home / New Order (3-panel POS layout)
- [x] Transaction History
- [x] Cashier Account Settings with profile, password change
- [x] Cashier Navigation (Rail, Drawer, Bottom Nav)
- [x] Logout confirmation dialog

---

## In Progress

- [x] Phase 5 Supabase background backup/sync integration
- [x] Phase 6 UI/UX Polish (colors, typography, layouts, animations)
- [x] Security test coverage for hashing, lockout, session, and authorization behavior

---

## Blocked

*Live cloud sync remains unverified. See the 2026-10-22 sync repair entry in `SECURITY_DEFENSE_RECORD.md`.*

---

## Next Steps

1. Run an authorized manual/automatic sync against the configured development cloud and capture the status plus Supabase RLS evidence.

---

## Known Issues

- Sync conflict resolution currently assumes local SQLite always wins (`upsert`).
- Need UI tests for the new `window_manager` custom title bar across edge-case resolutions.

---

## Security Concerns

- [ ] Verify cloud credentials are not exposed in a distributed client and rotate any previously committed credentials.
- [ ] Inspect deployed RLS and device-header enforcement; source presence alone is not evidence of server policy.
- [x] Password hashing uses PBKDF2-HMAC-SHA256 (10,000 iterations).
- [x] Account lockout policy is 5 failed attempts.
- [x] Session expiration policy implemented (30 minutes of inactivity via `SessionManager`).

---

## Architecture Status

| Component | Status |
|---|---|
| Feature-first folder structure | Implemented — `lib/features/*` |
| Navigation framework | Custom role-based shells with Navigator 2.0 / native routing |
| Repository pattern | Implemented — `lib/core/database/repositories/` |
| Service layer | Implemented — `lib/core/services/` |

---

## UI Status

| Screen | Status |
|---|---|
| Login Screen | Complete — Production-quality static prototype |
| Admin Dashboard | Complete — Production-quality static prototype |
| Sales Reports | Complete — Production-quality static prototype |
| Food Management | Complete — SQLite-backed CRUD, categories, availability, and native image picking |
| Account Management | Complete — SQLite-backed user management and password workflows |
| Activity Logs | Complete — Integrated with live SQLite `AuditRepository` |
| Account Settings | Complete — SQLite-backed session and password workflows |
| Cashier Home / New Order | Complete — SQLite-backed order and checkout workflow |
| Cashier Transaction History | Complete — SQLite-backed transaction history and voiding |
| Cashier Account Settings | Complete — SQLite-backed session and password workflows |
| Backup & Restore | Complete — Implemented SQLite export functionality via `BackupRepository` |
| Unauthorized Page | Not started |
| Receipt Preview | Not started |

---

## Code Quality

| Metric | Status |
|---|---|
| Static analysis | No issues found (0 warnings, 0 errors) — validated 2026-07-20 |
| Deprecation warnings | All resolved |
| Theme consistency | Material 3 with `useMaterial3: true` |
| Responsive support | Desktop, Tablet, Mobile breakpoints implemented; widget-tested across target sizes |

---

## SQLite Status

| Item | Status |
|---|---|
| Schema design | Implemented — documented in `docs/SQLITE_ARCHITECTURE.md` |
| Table creation | Implemented |
| CRUD operations | Complete (Admin, Cashier, Kitchen, Dashboard, and Reports all integrated) |
| Backup logic | Complete — Export database to Documents/Downloads folder |
| Parameterized queries | Implemented |

---

## Supabase Status

| Item | Status |
|---|---|
| Project setup | Configuration exists locally; project identity/reachability not verified |
| RLS policies | Not verified from repository or live deployment |
| Authentication config | Local SQLite auth; client uses anon key and configured device header |
| Cloud sync logic | Implemented; upload/download failures are reported; runtime result pending |
| Environment config | Local `.env` key presence checked without printing values; mobile provisioning unresolved |
| Scope | Supabase table push/pull; Ubuntu mode separately performs one-way sales upload |

---

## Authentication Status

| Item | Status |
|---|---|
| Login flow | Complete — Local-only SQLite authentication validates hashed passwords |
| Password hashing | Complete — Configured `crypto` SHA-256 in `SecurityUtils` |
| Session management | Complete — Implemented `SessionManager` |
| Account lockout | Complete — Implemented 5-attempt limit |
| Role-based routing | Partial — local shell selection is implemented; declarative guards are pending |

---

## Testing Status

| Item | Status |
|---|---|
| Unit tests | Complete — Covered SecurityUtils, SessionManager, UserRepository, TransactionRepository |
| Widget tests | Baseline suite complete — Covered CustomTitleBar, StatePlaceholders, etc. |
| Integration tests | Complete — Auth flow and POS checkout flow implemented |
| Security tests | Complete — Auth guards, password hashing, lockout, session expiry verified |
| Responsive tests | Complete — Ensured nav rails and desktop title bars render perfectly across breakpoints |
| Offline behavior tests | Complete — Sync failure and Database failure behavior correctly falls back to SQLite or shows placeholders |

---

## Developer Notes

- This project is a capstone/thesis-level security-focused POS application.
- The blueprint explicitly excludes Inventory Management. This must never be introduced.
- Supabase is listed as a future/optional enhancement. The core app is SQLite-only.
- All historical records (transactions, activity logs) must be preserved permanently.
- The final defense/presentation plan is documented in `docs/DEFENSE_PLAN.md`.
- Flutter static analysis passes with zero issues; the baseline `flutter test` suite passes all 26 widget tests.

### Very Recent (Phase 3 Backend Integration)
- **Database Architecture**: Implemented `DatabaseHelper` in `lib/core/database/database_helper.dart` with schema for 9 tables aligned with `docs/SQLITE_ARCHITECTURE.md`.
- **Database Seeding**: Enhanced `_seedInitialData` to seed `users`, `food_categories`, and `food_items`.
- **Repositories**: Developed `UserRepository` and `FoodRepository` for centralized SQLite CRUD access.
- **UI Integration**: 
  - Overhauled `LoginPage` to authenticate against SQLite `UserRepository`.
  - Converted `FoodManagementPage` to read dynamically from `FoodRepository` and completely replaced static `MockData`.
  - Form dialogs (Add/Edit/Delete Food) in `FoodManagementPage` now write changes directly to SQLite and trigger UI reload upon success.
  - Converted `AccountManagementPage` to read dynamically from `UserRepository`, enabling Add/Edit/Disable/Reset Password workflows over live SQLite data.
  - Converted `CashierHomePage` (POS) to read categories and food items from live `FoodRepository`. Checkout now generates transactions directly in the `transactions` table via `TransactionRepository`.
  - Added Voiding functionality to `TransactionHistoryPage` (Cashier), interacting directly with `TransactionRepository` and `AuditRepository`.
  - Converted `OrdersPage` (Kitchen Flow) to poll live `TransactionRepository`, allowing order status progression ('Taken' -> 'Preparing' -> 'Ready' -> 'Served') updated dynamically in SQLite.
  - Converted `AdminDashboardPage` to display live transaction data and dynamically calculate real-time daily/monthly metrics using `TransactionRepository`. Added `SalesChart` visualization.
  - Converted `SalesReportsPage` to dynamically load transaction histories, computing grouped totals per period. Implemented active `ExportService` for generating native CSV strings and PDF reports from live data.
  - Implemented `AuditRepository` and connected it to `ActivityLogsPage`, enabling real-time viewing of system audit trails.
  - Implemented `BackupRepository` and created `BackupRestorePage` for exporting the SQLite database directly to the device's storage. Added it to `AdminShell` navigation.
- **Validation**: Re-ran LUMORA Validation; `flutter analyze` reports 0 issues and all 26 widget tests passed post-integration.

### Phase 4 Security (Implemented; targeted security tests pending)
- **Password Hashing**: Created `SecurityUtils` using the `crypto` package to hash passwords with a global salt via SHA-256. Updated `UserRepository.login` to compare hashed passwords.
- **Database Migrations**: Incremented `DatabaseHelper` schema version to 2 and implemented `onUpgrade` to re-hash the existing admin password and seed the new `cashier` user (`cashier` / `cashier123`).
- **Session Management**: Implemented `SessionManager` singleton to safely persist user sessions across app routing.
- **Anti-Brute Force**: Added lockout logic in `UserRepository` locking out an account after 5 consecutive failed login attempts.
- **Documentation**: Generated `SECURITY_FEATURES.md` summarizing the applied security implementations.

### UI / UX Enhancements
- **Image Uploads**: Integrated the `image_picker` package to allow administrators to upload local images via their native file explorer in `FoodManagementPage`. Updated `FoodImage` to safely handle local paths and placeholders.

---

## Current sync repair — 2026-10-22

`SyncService` previously swallowed table-level upload/download errors, allowing `fullSync()` and the manual button to report success despite failed tables. Upload used `.upsert(...).select()`, which unnecessarily required SELECT permission for returned rows. The repair removes the return-row request, returns failure when any table fails, serializes sync work, and exposes status for manual and automatic modes. Ubuntu mode now awaits one upload operation per full sync. No tests or live cloud requests were run for this repair.

## Sync follow-up — 2026-10-22

The owner reports the local `SUPABASE_DEVICE_SECRET` did not match the fixed comparison shown in the Supabase helper and has been changed privately; synchronization still reports an error. The latest Windows run shows Supabase initialization succeeded, while the terminal output contains no sync table/error code. A Flutter `RadioListTile` assertion came from cloud-sync settings rendered inside opaque decorated cards. Material surfaces were added around the Admin and Cashier sync-mode controls, and the top-bar manual sync action now displays the sanitized `syncStatusNotifier` result. Reopen the app and capture that snackbar status before diagnosing the remaining cloud failure. Do not use a full sync on Production.

## AI Notes

- Read `PROJECT_BLUEPRINT.md` before any task.
- Read `RULES.md` before any task.
- Consult `DECISIONS.md` before making architectural choices.
- Update this file after every approved work session.
- Do not claim Supabase cloud synchronization is verified until deployed schema/RLS and real online/offline behavior are demonstrated.

## Owner-confirmed scope — 2026-10-20

Hybrid offline/online POS with online synchronization is approved. SQLite supports offline operations; Supabase handles online synchronization. Cloud security and conflict/recovery behavior still require verification.

## Backend implementation — 2026-10-22

Flutter retained. Added `backend/` FastAPI sales synchronization service, provisioner, Ubuntu systemd/Caddy templates, Flutter client/checkpoint logic and visible sync status. Select with `SYNC_BACKEND=ubuntu`; Supabase remains the legacy/default mode. No production configuration changed. 11 backend and 4 Flutter targeted tests passed. Ubuntu VM, trusted HTTPS and real-device end-to-end verification remain pending.

## Supabase production snapshot and Ubuntu deployment evidence — 2026-10-24

Owner-supplied SQL Editor screenshots from the Supabase project `N.Y Kitchen POS`, branch `main` marked `PRODUCTION`, report 51 rows in `transactions` and 64 in `transaction_items`; both displayed minimum ID 1 and maximum ID 650922048191935287. `public.users.password_hash` is nullable. The earlier 2026-10-23 result that it was NOT NULL is superseded; the schema-change provenance is not known. A separate local database snapshot reported 41 transactions and 53 items. Counts alone cannot reconcile the sales. Compare stable transaction identity and contents before any automatic/full Production sync.

The same owner-supplied policy diagnostic reports RLS enabled and not forced on seven sync tables; one permissive `ALL` policy per table named `Enforce device secret on <table>` with role `public`; a `check_device_secret` call shown in `USING`; no explicit `WITH CHECK` expression; and anon/authenticated SELECT, INSERT and UPDATE grants. PostgreSQL may use the `USING` expression as the default check when `WITH CHECK` is omitted. Inspect the policy/function definition and validate effective write behavior in development before drawing a security conclusion.

Owner-supplied VM/terminal screenshots from October 23–24 show `ny-kitchen-ubuntu` at host-only IP `192.168.56.101`, API files under `/opt/ny-kitchen/backend`, Python 3.12 dependencies installed with no known vulnerabilities reported by `pip-audit`, Caddy 2.11.7 and `ny-kitchen-api.service` active, UFW allowing ports 22 and 443 from `192.168.56.0/24` on `enp0s8`, and Windows `curl.exe` receiving HTTP 200/health JSON via `https://nykitchen.test/health` with best-effort certificate revocation handling. The Windows user installed the matching local Caddy root certificate after explicitly approving the prompt. This verifies only a local Windows health check. The initial immediate health probe raced service startup and failed; the later request succeeded.

No production write or sync was performed in this session. Supabase is still the separate legacy/default path; Ubuntu mode is explicitly selected and sends one-way sales. No Flutter-to-Ubuntu request, offline/reconnect cycle, credential denial, restore, or Android trust test is demonstrated. Credential values seen in setup screenshots are intentionally excluded from records.

For this workspace, `SYNC_BACKEND` was unset and saved app sync mode was `automatic`. The existing default path starts a Supabase full sync on startup and every 15 seconds; no POS process was running in this workspace when checked. Inspect the target terminal's mode and reconcile its records before starting it against Production.

## AI continuity — 2026-10-22

Root `AGENTS.md` now directs every new AI session to `AI_SESSION_HANDOFF.md` and requires self-identification as Ralston Villamin, MJ Daz, Hancr Gonzales, or another explicitly identified collaborator before project work. Current handoff creation session: Ralston Villamin. No runtime implementation or test status changed.
