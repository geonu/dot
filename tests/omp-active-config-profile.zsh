#!/usr/bin/env zsh
# Regression test: plain omp config must match the selected default profile.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
work="${TMPDIR:-/tmp}/omp-active-config-profile.$$"
trap 'rm -rf "$work"' EXIT

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

providers = {
    "openai-codex": [
        {"id": "gpt-5.6-luna", "thinking": {"efforts": ["low", "medium", "high", "off"]}},
        {"id": "gpt-5.6-terra", "thinking": {"efforts": ["medium", "high", "xhigh"]}},
        {"id": "gpt-5.6-sol", "thinking": {"efforts": ["medium", "high", "xhigh"]}},
    ],
    "anthropic": [
        {"id": "claude-haiku-4-5", "thinking": {"efforts": ["minimal", "off"]}},
        {"id": "claude-opus-5", "thinking": {"efforts": ["medium", "high"]}},
        {"id": "claude-sonnet-5", "thinking": {"efforts": ["medium", "high"]}},
    ],
    "xai-oauth": [
        {"id": "grok-4.6", "thinking": {"efforts": ["minimal", "low", "medium", "high", "xhigh"]}},
    ],
    "zai": [
        {"id": "glm-5.3", "thinking": {"efforts": ["low", "high", "max"], "requiresEffort": True}},
    ],
    "kimi-code": [
        {"id": "k3", "thinking": {"efforts": ["minimal", "medium", "high"]}},
    ],
}

conn = sqlite3.connect(sys.argv[1])
conn.execute("create table model_cache (provider_id text, models text)")
for provider_id, models in providers.items():
    conn.execute(
        "insert into model_cache (provider_id, models) values (?, ?)",
        (provider_id, json.dumps(models)),
    )
conn.commit()
PY

OMP_ACTIVE_PROFILE=gpt bash "$work/bin/omp-profile-check.sh" "$work"

print -- "ok: active config matches gpt default profile"
