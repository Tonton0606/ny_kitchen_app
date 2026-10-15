# NY Kitchen Secure Sales Management System
## Applying ISO/IEC 25010 Quality Standards and OWASP Security Practices in a Cross-Platform Order Processing Application

**A Concept Paper**

*Submitted in Partial Fulfillment of the Requirements for the Capstone/Thesis Project*

---

---

## I. Background of the Study

NY Kitchen is a small food stall that currently records all dine-in and takeout orders manually in a physical notebook. This conventional approach, while familiar, introduces a cascade of operational and security vulnerabilities that directly affect the reliability of business data. Manual order recording is inherently susceptible to human error, including miscounted items, illegible handwriting, and misplaced pages. More critically, paper-based systems provide no mechanism for authentication, access control, or auditability—any individual with physical access to the notebook can read, modify, or destroy the business's transactional history without detection.

As small food businesses scale their daily operations, the inadequacy of manual record-keeping becomes increasingly apparent. The inability to consolidate sales data in real time, to verify which staff member processed a particular transaction, or to detect unauthorized modifications to records represents a significant gap in operational security and business accountability.

The shift toward digital, software-based management systems is not merely a convenience improvement—it is an information assurance imperative. When sensitive business data, including revenue figures, pricing structures, and staff credentials, resides in an unprotected notebook, it is exposed to risks that a properly engineered software system can systematically eliminate.

This study proposes the design, development, and evaluation of the **N.Y Kitchen Secure Order and Sales Management System**: a cross-platform, offline-first Point-of-Sale (POS) and sales management application built using Flutter and SQLite, with optional cloud backup via Supabase. The system is designed to operate reliably without internet connectivity while implementing robust security controls grounded in the CIA Triad, OWASP Secure Coding Practices, and the ISO/IEC 25010 Software Quality Model.

---

## II. Statement of the Problem

The study seeks to address the following problems:

1. **Operational Inefficiency:** Manual order recording causes delays, miscounted items, and miscommunication errors between the counter and the kitchen, directly impacting customer service quality and revenue accuracy.

2. **Absence of Data Security:** Paper-based records can be lost, physically damaged, altered, or accessed by unauthorized individuals. There is no audit trail to trace who created, modified, or voided a transaction, nor any mechanism to detect tampering.

3. **Lack of Authentication and Access Control:** There is no authentication mechanism to verify the identity of the person handling the business's records, and no access control to restrict what different staff roles may do. Any individual can review or modify all records without restriction.

4. **Inadequate Sales Monitoring:** Business owners have no reliable means of consolidating daily, weekly, or monthly sales data for performance monitoring and informed decision-making.

5. **No Backup or Recovery Mechanism:** Paper records offer no recovery path in the event of physical loss (fire, water damage, theft). A single incident can permanently erase months of business history.

6. **Inability to Enforce Accountability:** Without digital timestamps and user attribution, there is no way to determine which staff member processed a specific order, handled a refund, or voided a transaction.

---

## III. Objectives of the Study

### General Objective

To design, develop, and evaluate a Secure Cross-Platform Order and Sales Management System for NY Kitchen using an offline-first architecture, applying ISO/IEC 25010 software quality standards and OWASP security practices.

### Specific Objectives

1. Develop a fully functional digital order management system supporting dine-in and takeout transactions through a three-panel POS interface optimized for desktop operation.

2. Implement Role-Based Access Control (RBAC) with distinct Admin and Cashier roles, enforcing strict module-level and route-level access restrictions.

3. Enable complete offline transaction processing via a local SQLite database (`sqflite`/`sqflite_common_ffi`), with optional background synchronization to Supabase when internet connectivity is available.

4. Automate order total computation, cash payment recording, change calculation, and digital receipt generation using the `pdf` and `printing` Flutter packages.

