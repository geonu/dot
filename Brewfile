# Brewfile - declarative package list for this machine.
#
#   brew bundle install --file=~/.dotfiles/Brewfile   # install everything
#   brew bundle check   --file=~/.dotfiles/Brewfile   # report what is missing
#   brew bundle cleanup --file=~/.dotfiles/Brewfile   # list/remove untracked
#
# `./install` symlinks this to ~/.Brewfile so `brew bundle --global` works too.

# --- taps -------------------------------------------------------------------
# Homebrew only loads third-party tap items that are trusted. Trust is declared
# per item (`trusted: true`), not per tap, and `brew bundle cleanup --force`
# resets the trust store to exactly these declarations.
tap "can1357/tap"
tap "gyorgysh/keepresso"
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
brew "git-filter-repo"     # rewrite git history (strip files/secrets from commits)
brew "gogcli"              # Google Workspace CLI (gog) — replaces unmaintained googleworkspace-cli/gws
brew "jq"                  # JSON processor
brew "libpq"               # PostgreSQL client libraries (psql)
brew "mas"                 # Mac App Store CLI (backs the `mas` entries below)
brew "mise"                # polyglot runtime manager (replaces nvm/pyenv/jenv)
brew "neovim"              # editor
brew "can1357/tap/omp", trusted: true # oh-my-pi coding agent (config in omp/)
brew "pnpm"                # Node package manager
brew "postgresql@16"       # local PostgreSQL 16 server (data: $(brew --prefix)/var/postgresql@16)
brew "railway"             # Railway CLI
brew "ripgrep"             # modern `grep` file search (used by nvim)
brew "starship"            # shell prompt
brew "summarize"           # AI summarizer for URLs/media (SUMMARIZE_* config in zshrc)
brew "supabase/tap/supabase", trusted: true # Supabase CLI (replaces supabase MCP)
brew "tmux"                # terminal multiplexer
brew "vercel"              # Vercel CLI (replaces vercel MCP)
brew "yq"                  # YAML processor
brew "zoxide"              # modern `cd` with directory jumping

# --- language servers (OMP LSP auto-detection) -----------------------------
brew "bash-language-server" # bash/zsh LSP (bin/, zshrc, tests/*.zsh)
brew "yaml-language-server" # YAML LSP (omp/ configs, .github/workflows)
brew "typescript-language-server" # TS/JS LSP (auto-attaches in TS projects: package.json/tsconfig.json)

# Node and Python for your own use come from mise (see mise/config.toml). The
# node/python@3.14 kegs Homebrew pulls in are formula dependencies only; an
# interactive shell puts mise ahead of them on PATH.

# --- GUI apps (casks) -------------------------------------------------------
# Apps that update themselves (`auto_updates`) were adopted in place with
# `brew install --cask --adopt`; Homebrew tracks them and the app keeps
# updating itself. AdGuard Mini has no cask and stays a manual install.
cask "1password"          # password manager (1Password for Safari is under mas)
cask "aside"               # Aside browser (also links ~/.local/bin/aside)
cask "charles"             # HTTP(S) debugging proxy
cask "chatgpt"           # OpenAI ChatGPT desktop app
cask "claude"              # Claude desktop app (Claude Code CLI: see README)
cask "codex"
cask "steipete/tap/codexbar", trusted: true
cask "gcloud-cli"
cask "font-hack-nerd-font" # terminal font (Alacritty config)
# DISABLED cask since 2026-09-01 (fails the Gatekeeper check / not notarized).
# Kept on purpose: the installed app keeps working and `brew bundle` leaves an
# installed cask alone, but a fresh `brew bundle install` fails on this line.
# Removing the line makes `cleanup --force` uninstall the app, so replace it
# first (e.g. `git clone … && make app` for a /Applications bundle).
cask "alacritty"           # terminal emulator (GPU, low-RAM, primary)
cask "google-chrome"
cask "gyorgysh/keepresso/keepresso", trusted: true # caffeinate-style sleep/idle keeper (menu bar)
cask "muse"                # Meta Muse AI assistant
cask "notion"              # Notion desktop
cask "orbstack"           # docker/linux runtime (Docker Desktop replacement)
cask "rectangle"           # window manager
cask "slack"
cask "spotify"
cask "tailscale-app"       # mesh VPN
cask "visual-studio-code"

# --- Mac App Store (needs an App Store sign-in; IDs from `mas list`) ---------
mas "1Password for Safari", id: 1569813296
mas "Day One", id: 1055511498
mas "Numbers", id: 361304891
mas "Xcode", id: 497799835
