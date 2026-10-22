# docs/SUPABASE_ARCHITECTURE.md

> 2026-10-20 reconciliation: Supabase push/pull and image transfer exist in current source. Deployment/RLS are not verified. Future-only statements below describe older planning; local authentication remains the baseline. See SECURITY_IMPLEMENTATION_PLAN.md for K02, AT10 and the approved hybrid synchronization scope (owner confirmation, 2026-10-20).
# N.Y Kitchen — Supabase Architecture

> Status: APPROVED — Online synchronization in a hybrid offline/online application; live security verification pending
> Source of Truth: PROJECT_BLUEPRINT.md
> See: DECISIONS.md ADR-002

---

## Purpose
Document Supabase online synchronization while preserving SQLite-backed offline operations.

---

## Supabase Project Purpose
Supabase serves as an optional cloud platform for:
- Cloud backup of SQLite data
- Cross-device synchronization
- PostgreSQL cloud storage
- Remote Admin access (future)
- Authentication support (optional future)
- Security event synchronization
- Transaction synchronization
- Account synchronization
- Menu synchronization
- Future analytics

---

## Critical Security Rules
- **The service-role key MUST NEVER be placed in the Flutter client.**
- **Supabase credentials must never be committed to source control.**
- Row-Level Security (RLS) must be enabled on ALL protected tables.
- Separate development and production Supabase projects.
- Use least-privilege access for all operations.
- Use environment-based configuration (.env, not hardcoded).

---

## Authentication Strategy
- TODO: Pending Review — Supabase Auth vs custom JWT vs no cloud auth
- Local SQLite-based authentication must remain the primary auth system.
- Supabase Auth, if used, is supplementary only.
- See: DECISIONS.md ADR-013

---

## Row-Level Security Strategy
- Enable RLS on all tables.
- Define policies based on authenticated user role.
- Never rely on client-side filtering for security.
- Document all policies before implementation.
- TODO: Define table-level RLS policies before Supabase integration begins.

---

## Storage Strategy
- Supabase Storage: For cloud backup files (future).
- Food images: Local only in initial version. Cloud storage is future enhancement.
- Never store plain-text passwords in cloud storage.

---

## Environment Configuration

### Development Environment
- Supabase URL: [TODO — Store in .env only]
- Supabase Anon Key: [TODO — Store in .env only]
- Project ID: [TODO]

### Production Environment
- Supabase URL: [TODO — Store in secure environment config]
- Supabase Anon Key: [TODO — Store in secure environment config]
- Project ID: [TODO]

> **IMPORTANT:** Never commit real values. Use environment variables.

---

## Synchronization Boundaries
- See: docs/DATA_SYNCHRONIZATION.md
- See: docs/SYNC_CONFLICT_POLICY.md

## Current Synchronization Implementation (Not Yet Live-Verified)
- The app can upload and download `users`, `food_categories`, `food_items`, `transactions`, `transaction_items`, `activity_logs`, and `login_attempts` through `SyncService`.
- Manual mode invokes one upload followed by one download. Automatic mode starts an immediate full sync and retries every 15 seconds when the saved `app_settings.sync_mode` is `automatic`.
- Ubuntu backend mode is a separate one-way sales upload path; it does not use this Supabase table sync.
- Upload failures and download failures are reported by table and a safe database error code. A full sync is successful only when both directions finish without table failures.
- Upserts use the minimal response so they do not require an additional `SELECT` policy. Download still requires valid `SELECT` access for each configured table.
- User password hashes and face encodings are excluded from uploads. Local values are retained when user records are pulled.
- `.env` values can be read from the process environment, the current working directory, or beside the desktop executable. Mobile builds do not receive `.env` automatically; do not package device secrets as Flutter assets.

The code path is implemented, but live reachability, deployed table schemas, RLS policies, mobile provisioning, and cross-device conflict behavior remain unverified. See the latest entry in `SECURITY_DEFENSE_RECORD.md`.

## Reported RLS rejection — 2026-10-22

A user-provided Windows trace reports PostgreSQL `42501` / `new row violates row-level security policy` for every table in the sync allowlist. This is a Supabase authorization failure, not an offline SQLite failure. The trace's `SyncToCloud failed` and `Cloud Backup Sync Complete!` messages are absent from the current source, so those lines are from an older build/run; the later `flutter run` output in the same attachment shows Supabase initialization but no fresh sync result.

