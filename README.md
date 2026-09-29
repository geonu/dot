# dotfiles

Personal macOS development environment, managed with
[dotbot](https://github.com/anishathalye/dotbot).

## What's inside

| Area     | Tool                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------- |
| Terminal | [Alacritty](https://alacritty.org)                                                                |
| Shell    | zsh + [antidote](https://antidote.sh) plugins + [starship](https://starship.rs) prompt            |
| Editor   | [Neovim](https://neovim.io) (Lua config, lazy.nvim)                                               |
| Runtimes | [mise](https://mise.jdx.dev) — Node, Python, Java, …                                              |
| Packages | [Homebrew](https://brew.sh) (`Brewfile`: formulae, casks, App Store via `mas`) + `packages/` globals |
| Fleet    | Multi-claw host policy + helpers (`workspace/AGENTS.md`, `claw-id`, `credentials-init`, `git-worktree-new`) |

## Repo boundaries

| Tree | Role |
| ---- | ---- |
| **This repo (`dot`)** | Machine config: shell, editor, brew, **fleet policy**, small PATH helpers. No API keys, no OAuth stores, no company KB. |
| **`~/workspace/*`** | Work checkouts and claw agent folders (e.g. `tandum`, product repos). |
| **`~/credentials/`** | Host-local tool sessions/OAuth by identity (`company` / `personal`). **Never git.** Created by `credentials-init`. |

Linked onto the machine by `./install`:

- `~/workspace/AGENTS.md` ← `workspace/AGENTS.md` (fleet rules)
- `~/.local/bin/claw-id`, `credentials-init`, `git-worktree-new`

After bootstrap on a new Mac: `credentials-init && claw-id company`, then restore
or re-auth tool credentials into `~/credentials/<identity>/` (see fleet AGENTS).

## Install

Fresh machine — `./bootstrap` installs Homebrew, all `Brewfile`
packages, the dotfile symlinks, and the `mise` runtimes in one go:

```bash
git clone --recurse-submodules git@github.com:geonu/dot.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap
```

Already set up — `./install` re-applies the symlinks and converges the
packages (see [Where packages live](#where-packages-live)).

Open a new shell afterwards: antidote installs the zsh plugins on first
run, and Neovim installs its plugins (lazy.nvim) on first launch.

## Keeping in sync

Every step is idempotent — re-run it anytime to converge:

```bash
./install                              # symlinks + Brewfile sync + mise/globals
brew bundle install   --file=Brewfile  # install missing packages
brew bundle cleanup   --file=Brewfile  # show packages not in the Brewfile
mise install                           # install runtimes from mise/config.toml
```

`brew bundle cleanup --force` actually removes the untracked packages.

## Where packages live

Each package has exactly one home. `./install` converges every layer.

| Layer | Declared in | Installed into | `./install` behaviour |
| ----- | ----------- | -------------- | --------------------- |
| Formulae, casks, App Store apps | `Brewfile` (`mas` entries by ID) | Homebrew, `/Applications` | install + upgrade; `cleanup --force` removes anything undeclared and resets tap trust |
| Node, Python runtimes | `mise/config.toml` | `~/.local/share/mise` | `mise install` |
| npm globals | `packages/npm-global.txt` | mise's node | install if missing |
| pip `--user` packages | `packages/pip-user.txt` | mise's python, scripts in `~/.local/bin` | install if missing |
| bun globals | `packages/bun-global.txt` | `~/.bun` (LaunchAgents call `~/.bun/bin/*`) | install if missing, only when bun exists |

Homebrew's own `node` and `python@3.14` exist only as formula dependencies;
an interactive shell puts mise's runtimes ahead of them on `PATH`.

Installed by hand (vendor installers, no Brewfile entry):

- bun — `curl -fsSL https://bun.sh/install | bash`
- Claude Code CLI (`~/.local/bin/claude`) — `curl -fsSL https://claude.ai/install.sh | bash`
- Notion CLI `ntn` (`~/.local/bin/ntn`) — self-updates with `ntn update`
- Aside CLI (`~/.local/bin/aside`) — linked by the Aside app
- AdGuard Mini — no cask; download from adguard.com
- Playwright browsers — `playwright install` after the pip packages
