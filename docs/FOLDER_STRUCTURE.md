# docs/FOLDER_STRUCTURE.md
# N.Y Kitchen — Folder Structure

> Source of Truth: `PROJECT_BLUEPRINT.md` Section 18 (Architecture)

---

## Purpose
Define the approved feature-first folder structure for the Flutter application. This structure must be followed by all developers and AI agents.

---

## Proposed Structure

`
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   ├── enums/
│   ├── errors/
│   ├── extensions/
│   ├── theme/
│   ├── router/
│   └── widgets/          ← Shared reusable widgets
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── providers/
│   │
│   ├── dashboard/
│   ├── menu/
│   ├── transactions/
│   ├── receipts/
│   ├── users/
│   ├── activity_logs/
│   ├── reports/
│   ├── settings/
│   └── backup/
│
├── data/
│   ├── database/         ← SQLite initialization and migrations
│   ├── repositories/     ← Repository implementations
│   └── models/           ← Data models
│
└── services/             ← Application-wide services
    ├── activity_log_service.dart
    ├── auth_service.dart
    └── sync_service.dart  (Future)
`

---

## Rules
- Do not place feature-specific code in core/ or shared areas.
- Do not create additional top-level directories without architectural review.
- Shared widgets must be placed in core/widgets/.
- Do not duplicate models across features.

---

## Status
Pending Review — To be finalized before Phase 2 implementation begins.

---

## TODO
- [ ] Finalize and confirm folder structure before Phase 2
- [ ] Update this document when structure is confirmed
