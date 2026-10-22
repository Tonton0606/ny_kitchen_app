# Required AI session entry point

These instructions apply throughout this repository, subject to the assistant's higher-priority instructions and the user's current instructions.

## Start every new session here

1. Read `AI_SESSION_HANDOFF.md` completely before planning or editing the project.
2. Ask: **“Who is working in this session: Ralston Villamin, MJ Daz, or Hancr Gonzales?”** Wait for the answer before project changes, tests, installations, or deployment. Reading the entry-point documents to establish context is allowed.
3. If the user already identified themselves in the current conversation, use that answer. Ask again for a new chat or an explicit operator change. Do not ask again merely because context was compacted when the current answer is preserved.
4. Record the name as **self-reported session owner**. A typed name does not authenticate identity or grant application, server, or deployment privileges. Never infer identity from the Windows username, Git author, filenames, or a previous chat.
5. Follow the handoff's reading order, approved scope, evidence rules, and session-record procedure.

The team members above are project collaborators, not additional POS roles. POS roles remain Administrator and Cashier. Team job responsibilities have not been assigned; do not invent them.

If a different collaborator identifies themselves, record their supplied name and clarify their requested task; do not impersonate or silently assign one of the listed names.

Before modifying files, inspect current Git changes and applicable nested `AGENTS.md` files. Preserve other collaborators' work. No automatic reset, cleanup, commit, push, or deployment.

Current approved direction: retain Flutter and offline SQLite; add the Ubuntu API backend. Do not convert the interface to web without an explicit new user instruction. Consult the handoff for the distinction between Ubuntu sales replication and existing Supabase synchronization.