5. Implement secure authentication using PBKDF2-HMAC-SHA256 password hashing with per-user random salts, session management with inactivity expiration, account lockout after five consecutive failed login attempts, and comprehensive audit logging.

6. Enable administrators to generate sales reports (daily, weekly, monthly, annual) and security event summaries, with export capabilities to PDF and CSV formats.

7. Evaluate the system's software quality using ISO/IEC 25010 characteristics (Functional Suitability, Performance Efficiency, Usability, Reliability, Security, Maintainability, Portability) and its security posture using OWASP Secure Coding Practices.

8. Implement a database backup and restore mechanism to protect against data loss, storing rolling backups in the application documents directory with optional cloud vault storage via Supabase.

---

## IV. Significance of the Study

**For NY Kitchen (Business Owner):**
The system eliminates manual order errors and communication delays, providing real-time sales data and analytics. Authentication and access control ensure that only authorized staff interact with business records, while audit logs create a verifiable chain of accountability for every transaction, user management action, and system event.

**For Cashiers:**
The digital POS interface accelerates order processing through a categorized menu, search functionality, and automated total computation—reducing cognitive load and arithmetic errors during peak operating hours.

**For Customers:**
Faster, more accurate order processing results in improved service quality. Digital receipt generation ensures customers receive accurate itemized proof of payment.

**For Researchers and Developers:**
This project provides a practical case study in applying information assurance frameworks (CIA Triad, OWASP) and software quality standards (ISO/IEC 25010) to real-world small business software development using cross-platform technologies (Flutter + SQLite + Supabase).

**For Future Studies:**
The system architecture, security design decisions, and evaluation methodology may serve as a reference model for future research on secure POS systems, offline-first applications, and security-focused software engineering for micro-enterprises and SMEs.

---

## V. Scope and Limitations

### Scope

The N.Y Kitchen Secure Sales Management System covers the following:

- **Transaction Types:** Dine-in and takeout orders at a single branch location.
- **User Roles:** Two roles — Administrator and Cashier — with strictly enforced module-level and route-level access control.
- **Offline Operation:** All core functions (order processing, receipt generation, activity logging, authentication) operate without internet access using SQLite as the local database.
- **Cloud Backup (Optional):** Background synchronization to Supabase acts as an immutable disaster recovery vault. The cloud layer uses Row-Level Security (RLS) and a device-level pre-shared secret (`x-device-secret` header) to authenticate sync requests.
- **Payment Support:** Cash payment processing with automated change calculation. The system is architected to support additional payment methods (GCash, Maya, card) in future versions without workflow redesign.
- **Receipt Printing:** Digital receipt generation compatible with 80mm/58mm thermal printers and standard OS-configured printers on both Windows and Android.
- **Reports:** Sales summaries (All, Today, Weekly, Monthly, Annual) and security event logs accessible to Administrators.
- **Platform Support:** Android phones, Android tablets, and Windows desktop from a single Flutter codebase.
- **Database Management:** Manual backup (export to local storage or cloud) and restore via the Admin Backup & Restore module, with rolling 7-day automatic backup retention.

### Limitations

The system intentionally excludes the following in its initial version:

- Inventory management, supplier management, and stock tracking
- Multiple branch support
- Customer accounts, loyalty programs, or CRM features
- Digital payment gateway integration (GCash, Maya, card transactions are UI-staged but not wired to payment processors)
- Advanced business analytics beyond the defined reporting periods
- Employee payroll, time-tracking, or HR management
- Online ordering or delivery tracking

**Connectivity Dependency:** Initial user provisioning (creating new accounts) requires internet access for the optional Supabase sync. All core transaction processing, authentication (for pre-provisioned users), and activity logging function completely offline. Cloud-based admin features (remote audit review, cloud backup) require connectivity.

---

## VI. Review of Related Literature and Studies

### 6.1 ISO/IEC 25010 Software Quality Model

