# docs/DATABASE.md
# N.Y Kitchen — Database Overview

> Source of Truth: PROJECT_BLUEPRINT.md Section 10

---

## Purpose
Provide a high-level overview of the N.Y Kitchen database architecture. See specialized documents for details.

---

## Primary Database: SQLite (Local, Offline-First)
- Stores all application data locally on the device.
- Operates without internet access.
- See: docs/SQLITE_ARCHITECTURE.md

## Optional Cloud Database: Supabase/PostgreSQL (Future)
- Optional cloud backup and synchronization.
- Not required for core functionality.
- See: docs/SUPABASE_ARCHITECTURE.md

## Database Design Principles
- Normalize related data with foreign keys.
- Preserve historical transactions (never delete).
- Store image paths, not image binary data.
- Use parameterized queries for all operations.
- Support backup and restore.

## Approved Tables (SQLite)
- users
- food_categories
- food_items
- transactions
- transaction_items
- activity_logs
- login_attempts
- app_settings
- backup_records

---

## Security Considerations
- Parameterized queries required on all database operations.
- Database file stored in application documents directory with restricted access.
- Backup files must not contain plain-text passwords.
