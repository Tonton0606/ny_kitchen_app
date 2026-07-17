# Visual Polish & Design Philosophy

> High-contrast, functional typography. Intentional whitespace. No-nonsense flat layouts. Sleek muted dark mode.

---

## 1. Design Philosophy

### High-Contrast, Functional Typography
- Clean sans-serif (Material default `Roboto` / system)
- Scannable hierarchies: bold titles (22-24px), medium body (15-16px), light captions (12-13px)
- High contrast ratios: `darkCharcoal` text on white bg, white text on `darkCharcoal` bg
- Never use grey-on-grey — always ≥ 4.5:1 contrast

### Intentional Whitespace
- Generous padding: 24px margins everywhere, 16px between items, 32px between sections
- No decorative graphics or illustrations — space IS the design element
- Content breathes. If it feels empty, leave it empty — don't add filler.

### No-Nonsense Layouts
- Flat grid systems. Cards use `border` not `elevation` for separation.
- No gradients, no heavy shadows, no 3D effects.
- Structural cognitive load kept low: everything aligns to a 4px/8px grid.

### Sleek Dark Mode Aesthetics
- `AppColors.darkCharcoal` (`#2B241A`) is a **warm, muted dark** — not pure black (`#000000`)
- This reduces eye strain while maintaining a premium night-mode feel
- Nav rails, drawers, and mobile app bars use this background
- Content areas remain light (`Colors.white` / `AppColors.creamBackground`) for readability

---

## 2. Color Token Reference

| Token | Hex | Usage | Contrast |
|-------|-----|-------|----------|
| `AppColors.darkCharcoal` | `#2B241A` | Nav bg, drawer bg, dark surfaces | White text on this = ~12:1 |
| `AppColors.goldenYellow` | `#FFCA05` | Active icons, indicators, CTAs | Black text on gold = ~8:1 |
| `AppColors.brandRed` | `#D9271C` | Logout, destructive actions | White on red = ~6:1 |
| `AppColors.creamBackground` | `#FFF8E7` | Page/modal surfaces (warm) | Dark text on cream = ~15:1 |
| `Colors.white` | `#FFFFFF` | Panel surfaces, cards | Best contrast for body text |
| `AppColors.mutedText` | `#6F675C` | Secondary text, subtitles | On white = ~6:1 ✓ |
| `AppColors.softBorder` | `#E7DCCB` | Dividers, card outlines | Subtle, 1px |
| `Colors.white54` | 54% white | Unselected icons on dark | On darkCharcoal = OK |
| `Colors.white70` | 70% white | Secondary text on dark | On darkCharcoal = good |

---

## 3. Typography Scale

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Page title | 24px | Bold (700) | `darkCharcoal` |
| Section header | 20px | Bold (700) | `darkCharcoal` |
| Panel title | 22px | Bold (700) | `darkCharcoal` |
| Panel subtitle | 14px | Normal (400) | `mutedText` |
| Tile title | 16px | Medium (500) | `darkCharcoal` |
| Body text | 15px | Normal (400) | `darkCharcoal` |
| Caption | 13px | Normal (400) | `mutedText` |
| Label (forms) | 14px | Medium (500) | `darkCharcoal` |
| Badge/chip | 12px | Bold (700) | per context |

---

## 4. Spacing System

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 4px | Icon gaps, fine adjustments |
| `xs` | 8px | Tight spacing, icon padding |
| `sm` | 12px | Tile margins, chip padding |
| `md` | 16px | Section gaps, list item padding |
| `lg` | 24px | Page margins, card padding |
| `xl` | 32px | Section separation |
| `xxl` | 48px | Major layout gaps |

---

## 5. Card & Surface Rules

| Element | Style |
|---------|-------|
| Settings tiles / cards | `Colors.white`, `softBorder` 1px border, 12px radius, 0 elevation |
| Card leading icon bg | 40x40 `goldenYellow` at 10% opacity, 12px radius |
| Card leading icon | `goldenYellow`, 24px |
| Dividers | `softBorder`, 1px height |
| Modal panel surface | `Colors.white` |
| Page background (light) | `Colors.white` (preferred over cream for readability) |

---

## 6. Transition Philosophy

- Side panel: 200ms ease-out slide + fade
- Bottom sheet: default platform animation (slide-up)
- Page swaps: no animation (instant `setState` replacement)
- Keep transitions minimal — performance and directness over flash