ISO/IEC 25010 defines a hierarchical model of software product quality composed of eight primary characteristics: Functional Suitability, Performance Efficiency, Compatibility, Interaction Capability (Usability), Reliability, Security, Maintainability, and Flexibility (Portability). This model provides a structured evaluation framework applicable across domains.

For the N.Y Kitchen system, the most critical characteristics are **Security** (authentication, authorization, data integrity, and auditability), **Functional Suitability** (completeness of POS workflows), and **Reliability** (offline operation without data loss). The system's evaluation instruments will be designed to measure respondent perceptions across all eight characteristics using Likert-scale questionnaires validated through expert review.

### 6.2 OWASP Secure Coding Practices

The Open Web Application Security Project (OWASP) provides guidelines for mitigating the most prevalent application security vulnerabilities. While originally targeting web applications, OWASP principles are broadly applicable to desktop and mobile software. The relevant categories for this system include:

- **Broken Access Control (OWASP A01):** Mitigated through declarative route guards (`GuardedRoute`), role-based shells, and server-side RLS policies in Supabase.
- **Cryptographic Failures (OWASP A02):** Addressed through PBKDF2-HMAC-SHA256 password hashing with per-user salts, HTTPS/SSL for all Supabase communications, and AES-256 encryption at rest on Supabase servers.
- **Injection (OWASP A03):** Prevented through strict use of parameterized SQLite queries—no raw string concatenation is used for database interactions.
- **Identification and Authentication Failures (OWASP A07):** Addressed through password hashing, session management with inactivity timeout, account lockout, and masked input fields.
- **Security Logging and Monitoring Failures (OWASP A09):** Addressed through the immutable Activity Logs module that records authentication events, transaction actions, user management changes, and system configuration modifications.

### 6.3 CIA Triad in Information Systems

The CIA Triad—Confidentiality, Integrity, and Availability—forms the foundational framework for information security design in this system:

- **Confidentiality:** RBAC ensures cashiers cannot access administrative modules, reports, or user management. Passwords are never stored in plaintext. Sessions are isolated per user.
- **Integrity:** Parameterized queries prevent injection-based data corruption. Completed transactions are immutable. Activity logs cannot be modified through the application interface. Voiding or refunding requires administrator authorization and creates a permanent audit record.
- **Availability:** Offline-first SQLite architecture ensures the POS functions without internet. Backup and restore mechanisms protect against data loss. Error handling prevents application crashes from interrupting business operations.

### 6.4 Offline-First Application Architecture

Offline-first design prioritizes local data storage and processing, synchronizing with remote systems opportunistically when connectivity is available. This pattern is particularly appropriate for food service environments where internet reliability cannot be guaranteed. The implementation uses SQLite as the authoritative local data store, with Supabase serving as a background synchronization target using an upsert conflict resolution strategy (local SQLite always wins).

### 6.5 Cross-Platform Development with Flutter

Flutter is Google's open-source UI toolkit for building natively compiled applications for mobile, desktop, and web from a single codebase using the Dart programming language. The NY Kitchen system targets Android (phone and tablet) and Windows Desktop. Flutter's widget-based composition model, Material 3 design system, and platform-adaptive APIs make it well-suited for cross-platform POS applications requiring consistent behavior across form factors.

---

## VII. System Architecture and Design

### 7.1 Architecture Overview

The system follows a **Feature-First Clean Architecture** pattern with three primary layers:

```
Presentation Layer   →  Flutter Widgets, Pages, Shells
Service Layer        →  Business Logic, Validation, Audit Trigger
Repository Layer     →  SQLite CRUD, Supabase Sync
Database Layer       →  SQLite (sqflite + sqflite_common_ffi)
Cloud Layer          →  Supabase (Background Backup Vault)
```

Each feature domain (Auth, Admin, Cashier, Menu, Transactions, Reports, Backup) maintains its own folder under `lib/features/`, containing presentation pages, widgets, and feature-specific logic. Shared components (security utilities, session manager, database helper, audit repository) reside under `lib/core/`.

