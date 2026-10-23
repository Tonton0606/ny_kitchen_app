# N.Y Kitchen — mandatory AI handoff and security plan

Last updated: October 24, 2026, Asia/Manila.
Record owner for this handoff creation: **Ralston Villamin (self-reported in this conversation)**.

This file is the starting guide for any AI continuing the project. Read it completely. It summarizes approved decisions and points to detailed evidence. It is not proof that security requirements have passed. Current user instructions and inspected source take precedence over stale historical summaries; record discrepancies instead of silently inventing resolutions.

## 1. Identify the current session owner

At the beginning of every new chat/session, ask:

> Who is working in this session: Ralston Villamin, MJ Daz, or Hancr Gonzales?

Wait for the reply before changing project files, running tests, installing tools, or deploying. Reading this guide and the entry instructions is allowed. If identification is already explicit in the current conversation, do not repeat the question. On context compaction, carry forward the existing answer. On an explicit handover to another person, ask again.

| Collaborator | Recorded role |
|---|---|
| Ralston Villamin | Project collaborator; current session owner for this handoff creation |
| MJ Daz | Project collaborator; specific responsibilities not yet supplied |
| Hancr Gonzales | Project collaborator; specific responsibilities not yet supplied |

Names are for attributing work. This is **self-identification**, not authentication. Do not ask for passwords or identity documents. Do not assign unequal permissions or technical responsibilities based on these names. Do not add these names as application roles or seed accounts.

## 2. Required reading order

After this guide and session identification:

1. `PROJECT_BLUEPRINT.md` — approved business scope, including dated amendments.
2. `RULES.md` and `AI_DEVELOPMENT_RULES.md` — project constraints; distinguish historical proposals from current decisions.
3. `PROJECT_STATE.md` — read the newest dated updates, not just old completion percentages.
4. `docs/SECURITY_IMPLEMENTATION_PLAN.md` — all 20 rubric criteria, risks and AT01–AT10 procedures.
5. `SECURITY_DEFENSE_RECORD.md` — initial SEC findings and chronological work history.
6. `DECISIONS.md` — especially accepted ADR-002 and ADR-018; identify unresolved decisions.
7. `backend/README.md` and `docs/security/evidence/2026-10-defense/backend_verification.md` — actual backend capabilities, limits and recorded test evidence.
8. Relevant feature documentation and source, existing tests, `TODO.md`, and applicable nested agent instructions.

Then inspect `git status --short` and relevant diffs. Read the actual implementation before changing it. Existing modified files belong to the team; preserve them. Historical notes are not authority to undo newer work.

## 3. Approved system and decisions

**N.Y Kitchen Secure Order and Sales Management System** is a Flutter/Dart POS for a small food stall, with local SQLite and online synchronization. It is a hybrid system: core local operations must remain available offline.

- Keep the existing Flutter interface. No full web conversion is approved.
- Keep SQLite for local login and core sales operations.
- Only two human POS roles: Administrator and Cashier.
- Menu management is included; inventory management is excluded.
- Online synchronization is approved scope. Earlier documents excluding cloud sync have been superseded by the owner's October 20 confirmation.
- On October 22, the owner explicitly selected **“Keep Flutter POS and add a secured backend on an Ubuntu VM.”** Earlier advice that a VM was unnecessary does not cancel this later choice.
- Owner-supplied terminal screenshots from October 23–24 show the Ubuntu VirtualBox VM deployed and the API/Caddy service responding over the private host-only network. Observed details and limits are recorded below; this evidence does not establish Flutter-client synchronization, a production rollout, or Internet exposure.
- Docker is not a requirement. ZAP can support API assessment; it does not verify Flutter/local SQLite business controls.
- The defense was stated to be Thursday, October 22, 2026. For later sessions verify whether the defense schedule has changed; do not keep calling that date “tomorrow.”

## 4. Exact current backend scope

The newly added backend is **one-way sales replication**, not complete bidirectional synchronization of the POS database.

```text
Flutter POS → local SQLite (offline sales)
                  ↓ selected Ubuntu sync mode / HTTPS
Ubuntu Caddy → loopback FastAPI → server SQLite sales revision history
```

