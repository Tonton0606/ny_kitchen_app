# Threat model and risk assessment

Updated 2026-10-20. Current boundaries, prioritized assets, STRIDE scenarios and scored treatment register K01–K08 are in [SECURITY_IMPLEMENTATION_PLAN.md](SECURITY_IMPLEMENTATION_PLAN.md). Source findings SEC-01–SEC-11 are in [the session record](../SECURITY_DEFENSE_RECORD.md).

Actors include a malicious or careless Cashier, an unauthorized local user, a compromised OS account, a compromised cloud/device credential holder, and an administrator misusing legitimate access. Boundaries include UI-to-repository, local file storage, local HTTP service, cloud synchronization and backup restore.

Prioritize unauthorized privileged actions, cloud overwrites, backup disclosure/recovery failure and offline startup failure. Treat source findings as observed weaknesses; demonstrate reachability before asserting exploitation. Record each significant risk's preventive, detective and corrective controls, test evidence and residual risk.

Application-only audit restrictions do not prevent a device administrator from editing SQLite. Device encryption, OS access restrictions, protected independent evidence and tested recovery are compensating controls to assess. Do not call local logs tamper-proof or infer full non-repudiation.
