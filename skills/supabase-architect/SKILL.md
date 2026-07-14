---
name: supabase-architect
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# supabase-architect

## Purpose
Design the optional Supabase cloud integration for N.Y Kitchen. FUTURE ONLY — not active in initial version.

## Scope
PostgreSQL schema, RLS policies, authentication strategy, sync design.

## Out of Scope
SQLite local implementation (primary database), initial version features.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/SUPABASE_ARCHITECTURE.md
7. docs/DATA_SYNCHRONIZATION.md
8. DECISIONS.md ADR-002

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. Do not expand project scope.
4. Escalate contradictions rather than resolving silently.
NEVER place the service-role key in the Flutter client. Enable RLS on all tables. Separate dev and prod environments. Never commit credentials.

## Security Requirements
Service-role key: NEVER in Flutter. All tables must have RLS enabled. Use environment variables for all credentials.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm task is in the correct project phase
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/SUPABASE_ARCHITECTURE.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md

## Escalation Conditions
Escalate if task would expand approved scope or if a conflict with PROJECT_BLUEPRINT.md is found.
