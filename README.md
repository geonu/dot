# dotfiles

Personal macOS development environment, managed with
[dotbot](https://github.com/anishathalye/dotbot).

## What's inside

| Area     | Tool                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------- |
| Terminal | [Ghostty](https://ghostty.org)                                                                    |
| Shell    | zsh + [antidote](https://antidote.sh) plugins + [starship](https://starship.rs) prompt            |
| Editor   | [Neovim](https://neovim.io) (vim-plug)                                                            |
| Runtimes | [mise](https://mise.jdx.dev) — Node, Python, Java, …                                              |
| Packages | [Homebrew](https://brew.sh) (`Brewfile`)                                                          |

## Install

Requires [Homebrew](https://brew.sh).

```bash
git clone --recurse-submodules git@github.com:geonu/dot.git ~/.dotfiles
cd ~/.dotfiles

brew bundle install --file=Brewfile   # install packages
./install                             # symlink configs
```

Open a new shell afterwards: antidote installs the zsh plugins on first
run, and `nvim +PlugInstall +qa` installs the editor plugins.
