# docs/ROUTING.md
# N.Y Kitchen — Routing and Navigation

> Technology: go_router (see DECISIONS.md ADR-005 - Proposed)

---

## Purpose
Define the navigation structure, route paths, and access control rules.

---

## Route Structure (Proposed)

| Route | Description | Access |
|---|---|---|
| /login | Login screen | Public |
| /unauthorized | Unauthorized access page | Public |
| /admin | Admin root (redirect to /admin/dashboard) | Admin only |
| /admin/dashboard | Admin Dashboard | Admin only |
| /admin/transactions | Transaction management | Admin only |
| /admin/menu | Menu management | Admin only |
| /admin/users | User management | Admin only |
| /admin/activity-logs | Activity logs viewer | Admin only |
| /admin/reports | Reports | Admin only |
| /admin/settings | Admin account settings | Admin only |
| /admin/backup | Backup and restore | Admin only |
| /cashier | Cashier root | Cashier only |
| /cashier/orders | New order / POS | Cashier only |
| /cashier/transactions | Cashier transaction history | Cashier only |
| /cashier/settings | Cashier account settings | Cashier only |

---

## Route Guard Rules
- Unauthenticated users must be redirected to /login.
- Cashier users attempting Admin routes must be redirected to /unauthorized.
- Admin users attempting Cashier-only routes: document expected behavior (TBD).
- Unauthorized access must generate an Activity Log entry.

---

## Security Considerations
- Route guards are enforced at the go_router level.
- Role checks must also be enforced at the service layer.
- Do not rely solely on route guards for security.

---

## Open Questions
- [ ] Confirm Admin user accessing /cashier routes - redirect to /admin/dashboard?
- [ ] Confirm deeplink requirements (if any)

---

## TODO
- [ ] Implement route guards before Phase 4 (Authentication)
