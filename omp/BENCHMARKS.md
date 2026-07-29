# Model profile capability registry

This document records the models currently selected by OMP profiles. It is not a benchmark leaderboard: model capability and benchmark claims require a separate source review before they are used for routing.

**Registry source:** `~/.omp/agent/models.db`. Run `bin/omp-profile-check.sh` after a registry or profile change.

## Selected models

| Provider | Model | Confirmed registry capabilities | Profile use |
|---|---|---|---|
| OpenAI Codex | GPT-5.6 Luna | text/image, 272K context, 128K output, low–max effort | `smol`, `commit` |
| OpenAI Codex | GPT-5.6 Terra | text/image, 272K context, 128K output, low–max effort | `default`, `task` |
| OpenAI Codex | GPT-5.6 Sol | text/image, 272K context, 128K output, low–max effort | `slow`, `vision`, `plan`, `designer` |
| Anthropic | Claude Opus 5 | text/image, 1M context, 128K output, low–max effort | Claude `default`, `slow`, `vision`, `plan` |
| Anthropic | Claude Sonnet 5 | text/image, 1M context, 128K output, low–max effort | Claude `designer`, `task` |
| Anthropic | Claude Haiku 4.5 | text/image, 200K context, 64K output, minimal–xhigh effort | Claude utility roles |
| Z.ai | GLM-5.2 | text, 1M context, 128K output, high/max effort | `gpt-glm` `commit`, `task` |
| Kimi Code | K3 | text/image, 1M context, 128K output, minimal–high effort | `kimi` all roles |
| xAI | Grok 4.5 | text/image, 500K context, 500K output | `combo-grok` `default` |

## Routing policy

- Use Luna → Terra → Sol as the OpenAI lightweight → execution → high-reasoning tiers.
- Keep Terra in `task`; Luna is not a coding-worker replacement.
- Keep Sol's `xhigh` effort exclusive to `plan`; use `high` for its other high-risk roles.
- Keep GLM-5.2 out of vision and general orchestration because the registered model is text-only and supports only high/max effort.
- Keep Grok 4.5 as the `combo-grok` default. A model identifier with a larger-looking number is not automatically a newer flagship.
- Keep K3 `plan:high` and `commit:minimal`: its registry does not expose `xhigh` or `off`.

## Verification

```sh
bin/omp-profile-check.sh
zsh -n zshrc bin/omp-save-panes bin/omp-restore-panes
bash -n bin/omp-profile-check.sh
```
