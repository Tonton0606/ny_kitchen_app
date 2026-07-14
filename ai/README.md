# ai/README.md
# N.Y Kitchen — AI Collaboration System

---

## Purpose
The ai/ directory contains the AI collaboration and context management system for N.Y Kitchen. It defines how AI agents should behave, what to read, and how to coordinate work across sessions.

---

## Required Reading Order

Every AI agent starting a task must read in this order:
1. PROJECT_BLUEPRINT.md (root)
2. RULES.md (root)
3. AI_DEVELOPMENT_RULES.md (root)
4. PROJECT_STATE.md (root)
5. ai/CONTEXT.md — Stable project facts
6. DECISIONS.md (root) — Existing architectural decisions
7. Relevant docs/ files for the specific task

---

## How Agents Use PROJECT_BLUEPRINT.md
- PROJECT_BLUEPRINT.md is the single source of truth.
- No agent instruction, skill, or personal preference may override it.
- If an agent finds a contradiction between the blueprint and any other document, the blueprint wins.
- Report the contradiction instead of silently resolving it.

---

## How Skills Are Selected
- Review the skills/ directory for relevant skill definitions.
- Each skill has a SKILL.md that defines its scope and rules.
- Project rules (PROJECT_BLUEPRINT.md → RULES.md) always override skill instructions.
- Never execute third-party skill scripts without security review.
- See: skills/README.md

---

## How Task Handoffs Work
- Use ai/TASK_HANDOFF.md template when handing a task to another agent.
- Include all required context, scope, files, and acceptance criteria.
- Never assume the next agent has read previous conversation history.

---

## How Architectural Decisions Are Recorded
- All architectural decisions are recorded in DECISIONS.md (root).
- Use the ADR template format.
- Mark unresolved decisions as Pending Review.
- Do not implement features based on unresolved decisions.

---

## File Ownership and Locks
- See: ai/LOCKS.md
- Do not modify files that are claimed by another agent without coordination.

---

## Documentation Updates
- After every approved task, update: PROJECT_STATE.md, CHANGELOG.md, TODO.md.
- Update relevant docs/ files when implementation changes.
- Never let documentation diverge from implementation.
