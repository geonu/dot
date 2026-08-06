#!/usr/bin/env zsh
# Newer OMP builds may leave no sessions/*.jsonl fd open. Profile switch must
# still resume via @omp_session instead of forcing ompr_fresh.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_zdotdir="${TMPDIR:-/tmp}/omp-respawn-no-jsonl-zdotdir.$$"
mkdir -p "$test_zdotdir"
touch "$test_zdotdir/.zsh_plugins.txt"
touch "$test_zdotdir/.zsh_plugins.zsh"
export ZDOTDIR="$test_zdotdir"
export HOMEBREW_PREFIX="/nonexistent"
export TERM="xterm-256color"

set +u
source "$repo_root/zshrc"
set -u

old_uuid="11111111-1111-1111-1111-111111111111"
pane_path="$test_zdotdir/project"
mkdir -p "$pane_path"

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
      100) print -- "/bin/zsh -lic ompr_fresh grok" ;;
      200) print -- "/opt/homebrew/bin/omp --config /Users/lee/.dotfiles/omp/profiles/grok.yml" ;;
    esac
  fi
}

lsof() { :; }
sleep() { :; }

_omp_session_valid() {
  [[ "$1" == "$old_uuid" ]]
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

ompr_tmux_respawn gpt %1

if [[ "$respawn_launch" != *"OMP_RESUME_SESSION_ID=$old_uuid"* ]]; then
  print -u2 "expected respawn to resume pane @omp_session $old_uuid when live jsonl is missing"
  print -u2 "actual launch: $respawn_launch"
  exit 1
fi

if [[ "$respawn_launch" == *"ompr_fresh"* ]]; then
  print -u2 "must not fall through to ompr_fresh when @omp_session is valid"
  print -u2 "actual launch: $respawn_launch"
  exit 1
fi

print -- "ok: profile switch resumes via @omp_session when live jsonl is absent"
