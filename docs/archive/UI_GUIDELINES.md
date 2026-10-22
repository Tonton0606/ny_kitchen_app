SUPERSEDED: do not follow. See /UI_PRINCIPLES.md.

# docs/archive/UI_GUIDELINES.md
# N.Y Kitchen — Archived UI Guidelines

> **Authority Level: HIGH**  
> Source of Truth: `PROJECT_BLUEPRINT.md` Section 12 & `AI_DEVELOPMENT_RULES.md` Section 8.  
> Every engineer and AI agent updating or creating pages across N.Y Kitchen (both Cashier and Admin modules) must strictly adhere to these principles.

---

## 1. System Philosophy & Aesthetic Vision

The N.Y Kitchen POS & Administration interface is built on a **clean, modern, flat-tactile aesthetic**. It eliminates visual noise, ad-hoc gradients, and dark clutter, delivering a high-contrast, effortless operating environment for fast restaurant workflows:

1. **Light & Crisp Surfaces**: The application uses a soft slate off-white canvas (`#F8FAFC`) with pure solid white cards (`#FFFFFF`).
2. **Hairline Subtle Borders**: Cards and panels rely on precision 1px borders (`#E2E8F0`) rather than heavy drop shadows.
3. **Intentional Accent Color**: Golden Yellow (`AppColors.goldenYellow`) is reserved exclusively for high-intent actions (active navigation pills, primary CTAs, top rank badges).
4. **Information Hierarchy**: Bold tabular numerals, clear uppercase overlines, and muted metadata ensure instant scannability during peak service hours.

---

## 2. Canvas & Surface Hierarchy

| Element | Specification | Visual Purpose |
|---|---|---|
| **Canvas / Background** | `Color(0xFFF8FAFC)` (`AppColors.canvasBackground`) | Soft, clean off-white / slate-50 base layer. |
| **Cards & Containers** | `Colors.white` (`#FFFFFF` / `AppColors.surfaceWhite`) | Clean content islands. Never use colored backgrounds or gradients for containers. |
| **Card Borders** | `Border.all(color: Color(0xFFE2E8F0), width: 1.0)` | Subtle hairline delimiter creating clean geometric structure. |
| **Card Radius** | `BorderRadius.circular(16)` (`AppDesignTokens.borderRadius16`) | Primary cards, panels, charts, modal dialog containers. |
| **Element Radius** | `BorderRadius.circular(12)` (`AppDesignTokens.borderRadius12`) | Inner action tiles, list rows, form input fields, table action buttons. |
| **Badge / Pill Radius** | `BorderRadius.circular(20)` to `24` | Status badges, category filters, segmented tabs, count chips. |
| **Elevation & Shadows** | Flat and subtle ambient elevation: `BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))` | Minimal elevation, no dark or heavy drop shadows. |
| **Modal Dialogs & Sheets** | `Colors.white`, `surfaceTintColor: Colors.transparent`, `Border.all(color: Color(0xFFE2E8F0))` | High-focus pure white modals with crisp hairline borders. |

---

## 3. Color Palette & Semantic Tokens

All colors must be referenced through `AppColors`:

```
Brand Primary Accent:   #FFCA05 / #FFC107  (AppColors.goldenYellow)
Primary Text / Header:  #1E293B / #2B241A  (AppColors.darkCharcoal)
Secondary / Muted Text: #64748B            (AppColors.mutedText / AppColors.mutedSlate)
Hairline Slate Border:  #E2E8F0            (AppColors.softBorder / AppColors.slateBorder)
Canvas Background:      #F8FAFC            (AppColors.canvasBackground / AppColors.creamBackground)
Card Surface:           #FFFFFF            (AppColors.surfaceWhite)
```

### Semantic Status Colors
- **Success / In-Stock / Paid / Online**: Forest Green (`#16A34A` / `#2E7D4F` — `AppColors.forest`). Background tint: `Color(0xFFDCFCE7)` with `#166534` text.
- **Info / Syncing / Preparing**: Ink Blue (`#2563EB` / `#2F6F8F` — `AppColors.inkBlue`). Background tint: `Color(0xFFEFF6FF)` with `#1E40AF` text.
- **Warning / Low-Stock / Offline**: Amber / Gold Tint (`#F59E0B` — `AppColors.goldTint`). Background tint: `Color(0xFFFEF3C7)` with `#92400E` text.
- **Destructive / Error / Void / Out-of-Stock**: Brand Red (`#DC2626` / `#D9271C` — `AppColors.brandRed`). Background tint: `Color(0xFFFEE2E2)` with `#991B1B` text.

---

## 4. Typography Scale & Standards (`AppTypography`)

Use `AppTypography` tokens rather than inline `TextStyle` declarations:

