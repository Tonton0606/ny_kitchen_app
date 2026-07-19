# docs/DESIGN_SYSTEM.md
# N.Y Kitchen — Design System

> Source of Truth: PROJECT_BLUEPRINT.md Section 12.5

---

## Purpose
Define the design tokens, component specifications, and visual language for N.Y Kitchen.

---

## Color Tokens (Phase 1 implementation)

```
Primary seed:    #FFB300  (deep amber-yellow)
Tertiary:        #7C5800  (dark amber)
Success:         #2E7D32  (semantic success)
Info:            #1565C0  (semantic information)
Color system:    Material 3 `ColorScheme.fromSeed` in `lib/core/theme/app_theme.dart`
```

## Typography Scale

| Role | Size | Weight |
|---|---|---|
| Display Large | 57sp | Regular |
| Headline Medium | 28sp | Regular |
| Title Large | 22sp | Medium |
| Body Large | 16sp | Regular |
| Label Large | 14sp | Medium (buttons) |

## Spacing Scale
- 4dp base unit
- Common: 4, 8, 12, 16, 24, 32, 48

## Elevation / Shadow
- Material 3 tonal elevation (color-based, not shadow)

## Border Radius
- Cards: 12dp
- Buttons: 8dp
- Dialogs: 16dp
- Bottom Sheets: 16dp top corners

## Component States
- Default
- Hover (Desktop)
- Pressed
- Focused
- Disabled
- Loading
- Empty
- Error

---

## TODO
- [x] Finalize Phase 1 color tokens in `lib/core/theme/app_colors.dart`
- [ ] Create component library in Figma
- [ ] Link Figma file in docs/FIGMA_INTEGRATION.md
