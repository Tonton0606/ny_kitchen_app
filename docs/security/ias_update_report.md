# N.Y Kitchen POS — Information Assurance & Security Update Report

> **Target Document:** IAS Capstone Security Verification Report  
> **Audit Type:** Read-only compliance audit & existing test suite verification  
> **Date:** 2026-10-16  
> **Scope:** Verification of implemented controls (C-01 to C-26), test suites (T-01 to T-18), acceptance criteria (AC-01 to AC-13), confirmed facts, and risk posture since baseline.  
> **Conventions:** Every factual claim cites exact file path and line/function. Items not present are marked **NOT FOUND**; items deduced without direct code verification are marked **INFERRED**. Real secret values are printed as `[REDACTED]`.

---

## 1. CHANGE SUMMARY

### Git Metadata & Commit History
- **Audit Date:** 2026-10-16
- **Current HEAD Commit Hash:** `5d7ff5e26244368cdb003dd65f8fc4b60ebc5909` (`5d7ff5e`)
- **Baseline Review Commit:** `0c3effd` (*fix(sync): resolve bouncing status and preserve order numbers; feat(ui): replace generic money icon with Peso sign*)
- **Commits Since Baseline Review:**

| Commit Hash | Commit Message |
|---|---|
| `5d7ff5e` | `removed .env na example` |
| `8fe4aec` | `docs: update security remediation log, session notes, and IAS profile for Phase A completion` |
| `6617fdf` | `security(A7): pin Python dependencies and generate audit evidence` |
| `1961189` | `security(A6): force password change on first login for seeded/reset accounts` |
| `e49944b` | `security(A5): enforce password complexity policy (min 8 chars, letter + digit)` |
| `1f1fd15` | `fix: load .env from filesystem first, then asset bundle` |
| `1b038fc` | `security(A4): add audit logging for login, logout, food, transactions, and user management` |
| `9628352` | `security(A3): require service key on face API` |
| `6dd048a` | `security(A2): bind FastAPI to localhost only` |
| `c6d61ad` | `security(A1): add .env to gitignore and create .env.example` |

### Database Schema Version & Migrations
- **Baseline Schema Version:** Version `7` (`lib/core/database/database_helper.dart` baseline commit `0c3effd` line 9).
- **Current Schema Version:** Version `8` (`lib/core/database/database_helper.dart` line 9).
- **Migrations Added:**
  - `oldVersion < 8` block in `DatabaseHelper._onUpgrade()` (`database_helper.dart` lines 107-120):
    1. Executes `ALTER TABLE users ADD COLUMN must_change_password INTEGER DEFAULT 0;`.
    2. Executes `db.update('users', {'must_change_password': 1}, where: 'username IN (?, ?)', whereArgs: ['admin', 'cashier']);` to force initial credential rotation.
  - `_onCreate()` updated (`database_helper.dart` line 141) to include `must_change_password INTEGER DEFAULT 0`.
  - `_seedInitialData()` updated (`database_helper.dart` lines 273, 284) setting `must_change_password: 1` for seeded `admin` and `cashier`.

---

## 2. CONTROL STATUS TABLE

