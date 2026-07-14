# N.Y Kitchen Secure Order and Sales Management System

> **Single Source of Truth:** [`PROJECT_BLUEPRINT.md`](PROJECT_BLUEPRINT.md)
> **Immutable Rules:** [`RULES.md`](RULES.md)
> **Current Phase:** Phase 1 — Static UI/UX Prototype and Documentation Preparation

---

## Project Purpose

N.Y Kitchen is a **secure, offline-first Point of Sale and Sales Management System** built for a small food stall. It replaces manual order recording and handwritten logs with a digital solution focused on **security, accountability, and ease of use**.

The system demonstrates practical implementation of Information Assurance and Security principles through secure software design.

---

## Target Platforms

| Platform | Status |
|---|---|
| Android Phone | Planned |
| Android Tablet | Planned |
| Windows Desktop | Planned |

---

## Core Technologies

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI framework |
| Dart | Programming language |
| Material 3 | UI design system |
| SQLite | Primary local database (offline-first) |
| Supabase | Optional cloud backup and sync (future) |
| Provider | State management |
| go_router | Navigation and route guards |

---

## User Roles

Only **two roles** exist in this system:

| Role | Responsibilities |
|---|---|
| **Administrator** | Full system control — dashboard, menu, users, transactions, reports, activity logs, backup & restore |
| **Cashier** | Order processing — new order, checkout, receipt printing, personal transaction history |

> No other roles are permitted. See [`docs/USER_ROLES.md`](docs/USER_ROLES.md).

---

## Architecture

- **Offline-first** — All core features work without internet access.
- **Feature-first Flutter architecture** — Code organized by feature module.
- **Repository pattern** — Clean separation of data access from business logic.
- **Service layer** — Business logic separated from UI widgets.
- **SQLite** — Primary local database. Never removed.
- **Supabase** — Optional future cloud platform for backup and synchronization.

---

## Security Priorities

- **CIA Triad** — Confidentiality, Integrity, Availability built into every layer.
- **OWASP Secure Coding Principles** — Applied throughout development.
- **ISO/IEC 25010** — Primary software quality evaluation model.
- Password hashing, session management, account lockout, immutable audit logs.

---

## Project Structure

```
ny_kitchen_app/
├── PROJECT_BLUEPRINT.md   ← Single source of truth
├── RULES.md               ← Immutable project rules
├── AI_DEVELOPMENT_RULES.md ← AI agent rules
├── PROJECT_STATE.md       ← Current phase and status
├── CHANGELOG.md           ← Change history
├── TODO.md                ← Task tracker
├── DECISIONS.md           ← Architecture Decision Records
├── .aiignore              ← AI context exclusions
│
├── docs/                  ← Full project documentation
├── ai/                    ← AI collaboration system
├── skills/                ← AI skill definitions
│
├── lib/                   ← Flutter application source
├── android/               ← Android platform files
├── windows/               ← Windows platform files
├── pubspec.yaml           ← Flutter dependencies
└── test/                  ← Tests
```

---

## Documentation Index

| Document | Purpose |
|---|---|
| [`PROJECT_BLUEPRINT.md`](PROJECT_BLUEPRINT.md) | Master project specification |
| [`RULES.md`](RULES.md) | Immutable rules |
| [`DECISIONS.md`](DECISIONS.md) | Architecture Decision Records |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Phase-by-phase development plan |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | System architecture overview |
| [`docs/SQLITE_ARCHITECTURE.md`](docs/SQLITE_ARCHITECTURE.md) | Local database design |
| [`docs/SUPABASE_ARCHITECTURE.md`](docs/SUPABASE_ARCHITECTURE.md) | Optional cloud platform |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Security framework |
| [`docs/USER_ROLES.md`](docs/USER_ROLES.md) | Role definitions and permissions |
| [`docs/UI_GUIDELINES.md`](docs/UI_GUIDELINES.md) | UI design guidelines |
| [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) | Design tokens and components |
| [`ai/README.md`](ai/README.md) | AI collaboration system |
| [`skills/README.md`](skills/README.md) | Skills system |

---

## Current Status

- **Phase 1 — Documentation preparation in progress.**
- No application features have been implemented yet.
- Documentation review is required before Phase 1 UI prototype begins.

---

## Important Rules

1. Read `PROJECT_BLUEPRINT.md` before any task.
2. Never introduce Inventory Management.
3. Only Admin and Cashier roles are permitted.
4. SQLite is the primary local database — do not remove it.
5. Application must work offline.
6. Security is the highest priority.
7. Completed transactions must never be permanently deleted.
8. Activity logs are immutable through the normal interface.

---

*See [`RULES.md`](RULES.md) for the complete rule set.*
