# GPT Default Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the active OMP configuration default to GPT while retaining every selectable model profile, then commit and push the pending local changes.

**Architecture:** `omp/config.yml` remains the runtime configuration file. Replace only its `modelRoles` mapping with the values from `omp/profiles/gpt.yml`; leave all other profile files unchanged. Preserve the existing pending Alacritty and Claude settings edits, remove the empty generated lock file, and commit the resulting working tree.

**Tech Stack:** YAML, TOML, JSON, Git, Ruby standard library, Python standard library.

## Global Constraints

- Leave every file in `omp/profiles/` unchanged so alternative model profiles remain selectable.
- Make `omp/config.yml`'s `modelRoles` mapping exactly equal to `omp/profiles/gpt.yml`'s mapping.
- Preserve the existing edits to `alacritty/alacritty.toml` and `claude/settings.json` unchanged.
- Delete and do not commit the empty generated `omp/config.yml.lock`.
- Push the validated commit on `main` to `origin`.

---

### Task 1: Activate GPT model roles

**Files:**
- Modify: `omp/config.yml:5-13`
- Reference: `omp/profiles/gpt.yml:3-11`

**Interfaces:**
- Consumes: `modelRoles` mapping in `omp/profiles/gpt.yml`.
- Produces: active `omp/config.yml` mapping with GPT role assignments.

- [ ] **Step 1: Replace active role assignments**

Set `omp/config.yml`'s `modelRoles` values to:

```yaml
modelRoles:
  default: openai-codex/gpt-5.6-terra:medium
  smol: openai-codex/gpt-5.6-luna:low
  slow: openai-codex/gpt-5.6-sol:high
  vision: openai-codex/gpt-5.6-sol:high
  plan: openai-codex/gpt-5.6-sol:xhigh
  designer: openai-codex/gpt-5.6-sol:high
  commit: openai-codex/gpt-5.6-luna:off
  task: openai-codex/gpt-5.6-terra:medium
```

- [ ] **Step 2: Validate active configuration**

Run:

```bash
ruby -ryaml -e 'active = YAML.load_file("omp/config.yml"); profile = YAML.load_file("omp/profiles/gpt.yml"); abort("active modelRoles do not match GPT profile") unless active.fetch("modelRoles") == profile.fetch("modelRoles"); puts active.fetch("modelRoles").fetch("default")'
```

Expected: `openai-codex/gpt-5.6-terra:medium`.

### Task 2: Commit organized working tree

**Files:**
- Preserve: `alacritty/alacritty.toml`
- Preserve: `claude/settings.json`
- Delete: `omp/config.yml.lock`
- Create: `docs/superpowers/specs/2026-08-10-gpt-default-profile-design.md`
- Create: `docs/superpowers/plans/2026-08-10-gpt-default-profile.md`

**Interfaces:**
- Consumes: validated active GPT roles and existing local edits.
- Produces: one commit on `main`, pushed to `origin/main`.

- [ ] **Step 1: Remove generated lock file**

Run:

```bash
rm omp/config.yml.lock
```

- [ ] **Step 2: Validate structured files**

Run:

```bash
python3 -m json.tool claude/settings.json >/dev/null
python3 -c 'import tomllib; tomllib.load(open("alacritty/alacritty.toml", "rb")); print("TOML valid")'
```

Expected: `JSON valid` and `TOML valid`.

- [ ] **Step 3: Stage and commit intended files**

Run:

```bash
git add alacritty/alacritty.toml claude/settings.json omp/config.yml docs/superpowers/specs/2026-08-10-gpt-default-profile-design.md docs/superpowers/plans/2026-08-10-gpt-default-profile.md
git commit -m "chore(omp): default active profile to gpt"
```

Expected: one commit containing only the listed files.

- [ ] **Step 4: Push the commit**

Run:

```bash
git push origin main
```

Expected: remote `origin/main` advances to the created commit.
