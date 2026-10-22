SUPERSEDED: do not follow. See /UI_PRINCIPLES.md.

# Phase 0 — Baseline UI/UX Audit Report

> **Project:** N.Y Kitchen POS & Management App  
> **Date:** 2026-10-19  
> **Status:** REPORT ONLY (Zero code changes made)  
> **Goal:** Inventory screens, identify design inconsistencies (colors, radii, spacing, fonts), map tap counts for top tasks per role, and establish the baseline before Phase 1.

---

## 1. Screen & Navigation Inventory by Role

### Authentication & Shared Shell
| Screen / Component | File Path | Current Structure & Visual Layout |
|---|---|---|
| **Root Shell & Title Bar** | `lib/main.dart`, `custom_title_bar.dart` | Window control buttons, custom drag region, app logo watermark. |
| **Login Screen** | `login_page.dart` | Split screen: branded left hero panel, right panel with username/password fields, quick-fill test pills, Face Login button. |
| **Biometric Face Login** | `face_login_sheet.dart` | Modal bottom sheet with live camera preview, overlay status chip, cancel button. |
| **Face Registration** | `face_registration_page.dart` | Full-screen camera viewfinder with circular/oval reticle for encoding enrollment. |
| **Forced Password Reset** | `force_change_password_dialog.dart` | Modal dialog enforcing 8+ char alphanumeric credentials on initial login. |

### Cashier Role
| Screen / Component | File Path | Current Structure & Layout |
|---|---|---|
| **Cashier Shell** | `cashier_shell.dart`, `cashier_nav_rail.dart` | Desktop charcoal nav rail (Order, Orders, History, Logs, Settings, Logout). |
| **POS Order Screen** | `home_page.dart` | Category filter chips top; food item grid (~60%); order summary / cart panel (~40%) with item rows, totals, and "Charge" button. |
| **Active Orders** | `orders_page.dart` | Tabbed view (Pending, Preparing, Completed, Cancelled) displaying order cards with items and status actions. |
| **Transaction History** | `transaction_history_page.dart` | List of completed receipts with date filter, void actions, and receipt reprint modal. |
| **Cashier Activity Logs** | `cashier_activity_logs_page.dart` | Personal shift activity logs showing login, checkout, and order events. |
| **Account Settings** | `account_settings_page.dart` | Cashier profile view and change password dialog. |