### 7.2 Database Schema (SQLite)

The local SQLite database consists of nine tables:

| Table | Purpose |
|---|---|
| `users` | User credentials, roles, status, lockout tracking |
| `food_categories` | Menu category definitions |
| `food_items` | Menu items with pricing, availability, image paths |
| `transactions` | Sales transactions with totals, payment, change |
| `transaction_items` | Line items within each transaction |
| `activity_logs` | Immutable audit trail for all system events |
| `login_attempts` | Login attempt history for security monitoring |
| `app_settings` | Business info, receipt settings, printer preferences |
| `backup_records` | History of database backup operations |

Schema migrations are version-controlled within `DatabaseHelper` using SQLite's `onUpgrade` lifecycle, enabling safe structural changes without data loss.

### 7.3 User Roles and Module Access

#### Administrator
| Module | Access Level |
|---|---|
| Dashboard | Full — live revenue, analytics, security summary |
| Transactions | Full — view, search, filter, void, refund |
| Menu Management | Full CRUD + archive |
| User Management | Full CRUD + lock/unlock + password reset |
| Activity Logs | Read-only |
| Reports | View, print, export PDF/CSV |
| Account Settings | Profile, password, business info, receipt settings |
| Backup & Restore | Full |

#### Cashier
| Module | Access Level |
|---|---|
| Home / New Order (POS) | Full — browse menu, add to cart, checkout |
| Transaction History | Own transactions only — view, reprint |
| Account Settings | Own profile and password only |
| Dashboard, Reports, User Mgmt, Logs | ❌ No access — route guards enforce |

### 7.4 Checkout and Transaction Workflow

```
Customer Order
     ↓
Food Selection (Three-Panel POS)
     ↓
Order Review (Confirmation Dialog)
     ↓
Payment Entry (Cash Received, Change Calculated)
     ↓
Transaction Saved to SQLite
     ↓
Receipt Generated (pdf package)
     ↓
Receipt Printed / Displayed
     ↓
Activity Log Generated (audit trail)
     ↓
[If Online] Background Sync to Supabase Vault
```

### 7.5 Technology Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| UI System | Material 3 (`useMaterial3: true`) |
| Local Database | SQLite (`sqflite` + `sqflite_common_ffi`) |
| State Management | Provider |
| Navigation | Custom Role-Based Shells + Declarative Guards |
| Receipt Generation | `pdf` + `printing` packages |
| Charts | `fl_chart` |
| Password Hashing | `crypto` (SHA-256) + `pointycastle` (PBKDF2) |
| Secure Storage | `flutter_secure_storage` |
| Cloud Backup | Supabase (`supabase_flutter`) |
| Environment Config | `flutter_dotenv` |
| Window Management | `window_manager` (Desktop) |
| File Export | `share_plus`, `csv`, `syncfusion_flutter_xlsio` |
| Image Handling | `image_picker` |
| HTTP | `http` |

---

## VIII. Security Framework

### 8.1 Authentication and Credential Security

**Password Hashing:** All passwords are hashed using PBKDF2-HMAC-SHA256 with 10,000 iterations and a cryptographically random per-user salt via the `pointycastle` package. The hash and salt are stored separately in the SQLite `users` table. Plaintext passwords are never stored or logged.

**Secure Password Updates:** Any password change operation (admin reset, self-service change) generates a new random salt and re-hashes the input before persistence.

**Masked Input:** All password fields use `obscureText: true` to prevent shoulder surfing during login and account management operations.

**Generic Error Messages:** Authentication failure responses never reveal whether the username exists or whether the password was incorrect. The message is always: *"Invalid username or password."*

### 8.2 Session Management

**In-Memory Session State:** A `SessionManager` singleton maintains the authenticated user's identity and role across the application. Session data is never persisted to disk between application launches.

