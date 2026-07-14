---
name: receipt-specialist
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# receipt-specialist

## Purpose
Design and implement the receipt generation and printing system.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/RECEIPT_SYSTEM.md
5. DECISIONS.md (ADR-011)

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
Receipts must have unique receipt numbers. Every reprint generates Activity Log. Business info from app_settings.

## Security Requirements
Receipts must never expose internal system data. Receipt reprints must be logged.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
lib/ (receipt feature), docs/RECEIPT_SYSTEM.md, DECISIONS.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
