# Security Remediation Log

## Status Table

| ID | Gap # (from profile §13) | Task | Status (TODO/IN PROGRESS/DONE/BLOCKED/SKIPPED) | Files changed | Test added | Evidence |
|---|---|---|---|---|---|---|
| A1 | Gap 1 | Add `.env` to `.gitignore`, create `.env.example`, `git rm --cached .env` | DONE | `.gitignore`, `.env.example`, `.env` (untracked), `test/security/password_hashing_test.dart` | `test/security/env_gitignore_test.dart` | `docs/security/evidence/test_a1_gitignore.txt` |
| A2 | Gap 15 | Bind FastAPI microservice to `127.0.0.1` instead of `0.0.0.0` in `ai_service/main.py` | DONE | `ai_service/main.py` | `ai_service/tests/test_bind.py` | `docs/security/evidence/test_a2_fastapi_bind.txt` |
| A3 | Gap 14 | Require shared-secret header `X-Service-Key` on `/extract_encoding` and `/check_liveness` | TODO | - | - | - |
| A4 | Gaps 7-9 | Audit logging for login, logout, session expiry, food CRUD, transaction actions, admin user edits | TODO | - | - | - |
| A5 | Gap 2 | Password policy enforcement (min 8 chars, >=1 letter, >=1 number) | TODO | - | - | - |
| A6 | Gap 3 | Force password change on first login for seeded accounts (`must_change_password` migration) | TODO | - | - | - |
| A7 | Gaps 20-21 | Pin `ai_service/requirements.txt` dependencies, generate `flutter pub outdated` & pip audit evidence | TODO | - | - | - |
| B1 | - | Raise PBKDF2 iterations to 600,000 with per-record iteration metadata & re-hash on login | TODO (Needs User Approval) | - | - | - |
| B2 | - | Replace AES-CBC with AES-GCM for face encodings + migration | TODO (Needs User Approval) | - | - | - |
| B3 | Gaps 16, 19 | Rate limiting on Python API & magic-byte validation for image uploads | TODO (Needs User Approval) | - | - | - |
| B4 | Gap 18 | Restrict image download URLs to Supabase storage host; cap/disable redirects | TODO (Needs User Approval) | - | - | - |
| B5 | Gap 12 | SQLCipher database encryption | TODO (Needs User Approval) | - | - | - |

## Task Notes (one short block per completed task)

### Task A1 (Gap 1) — Stop tracking `.env`, add to `.gitignore`, provide `.env.example`
- **What changed**:
  - Added `.env`, `.env.*`, and `!.env.example` to `.gitignore`.
  - Created `.env.example` containing environment variable keys with sanitized placeholder values.
  - Ran `git rm --cached .env` to stop index tracking without deleting the local file.
  - Added test `test/security/env_gitignore_test.dart` asserting `.env` is ignored and `.env.example` exists with valid placeholders and no JWT credentials.
  - Fixed pre-existing typo in `test/security/password_hashing_test.dart` line 51 where the expected hash was a placeholder rather than the RFC 6070 PBKDF2-HMAC-SHA256 vector.
- **Why**: Prevent credentials (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_DEVICE_SECRET`) from being committed in future git commits, while giving new environments a template.
- **Verification**:
  - `flutter test test/security/env_gitignore_test.dart` failed before fix (2/2 failed), passed after fix (2/2 passed). Output saved to `docs/security/evidence/test_a1_gitignore.txt`.
  - `flutter test test/security/` passed 17/17 tests.
- **Before/After**:
  - *Before*: `.env` was tracked by git and previously committed in commit `ae00dea`.
  - *After*: `.env` is untracked in git index and ignored by `.gitignore`. Local `.env` remains intact for local development.

### Task A2 (Gap 15) — Bind FastAPI to localhost only (`127.0.0.1`)
- **What changed**:
  - In `ai_service/main.py` line 70, changed `uvicorn.run(app, host="0.0.0.0", port=5000)` to `uvicorn.run(app, host="127.0.0.1", port=5000)`.
  - Created unit test `ai_service/tests/test_bind.py` using Python `ast` and `unittest` to assert `0.0.0.0` is not bound and `127.0.0.1` is used.
- **Why**: Binding to `0.0.0.0` exposed the face recognition and liveness endpoints to all network interfaces on the local LAN without authentication. Binding to `127.0.0.1` limits access exclusively to local POS terminal callers.
- **Verification**:
  - `py -m unittest discover -s ai_service/tests` failed before fix (`AssertionError: '0.0.0.0' unexpectedly found in ['0.0.0.0']`), passed after fix (`Ran 1 test in 0.001s ... OK`).
  - Verbose output saved to `docs/security/evidence/test_a2_fastapi_bind.txt`.
  - `flutter test test/security/` passed 17/17 tests.
- **Before/After**:
  - *Before*: `ai_service` listened on `0.0.0.0:5000`, accepting connections from external machines on the local network.
  - *After*: `ai_service` listens on `127.0.0.1:5000`, accepting connections solely from localhost.

## Decisions and Discrepancies

- Fixed `test/security/password_hashing_test.dart` test vector discrepancy: the existing test had an incorrect expected base64 string; verified the correct RFC 6070 PBKDF2 output via independent derivation in Python (`XsArkaS1nG9Z3V++TKZJ7OT6hWjNuLo2z0FCbogFUis=`).
- Initialized remediation log based on verified IAS security profile (`docs/security/ias_security_profile.md`).
- Tier B tasks deferred until explicit user go-ahead as each requires data/schema migration or architectural discussion.

## Manual Actions Required From The Student

1. **Rotate Supabase Credentials**: Rotate `SUPABASE_DEVICE_SECRET` and decide on rotation for the `SUPABASE_ANON_KEY` in the Supabase web dashboard, as `.env` was previously committed to git history in commit `ae00dea`.

## Next Steps

1. Start Task A3 (Gap 14): Require shared-secret header `X-Service-Key` on `/extract_encoding` and `/check_liveness` in `ai_service/main.py`.
2. Update `lib/core/services/ai_service_client.dart` to send `X-Service-Key` sourced from env (`flutter_dotenv`).
3. Add `AI_SERVICE_KEY` placeholder to `.env.example` and local `.env`.
4. Add Python and Dart tests verifying 401 when missing/wrong, 200 when valid.
5. Proceed to A4 through A7.

## Session History (one line per session: date, tasks touched)

- 2026-10-15: Initialized profile in `docs/security/ias_security_profile.md` and `SECURITY_REMEDIATION_LOG.md`; completed Tasks A1 (Gap 1) and A2 (Gap 15).
