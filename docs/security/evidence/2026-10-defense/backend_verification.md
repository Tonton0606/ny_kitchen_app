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

## Owner-operated Ubuntu API demonstration — 2026-10-24

Source: owner-supplied screenshots and confirmation in the Codex conversation. These are manual observations, not independently captured VM logs.

- After the Ubuntu VM had a kernel soft-lockup and Windows SSH timed out, the owner rebooted the VM. The VirtualBox console showed `enp0s8` up at `192.168.56.101/24`; `sudo systemctl is-active ny-kitchen-api` returned `active`.
- The owner provisioned a separate `defense-demo` device credential, set `/etc/ny-kitchen/credentials.json` to `root:nykitchen` mode `640`, and restarted the API. No token value was recorded.
- From Windows PowerShell, the owner sent one synthetic sale to `/v1/sales/sync` using the `defense-demo` device token, `curl.exe --ssl-revoke-best-effort`, and `--resolve nykitchen.test:443:192.168.56.101`. The first inline-body attempt returned HTTP 422 `Invalid request`; a retry that sent UTF-8 JSON from a temporary file returned **HTTP 200**, `Via: 1.1 Caddy`, and `{"accepted":1,"new_revisions":1}`.
- This verifies one authenticated synthetic request was accepted through the Windows-to-Caddy-to-API path after the VM reboot. It did not involve the Flutter app, local POS SQLite, or Supabase. It is not an end-to-end sync, offline/reconnect, role-denial, backup/restore, or full recovery acceptance test. No automated tests were run for this manual demonstration.
- The evidence screenshot is `codex-clipboard-f0d9e227-fbe7-479b-80d1-9ece72253561.png` in the owner's conversation, not copied into the repository. It does not expose the token.

Presentation notes: [`DEFENSE_BACKEND_PRESENTATION_NOTES.md`](../../../DEFENSE_BACKEND_PRESENTATION_NOTES.md).
