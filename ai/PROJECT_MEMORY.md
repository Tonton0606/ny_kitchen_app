# ai/PROJECT_MEMORY.md
# N.Y Kitchen — AI Project Memory

> This file stores approved long-term project decisions for AI agent continuity.
> Only CONFIRMED and APPROVED decisions are recorded here.
> For architectural decisions, see DECISIONS.md (root).

---

## Confirmed Technology Decisions

| Decision | Value | Confirmed By |
|---|---|---|
| Primary database | SQLite | PROJECT_BLUEPRINT.md |
| Cloud platform | Supabase (optional, future) | PROJECT_BLUEPRINT.md |
| Architecture | Offline-first, Feature-first | PROJECT_BLUEPRINT.md |
| UI framework | Material 3 | PROJECT_BLUEPRINT.md |
| State management | Provider (proposed) | ADR-004 (Proposed) |
| Navigation | go_router (proposed) | ADR-005 (Proposed) |

---

## Confirmed Scope Exclusions

| Excluded Feature | Source |
|---|---|
| Inventory Management | PROJECT_BLUEPRINT.md Section 4 |
| Supplier Management | PROJECT_BLUEPRINT.md Section 4 |
| Customer Accounts | PROJECT_BLUEPRINT.md Section 4 |
| Delivery Tracking | PROJECT_BLUEPRINT.md Section 4 |
| Online Ordering | PROJECT_BLUEPRINT.md Section 4 |
| Multi-branch Support | PROJECT_BLUEPRINT.md Section 4 |

---

## Pending Decisions (Do Not Implement Until Resolved)

| Decision | Status | ADR |
|---|---|---|
| Supabase integration scope | Pending Review | ADR-002 |
| Password hashing algorithm | Pending Review | ADR-013 |
| SQLite package (sqflite vs drift) | Pending Review | ADR-015 |
| Backup storage location | Pending Review | ADR-016 |
| Receipt generation packages | Pending Review | ADR-011 |
| Sync conflict strategy | Pending Review | ADR-014 |
