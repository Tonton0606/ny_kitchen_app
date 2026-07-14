# skills/README.md
# N.Y Kitchen — Skills System

---

## Purpose
The skills/ directory contains AI agent skill definitions for the N.Y Kitchen project. Skills provide structured guidance, rules, and checklists for AI agents performing specific types of work.

---

## Skill Types

| Type | Description |
|---|---|
| Local | Created specifically for this project |
| Imported | Copied from an external repository |
| Forked | Based on an external repository with modifications |
| External | Referenced but not stored locally |

---

## Skill Structure
Each skill lives in its own directory:
```
skills/
└── skill-name/
    └── SKILL.md          (required — primary skill instructions)
    └── README.md         (optional)
    └── examples/         (optional)
    └── templates/        (optional)
    └── references/       (optional)
```

---

## How AI Agents Select a Skill
1. Identify the type of work being performed.
2. Find the matching skill directory in skills/.
3. Read the SKILL.md file completely before starting the task.
4. Follow the skill instructions within the boundaries set by RULES.md and PROJECT_BLUEPRINT.md.

---

## Priority Order (Highest to Lowest)
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/ specialized documentation
5. Skill instructions (SKILL.md)
6. Agent preference or convention

Project rules always override skill instructions.

---

## Security Review Requirement
- All imported and forked skills must be security-reviewed before use.
- Never execute scripts from third-party skills automatically.
- See: skills/CONTRIBUTING.md

---

## How to Add a Skill
See: skills/CONTRIBUTING.md

---

## Skill Registry
See: skills/REGISTRY.md
