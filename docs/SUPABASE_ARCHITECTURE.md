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

## Supported Synchronized Entities (Future)
- [ ] Transactions (read-only in cloud after sync)
- [ ] Activity Logs (append-only in cloud)
- [ ] Menu items
- [ ] User accounts (partial — no password hashes)
- [ ] App settings

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
