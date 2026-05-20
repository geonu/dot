# Brewfile - declarative package list for this machine.
#
#   brew bundle install --file=~/.dotfiles/Brewfile   # install everything
#   brew bundle check   --file=~/.dotfiles/Brewfile   # report what is missing
#   brew bundle cleanup --file=~/.dotfiles/Brewfile   # list/remove untracked
#
# `./install` symlinks this to ~/.Brewfile so `brew bundle --global` works too.

# --- taps -------------------------------------------------------------------
tap "manaflow-ai/cmux"
tap "steipete/tap"

# --- CLI tools --------------------------------------------------------------
brew "actionlint"          # GitHub Actions workflow linter
brew "antidote"            # zsh plugin manager (replaces zplug)
brew "coreutils"           # GNU core utilities
brew "eza"                 # modern `ls` (maintained fork of exa)
brew "gh"                  # GitHub CLI
brew "googleworkspace-cli" # Google Workspace CLI
brew "libpq"               # PostgreSQL client libraries (psql)
brew "mise"                # polyglot runtime manager (replaces nvm/pyenv/jenv)
brew "neovim"              # editor
brew "pnpm"                # Node package manager
brew "starship"            # shell prompt
brew "tmux"                # terminal multiplexer

# Node, Python, Java, ... are managed by mise (see mise/config.toml).

# --- GUI apps (casks) -------------------------------------------------------
cask "cmux"
cask "codex"
cask "steipete/tap/codexbar"
cask "gcloud-cli"
cask "font-hack-nerd-font" # terminal font (used by Ghostty config)
cask "ghostty"             # terminal emulator
cask "google-chrome"
cask "rectangle"           # window manager
cask "stats"               # menu-bar system monitor
cask "tailscale"           # mesh VPN
cask "visual-studio-code"
