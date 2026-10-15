# N.Y Kitchen POS — Information Assurance & Security Profile

> **Prepared for:** IAS Capstone Review  
> **Source revision inspected:** branch `main` (latest commit referenced in git log)  
> **Evidence convention:** every factual claim cites a file path and line/function.  
> Items not found are marked **NOT FOUND**. Items inferred rather than directly seen are marked **INFERRED**.

---

## 1. SYSTEM OVERVIEW

### Purpose & Target Users
N.Y Kitchen is a **Point-of-Sale (POS) desktop/mobile application** for a food-service business ("N.Y Kitchen"). It is intended for use by **internal store staff only** — no public-facing interface exists.  
*Source: `README.md`, `lib/main.dart` (title `'N.Y Kitchen POS'`)*

### User Roles

| Role | Description | Shell |
|---|---|---|
| `admin` | Full system access — dashboard, reports, food management, account management, activity logs, backup/restore | `AdminShell` (`lib/features/admin/presentation/pages/admin_shell.dart`) |
| `cashier` | Restricted access — order-taking and transaction processing only | `CashierShell` (`lib/features/cashier/presentation/pages/cashier_shell.dart`) |

### Project Type
**Hybrid** — Flutter desktop/mobile application with a local SQLite database (primary) + Supabase cloud backend (secondary/backup). A local Python microservice handles face recognition.

### Key Features & Modules

| Module | Location |
|---|---|
| Authentication (password + optional face recognition) | `lib/features/auth/` |
| Admin Dashboard | `lib/features/admin/presentation/pages/admin_dashboard_page.dart` |
| Sales Reports | `lib/features/admin/presentation/pages/sales_reports_page.dart` |
| Food Management | `lib/features/admin/presentation/pages/food_management_page.dart` |
| Account Management | `lib/features/admin/presentation/pages/account_management_page.dart` |
| Activity Logs (Audit Trail) | `lib/features/admin/presentation/pages/activity_logs_page.dart` |
| Backup & Restore | `lib/features/admin/presentation/pages/backup_restore_page.dart` |
| Cashier Order Processing | `lib/features/cashier/` |
| Cloud Sync (Supabase) | `lib/core/services/sync_service.dart` |
| Face Recognition Microservice | `ai_service/main.py` |

---

## 2. TECH STACK AND ARCHITECTURE

### Languages, Frameworks, Libraries

| Component | Technology | Version |
|---|---|---|
| UI Framework | Flutter / Dart | SDK `^3.12.2` (`pubspec.yaml` line 22) |
| Local Database | sqflite / sqflite_common_ffi | `^2.4.3` / `^2.4.2` (`pubspec.yaml` lines 38, 41) |
| Cloud Backend | supabase_flutter | `^2.16.0` (`pubspec.yaml` line 50) |
| Cryptography | pointycastle | `^4.0.0` (`pubspec.yaml` line 49) |
| Cryptography | crypto | `^3.0.7` (`pubspec.yaml` line 47) |
| Secure Storage | flutter_secure_storage | `^9.0.0` (`pubspec.yaml` line 58) |
| Env loading | flutter_dotenv | `^6.0.1` (`pubspec.yaml` line 51) |
| HTTP client | http | `^1.6.0` (`pubspec.yaml` line 53) |
| Charts | fl_chart | `^1.2.0` |
| PDF generation | pdf + printing | `^3.13.0` / `^5.15.0` |
| Excel export | syncfusion_flutter_xlsio | `^34.1.33` |
| Camera | camera + camera_windows | `^0.12.0+2` / `^0.2.6+4` |
| Face Recognition API (Python) | FastAPI + uvicorn + face_recognition + Pillow + numpy | No pinned versions (`ai_service/requirements.txt`) |

### Database & Storage

| Store | Technology | Location |
|---|---|---|
| Primary operational DB | SQLite (`ny_kitchen.db`) | App documents directory (`lib/core/database/database_helper.dart` line 28-29) |
| Cloud backup/sync | Supabase (PostgreSQL) | Supabase-hosted cloud (`lib/core/services/sync_service.dart`) |
| Supabase file storage | Supabase Storage bucket `food_images` | Cloud (`sync_service.dart` line 62) |
| AES key/IV for face encodings | flutter_secure_storage (OS keychain) | Device OS secure enclave (`lib/core/utils/security_utils.dart` lines 52-54) |
| Temp backup export | Device temp directory | Local filesystem (`lib/core/database/repositories/backup_repository.dart` line 53-56) |

