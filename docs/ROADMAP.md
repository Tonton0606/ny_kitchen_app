# docs/ROADMAP.md
# N.Y Kitchen — Development Roadmap

> **Source of Truth:** `PROJECT_BLUEPRINT.md` Section 19
> All phases follow the approved blueprint. Do not modify phase scope without updating the blueprint.

---

## Phase 1 — Static UI/UX Prototype *(Current)*

**Purpose:** Client presentation, UI approval, and design validation. No backend, no database, no real authentication.

**Restrictions:** No SQLite. No Supabase. No authentication logic. No backend. Mock data only.

### Checklist

- [ ] Complete login mockup (static, mock credentials)
- [ ] Complete Admin Dashboard mockup (mock analytics)
- [ ] Complete Admin Transactions screen mockup
- [ ] Complete Menu Management mockup (add/edit/archive)
- [ ] Complete User Management mockup
- [ ] Complete Activity Logs mockup (read-only, mock entries)
- [ ] Complete Reports mockup (charts, mock data)
- [ ] Complete Account Settings mockup
- [ ] Complete Backup & Restore mockup
- [ ] Complete Cashier Home / New Order (3-panel desktop layout)
- [ ] Complete Cashier Transaction History mockup
- [ ] Complete Cashier Account Settings mockup
- [ ] Complete checkout process flow (mock)
- [ ] Complete receipt preview mockup
- [ ] Complete responsive layouts (phone, tablet, desktop)
- [ ] Complete Drawer Navigation for mobile
- [ ] Complete Sidebar Navigation for desktop/tablet
- [ ] Complete confirmation dialogs
- [ ] Complete unauthorized page
- [ ] Complete loading state components
- [ ] Complete empty state components
- [ ] Complete error state components
- [ ] Complete dark and light themes
- [ ] Client review and approval

---

## Phase 2 — Project Architecture

**Purpose:** Establish the clean architecture, folder structure, shared components, theme, and navigation before feature implementation.

### Checklist

- [ ] Finalize and create feature-first folder structure (`docs/FOLDER_STRUCTURE.md`)
- [ ] Implement Material 3 theme (light + dark)
- [ ] Implement design tokens from `docs/DESIGN_SYSTEM.md`
- [ ] Configure go_router with role-based route definitions
- [ ] Implement shared widget library
- [ ] Define domain models (User, FoodItem, FoodCategory, Transaction, TransactionItem, ActivityLog)
- [ ] Define repository interfaces
- [ ] Define service interfaces
- [ ] Document architecture in `docs/ARCHITECTURE.md`

---

## Phase 3 — SQLite Integration

**Purpose:** Implement the local database layer that all features depend on.

### Checklist

- [ ] Select and install SQLite package (sqflite or drift — see `DECISIONS.md` ADR-015)
- [ ] Implement database initialization and version management
- [ ] Implement migration system
- [ ] Create `users` table
- [ ] Create `food_categories` table
- [ ] Create `food_items` table
- [ ] Create `transactions` table
- [ ] Create `transaction_items` table
- [ ] Create `activity_logs` table
- [ ] Create `login_attempts` table
- [ ] Create `app_settings` table
- [ ] Create `backup_records` table
- [ ] Implement repositories (User, FoodItem, FoodCategory, Transaction, ActivityLog)
- [ ] Implement parameterized queries throughout
- [ ] Implement database backup (file copy)
- [ ] Implement database restore
- [ ] Write unit tests for repositories

---

## Phase 4 — Authentication

**Purpose:** Implement secure login, session management, and role-based access control.

### Checklist

- [ ] Implement login screen logic
- [ ] Implement password hashing (confirm algorithm — see `DECISIONS.md` ADR-013)
- [ ] Implement failed login counter
- [ ] Implement account lockout (threshold TBD)
- [ ] Implement session management
- [ ] Implement session expiration
- [ ] Implement automatic logout on timeout
- [ ] Implement role-based route guards (go_router)
- [ ] Implement unauthorized page redirect
- [ ] Implement logout with Activity Log entry
- [ ] Write authentication unit tests

---

## Phase 5 — Menu Management

**Purpose:** Allow Administrators to manage the food menu.

### Checklist

