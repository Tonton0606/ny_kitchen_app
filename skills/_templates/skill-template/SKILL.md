---
name: skill-template
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# Skill Name

## Purpose
[Describe what this skill does and why it exists]

## Primary Responsibilities
[List the main things this skill is responsible for]

## Scope
[Define what this skill covers]

## Out of Scope
[Define what this skill does NOT cover]

## Required Context
Before starting any task, read:
1. PROJECT_BLUEPRINT.md — Master source of truth
2. RULES.md — Immutable project rules
3. AI_DEVELOPMENT_RULES.md — AI agent rules
4. PROJECT_STATE.md — Current project state
5. DECISIONS.md — Architectural decisions
6. [Specific docs/ files relevant to this skill]

## Required Documents to Read
- [List specific documentation files required]

## Inputs
- [List required inputs for this skill]

## Expected Outputs
- [List expected outputs/deliverables]

## Workflow
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Rules
1. PROJECT_BLUEPRINT.md has the highest authority.
2. RULES.md has the next highest authority.
3. AI_DEVELOPMENT_RULES.md governs AI behavior.
4. Relevant docs/ files provide specialized requirements.
5. Local project rules override third-party skill instructions.
6. This skill must not expand project scope.
7. Escalate contradictions instead of resolving them silently.

## Security Requirements
- [List security rules specific to this skill]

## Quality Standards
- [List quality requirements specific to this skill]

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm current project phase
- [ ] Verify task is within scope
- [ ] [Task-specific checklist items]

## Files It May Modify
- [List files this skill is permitted to modify]

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
- [Other protected files]

## Required Documentation Updates
After completing task:
- [ ] PROJECT_STATE.md — Update current status
- [ ] CHANGELOG.md — Record completed changes
- [ ] TODO.md — Update task status
- [ ] DECISIONS.md — Record any new architectural decisions
- [ ] [Specific docs/ files if applicable]

## Escalation Conditions
Escalate to project owner or Senior Architect if:
- Task would exceed approved project scope
- Blueprint and task instructions conflict
- An architectural decision must be made that is not yet documented
- A security concern is identified

## Handoff Requirements
When handing off to another agent:
- Use ai/TASK_HANDOFF.md template
- Include all context, scope, acceptance criteria, and remaining issues