### Hosting / Deployment

- **Primary app:** Runs locally on Windows/Linux/macOS desktop, or Android/iOS mobile (`lib/main.dart` lines 57, 103).
- **Cloud backup:** Supabase-managed cloud service.
- **Face recognition sidecar:** Local Python FastAPI server at `http://127.0.0.1:5000` (`lib/core/services/ai_service_client.dart` line 7). No containerization files found. **NOT FOUND:** `docker-compose.yml`, Dockerfile, or any deployment scripts for the Python service.

### Third-Party Services & External Integrations

| Service | Purpose | Auth method |
|---|---|---|
| Supabase | Cloud DB backup + file storage | `anon` key + custom `x-device-secret` header (`lib/main.dart` lines 86-93) |
| placehold.co | Placeholder food images (seeded URLs) | None — public URL (`database_helper.dart` lines 291-296) |

### Devices / Hardware
- **Windows PC** — primary deployment target (windowed app, `lib/main.dart` line 103).
- **Android/iOS** — secondary target.
- **Webcam/camera** — used for face registration and face-login liveness check (`pubspec.yaml` lines 55-56; `ai_service_client.dart`).

### Architecture Description & Data Flow

```
[Cashier/Admin UI (Flutter)]
        │ username+password or face image
        ▼
[UserRepository] ──── SQLite (ny_kitchen.db, local) ────► [AuditRepository → activity_logs table]
        │
        │ (face image only)
        ▼
[AIServiceClient] ──HTTP POST──► [Python FastAPI :5000 (local)]
                                          │ 128-D face encoding
                                          ▼
                               [face_recognition library]

[SyncService] ──HTTPS (Supabase REST)──► [Supabase PostgreSQL / Storage]
        ▲
[SessionManager → setSession() / clearSession()]
```

### Entry Points

| Entry Point | Protocol | Notes |
|---|---|---|
| Login screen | In-process (Flutter widget) | `lib/features/auth/presentation/pages/login_page.dart` |
| Admin Shell | In-process | Protected by `GuardedRoute(allowedRoles: ['admin'])` |
| Cashier Shell | In-process | Protected by `GuardedRoute(allowedRoles: ['cashier'])` |
| Python Face API `/extract_encoding` | HTTP POST `127.0.0.1:5000` | No authentication (`ai_service/main.py` line 9) |
| Python Face API `/check_liveness` | HTTP POST `127.0.0.1:5000` | No authentication (`ai_service/main.py` line 36) |
| Supabase REST API | HTTPS | Protected by RLS + `x-device-secret` (`SECURITY_FEATURES.md` lines 46-48) |
| Supabase Storage | HTTPS | Inherits RLS protection (INFERRED from above) |

---

## 3. ASSETS AND DATA

### Data Stored / Processed

| Data Type | Sensitivity |
|---|---|
| Full names, usernames | PII — Moderate |
| Password hashes (PBKDF2) | Credential |
| Face encodings (biometric, AES-CBC encrypted) | PII — High (biometric) |
| Transaction records (amounts, payment method, cashier ID) | Financial |
| Activity/audit logs (user actions, failed logins) | Security-sensitive |
| Login attempt records | Security-sensitive |
| Food item images | Low |
| App configuration key-value pairs | Low |

### Database Tables & Sensitive Fields

| Table | Sensitive Fields | Source |
|---|---|---|
| `users` | `password_hash`, `face_encoding`, `failed_login_count`, `status`, `last_login`, `role` | `database_helper.dart` lines 117-129 |
| `transactions` | `total_amount`, `discount`, `payment_method`, `amount_received`, `change`, `void_reason`, `refund_reason`, `user_id` | `database_helper.dart` lines 162-178 |
| `transaction_items` | `food_price`, `subtotal` | `database_helper.dart` lines 182-193 |
| `activity_logs` | `username`, `role`, `action`, `description`, `device_info` | `database_helper.dart` lines 197-209 |
| `login_attempts` | `username`, `ip_address`, `device_info` | `database_helper.dart` lines 213-221 |
| `app_settings` | Potentially sensitive config values | `database_helper.dart` lines 225-230 |
| `backup_records` | `file_path`, `created_by` | `database_helper.dart` lines 234-243 |

