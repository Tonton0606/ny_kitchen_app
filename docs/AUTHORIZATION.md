# docs/AUTHORIZATION.md
# N.Y Kitchen — Authorization

---

## Purpose
Define authorization rules for each user role and how access control is enforced.

---

## Authorization Approach
- Role-Based Access Control (RBAC).
- Role is stored in the SQLite users table.
- Role is loaded into the AuthProvider at login.
- go_router route guards check the role before allowing navigation.
- Service layer re-validates role for sensitive operations.

## Admin Authorized Operations
- Full access to all modules listed in docs/USER_ROLES.md.
- Void and refund transactions.
- Manage user accounts.
- View all Activity Logs.
- Access Backup and Restore.

## Cashier Authorized Operations
- New order / POS screen.
- Own transaction history only.
- Account settings (change own password only).
- Reprint own receipts (with Activity Log).

## Enforcement Layers
1. go_router route guards (UI layer).
2. Service layer role checks (logic layer).
3. SQLite queries filtered by user_id where applicable.

## Unauthorized Access Handling
- Redirect to /unauthorized page.
- Generate an Activity Log entry for the unauthorized access attempt.
- Never silently ignore unauthorized access.

---

## Rules
- Do NOT rely solely on UI route guards for security.
- Always enforce authorization at the service/logic layer as well.
- Do not use hidden UI elements as the only access control mechanism.

---

## TODO
- [ ] Implement route guards in Phase 4
- [ ] Implement service-layer role checks in Phases 5-9
