# PROJECT KNOWLEDGE BASE

## OVERVIEW
Personal macOS dotfiles (`geonu/dot`), applied with dotbot (git submodule `dotbot/`).
Also ships the multi-claw fleet policy and host helpers. `~/.dotfiles` is the
installed path to the permanent checkout: it can be the checkout itself or a
symlink to it, never a path into `.worktrees/`.

## STRUCTURE
```
dot/
├── install.conf.yaml   # single source of truth for every symlink + converge step
├── bootstrap / install # fresh-Mac setup / re-apply (idempotent)
├── agents/CORE.md      # global agent prompt -> ~/AGENTS.md, ~/agents.md, ~/.codex/AGENTS.md, ~/.omp/agent/AGENTS.md
│                       #   PLAYBOOK.md (linked on demand), README.md (maintenance loop)
├── workspace/AGENTS.md # fleet policy -> ~/workspace/AGENTS.md (NOT a guide for this repo)
├── omp/                # OMP agent config, profiles, extensions (see omp/AGENTS.md)
├── claude/             # ~/.claude: CLAUDE.md (@~/agents.md), settings.json, skills/
├── bin/                # tmux status helpers, OMP pane save/restore, terminal-font, claw-id, credentials-init, git-worktree-new, agent-handoff-audit
├── tests/              # zsh/bash regression tests for OMP wrappers, battery indicator, git-worktree-new
├── packages/           # npm / pip --user / bun global lists
├── docs/superpowers/   # historical plan/spec for a past change
└── dotbot/             # submodule; never edit
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add/move a linked file | `install.conf.yaml` `link:` | Add the source file in the same change; `clean:` drops dead links |
| Shell / OMP wrappers (`omp`, `ompr`, `omp<profile>`) | `zshrc` | `_omp_*` helpers |
| tmux keys, `Ctrl-a R` profile respawn | `tmux.conf`, `bin/tmux-theme.sh` | `@omp-default-profile`, `@omp-profile-choices` |
| Packages | `Brewfile`, `mise/config.toml`, `packages/*.txt` | One home per package (README table) |
| Agent behavior for every CLI | [agents/CORE.md](agents/CORE.md), [agents/PLAYBOOK.md](agents/PLAYBOOK.md) | Installed source: `~/.dotfiles/agents/`; change process in [agents/README.md](agents/README.md) |
| Terminal.app font | `bin/terminal-font` | `./install` runs it only from Terminal.app |
| Worktree helper | `bin/git-worktree-new` | Agent default: `GIT_WORKTREE_GC=0 git worktree-new BRANCH` |
| Fleet / credentials identity | [workspace/AGENTS.md](workspace/AGENTS.md), `bin/claw-id`, `bin/credentials-init` | Installed policy source: `~/.dotfiles/workspace/AGENTS.md` |

## CONVENTIONS
- Every installed file is a symlink declared in `install.conf.yaml`; never copy into `$HOME`.
- `./install` must stay convergent: `clean` removes dead links, Brewfile sync installs and
  `cleanup --force` uninstalls anything undeclared, globals are install-if-missing only.
- Runtimes come from mise, not Homebrew's `node`/`python` (those exist only as deps).
- File-modifying work goes in a linked worktree under `.worktrees/` (gitignored).
  Agents create it with `GIT_WORKTREE_GC=0 git worktree-new BRANCH` to avoid deleting
  other worktrees or their ignored files. Do not enable cleanup without explicit
  approval. Ignore `.worktrees/` when searching from the permanent checkout.
- Edit sources in the task worktree, not through installed links or the
  `~/.dotfiles` path to the permanent checkout.
- `omp/README.md` mixes Korean and English; keep the surrounding language when editing.

## ANTI-PATTERNS (THIS PROJECT)
- NEVER commit secrets, OAuth stores, API keys, or `~/credentials` content. See
  the credentials and backup rules in [the fleet policy](workspace/AGENTS.md)
  (`~/.dotfiles/workspace/AGENTS.md` on installed hosts).
- NEVER edit `workspace/AGENTS.md` as if it described this repo; it is machine-wide fleet policy.
- NEVER add a Homebrew package outside `Brewfile`; `cleanup --force` removes undeclared ones.
- Do not add a `link:` entry whose source file is not committed; fresh clones and `clean` break.
- Do not edit `dotbot/` (submodule) or `nvim/lazy-lock.json` by hand.
- Tests run in temp `HOME`/`ZDOTDIR` dirs; never point them at the real `~/.omp` or `omp` binary.

## UNIQUE STYLES
- Bash scripts: `set -euo pipefail`, `die()`/`usage()` helpers, env-var knobs with defaults.
- zsh tests: `emulate -R zsh; set -eo pipefail`, `repo_root="${0:A:h:h}"`, temp dirs removed
  by `trap ... EXIT`.

## VERIFICATION
Run the narrowest relevant checks in the worktree:
```bash
bin/omp-profile-check.sh            # OMP profile/README/zshrc/tmux consistency; needs ~/.omp/agent/models.db
for t in tests/*.zsh; do zsh "$t"; done
bash tests/git-worktree-new.bash && bash tests/battery-indicator.bash
# CI (.github/workflows/ci.yml) only checks syntax: bash -n, zsh -n zshrc, luajit, yq, actionlint
```

CI does not run `tests/`; run the relevant tests locally before claiming a change works.

## HOST SETUP (NOT VERIFICATION)
- `./bootstrap` provisions a fresh Mac: Homebrew, Brewfile packages, then `./install`.
- `./install` re-applies home-directory symlinks and settings, converges Homebrew
  (`brew bundle cleanup --global --force` removes undeclared packages), and sets
  up mise runtimes, globals, and TPM.

Both mutate the live host. Agents need explicit approval to run either, and
must run them from the permanent checkout, never from a linked worktree.
They are not smoke tests. See [Install](README.md#install)
(`~/.dotfiles/README.md` on installed hosts).

## NOTES
- `~/.omp/agent/AGENTS.md` links to `~/AGENTS.md`, which links to `agents/CORE.md`.
- Tailscale SSH needs the open-source `tailscale` formula and manual root setup (see `Brewfile`).
- The main checkout often carries uncommitted OMP work; check `git status` and compare with
  `origin/main` before trusting either as current.
