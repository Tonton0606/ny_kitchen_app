# docs/NAMING_CONVENTIONS.md
# N.Y Kitchen — Naming Conventions

---

## Purpose
Ensure consistent naming throughout the codebase.

---

## Dart/Flutter Naming

| Type | Convention | Example |
|---|---|---|
| Classes | PascalCase | UserRepository, MenuService |
| Files | snake_case | user_repository.dart |
| Variables | camelCase | currentOrder, userRole |
| Constants | lowerCamelCase or SCREAMING_SNAKE | kMaxLoginAttempts |
| Enums | PascalCase | UserRole.admin |
| Widgets | PascalCase | FoodItemCard |
| Providers | PascalCase + Provider suffix | AuthProvider |
| Routes | kebab-case strings | /admin/dashboard |

## Database Naming

| Type | Convention | Example |
|---|---|---|
| Tables | snake_case plural | food_items, activity_logs |
| Columns | snake_case | created_at, food_name |
| Primary key | id | id INTEGER PRIMARY KEY |
| Foreign keys | table_id | food_item_id, user_id |

## File Naming
- All Dart files: snake_case.dart
- All documentation files: SCREAMING_SNAKE.md (root) or SCREAMING_SNAKE.md (docs/)
- All skill files: SKILL.md

---

## TODO
- [ ] Review and confirm conventions before Phase 2
