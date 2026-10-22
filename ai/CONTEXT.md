# ai/CONTEXT.md

> 2026-10-20 reconciliation: The phase, future-cloud and proposed navigation entries below are historical. Current source has SQLite repositories, Navigator, in-memory sessions and optional Supabase push/pull. Use ../SECURITY_DEFENSE_RECORD.md and ../docs/SECURITY_IMPLEMENTATION_PLAN.md for this defense session.
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
- Project Phase 1: Static UI/UX Prototype (implemented)
- LUMORA Phase 4: Validate (CURRENT)
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

## Color Palette (Phase 1 implementation)
- Primary seed: Deep amber-yellow (`#FFB300`)
- Tertiary: Dark amber (`#7C5800`)
- Semantic success: Green (`#2E7D32`)
- Semantic info: Blue (`#1565C0`)
- Material 3 `ColorScheme.fromSeed` is implemented in `lib/core/theme/app_theme.dart`.
- Text: Black
