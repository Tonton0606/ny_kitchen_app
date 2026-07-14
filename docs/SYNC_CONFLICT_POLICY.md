# docs/SYNC_CONFLICT_POLICY.md
# N.Y Kitchen — Sync Conflict Policy

> Status: PENDING REVIEW — No conflict strategy has been finalized.
> See: DECISIONS.md ADR-014

---

## Purpose
Define how conflicts are handled when local SQLite records and Supabase cloud records disagree.

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
