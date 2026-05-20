# ~/.zshrc - interactive zsh configuration
# Managed in ~/.dotfiles - https://github.com/geonu/dot

# Keep PATH/FPATH free of duplicates so re-sourcing this file is idempotent.
typeset -U path fpath

# --- Homebrew ---------------------------------------------------------------
# Apple Silicon installs to /opt/homebrew, Intel to /usr/local.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

# --- zsh plugins (antidote) -------------------------------------------------
antidote_zsh="$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
if [[ -e "$antidote_zsh" ]]; then
  source "$antidote_zsh"
  antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
fi
unset antidote_zsh

autoload -Uz compinit && compinit

# --- aliases ----------------------------------------------------------------
alias ls="eza"
alias ll="eza -al"
alias cls="clear"
alias vi="nvim"

# --- environment ------------------------------------------------------------
export EDITOR=nvim
export CLICOLOR=1

# locale
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- runtimes ---------------------------------------------------------------
# mise manages Node, Python, Java, ... (replaces nvm/pyenv/jenv).
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# PostgreSQL client (libpq is keg-only)
[[ -n "$HOMEBREW_PREFIX" ]] && export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH"

# --- prompt -----------------------------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"
