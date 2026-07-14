# docs/SECURITY_TESTING.md
# N.Y Kitchen — Security Testing Plan

---

## Purpose
Define security testing procedures for N.Y Kitchen.

---

## Security Tests

### Authentication Testing
- [ ] Attempt login with incorrect password — verify error message does not reveal username existence
- [ ] Attempt login with non-existent username — verify same error message
- [ ] Trigger account lockout — verify threshold, lockout message, Activity Log
- [ ] Attempt login with locked account — verify rejection
- [ ] Test session expiration — verify automatic logout

### Authorization Testing
- [ ] Attempt to access Admin routes as Cashier — verify redirect to /unauthorized and Activity Log
- [ ] Attempt to access Admin routes without login — verify redirect to /login
- [ ] Verify Cashier cannot view Admin Dashboard, Reports, Activity Logs, User Management
- [ ] Verify route guards cannot be bypassed by URL manipulation

### Injection Testing
- [ ] Attempt SQL injection through search fields
- [ ] Attempt SQL injection through login fields
- [ ] Attempt SQL injection through food name/description fields
- [ ] Verify all queries use parameterized statements

### Data Integrity Testing
- [ ] Attempt to delete a completed transaction — verify rejection
- [ ] Attempt to edit an activity log — verify rejection
- [ ] Verify void/refund requires Admin authorization and reason
- [ ] Verify archived food items do not appear in new order menu

### Secret Handling Testing
- [ ] Verify no credentials exist in source code
- [ ] Verify no Supabase keys in Flutter client
- [ ] Verify database file does not contain plain-text passwords

---

## TODO
- [ ] Perform security testing during Phase 10
- [ ] Document all findings and resolutions