**Inactivity Timeout:** A global interaction listener monitors user activity. Sessions automatically expire after **30 minutes of inactivity**, triggering immediate logout and redirection to the login screen.

**Explicit Logout:** Users may terminate their session at any time via the logout confirmation dialog. Logout clears all session state and generates an Activity Log entry.

**Stateless Offline Operation:** Since the POS operates offline, session tokens are not transmitted over a network, eliminating man-in-the-middle interception risks during normal POS operation.

### 8.3 Account Lockout (Anti-Brute Force)

- **Tracking:** Every failed login attempt increments the `failed_login_count` column in the `users` table.
- **Lockout Threshold:** Five consecutive failed attempts automatically set the account `status = 'locked'`.
- **Locked accounts** are rejected before password comparison, preventing timing-based enumeration.
- **Reset:** A successful login resets `failed_login_count` to zero.
- **Administrative Remediation:** Only an Administrator can unlock a locked account via the Account Management module.
- **Audit Trail:** Both the lockout event and the unlock action generate Activity Log entries.

### 8.4 Role-Based Access Control (RBAC)

- **Declarative Route Guards:** `GuardedRoute` wrappers protect all Admin and Cashier shells, verifying session validity and role before rendering any protected page.
- **Session Expiration Enforcement:** If a session has expired, the route guard catches the access attempt and redirects to the login screen, regardless of the target route.
- **Module-Level Restrictions:** Cashier users cannot navigate to any Admin module; the navigation items are not rendered and the routes are guarded at the router level.
- **Unauthorized Access Logging:** Any access attempt to a protected route by an unauthorized or unauthenticated user generates an Activity Log entry with category `Security Events`.

### 8.5 SQL Injection Prevention

All database interactions use **parameterized queries** exclusively. No user-supplied input is ever concatenated into a SQL string. The `sqflite` API's `where` and `whereArgs` parameters enforce this practice.

Example:
```dart
// CORRECT — Parameterized
await db.query('users', where: 'username = ?', whereArgs: [username]);

// INCORRECT — Never used in this system
await db.rawQuery("SELECT * FROM users WHERE username = '$username'");
```

### 8.6 Activity Logging (Audit Trail)

The Activity Logs module records every significant system event with the following attributes:

| Field | Description |
|---|---|
| `timestamp` | ISO 8601 datetime of the event |
| `user_id` / `username` | Identity of the actor |
| `role` | Actor's role at the time of the event |
| `module` | Feature area (Auth, Transactions, Menu, Users, Settings, Backup, Security) |
| `action` | Specific action performed |
| `status` | Success or Failed |
| `description` | Human-readable summary |
| `device_info` | Platform and device identifier |
| `ip_address` | Network address (where available) |

**Immutability:** Activity logs cannot be modified or deleted through any application interface. The Admin module provides read-only access with search and export capabilities only.

**Logged Events Include:**
- Login, logout, failed login, account lockout, account unlock
- Transaction creation, voiding, refunding, receipt reprinting
- Menu item creation, editing, archiving
- User account creation, editing, password reset, activation, deactivation
- Application settings changes
- Database backup creation, restore operations, backup deletion
- Unauthorized access attempts

### 8.7 Cloud Backup Security (Supabase Device-Level Authentication)

Since the system operates primarily offline, Supabase does not use standard user JWTs for authentication. Instead, a **device-level pre-shared secret** approach is implemented:

- The Flutter application injects a custom `x-device-secret` HTTP header into the global `SupabaseClient` initialization.
- The secret is loaded from a `.env` file (`SUPABASE_DEVICE_SECRET`) that is excluded from version control via `.gitignore`.
- **Row-Level Security (RLS)** is enabled on all Supabase tables.
- A custom PostgreSQL function `check_device_secret()` intercepts every incoming request and validates the header against the registered secret.
- Requests with missing or incorrect secrets are rejected at the database policy level, rendering the public `anon` key useless to unauthorized clients.
- All data in transit is encrypted via SSL/HTTPS. All data at rest on Supabase servers is encrypted with AES-256.

