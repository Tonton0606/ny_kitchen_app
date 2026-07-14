# ai/LOCKS.md
# N.Y Kitchen — File Ownership and Conflict Prevention

---

## Purpose
Prevent multiple agents from simultaneously modifying the same files and causing conflicts.

---

## Lock Protocol

Before modifying a file, an agent should:
1. Check if the file is listed as currently locked below.
2. If locked, wait for the lock to be released before modifying.
3. If unlocked, record the lock before starting work.
4. Release the lock immediately after completing and verifying work.

---

## Currently Locked Files

| File | Locked By | Reason | Date |
|---|---|---|---|
| (none) | — | — | — |

---

## Protected Files (Never Modify Without Blueprint Approval)

| File | Protection Reason |
|---|---|
| PROJECT_BLUEPRINT.md | Single source of truth — never overwrite |
| RULES.md | Immutable rules — requires explicit approval to change |
| AI_DEVELOPMENT_RULES.md | AI governance — requires explicit approval to change |

---

## Conflict Resolution
- If two agents have modified the same file, review both versions and keep the one consistent with PROJECT_BLUEPRINT.md.
- Record the conflict in ai/DECISIONS.md and escalate to the project owner.
- Never silently discard changes without review.