- `backend/app.py`: sales ingest, separate Admin reads, protected schema, audit records, payload/body/rate limits.
- `backend/provision.py`: operator provisioning and rotation; random device/Admin tokens, server stores token digests.
- `backend/deploy/`: systemd service, Caddy HTTPS template and environment template.
- `lib/core/services/backend_sync_service.dart`: allowlisted sales fields, integer money, HTTPS checks, acknowledgement checkpoints and retries.
- `lib/core/services/sync_service.dart` and `lib/main.dart`: explicit backend mode selection and sync status footer.
- `SYNC_BACKEND=ubuntu` selects the Ubuntu path and prevents the existing direct Supabase push/pull and image-upload path from running for that app run.
- Existing Supabase code remains the legacy/default mode. Do not activate both synchronization paths together or silently fall back between them.
- Device credentials are installation identities, not new human POS roles. The backend Admin token must not be stored in the Flutter app.
- The new path does not upload users, password hashes, face templates, images or local audit descriptions. It does not download menus/accounts, authorize each offline Cashier remotely, or restore a terminal.
- Server revisions are append-only through the API; an OS administrator can still modify server files. A compromised device token can submit false data within its namespace. Do not claim tamper-proof storage or full end-to-end assurance.

Read `backend/README.md` before configuring or demonstrating this service. Preserve local sales and existing cloud data.

## 5. Rubric source and interpretation

Source workbook: `C:/Users/tonton/Downloads/BSIT_Information_Assurance_Security_Framework_Rubric.xlsx`, sheet `Security Rubric`. On another computer request the supplied rubric if it cannot be located. Do not substitute an unrelated rubric.

The worksheet has **20 criteria worth 5 points each**, total **100**:

| Section | Points | Tracking IDs |
|---|---:|---|
| Security context and assets | 15 | R01–R03 |
| Risk, threat and vulnerability analysis | 20 | R04–R07 |
| Security design and controls | 25 | R08–R12 |
| Assurance, testing and acceptance | 20 | R13–R16 |
| Privacy, governance and resilience | 10 | R17–R18 |
| Security readiness and communication | 10 | R19–R20 |

Ratings are 5 / 4 / 3 / 1 as specified in the workbook. Readiness bands: 85–100 ready, 75–84 subject to revision, below 75 not yet ready. The workbook also lists critical requirements. No earned score has been assigned in this work. Empty score cells and cached summary zeroes are not an evaluated project score.

All exact criterion names and the evidence mapping are in `docs/SECURITY_IMPLEMENTATION_PLAN.md`. Use applicable MASVS controls for Android, ASVS/API guidance for the API, NIST/CIS guidance for infrastructure where relevant, STRIDE for threat scenarios, and ISO/IEC 25010 for measured quality evaluation. Do not claim certification or complete framework compliance from a subset of tests.

## 6. Security work still required

| Priority | Work | Existing tracking |
|---|---|---|
| High | Enforce acting-session permissions in repositories; reject forged role/actor fields; own-record restrictions and denial logs | SEC-01, K01, AT02/AT05 |
| High | Verify lockout, forced password changes, inactivity, disabled-account revocation and audit coverage | SEC-09/11, AT01/AT03 |
| High | Validate existing Supabase conflict/RLS behavior if that mode is demonstrated; preserve protected records | SEC-02, K02, AT10 |
| High | Implement and demonstrate protected backup plus actual successful restore and corruption rejection | SEC-03, K03, AT08 |
| High | Finish Flutter-to-Ubuntu trust/sync validation, device/Admin denial, and actual offline/reconnect behavior; preserve server recovery evidence | Backend deployment guide; AT07/AT09/AT10 coverage |
| Further hardening | Password KDF migration, authenticated biometric encryption if used, safe errors, API/input limits, secrets and dependency review | SEC-04–SEC-10; AT04/AT06/AT09/AT10 |
| Defense | Privacy/retention/incident procedures, risk treatment, evidence traceability, scored review and rehearsal | R17–R20 |

The new backend does **not** fix missing authorization in local repositories. Do not close unrelated findings because its API tests pass. Resolve the highest-risk remaining issue within the current requested scope; avoid a broad cosmetic refactor before the defense.

## 7. Verified results and evidence limits

Recorded October 22:

- 11 Python backend tests passed on synthetic credentials and isolated test databases.
- 4 Flutter backend sync tests passed using an in-memory database and mocked HTTP.
- Targeted Dart analysis returned informational notices, including existing logging/deprecation items. Two new braces notices were corrected. No completely clean post-format analyzer result was claimed.
- `git diff --check` completed without whitespace errors.

See `docs/security/evidence/2026-10-defense/backend_verification.md` for commands and limitations. These results are historical once code changes; rerun relevant checks for affected code. Do not report them as tests executed in a new session.

On 2026-10-22, the manual/automatic cloud sync paths were updated to report table failures, avoid an unnecessary Supabase SELECT response after upsert, serialize overlapping sync work, and expose automatic-mode status. No tests, app launch, or live cloud request was run for this repair. The current code is **Implemented—not verified**; see the latest entry in `SECURITY_DEFENSE_RECORD.md`.

Follow-up: the owner privately changed a local device-secret mismatch, but still sees a Sync error. The latest Windows log shows Supabase initialization and repeated `RadioListTile` Material assertions, but no fresh sync failure code/table. The settings warning was addressed, and the top-bar manual action now shows the sanitized sync status. Live sync remains **unverified**; test only with synthetic data in a development project.

