#!/usr/bin/env zsh
# Deterministic profile gate, exact-selector, and registry-evidence regressions.

emulate -R zsh
set -eo pipefail

repo_root="${0:A:h:h}"
python3 - "$repo_root" <<'PY'
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

repo = Path(sys.argv[1])
roles = {
    "default": "fixture/large:medium",
    "smol": "fixture/small:low",
    "slow": "fixture/large:high",
    "vision": "fixture/large:high",
    "plan": "fixture/large:high",
    "commit": "fixture/small:off",
    "task": "fixture/large:medium",
}
profiles = ["gpt", "grok", "claude", "claude-gpt", "gpt-claude", "grok-gpt"]


def config_text(role_items=None, gate='"on"'):
    return (
        "modelRoles:\n"
        + "".join(f"  {key}: {value}\n" for key, value in (roles.items() if role_items is None else role_items))
        + f"task:\n  perCallModel: {gate}\n"
        + '  agentModelOverrides:\n    reviewer: "@slow"\n    sonic: "@smol"\n'
    )


with tempfile.TemporaryDirectory(prefix="omp-profile-check-drift.") as directory:
    work = Path(directory)
    (work / "omp/profiles").mkdir(parents=True)
    (work / "bin").mkdir()
    # Keep integration inputs real; assertions below exercise checker behavior, not source wording.
    for relative in [
        "omp/README.md", "tmux.conf", "zshrc", "bin/omp-profile-check.sh",
        "bin/omp-save-panes", "bin/omp-restore-panes",
    ]:
        shutil.copyfile(repo / relative, work / relative)
    paths = [work / "omp/config.yml"] + [work / f"omp/profiles/{name}.yml" for name in profiles]
    base, gpt, grok, claude = paths[:4]
    models_dir = work / "models"
    models_dir.mkdir()
    metadata = {
        "fixture:0.155.1": [
            {"id": "small", "thinking": {"efforts": ["low", "medium"]}},
            {"id": "large", "thinking": {"efforts": ["medium", "high"]}},
            {"id": "required", "thinking": {"efforts": ["low"], "requiresEffort": True}},
        ],
        "absent-provider": [{"id": "cached", "thinking": {"efforts": ["high"]}}],
    }
    with sqlite3.connect(models_dir / "models.db") as conn:
        conn.execute("create table model_cache (provider_id text, models text)")
        conn.executemany(
            "insert into model_cache (provider_id, models) values (?, ?)",
            [(provider, json.dumps(models)) for provider, models in metadata.items()],
        )
    catalog = [
        {"provider": provider.split(":", 1)[0], "id": model["id"]}
        for provider, models in metadata.items() for model in models
    ]
    snapshot = work / "available.json"
    snapshot.write_text(json.dumps({"models": catalog}))
    env = dict(os.environ)
    env.pop("OMP_ACTIVE_PROFILE", None)
    env.pop("OMP_AVAILABLE_MODELS_JSON", None)
    env["PI_CODING_AGENT_DIR"] = str(models_dir)

    def reset():
        for path in paths:
            path.write_text(config_text())

    def replace(path, old, new):
        text = path.read_text()
        assert text.count(old) == 1, (path, old)
        path.write_text(text.replace(old, new))

    def check(expected=None, **overrides):
        result = subprocess.run(
            ["bash", str(work / "bin/omp-profile-check.sh"), str(work)],
            env=env | overrides, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        if expected is None:
            assert result.returncode == 0, result.stdout
        else:
            assert result.returncode != 0, f"expected failure containing {expected!r}: {result.stdout}"
            assert expected in result.stdout, result.stdout
        return result.stdout

    reset()
    output = check()
    assert "Cache-only check: runtime availability and model requests were not checked" in output
    output = check(OMP_AVAILABLE_MODELS_JSON=str(snapshot))
    assert "no model request was checked" in output

    # All seven files must pin the quoted string; inherited or boolean gates do not count.
    for path in paths:
        for gate in [None, "off", '"off"', "eval", '"eval"', "true", "false", "on"]:
            reset()
            replacement = "" if gate is None else f"  perCallModel: {gate}\n"
            replace(path, '  perCallModel: "on"\n', replacement)
            check(f'{path}: task.perCallModel must be the quoted string "on"')
    reset()
    claude.write_text(config_text(gate="'on'"))
    check()

    # Required keys are a set, not a serialization order.
    reset()
    gpt.write_text(config_text(role_items=reversed(list(roles.items()))))
    check(OMP_ACTIVE_PROFILE="gpt")
    replace(gpt, "  vision: fixture/large:high\n", "")
    check("role keys must be")
    reset()
    replace(claude, '    sonic: "@smol"\n', "")
    check("task.agentModelOverrides keys must be")

    # The GPT default and explicit equality assertions reject role and override drift.
    reset()
    replace(base, "  default: fixture/large:medium", "  default: fixture/large:high")
    check("OMP_ACTIVE_PROFILE equality assertion", OMP_ACTIVE_PROFILE="gpt")
    check("OMP_ACTIVE_PROFILE equality assertion")
    check(OMP_ACTIVE_PROFILE="config")
    reset()
    replace(base, '    sonic: "@smol"', '    sonic: "@slow"')
    check("task.agentModelOverrides must match", OMP_ACTIVE_PROFILE="gpt")
    reset()
    check("unknown OMP_ACTIVE_PROFILE", OMP_ACTIVE_PROFILE="not-a-profile")

    # Cache evidence never proves the provider or exact model is currently registered.
    reset()
    replace(claude, "  default: fixture/large:medium", "  default: absent-provider/cached:high")
    check()
    snapshot.write_text(json.dumps({"models": [m for m in catalog if m["provider"] == "fixture"]}))
    check("provider absent-provider is absent from the available registry snapshot", OMP_AVAILABLE_MODELS_JSON=str(snapshot))
    reset()
    snapshot.write_text(json.dumps({"models": [m for m in catalog if m["id"] != "large"]}))
    check("cached model fixture/large is not available", OMP_AVAILABLE_MODELS_JSON=str(snapshot))
    snapshot.write_text(json.dumps({"models": []}))
    check("provider fixture is absent", OMP_AVAILABLE_MODELS_JSON=str(snapshot))

    # Exact selectors and effort metadata remain strict with or without availability evidence.
    reset()
    replace(grok, "  default: fixture/large:medium", "  default: fixture/unknown:medium")
    check("unknown model fixture/unknown in cached metadata")
    snapshot.write_text(json.dumps({"models": catalog + [{"provider": "fixture", "id": "unknown"}]}))
    check("unknown model fixture/unknown in cached metadata", OMP_AVAILABLE_MODELS_JSON=str(snapshot))
    reset()
    replace(grok, "  default: fixture/large:medium", "  default: fixture:0.155.1/large:medium")
    check("unknown model fixture:0.155.1/large in cached metadata")
    reset()
    replace(grok, "  default: fixture/large:medium", "  default: large:medium")
    check("selector lacks provider")
    reset()
    replace(grok, "  default: fixture/large:medium", "  default: fixture/large:xhigh")
    check("unsupported effort xhigh for fixture/large")
    snapshot.write_text(json.dumps({"models": catalog}))
    check("unsupported effort xhigh for fixture/large", OMP_AVAILABLE_MODELS_JSON=str(snapshot))
    reset()
    replace(grok, "  commit: fixture/small:off", "  commit: fixture/required:off")
    output = check("unsupported effort off for fixture/required")
    assert "requires an effort" in output
    replace(grok, "fixture/required:off", "fixture/required:low")
    check()

    reset()
    check("cannot read OMP_AVAILABLE_MODELS_JSON snapshot", OMP_AVAILABLE_MODELS_JSON=str(work / "missing.json"))
    for payload in ["{", "[]", '{"models": {}}', '{"models": [{"provider": "fixture"}]}', '{"models": [{"provider": true, "id": "large"}]}']:
        snapshot.write_text(payload)
        check("cannot read OMP_AVAILABLE_MODELS_JSON snapshot", OMP_AVAILABLE_MODELS_JSON=str(snapshot))

print("ok: profile gates, unordered roles, exact metadata, and optional availability snapshot")
PY
