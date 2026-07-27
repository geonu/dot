#!/usr/bin/env zsh
# Regression tests for a single tmux default-profile option.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"

tmux_conf="$repo_root/tmux.conf"
save_script="$repo_root/bin/omp-save-panes"
restore_script="$repo_root/bin/omp-restore-panes"

fail() {
  print -u2 -- "$1"
  exit 1
}
assert_file_contains() {
  local path="$1" needle="$2" label="$3" content
  content="$(<"$path")"
  if [[ "$content" != *"$needle"* ]]; then
    fail "$label: expected $path to contain: $needle"
  fi
}

assert_file_not_contains() {
  local path="$1" needle="$2" label="$3" content
  content="$(<"$path")"
  if [[ "$content" == *"$needle"* ]]; then
    fail "$label: expected $path not to contain: $needle"
  fi
}

assert_file_contains "$tmux_conf" "set -g @omp-default-profile 'combo-gpt'" "tmux default option"
assert_file_contains "$tmux_conf" "set -g @omp-profile-choices 'gpt-glm/gpt/claude/combo-claude/combo-gpt/config'" "tmux choices option"
assert_file_contains "$tmux_conf" '-I "#{@omp-default-profile}"' "single-pane prompt default"
assert_file_contains "$tmux_conf" 'OMP profile (#{@omp-profile-choices})' "single-pane prompt choices"
assert_file_contains "$tmux_conf" 'OMP profile ALL panes (#{@omp-profile-choices})' "all-pane prompt choices"
assert_file_not_contains "$tmux_conf" "@omp-restore-profile" "old restore-only option"

assert_file_contains "$save_script" "@omp_profile" "save pane profile option"
assert_file_contains "$restore_script" "gpt|gpt-glm|claude|combo-claude|combo-gpt|config)" "restore profile whitelist"
assert_file_not_contains "$save_script" "@omp-restore-profile" "old save fallback option"
assert_file_not_contains "$restore_script" "@omp-restore-profile" "old restore fallback option"
assert_file_not_contains "$save_script" "\${fb:-combo-claude}" "unvalidated save fallback"
assert_file_not_contains "$restore_script" "\${fb:-combo-claude}" "unvalidated restore fallback"

print -- "ok: tmux default profile option is centralized"
