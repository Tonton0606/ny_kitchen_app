# ai/CONTEXT.md
# N.Y Kitchen — Stable Project Facts

> This file contains only confirmed, stable project facts.
> Do not add unresolved decisions or speculative information here.
> Update only when a fact changes with blueprint approval.

---

## Project Identity
- **Project Name:** N.Y Kitchen Secure Order and Sales Management System
- **Type:** Offline-first POS and Sales Management System
- **Platforms:** Android Phone, Android Tablet, Windows Desktop

## Technology Stack (Confirmed)
- **Framework:** Flutter / Dart
- **UI:** Material 3
- **Local Database:** SQLite (primary, permanent)
- **Cloud Platform:** Supabase (optional, future)
- **Architecture:** Feature-first, Repository Pattern, Service Layer
- **State Management:** Provider (proposed, see ADR-004)
- **Navigation:** go_router (proposed, see ADR-005)

## User Roles (Immutable)
- **Administrator** — Full system control
- **Cashier** — Order processing only
- **No other roles exist or may be added without blueprint approval.**

## Key Business Rules (Immutable)
- Completed transactions are NEVER permanently deleted.
- Activity logs are IMMUTABLE through the normal interface.
- Inventory Management is EXCLUDED from scope.
- The application must work OFFLINE without internet.
- SQLite must remain the primary local database.
- Supabase service-role key must NEVER be in the Flutter client.

## Development Phases
- Phase 1: Static UI/UX Prototype (CURRENT)
- Phase 2: Architecture Setup
- Phase 3: SQLite Integration
- Phase 4: Authentication
- Phase 5: Menu Management
- Phase 6: Sales Module
- Phase 7: User Management
- Phase 8: Activity Logs
- Phase 9: Reports
- Phase 10: Security Hardening and QA
- Phase 11: Deployment and Defense

## Color Palette (Provisional)
- Primary: Yellow
- Secondary: Red
- Surface: White
- Text: Black
