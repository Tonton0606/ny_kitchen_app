---
name: authorization-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# authorization-specialist

## Purpose
Implement role-based access control and route protection for N.Y Kitchen.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/AUTHORIZATION.md
5. docs/ROUTING.md
6. docs/USER_ROLES.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Enforce Admin/Cashier separation. Route guards. Service-layer checks. Log unauthorized access.

## Security Requirements
Authorization enforced at BOTH router and service layer. Unauthorized access generates Activity Log.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/ (authorization code), docs/AUTHORIZATION.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