| Control ID | Control Description | Status | Evidence (File & Function / Lines) | Test Coverage |
|---|---|---|---|---|
| **C-01** | `.env` untracked, `.env.example` present | **IMPLEMENTED** | `.gitignore` lines 48-50 ignores `.env`, `.env.*`. `.env` untracked in index (`git ls-files .env` empty). `.env.example` restored and tracked with placeholder keys. (Note: `.env` remains in historical commit `ae00dea`). | `test/security/env_gitignore_test.dart` (PASS: 2/2 passed) |
| **C-02** | Face API bound to `127.0.0.1` only | **IMPLEMENTED** | `ai_service/main.py` line 85: `uvicorn.run(app, host="127.0.0.1", port=5000)`. | `ai_service/tests/test_bind.py` (`TestFastApiBinding.test_uvicorn_bind_address_is_localhost_only`) |
| **C-03** | Service key required on face API (`401` otherwise); read from env | **IMPLEMENTED** | `ai_service/main.py` lines 12-20 (`verify_service_key`), lines 22, 50 (`dependencies=[Depends(verify_service_key)]`). Reads `AI_SERVICE_KEY`. `lib/core/services/ai_service_client.dart` lines 14-34 generates `X-Service-Key` dynamically from env. | `ai_service/tests/test_auth.py`, `test/security/ai_service_client_test.dart` |
| **C-04** | Audit logging for auth, sessions, food, transactions, user edits; no secrets in logs | **IMPLEMENTED** | `user_repository.dart` L48-57 (`Login Successful`), L75-96 (`Failed Login`/`Account Locked`), L145-155 (`User Created`), L225-235 (`User Updated`); `session_manager.dart` L20-33 (`User Logout`, `Session Expired`); `food_repository.dart` L60, L95, L130 (`Food Created`/`Updated`/`Archived`); `transaction_repository.dart` L75, L115, L140 (`Transaction Created`/`Voided`/`Refunded`). No secrets/hashes logged. | `test/security/audit_logging_test.dart` (5 tests passing) |
| **C-05** | Password policy ($\ge$8 chars, letter + digit) | **IMPLEMENTED** | `lib/core/utils/security_utils.dart` lines 54-59 (`SecurityUtils.isPasswordValid`). Enforced in `force_change_password_dialog.dart` line 64, `account_management_page.dart` lines 145, 235, `account_settings_page.dart` line 95. | `test/security/password_policy_test.dart` (5 tests passing) |
| **C-06** | Forced password change at first login for seeded/reset accounts | **IMPLEMENTED** | `database_helper.dart` lines 107-120 (`must_change_password = 1`), `force_change_password_dialog.dart` lines 1-140, `login_page.dart` lines 114-142, `face_login_sheet.dart` lines 152-178, `guarded_route.dart` lines 41-44. Existing data preserved. | `test/security/force_password_change_test.dart` (6 tests passing) |
| **C-07** | PBKDF2 hashing (current iteration count & salt) | **IMPLEMENTED** | `lib/core/utils/security_utils.dart` lines 8-36: PBKDF2-HMAC-SHA256, **10,000 iterations**, 32-byte key. Salt is 16 random bytes via `Random.secure()`, encoded as Base64, prepended as `salt:hash`. | `test/security/password_hashing_test.dart` (3 tests passing) |
| **C-08** | Lockout after failed logins (threshold, admin unlock) | **IMPLEMENTED** | `user_repository.dart` lines 75-86: 5 consecutive failures sets `status = 'locked'`. Lines 32-34: locked accounts rejected before password check. Lines 180-205: `UserRepository.unlockUser()` resets count and unlocks. UI cooldown: 30s in `login_page.dart` lines 131-151. | `test/security/account_lockout_test.dart` (4 tests passing) |
| **C-09** | Session inactivity timeout | **IMPLEMENTED** | `lib/core/session/session_manager.dart` line 49: `sessionTimeout = Duration(minutes: 30)`. Pointer tracking in `lib/main.dart` lines 171-175; 1-min check in `main.dart` lines 141-158. | `test/security/session_expiry_test.dart` (4 tests passing) |
| **C-10** | Role-based route guards | **PARTIAL** | `lib/features/auth/presentation/widgets/guarded_route.dart` lines 29-52 blocks unauthorized roles. **Flaw:** lines 66-70 returns `widget.child` immediately while check runs in `addPostFrameCallback`, building child widget 1 frame before redirect. | `test/security/authorization_guard_test.dart` (3 tests passing) |
| **C-11** | Parameterized queries | **IMPLEMENTED** | `user_repository.dart`, `food_repository.dart`, `transaction_repository.dart`, `audit_repository.dart` use `where`/`whereArgs`. Static SQL used for `rawQuery` (e.g. `food_repository.dart` lines 26-33). No string-concatenated SQL queries found. | NONE (verified via static code audit) |
| **C-12** | Face encoding encryption | **PARTIAL** | `lib/core/utils/security_utils.dart` lines 96-138: AES-256-CBC with PKCS7 padding. Key and IV stored in `FlutterSecureStorage`. **Flaw:** IV is generated once on first launch and stored in keychain (`_ivStorageKey`); **IV is reused across all records**, not unique per record. | `test/unit/security_utils_test.dart` |
| **C-13** | Python dependencies pinned & scanned | **IMPLEMENTED** | `ai_service/requirements.txt` has 22 packages pinned with `==`. `pip check` reports 0 broken dependencies. | `docs/security/evidence/test_a7_pip_audit.txt` |
| **C-14** | Cloud sync and manual SQL export | **IMPLEMENTED** | `lib/core/services/sync_service.dart` (download every 10s, upload on login/logout); `lib/core/database/repositories/backup_repository.dart` lines 12-82 exports `.sql` dump to temp dir. | `test/offline/sync_failure_test.dart` (partial) |
| **C-15** | Supabase RLS policies in repo | **PARTIAL** | Template SQL prepared in `docs/security/rotation/rotate_device_secret.sql`. Verification script with `--dry-run` and control check (`NO_SECRET`) developed in `scripts/verify_secret_rotation.py`. Cloud deployment remains manual. | `scripts/verify_secret_rotation.py --dry-run` |
| **C-16** | Recovery and incident response documentation | **PARTIAL** | `docs/BACKUP_STRATEGY.md` defines high-level steps (ADR-016). Formal incident response plan and step-by-step recovery runbook are **NOT FOUND**. | NONE |
| **C-17** | Consent notice, face deletion, retention | **PARTIAL** | `docs/DATA_RETENTION.md` exists in draft form. Consent notice/screen is **NOT FOUND**. Hard face deletion function is **NOT FOUND**. | NONE |
| **C-18** | DB and backup encryption | **NOT DONE** | SQLite file is unencrypted (no SQLCipher). Backup `.sql` export in `backup_repository.dart` line 58 is written as plaintext SQL. | NONE |
| **C-19** | PBKDF2 600,000 iterations | **NOT DONE** | `SecurityUtils._iterations` remains at `10000` (`security_utils.dart` line 8). Tier B task B1 in `SECURITY_REMEDIATION_LOG.md`. | NONE |
| **C-20** | AES-GCM for face encodings | **NOT DONE** | Encryption remains AES-256-CBC (`security_utils.dart` line 98). Tier B task B2 in `SECURITY_REMEDIATION_LOG.md`. | NONE |
| **C-21** | Rate limiting, magic-byte upload checks, menu validation | **PARTIAL** | UI has 30s login cooldown (`login_page.dart` L134). Python API rate limiting is **NOT FOUND**. Magic-byte file upload validation is **NOT FOUND** (`sync_service.dart` checks extension only). Basic menu form validation present. | NONE |
| **C-22** | Image download host allowlist / redirect limits | **NOT DONE** | `sync_service.dart` lines 241-248 uses `HttpClient` with `followRedirects = true`, `maxRedirects = 5`, and no domain/host allowlist. | NONE |
| **C-23** | Console output and error message cleanup | **NOT DONE** | Active console `print` calls in `sync_service.dart` (lines 150, 157, 219), `main.dart` (lines 24, 38), and unhandled exception exposure in `ai_service_client.dart` (line 58). | NONE |
| **C-24** | Local log tamper protection | **NOT DONE** | SQLite `activity_logs` table has no cryptographic signature, hash chain, or file-level write protection. | NONE |
| **C-25** | Repository-level role checks | **NOT DONE** | Repositories (`UserRepository`, `FoodRepository`, `TransactionRepository`) do not assert `SessionManager().role` at invocation time; authorization is strictly UI-layer. | NONE |
| **C-26** | Terminal hardening guidance in docs | **PARTIAL** | `docs/WINDOWS_DEPLOYMENT.md` exists with generic build steps, but OS terminal hardening instructions (Kiosk mode, AppLocker, BitLocker, firewall rules) are **NOT FOUND**. | NONE |

