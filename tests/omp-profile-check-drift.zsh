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

models_dir="$work/models"
mkdir -p "$models_dir"
export PI_CODING_AGENT_DIR="$models_dir"
python3 - "$models_dir/models.db" <<'PY'
import json
import sqlite3
import sys

db = sys.argv[1]
providers = {
    "openai-codex": [
        {"id": "gpt-5.6-luna", "thinking": {"efforts": ["low", "medium", "high"]}},
        {"id": "gpt-5.6-terra", "thinking": {"efforts": ["medium", "high", "xhigh"]}},
        {"id": "gpt-5.6-sol", "thinking": {"efforts": ["medium", "high", "xhigh"]}},
    ],
    "anthropic": [
        {"id": "claude-haiku-4-5", "thinking": {"efforts": ["minimal", "off"]}},
        {"id": "claude-opus-5", "thinking": {"efforts": ["medium", "high"]}},
        {"id": "claude-sonnet-5", "thinking": {"efforts": ["medium", "high"]}},
    ],
    "zai": [
        {"id": "glm-5.3", "thinking": {"efforts": ["low", "high", "max"], "requiresEffort": True}},
    ],
    "xai-oauth": [
        {"id": "grok-4.6", "thinking": {"efforts": ["minimal", "low", "medium", "high", "xhigh"]}},
    ],
    "kimi-code": [
        {"id": "k3", "thinking": {"efforts": ["minimal", "medium", "high"]}},
    ],
}

conn = sqlite3.connect(db)
conn.execute("create table model_cache (provider_id text, models text)")
for provider_id, models in providers.items():
    conn.execute(
        "insert into model_cache (provider_id, models) values (?, ?)",
        (provider_id, json.dumps(models)),
    )
conn.commit()
PY

python3 - "$work/omp/profiles/gpt.yml" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace(
    "  smol: openai-codex/gpt-5.6-luna:low",
    "  smol: openai-codex/gpt-5.6-luna:off",
)
text = text.replace(
    "  commit: openai-codex/gpt-5.6-luna:off",
    "  commit: zai/glm-5.3:low",
)
path.write_text(text)
PY

OMP_ACTIVE_PROFILE=config bash "$work/bin/omp-profile-check.sh" "$work"

python3 - "$work/omp/profiles/gpt.yml" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(path.read_text().replace("zai/glm-5.3:low", "zai/glm-5.3:off"))
PY

output_file="$work/check.out"
if OMP_ACTIVE_PROFILE=config bash "$work/bin/omp-profile-check.sh" "$work" >"$output_file" 2>&1; then
  fail "expected profile check to reject off for a model that requires an effort"
fi

output="$(<"$output_file")"
if [[ "$output" != *"unsupported effort off for zai/glm-5.3"* || "$output" != *"requires an effort"* ]]; then
  fail "expected required-effort failure output, got: $output"
fi

content="$(<"$work/tmux.conf")"
default_option="set -g @omp-default-profile 'gpt'"
invalid_default_option="set -g @omp-default-profile 'not-a-profile'"
print -r -- "${content/$default_option/$invalid_default_option}" > "$work/tmux.conf"

output_file="$work/check.out"
if bash "$work/bin/omp-profile-check.sh" "$work" >"$output_file" 2>&1; then
  fail "expected profile check to reject an unknown @omp-default-profile"
fi

output="$(<"$output_file")"
if [[ "$output" != *"@omp-default-profile"* ]]; then
  fail "expected @omp-default-profile in failure output, got: $output"
fi

print -- "ok: profile check rejects default-profile drift"
