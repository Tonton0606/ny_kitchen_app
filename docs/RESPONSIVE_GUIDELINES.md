# docs/RESPONSIVE_GUIDELINES.md
# N.Y Kitchen — Responsive Design Guidelines

> Source of Truth: PROJECT_BLUEPRINT.md Section 12

---

## Purpose
Define breakpoints and layout rules for all target screen sizes.

---

## Breakpoints (Proposed)

| Device | Min Width | Layout |
|---|---|---|
| Mobile Phone | < 600dp | Drawer nav, single column, bottom sheet checkout |
| Tablet | 600dp - 1200dp | Compact sidebar, 2-column, floating checkout panel |
| Desktop | > 1200dp | Fixed sidebar, 3-panel POS layout |

## Desktop Layout (Cashier Home)
- Left Panel: Navigation + Food Categories
- Center Panel: Food Menu Grid
- Right Panel: Current Order Preview

## Tablet Layout
- Compact sidebar (icons + labels)
- Responsive food grid (2-3 columns)
- Responsive data tables
- Floating checkout panel

## Mobile Layout
- Drawer navigation
- Single column layout
- Floating cart button
- Bottom sheet for checkout
- Cards instead of tables for transaction lists

## Rules
- Large desktop tables must convert to card layouts on mobile.
- Touch targets must be at least 48dp on mobile and tablet.
- Text must be readable without zooming.
- All forms must be usable on touch interfaces.

---

## TODO
- [ ] Validate responsive layouts on actual devices during Phase 10
