#!/usr/bin/env zsh
# Regression test: invalid profile input must not kill/respawn panes.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_zdotdir="${TMPDIR:-/tmp}/omp-invalid-profile-zdotdir.$$"
mkdir -p "$test_zdotdir"
touch "$test_zdotdir/.zsh_plugins.txt"
touch "$test_zdotdir/.zsh_plugins.zsh"
export ZDOTDIR="$test_zdotdir"
export TERM="xterm-256color"
export HOMEBREW_PREFIX="/nonexistent"

set +u
source "$repo_root/zshrc"
set -u

_omp_latest_session() { return 0; }
_omp_session_valid() { return 1; }

typeset -gi respawn_called=0
typeset display_msg=""

tmux() {
  case "$1" in
    display-message)
      if [[ "$*" == *" -p "* ]]; then
        case "${@: -1}" in
          '#{pane_pid}') print -- "100" ;;
          '#{pane_current_path}') print -- "$test_zdotdir/project" ;;
          *) print -u2 "unexpected display-message format: $*"; return 2 ;;
        esac
      else
        display_msg="${*:2}"
      fi
      ;;
    show-options)
      return 0
      ;;
    set-option)
      return 0
      ;;
    respawn-pane)
      (( ++respawn_called ))
      ;;
    *)
      print -u2 "unexpected tmux command: $*"
      return 2
      ;;
  esac
}

if ompr_tmux_respawn not-a-profile %1 2>/dev/null; then
  print -u2 "expected invalid profile to fail"
  exit 1
fi

if (( respawn_called != 0 )); then
  print -u2 "invalid profile must not respawn-pane; called $respawn_called time(s)"
  exit 1
fi

if [[ "$display_msg" != *"invalid profile"* ]]; then
  print -u2 "expected tmux display-message to mention invalid profile, got: $display_msg"
  exit 1
fi

print -- "ok: invalid profile does not respawn pane"
