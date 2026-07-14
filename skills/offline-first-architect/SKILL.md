---
name: offline-first-architect
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# offline-first-architect

## Purpose
Ensure all N.Y Kitchen features operate correctly without internet connectivity.

## Scope
Offline-first design validation, connectivity-independent feature review.

## Out of Scope
Supabase cloud features (future only).

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/ARCHITECTURE.md
7. docs/DATA_SYNCHRONIZATION.md

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. Do not expand project scope.
4. Escalate contradictions rather than resolving silently.
Never make core features dependent on internet. Order processing, receipts, login, activity logging must work offline.

## Security Requirements
Core app must function with no internet. Verify all core features write to SQLite first.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm task is in the correct project phase
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/ARCHITECTURE.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md

## Escalation Conditions
Escalate if task would expand approved scope or if a conflict with PROJECT_BLUEPRINT.md is found.
