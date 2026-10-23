# Ubuntu backend for the existing Flutter POS

This version adds **one-way, authenticated sales synchronization** from local SQLite to a server-side SQLite revision store. Flutter remains the interface. The VM exposes HTTPS API URLs, not a browser POS. Two-way menu/account sync, remote refunds, a web dashboard, and complete database recovery are not implemented by this backend.

## What is enforced

- Unique provisioned device token authenticates an installation; server assigns its namespace.
- A separate operator/Admin token can read sales and security events. Never put that token in Flutter.
- Tokens are random 256-bit values; only SHA-256 digests are stored on the server. They are not human passwords. Rotation requires backend restart; there is no automatic token expiration in this version.
- Device credentials cannot read Admin endpoints. Admin credentials cannot ingest sales.
- Explicit payload fields, bounded counts/body size, integer money, timestamp checks, and arithmetic checks.
- Duplicate retries add no revision; changed records append a revision. Replaying an earlier identical version cannot revert the latest version. No API updates/deletes stored revisions.
- No users, password hashes, encryption keys, face templates, images or local audit descriptions are uploaded.
- Security events record successful uploads/reads and authentication/permission denials. Invalid payloads and rate limits use sanitized server logs.
- HTTPS for remote Flutter connections; redirects disabled; HTTP allowed only on localhost for development.
- Local SQLite is the retry source. A checksum is checkpointed in app_settings only after server acknowledgement. Subsequent cycles skip unchanged records.
- Sync runs in background with an eight-second HTTP timeout. A visible footer reports the current sync status.

## Important boundaries

This authenticates a **device**, not each offline Cashier. A compromised device/key can submit false but structurally valid sales in its own namespace. Repository authorization and sale correctness remain separate open findings. Server records are append-only through this API, not tamper-proof against the Ubuntu administrator. Arithmetic checks do not validate against an authoritative server price catalog.

The service does not overwrite local SQLite records. It does not restore a failed terminal, synchronize users/menus across terminals, or forward data to Supabase. `SYNC_BACKEND=ubuntu` disables the existing direct Supabase push/pull and image-upload path for that run. Without that setting, existing behavior remains. Switching destinations is explicit; it is not an automatic fallback.

Only provision one device ID per installation/database identity. After a database reset or cloning, provision a new device ID to avoid confusing reused local transaction IDs with the original installation. Changed records are revisions, not additional sales; reports must select the latest revision per device/local ID.

## Local verification

From the repository root, using a normal Python 3.12 environment:

```text
python -m venv backend/.venv
backend/.venv/Scripts/python -m pip install -r backend/requirements-test.txt
backend/.venv/Scripts/python -m pytest backend/tests -q
flutter test test/security/backend_sync_test.dart --no-pub
```

Production direct dependencies are pinned in requirements.txt. requirements-test.txt adds test dependencies. Review resolved transitive dependencies and run a vulnerability audit before deployment; passing behavior tests does not substitute for that audit.

## Ubuntu VM deployment

Deployment has been observed on the owner's Ubuntu VirtualBox VM (`ny-kitchen-ubuntu`) using Python 3.12+, systemd and Caddy. Owner-supplied screenshots from October 23–24, 2026 show the service and Caddy active, UFW restricted to the host-only subnet, and a successful Windows HTTPS health request. The exact observed setup and limits are recorded in `AI_SESSION_HANDOFF.md` and `SECURITY_DEFENSE_RECORD.md`. The steps below describe setup for a new VM. Treat the observed VM as an existing deployment: inspect its current configuration before repeating provisioning commands, and preserve its data and credentials. The VM is separate from the Windows host and is not a public Internet service.

1. Install Python venv support and Caddy using the official Ubuntu/Caddy instructions. Copy the repository's `backend/` directory to `/opt/ny-kitchen/backend/`. Exclude `.venv`, `data`, credentials, caches and test artifacts. Do not copy a Windows virtual environment to Linux.
2. On Ubuntu create the service identity and directories:

```bash
sudo useradd --system --home /var/lib/ny-kitchen --shell /usr/sbin/nologin nykitchen
sudo install -d -o nykitchen -g nykitchen -m 700 /var/lib/ny-kitchen
sudo install -d -o root -g nykitchen -m 750 /etc/ny-kitchen
cd /opt/ny-kitchen
sudo python3 -m venv backend/.venv
sudo backend/.venv/bin/python -m pip install -r backend/requirements.txt
sudo install -o root -g nykitchen -m 640 backend/deploy/backend.env.example /etc/ny-kitchen/backend.env
```

3. Provision distinct credentials from the VM console. Save each generated token privately; do not record this step in the defense video:

```bash
sudo backend/.venv/bin/python -m backend.provision /etc/ny-kitchen/credentials.json terminal-01 device
sudo backend/.venv/bin/python -m backend.provision /etc/ny-kitchen/credentials.json defense-admin admin
sudo chown root:nykitchen /etc/ny-kitchen/credentials.json
sudo chmod 640 /etc/ny-kitchen/credentials.json
sudo install -m 644 backend/deploy/ny-kitchen-api.service /etc/systemd/system/ny-kitchen-api.service
sudo systemctl daemon-reload
sudo systemctl enable --now ny-kitchen-api
curl http://127.0.0.1:8000/health
```

For rotation repeat provision with the same ID/role and `--rotate`, restore file group/mode, then restart the service. Distribute the new device token to that installation. To revoke a device remove its entry as an operator and restart. Protect and back up the server database/credentials separately. There is no HTTP provisioning endpoint.

4. Review `backend/deploy/Caddyfile` before installing it as `/etc/caddy/Caddyfile` (preserve an existing Caddy configuration). Validate with `sudo caddy validate --config /etc/caddy/Caddyfile`, then reload Caddy. API port 8000 stays on VM loopback. Permit HTTPS port 443 only from the demo host/subnet; restrict SSH similarly if used. Do not enable a firewall over SSH before allowing your current management connection.
5. Map `nykitchen.test` to the actual VM host-only IP on Windows. Export **only Caddy's public root CA certificate**, verify its fingerprint from the VM console, and trust it on the demo client. Never export its private CA key. Test `https://nykitchen.test/health` without certificate-bypass flags. Browser trust alone does not prove Dart trust: test Flutter on the actual device. For Android, use a supported trusted certificate or a reviewed test trust configuration; do not disable certificate validation.

## Connect Flutter

In the ignored local `.env`, set:

```dotenv
SYNC_BACKEND=ubuntu
BACKEND_URL=https://nykitchen.test
BACKEND_DEVICE_TOKEN=<the generated terminal-01 device token>
```

The desktop loader reads `.env` from its working directory. Start the app from the project root for the initial demo. The token is copied into Flutter secure storage for that URL. After the first successful setup remove its plaintext line from `.env`; subsequent starts retrieve it from secure storage. The operator/Admin token stays outside the POS. Android environment provisioning and secure-storage/certificate behavior require separate validation; do not bundle production tokens into application assets.

If configuration is invalid, Ubuntu mode remains selected but no cloud fallback is attempted, and the footer reports that sync is not configured. Local checkout continues. Server rejection keeps sales pending; correct the data/configuration and allow retry. A malformed legacy sale currently stops that cycle at the rejected record, so review pending failures before presenting. No deletion/reset of sales is required to configure this service.

The first cycle uploads historical sales in batches of up to 40 requests per cycle. The 30-second timer retries remaining or changed records; the server limits 120 requests/minute per observed client IP for this single-worker lab deployment. Repeated manual triggers may hit 429; data remains local. For larger deployments use durable queuing and distributed rate limiting.

## Defense endpoints and checks

| URL | Permission | Expected result |
|---|---|---|
| GET /health | Public | Minimal service status |
| POST /v1/sales/sync | Provisioned device | Validate/store sale revisions |
| GET /v1/admin/sales | Separate Admin credential | Latest received revision per device/local sale; after/limit pagination |
| GET /v1/admin/audit | Admin | Authentication, permission and access evidence |
| GET /openapi.json | Admin | API schema for review/ZAP import |

Use a REST client with an unsaved/secret `Authorization: Bearer ...` header. Missing/incorrect token must produce 401. A device token on `/v1/admin/sales` must produce 403; the Admin token must succeed. Demonstrate offline sale, server reconnection, duplicate-safe retry, and the Admin audit entry. Do not put credentials into the URL or screenshots. ZAP testing is limited to your isolated API and still requires triage and authenticated request coverage.

Observed from owner-supplied screenshots: systemd reports the API service active; its process command binds Uvicorn to `127.0.0.1:8000`; Caddy is active; UFW allows SSH/HTTPS only from `192.168.56.0/24` on `enp0s8`; Windows accepted the local Caddy CA after the owner confirmed the matching fingerprint and approved installation, and `curl.exe --ssl-revoke-best-effort --resolve nykitchen.test:443:192.168.56.101 https://nykitchen.test/health` returned HTTP 200 with the health JSON. The default Windows Schannel request could not check revocation for the local certificate; the successful test used best-effort revocation handling. These screenshots do not prove Flutter/Dart/Android certificate trust or successful sale synchronization.

Still to verify: inspect the running process/user and firewall directly; test HTTPS from the actual Flutter desktop and Android clients without bypassing trust; demonstrate offline/reconnect sales and device/Admin denial; confirm credentials, rotation/revocation and service restart behavior; back up and restore the server data; verify reboot persistence. The deployment is operational for a local health check, but acceptance testing is incomplete.

References: [FastAPI HTTPS deployment](https://fastapi.tiangolo.com/deployment/https/), [Caddy automatic HTTPS](https://caddyserver.com/docs/automatic-https), [Caddy installation](https://caddyserver.com/docs/install), [FastAPI testing](https://fastapi.tiangolo.com/tutorial/testing/).
