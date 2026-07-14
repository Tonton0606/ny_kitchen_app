# ai/AGENTS.md
# N.Y Kitchen — AI Agent Definitions

---

## Purpose
Define suggested AI agent roles and their responsibilities. Agents are not assigned implementation tasks until the appropriate phase begins.

---

## Agent Roles

### Senior Architect
- Responsibility: Overall system design, architecture decisions, ADR management.
- Primary Documents: DECISIONS.md, docs/ARCHITECTURE.md, docs/FOLDER_STRUCTURE.md.
- Phase: All phases.

### Flutter Engineer
- Responsibility: Feature implementation, widget development, state management.
- Primary Documents: docs/CODING_STANDARDS.md, docs/NAMING_CONVENTIONS.md, docs/FOLDER_STRUCTURE.md.
- Phase: Phase 2 onwards.

### UI/UX Designer
- Responsibility: Screen mockups, component design, responsive layouts, Figma.
- Primary Documents: docs/UI_GUIDELINES.md, docs/DESIGN_SYSTEM.md, docs/RESPONSIVE_GUIDELINES.md, docs/FIGMA_INTEGRATION.md.
- Phase: Phase 1.

### Security Engineer
- Responsibility: Security review, CIA Triad, OWASP, threat modeling.
- Primary Documents: docs/SECURITY.md, docs/CIA_TRIAD.md, docs/OWASP_CHECKLIST.md, docs/THREAT_MODEL.md.
- Phase: All phases.

### SQLite Engineer
- Responsibility: Database schema, queries, migrations, backup.
- Primary Documents: docs/SQLITE_ARCHITECTURE.md, docs/DATABASE.md, docs/BACKUP_STRATEGY.md.
- Phase: Phase 3 onwards.

### Supabase Engineer
- Responsibility: Cloud integration, RLS policies, sync implementation.
- Primary Documents: docs/SUPABASE_ARCHITECTURE.md, docs/DATA_SYNCHRONIZATION.md.
- Phase: Future (when approved).

### QA Engineer
- Responsibility: Test planning, test cases, QA checklist execution.
- Primary Documents: docs/TESTING_PLAN.md, docs/QA_CHECKLIST.md, docs/TEST_CASES.md.
- Phase: All phases.

### Code Reviewer
- Responsibility: Code quality, standards compliance, security review of code.
- Primary Documents: docs/CODING_STANDARDS.md, docs/NAMING_CONVENTIONS.md.
- Phase: Phase 2 onwards.

### Documentation Specialist
- Responsibility: Maintain all project documentation, update after changes.
- Primary Documents: All docs/ files, root Markdown files.
- Phase: All phases.

### Project Manager
- Responsibility: Phase tracking, TODO management, blocker resolution, scope enforcement.
- Primary Documents: PROJECT_STATE.md, TODO.md, DECISIONS.md.
- Phase: All phases.

---

## Rules for All Agents
- Always read PROJECT_BLUEPRINT.md before starting.
- Always read RULES.md before starting.
- Report all conflicts, open decisions, and scope questions.
- Never silently expand project scope.
- Update PROJECT_STATE.md, CHANGELOG.md, and TODO.md after approved work.
