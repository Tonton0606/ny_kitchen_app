# Modified Files Tracker
This document tracks all files modified during the Phase 3 backend integration (SQLite) to provide a clear branch tree of changes. It serves as a reference point for commits or push operations.

## Branch/Module: Admin Authentication & Management
- `lib/core/database/repositories/user_repository.dart`
  - *Created to handle User CRUD and authentication with SQLite.*
- `lib/features/auth/presentation/pages/login_page.dart`
  - *Updated to authenticate via `UserRepository` instead of static mocks.*
- `lib/features/admin/presentation/pages/account_management_page.dart`
  - *Updated to use `UserRepository` for loading, adding, editing, and disabling users.*

## Branch/Module: Admin Dashboard & Analytics
- `lib/features/admin/presentation/pages/admin_dashboard_page.dart`
  - *Converted to StatefulWidget to fetch live transactions via `TransactionRepository` and compute real-time daily/monthly revenue and orders.*
- `lib/features/admin/presentation/shared/widgets/sales_chart.dart`
  - *Created a new `fl_chart` based component to render live hourly sales data.*
- `lib/features/admin/presentation/pages/sales_reports_page.dart`
  - *Integrated with live `TransactionRepository` data to display calculated metrics per tab and connect export buttons.*
- `lib/core/services/export_service.dart`
  - *Added CSV and PDF generation logic for Sales Reports using `csv`, `pdf`, and `printing` packages.*
- `pubspec.yaml`
  - *Added `fl_chart`, `pdf`, `printing`, `csv`, and `intl` for analytics and export capabilities.*

## Branch/Module: Activity Logs & Cashier
- `lib/core/database/repositories/audit_repository.dart`
  - *Created repository for interacting with `activity_logs` table.*
- `lib/core/database/repositories/backup_repository.dart`
  - *Created repository for exporting SQLite database to system storage.*
- `lib/features/cashier/presentation/pages/transaction_history_page.dart`
  - *Added transaction voiding feature which updates `transactions` table and calls `AuditRepository` to log the event.*
- `lib/features/admin/presentation/pages/activity_logs_page.dart`
  - *Decoupled from `MockData` to fetch, search, and filter real-time logs from `AuditRepository`.*
- `lib/features/admin/presentation/pages/backup_restore_page.dart`
  - *Created new page for database export controls and connected it to `BackupRepository`.*
- `lib/features/admin/presentation/pages/admin_shell.dart`, `admin_nav_rail.dart`, `admin_drawer.dart`
  - *Added navigation entries for Backup & Restore module.*

## Branch/Module: Phase 4 Authentication & Security
- `lib/core/utils/security_utils.dart`
  - *Created utility for SHA-256 password hashing.*
- `lib/core/database/database_helper.dart`
  - *Bumped version to 2, added `onUpgrade` script to hash admin password and seed new cashier account (`cashier` / `cashier123`).*
- `lib/core/session/session_manager.dart`
  - *Created for offline in-memory session management.*
- `lib/features/auth/presentation/pages/login_page.dart`
  - *Integrated SessionManager.*
- `lib/core/database/repositories/user_repository.dart`
  - *Added 5-attempt lockout logic and changePassword.*
- `lib/features/cashier/presentation/pages/account_settings_page.dart`
  - *Bound user session, implemented Change Password.*
- `lib/features/admin/presentation/pages/admin_account_settings_page.dart`
  - *Bound user session.*
- `lib/features/admin/presentation/pages/account_management_page.dart`
  - *Fixed missing password hashing on user create/reset.*
- `pubspec.yaml`
  - *Added `crypto` package for SHA-256 hashing.*
- `lib/core/database/repositories/food_repository.dart`
  - *Created to handle CRUD operations for Food Categories and Food Items in SQLite.*
- `lib/features/admin/presentation/pages/food_management_page.dart`
  - *Updated to read/write food items using `FoodRepository` instead of static mocks. Integrated `image_picker` package to support local image uploads.*
- `lib/features/shared/widgets/food_image.dart`
  - *Updated to safely support native local files and external network URLs, providing reliable fallbacks for null values.*

## Branch/Module: Cashier & POS Workflow
- `lib/core/database/repositories/transaction_repository.dart`
  - *Created to handle transaction inserts, status updates, and history retrieval from SQLite.*
- `lib/features/cashier/presentation/pages/home_page.dart` (Cashier POS)
  - *Updated to fetch live menu items from `FoodRepository` and save completed checkouts to `TransactionRepository` (defaulting to 'Taken' status).*
- `lib/features/cashier/presentation/pages/orders_page.dart` (Kitchen Flow)
  - *Updated to poll `TransactionRepository.getActiveTransactions()` every 3 seconds to manage active orders dynamically (Taken -> Preparing -> Ready -> Served).*
  - *Fixed null-safe rendering for transaction item prices and payment values, plus guarded async status updates and refreshes.*
- `lib/features/cashier/presentation/pages/transaction_history_page.dart` (History)
  - *Updated to fetch `TransactionRepository.getAllTransactions()` and display actual saved transactions.*

## Branch/Module: Core Database Configuration
- `lib/core/database/database_helper.dart`
  - *Created and configured schema for 9 core tables (users, food_categories, food_items, transactions, transaction_items, etc.) and implemented initial seeding logic.*

## Branch/Module: Phase 4 Validation Fixes
- `lib/features/admin/presentation/pages/food_management_page.dart`
  - *Added lifecycle guards around asynchronous food/category operations and cleared analyzer warnings in the native image/category management flow.*

## Branch/Module: Project Documentation & States
- `PROJECT_STATE.md`
  - *Continually updated to reflect the completion of the above integrations.*
- `CHANGELOG.md`
  - *Documented the exact SQLite integration steps taken.*
- `SECURITY_FEATURES.md`
  - *Documents local-only SQLite authentication, current SHA-256 hashing, five-attempt lockout, in-memory sessions, and the deferred Supabase boundary.*
- `MODIFIED_FILES.md`
  - *Tracks the Phase 3/4 database, security, native image, category, and cashier workflow changes.*

## Branch/Module: Phase 5 Cloud Synchronization & Disaster Recovery
- `lib/core/services/sync_service.dart`
  - *Created to handle background backup of SQLite data to Supabase using upsert logic.*
- `lib/core/session/session_manager.dart`
  - *Integrated SyncService to trigger background cloud sync upon login and logout events.*
- `lib/main.dart`
  - *Initialized Supabase and dotenv, and injected x-device-secret header.*
- `pubspec.yaml`
  - *Registered .env file in assets and added `supabase_flutter` and `flutter_dotenv`.*
- `.env`
  - *Created to securely store Supabase URL, anon key, and device secret.*
- `SECURITY_FEATURES.md`
  - *Documented Supabase device-level security, RLS implementation, and disaster recovery benefits.*
- `supabase_migration.md`
  - *Generated as a reference for Postgres SQL schema configuration.*
- `lib/features/admin/presentation/pages/admin_shell.dart` & `lib/features/cashier/presentation/pages/cashier_shell.dart`
  - *Updated to use absolute package imports for GuardedRoute.*

*(This document should be updated whenever new branches/modules are integrated with the live backend).*