On 2026-10-23, the owner supplied a `users (23502)` upload error and read-only schema output showing `password_hash` required. A later owner-supplied SQL Editor screenshot from the `main` / `PRODUCTION` project on 2026-10-24 shows `public.users.password_hash` exists and is nullable (`YES`). This supersedes the earlier schema observation; the cause/provenance of the change is unknown, and no migration application by this assistant is claimed. The Flutter pull path requests profile columns only, preserves existing device-local auth state, and generates a local-only password hash for imported profiles. No successful sync or database write is verified. Do not apply the prepared migration to Production based solely on the older observation; first inspect the current schema in the intended environment and validate the workflow with synthetic data in development.

On 2026-10-23, two device screenshots showed distinct sales sharing local transaction/order ID `#1` with different receipts and amounts. SQLite auto-increment IDs are per installation, while Supabase upserts on `id`; this can overwrite one device's sale and explains the differing dashboard totals. New sales and line items now use a local-only installation namespace plus monotonic counter, receipts include the generated ID suffix, and sync rekeys a legacy local sale and its items when the same cloud ID represents a different sale. Before deploying, use `docs/security/supabase_transaction_id_diagnostic.sql` in development to confirm the cloud ID columns are `bigint`. This code has not been runtime-verified. Re-test with both devices and synthetic sales; only data still present on a device can be recovered.

### Owner-supplied infrastructure and Supabase evidence — 2026-10-24

The following are observations from screenshots supplied by the owner in this conversation. They are not independently captured machine logs, and no production write or synchronization was performed by this assistant.

**Supabase `main` / `PRODUCTION`, read-only SQL Editor results:**

- `transactions`: 51 rows, minimum `id` 1. A later read-only REST query confirmed maximum `id` 6509220481919352873; the earlier screenshot transcription was missing the final digit.
- `transaction_items`: 64 rows, minimum `id` 1. A later read-only REST query confirmed maximum `id` 6509220481919352874; the earlier screenshot transcription was missing the final digit.
- `public.users.password_hash` exists and `is_nullable = YES`. The separate required-column query showed `id bigint`, `full_name text`, `username text`, `role text`, `status text`, and `created_at timestamp with time zone` as non-nullable.
- The policy diagnostic showed RLS enabled and not forced on each of seven sync tables, one permissive `ALL` policy per table named `Enforce device secret on <table>` for role `public`. The displayed condition metadata showed a `check_device_secret` call in `USING`, no explicit `WITH CHECK` expression, and `references_request_headers = false`. The query also showed anon/authenticated SELECT, INSERT, and UPDATE table privileges. Because PostgreSQL may use the `USING` expression as the default check when `WITH CHECK` is omitted, inspect the policy definition/function and effective INSERT/UPDATE behavior before judging whether writes are safely authorized.
- Read-only reconciliation on 2026-10-24 compared local SQLite with Supabase Production via GET only. Local had 41 transactions and 53 items; Production had 51 and 64. All 41 local transaction IDs and all 53 local item IDs exist in Production; there are no local-only IDs, plus 10 cloud-only transactions and 11 cloud-only items. All compared item fields match. Transaction receipt, timestamp, amounts, payment method, reasons, order number and user ID match for all shared IDs; only `status` differs on 14 transactions. For IDs `1`, `3`–`8`, `20`–`23`, `26`, and `2216799791961079831`, Production says `Served` while local says `Ready`, `Taken`, or `Preparing`. For `2216799791961079835`, Production says `Voided` and local says `Preparing`. No rows were written or synced. Preserve the cloud state before any Supabase upsert; the current Supabase uploader upserts every local transaction row.
- Earlier direct REST attempts failed to obtain metadata (one schema request returned HTTP 401; count requests returned HTTP 406 or timed out). They were inconclusive and did not establish invalid credentials. The later read-only GET returned row data successfully; its results are recorded above. Do not repeat a sync/write probe against Production.

**Ubuntu VirtualBox backend and Windows HTTPS check, observed October 23–24:**

