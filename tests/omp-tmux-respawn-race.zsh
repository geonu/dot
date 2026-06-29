#!/usr/bin/env zsh
# Regression test for the tmux profile-switch race: a freshly-started OMP pane may
# not expose its session jsonl on the first process scan. The respawn helper must
# wait for that live session instead of falling back to a stale @omp_session.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_zdotdir="${TMPDIR:-/tmp}/omp-profile-switch-zdotdir.$$"
mkdir -p "$test_zdotdir"
touch "$test_zdotdir/.zsh_plugins.txt"
export ZDOTDIR="$test_zdotdir"
export HOMEBREW_PREFIX="/nonexistent"
export TERM="xterm-256color"

set +u
source "$repo_root/zshrc"
set -u

old_uuid="11111111-1111-1111-1111-111111111111"
new_uuid="22222222-2222-2222-2222-222222222222"
pane_path="$test_zdotdir/project"
mkdir -p "$pane_path"

counter_file="$test_zdotdir/lsof-calls"
print -- 0 > "$counter_file"
typeset -a tmux_sets
typeset respawn_launch=""

pgrep() {
  if [[ "$1" == "-P" && "$2" == "100" ]]; then
    print -- "200"
  fi
}

ps() {
  if [[ "$1" == "-p" && "$3" == "-o" && "$4" == "command=" ]]; then
    case "$2" in
      100) print -- "/bin/zsh -lic ompr_fresh gpt" ;;
      200) print -- "/opt/homebrew/bin/omp --config /Users/lee/.dotfiles/omp/profiles/gpt.yml" ;;
    esac
  fi
}

lsof() {
  if [[ "$1" == "-p" ]]; then
    local calls
    calls="$(<"$counter_file")"
    (( ++calls ))
    print -- "$calls" > "$counter_file"
    if (( calls > 2 )); then
      print -- "omp 200 lee 10r REG 1,2 3 /Users/lee/.omp/agent/sessions/2026/06/29/2026-06-29T00-00-00_${new_uuid}.jsonl"
    fi
  fi
}

sleep() { :; }

_omp_session_valid() {
  [[ "$1" == "$old_uuid" || "$1" == "$new_uuid" ]]
}

_omp_latest_session() {
  print -- "33333333-3333-3333-3333-333333333333"
}

tmux() {
  case "$1" in
    display-message)
      case "${@: -1}" in
        '#{pane_pid}') print -- "100" ;;
        '#{pane_current_path}') print -- "$pane_path" ;;
        *) print -u2 "unexpected display-message: $*"; return 2 ;;
      esac
      ;;
    show-options)
      print -- "$old_uuid"
      ;;
    set-option)
      tmux_sets+=("$*")
      ;;
    respawn-pane)
      respawn_launch="${@: -1}"
      ;;
    *)
      print -u2 "unexpected tmux command: $*"
      return 2
      ;;
  esac
}

ompr_tmux_respawn combo-claude %1

if [[ "$respawn_launch" != *"OMP_RESUME_SESSION_ID=$new_uuid"* ]]; then
  print -u2 "expected respawn to resume newly opened session $new_uuid"
  print -u2 "actual launch: $respawn_launch"
  exit 1
fi

if [[ " ${(j: :)tmux_sets} " != *" @omp_session $new_uuid "* ]]; then
  print -u2 "expected @omp_session to be updated to $new_uuid"
  print -u2 "actual set-option calls: ${(j: | :)tmux_sets}"
  exit 1
fi

print -- "ok: profile switch waits for fresh live OMP session"
