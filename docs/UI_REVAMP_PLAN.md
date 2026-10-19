# N.Y Kitchen POS — UI/UX Revamp & Engineering Plan

> **Design Direction:** Unified Design System, Fast-Paced Ergonomics, Modern Tactile Polish, High-Contrast Brand Palette.  
> **Hard Constraints:** Strict UI/UX and presentation layer only. Zero modifications to database schemas, SQLite migrations, repository query contracts, Supabase sync logic, or authentication business rules.

---

## 1. Prompt Critique & Feasibility Analysis

### Strengths
1. **Zero-Backend Safety:** Fully conforms to the repository's security boundaries. Does not touch SQLite schema v8, encryption utilities, or Supabase RLS.
2. **Phase-by-Phase Execution:** Phase 0 (Audit only) through Phase 8 (QA/Rollout) ensures changes are modular, easily reviewable, and reversible.
3. **Idiomatic Flutter Tokens:** Leveraging `ThemeData` with a custom `ThemeExtension` is the official Flutter 3+ standard for type-safe design tokens without hardcoded screen colors.
4. **Ergonomic Division of Roles:** Optimizes wide-screen desktop POS terminal layouts (~65% product grid, ~35% sticky cart) for Cashier speed while giving Admin scannable data tables and side panels.

### Critique & Practical Considerations
1. **The "3D Effect" vs. "Flat & Quiet" Resolution:**
   - *Conflict:* The prompt states *"flat and quiet... no blur, BackdropFilter, heavy shadows... use 1px borders"*, while modern design often demands visual punch and 3D depth.
   - *Feasible Solution (Tactile Micro-Depth):*
     - **Mechanical Key Press:** Instead of heavy blurry shadows, use mechanical tactile depth: buttons and active tiles have a solid 2px bottom offset edge (`AppColors.goldDeep` / `AppColors.darkCharcoal`). On press, the button translates 1–2px downward (`Transform.translate(offset: Offset(0, 1.5))`). This creates a satisfying, modern 3D tactile feel with zero GPU shader overhead.
     - **Crisp Layered Rim:** Cards use a crisp 1px `softBorder` with an optional 1px crisp layered rim, keeping frame times locked at 60 FPS on POS terminals.
     - **Restricted Hover Tilts:** Keep interactive `Matrix4` perspective hover tilts limited to non-critical surfaces (e.g. Admin KPI summary cards or Login face guide card), avoiding any motion lag in the high-frequency cashier catalog.
2. **Benchmarking Real Hardware (Phase 0):**
   - Headless IDE environments cannot measure physical GPU rasterization times on Windows touchscreens.
   - We will provide the exact `flutter run --profile` command and DevTools steps for the student to capture hardware cold-start and frame times, while we execute the complete code audit, screen inventory, tap-count analysis, and widget hierarchy review.

---

## 2. Token Architecture (Single Source of Truth)

### Color Palette
| Token Name | Hex Code | Semantic Role |
|---|---|---|
| `darkCharcoal` | `#2B241A` | Nav rail, title bar, high-contrast primary text |
| `goldenYellow` | `#FFCA05` | Active indicators, selected tabs, primary CTA fill |
| `goldDeep` | `#E0B000` | Pressed / hover state on gold surfaces (3D button edge) |
| `goldInk` | `#7A5B00` | Gold-toned text or links on light backgrounds |
| `brandRed` | `#D9271C` | Destructive actions, account lockouts, error alerts only |
| `forest` | `#2E7D4F` | Paid status, synced indicator, in-stock badge |
| `inkBlue` | `#2F6F8F` | Informational chips, background sync progress |
| `goldTint` | `#FFF1C2` | Warning surfaces (low inventory, pending offline sync) |
| `creamBackground` | `#FFF8E7` | Primary window / page background surface |
| `surfaceWhite` | `#FFFFFF` | Flat cards and panel surfaces (paired with `softBorder`) |
| `softBorder` | `#E7DCCB` | 1px clean card outlines and section dividers |
| `mutedBrown` | `#6B5E4B` | Secondary body text, metadata captions |
| `disabled` | `#B9AE9B` | Inactive controls and disabled buttons |

### Layout & Spacing Tokens
- **Spacing Scale:** 4px, 8px, 12px, 16px, 24px, 32px
- **Corner Radii:** `8px` (inputs, buttons, filter chips), `12px` (cards, modals, dialogs)
- **Typography (Roboto):**
  - Display: 28px (Bold 700)
  - Title: 20px (Bold 700)
  - Body Large: 16px (Medium 500)
  - Body: 14px (Regular 400)
  - Caption: 12px (Regular 400 / Medium 500)
  - Tabular figures (`FontFeature.tabularFigures()`) for prices, currency, and quantities.
- **Touch Targets:** 48px minimum; 56px for primary Cashier actions (Add, Charge, Checkout).

---

## 3. Screen & Component Inventory (Target Map)

