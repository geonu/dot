#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(pwd)}"
active_profile="${OMP_ACTIVE_PROFILE:-gpt-claude}"
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
role_keys = ["default", "smol", "slow", "vision", "plan", "commit", "task"]
profile_names = ["gpt", "grok", "claude", "claude-gpt", "gpt-claude", "grok-gpt"]
profile_choices = ["gpt", "grok", "claude", "claude-gpt", "gpt-claude", "grok-gpt", "config"]
known_choices = set(profile_choices)
default_profile = "gpt-claude"
agent_override_keys = ["reviewer", "sonic"]


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


def parse_agent_overrides(path: Path) -> dict[str, str]:
    overrides = {}
    in_task = in_overrides = False
    for raw in path.read_text().splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if not raw.startswith(" "):
            in_task = raw.rstrip() == "task:"
            in_overrides = False
            continue
        if in_task and raw.startswith("  ") and not raw.startswith("   "):
            in_overrides = raw.rstrip() == "  agentModelOverrides:"
            continue
        if in_overrides and raw.startswith("    ") and ": " in raw:
            key, value = raw.strip().split(": ", 1)
            overrides[key] = value.split(" #", 1)[0].strip().strip("\"'")
    return overrides


def tmux_option(text: str, option: str):
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

if not models_db.exists():
    raise SystemExit(f"models db missing: {models_db}; run OMP once or set PI_CODING_AGENT_DIR")

providers = {}
try:
    conn = sqlite3.connect(f"file:{models_db}?mode=ro", uri=True)
    for provider_id, models_json in conn.execute("select provider_id, models from model_cache"):
        base_id = provider_id.split(":", 1)[0]
        providers.setdefault(base_id, {}).update({m["id"]: m for m in json.loads(models_json)})
except (sqlite3.Error, json.JSONDecodeError) as exc:
    raise SystemExit(f"cannot read models db {models_db}: {exc}") from exc

errors = []


def check_selector(path: Path, label: str, selector: str) -> None:
    if selector.startswith("@"):
        if selector[1:] not in role_keys:
            errors.append(f"{path}: {label}: unknown role alias {selector}")
        return
    if "/" not in selector:
        errors.append(f"{path}: {label}: selector lacks provider: {selector}")
        return
    provider, rest = selector.split("/", 1)
    model, effort = rest.rsplit(":", 1) if ":" in rest else (rest, "")
    model_meta = providers.get(provider, {}).get(model)
    if model_meta is None:
        errors.append(f"{path}: {label}: unknown model {provider}/{model}")
        return
    thinking = model_meta.get("thinking") or {}
    efforts = thinking.get("efforts") or []
    if effort == "off" and thinking.get("requiresEffort"):
        errors.append(f"{path}: {label}: unsupported effort off for {provider}/{model}; model requires an effort; available={efforts}")
    elif effort and effort != "off" and effort not in efforts:
        errors.append(f"{path}: {label}: unsupported effort {effort} for {provider}/{model}; available={efforts}")


for name, path in {"config": config, **{name: profiles_dir / f"{name}.yml" for name in profile_names}}.items():
    # omp deep-merges config.yml under every --config overlay, so each profile must pin every override key.
    overrides = parse_agent_overrides(path)
    if sorted(overrides) != agent_override_keys:
        errors.append(f"{path}: task.agentModelOverrides keys must be {agent_override_keys}, got {sorted(overrides)}")
    for agent, selector in overrides.items():
        for candidate in selector.split(","):
            check_selector(path, f"agentModelOverrides.{agent}", candidate.strip())
    roles = parse_roles(path)
    if list(roles.keys()) != role_keys:
        errors.append(f"{path}: role keys mismatch: {list(roles.keys())}")
        continue
    for role, selector in roles.items():
        check_selector(path, role, selector)
config_roles = parse_roles(config)
if active_profile not in {"config", "default"}:
    active_path = profiles_dir / f"{active_profile}.yml"
    if not active_path.exists():
        errors.append(f"unknown active profile: {active_profile} ({active_path} missing)")
    elif config_roles != parse_roles(active_path):
        errors.append(f"omp/config.yml must match omp/profiles/{active_profile}.yml (active default profile)")
    elif parse_agent_overrides(config) != parse_agent_overrides(active_path):
        errors.append(f"omp/config.yml task.agentModelOverrides must match omp/profiles/{active_profile}.yml (active default profile)")

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

for path, text in [(tmux_conf, tmux_text), (save_script, save_text), (restore_script, restore_text)]:
    if "@omp-restore-profile" in text:
        errors.append(f"{path} still references old @omp-restore-profile")

if "@omp_profile" not in save_text:
    errors.append(f"{save_script} must recover @omp_profile before guessing from process args")

restore_case = re.search(r'case "\$profile" in(?P<body>.*?)esac', restore_text, re.S)
restore_body = restore_case.group("body") if restore_case else ""
profile_token = "|".join(sorted(map(re.escape, profile_choices), key=len, reverse=True))
accepted_restore = set(re.findall(rf'(?<![\w-])({profile_token})(?![\w-])', restore_body))
missing_restore = set(profile_choices) - accepted_restore
if missing_restore:
    errors.append(f"{restore_script} profile whitelist missing: {sorted(missing_restore)}")

for path, text in [(save_script, save_text), (restore_script, restore_text)]:
    if f"${{fb:-{default_profile}}}" in text:
        errors.append(f"{path} uses an unvalidated default-profile fallback")

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
