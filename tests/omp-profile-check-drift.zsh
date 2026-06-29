#!/usr/bin/env zsh
# Regression tests that omp-profile-check catches profile/default drift.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
work="${TMPDIR:-/tmp}/omp-profile-check-drift.$$"
trap 'rm -rf "$work"' EXIT

fail() {
  print -u2 -- "$1"
  exit 1
}

mkdir -p "$work/omp/profiles" "$work/bin"
cp "$repo_root/omp/config.yml" "$work/omp/config.yml"
cp "$repo_root/omp/README.md" "$work/omp/README.md"
cp "$repo_root/omp/profiles/"*.yml "$work/omp/profiles/"
cp "$repo_root/tmux.conf" "$work/tmux.conf"
cp "$repo_root/zshrc" "$work/zshrc"
cp "$repo_root/bin/omp-profile-check.sh" "$work/bin/omp-profile-check.sh"
cp "$repo_root/bin/omp-save-panes" "$work/bin/omp-save-panes"
cp "$repo_root/bin/omp-restore-panes" "$work/bin/omp-restore-panes"

content="$(<"$work/tmux.conf")"
print -r -- "${content/gpt-glm/not-a-profile}" > "$work/tmux.conf"

output_file="$work/check.out"
if bash "$work/bin/omp-profile-check.sh" "$work" >"$output_file" 2>&1; then
  fail "expected profile check to reject an unknown @omp-default-profile"
fi

output="$(<"$output_file")"
if [[ "$output" != *"@omp-default-profile"* ]]; then
  fail "expected @omp-default-profile in failure output, got: $output"
fi

print -- "ok: profile check rejects default-profile drift"
