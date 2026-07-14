# docs/MENU_MANAGEMENT.md
# N.Y Kitchen — Menu Management

> Source of Truth: PROJECT_BLUEPRINT.md Sections 7.4, 7.5

---

## Purpose
Document food menu and category management rules and features.

---

## Food Categories
- Admin can add, rename, enable, and disable categories.
- Suggested: Rice Meals, Snacks, Pasta, Beverages, Desserts, Specials.
- All category changes generate Activity Log entries.

## Food Items

### Fields
| Field | Notes |
|---|---|
| Food Image | Optional. Valid format. Stored locally (path in SQLite). |
| Food Name | Required. Cannot be empty. |
| Category | Required. Must exist in food_categories. |
| Description | Optional. |
| Price | Required. Numeric. Greater than zero. |
| Availability | available or unavailable. |
| Status | active or archived. |

### Operations
- Add Food — Admin only.
- Edit Food — Admin only. All changes logged.
- Archive Food — Admin only. Archived items are not shown in new orders.
- Enable Food — Toggle availability to available.
- Disable Food — Toggle availability to unavailable.
- Search and filter food items.

## Rules
- Food records must NEVER be permanently deleted if they exist in transaction_items.
- Archived items remain visible on historical receipts.
- Archived items cannot be selected for new orders.
- Food name and price are snapshotted in transaction_items at time of sale.
- All menu changes must generate Activity Log entries.

---

## TODO
- [ ] Define max image file size
- [ ] Confirm image formats (jpg, png, webp?)
- [ ] Implement menu module in Phase 5
