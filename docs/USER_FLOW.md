# docs/USER_FLOW.md
# N.Y Kitchen — User Flows

> Source of Truth: PROJECT_BLUEPRINT.md Sections 6 and 7

---

## Purpose
Document the primary user flows to guide UI design and navigation implementation.

---

## Authentication Flow

```
App Launch
  ↓
Login Screen
  ↓
[Credentials Valid?]
  ├── No  → Show error → Increment failed login counter
  │           → [Threshold exceeded?] → Lock account → Show locked message
  └── Yes → [Role?]
              ├── Admin   → Admin Dashboard
              └── Cashier → Cashier Home / New Order
```

## Cashier Order Flow

```
Cashier Home / New Order
  ↓ Browse/Search Food Items
Add Items to Cart
  ↓
Review Current Order
  ↓
Select Payment Method
  ↓
Confirm Payment
  ↓
Generate Receipt → Print Receipt
  ↓
Save Transaction to SQLite
  ↓
Generate Activity Log
  ↓
Return to New Order
```

## Checkout Logout Guard

```
Cashier Logout Request
  ↓
[Unfinished transaction?]
  ├── Yes → Confirm discard → End session → Activity Log → Login
  └── No  → Confirm logout → End session → Activity Log → Login
```

## Admin Transaction Void Flow

```
Admin selects transaction
  ↓
Click Void
  ↓
Enter reason
  ↓
Confirm
  ↓
Mark transaction as Voided (never delete)
  ↓
Generate Activity Log
```

---

## TODO
- [ ] Create Figma flow diagrams for all user flows before Phase 1
