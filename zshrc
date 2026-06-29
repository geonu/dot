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

# --- tmux auto-attach (Alacritty) ------------------------------------------
# In an interactive Alacritty shell not already inside tmux: attach to the
# running server, or cold-start tmux so continuum restores the last saved
# session. Alacritty has no native TERM_PROGRAM, so its [env] block sets
# TERM_PROGRAM=alacritty for this guard. `exec` replaces this shell, so
# detaching/quitting tmux closes the window.
if [[ -o interactive && -z "$TMUX" && "$TERM_PROGRAM" == "alacritty" ]] && command -v tmux >/dev/null; then
  if tmux has-session 2>/dev/null; then
    exec tmux attach
  else
    exec tmux   # first launch after boot: triggers @continuum-restore
  fi
fi

# --- zsh plugins (antidote) -------------------------------------------------
# Oh My Zsh plugins cache completions here; ensure the dir exists and is ours.
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# compinit must run before plugins that call compdef (e.g. the omz git plugin).
# Rebuild the dump (full compinit + security audit) when it's missing or older
# than a day; otherwise take the fast path (-C) that skips the audit + staleness
# scan to shave interactive startup latency.
autoload -Uz compinit
_zcompdump=(${ZDOTDIR:-$HOME}/.zcompdump(Nmh-24))
if (( $#_zcompdump )); then compinit -C; else compinit; fi
unset _zcompdump

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
alias img="qlmanage -p 2>/dev/null"  # Quick Look preview (Alacritty has no inline images)


# OMP session helpers. Resume can restore the session's active model, so these
# wrappers force the provider profile while preserving the latest session id.
_omp_latest_session() {
  omp __complete sessions -- "" | awk 'NR == 1 { print $1; exit }'
}

# True when $1 is a prefix of some real session id for the current directory.
# Used to reject stale/poisoned ids (e.g. a subagent name like "SuccessiveBat")
# before they reach `--resume`, which would otherwise hard-fail the launch.
_omp_session_valid() {
  local id="$1"
  [[ -n "$id" ]] || return 1
  omp __complete sessions -- "" 2>/dev/null | awk -v id="$id" '
    index($1, id) == 1 { found = 1; exit }
    END { exit found ? 0 : 1 }
  '
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

    # Session files are stored as `<ts>_<uuid>.jsonl` (top-level) or
    # `<ts>_<uuid>/<AgentName>.jsonl` (subagent transcript). Resume needs the
    # parent session UUID in both cases — never the bare subagent name, which
    # `--resume` cannot find. Pull the UUID straight out of the path.
    session_path="$(lsof -p "$pid" 2>/dev/null | awk '/\/sessions\/.*\.jsonl/ { print $NF; exit }')"
    if [[ -n "$session_path" && \
          "$session_path" =~ '_([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})' ]]; then
      print -- "$match[1]"
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

_omp_pane_has_live_omp() {
  local pane_pid="${1:-$(tmux display-message -p '#{pane_pid}' 2>/dev/null)}"
  local pid command
  local -a pids

  [[ -n "$pane_pid" ]] || return 1
  pids=("$pane_pid" "${(@f)$(_omp_descendant_pids "$pane_pid")}")
  for pid in "${pids[@]}"; do
    command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    case "$command" in
      omp|omp' '*|*'/omp'|*'/omp '*|*' ompr '*|*' ompr_fresh '*) return 0 ;;
    esac
  done

  return 1
}

_omp_session_from_tmux_pane_wait() {
  local pane_pid="$1" attempts session_id

  session_id="$(_omp_session_from_tmux_pane "$pane_pid" || true)"
  if [[ -n "$session_id" ]]; then
    print -- "$session_id"
    return 0
  fi

  _omp_pane_has_live_omp "$pane_pid" || return 1
  for attempts in {1..10}; do
    sleep 0.2
    session_id="$(_omp_session_from_tmux_pane "$pane_pid" || true)"
    if [[ -n "$session_id" ]]; then
      print -- "$session_id"
      return 0
    fi
  done

  return 2
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

_omp_default_profile() {
  print -- "${OMP_DEFAULT_PROFILE:-gpt-glm}"
}

_omp_profile_choices() {
  print -- "gpt-glm/gpt/claude/fable-codex/combo-claude/combo-gpt/config"
}

_omp_profile_usage() {
  print -- "gpt-glm|gpt|claude|fable-codex|combo-claude|combo-gpt|config"
}

_omp_canonical_profile() {
  case "${1:-}" in
    gpt|gpt-glm|claude|fable-codex|combo-claude|combo-gpt|config)
      print -- "$1"
      ;;
    glm)
      print -- "gpt-glm"
      ;;
    fable|fable5)
      print -- "fable-codex"
      ;;
    combo|combination|mixed)
      print -- "combo-claude"
      ;;
    default)
      print -- "config"
      ;;
    *)
      return 1
      ;;
  esac
}

