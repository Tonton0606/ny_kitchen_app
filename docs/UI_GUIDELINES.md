# docs/UI_GUIDELINES.md
# N.Y Kitchen — UI Guidelines

> Source of Truth: PROJECT_BLUEPRINT.md Section 12

---

## Purpose
Define the visual design standards for all UI components in N.Y Kitchen.

---

## Design Foundation
- Material 3 (Flutter useMaterial3: true)
- N.Y Kitchen branding: Yellow, Red, White, Black palette

## Color Palette (Provisional)
| Role | Color | Use |
|---|---|---|
| Primary | Yellow (#FFD600 approx) | Main actions, buttons, highlights |
| Secondary | Red (#D32F2F approx) | Alerts, delete actions, warnings |
| Surface | White | Cards, panels, backgrounds |
| On-Surface | Black | Text, icons on light surfaces |

> Exact Material 3 color tokens TBD. Define in docs/DESIGN_SYSTEM.md.

## Typography
- Use Material 3 text theme defaults.
- Headings must be clear and legible.
- Body text must meet WCAG AA contrast minimum (4.5:1).

## Component Standards
- All interactive elements must have visible focus indicators.
- Loading states must use CircularProgressIndicator or Shimmer.
- Empty states must provide a helpful message and action.
- Error states must display a user-friendly message.
- Confirmation dialogs required for all destructive actions (delete, void, logout).

## Icons
- Material Icons (primary)
- Lucide Icons (secondary, if available for Flutter)

---

## TODO
- [ ] Define complete color token set in docs/DESIGN_SYSTEM.md
- [ ] Create UI mockups in Figma before Phase 1 prototype
