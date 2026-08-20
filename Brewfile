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
brew "chafa"               # terminal image viewer (Unicode/symbol art)
brew "cocoapods"           # CocoaPods dependency manager (iOS/macOS)
brew "coreutils"           # GNU core utilities
brew "duf"                 # modern `df` disk usage viewer
brew "dust"                # modern `du` disk usage viewer
brew "eza"                 # modern `ls` (maintained fork of exa)
brew "fd"                  # modern `find` file search
brew "fzf"                 # fuzzy finder (omppick session picker)
brew "gh"                  # GitHub CLI
brew "gogcli"              # Google Workspace CLI (gog) — replaces unmaintained googleworkspace-cli/gws
brew "jq"                  # JSON processor
brew "libpq"               # PostgreSQL client libraries (psql)
brew "mise"                # polyglot runtime manager (replaces nvm/pyenv/jenv)
brew "neovim"              # editor
brew "can1357/tap/omp"     # oh-my-pi coding agent (config in omp/)
brew "pnpm"                # Node package manager
brew "railway"             # Railway CLI
brew "ripgrep"             # modern `grep` file search (used by nvim)
brew "starship"            # shell prompt
brew "supabase/tap/supabase" # Supabase CLI (replaces supabase MCP)
brew "tmux"                # terminal multiplexer
brew "vercel-cli"          # Vercel CLI (replaces vercel MCP)
brew "yq"                  # YAML processor
brew "zoxide"              # modern `cd` with directory jumping

# --- language servers (OMP LSP auto-detection) -----------------------------
brew "bash-language-server" # bash/zsh LSP (bin/, zshrc, tests/*.zsh)
brew "yaml-language-server" # YAML LSP (omp/ configs, .github/workflows)
brew "typescript-language-server" # TS/JS LSP (auto-attaches in TS projects: package.json/tsconfig.json)

# Node, Python, Java, ... are managed by mise (see mise/config.toml).

# --- GUI apps (casks) -------------------------------------------------------
cask "chatgpt"           # OpenAI ChatGPT desktop app
cask "codex"
cask "steipete/tap/codexbar"
cask "gcloud-cli"
cask "font-hack-nerd-font" # terminal font (Alacritty config)
# DEPRECATED cask, disabled 2026-09-01 (fails macOS Gatekeeper / not notarized).
# BEFORE 2026-09-01: remove this line and build from source instead, e.g.
#   mise use -g rust@latest && cargo install alacritty   (binary -> ~/.cargo/bin)
# or `git clone … && make app` for a /Applications bundle. Config is unaffected.
cask "alacritty"           # terminal emulator (GPU, low-RAM, primary)
cask "google-chrome"
cask "orbstack"           # docker/linux runtime (Docker Desktop replacement)
cask "rectangle"           # window manager
cask "tailscale-app"       # mesh VPN
cask "visual-studio-code"
