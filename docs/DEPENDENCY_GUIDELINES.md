# docs/DEPENDENCY_GUIDELINES.md
# N.Y Kitchen — Dependency Guidelines

---

## Purpose
Control which packages are added and how they are evaluated before use.

---

## Rules
- All packages must be reviewed before being added to pubspec.yaml.
- Packages must be compatible with Android and Windows desktop.
- Prefer packages maintained by the Flutter/Dart team or reputable publishers.
- Avoid packages with no recent maintenance.
- Do not add packages that require native code without testing on all target platforms.

## Confirmed Technology Packages (Blueprint)

| Package | Purpose | Status |
|---|---|---|
| provider | State management | Proposed (ADR-004) |
| go_router | Navigation | Proposed (ADR-005) |
| sqflite or drift | SQLite | Pending Review (ADR-015) |
| printing | Receipt printing | Pending Review (ADR-011) |
| pdf | PDF generation | Pending Review (ADR-011) |
| fl_chart | Charts and analytics | Proposed |

## Security Considerations
- Review package source code for security vulnerabilities before use.
- Avoid packages that request unnecessary permissions.
- Never add packages that embed hardcoded credentials or keys.

---

## TODO
- [ ] Confirm package versions before Phase 2
- [ ] Run dependency security audit before Phase 10
