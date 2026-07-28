# July 29 Branch Update Summary

This document recaps all the features, improvements, and bug fixes applied to the codebase in this update.

## 1. Security & Session Management 🔒
* **Global Inactivity Timeout (`lib/main.dart`)**
  * Converted `NYKitchenApp` to a `StatefulWidget`.
  * Added a background timer (`Timer.periodic`) that checks for user inactivity every minute.
  * If the session is idle for 30 minutes, it automatically logs out and redirects to the Login screen with a "Session Expired" alert.
* **Audit Logging for Security Events (`lib/core/database/repositories/user_repository.dart`)**
  * Injected `AuditRepository` into `UserRepository`.
  * **Failed Logins:** Generates a 'Warning' audit log for every failed login attempt.
  * **Account Lockout:** Locks the account and generates a 'Critical' audit log when a user accumulates 5 consecutive failed login attempts.
  * **Password Changes:** Automatically generates a 'Success' audit log whenever an admin changes a user's password.
* **Account Unlock UI (`lib/features/admin/presentation/pages/account_management_page.dart`)**
  * The user table now visually flags locked accounts with an orange "Locked" status indicator.
  * Replaced the standard Enable/Disable button with a dedicated **Unlock** button for locked accounts.
  * Implemented an unlock confirmation dialog which securely resets the `failed_login_count` and logs the unlock action to the audit logs.

## 2. Bug Fixes & Refinements 🐛
* **Client-side Login Rate Limiting (`lib/features/auth/presentation/pages/login_page.dart`)**
  * Added a local rate limiter that locks the username and password fields for 30 seconds after 5 consecutive failed login attempts on the device.
  * Cleaned up the UI by removing redundant error messages on both text fields, placing a single, clean countdown message below the password input during the lockout period.
* **Category Dropdown State Loss Fix (`lib/features/admin/presentation/pages/food_management_page.dart`)**
  * Fixed an issue where the "Category" dropdown would randomly reset to "Rice Meals" while adding or editing a food item.
  * **Root Cause:** The background cloud sync (which polls every 4 seconds) was triggering a UI rebuild that wiped the dropdown's internal state.
  * **Fix:** Upgraded the `DropdownButtonFormField` from using an `initialValue` to a fully controlled `value` binding, guaranteeing it retains the user's selected category even during background refreshes.

## 3. Sales Reports & Export Enhancements 📊
* **Excel Export (.xlsx):** Integrated the `syncfusion_flutter_xlsio` package to completely upgrade CSV exports. The new Excel export features bolded headers, adjusted column widths, proper currency number formatting, and an automatic `=SUM()` formula at the bottom of the Total column.
* **Native PDF Export:** Added a direct PDF Export option to save Sales Reports directly to your local files as a styled PDF (rather than just bringing up the print dialog).
* **Advanced Date Filters:** Added full Date Range and Search capabilities (by receipt/order number) to the Sales Reports page.
* **Numeric Type Safety Fix:** Fixed a critical bug where Supabase would sometimes return numeric amounts as Strings (e.g. `"150.00"`), which was silently crashing the widget tree. 

## 4. Admin Dashboard Polish 📈
* **Interactive Period Chips:** The "Today," "Week," and "Month" chips on the Dashboard are no longer static. They are now fully interactive and automatically recalculate the Total Revenue and Total Orders depending on the selected timeframe.

## 5. Cashier & Order Flow Logic 🧑‍🍳
* **Custom Order Numbers:** Enabled customizable Order Numbers via settings.
* **VAT Removal:** Disabled and removed the VAT tax computation from the order checkouts.
* **Workflow Constraints:** Removed the "Cancel" button for orders that are currently in the "Preparing" status, locking the workflow logic.
* **Serving Dialog UI:** Ensured that the confirmation dialog when moving an order to "Served" strictly adheres to the requested color palette.

## 6. Database & Sync Fixes 🪲
* **Status Snap-back Fix:** Repaired an issue where changing an order to "Served" would momentarily snap back to "Preparing". This was caused by the background Supabase cloud sync running at the exact same moment. The logic is now hardened against concurrency overlap.
