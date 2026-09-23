#!/usr/bin/env bash
set -euo pipefail

helper=$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd -P)/git-worktree-new
tmp=$(mktemp -d)
tmp=$(cd "$tmp" && pwd -P)
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  [[ $1 == "$2" ]] || fail "expected [$2], got [$1]"
}

assert_path() {
  [[ -d $1 ]] || fail "missing directory: $1"
}

expect_fail() {
  if "$@" >/dev/null 2>&1; then
    fail "expected failure: $*"
  fi
}

run_from() {
  local repo=$1
  shift
  (
    cd "$repo"
    "$@"
  )
}

new_repo() {
  local repo=$1
  git init -q "$repo"
  git -C "$repo" config user.name test
  git -C "$repo" config user.email test@example.invalid
  printf '/.worktrees/\n' > "$repo/.gitignore"
  printf 'base\n' > "$repo/file"
  git -C "$repo" add .gitignore file
  git -C "$repo" commit -qm initial
}

main=$tmp/main
new_repo "$main"
base=$(git -C "$main" rev-parse HEAD)

# Main-checkout invocation creates the requested local branch under .worktrees.
(
  cd "$main"
  "$helper" feature/main
)
main_child=$main/.worktrees/feature-main
assert_path "$main_child"
assert_eq "$(git -C "$main_child" branch --show-current)" feature/main
assert_eq "$(git -C "$main_child" rev-parse HEAD)" "$base"
registered=false
while IFS= read -r line; do
  if [[ $line == "worktree $main_child" ]]; then
    registered=true
    break
  fi
done < <(git -C "$main" worktree list --porcelain)
$registered || fail 'main-created worktree was not registered'

# A linked-worktree invocation still creates under the main checkout and bases on its HEAD.
linked=$tmp/linked-caller
git -C "$main" worktree add -q -b caller "$linked" "$base"
printf 'linked\n' > "$linked/linked-file"
git -C "$linked" add linked-file
git -C "$linked" commit -qm linked
linked_head=$(git -C "$linked" rev-parse HEAD)
(
  cd "$linked"
  "$helper" feature/from-linked
)
linked_child=$main/.worktrees/feature-from-linked
assert_path "$linked_child"
assert_eq "$(git -C "$linked_child" rev-parse HEAD)" "$linked_head"
[[ ! -e $linked/.worktrees/feature-from-linked ]] || fail 'linked checkout received .worktrees child'

# An explicit start point overrides the caller worktree HEAD.
(
  cd "$linked"
  "$helper" feature/explicit "$base"
)
assert_eq "$(git -C "$main/.worktrees/feature-explicit" rev-parse HEAD)" "$base"

# An explicit safe directory name can differ from the branch-derived default.
(
  cd "$linked"
  "$helper" --name custom-directory feature/custom "$base"
)
assert_eq "$(git -C "$main/.worktrees/custom-directory" branch --show-current)" feature/custom
assert_eq "$(git -C "$main/.worktrees/custom-directory" rev-parse HEAD)" "$base"

# Missing and ineffective ignore rules are rejected before creating .worktrees.
missing=$tmp/missing-ignore
new_repo "$missing"
rm "$missing/.gitignore"
expect_fail run_from "$missing" "$helper" feature/missing-ignore
[[ ! -e $missing/.worktrees ]] || fail 'missing-ignore created .worktrees'
invalid=$tmp/invalid-ignore
new_repo "$invalid"
printf '/.worktrees\n' > "$invalid/.gitignore"
expect_fail run_from "$invalid" "$helper" feature/invalid-ignore
[[ ! -e $invalid/.worktrees ]] || fail 'invalid-ignore created .worktrees'
negated=$tmp/negated-ignore
new_repo "$negated"
printf '/.worktrees/\n!/.worktrees/\n' > "$negated/.gitignore"
expect_fail run_from "$negated" "$helper" feature/negated-ignore
[[ ! -e $negated/.worktrees ]] || fail 'negated ignore created .worktrees'

# Unsafe names and invalid branch syntax cannot escape or create a destination.
expect_fail run_from "$main" "$helper" -n ../escape feature/traversal
expect_fail run_from "$main" "$helper" -n . feature/dot
expect_fail run_from "$main" "$helper" bad..branch
[[ ! -e $tmp/escape ]] || fail 'traversal created a path outside .worktrees'
expect_fail run_from "$main" "$helper" -- feature/bad-start --not-a-ref
if git -C "$main" show-ref --verify --quiet refs/heads/feature/bad-start; then
  fail 'invalid start point created a branch'
fi

# Existing local branches and destinations are refused without altering either.
git -C "$main" branch existing-branch "$base"
expect_fail run_from "$main" "$helper" existing-branch
mkdir "$main/.worktrees/existing-destination"
expect_fail run_from "$main" "$helper" -n existing-destination feature/new-destination
[[ ! -d $main/.worktrees/new-destination ]] || fail 'existing destination attempt created another path'
assert_eq "$(git -C "$main" rev-parse refs/heads/existing-branch)" "$base"
if git -C "$main" show-ref --verify --quiet refs/heads/feature/new-destination; then
  fail 'existing destination created a branch'
fi
ln -s "$tmp/missing-destination" "$main/.worktrees/dangling"
expect_fail run_from "$main" "$helper" -n dangling feature/dangling
if git -C "$main" show-ref --verify --quiet refs/heads/feature/dangling; then
  fail 'dangling destination created a branch'
fi

# Tracked worktree content and symlinked containers are rejected.
tracked=$tmp/tracked-content
new_repo "$tracked"
mkdir "$tracked/.worktrees"
printf 'tracked\n' > "$tracked/.worktrees/tracked"
git -C "$tracked" add -f .worktrees/tracked
git -C "$tracked" commit -qm tracked
expect_fail run_from "$tracked" "$helper" feature/tracked-content
[[ ! -e $tracked/.worktrees/feature-tracked-content ]] || fail 'tracked content allowed a worktree'

symlinked=$tmp/symlinked-container
new_repo "$symlinked"
symlink_target=$tmp/symlink-target
mkdir "$symlink_target"
ln -s "$symlink_target" "$symlinked/.worktrees"
expect_fail run_from "$symlinked" "$helper" feature/symlinked-container
[[ ! -e $symlink_target/feature-symlinked-container ]] || fail 'symlink container escaped repository'

# Non-worktrees and separate Git directories are outside the helper's contract.
expect_fail run_from "$tmp" "$helper" feature/outside-git
separate=$tmp/separate-checkout
separate_git=$tmp/separate-git-dir
git init -q --separate-git-dir="$separate_git" "$separate"
git -C "$separate" config user.name test
git -C "$separate" config user.email test@example.invalid
printf '/.worktrees/\n' > "$separate/.gitignore"
printf 'base\n' > "$separate/file"
git -C "$separate" add .gitignore file
git -C "$separate" commit -qm initial
expect_fail run_from "$separate" "$helper" feature/separate-git-dir
[[ ! -e $separate/.worktrees ]] || fail 'separate Git directory created .worktrees'

# Dirty files survive exactly; the helper does not stage, reset, clean, or otherwise alter them.
printf 'dirty\n' > "$main/dirty-file"
before_status=$(git -C "$main" status --porcelain)
run_from "$main" "$helper" feature/dirty "$base"
after_status=$(git -C "$main" status --porcelain)
assert_eq "$after_status" "$before_status"
assert_eq "$(git -C "$main/.worktrees/feature-dirty" rev-parse HEAD)" "$base"