- VM hostname shown as `ny-kitchen-ubuntu`; host-only IP `192.168.56.101`; hostname `nykitchen.test`; host-only subnet `192.168.56.0/24`.
- `/opt/ny-kitchen/backend` was populated with the approved backend files. A Python 3.12 virtual environment was created and production requirements installed; the separate `pip-audit --path .../site-packages` command reported “No known vulnerabilities found” for that resolved environment at that time.
- Caddy 2.11.7 and `ny-kitchen-api.service` were shown active. The API's initial immediate health probe raced service startup and failed; a subsequent local probe returned HTTP 200 with `{"status":"ok","service":"ny-kitchen-sync"}`.
- UFW was active with default-deny incoming; SSH 22/tcp and HTTPS 443/tcp were allowed on `enp0s8` only from `192.168.56.0/24`. Caddy's local root certificate was copied to Windows and its SHA-256 matched the Ubuntu-exported DER hash. The owner approved and installed that root CA into the Windows CurrentUser Root store. Windows `curl.exe --ssl-revoke-best-effort --resolve ... https://nykitchen.test/health` returned HTTP 200 and the expected JSON. Schannel's default attempt failed because revocation status could not be checked for this local CA; the best-effort retry tolerated that revocation-check limitation while still succeeding on the certificate connection.
- The Windows trust is scoped to that user profile and local test authority. Do not treat this as public CA trust, Internet exposure, or Flutter/Dart/Android trust validation. No Flutter app connection, device-authenticated sale upload, offline/reconnect cycle, server restore, or end-to-end device/Admin denial test is evidenced.
- Tokens appeared in setup screenshots and were rotated during setup; their values are intentionally omitted. Do not reuse or copy any screenshot token. Confirm current server/client credentials privately before use.

Supabase and Ubuntu are separate sync paths. Supabase is still the existing legacy/default path; `SYNC_BACKEND=ubuntu` selects the on-prem one-way sales API and disables Supabase sync for that app run. Do not enable both paths together. No evidence here establishes a successful Supabase sync or that the Flutter POS has been configured to use the Ubuntu API. The first Ubuntu sync sends historical local sales as well as later changes (up to 40 requests per cycle); it does not import the 10 cloud-only transactions or reconcile statuses from Supabase.

At this session's workspace inspection, `SYNC_BACKEND` was unset and the saved local app sync mode was `automatic`; with the current default, starting that POS can launch a Supabase full sync immediately and then repeat every 15 seconds. No POS process was running in this workspace when checked. This describes only the inspected local configuration, not every terminal. Check and reconcile the target terminal's mode/data before launching it against Production.

Remaining: resolve the 14 differing Production/local transaction statuses before any sync that could overwrite Production; review the Production RLS policy's write semantics; validate Supabase schema/auth in development; configure Flutter for Ubuntu and validate its HTTPS/device sync (the initial Ubuntu upload includes the 41 historical local sales); exercise offline/reconnect, denial, credential rotation/revocation and server recovery; complete the rubric review.

## 8. Evidence and safety rules

For each security claim record:

`rubric R-ID → risk/finding ID → implemented control → test AT-ID → actual result → evidence path → remaining limitations`.

Use statuses **Planned**, **Implemented—not verified**, **Pass**, **Fail**, **Blocked**, or **Not applicable with reason**. Keep rubric scores separate from test statuses. Never mark all AT01–AT10 passed because a small targeted suite passed.

Use disposable fixtures and synthetic identities for tests and demonstrations. Do not scan unrelated networks, run active tests on production cloud data, disclose secrets, or upload biometric data. Do not put tokens in URLs/screenshots. Preserve test output and label recorded demonstrations accurately.

Never reset the working tree, remove other collaborators' edits, delete business records, change live credentials, or deploy merely because this handoff exists. Follow the current user's authorized task. Do not claim a tool was installed, a command executed or a control verified without evidence.

## 9. Required session record

Append a session entry to `SECURITY_DEFENSE_RECORD.md` after completed work. Update `PROJECT_STATE.md`, `TODO.md`, and `CHANGELOG.md` as applicable. Update `DECISIONS.md` when an architecture decision changes. Keep this handoff current when the approved direction or important verification status changes.

Use this format:

```text
Date/time and timezone:
Session owner (self-reported):
Requested task and scope:
Rubric / risk / acceptance-test IDs:
Files changed:
Checks actually run and actual results:
Evidence paths:
Unverified items / remaining risks:
Next concrete step:
```

No need to invent the AI model name, team job titles, identity validation, or a score. If the current owner is unknown, ask instead of attributing work to the last recorded person.

## 10. Immediate continuation
 
Ask the session owner's name, read the required files, inspect the working tree, and immediately run `git fetch origin main` to check for remote commits. If incoming commits exist, pull and merge them, resolve any conflicts (preserving both collaborators' defense records chronologically), run verification tests, commit the merge, and push. Then proceed with the authorized task, committing and pushing upon completion. The Ubuntu VM deployment and Windows-side local HTTPS health check have now been observed. Before any sync, preserve/resolve the 14 cloud/local status differences. Ubuntu mode is available after configuring the local `.env` with the Ubuntu URL and a current device token; its first sync uploads the local database's historical sales. Then validate Flutter trust, device upload and offline/reconnect behavior. Do not perform a full web conversion or claim that backend deployment completes the rubric.
