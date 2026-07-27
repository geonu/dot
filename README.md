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
| Packages | [Homebrew](https://brew.sh) (`Brewfile`)                                                          |
| Fleet    | Multi-claw host policy + helpers (`workspace/AGENTS.md`, `claw-id`, `credentials-init`)         |

## Repo boundaries

| Tree | Role |
| ---- | ---- |
| **This repo (`dot`)** | Machine config: shell, editor, brew, **fleet policy**, small PATH helpers. No API keys, no OAuth stores, no company KB. |
| **`~/workspace/*`** | Work checkouts and claw agent folders (e.g. `tandum`, product repos). |
| **`~/credentials/`** | Host-local tool sessions/OAuth by identity (`company` / `personal`). **Never git.** Created by `credentials-init`. |

Linked onto the machine by `./install`:

- `~/workspace/AGENTS.md` ← `workspace/AGENTS.md` (fleet rules)
- `~/.local/bin/claw-id`, `credentials-init`

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

Already set up — `./install` just re-applies the symlinks.

Open a new shell afterwards: antidote installs the zsh plugins on first
run, and Neovim installs its plugins (lazy.nvim) on first launch.

## Keeping in sync

Every step is idempotent — re-run it anytime to converge:

```bash
./install                              # add new symlinks, drop dead ones
brew bundle install   --file=Brewfile  # install missing packages
brew bundle cleanup   --file=Brewfile  # show packages not in the Brewfile
mise install                           # install runtimes from mise/config.toml
```

`brew bundle cleanup --force` actually removes the untracked packages.
