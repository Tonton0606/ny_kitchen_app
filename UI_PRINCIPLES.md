# N.Y Kitchen POS: UI Principles

Single source of truth for all UI work. It supersedes every older UI document. Read it before changing any UI. If a change breaks a rule here, say why in the summary.

Scope: UI only. No business logic, database, security, sync, or auth changes.

## 1. Core idea
A POS is used all day by busy people. The UI must be fast to scan, honest, and calm. Hierarchy comes from size, weight, and spacing, not from boxes, colors, or decoration.

## 2. Honesty (highest priority)
1. Never show data that is not computed from real state. No hardcoded deltas, badges, counts, or statuses.
2. If there is no data, say so ("No previous data", "No sales yet"). Never show fake zeros as trends.
3. Every panel on a screen obeys the screen's filter (Today / Week / Month). If a panel uses a different scope, label it ("Latest 5 orders, all time").
4. Labels must be literally true. "On shift" means on shift. "Synced" means synced.
5. Status indicators (Online, Sync off, Printer) reflect live state, including the failed and disabled cases.

## 3. Tokens (no inline values)
All values live in lib/core/theme/. If a token is missing, add it there first.
- Spacing: 4, 8, 12, 16, 24, 32
- Corner radius: one value everywhere (currently 12)
- Icons: Lucide, thin stroke, 18-20 px in content, 20-24 px in nav

### 3a. Typography roles
Five roles defined in the theme (max 2 font families total):
- Figure: a distinct face used ONLY for numbers (hero revenue, stat values, amounts, counts), bold, tabular figures. Hero 32px+, other figures 18-24px.
- Heading: clean UI sans for section titles ("Sales Trend", "Recent Transactions", "Top Selling Foods"), 16-18px, weight 600, normal letter-spacing, visibly lighter than the hero figure.
- Body: same sans, 14px, weight 400 (row text, names, descriptions).
- Label: 11-12px, UPPERCASE, weight 600, +0.5 letter-spacing, muted (must still pass 4.5:1). Used for stat captions, table headers, the date line.
- Button: same sans, 14px, weight 600, sentence case, NOT uppercase. Used for Quick Actions, toggles (Today/Week/Month), View All, and any other tappable text.

Typography rules:
- Figure face only for numbers.
- Heading is never uppercase.
- Label is the only uppercase role.
- No TextStyle literals in screen files.
- All five roles come from the theme.
Rules:
- No Color(0x...), Colors.xxx, raw EdgeInsets/SizedBox numbers, or fontSize literals in screen files.
- Numbers use tabular figures so columns line up.
- Money uses one formatter (peso sign, two decimals) everywhere.

## 4. Color
- Neutral surfaces: page background a subtle gray, cards flat white.
- One accent: brand yellow. Use it only as a fill (active nav item, primary button, rank badge) with dark text on top.
- Never yellow text on a light background.
- Green and red only for real positive and negative values, or success and error states.
- Text contrast must meet WCAG AA (4.5:1). Muted text must still pass.
- Do not rely on color alone. Pair status colors with an icon or label.

## 5. Layout and hierarchy
1. One primary focus per screen (e.g. Today's Revenue on the dashboard). Make it clearly larger, not just wider.
2. Secondary info is quiet: smaller, muted, no extra boxes.
3. Group with spacing and background tone, not outlines. No boxes inside boxes.
4. Cards: flat white, no border, no shadow, or one very subtle shadow. A single border is allowed only for table row dividers and inputs.
5. Align everything to a grid. Columns share the same gutters and the same top and bottom edges.
6. Tables use the full card width. Header: 12px, muted. Rows: 14px. Money columns right-aligned.
7. Do not duplicate navigation. If the sidebar has it, a screen does not need a big tile for it.
8. One title per screen. No breadcrumb plus a repeated heading.
9. Desktop-first. Must work at 1280x720 and 1920x1080 with no overflow. Scrollable regions scroll; the page does not clip.

## 6. Components (build once, reuse)
Use shared widgets. If a pattern appears twice, extract it: page header, stat/KPI (hero and compact), card/section container, data table, primary/secondary/text buttons (one style each), dialog/modal (one style), empty/loading/error states, status chip, form field.
Buttons: one primary action per area. Compact rows or small buttons with icon and label vertically centered, never tall boxes with top-left content.

## 7. States (every screen handles all four)
- Empty: short message, one clear action. No empty axes or bare table headers.
- Loading: skeleton or subtle spinner in place. No layout jump.
- Error: plain-language message and a retry action. No stack traces.
- Populated: the designed view.

## 8. Interaction and accessibility
- Icon-only buttons have tooltips.
- Click and tap targets at least 40px (48px if a touch layout is ever added).
- Visible hover and focus states on everything clickable, including title bar buttons.
- Destructive actions (delete, restore, reset) need a confirm step with specific wording.
- Keyboard: logical Tab order, Enter submits, Esc closes dialogs.
- Motion: short (150-200 ms), purposeful, never decorative. No glows, gradients, or flourishes.
- Interactive text and button labels use the Button role (14px, 600, sentence case).

## 9. Never put in exports or screens
password_hash, face_encoding, secrets, or tokens. Not in tables, not in reports, not in debug text.

## 10. Per-screen checklist
- [ ] Reads as one clear focus, then secondary, then detail
- [ ] No hardcoded or fake data; every label is true
- [ ] Filters apply to every panel, or the scope is labeled
- [ ] Only tokens used; no inline colors, sizes, or spacing
- [ ] Every text element uses one of the five typography roles (no inline TextStyle)
- [ ] No yellow text on light backgrounds; contrast passes AA
- [ ] No outlined box inside another box; one radius
- [ ] Grid aligned; no overflow at 1280x720 and 1920x1080
- [ ] Empty, loading, and error states exist
- [ ] Tooltips on icon-only controls; hover and focus visible
- [ ] Uses shared components; nothing copy-pasted
- [ ] flutter analyze and flutter test (full, not subsets) pass

## 11. Workflow rules for the AI assistant
- Do NOT run git add, commit, push, or any state-changing git command. The owner commits manually. Read-only git status and git diff are fine.
- Plan in 3-5 lines first, implement one screen or phase only, then stop.
- Do not rewrite a whole file when a targeted edit works.
- Do not touch screens outside the current phase. Report issues found elsewhere instead of fixing them.
- Finish with: files changed, what visibly changed, what to check manually.
