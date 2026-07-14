---
name: provider-architecture
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# provider-architecture

## Purpose
Design and implement Provider-based state management for N.Y Kitchen.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. DECISIONS.md (ADR-004)
5. docs/STATE_MANAGEMENT.md
6. docs/ARCHITECTURE.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Providers call services, not repositories directly. Providers do not contain business logic. Clear session state on logout.

## Security Requirements
Sensitive session data must be cleared completely on logout.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/ (providers only)

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