**Immutable Backup Guarantee:** Supabase serves as a tamper-proof secondary record. Even if a malicious actor deletes transaction records or activity logs from the local SQLite database, the Supabase cloud vault retains the original copies.

### 8.8 Transaction Integrity Controls

- **Completed transactions are immutable.** They cannot be permanently deleted through any application interface.
- **Voiding or refunding** requires Administrator authorization and a stated reason, and automatically generates an Activity Log entry with the actor's identity, timestamp, and reason.
- **Unique receipt numbers** are generated for every transaction to prevent duplication.
- **Timestamps** are applied automatically by the system at the moment of transaction completion — not editable by the user.
- **Cashier attribution** is embedded in every transaction record, creating a direct link between a sale and the staff member who processed it.

### 8.9 Input Validation

All user input is validated at both the UI layer and the service/repository layer before database interaction:

| Input Category | Validation Rules |
|---|---|
| Username | Required, unique, character constraints, length limits |
| Password | Required, minimum 8 characters, hashed before storage |
| Food Name | Required, non-empty |
| Food Price | Required, numeric, greater than zero |
| Category | Required, must reference a valid existing category |
| Transaction | Must contain ≥1 item, food must be available, payment method required |
| Search Inputs | Sanitized before query construction |

Validation errors are displayed with user-friendly messages. Technical database errors are never exposed to end users.

### 8.10 Secure Configuration

- **Debug mode** is disabled in production builds (`--dart-define` / `kReleaseMode`).
- Sensitive environment variables (Supabase URL, anon key, device secret) are stored in `.env`, excluded from version control.
- The `service_role` key is **never** placed in the Flutter client application.
- Administrative features are inaccessible to Cashier-role users at both the UI rendering and route guard levels.

---

## IX. Missing Information Identified and Additions

The following gaps in the original concept paper outline have been identified and are addressed in this document:

### 9.1 Added: Specific Technology Details
The original outline referenced "SQLite (sqflite)" and "Supabase" generically. This paper specifies the exact package stack (`sqflite_common_ffi` for Windows, `pointycastle` for PBKDF2, `flutter_secure_storage` for session tokens, `window_manager` for desktop window control, etc.) and architectural decisions (ADR-001 through ADR-016).

### 9.2 Added: Cloud Security Architecture
The original outline did not address how Supabase authentication would work without standard user JWTs in an offline-first context. This paper documents the device-level pre-shared secret approach (`x-device-secret` header + PostgreSQL RLS policy via `check_device_secret()`) that secures the cloud backup channel.

### 9.3 Added: Database Schema Details
A complete nine-table SQLite schema is specified, including the `login_attempts` table for security monitoring and `backup_records` for backup history — neither of which appeared in the original outline.

### 9.4 Added: Receipt Printing Architecture
The original states receipts are generated but does not specify how. This paper documents the `pdf`/`printing` package approach, on-the-fly regeneration for reprints (no PDF file storage), and 80mm/58mm thermal printer compatibility.

### 9.5 Added: Detailed RBAC Table
Module-by-module access rights for both Admin and Cashier roles are documented in tabular form for clarity in evaluation.

### 9.6 Added: Error Handling Policy
Specific error handling policies (generic authentication error messages, no technical error exposure, backup integrity verification before restoration) are documented as security-critical behaviors.

### 9.7 Added: Backup Security Policy
The backup `.db` file retention policy (7 rolling automatic backups, manual backups retained until explicitly deleted), storage location, and export mechanism (`share_plus` on Android, native file dialogs on Windows) are specified.

### 9.8 Added: Data Validation Matrix
A complete input validation matrix is provided, covering all user-facing data entry points and their respective constraints.

---

## X. Additional Security Controls Recommended

