# Ubuntu backend preparation — local verification

Date: 2026-10-22 (Asia/Manila). Source: this working tree, including uncommitted changes. No release commit or VM deployment is claimed.

## Executed checks

Command: `backend/.venv/Scripts/python.exe -m pytest backend/tests -q --basetemp=backend/data/test-run-3 --tb=short`

Result: **11 passed, 1 warning in 1.25 seconds**. The warning concerns Starlette's deprecation of its httpx TestClient integration. These are in-process API requests using synthetic credentials and project-local temporary databases, not requests to a deployed VM.

Covered: missing configuration fails closed; health; missing/incorrect authentication; device/Admin permission separation; denied-action audit; idempotent retry; retained revisions and replay resistance for previously seen versions; device namespace separation; extra sensitive fields rejected without echo; invalid batch rollback; oversized body; protected schema; request rate limit; persistence across app recreation; no delete route; bounded pagination.

Command: `C:/src/flutter/bin/cache/dart-sdk/bin/dart.exe C:/src/flutter/bin/cache/flutter_tools.snapshot test test/security/backend_sync_test.dart --no-pub`

Result: **4 tests passed** using SQLite in memory and mocked HTTP. Covered remote HTTPS requirement, successful acknowledgement/checkpoint, changed-sale resync, offline retention/retry, 403 and invalid acknowledgement retention. This does not prove TLS certificate trust or a real-device network round trip.

Initial executions encountered sandbox temporary-directory/thread restrictions and Flutter SDK cache permissions. Backend and Flutter tests completed outside those restrictions after automatic approval. No business database or existing cloud project was used.

## Rubric and limitations

Relevant criteria: R08–R15 and R19. This provides partial evidence for authentication, API permissions, payload minimization, retry behavior and traceability. It does not close the earlier local repository authorization findings or establish an overall rubric score.

Pending: Ubuntu installation; systemd/Caddy validation; firewall and trusted HTTPS from Flutter; real offline/reconnect demonstration; rotation/revocation exercise; server backup/restore; dependency vulnerability audit; Android provisioning; distributed/concurrent deployment tests. Rate limiting is per-process and intended for the supplied single-worker service configuration.

Backend mode is one-way sales synchronization, with no two-way account/menu synchronization or automatic recovery of a terminal. Existing Supabase mode is a separate selectable path and was not security-validated by these tests.

## Static checks

Targeted Dart analysis completed with no errors or warnings and 15 informational lints (existing print/deprecation notices plus two missing-braces notices in the new client). The two new braces notices were corrected and formatted. A second invocation also returned the same informational output for its initial snapshot. No clean post-format analyzer result is claimed. `git diff --check` completed without whitespace errors.
