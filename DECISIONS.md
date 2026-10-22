# DECISIONS.md
# N.Y Kitchen — Architecture Decision Records (ADR) Index

> All architectural decisions must be recorded here before implementation.
> Unresolved decisions must use status: **Pending Review** or **Proposed**.
> Do not mark a decision as **Accepted** unless it has been reviewed and confirmed.
> Authority: `PROJECT_BLUEPRINT.md` → `RULES.md`

---

## ADR Index

| ID | Title | Status | Date |
|---|---|---|---|
| ADR-001 | SQLite as Primary Local Database | Accepted | 2026-07-14 |
| ADR-002 | Supabase online synchronization; offline core retained | Accepted | 2026-10-20 |
| ADR-003 | Offline-First Architecture | Accepted | 2026-07-14 |
| ADR-004 | Provider for State Management | Proposed | 2026-07-14 |
| ADR-005 | go_router for Navigation | Proposed | 2026-07-14 |
| ADR-006 | Feature-First Architecture | Accepted | 2026-07-14 |
| ADR-007 | Repository Pattern | Accepted | 2026-07-14 |
| ADR-008 | Service Layer | Accepted | 2026-07-14 |
| ADR-009 | Material 3 UI Foundation | Accepted | 2026-07-14 |
| ADR-010 | Local Food Image Storage (Path-Based) | Accepted | 2026-07-14 |
| ADR-011 | Receipt Generation Strategy | Accepted | 2026-07-14 |
| ADR-012 | Synchronization Strategy | Pending Review | 2026-07-14 |
| ADR-013 | Authentication Strategy | Accepted | 2026-07-14 |
| ADR-014 | Conflict Resolution Strategy | Pending Review | 2026-07-14 |
| ADR-015 | SQLite Package Selection | Accepted | 2026-07-14 |
| ADR-016 | Backup and Restore Strategy | Accepted | 2026-07-14 |

---

## ADR-001 — SQLite as Primary Local Database

| Field | Value |
|---|---|
| **Decision ID** | ADR-001 |
| **Title** | SQLite as Primary Local Database |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The application must function completely offline across Android and Windows devices. A local database is required to store users, menu items, transactions, activity logs, and settings without requiring internet access.

### Problem
Which local database engine should be used to ensure offline-first operation, reliability, and cross-platform support?

### Options Considered
1. **SQLite** — Lightweight, embedded, cross-platform, widely used with Flutter.
2. **Hive** — NoSQL, lightweight, good for key-value but lacks relational features needed for transactions.
3. **Isar** — Modern Flutter database, but less battle-tested for complex relational data.

### Decision
**SQLite** is used as the primary local database via a Flutter package (sqflite or drift — see ADR-015).

### Consequences
- All core application features work without internet.
- Complex relational queries are supported (JOIN, transactions, foreign keys).
- Backup and restore can be implemented by copying the SQLite file.
- Limited to one device per installation (multi-device sync requires Supabase — see ADR-002).

### Security Impact
- Parameterized queries must be used to prevent SQL injection.
- The database file should be stored in the application documents directory with restricted access.

### Data Impact
- All tables are defined in `docs/SQLITE_ARCHITECTURE.md`.
- Image paths (not blobs) are stored to keep the database lightweight.

### Platform Impact
- Supported on Android and Windows via Flutter SQLite packages.
- Windows SQLite file path differs from Android — documented in `docs/SQLITE_ARCHITECTURE.md`.

### Revisit Conditions
- If multi-device synchronization becomes a primary requirement.
- If a Supabase-first architecture is approved in a future version.

---

## ADR-002 — Supabase as Optional Cloud Platform

| Field | Value |
|---|---|
| **Decision ID** | ADR-002 |
| **Title** | Supabase as Optional Cloud Platform |
| **Status** | Accepted — scope confirmed 2026-10-20 |
| **Date** | 2026-07-14 |

### Historical Context
The blueprint mentions Supabase as a future optional enhancement for cloud backup, synchronization, and remote Admin access. It is NOT a core requirement for the initial application.

### Problem
Should Supabase be integrated in the initial version, and what should the scope of its integration be?

### Options Considered
1. **Supabase for cloud backup only** — Minimal integration, SQLite remains primary.
2. **Supabase for backup + sync** — Extends to cross-device synchronization.
3. **No Supabase in initial version** — Defer all cloud features to a future version.

### Decision
**Accepted, 2026-10-20.** The owner confirmed that the system is hybrid offline/online with online synchronization. SQLite supports core offline operations; Supabase synchronizes records when connected. This approves synchronization scope, not a claim of verified RLS, conflict handling, recovery, remote Admin access, or cloud authentication.

