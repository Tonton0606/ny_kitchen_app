# Authorization — required policy and current gaps

Updated 2026-10-20. Required policy is not a claim of complete enforcement.

| Operation | Admin | Cashier |
|---|---|---|
| Manage users, roles, unlock/reset another account | Allowed | Denied |
| Manage menu/categories | Allowed | Denied |
| View business reports and all audit/transaction records | Allowed | Denied |
| Create orders; view own history and own allowed activity | According to shell workflow | Allowed |
| Change own password | Allowed with identity verification | Allowed with identity verification |
| Void/refund completed sales | Allowed with reason and audit | Denied |
| Backup/restore or database export | Allowed | Denied |

`SessionManager` stores the authenticated role. `GuardedRoute` checks session, forced-change flag, and role after the first frame, then navigates rejected users to login. It currently renders its child while checking. This is not go_router routing.

Inspected user mutation and transaction status methods do not independently establish the acting user's authority. Caller-supplied role/user identifiers are not authorization. Own-record filtering, account revocation and denied-action logs require full caller review.

Plan: central deny-by-default permission checks in business/repository operations, authoritative actor attribution, allowlisted fields, ownership filters, state-transition rules, and pre-render UI guards. Verify direct calls as unauthenticated, Cashier, expired, disabled, and forged-actor callers with no forbidden database changes. See [plan](SECURITY_IMPLEMENTATION_PLAN.md), AT02 and AT05.