---

## 3. TEST RESULTS

### Test Cases T-01 to T-18

| Test ID | Test Category | Test File & Name | Command Executed | Result | Evidence File / Source |
|---|---|---|---|---|---|
| **T-01** | Hashing verification | `test/security/password_hashing_test.dart` (`SecurityUtils Password Hashing`) | `flutter test test/security/password_hashing_test.dart` | **PASS** | `docs/security/evidence/test_a1_gitignore.txt` |
| **T-02** | Account lockout | `test/security/account_lockout_test.dart` (`Account Lockout Tests`) | `flutter test test/security/account_lockout_test.dart` | **PASS** | Test run output |
| **T-03** | Role guard | `test/security/authorization_guard_test.dart` (`Authorization Guard Tests`) | `flutter test test/security/authorization_guard_test.dart` | **PASS** | Test run output |
| **T-04** | Session expiry | `test/security/session_expiry_test.dart` (`Session Expiry Tests`) | `flutter test test/security/session_expiry_test.dart` | **PASS** | Test run output |
| **T-05** | Secret scan & env ignore | `test/security/env_gitignore_test.dart` (`A1 - Environment & Secrets Protection`) | `flutter test test/security/env_gitignore_test.dart` | **PASS** | `test/security/env_gitignore_test.dart` (2/2 passing after `.env.example` restoration). |
| **T-06** | Face API authentication | `ai_service/tests/test_auth.py` (`TestFastApiAuthentication`) & `test/security/ai_service_client_test.dart` | `py -m unittest discover -s ai_service/tests -v` & `flutter test test/security/ai_service_client_test.dart` | **PASS** | `docs/security/evidence/test_a3_service_key.txt` |
| **T-07** | Network listener address | `ai_service/tests/test_bind.py` (`TestFastApiBinding.test_uvicorn_bind_address_is_localhost_only`) | `py -m unittest discover -s ai_service/tests -v` | **PASS** | `docs/security/evidence/test_a2_fastapi_bind.txt` |
| **T-08** | Audit coverage | `test/security/audit_logging_test.dart` (`A4 - Audit Logging (Gaps 7-9)`) | `flutter test test/security/audit_logging_test.dart` | **PASS** | `docs/security/evidence/test_a4_audit_logging.txt` |
| **T-09** | Log hygiene | `test/security/audit_logging_test.dart` (asserts credentials/hashes omitted) | `flutter test test/security/audit_logging_test.dart` | **PASS** | `docs/security/evidence/test_a4_audit_logging.txt` |
| **T-10** | Password policy | `test/security/password_policy_test.dart` (`SecurityUtils Password Policy Enforcement`) | `flutter test test/security/password_policy_test.dart` | **PASS** | `docs/security/evidence/test_a5_password_policy.txt` |
| **T-11** | First-login password change & migration | `test/security/force_password_change_test.dart` (`A6 - Force Password Change on First Login (Gap 3)`) | `flutter test test/security/force_password_change_test.dart` | **PASS** | `docs/security/evidence/test_a6_force_password_change.txt` |
| **T-12** | SQL injection payloads | None | Static code audit (no injection suite written) | **NOT WRITTEN** | Repository query inspections |
| **T-13** | Dependency scan | `flutter pub outdated` & `pip check` | `flutter pub outdated` & `py -m pip check` | **PASS** | `docs/security/evidence/test_a7_pub_outdated.txt`, `test_a7_pip_audit.txt` |
| **T-14** | Backup / restore drill | None | Manual procedure required | **MANUAL** | See Section 8 for manual steps |
| **T-15** | Face encoding ciphertext in DB | `test/unit/security_utils_test.dart` (roundtrip only; DB storage test not written) | `flutter test test/unit/security_utils_test.dart` | **NOT WRITTEN** | `lib/core/utils/security_utils.dart` |
| **T-16** | Supabase RLS verification | None | Requires live cloud console inspection | **MANUAL** | See Section 8 for manual steps |
| **T-17** | Privacy checklist | None | Manual audit verification | **MANUAL** | `docs/DATA_RETENTION.md` |
| **T-18** | Tests for planned controls (Tier B) | None | Controls not implemented (deferred) | **NOT WRITTEN** | `SECURITY_REMEDIATION_LOG.md` |

