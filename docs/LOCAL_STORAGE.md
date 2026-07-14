# docs/LOCAL_STORAGE.md
# N.Y Kitchen — Local Storage

---

## Purpose
Document what is stored locally, where, and how.

---

## Storage Locations

| Data Type | Location | Method |
|---|---|---|
| SQLite database | App documents directory | path_provider |
| Food images (default) | assets/images/foods/ | Flutter assets |
| Food images (uploaded) | App documents directory/images/ | File copy |
| Database backups | App documents directory/backups/ | File copy |
| Receipts (PDF) | App documents directory/receipts/ | Future enhancement |
| App settings | SQLite app_settings table | Database |

## Rules
- Never store plain-text passwords in any file.
- Never store the Supabase service-role key in local storage.
- Backup files must not contain sensitive unencrypted data (review before implementation).
- Image paths stored in SQLite, not image binary data.

---

## TODO
- [ ] Confirm backup file storage location for Android and Windows (ADR-016)
- [ ] Confirm whether backups should be encrypted