### Auth & Shell
- [ ] `lib/main.dart` — Custom title bar & root shell
- [ ] `lib/features/auth/presentation/pages/login_page.dart` — PIN / Password login & keypad
- [ ] `lib/features/auth/presentation/widgets/face_login_sheet.dart` — Biometric face capture sheet
- [ ] `lib/features/auth/presentation/pages/face_registration_page.dart` — Admin face registration
- [ ] `lib/features/auth/presentation/widgets/force_change_password_dialog.dart` — First-login credential reset
- [ ] `lib/features/auth/presentation/widgets/guarded_route.dart` — Route authorization wrapper

### Cashier Role
- [ ] `lib/features/cashier/presentation/pages/cashier_shell.dart` — Cashier shell & nav rail
- [ ] `lib/features/cashier/presentation/pages/home_page.dart` — POS catalog grid, category tabs, cart & checkout
- [ ] `lib/features/cashier/presentation/pages/orders_page.dart` — Active orders list & status cards
- [ ] `lib/features/cashier/presentation/pages/transaction_history_page.dart` — Past transaction ledger & receipts
- [ ] `lib/features/cashier/presentation/pages/account_settings_page.dart` — Cashier profile & password change
- [ ] `lib/features/cashier/presentation/pages/cashier_activity_logs_page.dart` — Cashier shift logs

### Admin Role
- [ ] `lib/features/admin/presentation/pages/admin_shell.dart` — Admin shell & navigation rail
- [ ] `lib/features/admin/presentation/pages/admin_dashboard_page.dart` — Executive summary, KPI cards & charts
- [ ] `lib/features/admin/presentation/pages/food_management_page.dart` — Food catalog table & edit drawer
- [ ] `lib/features/admin/presentation/pages/account_management_page.dart` — User accounts & role management
- [ ] `lib/features/admin/presentation/pages/sales_reports_page.dart` — Detailed sales reports & date filtering
- [ ] `lib/features/admin/presentation/pages/activity_logs_page.dart` — Security audit logs & filters
- [ ] `lib/features/admin/presentation/pages/backup_restore_page.dart` — Cloud backup & local SQL export
- [ ] `lib/features/admin/presentation/pages/admin_account_settings_page.dart` — Admin credentials & preferences

---

## 4. Phase-by-Phase Roadmap & Tracking

| Phase | Description | Status | Scope |
|---|---|---|---|
| **Phase 0** | Comprehensive UI Audit (report only, 0 code edits) | **DONE** | Inventory screens, hardcoded colors/radii, tap counts, baseline checks (`docs/UI_PHASE_0_AUDIT_REPORT.md`) |
| **Phase 1** | Centralize Tokens (`ThemeData` + `ThemeExtension`) | **DONE** | Create `AppDesignTokens`, register in `AppTheme`, propagate to core widgets |
| **Phase 2** | Unified Component Kit with Tactile Depth | **DONE** | Buttons, text fields, cards, status chips, dialogs, component gallery |
| **Phase 3** | Shell & Responsive Navigation | **DONE** | Charcoal Rail, Status Strip, Shift Badges, Compact Drawer/Bar |
| **Phase 4** | Login, Face Biometrics & Dialogs | **DONE** | Explicit states, oval guide, PIN fallback, lockout clarity |
| **Phase 5** | Cashier High-Speed POS Flow | **PENDING (Next Up)** | 65/35 grid/cart, quick-add, sticky charge, receipt flow |
| **Phase 6** | Admin Dashboard & Data Tables | PENDING | 4 KPIs, side panels for CRUD, audit search, backup card |
| **Phase 7** | Security Presentation (UI Layer) | PENDING | Idle timeout countdown, masked credentials, audit toasts |
| **Phase 8** | QA, Accessibility & Verification | PENDING | 4.5:1 contrast audit, keyboard nav, tap target verification |

---

## 5. Phase 1, 2, 3 & 4 Completion Summary

### Phase 1 (Tokens)
- [x] Create `AppDesignTokens` ThemeExtension in `lib/core/theme/app_design_tokens.dart`.
- [x] Centralize all color tokens, spacing (4/8/12/16/24/32), radii (8/12), and tactile depth.
- [x] Register `AppDesignTokens.light` in `lib/core/theme/app_theme.dart` with Material 3 radius 8/12 and Roboto typography.
- [x] Create `AppTypography` with tabular figures for monetary amounts.
- [x] Update core widgets (`custom_title_bar.dart`, `food_card.dart`, `order_item_widget.dart`, `order_summary_panel.dart`, nav rails, `guarded_route.dart`).
- [x] Unit tests in `test/unit/app_design_tokens_test.dart` (4/4 passed).

