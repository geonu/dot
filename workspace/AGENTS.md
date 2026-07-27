# Workspace fleet policy

Machine-level rules for sandboxed agents ("claws"), host credentials, and
repo boundaries. **No secrets in this file.**

- Host path (linked by dotbot): `~/workspace/AGENTS.md`
- Source of truth in git: `geonu/dot` → `workspace/AGENTS.md`
- Per-claw business manuals (e.g. tandum `AGENTS.md`) stay in that claw's repo.
  They link here for fleet/credential rules; they do not duplicate them.

---

## 1. Roles of git repos

| Repo | GitHub | Contains | Must NOT contain |
|------|--------|----------|------------------|
| **dot** (`geonu/dot`) | public/private dotfiles | shell, editor, Brewfile, **this policy**, small host helpers (`claw-id`, `credentials-init`) | API keys, OAuth stores, agent memory, company KB |
| **tandum** (`geonu/tandum`) | company claw + KB | typeclaw agent folder, onboarding KB, collectors, skills | host-wide fleet policy (link only), raw tool OAuth under `~/credentials` |
| **claw** (`geonu/claw`) | legacy / unused | empty placeholder | do not revive as personal claw; prefer `~/workspace/personal` |
| **product repos** (overflowing, jangbu, …) | app code | application source | claw runtime state, `~/credentials` |

**dot vs workspace**

- **dot** = how the *machine* is configured (portable across Macs).
- **workspace** = what you *work on* (claws + code checkouts).
- **`~/credentials`** = host secret/session store. **Never a git repo.**

---

## 2. Identities

| Identity | Meaning | Credentials root | Typical claw folder |
|----------|---------|------------------|---------------------|
| `company` | Tandum / work | `~/credentials/company` | `~/workspace/tandum` |
| `personal` | private | `~/credentials/personal` | `~/workspace/personal` |
| `shared` | explicit exceptions only | `~/credentials/shared` | mounted RO when needed |

Rules:

1. **One claw process ↔ one identity** for secrets and tool OAuth.
2. Do **not** mount another identity's credential tree into a claw.
3. **No default sharing.** Put something under `shared/` only when you
   deliberately need the same *non-admin* artifact in two claws; prefer
   duplication or re-auth. Company admin/PII/commerce tokens never go to
   `personal` or `shared`.
4. LLM API keys and chat **bot** tokens live in the claw's own runtime
   secrets file (typeclaw: `secrets.json` / `.env`), not under
   `~/credentials`, and are **not** shared across claws by default.

---

## 3. Layout

### 3.1 Current (Phase A — flat workspace)

```text
~/workspace/
  AGENTS.md                 ← this file (symlink → dot)
  tandum/                   ← company claw (typeclaw)
  personal/                 ← personal claw (create when needed)
  geonu/                    ← personal code (dot lives at geonu/dot)
  overflowing/              ← product / runners (not a claw)
  claw/                     ← legacy empty repo; do not use as an agent

~/credentials/              ← NOT in git; chmod 700
  company/ …
  personal/ …
  shared/ …
  active                    ← optional symlink: company | personal (host CLI only)
```

`typeclaw compose` from `~/workspace` picks immediate children that contain
`typeclaw.json` (skips `_`-prefixed and non-agent dirs).

### 3.2 Target (Phase B — optional later)

```text
~/workspace/
  AGENTS.md
  claws/
    tandum/
    personal/
  repos/
    geonu/
    overflowing/
```

Move only after LaunchAgents and docs paths are updated. Until then Phase A
is valid; this file describes both.

---

## 4. Runtime contract (typeclaw today, swappable later)

A **claw** is a sandboxed agent instance:

| Concern | Rule | typeclaw mapping |
|---------|------|------------------|
| Isolation | one container (or equivalent) per claw | Docker/OrbStack container |
| Agent tree | bind agent folder only | cwd → `/agent` |
| Secrets | per-claw runtime store | `secrets.json`, `.env`, `.typeclaw/` |
| Host data | **explicit mounts only** | `typeclaw.json#mounts` → `/agent/mounts/<name>` |
| Home | never mount all of `~` | forbidden |
| Identity creds | mount matching `~/credentials/<id>/…` only | mount `path` + container `ENV`/symlink |
| Fleet ops | parent-dir compose | `typeclaw compose *` |

If the runtime changes, keep **identities + `~/credentials` + this policy**.
Only replace the adapter (config filename, compose CLI, secret file shape).

Optional future marker in a claw folder (not required today):

```yaml
# claw.yaml — index only; runtime config remains authoritative
id: tandum
identity: company
runtime: typeclaw
credentials: ~/credentials/company
```

---

## 5. Credentials model

### 5.1 Three layers

```text
L0  Canonical   ~/credentials/<identity>/...
L1  Host default ~/.config/..., ~/Library/Application Support/...
L2  In claw      /agent/mounts/<name>  (+ in-container ln/ENV to tool defaults)
```

- **L0 is always the source of truth.**
- L1 exists only so host-side CLIs that hardcode `~/.config/...` keep working
  (`claw-id` retargets symlinks for the *active* host identity).
- Claws mount **L0**, never a grab-bag of host `~/.config`.
- Inside the container, point tools at the mount via `ENV` (preferred) or
  symlink to the path the tool expects.

### 5.2 L0 tree