- [ ] Implement food category CRUD
- [ ] Implement food item CRUD
- [ ] Implement food image upload and local storage
- [ ] Implement food availability toggle
- [ ] Implement food archiving
- [ ] Verify archived items appear on historical receipts
- [ ] Verify archived items cannot be added to new orders
- [ ] Activity Log for all menu changes
- [ ] Write menu management tests

---

## Phase 6 — Sales Module

**Purpose:** Implement the core order processing and receipt system.

### Checklist

- [ ] Implement food item selection (3-panel POS layout)
- [ ] Implement cart (add, remove, quantity, notes)
- [ ] Implement checkout workflow
- [ ] Implement payment method selection
- [ ] Implement receipt generation
- [ ] Implement receipt printing (confirm packages — see `DECISIONS.md` ADR-011)
- [ ] Implement transaction save to SQLite
- [ ] Implement receipt reprint (Admin and Cashier with Activity Log)
- [ ] Implement transaction history for Cashier
- [ ] Implement transaction history for Admin (full, with filters)
- [ ] Implement void transaction (Admin, with reason + Activity Log)
- [ ] Implement refund transaction (Admin, with reason + Activity Log)
- [ ] Verify completed transactions cannot be permanently deleted
- [ ] Write transaction tests

---

## Phase 7 — User Management

**Purpose:** Allow Administrators to manage application user accounts.

### Checklist

- [ ] Implement add user
- [ ] Implement edit user
- [ ] Implement activate/deactivate user
- [ ] Implement reset password
- [ ] Implement unlock account
- [ ] Implement change user role
- [ ] Verify final active Admin cannot deactivate itself
- [ ] Activity Log for all user management actions
- [ ] Write user management tests

---

## Phase 8 — Activity Logs

**Purpose:** Implement automatic audit trail for all tracked system events.

### Checklist

- [ ] Implement Activity Log service (auto-logging for all events)
- [ ] Implement Activity Log viewer (read-only)
- [ ] Implement search and filters
- [ ] Implement export to PDF
- [ ] Implement export to CSV
- [ ] Verify logs are immutable through the application interface
- [ ] Write Activity Log tests

---

## Phase 9 — Reports

**Purpose:** Provide business and security reports to Administrators.

### Checklist

- [ ] Implement daily sales report
- [ ] Implement weekly sales report
- [ ] Implement monthly sales report
- [ ] Implement annual sales report
- [ ] Implement best-selling foods report
- [ ] Implement best-selling categories report
- [ ] Implement cashier performance report
- [ ] Implement login summary report
- [ ] Implement security events report
- [ ] Implement report preview
- [ ] Implement export to PDF
- [ ] Implement export to CSV
- [ ] Write report generation tests

---

## Phase 10 — Security Hardening and QA

**Purpose:** Verify and harden all security controls. Complete testing.

### Checklist

- [ ] CIA Triad review against `docs/CIA_TRIAD.md`
- [ ] OWASP checklist completion (`docs/OWASP_CHECKLIST.md`)
- [ ] ISO/IEC 25010 evaluation (`docs/ISO25010_EVALUATION.md`)
- [ ] Threat model review (`docs/THREAT_MODEL.md`)
- [ ] Security testing (`docs/SECURITY_TESTING.md`)
- [ ] Performance profiling
- [ ] Accessibility testing
- [ ] Responsive testing (phone, tablet, desktop)
- [ ] Offline behavior testing
- [ ] Full QA pass (`docs/QA_CHECKLIST.md`)

---

## Phase 11 — Deployment and Presentation

**Purpose:** Build, deploy, and present the completed application.

### Checklist

- [ ] Build Android release APK
- [ ] Test on Android phone
- [ ] Test on Android tablet
- [ ] Build Windows installer
- [ ] Test on Windows desktop
- [ ] Prepare final documentation
- [ ] Prepare presentation (`docs/PRESENTATION.md`)
- [ ] Prepare client demo (`docs/CLIENT_DEMO_PLAN.md`)
- [ ] Prepare final defense (`docs/DEFENSE_PLAN.md`)

---

## Future Enhancements (Post-Defense)

See `docs/FUTURE_ENHANCEMENTS.md` for planned but out-of-scope features.

- Supabase cloud backup
- Cross-device synchronization
- Save receipt as PDF
- Remote Admin access
- Future analytics
