# N.Y Kitchen POS - Security Features Documentation

This document outlines the security features implemented in the N.Y Kitchen POS system. The current authentication boundary is **local-only SQLite**: Supabase Auth is not used, so login remains available without an internet connection.

## 1. Authentication & Access Control
- **Role-Based Access Control (RBAC):** The system enforces strict access control between different roles (`admin` and `cashier`).
  - Cashiers are restricted from accessing administrative features, such as account management, sensitive reports, and system settings.
  - Admins have full access to manage accounts, view comprehensive reports, and manage food inventory.
- **Local Shell Routing:** After local login, the role selects the Admin or Cashier shell. Declarative route guards and an Unauthorized page are not yet implemented.
- **Authentication Boundary:** `UserRepository` reads credentials from the local SQLite `users` table. Supabase is reserved for future background cloud backup/sync and must not become the authentication provider.

## 2. Secure Credential Management
- **Password Hashing:** Passwords are not stored in plain text. `SecurityUtils` uses the Dart `crypto` package and SHA-256 with the project-wide salt `ny_kitchen_secure_salt_2026` before storing values in the local SQLite database. This is the current implementation and requires a stronger password-KDF review before production deployment.
- **Secure Password Updates:** Any operation that alters a password (such as an Admin resetting a password, or a user changing their own password via Account Settings) automatically processes the input through `SecurityUtils.hashPassword()` before persistence.

## 3. Session Management
- **In-Memory Session State:** The system utilizes a `SessionManager` singleton to maintain the state of the currently logged-in user. This ensures that the application "knows" exactly who is operating the POS at all times.
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

## 7. Phase 5 Cloud-Sync Boundary
- Supabase integration is **not implemented** in the current codebase.
- The planned scope is background backup/synchronization of approved SQLite data only.
- SQLite remains the authoritative local source of truth and must continue to support offline operation.
- Supabase Auth is explicitly out of scope; local SQLite authentication remains authoritative.
- RLS policies, retry behavior, conflict resolution, and service-role-key handling must be approved before implementation.