| Token | Size | Weight | Tracking / Feature | Color | Usage |
|---|---|---|---|---|---|
| `AppTypography.overline` | 11px | `FontWeight.w700` | `letterSpacing: 0.8`, Uppercase | `AppColors.mutedText` | Category tags, metric labels, section overlines |
| `AppTypography.heroMetric` | 32px | `FontWeight.w800` | `letterSpacing: -0.5`, Tabular figures | `AppColors.darkCharcoal` | Hero KPI values (e.g. ₱48,920.00, 142 Orders) |
| `AppTypography.pageTitle` | 22px | `FontWeight.w800` | `letterSpacing: -0.4` | `AppColors.darkCharcoal` | Top navigation page headers |
| `AppTypography.sectionTitle` | 16px | `FontWeight.w700` | `letterSpacing: -0.2` | `AppColors.darkCharcoal` | Card titles, modal headers, table titles |
| `AppTypography.cardTitle` | 14px | `FontWeight.w600` | Standard | `AppColors.darkCharcoal` | Food item names, list item titles, form labels |
| `AppTypography.cardSubtitle` | 12px | `FontWeight.w500` | Standard | `AppColors.mutedText` | Descriptions, timestamps, secondary status |
| `AppTypography.tableHeader` | 12px | `FontWeight.w700` | `letterSpacing: 0.3` | `AppColors.mutedText` | Data table column headers |
| `AppTypography.tableCellPrimary`| 13px| `FontWeight.w600` | Standard | `AppColors.darkCharcoal` | Order IDs, food names, main table cells |
| `AppTypography.tabularPrice` | 14px | `FontWeight.w700` | `FontFeature.tabularFigures()` | `AppColors.darkCharcoal` | Currency, prices, quantities, numerical totals |

---

## 5. Layout & Grid Architecture

- **Page Padding**: Standard outer margin is uniform `EdgeInsets.all(24)`. For mobile or compact views, reduce to `EdgeInsets.all(16)`.
- **Top Header Bar**:
  - **Left**: Page title accompanied by role/context pill (e.g., `Sales Reports  ADMIN • System Administrator`).
  - **Right**: Real-time status cluster (Online status pill with animated green indicator, Cloud Sync badge, Live Digital Clock).
- **Metric Cards Grid**:
  - Top row consists of 3–4 metric cards or a hero metric split card.
  - High-emphasis numbers must use `AppTypography.heroMetric` or `AppTypography.metricValue` with tabular figures.
- **Data Tables & Lists**:
  - Wrapped inside a white card with hairline border and 16px radius.
  - Column headers styled with `AppTypography.tableHeader`.
  - Row dividers must use `Divider(height: 1, color: AppColors.softBorder)`.
  - Empty states must present a clean vector icon, 16px title, 12px muted subtitle, and a primary action button.

---

## 6. Buttons, Controls & Inputs

1. **Segmented Filter Pills** (e.g., `[ Today | Week | Month ]`):
   - Container: Pure white with `Border.all(color: Color(0xFFE2E8F0))` and `BorderRadius.circular(20)`.
   - Active Pill: `color: AppColors.goldenYellow`, bold text (`color: AppColors.darkCharcoal`).
   - Inactive Pill: Transparent background, `color: AppColors.mutedText`.
2. **Primary Action Buttons** (e.g., "Add Item", "Checkout", "Open POS"):
   - Background: `AppColors.goldenYellow`.
   - Text/Icon: `AppColors.darkCharcoal`, `FontWeight.w700`.
   - Radius: `BorderRadius.circular(12)`.
   - Minimum touch target: 48dp (56dp for checkout CTA).
3. **Secondary / Outlined Action Buttons**:
   - Background: Pure white `Colors.white`.
   - Border: `Border.all(color: Color(0xFFE2E8F0), width: 1.0)`.
   - Radius: `BorderRadius.circular(12)`.
   - Subtle hover feedback.
4. **Form Inputs & Dropdowns**:
   - Filled pure white `Colors.white`.
   - Outline border: `BorderSide(color: Color(0xFFE2E8F0), width: 1.0)`.
   - Focused border: `BorderSide(color: AppColors.goldenYellow, width: 1.5)`.
   - Border radius: `BorderRadius.circular(12)`.

---

## 7. Icons & Visual Assets

- **Vector Icons Only**: Use vector icons (`LucideIcons` or `Icons`). Never use heavy network images or emoji characters for category icons or controls.
- **Fast Local Icon Picker**: Use `FoodIconPickerDialog` for category icon assignment (zero network latency, categorized tabs, live search).
- **Placeholder Imagery**: Never use broken URLs or generic external placeholders; use themed local vector icon containers.

---

## 8. Checklist for New / Updated Pages

Before submitting any page review:
- [ ] Is the page background `Color(0xFFF8FAFC)`?
- [ ] Are all cards pure solid white (`#FFFFFF`) with `#E2E8F0` hairline borders and 16px corner radius?
- [ ] Is `AppColors.goldenYellow` used strictly for active states, primary CTAs, and top badges?
- [ ] Are all monetary values and numbers using `AppTypography.tabularPrice` or tabular figures?
- [ ] Are dialogs pure white with `surfaceTintColor: Colors.transparent`?
- [ ] Do data tables and scroll views have dedicated `ScrollController`s attached to their `Scrollbar`s?
