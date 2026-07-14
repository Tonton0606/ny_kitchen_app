# docs/SUPABASE_DEPLOYMENT.md
# N.Y Kitchen — Supabase Deployment

> Status: FUTURE/OPTIONAL — Not required for initial version.

---

## Purpose
Document the steps to configure Supabase for cloud integration when approved.

---

## Pre-Conditions
- Supabase integration approved by project owner (see DECISIONS.md ADR-002).
- Architecture decisions for sync and conflict resolution finalized.

## Setup Steps (Placeholder)
1. Create production Supabase project (separate from development).
2. Apply all database schema migrations.
3. Enable Row-Level Security on all tables.
4. Define and apply RLS policies.
5. Configure environment variables in deployment environment.
6. Never commit real credentials to source control.
7. Test all RLS policies thoroughly.

---

## TODO
- [ ] Complete only after Supabase integration is approved
- [ ] Document all RLS policies in docs/SUPABASE_ARCHITECTURE.md before implementation
