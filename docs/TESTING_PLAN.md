# docs/TESTING_PLAN.md
# N.Y Kitchen — Testing Plan

---

## Purpose
Define the testing strategy for all application phases.

---

## Testing Levels

### Unit Testing
- All service methods.
- All repository methods.
- All validation rules.
- Password hashing.
- Transaction logic.

### Widget Testing
- Login screen.
- Admin Dashboard.
- Cashier Home / New Order.
- Checkout flow.
- Receipt preview.

### Integration Testing
- Full checkout workflow.
- Full login and authentication flow.
- Backup and restore flow.
- Activity log generation for all events.

### Security Testing
- See: docs/SECURITY_TESTING.md

### Responsive Testing
- Android phone (portrait and landscape).
- Android tablet (portrait and landscape).
- Windows desktop (various window sizes).

### Offline Testing
- Verify all core features work without internet.
- Verify sync queue behavior on reconnection.

---

## Test Environments
- Local development machine.
- Android emulator and physical devices.
- Windows desktop.

---

## TODO
- [ ] Set up test infrastructure before Phase 2
- [ ] Write unit tests starting Phase 3
- [ ] Complete all tests before Phase 10
