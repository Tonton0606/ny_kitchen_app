# Security verification plan

Updated 2026-10-20. The authoritative current test procedures and measurable outcomes are AT01–AT10 in [SECURITY_IMPLEMENTATION_PLAN.md](SECURITY_IMPLEMENTATION_PLAN.md). All are planned; this documentation session did not execute security tests.

Test on disposable fixtures and the platforms actually claimed: Windows first, then Android if demonstrated. Use direct repository integration tests for authorization and database integrity, UI/device tests for sessions and offline behavior, Python API tests for the face service, and isolated cloud policy tests if cloud is included.

The app uses native Flutter navigation, so URL manipulation is not the primary route-guard test. Instantiate guarded screens and directly exercise protected operations as unauthorized callers. Verify own-record restrictions and zero prohibited mutations.

ZAP is optional for the HTTP API. Record authenticated endpoint coverage, include valid multipart requests, triage findings, and retain limitations. A scan of only rejected requests does not verify internal API behavior. Flutter/local SQLite controls need separate tests.

For each result record rubric/risk/test IDs, selected framework version/control, build revision and local changes, platform, prerequisites, expected and actual result, date, reviewer and sanitized evidence path. New evidence belongs under `docs/security/evidence/2026-10-defense/` when generated. Do not treat earlier saved results as current passes.

Secret review must distinguish a public client identifier from privileged service/device secrets. Never place a service-role key in Flutter. Inspect history and rotate exposed secrets rather than relying only on ignore rules.
