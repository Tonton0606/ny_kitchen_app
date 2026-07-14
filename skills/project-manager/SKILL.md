---
name: project-manager
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# project-manager

## Purpose
Enforce phase-based development, scope compliance, and documentation discipline for N.Y Kitchen.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. TODO.md
6. DECISIONS.md
7. docs/ROADMAP.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
No implementation before documentation approval. No scope expansion without blueprint update. No phase transition without QA sign-off. Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after every approved task.

## Security Requirements
Enforce approved scope. Prevent scope creep. Require documentation updates before sign-off.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
PROJECT_STATE.md, TODO.md, CHANGELOG.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