### Consequences
- Core application will be fully functional without Supabase.
- Supabase integration requires separate environment configuration.
- Service-role key must never be placed in the Flutter client.

### Security Impact
- Row-Level Security must be enabled on all Supabase tables.
- Credentials must use environment-based configuration.
- Development and production environments must be separated.

### Data Impact
- Supabase stores a copy of approved synchronized records.
- SQLite remains the primary data source.
- Conflict resolution must be defined before sync is implemented (see ADR-014).

### Platform Impact
- Supabase SDK must be compatible with Flutter on Android and Windows.

### Revisit Conditions
- When synchronization requirements or data boundaries change.
- Before beginning Supabase integration work.

---

## ADR-003 — Offline-First Architecture

| Field | Value |
|---|---|
| **Decision ID** | ADR-003 |
| **Title** | Offline-First Architecture |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
N.Y Kitchen operates in a food stall environment where internet access may be unreliable. The application must function completely without internet.

### Decision
All core operations write to SQLite first. Internet connectivity is never required for order processing, receipt generation, login of provisioned users, or activity logging.

### Consequences
- All primary features are available offline.
- Synchronization with Supabase is queued and performed when connectivity is available.

### Security Impact
- Local authentication must be performed against the SQLite user table.
- Session validation must not depend on external services.

### Revisit Conditions
- Never. Offline-first is a non-negotiable requirement from the blueprint.

---

## ADR-004 — Provider for State Management

| Field | Value |
|---|---|
| **Decision ID** | ADR-004 |
| **Title** | Provider for State Management |
| **Status** | Proposed |
| **Date** | 2026-07-14 |

### Context
The blueprint lists Provider as the state management solution, subject to change if future requirements demand another solution.

### Decision
**Proposed.** Use Provider for state management. This must be confirmed before Phase 2 implementation begins.

### Options Considered
1. **Provider** — Simple, official Flutter recommendation, sufficient for this application size.
2. **Riverpod** — More powerful, better testing support, greater complexity.
3. **BLoC** — Enterprise-level, higher boilerplate, overkill for this project size.
4. **GetX** — Lightweight but opinionated and less idiomatic.

### Revisit Conditions
- Before Phase 2 implementation begins.
- If application complexity grows beyond Provider's capabilities.

---

## ADR-005 — go_router for Navigation

| Field | Value |
|---|---|
| **Decision ID** | ADR-005 |
| **Title** | go_router for Navigation |
| **Status** | Proposed |
| **Date** | 2026-07-14 |

### Context
The blueprint lists go_router for navigation, which supports declarative routing, deep linking, and route guards for role-based access control.

### Decision
**Proposed.** Use go_router for navigation. Role-based route guards will be implemented to protect Admin and Cashier routes. Confirm before Phase 2.

### Security Impact
- Route guards must enforce role-based access at the router level AND at the logic layer.
- Unauthorized access attempts must generate an Activity Log entry.

### Revisit Conditions
- Before Phase 2 implementation begins.

---

## ADR-006 — Feature-First Architecture

| Field | Value |
|---|---|
| **Decision ID** | ADR-006 |
| **Title** | Feature-First Folder Architecture |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The application has clearly separated modules: Auth, Admin, Cashier, Menu, Transactions, Activity Logs, Reports, Backup, Settings. Feature-first organization keeps related code together and improves maintainability.

### Decision
**Accepted.** Use feature-first folder structure as documented in `docs/FOLDER_STRUCTURE.md`.

### Consequences
- Each feature has its own folder containing screens, widgets, providers, repositories, and services.
- Shared components live in a `shared/` or `core/` directory.

---

## ADR-007 — Repository Pattern

| Field | Value |
|---|---|
| **Decision ID** | ADR-007 |
| **Title** | Repository Pattern for Data Access |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The blueprint specifies the Repository Pattern to separate data access from business logic and facilitate testing.

### Decision
**Accepted.** All data access goes through repository interfaces. SQLite repositories implement local data access. Future Supabase repositories may implement cloud data access using the same interfaces.

---

## ADR-008 — Service Layer

| Field | Value |
|---|---|
| **Decision ID** | ADR-008 |
| **Title** | Service Layer Between UI and Data |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
Business logic (validation, activity log triggers, checkout workflow) must not live in UI widgets. A service layer provides a clean separation between presentation and domain logic.

### Decision
**Accepted.** Use a service layer for all business logic. Services call repositories and do not interact with the database directly.