The following security enhancements are recommended for implementation during Phase 10 (Security Hardening) based on analysis of the current system against OWASP and ISO/IEC 25010:

### 10.1 Backup File Encryption
**Gap:** Current backup strategy exports the raw SQLite `.db` file without encryption (relies on OS-level protection per ADR-016).
**Recommendation:** Encrypt backup files using AES-256 before export. A password-derived key (PBKDF2 from Admin password) or a randomly generated key stored in `flutter_secure_storage` should be used. This ensures backups stored on external drives or cloud services are unreadable without the decryption key.
**OWASP Alignment:** A02 — Cryptographic Failures.

### 10.2 Receipt Reprint Authorization Controls
**Gap:** The current system logs reprint events but does not explicitly gate reprint access on the cashier's own transactions vs. all transactions.
**Recommendation:** Explicitly enforce that Cashiers may only reprint receipts for transactions they personally processed (matching `cashier_id` = current session user ID). Admins retain access to all transaction reprints.
**OWASP Alignment:** A01 — Broken Access Control.

### 10.3 Session Token Secure Storage
**Gap:** The `SessionManager` singleton is in-memory only. If the application is backgrounded and resumed, session state behavior should be clearly defined.
**Recommendation:** Implement `flutter_secure_storage` (already a listed dependency) to persist a cryptographically signed session token with an expiration timestamp. On app resume, validate the token age before restoring the session.
**ISO/IEC 25010 Alignment:** Security — Authenticity sub-characteristic.

### 10.4 Failed Login IP/Device Logging
**Gap:** The `login_attempts` table exists but it is unclear whether device information and IP address are recorded at the time of the attempt.
**Recommendation:** Capture device identifier and network interface address at the moment of each login attempt and store alongside the `failed_login_count` increment. This enables the Admin to identify patterns of coordinated brute force attempts from specific devices.
**OWASP Alignment:** A09 — Security Logging and Monitoring Failures.

### 10.5 Void/Refund Dual Authorization
**Gap:** Voiding and refunding require "Administrator Authorization" but the current implementation may rely solely on the logged-in Admin role rather than a separate re-authentication step.
**Recommendation:** Implement a **Void/Refund Confirmation PIN** — a secondary confirmation requiring the Admin to re-enter their password before any void or refund is committed. This prevents accidental or unauthorized voids during an unattended Admin session.
**OWASP Alignment:** A07 — Identification and Authentication Failures.

### 10.6 Structured Error Logging
**Gap:** Database errors are handled gracefully but may not always be persisted to Activity Logs.
**Recommendation:** Standardize error logging in the `AuditRepository` to capture all database exceptions with error codes, module context, and user session info. This enables post-incident forensic analysis without exposing technical details in the UI.
**OWASP Alignment:** A09 — Security Logging and Monitoring Failures.

### 10.7 Receipt Number Tamper Protection
**Gap:** Receipt numbers are generated sequentially, which may allow detection of gaps (indicating deleted or suppressed transactions) but does not provide cryptographic non-repudiation.
**Recommendation:** Include a transaction hash (SHA-256 of: `receipt_number + cashier_id + total + timestamp + salt`) stored alongside each transaction. Admins can use this hash to verify that no receipt data has been tampered with post-creation.
**ISO/IEC 25010 Alignment:** Security — Integrity sub-characteristic.

### 10.8 Supabase Sync Queue and Retry Mechanism
**Gap:** The current sync strategy performs background upsert without a formalized queue or retry policy for failed sync operations.
**Recommendation:** Implement a `sync_queue` table in SQLite to track pending sync operations with status (`pending`, `failed`, `synced`) and retry count. This ensures no records are silently dropped due to transient connectivity issues.
**ISO/IEC 25010 Alignment:** Reliability — Fault Tolerance sub-characteristic.

