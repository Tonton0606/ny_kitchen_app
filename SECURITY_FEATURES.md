# N.Y Kitchen security features — inspection baseline

Updated 2026-10-20. See [implementation plan](docs/SECURITY_IMPLEMENTATION_PLAN.md) and [session record](SECURITY_DEFENSE_RECORD.md) for risks, rubric mapping and tests.

Observed in source: local SQLite password authentication; salted PBKDF2-HMAC-SHA256 at 10,000 iterations; five-attempt lockout for active known accounts; forced-change flag/dialog; 30-minute in-memory inactivity expiration; role route guard; selected audit events; parameterized inspected queries; atomic transaction creation; local API service-key checks.

These observations are not fresh test results. Privileged repository checks and ownership restrictions need strengthening and verification. The route guard currently checks after rendering. Failed/unknown/inactive authentication audit coverage needs review.

Optional Supabase push/pull exists in source. Its deployment policies have not been inspected. Replacement/upsert behavior does not establish immutable backups, tamper-proof logs, or instant disaster recovery. Outgoing password hashes are removed, but other fields and incoming role/account data require review.

Biometric encryption currently uses stored-key/stored-IV AES-CBC. Database export writes sensitive table data into unencrypted SQL. Neither feature should be described as fully hardened. Use authenticated encryption, reviewed key recovery, and validated backups as proposed in the plan.

Menu management is in scope; inventory management is excluded. No application changes or security test runs were performed during this documentation update.
