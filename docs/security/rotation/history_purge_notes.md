# Git History Purge & Credential Invalidation Strategy

> **Status:** Reference & Documentation Only — **Do NOT execute during development without team coordination.**

---

## 1. Context: Why Credentials Remain in History
In git commit `ae00dea` (*feat: Implement Phase 5 cloud synchronization & security hardening*), the `.env` file containing initial Supabase project credentials was committed to repository history. Even though `.env` was subsequent untracked and added to `.gitignore` (in commit `c6d61ad`), git preserves the historical snapshot in that specific commit object.

---

## 2. Invalidation vs. Purging: Why Rotation Matters More

In Information Assurance and Security (IAS), **cryptographic rotation is fundamentally more critical than git history scrubbing**:

1. **Exposure is Irreversible Once Pushed:** If a commit containing secrets was ever pushed to an external remote repository (e.g., GitHub, GitLab, or shared developer machine), the secret must be presumed compromised by search indexers, automated scrapers, or local caches.
2. **Purging Git History Does Not Revoke Active Credentials:** Even if every trace of `.env` is scrubbed from the git tree, an active key remains valid on the cloud server until explicitly revoked/rotated in the Supabase control plane.
3. **Primary Defense is Revocation:** Once `SUPABASE_DEVICE_SECRET` and `SUPABASE_ANON_KEY` are rotated in the cloud console, the historical secrets become inert strings that grant zero access.

---

## 3. History Scrubbing Tool Options

If the development team decides to clean the commit history for academic portfolio or open-source release, two primary tools are available:

### Option A: `git-filter-repo` (Recommended Modern Tool)
Official Git-recommended tool written in Python. Fast, reliable, and handles references cleanly.

- **Command Syntax (Educational / Future Use Only):**
  ```bash
  # Install: pip install git-filter-repo
  # Analyze and strip .env completely across all historical commits:
  git filter-repo --invert-paths --path .env
  ```

### Option B: BFG Repo-Cleaner
A simpler, high-performance alternative written in Scala/Java.

- **Command Syntax (Educational / Future Use Only):**
  ```bash
  # Delete all files named .env from history:
  bfg --delete-files .env
  git reflog expire --expire=now --all && git gc --prune=now --aggressive
  ```

---

## 4. Risks and Impact of Rewriting History

Rewriting git history is a disruptive operation that should not be performed lightly:

1. **Commit Hash Cascades:** Every commit from `ae00dea` forward will receive a completely new SHA-1/SHA-256 commit hash.
2. **Breaks Collaborator Clones:** Any team members working on local branches will face non-fast-forward divergence errors when pulling. They must delete and re-clone their local repositories.
3. **Requires Force-Pushing (`git push --force`):** Overwriting remote branches disables branch protection checks and can destroy unmerged work if done incorrectly.
4. **Invalidates Academic Audit Trails:** If previous project documentation, test logs, or remediation reports cited specific commit hashes (e.g. `ae00dea`, `c6d61ad`), those citations will no longer match the rewritten git log.

---

## 5. Recommended Operational Order
1. **Rotate the credentials first** in the Supabase Dashboard and update the local `.env` file.
2. **Verify rotation** using `scripts/verify_secret_rotation.py`.
3. **Only scrub git history** at the final project packaging milestone, coordinated with all project stakeholders.
