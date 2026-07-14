# docs/TEST_CASES.md
# N.Y Kitchen — Test Cases

---

## Purpose
Document specific test cases for critical application features.

---

## TC-AUTH-001: Successful Admin Login
- Input: Valid Admin username and password
- Expected: Redirect to /admin/dashboard, Activity Log created

## TC-AUTH-002: Failed Login — Wrong Password
- Input: Valid username, wrong password
- Expected: Error message "Invalid username or password." displayed, failed_login_count incremented

## TC-AUTH-003: Account Lockout
- Input: Valid username, wrong password repeated N times (N = lockout threshold)
- Expected: Account locked, lockout message shown, Activity Log created

## TC-AUTH-004: Cashier Accesses Admin Route
- Input: Logged-in Cashier attempts to navigate to /admin/dashboard
- Expected: Redirect to /unauthorized, Activity Log created

## TC-ORDER-001: Successful Order Checkout
- Input: Cashier adds items to cart, selects Cash payment, confirms
- Expected: Receipt generated, transaction saved to SQLite, Activity Log created, receipt preview shown

## TC-ORDER-002: Empty Cart Checkout Attempt
- Input: Cashier attempts checkout with no items in cart
- Expected: Validation error "Please add at least one item to the order."

## TC-TXN-001: Transaction Cannot Be Deleted
- Input: Admin attempts to delete a completed transaction
- Expected: No delete option available. Transaction status changes only.

## TC-LOG-001: Activity Log Immutability
- Input: Admin attempts to edit or delete an Activity Log entry
- Expected: No edit or delete option available in the UI.

## TC-MENU-001: Archive Food Item
- Input: Admin archives a food item that exists in past transactions
- Expected: Item removed from new order menu. Item still visible on historical receipts.

## TC-BKP-001: Database Backup
- Input: Admin triggers manual backup
- Expected: Backup file created, backup record saved, Activity Log created

## TC-BKP-002: Database Restore
- Input: Admin selects a backup file and confirms restore
- Expected: Existing database preserved until restore completes. Activity Log created.

---

## TODO
- [ ] Expand test cases for all modules before Phase 10
- [ ] Convert to automated tests where possible