### Phase 2 (Component Kit)
- [x] `AppPrimaryButton`, `AppSecondaryButton`, `AppDestructiveButton` in `lib/features/shared/widgets/app_buttons.dart` with tactile 3D press physics (1.5px translateY, crisp 2.5px bottom edge, 48px/56px heights).
- [x] `AppTextField` in `lib/features/shared/widgets/app_text_field.dart` with visible labels, golden focus ring, and inline validation errors.
- [x] `AppCard` in `lib/features/shared/widgets/app_card.dart` with flat 12px surface and 1px softBorder.
- [x] `AppStatusChip` in `lib/features/shared/widgets/app_status_chip.dart` pairing semantic colors (forest, inkBlue, goldTint, brandRed) with icons and text.
- [x] `AppEmptyState`, `AppErrorState`, and `AppSkeleton` in `lib/features/shared/widgets/app_state_placeholders.dart`.
- [x] `AppConfirmDialog` in `lib/features/shared/widgets/app_confirm_dialog.dart` with red CTA, plain-language consequence text, and Cancel focused by default.
- [x] `AppDataTable` in `lib/features/shared/widgets/app_data_table.dart` for scannable admin data and audit logs.
- [x] `CashierListTile` in `lib/features/shared/widgets/cashier_list_tile.dart` with tabular prices and high-speed stepper buttons.
- [x] `ComponentGalleryPage` in `lib/features/shared/pages/component_gallery_page.dart` (debug-only visual test screen).
- [x] Component test suite in `test/widget/component_kit_test.dart` (5/5 passed).

### Phase 3 (Shell & Navigation)
- [x] Created `AppStatusStrip` in `lib/features/shared/widgets/app_status_strip.dart` featuring responsive layout (`LayoutBuilder`), online connectivity indicator, cloud sync chip, tabular digital clock (no visual jiggle), role badge, and settings button.
- [x] Updated `CashierNavRail` in `lib/features/cashier/presentation/widgets/navigation/cashier_nav_rail.dart` with active gold indicator bar (4px expanded, 16x3px collapsed pill), pinned Cashier shift badge, and standardized logout dialog.
- [x] Updated `AdminNavRail` in `lib/features/admin/presentation/widgets/navigation/admin_nav_rail.dart` with active gold indicator bar, pinned Administrator badge, and standardized logout dialog.
- [x] Integrated `AppStatusStrip` into `CashierShell` (`cashier_shell.dart`) and `AdminShell` (`admin_shell.dart`), replacing ad-hoc top bars.
- [x] Enhanced `CashierBottomNav` (`cashier_bottom_nav.dart`) with top border container and 11px labeled touch navigation.
- [x] Standardized `AdminDrawer` (`admin_drawer.dart`) with `AppDesignTokens.radius8/12`, `SessionManager().clearSession()` on logout, and consistent dialog typography.
- [x] Widget tests in `test/widget/shell_navigation_test.dart` (5/5 passed; total 16/16 widget tests passed).

### Phase 4 (Login, Face Biometrics & Dialogs)
- [x] Redesigned `LoginPage` ([login_page.dart](file:///c:/src/ny_kitchen_app/lib/features/auth/presentation/pages/login_page.dart)) adopting the clean floating card layout of Image 2 with N.Y Kitchen's signature warm brand palette:
  - **Preserved Brand Palette:** Warm cream page background (`AppColors.creamBackground` `#FFF8E7`), brand golden yellow showcase (`AppColors.goldenYellow` `#FFCA05`), deep dark charcoal (`AppColors.darkCharcoal` `#2B241A`), surface white cards (`AppColors.surfaceWhite` `#FFFFFF`), and soft borders (`AppColors.softBorder` `#E7DCCB`).
  - **Floating Enclosure Layout:** Centered dual-panel card (`maxWidth: 1160px`, `targetHeight: 640-740px`, `borderRadius: 24`, soft ambient shadow, 1px `softBorder`).
  - **Left Showcase Panel:** Clean mascot emblem ([ny_kitchen_emblem.png](file:///c:/src/ny_kitchen_app/assets/images/branding/ny_kitchen_emblem.png)) & brand wordmark, bold headline *"One counter. Every order, tracked."*, compact white glass live order preview (`#00482`, `Sisig Rice`, `Served`), and responsive pastil food cluster wrapped in `FittedBox` (preventing any layout overflow).
  - **Right Login Panel (Clean Input UI):** Completely stripped of visual clutter and redundant stacked labels:
    - Sleek, minimalist inputs: single rounded box (`borderRadius: 12`), subtle 1.2px `softBorder`, clean floating `labelText` (no redundant duplicate hint text), subtle Lucide prefix icons (`LucideIcons.user`, `LucideIcons.lock`), and brand golden yellow focus border.
    - Clean aligned row for `Remember Me` checkbox and `Forgot Password?` link.
    - Primary CTA: Brand Golden Yellow button (`ElevatedButton`) with tactile bottom edge (`AppColors.goldTactileEdge`) and high-contrast dark charcoal text.
    - Clean divider with "or continue with" and secondary white pill `Login with Face` button (`LucideIcons.scan_face`).
- [x] Integrated `flutter_lucide` (^1.59.0) across navigation tabs and actions:
  - Cashier navigation rail & bottom nav: `LucideIcons.utensils`, `LucideIcons.receipt`, `LucideIcons.clock_arrow_left`, `LucideIcons.log_out`.
  - Admin navigation rail & drawer: `LucideIcons.layout_dashboard`, `LucideIcons.trending_up`, `LucideIcons.utensils`, `LucideIcons.users`, `LucideIcons.clipboard_list`, `LucideIcons.database_backup`, `LucideIcons.log_out`.
- [x] Full test suite verification: 48/48 widget tests passed, 35/35 security tests passed, 0 analyze errors in auth feature.