### Other Critical Assets

| Asset | Location | Access |
|---|---|---|
| Supabase URL | `.env` line 1 (plaintext) | Local filesystem; not in `.gitignore` (see §5) |
| Supabase anon key | `.env` line 2 (plaintext JWT) | Local filesystem; not in `.gitignore` |
| `SUPABASE_DEVICE_SECRET` | `.env` line 3 (plaintext) | Local filesystem; not in `.gitignore` |
| AES key + IV for face encoding | OS secure storage via `flutter_secure_storage` | Device OS keychain only |
| SQLite database file | App documents directory | Local OS user account (INFERRED, no explicit permission hardening found) |
| Backup `.sql` export | System temp directory | Temporary; shared via OS share sheet |

---

## 4. AUTHENTICATION AND ACCESS CONTROL

### Login Mechanism

- **Primary:** Username + password via `UserRepository.login()` (`user_repository.dart` lines 11-95).
- **Alternative:** Face recognition login via `AIServiceClient` + `SecurityUtils.decryptFaceEncoding()` (`user_repository.dart` lines 194-211, `ai_service_client.dart`).
- Authentication is **local-only**; Supabase Auth is explicitly **not used** (`SECURITY_FEATURES.md` line 3).

### Password Rules
- **NOT FOUND:** Any minimum length, complexity, or character-class requirements enforced in code. The only validation found is an empty-field check (`login_page.dart` lines 92-97).

### Password Hashing

- Algorithm: **PBKDF2-HMAC-SHA256**, 10,000 iterations, 32-byte key, random per-user salt.
- Implementation: `SecurityUtils.hashPassword()` (`security_utils.dart` lines 24-36).
- Salt is prepended to the hash in format `salt:hash` (base64 encoded).
- Verified by `SecurityUtils.verifyPassword()` which re-derives and compares (`security_utils.dart` lines 39-50).

### Default Credentials

- **Seeded at DB creation:** `admin` / `admin123`, `cashier` / `cashier123` (`database_helper.dart` lines 252-268).  
- These default passwords are hardcoded and seeded by `_seedInitialData()`. There is no forced first-login password change.

### Session / Token Handling

- Session is held **in-memory** as a `Map<String, dynamic>` in the `SessionManager` singleton (`session_manager.dart` lines 8, 11-16).
- No JWT, cookie, or token is issued; the entire session state lives in RAM.
- **Session timeout:** 30 minutes of inactivity (`session_manager.dart` line 31).
- Activity tracked by pointer events in `main.dart` (lines 171-175).
- Session expiry checked every 1 minute via a `Timer.periodic` in `_NYKitchenAppState.initState()` (`main.dart` lines 141-158).

### MFA
- **NOT FOUND:** Traditional MFA (TOTP, SMS, email OTP). Face login acts as a biometric alternative to password, but is not used as a second factor on top of a password; it appears to be a separate primary authentication path.

### Account Lockout

- **DB-persisted lockout:** After 5 consecutive failed logins, `status` is set to `'locked'` in the `users` table (`user_repository.dart` lines 63-64).
- **UI-side cooldown:** A 30-second UI lockout timer fires at 5 failed UI attempts (`login_page.dart` lines 131-151). This is separate from the DB-level lock and resets independently.
- Locked accounts are rejected before password comparison (`user_repository.dart` lines 32-34).
- Unlock requires admin intervention via Account Management UI (`user_repository.dart` `unlockUser()`, lines 157-178).

### Password Reset Flow

- **NOT FOUND:** A self-service password reset flow (email link, OTP). The "Forgot Password?" button displays a dialog instructing the user to contact the Store Administrator (`login_page.dart` lines 65-87).

### Roles & Authorization Enforcement

| Location | Mechanism | Roles |
|---|---|---|
| `AdminShell` | `GuardedRoute(allowedRoles: ['admin'])` (`admin_shell.dart` line 80-81) | admin |
| `CashierShell` | `GuardedRoute(allowedRoles: ['cashier'])` (`cashier_shell.dart` line 71) | cashier |
| `GuardedRoute._checkAccess()` | Checks `SessionManager().isLoggedIn` and role match; redirects to login if failed (`guarded_route.dart` lines 29-45) | Both |

