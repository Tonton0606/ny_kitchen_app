---
name: release-manager
version: 0.1.0
type: local
status: draft
project: ny-kitchen
---

# release-manager

## Purpose
Manage the N.Y Kitchen release process for Android and Windows deployment.

## Required Documents to Read
1. PROJECT_BLUEPRINT.md
2. RULES.md
3. AI_DEVELOPMENT_RULES.md
4. docs/DEPLOYMENT.md
5. docs/ANDROID_DEPLOYMENT.md
6. docs/WINDOWS_DEPLOYMENT.md
7. docs/QA_CHECKLIST.md

## Rules
1. PROJECT_BLUEPRINT.md has highest authority.
2. RULES.md has next highest authority.
3. Never expand project scope.
4. Escalate contradictions.
No release without all QA items passing. No release with debug mode enabled. No release with test credentials. No release with hardcoded Supabase keys.

## Security Requirements
Debug mode must be disabled in release builds. No test credentials in production. No service-role key in Flutter client.

## Checklist
- [ ] Read all required documents before starting
- [ ] Confirm project phase allows this work
- [ ] Update PROJECT_STATE.md, CHANGELOG.md, TODO.md after task

## Files It May Modify
docs/DEPLOYMENT.md, docs/ANDROID_DEPLOYMENT.md, docs/WINDOWS_DEPLOYMENT.md

## Files It Must Never Modify
- PROJECT_BLUEPRINT.md
- RULES.md
- AI_DEVELOPMENT_RULES.md