### Admin Role
| Screen / Component | File Path | Current Structure & Layout |
|---|---|---|
| **Admin Shell** | `admin_shell.dart`, `admin_nav_rail.dart` | Desktop charcoal nav rail with Admin tabs (Dashboard, Food, Accounts, Reports, Logs, Backup, Settings). |
| **Admin Dashboard** | `admin_dashboard_page.dart` | 4 metric cards (Today's Sales, Orders, Low Stock, Active Cashiers), revenue chart, recent transactions, quick actions. |
| **Food Catalog Management** | `food_management_page.dart` | Search bar, category filter, food cards / data table, add/edit food dialog with image upload. |
| **Account Management** | `account_management_page.dart` | Cashier accounts table, Add Cashier modal, Reset Password dialog, biometric enrollment status. |
| **Sales Reports** | `sales_reports_page.dart` | Date range selector, category breakdown charts, hourly sales distribution, export buttons. |
| **Activity & Audit Logs** | `activity_logs_page.dart` | Searchable security audit table, role filter, date filter, action type chips. |
| **Backup & Restore** | `backup_restore_page.dart` | Supabase cloud sync status, "Sync Now" button, "Export Database" (.sql dump) action. |
| **Admin Account Settings** | `admin_account_settings_page.dart` | Admin credential management, session info, dark mode toggle draft. |

---

## 2. Inconsistencies & Anti-Patterns Identified

### A. Hard-Coded Colors & Low Contrast
1. **Raw Material Colors:** Found 40+ instances of raw `Colors.grey`, `Colors.green`, `Colors.red`, `Colors.orange`, and `Colors.amber` scattered inside screen files instead of referencing `AppColors` tokens.
2. **Grey-on-Grey Contrast Failures:** 
   - Multiple captions and placeholder texts use `TextStyle(color: Colors.grey)` or `Colors.grey.shade400` on white card surfaces, resulting in contrast ratios around **2.2:1 to 3.1:1** (failing the **4.5:1** WCAG AA requirement).
3. **Mismatched Status Palettes:**
   - Account lockout is rendered as `Colors.orange` in `account_management_page.dart` line 496, but defined as `AppColors.brandRed` in `specs/visual-polish-spec.md`.
   - Low stock warnings mix `Colors.amber` and `Colors.orange`.

### B. Corner Radii Proliferation
The codebase currently uses **7 different corner radii** inconsistently:
- `4px`: `order_item_widget.dart` quantity buttons
- `6px`: `order_summary_panel.dart` and `transaction_history_page.dart` chips
- `8px`: Dialog inputs, buttons
- `10px`: Card outlines, modal buttons, search bars
- `12px`: Primary cards, cashier nav rail items
- `16px`: Dialog containers, card wrappers
- `20px`: Success checkout dialog container
*Target Rule:* Standardize strictly on **two radii**: **8px** (inputs, buttons, chips) and **12px** (cards, dialogs, modals).

### C. Layout & Spacing Fragmentation
- Spacing values of `2px`, `5px`, `6px`, `10px`, `14px`, `15px`, `18px`, `20px`, `22px` appear arbitrarily across margin/padding calls.
*Target Rule:* Standardize on the 8-point system: **4, 8, 12, 16, 24, 32px only**.

### D. Typography & Figures
- Prices and monetary amounts currently use variable-width default sans numerals without `FontFeature.tabularFigures()`, causing visual jiggle when order totals change or quantities increment.
- Headers oscillate between `18px`, `20px`, `22px`, and `24px` with mixed font weights (`FontWeight.w600` vs `FontWeight.bold`).

---

## 3. Tap-Count Baseline for Top 5 Tasks per Role

### Cashier Tasks
| Task | Current Steps & Tap Flow | Baseline Tap Count | Target Post-Revamp |
|---|---|:---:|:---:|
| **1. Add Item to Cart** | Tap category chip $\rightarrow$ scroll/find product $\rightarrow$ tap item card | **2 taps** | **1-2 taps** |
| **2. Adjust Quantity** | Locate item in cart $\rightarrow$ tap small `+` icon $\rightarrow$ wait for state update | **2 taps** | **1 tap** (prominent 48px stepper) |
| **3. Filter by Category** | Tap category pill horizontally | **1 tap** | **1 tap** (sticky gold active state) |
| **4. Complete Cash Checkout** | Tap "Charge" button $\rightarrow$ select "Cash" payment method $\rightarrow$ tap amount preset / enter tendered $\rightarrow$ tap "Pay" $\rightarrow$ dismiss receipt modal | **5 taps** | **3-4 taps** (auto-focus cash input, 1-tap fast pay) |
| **5. Reprint Past Receipt** | Tap "History" in nav $\rightarrow$ locate transaction row $\rightarrow$ tap "View Receipt" $\rightarrow$ tap "Print" | **4 taps** | **3 taps** (quick reprint action directly on row) |

### Admin Tasks
| Task | Current Steps & Tap Flow | Baseline Tap Count | Target Post-Revamp |
|---|---|:---:|:---:|
| **1. Add Menu Item** | Tap "Food" in nav $\rightarrow$ tap "Add Item" button $\rightarrow$ enter name $\rightarrow$ enter price $\rightarrow$ select category $\rightarrow$ tap "Save" | **5 taps** | **4 taps** (streamlined drawer with auto-focus) |
| **2. Update Price / Stock** | Tap "Food" in nav $\rightarrow$ search item $\rightarrow$ tap edit icon $\rightarrow$ edit field $\rightarrow$ tap "Update" | **5 taps** | **3-4 taps** (inline editable cell or quick sheet) |
| **3. Reset Cashier Password** | Tap "Accounts" in nav $\rightarrow$ locate user $\rightarrow$ tap three-dot menu $\rightarrow$ tap "Reset Password" $\rightarrow$ enter new pass $\rightarrow$ tap Confirm | **5 taps** | **3-4 taps** (direct secondary action on table row) |
| **4. Filter Audit Logs** | Tap "Logs" in nav $\rightarrow$ tap filter dropdown $\rightarrow$ pick action $\rightarrow$ tap apply | **4 taps** | **2 taps** (persistent filter chips) |
| **5. Trigger Cloud Backup** | Tap "Backup" in nav $\rightarrow$ tap "Export Database" $\rightarrow$ confirm file save | **3 taps** | **2 taps** (one-click export with toast feedback) |

---

## 4. Performance & Hardware Baseline

- **Current Flutter Test Execution Time:** ~3.0s for full security test suite (35 tests passing).
- **Physical Hardware Profiling Command (For Windows POS Terminal):**
  To capture actual GPU rasterization times, frame budgets (<16.6ms for 60fps), and cold-start seconds on the physical POS touchscreen terminal, execute:
  ```powershell
  flutter run -d windows --profile
  ```
  Then open Flutter DevTools $\rightarrow$ **Performance** tab $\rightarrow$ record frame raster and UI thread graphs during rapid catalog scrolling.

---

## 5. Next Steps for Phase 1

Upon your approval, we will proceed to **Phase 1 (Tokens)**:
1. Create `ThemeExtension` (`AppDesignTokens`) housing all brand color tokens and radii.
2. Update `AppTheme.lightTheme` in `lib/core/theme/app_theme.dart` to expose these tokens directly via `Theme.of(context)`.
3. Provide tactile button physics tokens (`goldDeep` bottom edge) for the modern 3D press feel.
