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

## Color Palette (Phase 1 implementation)
| Role | Color | Use |
|---|---|---|
| Primary seed | Deep amber-yellow (#FFB300) | Main actions, buttons, highlights |
| Tertiary | Dark amber (#7C5800) | Secondary accents and warnings |
| Success | Green (#2E7D32) | Completed and active states |
| Info | Blue (#1565C0) | Informational status and metrics |
| Surface | Material 3 surface tones | Cards, panels, backgrounds |
| On-Surface | Material 3 on-surface tones | Text and icons on light surfaces |

> Implemented tokens are defined in `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart`.

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