> **Note:** `GuardedRoute.build()` renders `widget.child` immediately and checks access in a `WidgetsBinding.instance.addPostFrameCallback`. This means the protected widget is instantiated before the guard fires (one frame flash). (`guarded_route.dart` lines 59-63).

### Device/Service Identity
- A pre-shared secret (`SUPABASE_DEVICE_SECRET`) is sent as `x-device-secret` header to Supabase on every request (`main.dart` line 91). Server-side RLS validates this via a PostgreSQL function (`SECURITY_FEATURES.md` lines 46-48). The RLS schema itself is not in the codebase.

---

## 5. DATA PROTECTION AND SECRETS

### Encryption in Transit
- **Supabase (cloud sync):** All traffic goes over Supabase's HTTPS/TLS. INFERRED from Supabase's platform behavior, confirmed by documentation reference in `SECURITY_FEATURES.md` line 40.
- **Python face API:** Communicates over `http://127.0.0.1:5000` — **plaintext HTTP on localhost** (`ai_service_client.dart` line 7). No TLS.
- **Image downloads (food images):** Uses raw `dart:io` `HttpClient` over HTTP/HTTPS depending on the URL (`sync_service.dart` lines 241-244). NOT FOUND: certificate pinning.

### Encryption at Rest
- **Face encodings:** Encrypted with AES-256-CBC (PKCS7) before being written to SQLite. Key and IV are stored in OS secure storage (`security_utils.dart` lines 82-130; `user_repository.dart` lines 182-191).
- **SQLite database file:** **NOT FOUND** — No SQLite-level encryption (e.g., SQLCipher). The database file itself is not encrypted.
- **Supabase at-rest:** Supabase encrypts its PostgreSQL data at rest with AES-256 at the infrastructure level (`SECURITY_FEATURES.md` line 40 — INFERRED from Supabase platform guarantees, not verified in code).
- **Backup `.sql` export:** Written to the OS temp directory as a plaintext SQL file. No encryption applied (`backup_repository.dart` lines 52-58).

### Secrets Management

| Secret | Location | In `.gitignore`? | In Git history? |
|---|---|---|---|
| `SUPABASE_URL` | `.env` line 1 | **NO** — `.gitignore` does not list `.env` | **YES** — committed in commit `ae00dea` |
| `SUPABASE_ANON_KEY` (JWT) | `.env` line 2 | **NO** | **YES** — committed in commit `ae00dea` |
| `SUPABASE_DEVICE_SECRET` | `.env` line 3 | **NO** | **YES** — committed in commit `ae00dea` |
| AES key / IV | flutter_secure_storage (OS keychain) | N/A | Not committed |

> The `.env` file containing live credentials is present in the repository and was committed at least once (`git log --all -- ".env"` → `ae00dea`). Even if the file is removed from a future commit, the secrets remain in git history.

### Sensitive Data in Logs / Error Messages

- `SyncService.syncToCloud()` uses `print('Sync failed: $e')` — exception message (potentially including table names or data snippets) is printed to console (`sync_service.dart` line 150).
- `SyncService._downloadImageToLocal()` prints `'Failed to download image $url: $e'` — URL is logged (`sync_service.dart` line 258).
- `main.dart` line 24: `print('Async Error Caught: $error')` — unhandled async errors are printed.
- `ai_service_client.dart` line 28: exception messages from the face API are propagated as user-visible `Exception` strings.
- `main.dart` line 38: `details.exceptionAsString()` is displayed in the error widget UI, potentially exposing stack traces or internal state.
- **NOT FOUND:** Any log-scrubbing, structured logging framework, or log-level gating.

---

## 6. APPLICATION-LEVEL SECURITY CONTROLS

### Input Validation & Output Encoding

- Login fields: only an empty-check is performed (`login_page.dart` lines 92-97). No length limits, character allowlists, or sanitisation.
- All SQLite queries use parameterized queries via sqflite's `where`/`whereArgs` API throughout all repository files — **SQL injection is mitigated** by the ORM layer.
- **NOT FOUND:** Output encoding for exported reports (CSV, PDF, Excel). Malicious food item names or descriptions could result in formula injection in Excel exports (CSV injection).
- **NOT FOUND:** Input validation on food item names, prices, or description fields in `food_management_page.dart`.

### SQL Injection
- Mitigated via sqflite parameterized queries (`user_repository.dart`, `food_repository.dart`, `audit_repository.dart` — all use `where`/`whereArgs`). No raw string interpolation into SQL queries was found.

