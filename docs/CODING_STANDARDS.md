# docs/CODING_STANDARDS.md
# N.Y Kitchen — Coding Standards

---

## Purpose
Define coding standards and conventions for all Flutter/Dart development.

---

## General Rules
- Follow Dart best practices and the official Dart style guide.
- Use strong typing. Avoid `dynamic` unless absolutely necessary.
- Prefer immutable data structures where practical.
- Keep functions small and focused on a single responsibility.
- Avoid code duplication — extract reusable components.

## Dart Formatting
- Run `dart format` before committing.
- Maximum line length: 80 characters (configurable in `analysis_options.yaml`).

## Error Handling
- Never swallow errors silently.
- Log errors through the Activity Log service or a crash reporter.
- Display user-friendly messages. Never expose stack traces to users.

## Comments and Documentation
- Add doc comments (`///`) to all public classes, methods, and properties.
- Explain WHY, not WHAT (code should explain what; comments explain why).

## Security Rules
- Never use raw string concatenation for SQL queries. Use parameterized queries.
- Never store passwords as plain text.
- Never log sensitive data (passwords, tokens) in log output.

## Testing
- Write unit tests for all service and repository methods.
- Write widget tests for critical UI flows.
- Follow the testing plan in `docs/TESTING_PLAN.md`.

---

## TODO
- [ ] Add specific lint rules to `analysis_options.yaml` before Phase 2
