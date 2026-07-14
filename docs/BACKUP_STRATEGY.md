# docs/BACKUP_STRATEGY.md
# N.Y Kitchen — Backup and Restore Strategy

> See: DECISIONS.md ADR-016

---

## Purpose
Define how database backups are created, stored, and restored.

---

## Backup Method
- SQLite backup: Copy the .db file to a backup directory.
- The backup file preserves the complete database state.

## Backup Storage Locations (Pending Review)
- Android: TODO — Define target directory (Downloads, external storage, app documents)
- Windows: TODO — Define target directory (Documents folder, application directory)

## Backup Naming
- Proposed format: ny_kitchen_backup_YYYYMMDD_HHMMSS.db
- Unique timestamp ensures no overwriting.

## Backup Retention
- TODO: Define maximum number of backup versions to retain.

## Restore Process
1. Select backup file.
2. Confirm restore (destructive action — confirm dialog required).
3. Copy backup file to replace active database.
4. Verify database integrity after restore.
5. Restart database connection.
6. Generate Activity Log entry.

## Rules
- The existing database must be preserved until restoration is confirmed successful.
- All backup and restore actions must generate Activity Log entries.
- Backup files should not contain plain-text passwords.

## Cloud Backup (Future Optional)
- Store backup files in Supabase Storage.
- Requires Supabase integration approval (ADR-002).

---

## Open Questions
- [ ] Backup encryption: Required? (ADR-016)
- [ ] Storage location per platform: Android and Windows (ADR-016)
- [ ] Maximum backup retention count?

---

## TODO
- [ ] Confirm backup strategy decisions before Phase 3