---

## ADR-009 — Material 3 UI Foundation

| Field | Value |
|---|---|
| **Decision ID** | ADR-009 |
| **Title** | Material 3 as UI Design Foundation |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The blueprint specifies Material 3 as the approved UI system for the application.

### Decision
**Accepted.** Use Material 3 (Flutter's `useMaterial3: true`). Theme tokens are defined in `docs/DESIGN_SYSTEM.md`. Primary palette: Yellow, Red, White, Black.

---

## ADR-010 — Local Food Image Storage (Path-Based)

| Field | Value |
|---|---|
| **Decision ID** | ADR-010 |
| **Title** | Store Food Image Paths, Not Image Blobs |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
Storing image binary data in SQLite would increase database size significantly and degrade performance.

### Decision
**Accepted.** SQLite stores only the file path to the food image. Default images are stored in `assets/images/foods/`. Admin-uploaded images are copied to the application's local storage directory.

---

## ADR-011 — Receipt Generation Strategy

| Field | Value |
|---|---|
| **Decision ID** | ADR-011 |
| **Title** | Receipt Generation and Printing Strategy |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The application must generate printable receipts immediately after every successful transaction. The blueprint mentions the `printing` and `pdf` packages.

### Problem
Which packages should be used? Should receipts be printed directly or generated as PDF first? How should printing be handled on Windows vs Android?

### Decision
**Accepted.** Use the `pdf` package to generate receipt layouts in memory, and the `printing` package to interface with native print dialogs on both Windows and Android.
- **Printer Models**: Support any OS-configured printer (thermal or standard) using native print dialogs.
- **Format**: Standard PDF layout tailored for 80mm/58mm thermal paper dimensions.
- **Storage**: Do not save PDFs to local storage. Instead, re-generate the PDF on the fly from the SQLite transaction history if a reprint is requested.
- **Platform**: `printing` abstracts OS differences seamlessly.

### Consequences
- Requires configuring OS-level printers for thermal receipts.
- No local file bloat since PDFs are not saved permanently.

---

## ADR-012 — Synchronization Strategy

| Field | Value |
|---|---|
| **Decision ID** | ADR-012 |
| **Title** | Offline-to-Cloud Synchronization Strategy |
| **Status** | Pending Review |
| **Date** | 2026-07-14 |

### Context
When Supabase is integrated (future phase), records created offline must be synchronized to the cloud when connectivity is restored.

### Open Questions
- [ ] Which entities should be synchronized? (transactions, menu, users, activity logs)
- [ ] Should sync be automatic on reconnect, manual only, or both?
- [ ] How is the sync queue implemented? (SQLite table, in-memory, etc.)
- [ ] How is duplicate prevention handled?

### Revisit Conditions
- When Supabase integration is approved by the project owner.

---

## ADR-013 — Authentication Strategy

| Field | Value |
|---|---|
| **Decision ID** | ADR-013 |
| **Title** | Authentication and Password Hashing Strategy |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The application uses username/password authentication stored in SQLite. Passwords must be hashed before storage.

### Decision
**Accepted.** Use standard cryptographic hashing with PBKDF2 (SHA-256) and a random salt via the official Dart `crypto` package.
- **Hashing Algorithm**: PBKDF2 with SHA-256 and a random salt. This requires no native dependencies, ensuring consistent behavior across Windows and Android.
- **Minimum Password Length**: 8 characters.
- **Lockout Policy**: 5 failed login attempts trigger a 15-minute account lockout.
- **Session Expiration**: Sessions expire automatically after 12 hours of inactivity, requiring re-authentication (aligns with a typical cashier shift).
- **Session Storage**: Session tokens and authentication state will be stored securely using `flutter_secure_storage`.

### Consequences
- Requires adding `crypto` and `flutter_secure_storage` dependencies.
- Passwords are secure against rainbow tables due to individual salting.

---

## ADR-014 — Conflict Resolution Strategy

| Field | Value |
|---|---|
| **Decision ID** | ADR-014 |
| **Title** | Sync Conflict Resolution Strategy |
| **Status** | Pending Review |
| **Date** | 2026-07-14 |

### Context
When multiple devices sync to Supabase, conflicts may occur. A policy is needed to determine which version wins or how conflicts are surfaced for review.

### Open Questions
- [ ] Last-write-wins vs. first-write-wins vs. manual review?
- [ ] How are immutable records (transactions, activity logs) protected from overwrite?
- [ ] How are device clock differences handled?

### Implementation Note — 2026-10-23 (Pending Verification)

To address observed cross-device sale ID collisions, the client now assigns new transactions and transaction items installation-scoped signed 64-bit IDs. The local namespace and counter are stored outside the synchronized table set. During Supabase sync, a same-ID transaction with a different receipt/sale identity is preserved by moving the local transaction and its items to new IDs before the cloud record is inserted. This is a partial identity-collision control, not a final policy for simultaneous status edits or all synchronized tables. Confirm cloud key columns are `bigint` and verify with two devices before accepting this ADR.

### Revisit Conditions
- Before Supabase sync implementation begins.

---

## ADR-015 — SQLite Package Selection

| Field | Value |
|---|---|
| **Decision ID** | ADR-015 |
| **Title** | Flutter SQLite Package (sqflite vs drift) |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
Two major Flutter SQLite packages exist: `sqflite` (direct SQL) and `drift` (type-safe ORM with code generation).

### Decision
**Accepted.** Use `sqflite` (and `sqflite_common_ffi` for Windows support). 
- **Simplicity**: The direct SQL approach of `sqflite` is simpler for this project's scope and avoids the boilerplate and build-step overhead of code generation tools like `drift`.
- **Control**: Writing raw SQL queries allows explicit control over performance and schema migrations.
- **Windows Support**: `sqflite_common_ffi` provides full support for SQLite on Windows desktop.

### Consequences
- Developers must write raw SQL strings, increasing the risk of syntax errors compared to type-safe ORMs.
- Strict adherence to parameterized queries is required to prevent SQL injection (as noted in ADR-001).

---

## ADR-017 — Defense environment and security reconciliation (2026-10-20)

**Status:** Recommended plan; implementation decisions pending verification.

Use Windows with disposable SQLite fixtures for the base defense. The owner clarified Linux meant a VM and could be omitted if unnecessary; the rubric does not require it. Docker is optional. ZAP is optional for the Python HTTP API. Native application controls require direct repository and device tests.

`docs/SECURITY_IMPLEMENTATION_PLAN.md` maps all 20 rubric criteria and the proposed treatment sequence. No runtime architecture was changed.

Pending decisions: confirm face functionality in the demonstrated scope; verify the owner-approved online synchronization; record current Navigator/stateful-widget implementation against earlier Provider/go_router proposals; revise ADR-016 to match a verified protected backup/restore implementation. RPO/RTO targets in the plan are proposals, not achieved guarantees.

## ADR-016 — Backup and Restore Strategy

| Field | Value |
|---|---|
| **Decision ID** | ADR-016 |
| **Title** | Database Backup and Restore Strategy |
| **Status** | Accepted |
| **Date** | 2026-07-14 |

### Context
The application must support manual database backup and restore. SQLite backup can be implemented by copying the database file to a user-accessible directory.

### Decision
**Accepted.** Backups will consist of copying the SQLite `.db` file to a dedicated backups folder within the Application Documents directory (on both Windows and Android).
- **Storage Location**: `getApplicationDocumentsDirectory()/ny_kitchen_backups/`
- **Exporting**: Users can export the backup file externally via the `share_plus` package (Android) or native file save dialogs (Windows).
- **Compression & Encryption**: None at the app level. Rely on OS-level encryption for the device. The `.db` files are expected to be small enough without compression.
- **Retention**: Keep a rolling window of the last 7 daily automatic backups. Manual backups are kept indefinitely until explicitly deleted by the user.
- **Cloud Backup**: Supabase Storage may be supported as an optional backup destination in a future phase.

### Consequences
- Simple, reliable backup process.
- Requires user training on how to export backups to external drives for disaster recovery.

## ADR-018 — Flutter retained with Ubuntu synchronization backend

**Accepted direction, 2026-10-22:** owner explicitly chose an Ubuntu VM backend while retaining Flutter. First implementation: device-authenticated HTTPS sales replication; separate Admin read token; server SQLite revision history; no deletion endpoint; explicit backend selection to avoid concurrent Supabase writes. No local user/password/biometric replication. This is one-way sales sync, not a full replacement for existing two-way Supabase features. Existing server credentials are operator-provisioned, not new POS user roles. User has no VM yet; deployment files prepared, deployment pending.

Local evidence: 11 backend tests and 4 Flutter sync tests pass; see `docs/security/evidence/2026-10-defense/backend_verification.md`. Threats remaining: compromised terminal can falsify its own submissions; operator filesystem access can alter server data; local repository authorization remains open. Exact VM network/HTTPS setup and recovery need separate verification.
