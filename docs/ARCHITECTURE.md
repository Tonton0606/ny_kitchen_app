# docs/ARCHITECTURE.md
# N.Y Kitchen — System Architecture

> Source of Truth: `PROJECT_BLUEPRINT.md` Section 18
> Confirmed Decisions: See `DECISIONS.md` ADR-006, ADR-007, ADR-008

---

## Purpose
Document the overall system architecture and the design patterns used in N.Y Kitchen.

---

## Architecture Style
**Offline-First, Feature-First Flutter Application**

---

## Layer Overview

`
UI Layer (Flutter Widgets, Screens)
        ↓ calls
Provider Layer (State Management)
        ↓ calls
Service Layer (Business Logic, Validation, Activity Logging)
        ↓ calls
Repository Layer (Data Access Abstraction)
        ↓ implements
SQLite Repository (Local) | Supabase Repository (Cloud - Future)
`

---

## Feature-First Folder Structure
Code is organized by feature, not by layer. Each feature contains its own screens, providers, repositories, and services. Shared components live in core/.

See: `docs/FOLDER_STRUCTURE.md`

---

## Repository Pattern
- Repository interfaces define data access contracts.
- SQLite repositories implement local data access.
- Future Supabase repositories may implement the same interfaces.
- Services never access the database directly.

---

## Service Layer
- Contains all business logic.
- Handles validation before writing to repositories.
- Triggers Activity Log entries for all tracked events.
- Services do not interact with the database directly.

---

## State Management
- Provider (see `DECISIONS.md` ADR-004 - Proposed)
- Providers hold application state and call services.
- UI rebuilds reactively when provider state changes.

---

## Navigation
- go_router (see `DECISIONS.md` ADR-005 - Proposed)
- Declarative routing with route guards for role-based access control.
- Unauthorized access redirects to the Unauthorized page.

---

## Security Architecture
- Role-based access enforced at router and service layers.
- All database operations use parameterized queries.
- Passwords hashed before storage (algorithm TBD - ADR-013).
- Activity logs generated automatically by the service layer.

---

## Open Questions
- [ ] Confirm Provider vs alternatives before Phase 2 (ADR-004)
- [ ] Confirm go_router version before Phase 2 (ADR-005)
- [ ] Confirm SQLite package before Phase 3 (ADR-015)