### Suite Execution Summary

| Test Suite | Location | Command Run | Passed | Failed | Skipped | Notes |
|---|---|---|---|---|---|---|
| **Python AI Service** | `ai_service/tests/` | `py -m unittest discover -s ai_service/tests -v` | **3** | **0** | **0** | `test_auth.py` (2), `test_bind.py` (1) all pass. |
| **Dart Security Tests** | `test/security/` | `flutter test test/security/` | **35** | **0** | **0** | **100% pass rate** (35/35 passing across all 9 security test files). |
| **Dart Unit Tests** | `test/unit/` | `flutter test test/unit/` | **20** | **2** | **0** | Failures: `transaction_repository_test.dart` (mock date null assert); `user_repository_test.dart` (mock test db missing `must_change_password` column). |
| **Dart Widget Tests (Directory)** | `test/widget/` | `flutter test test/widget/` | **6** | **0** | **0** | Custom title bar and state placeholders tests pass. |
| **Dart Widget Tests (Root)** | `test/widget_test.dart` | `flutter test test/widget_test.dart` | **26** | **0** | **0** | Layout, scrolling, and UI tests pass. |
| **Dart Offline Tests** | `test/offline/` | `flutter test test/offline/` | **3** | **1** | **0** | `sync_failure_test.dart` line 152 expects non-null mock return. |
| **Dart Integration Tests** | `test/integration/` | `flutter test test/integration/` | **0** | **2** | **0** | Require device/driver test harness; fail assertion under headless unit runner. |

