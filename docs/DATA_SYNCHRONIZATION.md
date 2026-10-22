# docs/DATA_SYNCHRONIZATION.md
# N.Y Kitchen — Data Synchronization

> Status: PARTIALLY IMPLEMENTED — Cloud round trips and conflict recovery remain unverified.
> See: DECISIONS.md ADR-012

---

## Purpose
Define the strategy for synchronizing local SQLite data with Supabase when internet is available.

## Current Transaction Identity Control

New sales and their line items receive device-scoped signed 64-bit IDs from `SyncIdGenerator`. The installation namespace and counter are stored only in local `app_settings`. Receipt numbers include the sale ID suffix, while daily order numbers remain local display sequences.

For legacy data, Supabase synchronization compares rows with the same transaction ID. If the receipt and sale fields show they are different transactions, the client rekeys the local transaction and its child items before upload or insert. See `docs/SYNC_CONFLICT_POLICY.md` for limits and schema requirements. This is implemented in source but has not been tested across two devices or against the live database.

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
