# N.Y Kitchen — mandatory AI handoff and security plan

Last updated: October 22, 2026, Asia/Manila.
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
- The owner said the VM is not yet installed and they will install it later. Do not claim deployment or infer a VM IP, Ubuntu version, hostname mapping, SSH credentials, or TLS trust.
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
| High | Deploy Ubuntu service, validate HTTPS/firewall, device/Admin denial and actual offline/reconnect behavior | Backend deployment guide; AT07/AT09/AT10 coverage |
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

Not yet demonstrated: Ubuntu deployment, trusted HTTPS from Flutter, real-device offline/reconnect round trip, server backup/restore, rotation/revocation on the VM, Android provisioning, comprehensive dependency audit, or a complete rubric pass.

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

Ask the session owner's name, read the required files, and inspect the working tree. If Ubuntu is available, follow the deployment guide and capture real HTTPS/offline-reconnect evidence. If it is not ready, continue authorized local security work, starting with repository authorization and its negative tests. Do not perform a full web conversion or claim that backend preparation completes the rubric.
