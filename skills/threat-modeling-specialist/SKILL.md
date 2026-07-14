---
name: threat-modeling-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# threat-modeling-specialist

## Purpose
Maintain and update the N.Y Kitchen threat model.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/THREAT_MODEL.md
5. docs/SECURITY.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Identify threats, assess risk, define mitigations, record residual risks.

## Security Requirements
All high-impact threats must have documented mitigations before Phase 10.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/THREAT_MODEL.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
