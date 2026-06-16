# Brewfile - declarative package list for this machine.
#
#   brew bundle install --file=~/.dotfiles/Brewfile   # install everything
#   brew bundle check   --file=~/.dotfiles/Brewfile   # report what is missing
#   brew bundle cleanup --file=~/.dotfiles/Brewfile   # list/remove untracked
#
# `./install` symlinks this to ~/.Brewfile so `brew bundle --global` works too.

# --- taps -------------------------------------------------------------------
tap "can1357/tap"
tap "steipete/tap"
tap "supabase/tap"

# --- CLI tools --------------------------------------------------------------
brew "actionlint"          # GitHub Actions workflow linter
brew "antidote"            # zsh plugin manager (replaces zplug)
brew "bat"                 # modern `cat` with syntax highlighting
brew "btop"                # modern `top` resource monitor
brew "chafa"               # terminal image viewer (sixel output for tmux)
brew "cocoapods"           # CocoaPods dependency manager (iOS/macOS)
brew "coreutils"           # GNU core utilities
brew "duf"                 # modern `df` disk usage viewer
brew "dust"                # modern `du` disk usage viewer
brew "eza"                 # modern `ls` (maintained fork of exa)
brew "fd"                  # modern `find` file search
brew "gh"                  # GitHub CLI
brew "googleworkspace-cli" # Google Workspace CLI
brew "jq"                  # JSON processor
brew "libpq"               # PostgreSQL client libraries (psql)
brew "mise"                # polyglot runtime manager (replaces nvm/pyenv/jenv)
brew "neovim"              # editor
brew "can1357/tap/omp"     # oh-my-pi coding agent (config in omp/)
brew "pnpm"                # Node package manager
brew "ripgrep"             # modern `grep` file search (used by nvim)
brew "starship"            # shell prompt
brew "supabase/tap/supabase" # Supabase CLI (replaces supabase MCP)
brew "tmux"                # terminal multiplexer
brew "vercel-cli"          # Vercel CLI (replaces vercel MCP)
brew "yq"                  # YAML processor
brew "zoxide"              # modern `cd` with directory jumping

# Node, Python, Java, ... are managed by mise (see mise/config.toml).

# --- GUI apps (casks) -------------------------------------------------------
cask "codex"
cask "steipete/tap/codexbar"
cask "gcloud-cli"
cask "font-hack-nerd-font" # terminal font (used by Ghostty config)
cask "ghostty"             # terminal emulator
cask "google-chrome"
cask "rectangle"           # window manager
cask "tailscale-app"       # mesh VPN
cask "visual-studio-code"