### XSS
- **NOT APPLICABLE** in a Flutter native app context — Flutter renders its own widget tree and does not interpret HTML. No WebView is used.

### CSRF
- **NOT APPLICABLE** — no browser-based session cookies or form submissions. Supabase requests use the `anon` key + `x-device-secret` header.

### File Upload Abuse
- Food images are uploaded to Supabase Storage (`sync_service.dart` lines 49-77). The `_contentTypeFor()` function determines MIME type by file extension only (`sync_service.dart` lines 79-93) — **no magic-byte validation** of uploaded image content. A file with a `.jpg` extension but arbitrary binary contents could be uploaded.

### SSRF
- The app downloads food images from Supabase Storage using a raw `HttpClient` with `followRedirects = true; maxRedirects = 5` (`sync_service.dart` lines 244-245). If an attacker can insert a malicious URL into `food_items.image_path` (e.g., via a compromised Supabase record), the app will fetch it. **Potential SSRF vector** on the local machine.

### Rate Limiting
- **UI-side:** 30-second lockout after 5 failed UI attempts (`login_page.dart` line 134).
- **DB-side:** Account locked after 5 failed DB-validated attempts (`user_repository.dart` line 63).
- **Python API:** **NOT FOUND** — no rate limiting on the FastAPI service (`ai_service/main.py`).

### CORS
- **NOT APPLICABLE** to the Flutter client. The Python FastAPI service runs without explicit CORS configuration — FastAPI defaults to **no CORS headers**, which restricts browser-based cross-origin calls (but the Flutter client is not a browser). Accessible to any local process on the machine.

### Security Headers
- **NOT APPLICABLE** for a native Flutter app. **NOT FOUND** for the Python FastAPI service (no `CORSMiddleware`, no security headers configured in `ai_service/main.py`).

### API Authentication on Every Endpoint

| Endpoint | Auth |
|---|---|
| Python `/extract_encoding` | **NONE** — no token, key, or auth check (`ai_service/main.py` line 9) |
| Python `/check_liveness` | **NONE** — no auth check (`ai_service/main.py` line 36) |
| Supabase REST | `anon` key + `x-device-secret` header enforced via RLS |

### Object-Level Authorization
- Admin pages (account management, activity logs, backup) are protected at the shell/route level by `GuardedRoute`. **NOT FOUND:** Row-level authorization checks inside individual repository methods (e.g., a cashier-role user cannot be fabricated to call `UserRepository.getAllUsers()` directly at the Dart level, but there is no runtime role check inside the repository itself — the enforcement is entirely UI-layer).

### Dependency Management
- **NOT FOUND:** Any evidence of `flutter pub outdated` or automated dependency scanning (e.g., Dependabot, Snyk).
- Python AI service dependencies are **unpinned** (`ai_service/requirements.txt` — no version constraints on `fastapi`, `face_recognition`, etc.). This means the installed versions at any point in time cannot be reproduced or audited.

---

## 7. NETWORK, INFRASTRUCTURE, AND DEPLOYMENT SECURITY

### Firewall / Open Ports
- **NOT FOUND:** Any explicit firewall rules or port configuration in the codebase.
- The Python FastAPI server is started with `host="0.0.0.0", port=5000` (`ai_service/main.py` line 70) — this binds to **all network interfaces**, not just localhost. Any machine on the same local network could reach the unauthenticated face API on port 5000 if the Windows Firewall does not block it.

### Reverse Proxy
- **NOT FOUND:** Nginx, Caddy, or any reverse proxy configuration.

### Server/OS Hardening
- **NOT FOUND:** Any hardening scripts, OS configuration files, or container security settings.

### Container Configuration
- **NOT FOUND:** Dockerfile or docker-compose files.

### Environment Separation
- **NOT FOUND:** Separate dev/staging/production configurations or environment-specific `.env` files. One `.env` file contains what appear to be live production Supabase credentials.

### Default Credentials
- Default `admin/admin123` and `cashier/cashier123` are seeded at database creation (`database_helper.dart` lines 252-268). No mechanism forces credential rotation at first run.

---

## 8. LOGGING, MONITORING, AND AUDITABILITY

### Events Logged

The following events are written to the `activity_logs` table via `AuditRepository.logAction()`:

