# Kiosk Navigation Specification

> Premium NY kiosk-style navigation. Icon-only, dark muted background, gold accents.

## Core Principles

- **Icon-only nav rails** — zero text labels anywhere. Destinations communicated purely through recognizable outlined icons.
- **Premium iconography** — consistent `Icons.XXX_outlined` (unselected) / `Icons.XXX` (selected) pairings. No mixed weights.
- **Muted dark background** — `AppColors.darkCharcoal` (`#2B241A`) for all nav surfaces. This is a warm dark, not pure black, matching "low-strain" dark mode philosophy.
- **Gold active state** — `AppColors.goldenYellow` (`#FFCA05`) for selected icons and indicator pill.
- **Settings moved out of nav rail** — triggered from gear icon in content-area top bar, or NY logo tap.

---

## Icon Set (Premium Outlined)

### Cashier
| Destination | Unselected | Selected | Meaning |
|-------------|-----------|----------|---------|
| Home | `Icons.table_restaurant_outlined` | `Icons.table_restaurant` | Order taking / dining |
| History | `Icons.history_outlined` | `Icons.history` | Transaction history |

### Admin
| Destination | Unselected | Selected | Meaning |
|-------------|-----------|----------|---------|
| Dashboard | `Icons.space_dashboard_outlined` | `Icons.space_dashboard` | Overview KPIs |
| Sales | `Icons.trending_up_outlined` | `Icons.trending_up` | Sales reports |
| Food | `Icons.menu_book_outlined` | `Icons.menu_book` | Menu management |
| Accounts | `Icons.badge_outlined` | `Icons.badge` | Cashier accounts |
| Logs | `Icons.assignment_outlined` | `Icons.assignment` | Activity audit trail |

---

## Nav Rail Styling

| Property | Value |
|----------|-------|
| Width | `76px` fixed |
| Background | `AppColors.darkCharcoal` |
| Label type | `NavigationRailLabelType.none` |
| Selected icon size | `28px` |
| Selected icon color | `AppColors.goldenYellow` |
| Unselected icon size | `24px` |
| Unselected icon color | `Colors.white54` |
| Indicator | `AppColors.goldenYellow` with 20% opacity, pill shape |
| Indicator size | 40x40 rounded rectangle behind icon |
| Leading (NY logo) | 44px `CircleAvatar`, `AppColors.goldenYellow` bg, white bold "NY" |
| Destination spacing | 16px gap between items, 24px padding top/bottom of list |
| Trailing (logout) | `Colors.white54` icon, `Colors.brandRed` on hover |

### Premium touches
- Icons use `outlined` weight for clean, thin appearance
- Hover (desktop): unselected icon lightens to `Colors.white70`
- Selected indicator: subtle inner glow using `IndicatorDecoration`

---

## Bottom Nav (Mobile Cashier)

| Property | Value |
|----------|-------|
| Background | `AppColors.darkCharcoal` |
| Type | `BottomNavigationBarType.fixed` |
| Selected color | `AppColors.goldenYellow` |
| Unselected color | `Colors.white54` |
| Labels | Hidden (`showSelectedLabels: false`, `showUnselectedLabels: false`) |
| Items | Only 2 (Home, History) — no Account |

---

## Admin Drawer (Mobile)

| Property | Value |
|----------|-------|
| Background | `AppColors.darkCharcoal` |
| Header bg | `AppColors.darkCharcoal` |
| NY logo bg | `AppColors.goldenYellow`, text white |
| Title | "Admin Portal" white, "N.Y Kitchen POS" `Colors.white70` |
| Items | 5 (no Settings) |
| Selected item | `AppColors.goldenYellow` with 15% opacity bg, gold text/icon |
| Unselected item | `Colors.white70` text/icon |
| Logout | `Colors.brandRed` icon + text |
