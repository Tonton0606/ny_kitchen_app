# docs/ACCESSIBILITY.md
# N.Y Kitchen — Accessibility Requirements

---

## Purpose
Define accessibility requirements to ensure the application is usable by all users.

---

## Standards Target
- WCAG 2.1 Level AA (target)
- Flutter Semantics API for screen reader support

## Requirements
- All text must meet minimum contrast ratio (4.5:1 for body, 3:1 for large text).
- All interactive elements must have semantic labels.
- Touch targets must be at least 48x48dp.
- Forms must have clear labels and error messages.
- Navigation must be operable by keyboard on desktop.
- Focus management must be logical and predictable.

## Implementation Notes
- Use Flutter Semantics widgets (Semantics, MergeSemantics, ExcludeSemantics).
- Use semanticsLabel on icons without visible text.
- Test with TalkBack (Android) and Narrator (Windows).

---

## TODO
- [ ] Conduct accessibility audit during Phase 10
- [ ] Test with screen readers on Android and Windows
