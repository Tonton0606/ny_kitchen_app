---
name: owasp-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# owasp-specialist

## Purpose
Ensure N.Y Kitchen meets OWASP Secure Coding Principles.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/OWASP_CHECKLIST.md
5. docs/SECURITY.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Complete all OWASP checklist items. No broken access control. No injection. No cryptographic failures. Proper logging.

## Security Requirements
Verify parameterized queries throughout. Verify no credentials exposed. Verify access control at logic layer.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/OWASP_CHECKLIST.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
