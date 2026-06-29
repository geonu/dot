#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(pwd)}"
active_profile="${OMP_ACTIVE_PROFILE:-config}"
config="$repo_root/omp/config.yml"
profiles_dir="$repo_root/omp/profiles"
readme="$repo_root/omp/README.md"
models_db="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}/models.db"
zshrc="$repo_root/zshrc"
tmux_conf="$repo_root/tmux.conf"
save_script="$repo_root/bin/omp-save-panes"
restore_script="$repo_root/bin/omp-restore-panes"
python3 - "$config" "$profiles_dir" "$readme" "$models_db" "$active_profile" "$zshrc" "$tmux_conf" "$save_script" "$restore_script" <<'PY'
import json
import re
import sqlite3
import sys
from pathlib import Path

config = Path(sys.argv[1])
profiles_dir = Path(sys.argv[2])
readme = Path(sys.argv[3])
models_db = Path(sys.argv[4])
active_profile = sys.argv[5]
zshrc = Path(sys.argv[6])
tmux_conf = Path(sys.argv[7])
save_script = Path(sys.argv[8])
restore_script = Path(sys.argv[9])
role_keys = ["default", "smol", "slow", "vision", "plan", "designer", "commit", "task"]
profile_names = ["gpt", "gpt-glm", "claude", "fable-codex", "combo-claude", "combo-gpt"]
profile_choices = ["gpt-glm", "gpt", "claude", "fable-codex", "combo-claude", "combo-gpt", "config"]
known_choices = set(profile_choices)
default_profile = "gpt-glm"


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


def tmux_option(text: str, option: str) -> str | None:
    match = re.search(rf"^set -g {re.escape(option)} '([^']+)'$", text, re.M)
    return match.group(1) if match else None


paths = {"config": config} | {name: profiles_dir / f"{name}.yml" for name in profile_names}
paths |= {
    "README": readme,
    "zshrc": zshrc,
    "tmux.conf": tmux_conf,
    "omp-save-panes": save_script,
    "omp-restore-panes": restore_script,
}
missing = [str(path) for path in paths.values() if not path.exists()]
if missing:
    raise SystemExit(f"missing profile files: {', '.join(missing)}")

conn = sqlite3.connect(models_db)
providers = {}
for provider_id, models_json in conn.execute("select provider_id, models from model_cache"):
    providers[provider_id] = {m["id"]: m for m in json.loads(models_json)}

errors = []
for name, path in {"config": config, **{name: profiles_dir / f"{name}.yml" for name in profile_names}}.items():
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
if active_profile not in {"config", "default"}:
    active_path = profiles_dir / f"{active_profile}.yml"
    if not active_path.exists():
        errors.append(f"unknown active profile: {active_profile} ({active_path} missing)")
    elif config_roles != parse_roles(active_path):
        errors.append(f"omp/config.yml must match omp/profiles/{active_profile}.yml (active default profile)")

readme_text = readme.read_text()
for name in profile_names:
    if f"`{name}`" not in readme_text or f"omp/profiles/{name}.yml" not in readme_text:
        errors.append(f"README missing profile reference: {name}")

zsh_text = zshrc.read_text()
tmux_text = tmux_conf.read_text()
save_text = save_script.read_text()
restore_text = restore_script.read_text()

tmux_default = tmux_option(tmux_text, "@omp-default-profile")
if tmux_default is None:
    errors.append("tmux.conf missing @omp-default-profile")
elif tmux_default not in known_choices:
    errors.append(f"tmux.conf @omp-default-profile unknown: {tmux_default}")
elif tmux_default != default_profile:
    errors.append(f"tmux.conf @omp-default-profile must be {default_profile}, got {tmux_default}")

tmux_choices = tmux_option(tmux_text, "@omp-profile-choices")
if tmux_choices is None:
    errors.append("tmux.conf missing @omp-profile-choices")
elif tmux_choices.split("/") != profile_choices:
    errors.append(f"tmux.conf @omp-profile-choices mismatch: {tmux_choices}")

if "@omp-restore-profile" in tmux_text:
    errors.append("tmux.conf still references old @omp-restore-profile")
for path, text in [(save_script, save_text), (restore_script, restore_text)]:
    if "@omp-default-profile" not in text:
        errors.append(f"{path} must read @omp-default-profile")
    if "@omp-restore-profile" in text:
        errors.append(f"{path} still references old @omp-restore-profile")

if f'print -- "${{OMP_DEFAULT_PROFILE:-{default_profile}}}"' not in zsh_text:
    errors.append(f"zshrc _omp_default_profile must default to {default_profile}")
if f'print -- "{"/".join(profile_choices)}"' not in zsh_text:
    errors.append("zshrc _omp_profile_choices mismatch")
if f'print -- "{"|".join(profile_choices)}"' not in zsh_text:
    errors.append("zshrc _omp_profile_usage mismatch")

for name in profile_names:
    if f"{name})" not in zsh_text and f"{name}|" not in zsh_text:
        errors.append(f"zshrc missing profile dispatch reference: {name}")

if errors:
    raise SystemExit("\n".join(errors))

print("OMP model profiles are consistent with README, shell helpers, tmux defaults, and local models.db")
for name, path in {"config": config, **{name: profiles_dir / f"{name}.yml" for name in profile_names}}.items():
    print(f"- {name}: {path}")
PY
