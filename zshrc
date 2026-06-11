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
# Oh My Zsh plugins cache completions here; ensure the dir exists and is ours.
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# compinit must run before plugins that call compdef (e.g. the omz git plugin).
autoload -Uz compinit && compinit

antidote_zsh="$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"
if [[ -e "$antidote_zsh" ]]; then
  source "$antidote_zsh"
  antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
fi
unset antidote_zsh

# --- aliases ----------------------------------------------------------------
# Modern replacements for classic coreutils commands.
alias ls="eza"
alias ll="eza -al"
alias cat="bat --paging=never"
alias top="btop"
alias du="dust"
alias df="duf"
alias cls="clear"
alias vi="nvim"


# OMP session helpers. Resume can restore the session's active model, so these
# wrappers force the provider profile while preserving the latest session id.
_omp_latest_session() {
  omp __complete sessions -- "" | awk 'NR == 1 { print $1; exit }'
}

_omp_descendant_pids() {
  local -a queue out children
  local pid child
  queue=("$1")

  while (( ${#queue[@]} )); do
    pid="${queue[1]}"
    queue=("${queue[@]:1}")
    children=("${(@f)$(pgrep -P "$pid" 2>/dev/null)}")
    for child in "${children[@]}"; do
      [[ -n "$child" ]] || continue
      out+=("$child")
      queue+=("$child")
    done
  done

  print -l -- "${out[@]}"
}

_omp_session_from_process() {
  local pid command session_path session_id

  for pid in "$@"; do
    command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if [[ "$command" =~ '--resume[ =]([^ ]+)' ]]; then
      print -- "$match[1]"
      return 0
    fi

    session_path="$(lsof -p "$pid" 2>/dev/null | awk '/\/sessions\/.*\.jsonl/ { print $NF; exit }')"
    if [[ -n "$session_path" ]]; then
      session_id="${session_path:t:r}"
      print -- "${session_id##*_}"
      return 0
    fi
  done

  return 1
}

_omp_session_from_tmux_pane() {
  local pane_pid="${1:-$(tmux display-message -p '#{pane_pid}' 2>/dev/null)}"
  local -a pids

  [[ -n "$pane_pid" ]] || return 1
  pids=("$pane_pid" "${(@f)$(_omp_descendant_pids "$pane_pid")}")
  _omp_session_from_process "${pids[@]}"
}

_omp_resume_args() {
  local session_id

  if [[ $# -gt 0 && "$1" != -* ]]; then
    session_id="$1"
    shift
  elif [[ -n "${OMP_RESUME_SESSION_ID:-}" ]]; then
    session_id="$OMP_RESUME_SESSION_ID"
  else
    session_id="$(_omp_latest_session)"
  fi

  if [[ -z "$session_id" ]]; then
    print -u2 "omp resume: no OMP session found for this directory"
    return 1
  fi

  print -- "--resume"
  print -- "$session_id"
  printf '%s\n' "$@"
}

_omp_profile_path() {
  print -- "$HOME/.dotfiles/omp/profiles/$1.yml"
}

ompgpt() {
  omp \
    --config "$(_omp_profile_path gpt)" \
    --model openai-codex/gpt-5.5 \
    --thinking medium \
    --smol openai-codex/gpt-5.4-nano \
    --slow openai-codex/gpt-5.5 \
    --plan openai-codex/gpt-5.5 \
    "$@"
}

ompclaude() {
  omp \
    --config "$(_omp_profile_path claude)" \
    --model anthropic/claude-fable-5 \
    --thinking low \
    --smol anthropic/claude-haiku-4-5 \
    --slow anthropic/claude-fable-5 \
    --plan anthropic/claude-fable-5 \
    "$@"
}

ompcombo_claude() {
  omp \
    --config "$(_omp_profile_path combo-claude)" \
    --model anthropic/claude-opus-4-8 \
    --thinking low \
    --smol anthropic/claude-haiku-4-5 \
    --slow openai-codex/gpt-5.5 \
    --plan openai-codex/gpt-5.5 \
    "$@"
}

ompcombo_gpt() {
  omp \
    --config "$(_omp_profile_path combo-gpt)" \
    --model openai-codex/gpt-5.5 \
    --thinking medium \
    --smol anthropic/claude-haiku-4-5 \
    --slow openai-codex/gpt-5.5 \
    --plan openai-codex/gpt-5.5 \
    "$@"
}

ompgptr() {
  local -a args
  args=("${(@f)$(_omp_resume_args "$@")}") || return 1
  ompgpt "${args[@]}"
}

ompclauder() {
  local -a args
  args=("${(@f)$(_omp_resume_args "$@")}") || return 1
  ompclaude "${args[@]}"
}

ompcombo_clauder() {
  local -a args
  args=("${(@f)$(_omp_resume_args "$@")}") || return 1
  ompcombo_claude "${args[@]}"
}

ompcombo_gptr() {
  local -a args
  args=("${(@f)$(_omp_resume_args "$@")}") || return 1
  ompcombo_gpt "${args[@]}"
}


ompr_tmux_respawn() {
  local profile="${1:-gpt}"
  local pane_pid pane_path session_id

  pane_pid="$(tmux display-message -p '#{pane_pid}')"
  pane_path="$(tmux display-message -p '#{pane_current_path}')"
  session_id="$(_omp_session_from_tmux_pane "$pane_pid" || true)"

  if [[ -z "$session_id" ]]; then
    session_id="$(_omp_latest_session)"
  fi

  if [[ -z "$session_id" ]]; then
    print -u2 "ompr_tmux_respawn: no OMP session found for this pane"
    return 1
  fi

  tmux respawn-pane -k -c "$pane_path" "env OMP_RESUME_SESSION_ID=$session_id zsh -lic 'ompr $profile'"
}
ompr() {
  local profile="${1:-gpt}"
  [[ $# -gt 0 ]] && shift

  case "$profile" in
    gpt) ompgptr "$@" ;;
    claude) ompclauder "$@" ;;
    combo-claude|combo|combination|mixed) ompcombo_clauder "$@" ;;
    combo-gpt) ompcombo_gptr "$@" ;;
    config|default)
      local -a args
      args=("${(@f)$(_omp_resume_args "$@")}") || return 1
      omp "${args[@]}"
      ;;
    *)
      print -u2 "usage: ompr [gpt|claude|combo-claude|combo-gpt|config] [session-id-prefix] [omp flags...]"
      return 2
      ;;
  esac
}
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

# --- directory jumping ------------------------------------------------------
# zoxide learns visited dirs; `--cmd cd` makes `cd` the smart jumper.
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# --- prompt -----------------------------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"
