#!/usr/bin/env zsh
# Regression tests for OMP profile dispatch wrappers.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_zdotdir="${TMPDIR:-/tmp}/omp-profile-dispatch-zdotdir.$$"
mkdir -p "$test_zdotdir"
touch "$test_zdotdir/.zsh_plugins.txt"
export ZDOTDIR="$test_zdotdir"
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == dumb ]] && export TERM="xterm-256color"
export HOMEBREW_PREFIX="/nonexistent"

set +u
source "$repo_root/zshrc"
set -u

typeset -a omp_args
omp() {
  omp_args=("$@")
}

fail() {
  print -u2 -- "$1"
  exit 1
}

assert_args() {
  local label="$1"
  shift
  local -a expected=("$@")
  if [[ "${(j: :)omp_args}" != "${(j: :)expected}" ]]; then
    fail "$label: expected '${(j: :)expected}', got '${(j: :)omp_args}'"
  fi
}

assert_no_role_overrides() {
  local label="$1" flag
  for flag in --model --thinking --smol --slow --plan; do
    if (( ${omp_args[(I)$flag]} )); then
      fail "$label: profile wrapper must not pass role override flag $flag"
    fi
  done
}

expected_gpt_glm_config="$HOME/.dotfiles/omp/profiles/gpt-glm.yml"

ompr_fresh
assert_args "default fresh profile" --config "$expected_gpt_glm_config"
assert_no_role_overrides "default fresh profile"

ompr_fresh glm --probe
assert_args "glm alias" --config "$expected_gpt_glm_config" --probe
assert_no_role_overrides "glm alias"

ompr_fresh config --probe
assert_args "config fresh profile" --probe

bad_default_stderr="$test_zdotdir/bad-default.err"
OMP_DEFAULT_PROFILE=not-a-profile
if ompr_fresh 2>"$bad_default_stderr"; then
  fail "invalid OMP_DEFAULT_PROFILE must fail"
fi
unset OMP_DEFAULT_PROFILE
bad_default_output="$(<"$bad_default_stderr")"
if [[ "$bad_default_output" != *"invalid OMP profile"* ]]; then
  fail "invalid OMP_DEFAULT_PROFILE must print a profile error, got: $bad_default_output"
fi

print -- "ok: profile dispatch uses profile yaml without role overrides"
