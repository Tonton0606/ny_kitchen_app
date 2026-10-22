# Authentication — current baseline and planned work

Updated 2026-10-20 from source inspection. Verification is pending.

Local username/password authentication uses SQLite through `UserRepository.login()`. `SecurityUtils` implements PBKDF2-HMAC-SHA256 with 10,000 iterations and a random salt per password. Stored values use `salt:hash`. The policy helper requires eight characters, a letter, and a digit; consistent repository enforcement is pending.

Five failed password checks for an active known account set its status to locked. Successful login resets the counter. Locked/inactive and unknown accounts are rejected early; those early rejection paths need audit coverage. Login success, failed password checks, and lockout have audit calls.

Seed accounts carry a forced-password-change flag. Verify this requirement at every protected operation, including direct repository calls. The current `SessionManager` stores the user in memory and expires after 30 minutes of inactivity. `main.dart` checks periodically. Disabled-account session revocation needs verification.

Planned: versioned KDF parameters and compatible rehash-on-login, repository password policy checks, complete audit coverage, consistent safe errors, and verified first-login restrictions. Do not change iteration counts without migration support.

See [implementation plan](SECURITY_IMPLEMENTATION_PLAN.md), AT01, AT03 and AT04. Face-service code exists; current login integration and deployment are not verified.
