# Defense presentation notes — Ubuntu sales API

**Evidence date:** 2026-10-24 (Asia/Manila)

**Scope:** Ubuntu backend security demonstration. The direct API check below is not an end-to-end Flutter POS sync.

## Short talk track

“The POS remains offline-first and keeps its working data in SQLite. The Ubuntu service is a separate one-way sales-replication endpoint. Caddy accepts HTTPS from the host-only network and proxies requests to the FastAPI/Uvicorn process bound to loopback inside Ubuntu. A device bearer token is required for sales uploads. The API validates a limited sale payload and stores accepted revisions in its Ubuntu database. I sent one synthetic sale from Windows and received HTTP 200 with one new revision. This verifies the API path; automatic Flutter-to-Ubuntu syncing has not yet been demonstrated.”

## What the live check showed

- Windows PowerShell sent a synthetic `defense-demo` sale to `https://nykitchen.test/v1/sales/sync` over HTTPS. The request resolved `nykitchen.test` to the VM host-only address `192.168.56.101`.
- The response was `HTTP/1.1 200 OK` with `{"accepted":1,"new_revisions":1}` and a `Via: 1.1 Caddy` header.
- This was a direct API request with a device credential. It did not use the Flutter POS, its SQLite database, or Supabase. No real sales or customer records were sent.
- The screenshot supplied by the owner on 2026-10-24 is in the Codex conversation, not stored in this repository. The token was entered through a hidden secure prompt and is not recorded here.

## Architecture to point to

`Windows test client → HTTPS :443 → Caddy on Ubuntu → FastAPI/Uvicorn at 127.0.0.1:8000 → Ubuntu sync database`

The `127.0.0.1` address is internal to the Ubuntu VM. Windows reaches Caddy at `nykitchen.test` over the VirtualBox host-only network; there is no separate Windows localhost server to launch. The systemd service runs the API in the VM.

## Security points to explain

- **Network boundary:** UFW was observed with default-deny incoming and SSH 22/HTTPS 443 allowed only from `192.168.56.0/24` on the host-only interface. This is a lab VM boundary, not proof of Internet-facing production hardening.
- **Transport:** Caddy serves HTTPS using a local CA trusted in the owner's Windows Current User store. This is a local test certificate, not a publicly trusted certificate. Windows needed best-effort handling for the unavailable local-CA revocation check.
- **Authentication:** The upload route requires a device bearer token; the separate admin role is for read-only administration. The token value is secret and must not appear in slides, screenshots, or chat.
- **Payload and storage:** The API enforces a strict sale schema, rejects undeclared fields, and records append-only revisions with an audit outcome. These controls do not make the VM's files tamper-proof against its OS administrator.
- **Service boundary:** Uvicorn is bound to loopback and Caddy is the HTTPS entry point. The API is managed by systemd; do not start a second manual Uvicorn process during the presentation.

## Simple demo sequence

1. Start the **NY Kitchen Ubuntu** VM and keep it running. If useful, show `sudo systemctl is-active caddy ny-kitchen-api`; both should report `active`.
2. Show the Windows PowerShell screenshot with the HTTPS `200 OK` sale response. A health check is also available without a token: `curl.exe --ssl-revoke-best-effort --resolve nykitchen.test:443:192.168.56.101 --max-time 10 -i https://nykitchen.test/health`.
3. Explain that the sale response proves a manually authenticated synthetic request reached the Ubuntu API through Caddy. Do not claim it proves the Flutter client synchronized.

## Limitations to state clearly

- Flutter's `BackendSyncService` has not been demonstrated against this VM; no live Flutter HTTPS trust, sale upload, offline/reconnect, or device/Admin denial check was performed in this session.
- The inspected workspace had `SYNC_BACKEND` unset. Starting the POS without checking its configuration may use its existing Supabase path. Do not launch a full sync against Production for this demo: local/cloud sale statuses still differ, and a first Ubuntu app sync would include historical local sales.
- Supabase and the Ubuntu API are separate synchronization paths. The synthetic API request did not read or write Supabase.
- The VM previously showed a kernel soft-lockup and SSH timed out. After reboot, the owner observed the host-only interface and API active, then the HTTPS sale request succeeded. This is useful recovery evidence, but it is not a backup/restore test.
- The backend test-suite results recorded elsewhere used synthetic credentials/test databases or mocked HTTP. They are not live Flutter-to-VM results.

## Likely questions

**Why does the API use localhost?** Uvicorn listens only on Ubuntu's loopback interface. Caddy accepts the network connection and proxies it internally, so port 8000 does not need to be exposed to Windows.

**Is this publicly accessible?** The demonstrated path uses a VirtualBox host-only address and a local CA. It is a lab deployment, not an Internet-hosted service with a public certificate.

**Does this prove the POS is syncing?** No. It proves one authenticated synthetic request was accepted by the Ubuntu API. Flutter-to-Ubuntu integration remains to be validated.
