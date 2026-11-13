# dotfiles

Personal macOS development environment, managed with
[dotbot](https://github.com/anishathalye/dotbot).

## What's inside

| Area     | Tool                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------- |
| Terminal | [Alacritty](https://alacritty.org) + [Herdr](https://herdr.dev)                                      |
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

## tmux battery status

The right-hand status bar hides the battery segment, including its separator,
on desktops without a battery (such as Mac mini) or when capacity is unavailable.
On laptops it keeps the original three-heart gauge. At 100% while connected
to power (and not discharging), it shows `∞` instead. No extra text labels.

macOS uses `pmset -g batt`; Linux uses the first battery in
`/sys/class/power_supply`. Run the macOS state regressions with
`bash tests/battery-indicator.bash`.

## Terminal fonts

The `Brewfile` package `font-hack-nerd-font` provides **Hack Nerd Font Mono**,
which Alacritty is already configured to use.

When `./install` runs from Terminal.app (`TERM_PROGRAM=Apple_Terminal`), it
runs `bin/terminal-font` after Homebrew sync. The helper requires macOS,
Terminal.app already running, and the installed `HackNFM-Regular` font. Missing
prerequisites or a missing named profile produce a successful skip; unexpected
automation errors fail the task. macOS may request Automation permission.

For a font-only repair, run the helper directly from this repo:

```bash
./bin/terminal-font "Clear Dark"
./bin/terminal-font               # saved default profile, not necessarily active
```

It changes only the saved profile's font name, preserves its size and other
settings, and does nothing when it already uses Hack. It does not change which
profile is the default or startup profile, create windows, or start Terminal.
An active tab can use a different profile: pass that profile's name explicitly.
Changing only a tab's current settings does not persist the profile.

Alternatively, in Terminal → Settings → Profiles → Text → Font, choose **Hack
Nerd Font Mono Regular** for the intended profile, keeping its current font
size. Korean text is expected to use macOS system font fallback.

Do not run the full installer for a font-only repair: it also converges packages,
runtimes, and symlinks unrelated to the font.

## Claude skills

`~/.claude/skills` links to `claude/skills`. Keep user-authored, portable
skills there and commit them explicitly. Two externally maintained directories
are ignored: `synced/` holds account-specific synchronized skills, and
`aside-browser/` holds the Aside skill (also installed in `~/.agents/skills`).
Leave their local contents intact; do not vendor them into this repo. Restore
them through the respective app or account on a new machine. `.omo/` is also
local-only and is not backed up by Git.

## Herdr

`Brewfile` installs the `herdr-app` cask. The parts of Herdr that should match on
every machine live here, and `git pull && ./install` applies them:

| What | In this repo | On the machine |
| ---- | ------------ | -------------- |
| Shortcuts | `herdr/keys.json` | symlink `~/.config/herdr-app/keys.json` |
| Theme, zoom, fonts, sounds | `herdr/settings.json` | symlink `~/.config/herdr-app/settings.json` |
| Remote machines | `herdr/machines.json` | `./install` adds missing ones via `herdr-core machine add` |
| Common SSH hosts | `ssh/herdr-hosts.conf` | symlink `~/.ssh/config.d/herdr-hosts.conf`, loaded by an `Include` appended to `~/.ssh/config` |

Everything else stays local: `core.json` (this machine's identity), spaces,
terminal and view state, sockets, logs, telemetry, generated mods, app-owned
files, SSH keys, `known_hosts` and agents.

The machine list is never symlinked: herdr-core replaces its
`~/.local/state/herdr-core/default/machines.json` atomically, which would turn
a link into a regular file. `./install` adds only machines whose SSH
target is missing; it never removes, renames or updates one, and never installs
herdr-core on the remote. Work continues across machines because every client
connects to the same remote herdr-core, whose terminals keep running.

Before linking, `./install` moves a regular `settings.json`/`keys.json` that
Herdr created to
`<file>.before-dotfiles-<time>`; dotbot refuses to overwrite regular files.
The SSH `Include` is appended after `Match all`, so each machine's own `Host`
rules keep precedence; `~/.ssh/config` is backed up first.

After adding or renaming a machine in Herdr, publish the list:

```bash
cd ~/.dotfiles
herdr-core machine ls --json \
  | jq '{machines: [.machines[] | {name, target, via, temporary}]}' > herdr/machines.json
git add herdr && git commit && git push
```

Settings and shortcuts edited in Herdr already write into the repo through
the symlinks. `settings.json` is shared as-is because it holds no paths; if
you set a sound file, use a path relative to `~/.config/herdr-app`.

The keys retain the macOS defaults and add the tmux `Ctrl+A` prefix:
`h/j/k/l` or arrows move between panes, `%`/`"` split right/down, `z`/`f`
toggle zoom, `c` creates a tab, and `n`/`p`/`1–9` switch tabs. Press
`Ctrl+A Ctrl+A` to send a literal Ctrl+A to the program. `Ctrl+A x` closes
a pane immediately, without tmux's confirmation. Pane resizing, tiled layout
and synchronized input have no matching Herdr command and are not bound.

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
