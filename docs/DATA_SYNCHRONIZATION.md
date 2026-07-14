# docs/DATA_SYNCHRONIZATION.md
# N.Y Kitchen — Data Synchronization

> Status: FUTURE/OPTIONAL
> See: DECISIONS.md ADR-012

---

## Purpose
Define the strategy for synchronizing local SQLite data with Supabase when internet is available.

---

## Offline-First Write Strategy
- All writes go to SQLite first.
- Records are marked with sync_status: pending when created while offline.
- Sync is performed when internet connectivity is detected.

## Pending Synchronization Queue
- A sync queue (SQLite table or in-memory queue) tracks pending records.
- Each queued record includes: entity type, entity ID, action (create/update), timestamp.
- TODO: Define sync_queue table schema before Supabase integration.

## Synchronization Status
- pending: Created locally, not yet synced.
- synced: Successfully synchronized with Supabase.
- failed: Sync attempted but failed.
- conflict: Conflict detected, requires resolution.

## Retry Policy
- Retry failed syncs on next connectivity event.
- Exponential backoff for repeated failures.
- TODO: Define maximum retry count and fallback behavior.

## Duplicate Prevention
- Use unique identifiers (UUID or composite keys) to prevent duplicate cloud records.
- TODO: Define duplicate detection strategy.

## Device Identification
- Each installation generates a unique device ID.
- Device ID is included in synced records for traceability.

## Immutable Records (Activity Logs, Completed Transactions)
- Activity logs are append-only — never updated or deleted in cloud.
- Completed transactions are never modified after sync.

## Network Detection
- Use Flutter connectivity_plus package (or equivalent) to detect network state.
- Do not depend on continuous connectivity for any core feature.

---

## Open Decisions
- [ ] ADR-012: Synchronization strategy (Pending Review)
- [ ] Which entities to synchronize?
- [ ] Manual vs automatic sync behavior?
- [ ] Sync queue table schema?

---

## TODO
- [ ] Define sync entity list with project owner
- [ ] Define sync queue schema
- [ ] Implement network detection service
- [ ] Implement retry policy
