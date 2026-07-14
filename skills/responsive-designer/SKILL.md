---
name: responsive-designer
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# responsive-designer

## Purpose
Ensure N.Y Kitchen UI adapts correctly to Android Phone, Android Tablet, and Windows Desktop.

## Primary Responsibilities
See Purpose above.

## Scope
Responsive breakpoints, layout switching, mobile bottom sheet, tablet sidebar, desktop 3-panel.

## Out of Scope
Business logic, authentication.

## Required Context
Before starting any task, read:
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. PROJECT_STATE.md
5. DECISIONS.md
6. docs/RESPONSIVE_GUIDELINES.md
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
Minimum 48dp touch targets on mobile. Tables convert to cards on mobile. Desktop uses 3-panel POS layout.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm current project phase allows this work
- [ ] Verify task is within approved scope
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/ (layout and responsive code)

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
