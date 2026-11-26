# Fleet operations runbook

[Workspace fleet policy](AGENTS.md) sets the rules; this runbook provides examples and procedures. On an installed host, read the policy at `~/workspace/AGENTS.md`. Follow each claw repo’s own business manual for claw-specific operations.

## Workspace layout

The current layout (Phase A) is flat:

```text
~/workspace/
  AGENTS.md           # symlink to the fleet policy in geonu/dot
  <company-claw>/     # company TypeClaw agent and KB
  personal/           # personal TypeClaw agent
  geonu/              # personal code checkouts
  overflowing/        # product code and runners, not a claw
  claw/               # legacy empty checkout, not an agent
```

`typeclaw compose` from `~/workspace` discovers immediate children with `typeclaw.json`, skipping `_`-prefixed directories and non-agents. If you pin ports, give each claw a distinct `port` in its `typeclaw.json`.

An optional future layout (Phase B) would use `~/workspace/claws/{<company-claw>,personal}` and `~/workspace/repos/{geonu,overflowing}`. Phase A remains valid; move only after updating LaunchAgent and documentation paths, and run compose from the new parent of the claws.

If a claw changes runtimes, adapt its config filename, compose CLI, and secret file format without changing its identity or credential boundaries. An optional future `claw.yaml` is just an index, not runtime configuration:

```yaml
id: company-claw
identity: company
runtime: typeclaw
credentials: ~/credentials/company
```

## Host worktrees

Use `GIT_WORKTREE_GC=0 git worktree-new [-n DIRECTORY] BRANCH [START_POINT]` from the main checkout or a linked worktree. It creates a new local branch at `START_POINT` (default: the caller’s `HEAD`) under the main checkout’s `.worktrees/`. The directory name defaults to the branch name with `/` replaced by `-`. The main checkout must contain the exact line `/.worktrees/` in its root `.gitignore`; the helper refuses tracked content there.

```bash
GIT_WORKTREE_GC=0 git worktree-new -n docs-review docs/review main
```

This override disables only cleanup. The helper still checks available space on the main checkout’s filesystem and normally refuses below 30 GiB. If it refuses, report the space shortfall; do not lower or disable the floor to make the task proceed.

### Cleanup is a separate, approved operation

The helper itself defaults to GC **on** when `GIT_WORKTREE_GC` is unset. Before any GC-enabled invocation, inspect the target repository and get explicit approval for the cleanup scope, including ignored files and abandoned directories. Approval to create a worktree does not authorize cleanup. Prefer reviewing `git worktree list --porcelain`, tracked and untracked changes, ignored contents, and active processes before proposing cleanup. The helper has no GC-only mode: with GC enabled it cleans before checking space or creating the new checkout, so creation can fail **after** deleting data. Do not use a GC-enabled creation as a routine substitute for separate cleanup.

- The helper considers direct child worktrees under that repository’s `.worktrees/`. It skips the caller’s worktree and locked worktrees. It removes a worktree only when it meets the age cutoff (3 days by default), has no tracked or untracked changes, and its `HEAD` is already contained in `origin/HEAD`, `main`, or `master`. The branch remains, but ignored files such as `node_modules`, caches, and runtime output are lost. Use `git worktree lock` to protect a worktree that must be kept.
- A direct child directory unregistered with Git and lacking `.git`, such as an interrupted copy, is moved aside and deleted in the background once it is older than one hour. The helper can also resume interrupted background deletions.
- `GIT_WORKTREE_GC_DAYS` changes the stale age cutoff. `GIT_WORKTREE_MIN_FREE_GIB` controls the space floor (`0` disables it); it is not a workaround for low space in agent tasks. `GIT_WORKTREE_GC=0` is the agent creation default, regardless of the helper’s built-in default.
- Do not run `git worktree prune` on the host: registrations created in a container can look missing from the host while still in use. TypeClaw’s container-agent worktrees under `/tmp/cc-*` and `/tmp/cx-*` are runtime exceptions, not host worktrees to relocate or clean.

### Migrating an existing host worktree

Do not migrate automatically. Audit tracked and untracked changes, ignored data, and active processes first. For a deliberate migration approved for that worktree, use Git’s move command from the main checkout, not a filesystem move or deletion:

```bash
git -C <main> worktree move <old-path> <main>/.worktrees/<name>
```

Do not remove or prune the registration as part of migration.

## Credential layout and host CLI selection

`credentials-init` creates or repairs the host-only tree. The canonical store (L0) is `~/credentials/<identity>/`; keep `~/credentials` private (`chmod 700`) and outside Git. What may live there and how each credential class is maintained: [credentials store rules](../credentials/AGENTS.md). Example layout:

