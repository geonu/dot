#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(pwd)}"
active_profile="${OMP_ACTIVE_PROFILE:-combo-claude}"
config="$repo_root/omp/config.yml"
profiles_dir="$repo_root/omp/profiles"
readme="$repo_root/omp/README.md"
models_db="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}/models.db"
python3 - "$config" "$profiles_dir" "$readme" "$models_db" "$active_profile" <<'PY'
import json
import sqlite3
import sys
from pathlib import Path

config = Path(sys.argv[1])
profiles_dir = Path(sys.argv[2])
readme = Path(sys.argv[3])
models_db = Path(sys.argv[4])
active_profile = sys.argv[5]
role_keys = ["default", "smol", "slow", "vision", "plan", "designer", "commit", "task"]
profile_names = ["gpt", "claude", "fable-codex", "combo-claude", "combo-gpt"]


def parse_roles(path: Path) -> dict[str, str]:
    roles = {}
    in_roles = False
    for raw in path.read_text().splitlines():
        if raw.startswith("modelRoles:"):
            in_roles = True
            continue
        if in_roles and raw and not raw.startswith(" "):
            break
        if in_roles and raw.startswith("  ") and ": " in raw:
            key, value = raw.strip().split(": ", 1)
            roles[key] = value.split(" #", 1)[0].strip()
    return roles

paths = {"config": config} | {name: profiles_dir / f"{name}.yml" for name in profile_names}
missing = [str(path) for path in paths.values() if not path.exists()]
if missing:
    raise SystemExit(f"missing profile files: {', '.join(missing)}")

conn = sqlite3.connect(models_db)
providers = {}
for provider_id, models_json in conn.execute("select provider_id, models from model_cache"):
    providers[provider_id] = {m["id"]: m for m in json.loads(models_json)}

errors = []
for name, path in paths.items():
    roles = parse_roles(path)
    if list(roles.keys()) != role_keys:
        errors.append(f"{path}: role keys mismatch: {list(roles.keys())}")
        continue
    for role, selector in roles.items():
        if "/" not in selector:
            errors.append(f"{path}: {role}: selector lacks provider: {selector}")
            continue
        provider, rest = selector.split("/", 1)
        model, effort = rest.rsplit(":", 1) if ":" in rest else (rest, "")
        model_meta = providers.get(provider, {}).get(model)
        if model_meta is None:
            errors.append(f"{path}: {role}: unknown model {provider}/{model}")
            continue
        if effort and effort != "off":
            efforts = (model_meta.get("thinking") or {}).get("efforts") or []
            if effort not in efforts:
                errors.append(f"{path}: {role}: unsupported effort {effort} for {provider}/{model}; available={efforts}")

config_roles = parse_roles(config)
active_path = profiles_dir / f"{active_profile}.yml"
if not active_path.exists():
    errors.append(f"unknown active profile: {active_profile} ({active_path} missing)")
elif config_roles != parse_roles(active_path):
    errors.append(f"omp/config.yml must match omp/profiles/{active_profile}.yml (active default profile)")

readme_text = readme.read_text()
for name in profile_names:
    if f"`{name}`" not in readme_text or f"omp/profiles/{name}.yml" not in readme_text:
        errors.append(f"README missing profile reference: {name}")

if errors:
    raise SystemExit("\n".join(errors))

print("OMP model profiles are consistent with README and local models.db")
for name, path in paths.items():
    print(f"- {name}: {path}")
PY
