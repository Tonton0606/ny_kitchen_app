# skills/CONTRIBUTING.md
# N.Y Kitchen — Skills Contributing Guide

---

## Naming Convention
- Folder names: lowercase-kebab-case
- Primary skill file: SKILL.md (always this exact name)
- One skill per directory

## Required SKILL.md Structure

Every SKILL.md must start with YAML front matter:

```yaml
---
name: skill-name
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---
```

Then include these sections:
- Purpose
- Primary Responsibilities
- Scope
- Out of Scope
- Required Context
- Required Documents to Read
- Inputs
- Expected Outputs
- Workflow
- Rules
- Security Requirements
- Quality Standards
- Checklist
- Files It May Modify
- Files It Must Never Modify
- Required Documentation Updates
- Escalation Conditions
- Handoff Requirements

## Versioning
- Start at 0.1.0 (Draft)
- Increment to 1.0.0 when approved
- Use semantic versioning

## Security Review
- All skills must be reviewed for security before use in production tasks.
- Third-party skill scripts must never be auto-executed without review.
- Record security review completion in REGISTRY.md.

## Registry Updates
- Every new skill must be added to REGISTRY.md.
- Every imported or forked skill must include attribution.
- License files must be preserved.

## Approval Process
1. Create skill in skills/skill-name/SKILL.md.
2. Add to REGISTRY.md with Status: Draft.
3. Conduct security review.
4. Update REGISTRY.md to Status: Under Review.
5. Project Manager approves.
6. Update REGISTRY.md to Status: Approved.

## Deprecation
- Mark deprecated skills in REGISTRY.md: Status: Deprecated.
- Do not delete deprecated skills immediately — retain for reference.
- Update agents to stop using deprecated skills.
