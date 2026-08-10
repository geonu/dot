#!/usr/bin/env zsh
# Regression tests for OMP profile dispatch wrappers.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
test_zdotdir="${TMPDIR:-/tmp}/omp-profile-dispatch-zdotdir.$$"
mkdir -p "$test_zdotdir"
touch "$test_zdotdir/.zsh_plugins.txt"
touch "$test_zdotdir/.zsh_plugins.zsh"
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

expected_gpt_glm_flags() {
  print -l -- \
    --config "$expected_gpt_glm_config" \
    --model openai-codex/gpt-5.6-terra \
    --thinking medium \
    --smol openai-codex/gpt-5.6-luna:low \
    --slow openai-codex/gpt-5.6-sol:xhigh \
    --plan openai-codex/gpt-5.6-sol:xhigh
}

expected_gpt_flags() {
  print -l -- \
    --config "$expected_gpt_config" \
    --model openai-codex/gpt-5.6-terra \
    --thinking medium \
    --smol openai-codex/gpt-5.6-luna:low \
    --slow openai-codex/gpt-5.6-sol:high \
    --plan openai-codex/gpt-5.6-sol:xhigh
}

expected_grok_flags() {
  print -l -- \
    --config "$expected_grok_config" \
    --model xai-oauth/grok-4.5 \
    --thinking medium \
    --smol xai-oauth/grok-4.5:low \
    --slow xai-oauth/grok-4.5:high \
    --plan xai-oauth/grok-4.5:xhigh
}

expected_gpt_glm_config="$HOME/.dotfiles/omp/profiles/gpt-glm.yml"
expected_gpt_config="$HOME/.dotfiles/omp/profiles/gpt.yml"
expected_grok_config="$HOME/.dotfiles/omp/profiles/grok.yml"

ompr_fresh
assert_args "default fresh profile" "${(@f)$(expected_gpt_flags)}"

ompr_fresh glm --probe
assert_args "glm alias" "${(@f)$(expected_gpt_glm_flags)}" --probe

ompr_fresh config --probe
assert_args "config fresh profile" --probe
if ompr_fresh fable-codex --probe 2>/dev/null; then
  fail "removed Fable profile must be rejected"
fi

ompr gpt-glm 12345678 --probe
assert_args "resume profile switch" "${(@f)$(expected_gpt_glm_flags)}" --resume 12345678 --probe
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

print -- "ok: profile dispatch forces selected profile on fresh and resumed sessions"
