# docs/TRANSACTIONS.md
# N.Y Kitchen — Transactions

> Source of Truth: PROJECT_BLUEPRINT.md Sections 6.3, 7.3, 15

---

## Purpose
Document the transaction lifecycle, rules, and security controls.

---

## Transaction Lifecycle

```
Order Created → Items Selected → Checkout → Payment Confirmed
→ Receipt Generated → Transaction Saved → Activity Log Created
```

## Transaction Statuses
| Status | Description |
|---|---|
| completed | Successfully paid and finalized |
| cancelled | Cancelled before payment |
| voided | Voided by Admin after completion (reason required) |
| refunded | Refunded by Admin (reason required) |

## Transaction Rules
- Completed transactions are NEVER permanently deleted.
- Void requires: Admin authorization, reason, Activity Log.
- Refund requires: Admin authorization, reason, Activity Log.
- Receipt reprint requires: Activity Log.
- Cashier can only view own transactions.
- Admin can view all transactions.

## Receipt Number
- Unique, auto-generated.
- Format: TBD (e.g., TXN-YYYYMMDD-NNNN).
- Never reused.

## Supported Payment Methods
- Cash
- GCash
- Maya
- Credit Card
- Debit Card

## Checkout Validation
- Order must contain at least one item.
- All items must be available (not archived, not disabled).
- Quantity must be greater than zero.
- Payment method must be selected.
- Total must be a valid positive number.

---

## TODO
- [ ] Define receipt number format
- [ ] Implement transaction module in Phase 6
- [ ] Test transaction immutability in Phase 10