### 10.9 Minimum Password Complexity Enforcement
**Gap:** The system enforces a minimum password length of 8 characters but does not enforce character complexity requirements.
**Recommendation:** Require passwords to contain at least one uppercase letter, one lowercase letter, one digit, and one special character. Display a real-time password strength indicator during account creation and password change workflows.
**OWASP Alignment:** A07 — Identification and Authentication Failures.

### 10.10 Application Build Obfuscation
**Gap:** Flutter release builds for Android and Windows are not explicitly configured for code obfuscation.
**Recommendation:** Enable Dart code obfuscation (`--obfuscate --split-debug-info`) in production release builds to prevent reverse-engineering of security logic, credential loading, and database access patterns.
**OWASP Alignment:** A05 — Security Misconfiguration (insufficient hardening).

---

## XI. Research Methodology

The study will follow an iterative software development lifecycle consisting of the following phases:

### Phase 1 — Requirements Analysis
Structured interviews with the NY Kitchen owner and direct observation of current manual workflows to elicit functional and non-functional requirements. Requirements are documented in the Project Blueprint.

### Phase 2 — System and Database Design
Feature-first architecture design, SQLite schema specification (nine-table relational schema), UI wireframing (desktop three-panel POS layout, responsive Admin shell), and security control specification based on OWASP and the CIA Triad.

### Phase 3-10 — Iterative Development
Phased implementation following the approved roadmap: SQLite integration, authentication and security, menu management, cloud synchronization, UI/UX polish, and security hardening.

### Phase 11 — Testing
- **Unit Testing:** Repository and service layer logic
- **Widget Testing:** UI component rendering and navigation
- **Integration Testing:** End-to-end transaction workflows
- **Security Testing:** Password hashing correctness, lockout enforcement, session expiration, route guard behavior, SQL injection resistance
- **Offline Behavior Testing:** Full workflow without network connectivity
- **Responsive Testing:** Desktop, tablet, and mobile breakpoints

### Phase 12 — Evaluation
The completed system will be evaluated using:
1. **ISO/IEC 25010 Questionnaire:** Administered to target respondents (staff, IT evaluators) using a validated Likert-scale instrument covering all eight quality characteristics.
2. **OWASP Security Review:** Checklist-based assessment of implemented controls against the OWASP Secure Coding Practices Quick Reference Guide.
3. **Expert Validation:** Source code and architecture reviewed by academic evaluators with expertise in information security and software engineering.

---

## XII. Expected Output

Upon completion, the N.Y Kitchen Secure Order and Sales Management System will deliver:

- A production-ready cross-platform POS application supporting Windows Desktop and Android (phone and tablet)
- Secure login with PBKDF2-HMAC-SHA256 hashed credentials and session management
- Role-Based Access Control (Admin and Cashier) with declarative route guards
- Complete offline transaction processing via SQLite
- Digital receipt generation and printing
- Immutable activity audit logs with export functionality
- Admin dashboard with live revenue analytics and security event monitoring
- Sales reports (All, Daily, Weekly, Monthly, Annual) with PDF and CSV export
- Menu management with CRUD, category control, image handling, and archiving
- User account management with lockout, unlock, and password reset workflows
- Database backup and restore with rolling retention policy
- Optional background cloud synchronization to Supabase with device-level authentication and Row-Level Security
- ISO/IEC 25010 evaluation report and OWASP security assessment documentation

The system will demonstrate the practical application of information assurance principles—CIA Triad, OWASP Secure Coding Practices, and ISO/IEC 25010—in a real-world small business software engineering context.

---

*End of Concept Paper*

---

**Document Version:** 1.0  
**Date:** July 30, 2026  
**System:** N.Y Kitchen Secure Order and Sales Management System  
**Platform:** Flutter (Dart) — Android + Windows Desktop  
**Database:** SQLite (local) + Supabase (cloud backup vault)  
**Security Standards:** CIA Triad · OWASP Secure Coding Practices · ISO/IEC 25010