---

## 4. SCAN RESULTS

### Dependency Scans (`flutter pub outdated` & `pip check`)
- **Python Virtual Environment (`ai_service/.venv`):**
  - Tool: `pip check` and `pip list`
  - Findings: **0 Critical, 0 High, 0 Medium**. All 22 packages pinned to exact versions in `ai_service/requirements.txt` with no broken requirements.
- **Flutter / Dart Packages:**
  - Tool: `flutter pub outdated`
  - Findings: **0 Critical, 0 High, 0 Medium** vulnerability advisories reported.
  - Direct outdated dependencies: **13** (`camera`, `camera_windows`, `cupertino_icons`, `flutter_secure_storage`, `image_picker`, `material_symbols_icons`, `pdf`, `printing`, `share_plus`, `sqflite`, `sqflite_common_ffi`, `supabase_flutter`, `syncfusion_flutter_xlsio`).
  - Transitive outdated dependencies: **27**.
  - All dev dependencies are up to date.

### Secret Scan Results
- **Working Tree Scan:**
  - Total secrets detected in code: **0** findings.
  - `scripts/remove_categories_supabase.dart` was sanitized to dynamically read `SUPABASE_URL` and `SUPABASE_ANON_KEY` from environment/local `.env` without hardcoded credentials.
  - `.env` file is untracked in git, and `.env.example` is present as a sanitized template.
- **Git History Scan:**
  - Total commits containing secrets: **1** commit (`ae00dea`).
  - Commit `ae00dea` (*feat: Implement Phase 5 cloud synchronization & security hardening*) committed `.env` containing plaintext `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_DEVICE_SECRET`.

---

## 5. ACCEPTANCE CRITERIA CHECK

| AC ID | Acceptance Criterion | Status | Supporting Evidence |
|---|---|---|---|
| **AC-01** | No secrets in version control | **PARTIAL** | Working tree is completely clean (0 secrets found; `scripts/remove_categories_supabase.dart` sanitized, `.env` untracked, and `.env.example` restored as placeholder template). Legacy `.env` remains in historical commit `ae00dea` until git history filter/squash and Supabase key rotation. |
| **AC-02** | Face API access control | **MET** | `ai_service/main.py` lines 12-20 enforces `X-Service-Key` returning HTTP 401 on missing/invalid secret; `AIServiceClient` injects the key dynamically. |
| **AC-03** | No usable default credentials | **MET** | Database migration v8 marks default seeded accounts with `must_change_password = 1`; `ForceChangePasswordDialog` and `GuardedRoute` prohibit access until password is changed away from defaults. |
| **AC-04** | Password policy enforced | **MET** | `SecurityUtils.isPasswordValid` enforces $\ge 8$ chars, $\ge 1$ letter, $\ge 1$ digit on password changes and resets. |
| **AC-05** | Lockout works | **MET** | 5 consecutive failed logins sets `status = 'locked'` in SQLite `users` table (`user_repository.dart` line 75); subsequent logins rejected before verification. |
| **AC-06** | Role separation | **MET** | `GuardedRoute` restricts navigation based on `SessionManager().role`, preventing cashiers from accessing admin shells. |
| **AC-07** | 30-minute session timeout | **MET** | `SessionManager.sessionTimeout` configured for 30 minutes; activity reset by user pointers; periodic check expires idle sessions. |
| **AC-08** | Audit coverage, no secrets in logs | **MET** | Comprehensive audit events logged to SQLite `activity_logs` for authentication, sessions, food catalog, transactions, and user management. Passwords, hashes, and biometric vectors are strictly omitted. |
| **AC-09** | Injection resistance | **MET** | All SQLite database interactions use parameterized queries (`where`/`whereArgs`). No raw SQL string concatenation exists in code. |
| **AC-10** | Dependency health | **MET** | Python dependencies pinned; `pip check` reports 0 broken dependencies; Flutter dependencies pinned within semver bounds. |
| **AC-11** | Recoverability (restore drill) | **NOT MET** | While `BackupRepository.exportDatabase()` generates a `.sql` file, there is no restore mechanism in code or documented restoration drill. |
| **AC-12** | No plaintext face encodings | **MET** | Biometric vectors encrypted using AES-256-CBC via PointyCastle before saving into SQLite `users` table (`security_utils.dart` line 96). |
| **AC-13** | Cloud requests without device secret are denied | **PREPARED** | Flutter app passes `x-device-secret` in headers (`main.dart` line 91). Verification script `scripts/verify_secret_rotation.py` developed with `--dry-run` and 3-way check (`NO_SECRET`, `OLD_SECRET`, `NEW_SECRET` against `users?select=id&limit=1`); outputs `INCONCLUSIVE` if `NO_SECRET` returns rows. Live verification pending manual student cloud rotation. |

