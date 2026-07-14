# docs/NON_FUNCTIONAL_REQUIREMENTS.md
# N.Y Kitchen — Non-Functional Requirements

> Source of Truth: `PROJECT_BLUEPRINT.md` Sections 12, 13, 14

---

## Purpose
Define the quality attributes and constraints the system must satisfy beyond functional behavior.

---

## Security (Highest Priority)
- NFR-SEC-001: Passwords must be hashed using a strong, approved algorithm.
- NFR-SEC-002: The system must prevent SQL injection through parameterized queries.
- NFR-SEC-003: Activity logs must be immutable through the normal interface.
- NFR-SEC-004: Completed transactions must be preserved permanently.
- NFR-SEC-005: Role-based access must be enforced at the logic layer, not only UI.
- NFR-SEC-006: The Supabase service-role key must never be embedded in the Flutter client.
- NFR-SEC-007: Credentials must not be committed to source control.

## Performance
- NFR-PERF-001: Login must complete within 2 seconds.
- NFR-PERF-002: Transaction save must complete within 1 second.
- NFR-PERF-003: Menu loading must complete within 2 seconds.
- NFR-PERF-004: Report generation must complete within 5 seconds.
- NFR-PERF-005: The application must minimize device resource usage.

## Reliability
- NFR-REL-001: The application must operate without internet access.
- NFR-REL-002: The application must not crash on invalid input.
- NFR-REL-003: The application must preserve user data on unexpected errors.
- NFR-REL-004: Database operations must be atomic where possible.

## Usability
- NFR-USE-001: The interface must be usable without training for basic order processing.
- NFR-USE-002: Touch targets must be at least 48dp on mobile devices.
- NFR-USE-003: Error messages must be user-friendly and non-technical.
- NFR-USE-004: The system must support both light and dark themes.

## Compatibility
- NFR-COMP-001: The application must function on Android Phone, Android Tablet, and Windows Desktop from a single codebase.
- NFR-COMP-002: The minimum Android API level must be confirmed (currently assumed API 21).

## Maintainability
- NFR-MAINT-001: The codebase must follow feature-first architecture.
- NFR-MAINT-002: Components must be reusable and not duplicated.
- NFR-MAINT-003: All architectural decisions must be documented in DECISIONS.md.
- NFR-MAINT-004: Documentation must be updated when implementation changes.

## Portability
- NFR-PORT-001: A single Flutter codebase must support all three target platforms.

---

## Open Questions
- [ ] Define specific performance benchmarks with the project owner
- [ ] Confirm accessibility requirements (WCAG level, screen reader support)