```text
~/credentials/
  company/
    gogcli/
    notion/vibe-notion/
    notion/ntn/
    agent-messenger/     # Slack user session for collectors
    <tool>/              # identity-specific stores; inventory lives in the claw's private doc
  personal/
    gogcli/
    notion/vibe-notion/
    notion/ntn/
    agent-messenger/
  shared/               # empty by default; explicit RO exceptions only
    data/
  AGENTS.md             # link to geonu/dot credentials/AGENTS.md (working rules)
  README.md             # optional local map, not tracked
  active -> company|personal
```

L1 means host CLI defaults such as `~/.config/...` and `~/Library/Application Support/...`; they are not the canonical store. `claw-id company` and `claw-id personal` switch `active` and retarget known host config symlinks. Run `claw-id` to show status. For shell tools such as `gog`, load the selected environment in the current shell with `eval "$(claw-id env)"`. Avoid concurrent host writers to a store and limit container mounts to one RW mount per OAuth store.

L2 is the in-container path (TypeClaw: `/agent/mounts/<name>`). Containers mount the matching L0 tool directory directly and ignore the host’s `active` selector and L1 links. Set an environment variable such as `GOG_HOME` in the runtime environment (e.g. TypeClaw `docker.file`/`ENV`) if supported. For tools with a hard-coded path, create a symlink **inside** the container to the L2 mount. For Application Support blobs, re-authenticate or copy the tool’s files into L0; don’t use Application Support as the source of truth.

### Intended mounts

In `typeclaw.json`, use `mounts` entries with an explicit host `path` and `readOnly` setting. Mount a tool’s dedicated directory, not its parent. For the company claw, replace ad-hoc `~/.config/...` mounts with:

| Host path | Access | Use |
| --- | --- | --- |
| `~/credentials/company/gogcli` | RW | `GOG_HOME`; the keyring needs token refresh |
| `~/credentials/company/notion/vibe-notion` | RO | vibe-notion |
| `~/credentials/company/notion/ntn` | RO | ntn |
| `~/credentials/company/agent-messenger` | RO | Slack user session, if collectors need it |
| `~/credentials/company/<tool>` | RO unless refresh requires RW | Company-only stores listed in the claw's private credential doc |

The personal claw uses its own corresponding `~/credentials/personal/...` tool directories; do not give it company-only commerce or bot tokens. An explicitly approved non-secret dataset such as `~/credentials/shared/data` is RO. A permitted product checkout under `~/workspace/` is code only, with no foreign tokens; the default RO policy applies. TypeClaw mounts are boot-only: restart or rebuild as required after a mount change.

### Migrating an existing tool store

1. Stop writers: stop the affected claw and make sure the host CLI is idle.
2. Move the tool’s data or re-authenticate into `~/credentials/<identity>/<tool>/`. Do not overwrite a populated destination without reconciling it first.
3. Update the claw’s L0 mount and its in-container environment variable or symlink.
4. If the host CLI is used, run `claw-id <identity>` to point its L1 config at the canonical store. Refresh the shell environment if the tool needs it.
5. Restart or rebuild as needed, run `typeclaw doctor`, and smoke-test the tool inside the claw.

## Onboarding and routine operations

### New Mac

1. Clone `geonu/dot` (including its submodule) and follow the [dotfiles installation instructions](../README.md). `./bootstrap` installs the policy link and host helpers; it invokes `./install`, whose Homebrew convergence can remove unlisted packages. Obtain approval before running bootstrap or install.
2. Run `credentials-init`. Restore credentials from an encrypted, out-of-band backup or re-authenticate into the correct identity.
3. Clone claws and product repos into `~/workspace`.
4. Provision each claw’s own `secrets.json` / `.env` as its docs specify; keep runtime secrets and `.typeclaw/` gitignored.
5. Set the host identity with `claw-id company` if using work CLIs. Run `typeclaw doctor` before starting each claw.

### New claw

1. Choose exactly one identity (`company` or `personal`) and ensure its L0 directories exist with `credentials-init`.
2. Create the claw directory and scaffold the runtime there (`typeclaw init`; use `~/workspace/personal` for the personal claw, not `~/workspace/claw`).
3. Configure only matching-identity tool mounts, explicit RO shared paths, and authorized code mounts. Provision runtime secrets in the claw’s own folder.
4. Link `~/workspace/AGENTS.md` from the claw’s AGENTS or README instead of copying the fleet rules.
5. Run `typeclaw doctor` before relying on the claw in production channels.

From the relevant claw directory, run `typeclaw doctor` and then `typeclaw start` when Docker/OrbStack is up and starting the claw is authorized. From `~/workspace` in Phase A, use `typeclaw compose status` to inspect the fleet.