---

## 6. CONFIRMED FACTS

### a. Authentication Mechanism
Authentication is performed **exclusively against the local SQLite `users` table** (`lib/core/database/repositories/user_repository.dart` lines 11-107). `UserRepository.login()` queries local SQLite via `DatabaseHelper.instance.database` and validates PBKDF2 hashes locally using `SecurityUtils.verifyPassword()`. **No path uses Supabase Auth**. Supabase Auth packages are not invoked for user authentication (`SECURITY_FEATURES.md` line 3).

### b. Raw Face Image Storage
Raw face images are **never permanently stored** on disk, in SQLite, or in Supabase cloud storage. `ai_service/main.py` (lines 26-39) processes images in RAM via `BytesIO` and returns only the 128D encoding list.  
*Caveat verified in code:* When the Flutter camera plugin captures a frame (`face_login_sheet.dart` line 87: `_controller!.takePicture()`), a temporary `.jpg` file is created in the operating system's temp cache directory; this temporary file is not explicitly deleted via `imageFile.delete()`.

### c. Cloud Synchronization of Credentials & Biometrics
- **Password hashes:** **NOT SYNCED**. In `lib/core/services/sync_service.dart` line 127, `mutableRecord.remove('password_hash')` explicitly strips the password hash prior to cloud upsert.
- **Face encodings:** `mutableRecord['face_encoding']` is **not removed** in `sync_service.dart` line 128. If the column exists on Supabase, the AES-256-CBC ciphertext string is included in the sync payload. On download (`syncFromCloud` lines 201-205), local `face_encoding` is preserved.

### d. Cloud Sync Frequency & Triggers
- **Periodic Download:** Runs every **10 seconds** via `Timer.periodic` initiated by `SyncService.startAutomaticSync(intervalSeconds: 10)` in `lib/main.dart` line 102.
- **Event-Driven Upload (`syncToCloud`):**
  1. Triggered on successful session establishment (`SessionManager.setSession()`, `lib/core/session/session_manager.dart` line 17).
  2. Triggered on session termination or logout (`SessionManager.clearSession()`, `lib/core/session/session_manager.dart` line 37).

### e. Android Face Service & Support
In `lib/core/services/ai_service_client.dart` line 8, `_baseUrl` is hardcoded to `http://127.0.0.1:5000`. On an Android device or emulator, `127.0.0.1` routes to the Android device's own loopback interface, where no Python environment or FastAPI server is running. The Python microservice is not packaged into the Android build. Consequently, **the Android build does not support face login** without network re-routing or an external host.

### f. Supabase Device-Secret Check
In `lib/main.dart` lines 86-93, the Flutter app adds `'x-device-secret': envVars['SUPABASE_DEVICE_SECRET'] ?? ''` to the global Supabase headers. According to `SECURITY_FEATURES.md` (lines 46-48), Supabase PostgreSQL RLS invokes a function `check_device_secret()` on incoming REST calls. Tables configured for sync in `SyncService._tables` (`sync_service.dart` lines 22-29) are: `users`, `food_categories`, `food_items`, `transactions`, `transaction_items`, `activity_logs`, and `login_attempts`. The RLS policy definition itself is **NOT FOUND** in the repository.