| Event | Source |
|---|---|
| Failed login (each attempt, with count) | `user_repository.dart` lines 74-83 |
| Account locked (after 5 failures) | `user_repository.dart` lines 65-73 |
| Account unlocked by admin | `user_repository.dart` lines 169-177 |
| Password changed | `user_repository.dart` lines 110-116 |
| Database backup exported | `backup_repository.dart` lines 61-68 |
| Backup export failure | `backup_repository.dart` lines 72-79 |

**NOT FOUND** in audit logs:
- Successful login events
- Logout events
- Food item creation/modification/deletion
- Transaction creation, void, or refund
- User account creation or modification by admin

### Log Storage & Access
- Logs are stored in the local SQLite `activity_logs` table.
- Logs are synced to Supabase cloud on session start/end (`session_manager.dart` lines 15, 21).
- Accessible to admin users via the Activity Logs page (`activity_logs_page.dart`).
- **NOT FOUND:** Log retention policy, log rotation, or log deletion controls.
- **NOT FOUND:** Immutable/tamper-evident local log storage. A user with OS access to the SQLite file can modify or delete logs locally (cloud copy provides partial mitigation).
- Log limit returned by `AuditRepository.getLogs()` is capped at 1,000 records (`audit_repository.dart` line 73).

### Alerting / Monitoring
- **NOT FOUND:** Any real-time alerting, SIEM integration, or monitoring dashboard. Console `print()` statements are used for runtime diagnostics but not persisted or forwarded.

---

## 9. PRIVACY AND DATA HANDLING

### Personal Data Collected

| Data | Purpose | Consent Mechanism |
|---|---|---|
| Full name, username | Staff account identity | NOT FOUND — no consent screen or privacy notice in code |
| Face encoding (biometric) | Optional biometric login | NOT FOUND — no explicit informed-consent or biometric data notice in code |
| Login timestamps | Security audit trail | NOT FOUND |

### Retention & Deletion
- User accounts are **soft-deleted** (status set to `'inactive'`) by `UserRepository.disableUser()` (`user_repository.dart` lines 146-153). Hard deletion is NOT FOUND.
- Face encodings can be updated but **NOT FOUND:** a function to delete/wipe a user's face encoding.
- Audit log retention: **NOT FOUND** — no deletion or archival mechanism.

### Data Sharing with Third Parties
- Data is shared with **Supabase** (cloud backup) as described in §5. Password hashes are explicitly excluded from sync (`sync_service.dart` line 126). Face encodings stored in SQLite are not synced to Supabase (no `face_encoding` column reference in sync code — INFERRED, `sync_service.dart` lines 183-189 only restore it from local, not push it).

---

## 10. BACKUP, RECOVERY, AND CONTINUITY

### Backup Method

| Backup Type | Mechanism | Frequency | Location |
|---|---|---|---|
| Cloud sync | `SyncService.syncToCloud()` — full table upsert to Supabase | On session start/end + every 10 seconds (automatic sync) | Supabase cloud |
| Manual SQL export | `BackupRepository.exportDatabase()` — generates `.sql` file | Manual (admin-initiated) | OS temp directory, shared via OS |

### Recovery Procedure
- **Cloud restore:** `SyncService.syncFromCloud()` downloads all cloud records to local SQLite on startup (auto-sync) (`sync_service.dart` lines 155-206).
- **NOT FOUND:** A documented manual recovery procedure or restore-from-SQL workflow in code.

### Failover / Redundancy
- **NOT FOUND:** Redundant POS terminal configuration, load balancing, or failover procedures.

### Incident Response
- **NOT FOUND:** Any incident response plan, runbook, or escalation procedure in the codebase or documentation.

---

## 11. SECURITY TESTING ALREADY DONE

### Tests Found

| Test File | What It Tests |
|---|---|
| `test/security/password_hashing_test.dart` | PBKDF2 determinism, salt uniqueness, output format, known-hash vector |
| `test/security/account_lockout_test.dart` | 5-attempt lockout, locked account rejection, counter reset on success, admin unlock |
| `test/security/authorization_guard_test.dart` | `GuardedRoute` blocks wrong-role access |
| `test/security/session_expiry_test.dart` | Session expiry logic in `SessionManager` |
| `test/widget_test.dart` | UI layout, login form presence, password visibility toggle, empty-field validation, loading state |
| `test_security.dart` (root) | Minimal (439 bytes) — contents not fully read; appears to be a stub |

