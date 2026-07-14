# docs/STATE_MANAGEMENT.md
# N.Y Kitchen — State Management

> Technology: Provider (see DECISIONS.md ADR-004 - Proposed)

---

## Purpose
Document the state management approach and provider design patterns.

---

## Proposed Provider Structure

| Provider | Responsibility |
|---|---|
| AuthProvider | Current user session, role, login state |
| OrderProvider | Current order items, totals, payment method |
| MenuProvider | Food items, categories, filters |
| TransactionProvider | Transaction history, filters |
| ActivityLogProvider | Activity log entries and filters |
| ReportProvider | Report data and date ranges |
| SettingsProvider | App settings, theme preference |
| BackupProvider | Backup history and status |

---

## Rules
- Providers call services, not repositories directly.
- Providers do not contain business logic.
- Providers do not access SQLite directly.
- State must be initialized safely (handle null, loading, and error states).

---

## Security Considerations
- Sensitive session data must be cleared on logout.
- Providers must not retain state across sessions.

---

## TODO
- [ ] Confirm Provider vs Riverpod before Phase 2 (ADR-004)
- [ ] Document provider initialization order