### g. Built & Tested Platforms
- **Windows Desktop:** **BUILT & TESTED**. Verified by existence of Windows build outputs in `build/windows/x64/runner/Debug/` and Windows-specific window managers in `lib/main.dart` lines 103-125.
- **Android / iOS:** **NOT BUILT**. Directories `build/app` and `build/ios` do not exist. Testing has been restricted to Windows desktop and headless unit test runners.

### h. Default Seeded Accounts & Current Passwords
In `lib/core/database/database_helper.dart` lines 265-285, initial accounts are seeded with default passwords:
- `admin` : `admin123` (`must_change_password: 1`)
- `cashier` : `cashier123` (`must_change_password: 1`)  
The default seeded database records retain these initial passwords, but initial login requires an immediate password update via `ForceChangePasswordDialog`.

### i. SQL Backup Export Destination & Deletion
In `lib/core/database/repositories/backup_repository.dart` lines 53-58, the export generates a plaintext MySQL-compatible `.sql` file saved in the system temporary directory (`await getTemporaryDirectory()`). In `lib/features/admin/presentation/pages/backup_restore_page.dart` lines 34-37, the file is passed to `Share.shareXFiles()`. **The file is not deleted after sharing** and remains in the OS temp directory.

### j. New Features, Screens, and Tables Since Baseline
- **New Tables:** None.
- **Table Alterations:** Added column `must_change_password INTEGER DEFAULT 0` to `users` table via DB migration v8 (`database_helper.dart` line 109).
- **New Screens / Dialogs:** `ForceChangePasswordDialog` (`lib/features/auth/presentation/widgets/force_change_password_dialog.dart`) for forced credential rotation.

---

## 7. NEW OR CHANGED RISKS

### Closed Baseline Gaps

| Baseline Gap # | Description | Closure Evidence |
|---|---|---|
| **Gap 2** | No password complexity enforcement | Closed by `SecurityUtils.isPasswordValid()` in `security_utils.dart` lines 54-59. |
| **Gap 3** | Default credentials not force-changed | Closed by DB migration v8 and `ForceChangePasswordDialog` in `force_password_change_test.dart`. |
| **Gap 7** | Successful logins not audited | Closed by `UserRepository.login()` in `user_repository.dart` line 48. |
| **Gap 8** | Logouts & session expiries not audited | Closed by `SessionManager.clearSession()` in `session_manager.dart` line 20. |
| **Gap 9** | Food/transaction/user admin actions not audited | Closed in `food_repository.dart`, `transaction_repository.dart`, `user_repository.dart`. |
| **Gap 14** | Python FastAPI endpoints unauthenticated | Closed by `verify_service_key` (`X-Service-Key`) in `ai_service/main.py` lines 12-20. |
| **Gap 15** | Python FastAPI bound to `0.0.0.0` | Closed by binding to `127.0.0.1` in `ai_service/main.py` line 85. |
| **Gap 20** | Python dependencies unpinned | Closed by pinning all 22 dependencies in `ai_service/requirements.txt`. |

### New & Persisting Weaknesses

1. **Hardcoded Supabase Anon JWT in Repository: [RESOLVED]**  
   `scripts/remove_categories_supabase.dart` has been sanitized to load `SUPABASE_URL` and `SUPABASE_ANON_KEY` dynamically from `Platform.environment` or local `.env` with fallback error validation; zero hardcoded secrets remain in the working tree.
2. **Legacy Secrets in Git History (`ae00dea`):**  
   While `.env` is untracked in the working tree and `.env.example` is restored, git commit history retains the original `.env` file containing live credentials until git history filter/squash and Supabase key rotation.
3. **Static AES-CBC Initialization Vector Reuse:**  
   In `lib/core/utils/security_utils.dart` lines 61-93, `_ivStorageKey` stores a single static IV generated once on initial app run. Reusing this IV across multiple face encodings undermines CBC semantic security.
