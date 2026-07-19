# Changelog
# N.Y Kitchen Secure Order and Sales Management System

All notable changes to this project will be documented in this file.

This file follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

---

## [Unreleased]

### Added

- `RULES.md` — Immutable project rules governing all development.
- `AI_DEVELOPMENT_RULES.md` — Mandatory AI agent operating rules.
- `PROJECT_STATE.md` — Project state tracker for all development phases.
- `CHANGELOG.md` — This changelog file.
- `TODO.md` — Categorized task tracker.
- `DECISIONS.md` — Architecture Decision Record index and templates.
- `.aiignore` — AI exclusion configuration.
- `docs/` directory with 57 Markdown documentation templates.
- `ai/` directory with 9 AI collaboration Markdown files.
- `skills/` directory with 43 project-specific SKILL.md files.
- `skills/REGISTRY.md` — Skills registry table.
- `skills/CONTRIBUTING.md` — Skills contribution guide.
- `skills/_templates/skill-template/SKILL.md` — Standard skill template.
- `docs/OPEN_SOURCE_REVIEW.md` — Documentation of the open source review, import decisions, and security constraints.
- `docs/FIGMA_INTEGRATION.md` — Documentation of Figma workspace links and design handoff process.
- Cashier Module Phase 1 Static UI Prototype (Home/Order, History, Settings).
- Admin Module Phase 1 Static UI Prototype (Dashboard, Sales Reports, Food Management, Account Management, Activity Logs, Settings).
- Login Screen static prototype with mock role selection.
- **Mock Data**: Extended with 15 food items, 8 transactions, 5 users, 10 activity logs, 5 top-selling foods, 10 hourly revenue data points.
- **Login Page**: Enhanced with desktop side-by-side branding layout, polished Material 3 card design, role selector with icons, improved form fields with filled styling.

### Changed

- `README.md` — Updated with project overview, platforms, architecture summary, and documentation links.
- `DECISIONS.md` — Resolved pending ADRs 011, 013, 015, and 016.
- `PROJECT_STATE.md` — Updated to reflect resolution of ADRs and creation of Open Source Review documentation.
- **Admin Shell**: Improved Navigation Rail with compact mode for tablet, responsive drawer for mobile, logout now navigates to login page.
- **Admin Dashboard**: Added trend indicators to stat cards, period filter chips, hourly bar chart visualization, ranked top-selling foods with revenue, enhanced recent activities with status icons.
- **Sales Reports**: Added 4 summary cards per tab (Revenue, Avg Order, Orders, Completion Rate), added Items column to transactions table, improved status badges.
- **Food Management**: Complete CRUD dialogs with image placeholder, category dropdown, price input, availability toggle, prefilled edit dialog, search/filter functionality.
- **Account Management**: Complete dialogs for Add Cashier, Edit, Reset Password, Disable/Enable with proper form fields and confirmation messaging, search/filter functionality.
- **Activity Logs**: Added search by user/action/module, role filter dropdown, date filter dropdown, role and module colored badges, monospace IP styling.
- **Account Settings**: Added profile picture with camera icon overlay, role badge, theme switch with dark mode icon, about section, save button with feedback.
- **Admin design merge**: Consolidated the polished Material 3 login, admin navigation, dashboard, reports, food, account, activity-log, and settings UI into the Phase 1 prototype.
- **Cashier UI**: Refined cashier navigation, ordering, active orders, and settings presentation while retaining mock data only.

### Fixed

- All `withOpacity` deprecation warnings replaced with `withValues(alpha:)`.
- All `background`/`onBackground` theme deprecations replaced with `surface`/`onSurface`.
- All `activeColor` deprecation warnings on SwitchListTile replaced with `activeTrackColor`.
- All `value` deprecation warnings on DropdownButtonFormField replaced with `initialValue`.
- All `__` and `___` unnecessary underscore warnings resolved.
- String concatenation warnings resolved using interpolation.
- Removed unused `_initState` method from SalesReportsPage.
- Removed unused imports from admin navigation files.
- Removed unused local variables from ActivityLogsPage.
- Fixed invalid `const` modifiers in `Text` and `Column` widgets using dynamic `Theme.of(context)` styles across admin pages.
- Resolved bracket closure syntax error in `AdminDashboardPage`.
- Resolved unused `app_colors.dart` imports across multiple modules.
- Fixed `curly_braces_in_flow_control_structures` warnings in `ActivityLogsPage`.
- Applied Material 3 design polish to `LoginPage`, replacing hardcoded `AppColors` with `Theme.of(context).colorScheme` and enhancing the desktop split layout with branded visuals.
- Added mounted guards around order status updates and undo actions after dialog navigation.
- Wrapped cashier account-settings tiles in a transparent `Material` surface so ListTile ink feedback is visible.
- Completed LUMORA Phase 4 validation: `flutter analyze` reports zero issues and all 26 widget tests pass.

### Security

*No security changes yet. Security implementation begins in Phase 4.*

### Deprecated

*Nothing deprecated.*

### Removed

*Nothing removed.*

---

## [0.0.1] — 2026-07-14 — Documentation Setup

### Added

- Initial Flutter project scaffolding (generated by Flutter SDK).
- `PROJECT_BLUEPRINT.md` — Master project blueprint and single source of truth.
- Phase 1 documentation and AI operating system setup.

---

*This changelog will be updated as phases are completed and features are implemented.*
*Do not add feature entries until the corresponding implementation exists and is verified.*
