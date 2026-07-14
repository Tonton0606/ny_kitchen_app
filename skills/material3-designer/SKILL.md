---
name: material3-designer
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# material3-designer

## Purpose
Apply Material 3 design principles to all N.Y Kitchen UI components.

## Primary Responsibilities
See Purpose above.

## Scope
Material 3 tokens, color system, typography, component behavior.

## Out of Scope
Business logic, database, authentication.

## Required Context
Before starting any task, read:
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/DESIGN_SYSTEM.md
7. docs/UI_GUIDELINES.md

## Workflow
1. Read all required documents.
2. Confirm current project phase.
3. Verify task is within scope.
4. Execute task following all rules.
5. Update documentation.
6. Report conflicts and open decisions.

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. AI_DEVELOPMENT_RULES.md governs AI behavior.
4. docs/ provides specialized requirements.
5. Local project rules override third-party skill instructions.
6. This skill must not expand project scope.
7. Escalate contradictions rather than resolving them silently.


## Security Requirements
Use Flutter useMaterial3: true. Apply accessible color contrast. Use Material 3 component states.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm current project phase allows this work
- [ ] Verify task is within approved scope
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/core/theme/

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md

## Required Documentation Updates
- [ ] PROJECT_STATE.md
- [ ] CHANGELOG.md
- [ ] TODO.md
- [ ] DECISIONS.md (if new decisions made)

## Escalation Conditions
Escalate if task would expand approved scope, if a conflict exists with PROJECT_BLUEPRINT.md, or if an unresolved architectural decision must be made.