### Test Execution Results
- **NOT FOUND:** CI/CD pipeline, test run logs, or code coverage reports. Tests exist but no evidence of automated execution.

### Vulnerability Scans / Pen Tests
- **NOT FOUND:** Any static analysis security scan results (e.g., `dart analyze` security rules, Semgrep), dependency vulnerability scan (e.g., `pub audit`), or penetration test report.

---

## 12. FRAMEWORK APPLICABILITY

### Applicable Frameworks

| Framework | Applicable? | Reason |
|---|---|---|
| **OWASP Top 10** | ✅ Yes | Web/application risks apply to the Flutter+Supabase+Python components |
| **OWASP ASVS** (Application Security Verification Standard) | ✅ Yes | Desktop application with auth, session, and data protection requirements |
| **OWASP API Security Top 10** | ✅ Yes | Python FastAPI service is an exposed API |
| **OWASP MASVS** (Mobile Application Security) | ✅ Yes | Android/iOS targets are supported |
| **OWASP IoT** / **ETSI EN 303 645** / **NIST IoT** | ❌ No | No IoT devices, sensors, or embedded firmware |
| **NIST CSF** | ✅ Partial | Relevant for overall risk management posture |
| **CIS Controls / Benchmarks** | ✅ Partial | Relevant for OS hardening on Windows POS terminal |

---

### OWASP Top 10 (2021)

| ID | Risk | Status | Evidence |
|---|---|---|---|
| A01 Broken Access Control | ⚠️ Partial | `GuardedRoute` enforces role-based shell access. However, the guard renders child one frame before checking (`guarded_route.dart` L59-63). No repository-level authorization checks. |
| A02 Cryptographic Failures | ⚠️ Partial | PBKDF2 for passwords ✅. Face encodings AES-CBC ✅. SQLite DB not encrypted ❌. Secrets committed to git ❌. Backup SQL unencrypted ❌. |
| A03 Injection | ✅ Satisfied | Parameterized queries used throughout all repositories. |
| A04 Insecure Design | ⚠️ Partial | Default credentials seeded and not forced to change. No password complexity rules. No self-service password reset. |
| A05 Security Misconfiguration | ❌ Failing | Python API binds `0.0.0.0:5000` with no auth. `.env` committed to git. No environment separation. |
| A06 Vulnerable & Outdated Components | ⚠️ Unknown | Python deps unpinned. No dependency audit evidence found. |
| A07 Identification & Auth Failures | ⚠️ Partial | Account lockout ✅. Session timeout ✅. No password complexity rules ❌. Default credentials ❌. No MFA ❌. |
| A08 Software & Data Integrity Failures | ⚠️ Partial | No CI/CD pipeline found; no build integrity controls. |
| A09 Security Logging & Monitoring Failures | ⚠️ Partial | Failed logins logged ✅. Successful logins NOT logged ❌. No alerting ❌. |
| A10 SSRF | ⚠️ Risk exists | `HttpClient` fetches arbitrary URLs from DB-stored `image_path` with redirect following enabled (`sync_service.dart` L244-245). |

---

### OWASP API Security Top 10 (2023) — Python FastAPI Service

| ID | Risk | Status | Evidence |
|---|---|---|---|
| API1 Broken Object Level Authorization | ❌ Failing | `/extract_encoding` and `/check_liveness` have no authentication whatsoever. |
| API2 Broken Authentication | ❌ Failing | No auth on any endpoint. |
| API3 Broken Object Property Level Auth | N/A | Single-object responses only. |
| API4 Unrestricted Resource Consumption | ❌ Failing | No rate limiting on image upload endpoints. |
| API5 Broken Function Level Auth | ❌ Failing | All endpoints publicly accessible on the network. |
| API7 SSRF | ⚠️ Risk exists | API accepts file uploads; no SSRF risk from the API itself, but the caller side has SSRF risk. |
| API8 Security Misconfiguration | ❌ Failing | Binds `0.0.0.0`; no HTTPS; no auth. |

---

### OWASP MASVS (Mobile — Android/iOS targets)

