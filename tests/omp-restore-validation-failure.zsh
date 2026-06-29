#!/usr/bin/env zsh
# Regression test: restore must report session-list validation failures.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_home="${TMPDIR:-/tmp}/omp-restore-validation.$$"
restore_dir="$test_home/.local/share/tmux/resurrect"
cwd="$test_home/project"
mkdir -p "$restore_dir" "$cwd"
export HOME="$test_home"
export OMP_TMUX_RESTORE_CONTEXT=manual

sidecar="$restore_dir/omp_panes"
print -r -- "session"$'\t'"1"$'\t'"1"$'\t'"$cwd"$'\t'"gpt-glm"$'\t'"11111111-1111-1111-1111-111111111111" > "$sidecar"

typeset display_msg=""
typeset -gi respawn_called=0

tmux() {
  case "$1" in
    display-message)
      if [[ "$*" == *" -p "* ]]; then
        case "${@: -1}" in
          '#{pane_pid}') print -- "100" ;;
          '#{pane_current_path}') print -- "$cwd" ;;
          *) print -u2 "unexpected display-message format: $*"; return 2 ;;
        esac
      else
        display_msg="${*:2}"
      fi
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
omp() {
  print -u2 "omp unavailable in restore hook"
  return 127
}


_omp_session_from_tmux_pane() { return 1; }

set +e
source "$repo_root/bin/omp-restore-panes" 2>"$test_home/restore.err"
restore_status=$?
set -e

if (( restore_status != 0 )); then
  print -u2 "restore helper should continue after reporting validation failure, got status $restore_status"
  exit 1
fi

if (( respawn_called != 0 )); then
  print -u2 "validation failure must not respawn pane; called $respawn_called time(s)"
  exit 1
fi

stderr="$(<"$test_home/restore.err")"
if [[ "$stderr" != *"cannot list OMP sessions"* ]]; then
  print -u2 "expected stderr to explain session-list validation failure, got: $stderr"
  exit 1
fi

if [[ "$display_msg" != *"cannot validate sessions"* ]]; then
  print -u2 "expected tmux display-message to mention validation failure, got: $display_msg"
  exit 1
fi

print -- "ok: restore reports session validation failures"