```text
~/credentials/
  company/
    gogcli/                 # GOG_HOME (RW — token refresh)
    notion/vibe-notion/     # usually RO in claw
    notion/ntn/
    agent-messenger/        # slack user session for collectors
    cafe24/
    hwahae/                 # token cache if split out of app package
  personal/
    gogcli/
    notion/vibe-notion/
    notion/ntn/
    agent-messenger/
  shared/                   # empty by default; explicit RO exceptions only
    data/
  README.md                 # local map (may exist only on disk)
  active -> company|personal
```

Create/repair with:

```bash
credentials-init
```

### 5.3 What goes where

| Kind | Location | Shared? |
|------|----------|---------|
| LLM provider keys | claw `secrets.json` / `.env` | no |
| Slack/Discord/… **bot** tokens | claw `secrets.json` | no |
| Tool OAuth / user sessions (gog, notion, user slack) | `~/credentials/<identity>/` | no |
| Commerce admin (Cafe24, hwahae, …) | `company` only | never personal |
| Code checkouts (jangbu, …) | `~/workspace/...` mount | code only; no foreign tokens |
| Codex/Claude CLI login residue | claw `.typeclaw/home` (etc.) | no |
| Deliberate non-secret datasets | `~/credentials/shared/...` | RO mount if needed |

### 5.4 Home-path tools

| Tool class | Strategy |
|------------|----------|
| Env-overridable (e.g. `GOG_HOME`) | Point at L0; set env on host via `claw-id` and in container `docker.file`/`ENV` |
| Fixed `~/.config/<app>` | Real files in L0; L1 symlink managed by `claw-id`; container mounts L0 and ln internally |
| App Support blobs | Re-auth or copy **into L0**; do not treat Application Support as SoT |
| SSH, Keychains, browsers, raw cloud cred dirs | **Never** mount whole trees |

Forbidden mounts: `~`, `~/.ssh/`, Keychains, `~/.aws/` (whole), docker.sock,
other identity's `~/credentials/...`.

### 5.5 Host active identity

Containers each mount their own L0 and do **not** use `active`.

Host interactive CLIs that only understand one global config path:

```bash
claw-id company    # default work
claw-id personal
claw-id            # status
```

Switching retargets `~/credentials/active` and known L1 symlinks. Do not
run two host writers against the same L0 path; claws: at most one RW mount
per OAuth store.

---

## 6. Mount policy (every claw)

1. Default **`readOnly: true`**.
2. **`readOnly: false`** only for stores that refresh tokens (gog keyring,
   cafe24 token file, similar).
3. Mount **paths under the claw's identity L0**, or an explicit `shared/`
   path, or a code repo the claw is allowed to touch.
4. Prefer mounting a **directory dedicated to that tool**, not a parent that
   mixes accounts.
5. After mount changes: runtime restart/rebuild as required (typeclaw:
   mounts are boot-only).

### Company claw (tandum) — intended mounts

Target host paths (migrate off ad-hoc `~/.config/...` when ready):

- `~/credentials/company/gogcli` → gog (`GOG_HOME`, RW)
- `~/credentials/company/notion/vibe-notion` (RO)
- `~/credentials/company/notion/ntn` (RO)
- `~/credentials/company/agent-messenger` (RO) if collectors need user slack
- commerce CLIs / token dirs under `company/` only

### Personal claw — intended mounts

- Only `~/credentials/personal/...`
- **No** cafe24, hwahae, jangbu company tokens, tandum bot secrets

---

## 7. Day-2 operations

```bash
# credentials tree
credentials-init
claw-id company

# company claw
cd ~/workspace/tandum
typeclaw doctor
typeclaw start   # when Docker/OrbStack is up

# personal claw (after init)
mkdir -p ~/workspace/personal && cd ~/workspace/personal
typeclaw init    # then edit mounts to personal L0 only

# fleet
cd ~/workspace && typeclaw compose status
```

Migration of an existing tool store into L0:

1. Stop writers (claw stopped / CLI idle).
2. Move or re-auth into `~/credentials/<identity>/<tool>/`.
3. Point claw mounts + container ENV/ln at L0.
4. `claw-id <identity>` so host L1 matches if you use host CLI.
5. Doctor + smoke the tool inside the claw.

---

## 8. GitHub / backup boundary

| Artifact | Git? | Where |
|----------|------|--------|
| This policy, helpers, dotfiles | yes | `geonu/dot` |
| tandum KB + typeclaw.json (non-secret) | yes | `geonu/tandum` |
| `secrets.json`, `.env`, `.typeclaw/` | **no** | claw folder, gitignored |
| `~/credentials/**` | **no** | host only; back up encrypted/out-of-band |
| Agent memory/sessions | runtime-managed / claw repo rules | never into dot |

New machine:

1. Clone + `./bootstrap` **dot** → policy link + helpers on PATH.
2. `credentials-init` + restore credentials from secure backup (or re-auth).
3. Clone claws/repos into `~/workspace`.
4. Drop per-claw `secrets.json` / `.env` as that claw's docs say.
5. `claw-id company`, `typeclaw doctor`, start.

---

## 9. Non-goals

- One mega-agent holding company + personal tokens
- Mounting all of `$HOME` for convenience
- Putting OAuth material into `geonu/dot` or any public tree
- Using `~/workspace/claw` as the personal agent
- Silent cross-identity `shared/` dumps

---

## 10. Checklist — new claw

1. Choose identity (`company` | `personal`).
2. `credentials-init` (ensure L0 dirs).
3. Scaffold runtime under `~/workspace/<name>` (typeclaw: `typeclaw init`).
4. Mounts: that identity's L0 only (+ explicit shared if any).
5. Runtime secrets only in the claw folder.
6. Link fleet policy from the claw's own AGENTS/README if it has one.
7. `doctor` before relying on it in prod channels.
