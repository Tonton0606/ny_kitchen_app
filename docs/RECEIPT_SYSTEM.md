# docs/RECEIPT_SYSTEM.md
# N.Y Kitchen — Receipt System

> Source of Truth: PROJECT_BLUEPRINT.md Section 11
> See: DECISIONS.md ADR-011

---

## Purpose
Document receipt generation, content, printing, and reprint rules.

---

## Receipt Content

### Business Information
- Business Name (from app_settings)
- Business Address (from app_settings)
- Contact Number (from app_settings)

### Transaction Information
- Receipt Number (unique)
- Transaction Date
- Transaction Time
- Cashier Name
- Payment Method

### Ordered Items
- Food Name
- Quantity
- Unit Price
- Subtotal

### Payment Summary
- Gross Total
- Discount (if any)
- Tax (future support)
- Final Total

### Footer
- Thank You message
- Business Disclaimer
- Visit Again message

## Receipt Features
- Preview receipt before printing.
- Print receipt immediately after checkout.
- Reprint receipt (authorized users, generates Activity Log).
- Save as PDF: Future enhancement.

## Receipt Number Format
- Unique, auto-generated. Format: TBD (e.g., TXN-YYYYMMDD-NNNN).

## Printing Strategy (Pending Review)
- Flutter packages: printing, pdf (see ADR-011).
- Platform-specific printing considerations for Windows vs Android.
- Bluetooth/USB printer support: TBD.

---

## TODO
- [ ] Confirm receipt number format
- [ ] Confirm printing packages and printer compatibility (ADR-011)
- [ ] Implement receipt module in Phase 6
