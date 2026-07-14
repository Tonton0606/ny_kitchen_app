---
name: security-testing-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# security-testing-specialist

## Purpose
Execute security testing for N.Y Kitchen against OWASP and CIA Triad controls.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/SECURITY_TESTING.md
5. docs/OWASP_CHECKLIST.md
6. docs/CIA_TRIAD.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Test all OWASP checklist items. Test SQL injection attempts. Test unauthorized access attempts. Test password storage. Test session expiration.

## Security Requirements
Security tests must not be destructive to production data. Document all findings.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/SECURITY_TESTING.md, docs/OWASP_CHECKLIST.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