| Control | Status | Evidence |
|---|---|---|
| MASVS-STORAGE-1: Sensitive data not stored in plain text | ⚠️ Partial | Face encodings encrypted ✅. SQLite DB unencrypted ❌. |
| MASVS-STORAGE-2: No sensitive data in logs | ❌ Failing | Errors and URLs printed to console. |
| MASVS-CRYPTO-1: Strong cryptography | ✅ Satisfied | PBKDF2-HMAC-SHA256 10k iterations; AES-256-CBC. |
| MASVS-AUTH-1: Secure authentication | ⚠️ Partial | Local auth with lockout ✅. Default credentials ❌. |
| MASVS-NETWORK-1: TLS for all network traffic | ⚠️ Partial | Supabase uses HTTPS ✅. Python API uses plain HTTP ❌. |
| MASVS-CODE-3: Free of obvious vulnerabilities | ⚠️ Partial | No injection vulnerabilities found. SSRF and file-upload risks exist. |

---

## 13. GAP SUMMARY

The table below consolidates every **NOT FOUND** and **INFERRED** item from this report that requires verification or remediation before final IAS documentation.

| # | Category | Item | Status | Section |
|---|---|---|---|---|
| 1 | Secrets | `.env` committed to git (Supabase URL, anon key, device secret) | **NOT FOUND in gitignore; confirmed in git history** | §3, §5 |
| 2 | Auth | No password complexity or minimum-length rule | NOT FOUND | §4 |
| 3 | Auth | Default credentials `admin/admin123`, `cashier/cashier123` not force-changed | NOT FOUND | §4, §7 |
| 4 | Auth | No self-service password reset (email/OTP) | NOT FOUND | §4 |
| 5 | Auth | No MFA second factor | NOT FOUND | §4 |
| 6 | Auth | `GuardedRoute` renders protected widget one frame before guard fires | INFERRED risk | §4 |
| 7 | Logging | Successful login events not logged | NOT FOUND | §8 |
| 8 | Logging | Logout events not logged | NOT FOUND | §8 |
| 9 | Logging | Food/transaction/user admin actions not logged | NOT FOUND | §8 |
| 10 | Logging | No log retention or deletion policy | NOT FOUND | §8 |
| 11 | Logging | No real-time alerting or monitoring | NOT FOUND | §8 |
| 12 | Encryption | SQLite database file not encrypted at rest | NOT FOUND | §5 |
| 13 | Encryption | Backup `.sql` file written as plaintext to temp dir | NOT FOUND | §5, §10 |
| 14 | API Security | Python FastAPI has no authentication on any endpoint | NOT FOUND | §2, §6, §12 |
| 15 | API Security | Python FastAPI binds `0.0.0.0:5000` (accessible network-wide) | Confirmed in code | §2, §7 |
| 16 | API Security | No rate limiting on Python API | NOT FOUND | §6 |
| 17 | Network | Python API uses plain HTTP (no TLS) | NOT FOUND | §5 |
| 18 | SSRF | `image_path` URLs fetched with `followRedirects = true` from DB-stored value | Code-confirmed risk | §6 |
| 19 | File Upload | Image upload validated by extension only (no magic-byte check) | NOT FOUND | §6 |
| 20 | Dependency | Python AI service dependencies unpinned | NOT FOUND | §6 |
| 21 | Dependency | No `flutter pub audit` or automated dependency scan evidence | NOT FOUND | §6, §11 |
| 22 | Privacy | No consent mechanism for biometric data collection | NOT FOUND | §9 |
| 23 | Privacy | No hard-delete for user records or face encodings | NOT FOUND | §9 |
| 24 | Privacy | No privacy policy or data retention schedule | NOT FOUND | §9 |
| 25 | Deployment | No environment separation (dev vs. production) | NOT FOUND | §7 |
| 26 | Deployment | No containerization or deployment scripts for Python service | NOT FOUND | §7 |
| 27 | Recovery | No documented manual recovery or restore-from-SQL procedure | NOT FOUND | §10 |
| 28 | Recovery | No incident response plan | NOT FOUND | §10 |
| 29 | Testing | No CI/CD pipeline or automated test execution evidence | NOT FOUND | §11 |
| 30 | Testing | No vulnerability scan or penetration test results | NOT FOUND | §11 |
| 31 | Supabase RLS | RLS schema not in codebase — cannot verify server-side policy | INFERRED from documentation | §4, §6 |
| 32 | OS Security | SQLite file permissions not explicitly hardened | INFERRED | §3, §7 |
