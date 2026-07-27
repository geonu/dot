#!/usr/bin/env zsh
# Regression test: removed profiles must not silently restore as another provider mix.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_home="${TMPDIR:-/tmp}/omp-restore-removed-profile.$$"
restore_dir="$test_home/.local/share/tmux/resurrect"
cwd="$test_home/project"
mkdir -p "$restore_dir" "$cwd"
export HOME="$test_home"
export OMP_TMUX_RESTORE_CONTEXT=manual

sidecar="$restore_dir/omp_panes"
print -r -- "session"$'\t'"1"$'\t'"1"$'\t'"$cwd"$'\t'"fable-codex"$'\t'"11111111-1111-1111-1111-111111111111" > "$sidecar"

typeset display_msg=""
typeset -gi respawn_called=0

tmux() {
  case "$1" in
    display-message) display_msg="${*:2}" ;;
    respawn-pane) (( ++respawn_called )) ;;
    *)
      print -u2 "unexpected tmux command: $*"
      return 2
      ;;
  esac
}
omp() {
  print -u2 "omp must not run for a removed profile"
  return 127
}

source "$repo_root/bin/omp-restore-panes" 2>"$test_home/restore.err"

if (( respawn_called != 0 )); then
  print -u2 "removed profile must not respawn a pane; called $respawn_called time(s)"
  exit 1
fi

stderr="$(<"$test_home/restore.err")"
if [[ "$stderr" != *"unknown saved profile 'fable-codex'"* ]]; then
  print -u2 "expected removed profile diagnostic, got: $stderr"
  exit 1
fi

if [[ "$display_msg" != *"unknown profile 'fable-codex'"* ]]; then
  print -u2 "expected tmux message for removed profile, got: $display_msg"
  exit 1
fi

print -- "ok: removed profiles are skipped during restore"
