# docs/DESIGN_SYSTEM.md
# N.Y Kitchen — Design System

> Source of Truth: PROJECT_BLUEPRINT.md Section 12.5

---

## Purpose
Define the design tokens, component specifications, and visual language for N.Y Kitchen.

---

## Color Tokens (To Be Finalized)

```
// Provisional — Define exact hex values before Phase 1 prototype
Primary:         #FFD600  (Yellow)
PrimaryVariant:  #F9A825
Secondary:       #D32F2F  (Red)
Surface:         #FFFFFF  (White)
Background:      #F5F5F5
OnPrimary:       #000000  (Black)
OnSurface:       #212121
Error:           #B00020
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
- [ ] Finalize all color tokens before Phase 1 prototype
- [ ] Create component library in Figma
- [ ] Link Figma file in docs/FIGMA_INTEGRATION.md
