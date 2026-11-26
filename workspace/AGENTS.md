# Workspace fleet policy

Machine-wide rules for sandboxed agent instances ("claws"). This file is linked at `~/workspace/AGENTS.md` from `geonu/dot`. Keep claw-specific business manuals in each claw repo; link here instead of copying fleet rules. No secrets in these docs.

Read the [fleet runbook](FLEET-RUNBOOK.md) for setup, migration, mount examples, and cleanup details. Use the sibling source in the active worktree when editing; from the installed prompt, read `~/.dotfiles/workspace/FLEET-RUNBOOK.md`.

## Identity and credentials

- One claw, one identity: `company` uses `~/credentials/company` and normally lives at `~/workspace/<company-claw>`; `personal` uses `~/credentials/personal` and lives at `~/workspace/personal`. `shared` is an exception directory, not a claw identity.
- Tool OAuth and user sessions (gog, Notion, Slack) belong in the matching `~/credentials/<identity>/` tool directory (L0, the canonical store). Keep `~/credentials` private (`0700`). Company admin, PII, and commerce credentials stay in `company`, never `personal` or `shared`.
- No default sharing. Use `~/credentials/shared/` only for a deliberately approved non-admin artifact needed by more than one claw, mounted read-only. Prefer separate copies or re-authentication.
- LLM provider keys and chat **bot** tokens belong in each claw’s own runtime secrets (`secrets.json` / `.env`), not in `~/credentials`; do not share them by default. CLI login residue (e.g. Codex/Claude) stays in that claw’s runtime home (`.typeclaw/home`).
- `~/credentials/active` and the host `~/.config` links managed by `claw-id` are for host CLIs only. Claws use matching L0 mounts directly, never `active` or host config links. Do not run concurrent host writers on one store; allow at most one RW container mount per OAuth store.
- Before adding, moving, rotating, or backing up anything under `~/credentials`, read the [credentials store principles](../credentials/AGENTS.md) (installed: `~/credentials/AGENTS.md`). Identity-specific inventories and procedures stay in private claw-repo documents, never in `geonu/dot`.

## Sandbox and mounts

- One container or equivalent sandbox per claw. TypeClaw binds only that claw’s folder at `/agent`; any other host data needs an explicit mount (`typeclaw.json` → `/agent/mounts/<name>`). Keep these boundaries if the runtime changes.
- Mount only the matching identity’s tool directory, an explicitly approved `shared/` path, or a code checkout the claw is allowed to access. Scope each mount narrowly and point the tool at it via an in-container environment variable or symlink.
- Default to `readOnly: true`; `readOnly: false` is only for stores that need to refresh tokens (e.g. gog keyring, OAuth token files). Shared mounts are always RO. TypeClaw mounts are boot-only; restart or rebuild as required after changes.
- Never mount all of `$HOME`, a grab bag of `~/.config`, another identity’s credentials, the Docker socket (`docker.sock`), or whole trees for SSH, Keychains, browsers, or cloud credentials (e.g. `~/.aws`).

## Git and backups

- `geonu/dot` is for machine config, fleet policy, and small host helpers, not credentials, agent memory/sessions, or the company KB. Keep non-secret TypeClaw config, the KB, collectors, and skills in the company claw repo; product repos are for application code, not claw runtime state. `geonu/claw` is an unused legacy placeholder, not the personal claw.
- Never commit secrets or tool sessions to any repo. Keep `secrets.json`, `.env`, and `.typeclaw/` gitignored. `~/credentials` is never a Git repo; back it up only encrypted and out of band.

## Host worktrees

- Keep host development worktrees under the main checkout at `<repo>/.worktrees/<name>`. The repository’s root `.gitignore` must contain the exact line `/.worktrees/`. TypeClaw’s container-agent worktrees under `/tmp/cc-*` and `/tmp/cx-*` are runtime exceptions, not host migration or cleanup targets.
- Agents create worktrees with `GIT_WORKTREE_GC=0 git worktree-new [-n DIRECTORY] BRANCH [START_POINT]`. The helper otherwise defaults to destructive GC. This override skips only cleanup: the free-space check still applies (default 30 GiB). Do not lower or disable the floor to proceed.
- Worktree creation does not authorize deletion. Treat cleanup as a separate, explicitly approved operation; inspect worktrees, ignored data, and active processes before proposing it. Never run `git worktree prune` on the host: active container registrations may look missing there.
- Do not migrate existing worktrees automatically. Audit changes and active processes before a deliberate `git worktree move`; never use filesystem `mv` or `rm` or remove or prune a registration to migrate it.
