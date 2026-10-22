# Backup and restore — baseline and proposed correction

Updated 2026-10-20. The inspected `BackupRepository.exportDatabase()` writes MySQL-style SQL INSERT statements for local tables into a temporary `.sql` file. It includes stored user data, does not encrypt the export, and logs a placeholder Admin ID. This is not the SQLite file-copy recovery process previously described in ADR-016. A successful restore has not been demonstrated.

Proposed implementation: Admin-only consistent SQLite snapshot, protected authenticated backup container, documented key recovery, genuine actor audit, and retention approved with the client. If relying on OS encryption, document that copied exports may lose that protection. Optional cloud synchronization is not a substitute for an independently recoverable backup.

Restore into a temporary location first. Check authentication, format/schema compatibility, integrity and foreign-key consistency. Pause writes and sync, keep the existing database as a rollback copy, perform replacement, reopen/validate, and record the outcome. Corrupt or wrong-key input must leave the working data intact.

Proposed rehearsal targets: recovery point no older than 24 hours and recovery time at most 15 minutes. These are project targets awaiting acceptance and measurement, not statutory requirements or achieved results.

See [implementation plan](SECURITY_IMPLEMENTATION_PLAN.md), K03 and AT08. Cross-device recovery must account for device-bound biometric encryption keys.
