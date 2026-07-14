---
name: data-sync-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# data-sync-specialist

## Purpose
Design the data synchronization strategy between SQLite and Supabase. FUTURE ONLY.

## Scope
Sync queue design, retry policy, duplicate prevention, conflict detection.

## Out of Scope
SQLite schema, Supabase setup.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/DATA_SYNCHRONIZATION.md
7. docs/SYNC_CONFLICT_POLICY.md
8. DECISIONS.md ADR-012 ADR-014

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. Do not expand project scope.
4. Escalate contradictions rather than resolving silently.


## Security Requirements
Immutable records (transactions, activity logs) must never be overwritten by sync. Conflict resolution must be documented before implementation.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm task is in the correct project phase
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/DATA_SYNCHRONIZATION.md, docs/SYNC_CONFLICT_POLICY.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md

## Escalation Conditions
Escalate if task would expand approved scope or if a conflict with PROJECT_BLUEPRINT.md is found.
