# Session management — observed implementation

Updated 2026-10-20. `lib/core/session/session_manager.dart` uses a singleton and stores the current user map in memory. It is not an AuthProvider implementation.

The inactivity timeout is 30 minutes. Pointer listeners update activity, and `main.dart` checks expiry every minute. Logout clears the current user and requests an audit entry. Login/logout also trigger synchronization calls.

Pending verification: expiry before protected operations, keyboard activity, background/resume behavior, forced password changes, disabled-account revocation, duplicate timers and audit failure handling. A cached in-memory role is not enough to establish that the account remains authorized.

Do not claim a persistent session or automatic revocation on account disable without evidence. See [plan](SECURITY_IMPLEMENTATION_PLAN.md), AT01–AT03 and AT07.