_omp_profile_arg() {
  local command="$1" requested="${2:-}" suffix="$3"

  if [[ -z "$requested" || "$requested" == -* ]]; then
    _omp_default_profile
    return 0
  fi

  if _omp_canonical_profile "$requested"; then
    return 0
  fi

  print -u2 "usage: $command [$(_omp_profile_usage)]$suffix"
  return 2
}

_omp_run_profile() {
  local profile="$1"
  shift

  profile="$(_omp_canonical_profile "$profile")" || return 2
  case "$profile" in
    config)
      omp "$@"
      ;;
    *)
      omp --config "$(_omp_profile_path "$profile")" "$@"
      ;;
  esac
}

_omp_resume_profile() {
  local profile="$1"
  shift
  local -a args

  args=("${(@f)$(_omp_resume_args "$@")}") || return 1
  _omp_run_profile "$profile" "${args[@]}"
}

ompgpt() { _omp_run_profile gpt "$@"; }
ompgpt_glm() { _omp_run_profile gpt-glm "$@"; }
ompclaude() { _omp_run_profile claude "$@"; }
ompfable_codex() { _omp_run_profile fable-codex "$@"; }
ompcombo_claude() { _omp_run_profile combo-claude "$@"; }
ompcombo_gpt() { _omp_run_profile combo-gpt "$@"; }

ompgptr() { _omp_resume_profile gpt "$@"; }
ompgpt_glmr() { _omp_resume_profile gpt-glm "$@"; }
ompclauder() { _omp_resume_profile claude "$@"; }
ompfable_codexr() { _omp_resume_profile fable-codex "$@"; }
ompcombo_clauder() { _omp_resume_profile combo-claude "$@"; }
ompcombo_gptr() { _omp_resume_profile combo-gpt "$@"; }


ompr_tmux_respawn() {
  local profile="${1:-$(_omp_default_profile)}"
  local pane="${2:-$(tmux display-message -p '#{pane_id}')}"
  local pane_pid pane_path session_id session_status launch

  pane_pid="$(tmux display-message -t "$pane" -p '#{pane_pid}')"
  pane_path="$(tmux display-message -t "$pane" -p '#{pane_current_path}')"
  # 1. Exact: read the session straight from the live omp process in this pane.
  #    A newly-created OMP session can need a short moment before its jsonl is
  #    visible to lsof; wait for it instead of falling through to stale fallbacks.
  if session_id="$(_omp_session_from_tmux_pane_wait "$pane_pid")"; then
    session_status=0
  else
    session_status=$?
    session_id=""
  fi

  # 2. Exact-ish: the session we last recorded for THIS pane. A pane option
  #    survives omp exiting, so a re-press after omp quit still hits the right
  #    conversation instead of guessing.
  if [[ -z "$session_id" && "$session_status" -ne 2 ]]; then
    session_id="$(tmux show-options -pqv -t "$pane" @omp_session)"
  fi

  # 3. Heuristic last resort: newest session in the pane's own directory.
  #    run-shell does not inherit the pane cwd, so resolve it there explicitly.
  if [[ -z "$session_id" && "$session_status" -ne 2 && -n "$pane_path" ]]; then
    session_id="$(cd "$pane_path" 2>/dev/null && _omp_latest_session)"
  fi

  # Discard any resolved id that no longer maps to a real session (stale pane
  # option, a baked-in `--resume <subagent>` from an earlier poisoned respawn,
  # etc.). Validate in the pane's own directory, since sessions are dir-scoped.
  # Drop the stale pane option too so the poison does not survive the respawn.
  if [[ -n "$session_id" ]] && \
     ! ( cd "$pane_path" 2>/dev/null && _omp_session_valid "$session_id" ); then
    tmux set-option -pu -t "$pane" @omp_session
    session_id=""
  fi

  # Always respawn so the pane is never left dead. Resume when we have a
  # session; otherwise start a fresh one for the chosen profile. `exec zsh -i`
  # keeps the pane alive after omp exits (remain-on-exit is off).
  if [[ -n "$session_id" ]]; then
    tmux set-option -p -t "$pane" @omp_session "$session_id"
    launch="env OMP_RESUME_SESSION_ID=$session_id zsh -lic 'ompr $profile; exec zsh -i'"
  else
    tmux set-option -pu -t "$pane" @omp_session
    launch="zsh -lic 'ompr_fresh $profile; exec zsh -i'"
  fi

  tmux respawn-pane -k -t "$pane" -c "$pane_path" "$launch"
}

