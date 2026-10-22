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

The Flutter source initializes Supabase with the public anon key and a custom `x-device-secret` header. POS login is local SQLite; the repository has no Supabase Auth sign-in flow that establishes a cloud user identity. A custom HTTP header is not automatically enforced by PostgreSQL RLS. With RLS enabled and no matching policy for the request role, writes are denied as expected. The deployed policies and role grants are not available in this repository, so the exact policy mismatch is not yet established.

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
