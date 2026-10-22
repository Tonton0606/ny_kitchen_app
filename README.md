# N.Y Kitchen Secure Order and Sales Management System

> **AI collaborators:** Read [AGENTS.md](AGENTS.md) and [AI_SESSION_HANDOFF.md](AI_SESSION_HANDOFF.md) first. Ask the current session owner's name before starting project work.

> **Single Source of Truth:** [`PROJECT_BLUEPRINT.md`](PROJECT_BLUEPRINT.md)
> **Immutable Rules:** [`RULES.md`](RULES.md)
> **Current Phase:** Security defense planning and verification preparation (2026-10-20).
> **Start here:** [Security implementation and rubric plan](docs/SECURITY_IMPLEMENTATION_PLAN.md) and [session record](SECURITY_DEFENSE_RECORD.md).

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
| Supabase | Optional push/pull synchronization implemented in source; deployment unverified |
| Stateful widgets / singleton services | Current state management |
| Flutter Navigator / GuardedRoute | Current navigation and UI access checks |

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
- **Supabase** — Optional synchronization code exists; cloud policy and immutable-record protection need verification.

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

- Login, Admin, and Cashier screens use local SQLite repositories. Security controls exist but have open findings.
- Supabase push/pull exists in source; live configuration and RLS were not inspected. Hybrid offline/online operation with online synchronization is owner-confirmed scope (2026-10-20).
- The supplied security rubric has 20 criteria worth 100 points. The plan maps each criterion to required evidence; no score is assigned.
- Windows is the recommended base demo. Linux VM and Docker are optional; ZAP is relevant to the HTTP API, while native app controls require direct tests.
- No application code was changed or security tests run during the documentation review.

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

## Ubuntu VM backend (2026-10-22)

The approved Flutter + Ubuntu direction now has a [backend and deployment guide](backend/README.md). This first version provides one-way sales synchronization with device authentication, separate Admin reads, retained revisions, offline retries and a visible status footer. Select `SYNC_BACKEND=ubuntu` after deploying; it is exclusive with the existing direct Supabase mode. VM installation/HTTPS verification remain pending. [Local test evidence](docs/security/evidence/2026-10-defense/backend_verification.md): 11 backend and 4 Flutter tests passed.