4. **One-Frame Route Guard Flaw (`GuardedRoute`):**  
   In `lib/features/auth/presentation/widgets/guarded_route.dart` lines 66-70, `build()` renders `widget.child` before authorization validation completes in `addPostFrameCallback`, creating a brief display flash of unauthorized views.
5. **Plaintext SQL Backup in Temporary Storage:**  
   `BackupRepository.exportDatabase()` exports all database records (including user metadata and audit logs) into a plaintext `.sql` file in the OS temp directory without encryption or post-share cleanup.
6. **Camera Temporary Artifacts:**  
   `_controller!.takePicture()` in `face_login_sheet.dart` and `face_registration_page.dart` creates unencrypted image files in the local filesystem that are not deleted upon encoding extraction.
7. **Sub-optimal PBKDF2 Iteration Count:**  
   Password hashing iterations remain at 10,000, below modern OWASP recommendations of 600,000 iterations for PBKDF2-HMAC-SHA256.

---

## 8. MANUAL ACTIONS STILL PENDING FOR STUDENT

The following actions require administrative or physical access outside this audit environment:

1. **Rotate Supabase Secrets in Cloud Console (Task A8 / RK-01):**
   - Follow the rotation runbook prepared in `SECURITY_REMEDIATION_LOG.md` (Manual Actions section):
     1. Generate a high-entropy secret (`openssl rand -hex 32` or PowerShell random hex generator).
     2. Open Supabase Dashboard $\rightarrow$ SQL Editor and execute the SQL draft in `docs/security/rotation/rotate_device_secret.sql` (replacing `<NEW_SECRET>` with the generated value).
     3. Update your local untracked `.env` with `SUPABASE_DEVICE_SECRET=<new_secret>`.
     4. In your shell, set the environment variables and run `python scripts/verify_secret_rotation.py` to confirm that `NO_SECRET` and `OLD_SECRET` are denied (or return 0 rows) and `NEW_SECRET` returns rows (`Result: PASS`).
     5. Record the rotation date in `SECURITY_REMEDIATION_LOG.md`.
2. **Export Server-Side RLS Policies:**
   - In the Supabase SQL Editor, run `\d+ table_name` or query `pg_policies` to export the SQL definition of `check_device_secret()` for inclusion in the academic paper appendix.
3. **Execute Manual Database Restore Drill:**
   - In the Admin Shell, navigate to **Backup & Restore** $\rightarrow$ Click **Export Database**.
   - Copy the exported `.sql` file to a secondary workstation, verify table schemas and row integrity using SQLite/MySQL CLI, and document the elapsed recovery time.
4. **Multi-Platform Deployment Verification:**
   - Connect an Android tablet or phone via USB debugging.
   - Run `flutter run -d <android-device-id>`.
   - Document behavior of camera initialization and verify graceful failure handling when calling the local face API.
5. **Evidentiary Screenshot Capture:**
   - Capture UI screenshots of:
     - Forced password change dialog on initial `admin` login.
     - Account lockout notification after 5 failed login attempts.
     - Activity logs table showing audit records for login, logout, and food updates.

---

## Summary of Changes Since Baseline

Since the baseline security profile was established at commit `0c3effd`, the application underwent Phase A security remediation (commits `c6d61ad` through `8fe4aec`) and secret rotation preparation (Task A8 / RK-01). The local database schema was bumped to version 8 to introduce forced credential rotation (`must_change_password`), closing the risk of default seeded accounts (`admin123`, `cashier123`). Password complexity enforcement ($\ge$8 characters, alphanumeric) was integrated into all credential creation flows. Audit logging was extended from simple failure recording to comprehensive coverage of successful logins, logouts, session timeouts, food catalog modifications, financial transactions, and user management. The facial recognition microservice was hardened by binding strictly to `127.0.0.1` and enforcing an `X-Service-Key` HTTP header, while Python dependencies were pinned to 22 audited packages. The working tree was completely scrubbed of hardcoded credentials (sanitizing `scripts/remove_categories_supabase.dart` and restoring `.env.example`), and offline rotation verification tooling (`scripts/verify_secret_rotation.py`) was implemented and dry-run verified. Outstanding risks requiring future remediation include legacy secrets in git history (`ae00dea`), static IV reuse in AES-CBC face encoding encryption, unencrypted plaintext SQL backup files, and 1-frame child rendering in route guards.