# Respawn EVERY pane in a window into the latest OMP session, each resolving its
# OWN session (live process -> @omp_session pane option -> newest session in the
# pane cwd). This is NOT synchronize-panes: that mirrors keystrokes and would
# make every pane race to resolve against the active pane's cwd. Here we drive
# one server-side respawn per pane id, so each pane recalls its own conversation.
ompr_tmux_respawn_all() {
  local profile="${1:-$(_omp_default_profile)}"
  local window="${2:-$(tmux display-message -p '#{window_id}')}"
  local pane
  for pane in $(tmux list-panes -t "$window" -F '#{pane_id}'); do
    ompr_tmux_respawn "$profile" "$pane"
  done
}

ompr() {
  local profile

  profile="$(_omp_profile_arg ompr "${1:-}" " [session-id-prefix] [omp flags...]")" || return $?
  [[ $# -gt 0 && "$1" != -* ]] && shift
  _omp_resume_profile "$profile" "$@"
}

ompr_fresh() {
  local profile

  profile="$(_omp_profile_arg ompr_fresh "${1:-}" " [omp flags...]")" || return $?
  [[ $# -gt 0 && "$1" != -* ]] && shift
  _omp_run_profile "$profile" "$@"
}

# Cross-directory OMP session picker. After a crash you no longer hunt
# pane-by-pane with `C-a R`: from any pane run `omppick [profile]`, pick from
# every recent session (age / directory / auto-title), and it cd's into the
# session's own directory and resumes it under the chosen provider profile.
# Sessions are directory-scoped, so the cd is what lets `--resume` find them.
# Uses fzf when present, falls back to a numbered menu otherwise.
omppick() {
  emulate -L zsh
  local profile
  profile="$(_omp_profile_arg omppick "${1:-}" "")" || return $?
  local base="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}/sessions"
  local -a files lines
  local f hdr id cwd title now mt age tag

  # Depth-2 glob = real top-level sessions, newest-first by mtime, capped at 40.
  # Subagent transcripts live one level deeper (<ts>_<uuid>/<Agent>.jsonl) and
  # are excluded. (N) nullglob yields empty instead of erroring on no match.
  files=( "$base"/*/*.jsonl(Nom[1,40]) )
  (( ${#files} )) || { print -u2 "omppick: no OMP sessions under $base"; return 1; }

  now="$(date +%s)"
  for f in "${files[@]}"; do
    hdr="$(head -1 -- "$f")"
    # The header line of a resumable session carries id/cwd/title; jq emits
    # nothing for any other first line, so non-session files self-skip.
    IFS=$'\t' read -r id cwd title <<< "$(
      print -r -- "$hdr" | jq -r 'select(.type=="session") | [.id, .cwd, (.title // "(untitled)")] | @tsv' 2>/dev/null
    )"
    [[ -n "$id" ]] || continue
    mt="$(stat -f %m "$f" 2>/dev/null)" || mt="$now"
    age=$(( now - mt ))
    if   (( age < 3600 ));  then tag="$(( age / 60 ))m"
    elif (( age < 86400 )); then tag="$(( age / 3600 ))h"
    else                        tag="$(( age / 86400 ))d"
    fi
    # id<TAB>cwd<TAB>display — first two columns drive the resume, third is UI.
    lines+=( "${id}"$'\t'"${cwd}"$'\t'"$(printf '%4s  %-30s %s' "$tag" "${cwd/#$HOME/~}" "$title")" )
  done
  (( ${#lines} )) || { print -u2 "omppick: no resumable sessions found"; return 1; }

  local sel
  if command -v fzf >/dev/null 2>&1; then
    sel="$(printf '%s\n' "${lines[@]}" | fzf --delimiter=$'\t' --with-nth=3.. \
            --prompt="resume [$profile] > " --height=50% --reverse --no-sort)"
  else
    local i=1 l n
    for l in "${lines[@]}"; do printf '%2d) %s\n' "$i" "${l##*$'\t'}"; (( i++ )); done
    read "n?select # (empty cancels): "
    [[ -n "$n" ]] || return 1
    sel="${lines[$n]}"
  fi
  [[ -n "$sel" ]] || return 1

  local pick_id="${sel%%$'\t'*}" rest="${sel#*$'\t'}"
  local pick_cwd="${rest%%$'\t'*}"
  [[ -d "$pick_cwd" ]] && cd "$pick_cwd"
  ompr "$profile" "$pick_id"
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

# --- fuzzy finder -----------------------------------------------------------
# fzf key bindings + completion: Ctrl-R fuzzy history, Ctrl-T file widget,
# Alt-C cd into a subdir. (fzf also backs the omppick session picker.)
command -v fzf &>/dev/null && source <(fzf --zsh)

# --- prompt -----------------------------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"
