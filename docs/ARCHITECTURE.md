# System architecture — observed implementation

Updated 2026-10-20. This describes source, not a verified deployment.

Flutter/Dart and Material 3 provide the UI. `lib/main.dart` creates `MaterialApp`; navigation uses Flutter `Navigator` and `MaterialPageRoute`. Stateful widgets and singleton services manage state. Provider and go_router are older proposals, not current dependencies.

Admin, Cashier and authentication presentation code lives under `lib/features/`. Shared widgets live under `lib/features/shared/`. SQLite creation/migrations and concrete repositories live under `lib/core/database/`. Session, security helpers, sync and exports are under `lib/core/`.

Pages call repositories; the sync service also accesses SQLite directly. There is no universal service authorization layer established by this inspection. UI route guards exist, but repository enforcement must be strengthened.

SQLite is the local source for core operations. Optional configured Supabase code pushes and pulls records and transfers images. The Python FastAPI service is a separate local face-processing component. Its integration into the current login flow remains unverified.

See [security implementation plan](SECURITY_IMPLEMENTATION_PLAN.md) for boundaries, assets, deployment decisions and verification. The owner confirmed online synchronization as part of the hybrid system on 2026-10-20. SQLite remains the local operational store; this does not establish verified cloud security.

## Ubuntu backend mode — 2026-10-22

Owner-approved addition: Flutter + local SQLite → HTTPS → Caddy on Ubuntu → loopback FastAPI → server SQLite sales revisions. Device credential can upload only to its own server-assigned namespace; separate Admin credential reads sales/audit. No POS passwords or face data leave the device through this path.

`SYNC_BACKEND=ubuntu` selects this one-way sales mode and prevents direct Supabase push/pull/image upload. Unset/default mode preserves the prior Supabase path. Neither mode is silently used as a fallback for the other. See `../backend/README.md` for capabilities, deployment and remaining limits.
