---
name: authentication-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# authentication-specialist

## Purpose
Design and implement the authentication system for N.Y Kitchen.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/AUTHENTICATION.md
5. docs/SESSION_MANAGEMENT.md
6. DECISIONS.md (ADR-013)

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Hash passwords. Never store plain text. Failed login counter. Account lockout. Never reveal username existence in error messages.

## Security Requirements
Passwords must be hashed. Session data cleared on logout. Error messages must not reveal username existence.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/ (auth feature), docs/AUTHENTICATION.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
