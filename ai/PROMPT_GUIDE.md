# ai/PROMPT_GUIDE.md
# N.Y Kitchen — AI Prompt Guide

---

## Purpose
Provide effective prompt patterns for working with AI agents on this project.

---

## Standard Task Prompt Pattern

```
Read PROJECT_BLUEPRINT.md, RULES.md, and AI_DEVELOPMENT_RULES.md first.
Then read PROJECT_STATE.md and DECISIONS.md.
Then read [specific docs/ file relevant to this task].

Task: [Specific task description]

Scope: [What to do]
Out of Scope: [What NOT to do]
Phase: [Current phase]

Required outputs:
- [Output 1]
- [Output 2]

Update PROJECT_STATE.md, CHANGELOG.md, and TODO.md after completing the task.
Record any new architectural decisions in DECISIONS.md.
Report all conflicts, open questions, and security concerns.
```

---

## Documentation Setup Prompt
Use when setting up documentation for a new phase.

## Feature Implementation Prompt
Use when implementing a specific feature. Always specify the phase and cite the relevant blueprint sections.

## Security Review Prompt
Use when performing a security audit. Always reference docs/SECURITY.md, docs/CIA_TRIAD.md, and docs/OWASP_CHECKLIST.md.

## Architecture Decision Prompt
Use when evaluating architectural options. Reference existing ADRs in DECISIONS.md before creating new ones.

---

## Rules for Prompts
- Always reference the project phase.
- Always include scope and out-of-scope boundaries.
- Always request documentation updates in the output.
- Always request conflict and open-decision reporting.
