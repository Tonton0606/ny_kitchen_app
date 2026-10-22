# docs/SYNC_CONFLICT_POLICY.md
# N.Y Kitchen — Sync Conflict Policy

> Status: Partial sale-ID collision handling implemented; broader sync conflict rules remain pending review.
> See: DECISIONS.md ADR-014

---

## Purpose
Define how conflicts are handled when local SQLite records and Supabase cloud records disagree.

## Implemented Sale ID Collision Handling — 2026-10-23

- New offline sales and transaction items use signed 63-bit IDs composed from a random per-installation namespace and a local monotonic counter. The namespace and counter remain in local-only `app_settings`; neither is sent to the cloud.
- New receipt numbers include the generated transaction ID, so receipts stay distinct when devices sell during the same second. The daily `order_number` remains a local sequence and can repeat across devices; screens should retain the receipt as the stable display identifier.
- Before transaction upserts and during pulls, the client compares records sharing a numeric ID by receipt, creation time, total, discount, and payment method. If they are different sales, it moves the local transaction and all local line items to newly generated IDs before inserting the cloud row. This prevents an old local ID collision from silently replacing either sale.
- This repair can recover a distinct sale only while at least one device still has its local row. It cannot reconstruct data that has already been overwritten or deleted on every device.
- Cloud `transactions.id` and `transaction_items.id` columns, plus `transaction_items.transaction_id`, must be PostgreSQL `bigint` before this client change is deployed. Verify with `docs/security/supabase_transaction_id_diagnostic.sql` in a development project. No live schema change or sync validation is recorded here.
- This handles row identity collisions only. Concurrent status edits, menu/account conflicts, retries, and broader append-only semantics remain pending ADR-014 review.

---

## Conflict Scenarios

### Local Record Newer Than Cloud
- Proposed: Local record wins (offline-first principle).
- Decision: PENDING REVIEW.

### Cloud Record Newer Than Local
- Proposed: Cloud record wins if device was offline.
- Decision: PENDING REVIEW.

### Simultaneous Updates (Two Devices)
- Proposed: Last-write-wins, or flag for manual review.
- Decision: PENDING REVIEW.

### Duplicate Transaction Prevention
- Transactions must use unique receipt numbers.
- Same receipt number arriving twice must be rejected as duplicate.

### Immutable Records (Activity Logs, Completed Transactions)
- RULE: Immutable records must NEVER be overwritten by sync.
- Cloud sync must only append new records, never modify existing ones.

### Device Clock Differences
- Use server-side timestamps from Supabase where possible.
- Document clock sync requirements.

### Archived Food Item Conflicts
- Archived items in local SQLite must remain archived even if cloud has active status.
- Decision: PENDING REVIEW.

### Restored Backup Conflicts
- After a backup restore, all records may need re-sync review.
- Strategy: Mark all records as pending-review after restore.

---

## Conflict Audit Trail
- All resolved conflicts must be recorded in the Activity Log.
- Conflict resolution must never silently discard data.

---

## Open Decisions
- [ ] ADR-014: Final conflict resolution strategy (Pending Review)
- [ ] Define manual conflict review interface (if any)

---

## TODO
- [ ] Define and record conflict resolution decision before Supabase sync implementation
