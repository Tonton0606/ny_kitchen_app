# Security framework and evidence index

Updated 2026-10-20. Current defense plan: [SECURITY_IMPLEMENTATION_PLAN.md](SECURITY_IMPLEMENTATION_PLAN.md). Session and finding history: [SECURITY_DEFENSE_RECORD.md](../SECURITY_DEFENSE_RECORD.md).

Selected framework families: OWASP MASVS for Android, OWASP ASVS/API guidance for the Python service, and NIST CSF 2.0 for Windows/cloud operations and incident/recovery planning. Use STRIDE to structure threats and ISO/IEC 25010 to connect quality evaluation to measured security outcomes. Exact control/version coverage is to be recorded during implementation.

Observed controls include salted PBKDF2-HMAC-SHA256 passwords, five-attempt account lockout, in-memory sessions with 30-minute inactivity expiration, route guards, parameterized inspected queries, atomic transaction creation and selected audit events.

Open concerns include missing repository authorization, cloud replacement of local records, sensitive unencrypted exports, fixed-IV biometric encryption, raw exception display and incomplete verification of offline startup. Historical DONE entries do not establish current assurance.

The supplied rubric contains 20 criteria totaling 100 points. It does not require a Linux VM, Docker or a web scanner. The implementation plan maps all criteria to evidence and measurable acceptance tests. No score or certification is claimed.
