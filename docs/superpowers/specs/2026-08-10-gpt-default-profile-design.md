# GPT Default Profile Design

## Goal

Make the active OMP configuration use the repository's GPT-only model roles, then commit and push the existing local configuration changes.

## Scope

- Replace `omp/config.yml`'s `modelRoles` mapping with the mapping in `omp/profiles/gpt.yml`.
- Preserve the pending edits to `alacritty/alacritty.toml` and `claude/settings.json` unchanged.
- Delete the empty generated `omp/config.yml.lock`; do not commit it.
- Validate YAML and JSON syntax and ensure the active model-role mapping equals the GPT profile before committing and pushing `main` to `origin`.

## Design

The active `omp/config.yml` remains the runtime source of truth. Its `modelRoles` mapping is switched wholesale to the vetted GPT-only profile so every role—default, planning, delegation, vision, and commit—uses the intended OpenAI Codex model tier. This avoids a mixed-provider runtime caused by changing only the default role.

The available profile files, including Grok and Claude variants, remain unchanged. They continue to support later profile selection; only the currently active configuration defaults to GPT.

No indirection, symlink, or profile-loader mechanism is introduced. The current direct configuration model is retained.

## Error Handling and Verification

The change is rejected if YAML or JSON parsing fails, if the active roles differ from `profiles/gpt.yml`, or if the working tree contains unexpected staged content. The commit is pushed only after those checks pass.
