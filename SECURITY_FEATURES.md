# N.Y Kitchen POS - Security Features Documentation

This document outlines the security features implemented in the N.Y Kitchen POS system. The current authentication boundary is **local-only SQLite**: Supabase Auth is not used, so login remains available without an internet connection.

## 1. Authentication & Access Control
- **Role-Based Access Control (RBAC):** The system enforces strict access control between different roles (`admin` and `cashier`).
  - Cashiers are restricted from accessing administrative features, such as account management, sensitive reports, and system settings.
  - Admins have full access to manage accounts, view comprehensive reports, and manage food inventory.
- **Local Shell Routing:** After local login, the role selects the Admin or Cashier shell. **Declarative Route Guards (`GuardedRoute`)** now wrap the shells, ensuring unauthorized users or expired sessions are instantly redirected to the login screen.
- **Authentication Boundary:** `UserRepository` reads credentials from the local SQLite `users` table. Supabase is reserved for future background cloud backup/sync and must not become the authentication provider.

## 2. Secure Credential Management
- **Password Hashing:** Passwords are not stored in plain text. `SecurityUtils` uses **PBKDF2-HMAC-SHA256 (10,000 iterations)** with a **randomized, unique per-user salt** via the `pointycastle` package. The resulting hash and salt are securely persisted in the SQLite database.
- **Secure Password Updates:** Any operation that alters a password (such as an Admin resetting a password, or a user changing their own password via Account Settings) automatically generates a new random salt and processes the input through `SecurityUtils.hashPassword()` before persistence.

## 3. Session Management
- **In-Memory Session State:** The system utilizes a `SessionManager` singleton to maintain the state of the currently logged-in user. This ensures that the application "knows" exactly who is operating the POS at all times.
- **Session Expiration:** A global interaction listener tracks inactivity. The session will automatically expire and invalidate after **30 minutes of inactivity**. If an expired session tries to navigate or perform an action, the route guard will catch them and log them out.
- **Stateless/Offline Reliability:** Since the POS operates primarily offline, session tokens aren't transmitted over a network, eliminating risks associated with network interception (e.g., Man-In-The-Middle attacks) during regular operations.
- **Explicit Logout:** Users can securely terminate their session, clearing all sensitive data from active memory and requiring re-authentication to regain access.

## 4. Account Lockout Mechanism (Anti-Brute Force)
- **Failed Login Tracking:** The database records every consecutive failed login attempt (`failed_login_count`).
- **Automatic Account Lockout:** If a user submits an incorrect password **5 consecutive times**, their account is automatically disabled (`status = 'locked'`).
- **Administrative Remediation:** The Account Management UI exposes account status controls; lockout unlock policy and audit logging require additional security review.
- **Reset Behavior:** A successful login resets `failed_login_count` to zero. Locked or inactive accounts are rejected before password comparison.

## 5. UI/UX Security Enhancements
- **Safe State Handling:** Improved null-safety and UI state handling ensures the application does not crash when unexpected data states occur, reducing the risk of denial-of-service through application instability.
- **Obfuscated Password Entry:** All password entry fields (login, create account, reset password, change password) use masked input fields (`obscureText`) to prevent shoulder surfing.

## 6. Database Integrity
- **Database Migrations:** Structural changes to security elements (like adding new columns for lockout tracking or hashing existing passwords) are handled through controlled, versioned SQLite migrations.
- **Isolated Local Storage:** All security credentials and transaction data remain stored locally on the device, minimizing external exposure. Future cloud synchronizations (e.g., Supabase) will treat the local database as the primary source of truth for offline-first reliability.

## 7. Cloud Backup Security (Supabase Device-Level Auth)
- **Immutable Disaster Recovery Vault:** Because this is a POS system where all transactions happen locally on the machine, it faces a massive physical security risk (device theft, breakage, or malicious deletion of the local database to hide theft). Supabase acts as an immutable disaster recovery vault to mitigate this:
  - **Data Persistence:** If the POS hardware fails, a new device can sync from the cloud and be back in business instantly.
  - **Tamper-Proof Logging:** If an employee tries to delete voided transactions or activity logs from the local SQLite database to cover their tracks, the Supabase cloud already has a copy.
  - **Enterprise Encryption:** Supabase automatically encrypts all data "in transit" (using SSL/HTTPS when sending data over the internet) and "at rest" (using AES-256 encryption on their servers).
- **The Authentication Problem:** The POS system uses local SQLite for offline-first authentication, meaning Supabase does not have standard User JWTs to identify who is making the sync requests (it relies on the `anon` key).
- **The Solution:** "Device-Level Authentication" using custom headers.
- **Implementation:**
  - The Flutter app injects a hidden `x-device-secret` header into the global `SupabaseClient` initialization.
  - The secret is loaded securely from the local `.env` file (`SUPABASE_DEVICE_SECRET`).
  - Supabase **Row Level Security (RLS)** is enabled on all tables.
  - A custom PostgreSQL function `check_device_secret()` intercepts every incoming request and validates the `x-device-secret` header against the pre-shared token.
  - If the header is missing or incorrect, Supabase completely drops the request, making the `anon` key useless to external attackers.
- **Offline Operation:** SQLite remains the authoritative local source of truth, ensuring the app works perfectly offline. Supabase operates silently in the background solely as a backup vault.
