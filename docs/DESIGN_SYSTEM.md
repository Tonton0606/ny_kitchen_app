# docs/DESIGN_SYSTEM.md
# N.Y Kitchen — Design System & Tokens

> **Authority Level: HIGH**  
> Source of Truth: `PROJECT_BLUEPRINT.md` Section 12.5 & `docs/UI_GUIDELINES.md`.

---

## 1. Design Tokens Overview

N.Y Kitchen POS is built on an ultra-clean, tactile design system with slate borders, crisp white cards, and golden yellow accents.

```dart
// Core Token Constants (lib/core/theme/app_colors.dart)
Primary Accent:   Color(0xFFFFCA05) // AppColors.goldenYellow (Active pills, CTAs, Highlights)
Dark Charcoal:    Color(0xFF2B241A) // AppColors.darkCharcoal (Primary text, dark elements)
Muted Slate:      Color(0xFF64748B) // AppColors.mutedText (Secondary text, subtitles, overlines)
Slate Border:     Color(0xFFE2E8F0) // AppColors.softBorder / AppColors.slateBorder (Hairline 1px)
Canvas Off-White: Color(0xFFF8FAFC) // AppColors.canvasBackground (Clean slate-50 canvas)
Surface White:    Color(0xFFFFFFFF) // AppColors.surfaceWhite (Cards, sheets, modals)
Forest Green:     Color(0xFF2E7D4F) // AppColors.forest (Paid, in-stock, synced)
Ink Blue:         Color(0xFF2F6F8F) // AppColors.inkBlue (Info, preparing)
Brand Red:        Color(0xFFD9271C) // AppColors.brandRed (Destructive, errors, void)
```

---

## 2. Geometry & Spacing Scale

### Spacing Scale
- `space4`: `4.0` dp
- `space8`: `8.0` dp
- `space12`: `12.0` dp
- `space16`: `16.0` dp
- `space24`: `24.0` dp
- `space32`: `32.0` dp

### Corner Radii Scale
- `radius8`: `8.0` dp (inputs, small chips)
- `radius12`: `12.0` dp (buttons, inner action tiles, form containers)
- `radius16`: `16.0` dp (primary cards, panels, modals)
- `radius20`: `20.0` dp (filter pills, segmented controls)
- `radius24`: `24.0` dp (status badges, circular chips)

### Borders & Shadows
- **Card Border**: `Border.all(color: Color(0xFFE2E8F0), width: 1.0)`
- **Ambient Shadow**:
  ```dart
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ]
  ```

---

## 3. Typography Hierarchy (`AppTypography`)

| Role | Style Definition | Usage |
|---|---|---|
| **Overline** | `11px`, `w700`, `letterSpacing: 0.8`, uppercase, muted slate | Category badges, stat labels |
| **Hero Metric** | `32px`, `w800`, `letterSpacing: -0.5`, tabular figures, dark charcoal | Top-level KPI numerals |
| **Page Title** | `22px`, `w800`, `letterSpacing: -0.4`, dark charcoal | Page app bar header |
| **Section Title** | `16px`, `w700`, `letterSpacing: -0.2`, dark charcoal | Card headers, table titles |
| **Card Title** | `14px`, `w600`, dark charcoal | Food item titles, row labels |
| **Card Subtitle** | `12px`, `w500`, muted slate | Metadata, descriptions |
| **Table Header** | `12px`, `w700`, `letterSpacing: 0.3`, muted slate | Data table headers |
| **Table Cell** | `13px`, `w600`, dark charcoal | Table item content |
| **Tabular Price** | `14px`, `w700`, tabular figures, dark charcoal | ₱ totals, prices, quantities |

---

## 4. Reusable Component Patterns

### A. Segmented Control / Filter Pill
```dart
Container(
  padding: const EdgeInsets.all(3),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  ),
  child: Row(
    children: [
      _buildPill('Today', isSelected: true),
      _buildPill('Week', isSelected: false),
    ],
  ),
);
```

### B. Standard Metric Card
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('TOTAL REVENUE', style: AppTypography.overline),
      const SizedBox(height: 8),
      Text('₱48,920.00', style: AppTypography.heroMetric),
    ],
  ),
);
```

### C. Standard Modal Dialog
```dart
Dialog(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: Color(0xFFE2E8F0)),
  ),
  child: ...
)
```
