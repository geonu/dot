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

`mise/config.toml` installs the Herdr TUI. `git pull && ./install` applies its
shared client settings and SSH machine list:

| What | In this repo | On the machine |
| ---- | ------------ | -------------- |
| Shortcuts and dark theme | `herdr/config.toml` | symlink `~/.config/herdr/config.toml` |
| Remote machines | `herdr/endpoints.json` | `./install` merges missing target/session pairs into `~/.local/state/herdr/client/endpoints.json` |
| Common SSH hosts | `ssh/herdr-hosts.conf` | symlink `~/.ssh/config.d/herdr-hosts.conf`, loaded by an `Include` appended to `~/.ssh/config` |

Everything else stays local: TUI session and pane state, sockets, logs, SSH
keys, `known_hosts`, and agents. `endpoints.json` is a real local file: the
install step keeps existing profile IDs, labels, and enabled states and adds
only missing SSH target/session pairs. It keeps a dated backup before a change
and does not connect to, install, or update any remote server.

`config.toml` uses the tmux-like `Ctrl+A` prefix. Herdr's TUI defaults
already bind `h/j/k/l`, `z`, `x`, `c`, `n/p`, and `1–9` under that prefix.
Splitting uses `Ctrl+A v` (right) and `Ctrl+A -` (down), rather than the
desktop app's `%` and `"` bindings. The theme uses the built-in Catppuccin
dark palette.

Before linking, `./install` moves a regular TUI `config.toml` to
`config.toml.before-dotfiles-<time>`; dotbot refuses to overwrite regular files.
The SSH `Include` is appended after `Match all`, so each machine's own `Host`
rules keep precedence; `~/.ssh/config` is backed up first.

After adding a machine in the TUI, merge any other machines already saved on
that computer before publishing its catalog. Do not replace another
computer's entries, profile IDs, labels, or enabled states:

```bash
cd ~/.dotfiles
tmp="$(mktemp herdr/endpoints.json.XXXXXX)"
jq --slurpfile local "$HOME/.local/state/herdr/client/endpoints.json" '
  reduce $local[0].ssh[] as $entry (.;
    if any(.ssh[]; .target == $entry.target and .session == $entry.session)
    then . else .ssh += [$entry] end)
' herdr/endpoints.json > "$tmp" && mv "$tmp" herdr/endpoints.json
git diff -- herdr/endpoints.json
git add herdr && git commit && git push
```

`Brewfile` temporarily keeps `herdr-app`: removing it would cause the full
installer's `brew bundle cleanup --force` to uninstall the desktop app on
computers that still have running desktop sessions. The desktop app's local
settings are retained, but no longer linked into the repo. Remove the cask
only after those sessions have been migrated.

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
