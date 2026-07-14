# docs/VALIDATION_RULES.md
# N.Y Kitchen — Validation Rules

> Source of Truth: PROJECT_BLUEPRINT.md Section 16

---

## Purpose
Document all input validation rules for user accounts, food items, transactions, and general inputs.

---

## User Account Validation

| Field | Rule |
|---|---|
| Username | Required. Unique. No prohibited characters. Max length TBD. |
| Password | Required. Minimum length TBD. Must be hashed before storage. |
| Role | Must be exactly "admin" or "cashier". No other values accepted. |
| Status | Must be "active", "inactive", or "locked". |

## Food Item Validation

| Field | Rule |
|---|---|
| Food Name | Required. Cannot be empty. |
| Category | Required. Must exist in food_categories table. |
| Price | Required. Numeric only. Must be greater than zero. |
| Availability | Must be "available" or "unavailable". |
| Image | Optional. Valid image formats only (jpg, png). Stored locally. |

## Transaction Validation

| Check | Rule |
|---|---|
| Order contents | Must contain at least one item. |
| Quantity | Must be greater than zero. |
| Food availability | Food item must be available (not archived, not disabled). |
| Payment method | A valid payment method must be selected. |
| Total amount | Must be a valid positive number. |

## Search Input Validation
- All search inputs must be sanitized before database queries.
- Parameterized queries prevent SQL injection regardless of input.
- Invalid search expressions must not cause application errors.

## General Validation Rules
- Required fields must not be empty.
- Numeric fields must contain only valid numbers.
- Date ranges must be logically valid (start before end).
- Duplicate usernames must be rejected.
- Duplicate category names must be rejected.
- User-facing error messages must be friendly and non-technical.
- Technical system errors must never be exposed to end users.

---

## TODO
- [ ] Confirm minimum password length
- [ ] Define maximum username length
- [ ] Define allowed username characters
