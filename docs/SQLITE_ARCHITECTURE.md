# docs/SQLITE_ARCHITECTURE.md
# N.Y Kitchen — SQLite Architecture

> Source of Truth: PROJECT_BLUEPRINT.md Section 10
> See also: DECISIONS.md ADR-001, ADR-015

---

## Purpose
Document the SQLite local database schema, design principles, and implementation guidance.

---

## Package Selection
- **Pending Review** — sqflite vs drift (see DECISIONS.md ADR-015)

## Database Location
- Android: Application documents directory (via path_provider)
- Windows: Application documents directory (via path_provider)

## Approved Tables

### users
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| full_name | TEXT | NOT NULL |
| username | TEXT UNIQUE | NOT NULL |
| password_hash | TEXT | NOT NULL, hashed |
| role | TEXT | admin or cashier |
| status | TEXT | active, inactive, locked |
| last_login | TEXT | ISO8601 timestamp |
| failed_login_count | INTEGER | DEFAULT 0 |
| created_at | TEXT | ISO8601 timestamp |

### food_categories
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| name | TEXT UNIQUE | NOT NULL |
| status | TEXT | active, disabled |
| created_at | TEXT | |

### food_items
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| category_id | INTEGER FK | food_categories.id |
| name | TEXT | NOT NULL |
| description | TEXT | |
| price | REAL | NOT NULL, > 0 |
| image_path | TEXT | Path only, no binary |
| availability | TEXT | available, unavailable |
| status | TEXT | active, archived |
| created_at | TEXT | |
| updated_at | TEXT | |

### transactions
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| receipt_number | TEXT UNIQUE | |
| user_id | INTEGER FK | users.id |
| total_amount | REAL | |
| discount | REAL | DEFAULT 0 |
| payment_method | TEXT | cash, gcash, maya, credit, debit |
| status | TEXT | completed, voided, refunded, cancelled |
| void_reason | TEXT | nullable |
| refund_reason | TEXT | nullable |
| created_at | TEXT | |

### transaction_items
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| transaction_id | INTEGER FK | transactions.id |
| food_item_id | INTEGER FK | food_items.id |
| food_name | TEXT | Snapshot at time of sale |
| food_price | REAL | Snapshot at time of sale |
| quantity | INTEGER | |
| subtotal | REAL | |

### activity_logs
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| user_id | INTEGER | nullable (system logs) |
| username | TEXT | Snapshot |
| role | TEXT | Snapshot |
| module | TEXT | auth, transactions, menu, users, settings, backup, security |
| action | TEXT | Description of action |
| status | TEXT | success, failed |
| description | TEXT | Detailed description |
| device_info | TEXT | Device identifier |
| created_at | TEXT | ISO8601 timestamp |

### login_attempts
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| username | TEXT | |
| status | TEXT | success, failed |
| ip_address | TEXT | nullable |
| device_info | TEXT | |
| created_at | TEXT | |

### app_settings
| Column | Type | Notes |
|---|---|---|
| key | TEXT PK | Setting key |
| value | TEXT | Setting value |
| updated_at | TEXT | |

### backup_records
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| filename | TEXT | |
| file_path | TEXT | |
| file_size | INTEGER | bytes |
| created_by | INTEGER FK | users.id |
| created_at | TEXT | |

---

## Security Rules
- ALL queries must use parameterized statements.
- Direct SQL string concatenation is PROHIBITED.
- Password hashes, not plain-text passwords, are stored in users table.
- activity_logs must have no UPDATE or DELETE queries accessible through normal app interface.
- transactions: status changes only (voided, refunded) — never hard delete.

---

## Data Integrity Rules
- Food names and prices are snapshotted in transaction_items at time of sale.
- Archived food items remain in food_items with status = archived.
- Completed transactions are never deleted — status changes only.

---

## TODO
- [ ] Confirm package selection before Phase 3 (ADR-015)
- [ ] Design and test migration strategy before Phase 3
- [ ] Implement backup as SQLite file copy
