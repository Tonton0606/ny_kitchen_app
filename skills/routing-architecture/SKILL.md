---
name: routing-architecture
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# routing-architecture

## Purpose
Configure go_router navigation with role-based route guards for N.Y Kitchen.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. DECISIONS.md (ADR-005)
5. docs/ROUTING.md
6. docs/AUTHORIZATION.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Route guards must redirect unauthorized access to /unauthorized. Unauthorized access must generate Activity Log. Do not rely solely on route guards — enforce at service layer too.

## Security Requirements
Route guards are not the only security layer. Service layer must also enforce role checks.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/core/router/

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
