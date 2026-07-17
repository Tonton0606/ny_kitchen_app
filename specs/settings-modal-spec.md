# Settings Side Panel Specification

> Settings opens as a flyout panel **beside the nav rail**, not a centered dialog. This follows premium kiosk POS convention (Square, Toast, Lightspeed).

---

## Trigger Points

| Trigger | Desktop/Tablet | Mobile |
|---------|---------------|--------|
| Gear icon (top-right of content area) | Opens side panel | Opens bottom sheet |
| NY logo (nav rail leading) | Opens side panel | Opens bottom sheet |

---

## Desktop/Tablet: Side Panel (Beside Nav Rail)

### Layout

```
┌──────┬──────────────────┬─────────────────────────────┐
│      │                  │                             │
│ Nav  │  Settings Panel  │  Content Area (dimmed)      │
│ Rail │  380-420px       │  black38 overlay            │
│ 76px │                  │                             │
│      │                  │  [tap anywhere to close]    │
└──────┴──────────────────┴─────────────────────────────┘
```

The panel is positioned immediately to the right of the nav rail, overlapping the content area's left edge. The remaining content area is covered by a semi-transparent (`Colors.black38`) dismissible backdrop.

### Animation
- Slide in from left (0px width → full width) over 200ms ease-out
- Backdrop fades in simultaneously
- Reverse on close

### Panel Styling

| Property | Cashier | Admin |
|----------|---------|-------|
| Width | `380px` | `500px` (scrollable) |
| Surface bg | `Colors.white` | `Colors.white` |
| Border | `Border(left: BorderSide(color: softBorder))` | same |
| Elevation | `8` (shadow cast over content) | same |
| Corner radius | 0 (flush with nav rail edge) | same |

### Content Structure

```
┌──────────────────────────────┐
│ [Close X] Header             │
│ Subtitle text                │
│                              │
│ ┌──────────────────────────┐ │
│ │   Avatar                  │ │
│ │   Name + Role             │ │
│ └──────────────────────────┘ │
│                              │
│ [Tile] Edit Profile         │
│ [Tile] Change Password      │
│ [Tile] Printer Settings     │
│ [Tile] Help & Support       │
│                              │
│ ┌──────────────────────────┐ │
│ │ Profile Details card     │ │
│ │ (admin only)             │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ App Preferences card     │ │
│ │ (admin only)             │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

### Tile Styling
- Flat cards: `Colors.white` bg, `softBorder` outline (1px), 12px radius, 0 elevation
- Leading icon: `AppColors.goldenYellow` on 10% gold bg, 40x40 container, 12px radius
- Title: 16px semi-bold `darkCharcoal`
- Trailing: chevron right `mutedText`
- 12px margin bottom between tiles

---

## Mobile: Bottom Sheet

- `showModalBottomSheet` with `isScrollControlled: true`
- Top corners: 16px radius
- Background: `Colors.white`
- Height: 85% of screen
- Header with "Account Settings" title + close `IconButton` at right
- Standard scrollable content

---

## Color Rules

| Element | Color |
|---------|-------|
| Panel background | `Colors.white` |
| Panel border left | `AppColors.softBorder` |
| Header title | `AppColors.darkCharcoal`, 22px bold |
| Header subtitle | `AppColors.mutedText`, 14px |
| Close icon | `AppColors.darkCharcoal`, 24px |
| Tile card bg | `Colors.white` |
| Tile card border | `AppColors.softBorder` |
| Tile icon bg | `AppColors.goldenYellow` at 10% opacity |
| Tile icon color | `AppColors.goldenYellow` |
| Tile title | `AppColors.darkCharcoal`, 16px medium |
| Divider | `AppColors.softBorder` |
| Save button bg | `AppColors.goldenYellow`, text black |