The Flutter source initializes Supabase with the public anon key and a custom `x-device-secret` header. POS login is local SQLite; the repository has no Supabase Auth sign-in flow that establishes a cloud user identity. A custom HTTP header is not automatically enforced by PostgreSQL RLS. A later user-provided Supabase screenshot confirms RLS is enabled on all seven sync tables and each has one `ALL` policy named `Enforce device secret on ...`, with role `public`. The screenshot does not show the policy expressions or the rightmost anon/authenticated grants. The write error (`new row violates row-level security policy`) is consistent with a false `WITH CHECK` condition; a missing grant also needs to be ruled out. A stale or missing device secret is plausible, but has not been verified.

The expanded screenshots show the `USING` condition exists and calls `check_device_secret`; there is no explicit `WITH CHECK` condition, and the policy expression itself does not mention `request.headers`. All seven policies are `PERMISSIVE`, and the displayed anon and authenticated SELECT/INSERT/UPDATE grants are true. The `request.headers` check is expected to be inside the helper function, not the policy expression. PostgreSQL uses an `ALL` policy's `USING` expression as its write check when `WITH CHECK` is omitted ([PostgreSQL CREATE POLICY](https://www.postgresql.org/docs/current/sql-createpolicy.html)). Given the reported new-row policy violation, the device-secret helper is therefore evaluating false for the app's write request. The likely cause is a missing/mismatched header value or a stale server-side helper value; the exact mismatch is not visible in the metadata screenshots.

The Flutter startup loader gives process environment variables precedence over `.env` values (`envVars.addAll(processEnvVars)`), so a stale `SUPABASE_DEVICE_SECRET` in the launching PowerShell environment can override the local file. A user-provided, truncated screenshot of the helper shows it reads a value from request headers and compares it with a fixed literal. The owner reported the local `.env` value differed and changed it privately; synchronization still reports an error. The app's previous top-bar action displayed only a generic `Sync error`, and the latest terminal output has no fresh table/error code. The top-bar action now displays the sanitized status after a manual attempt. Restart Flutter after correcting configuration, then use a development project with synthetic data to capture the result; do not run a full sync on Production.

A fixed shared secret distributed with a Flutter client is extractable and is not a strong device identity. Treat the current comparison as a demo gate only. For durable security, replace the shared client secret with authenticated identities and least-privilege RLS, or route approved operations through the reviewed backend. The Ubuntu backend currently provides one-way sales replication and does not replace the existing multi-table Supabase sync.

The read-only diagnostic reports boolean indicators for whether conditions exist and reference `check_device_secret` / `request.headers`, without displaying policy expressions or any secret. It also reports policy mode and anon/authenticated table grants. Do not share the secret, function body, or raw policy expression.

Do not resolve this by disabling RLS or granting unrestricted `anon` access. The Ubuntu API is a separate, one-way sales replication path and does not currently replace this multi-table Supabase sync. Secure multi-table sync needs an explicit identity and authorization design (for example, Supabase Auth sessions with least-privilege policies, or reviewed authenticated backend endpoints). Run the read-only query in `docs/security/supabase_rls_diagnostics.sql` and review its output before writing project-specific policies. The query omits policy expressions and business data.

## Data Ownership
- SQLite (local) is the primary data owner.
- Supabase holds a synchronized copy.
- Local data is authoritative until sync conflict resolution policy is defined.

---

## Offline Behavior
- Application continues functioning when Supabase is unavailable.
- Pending sync records are queued in SQLite.
- Sync is retried when connectivity is restored.

---

## Security Incident Response (Placeholder)
- [ ] Define key rotation process
- [ ] Define compromised device response
- [ ] Define revoked account behavior
- [ ] Define compromised service-role key response

---

## Open Architectural Decisions
- ADR-002: Hybrid online synchronization scope (Accepted 2026-10-20)
- ADR-012: Synchronization strategy (Pending Review)
- ADR-014: Conflict resolution strategy (Pending Review)

---

## TODO
- [ ] Create Supabase project (not before integration phase is approved)
- [ ] Define and document all RLS policies before implementation
- [ ] Set up environment variable management
- [ ] Separate dev and prod environments
