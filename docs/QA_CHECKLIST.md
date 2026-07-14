# docs/QA_CHECKLIST.md
# N.Y Kitchen — QA Checklist

---

## Purpose
Provide a comprehensive QA checklist to be completed before each phase sign-off.

---

## Functional Checks
- [ ] Login works for Admin
- [ ] Login works for Cashier
- [ ] Login fails for wrong password (correct error message)
- [ ] Account locks after repeated failures
- [ ] Admin Dashboard displays correct analytics
- [ ] Cashier can process a complete order
- [ ] Receipt is generated correctly
- [ ] Transaction is saved to SQLite
- [ ] Activity Log is created for each tracked event
- [ ] Void transaction requires reason and Admin auth
- [ ] Refund transaction requires reason and Admin auth
- [ ] Completed transactions cannot be deleted
- [ ] Activity Logs cannot be edited
- [ ] Admin can manage users (create, edit, activate, deactivate)
- [ ] Final Admin cannot deactivate itself
- [ ] Reports generate correct data
- [ ] Backup and restore work correctly

## Responsive Checks
- [ ] Login screen: phone, tablet, desktop
- [ ] Cashier home: 3-panel desktop, tablet, phone bottom sheet
- [ ] Admin dashboard: mobile card layout, tablet, desktop
- [ ] Tables convert to cards on mobile
- [ ] Touch targets are minimum 48dp on mobile

## Security Checks
- [ ] Cashier cannot access Admin routes
- [ ] Passwords are not visible in database
- [ ] No SQL injection vulnerabilities
- [ ] No credentials in source code
- [ ] Activity logs are immutable

## Accessibility Checks
- [ ] Color contrast meets WCAG AA
- [ ] Touch targets are 48dp minimum
- [ ] Screen reader labels present on icon-only buttons

---

## TODO
- [ ] Complete QA checklist before Phase 10 sign-off
