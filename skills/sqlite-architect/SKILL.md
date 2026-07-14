---
name: sqlite-architect
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# sqlite-architect

## Purpose
Design and implement the N.Y Kitchen SQLite local database architecture.

## Scope
Schema design, parameterized queries, migrations, backup, restore.

## Out of Scope
Supabase cloud tables, UI implementation.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/SQLITE_ARCHITECTURE.md
7. docs/DATABASE.md
8. docs/BACKUP_STRATEGY.md
9. DECISIONS.md ADR-001 ADR-015

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. Do not expand project scope.
4. Escalate contradictions rather than resolving silently.
Never use raw SQL string concatenation. Always use parameterized queries. Never delete completed transactions. activity_logs must have no UPDATE or DELETE queries through the normal interface.

## Security Requirements
Use parameterized queries exclusively. Store only image paths. Normalize related data. Use foreign keys.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm task is in the correct project phase
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/data/database/, docs/SQLITE_ARCHITECTURE.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md

## Escalation Conditions
Escalate if task would expand approved scope or if a conflict with PROJECT_BLUEPRINT.md is found.
