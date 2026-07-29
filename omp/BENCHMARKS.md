# Model profile capability registry

This document records the models currently selected by OMP profiles and the publicly reported benchmark evidence relevant to their routing. It is **not** a unified leaderboard: scores are comparable only when the benchmark, harness, effort setting, and agent scaffold match.

**Registry source:** `~/.omp/agent/models.db`. **Benchmark review:** 2026-07-29. Run `bin/omp-profile-check.sh` after a registry or profile change.

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

## Public benchmark evidence

All figures below are provider-published. They are decision context, not routing gates: the published agent results use different scaffolds and effort settings.

| Model | Coding evidence | Source |
| --- | --- | --- |
| GPT-5.6 Sol / Terra / Luna | Terminal-Bench 2.1: **88.8% / 87.4% / 84.7%**. SWE-Bench Pro: **64.6% / 63.4% / 62.7%**. Sol Ultra reaches **91.9%** on Terminal-Bench 2.1, but is a multi-agent setting and is not comparable to a single-model role. | [OpenAI, 2026-07-09](https://openai.com/index/gpt-5-6/) |
| Claude Opus 5 | Anthropic reports state-of-the-art results on Frontier-Bench v0.1 and GDPval-AA, and near-Fable-5 performance on CursorBench 3.2 at max effort. Its release page publishes charts rather than a machine-readable score table. | [Anthropic, 2026-07-24](https://www.anthropic.com/news/claude-opus-5) |
| Claude Sonnet 5 | Anthropic reports gains over Sonnet 4.6 across coding, agentic search, multimodal reasoning, and professional-task evaluations; use its system card for evaluation methodology rather than comparing its marketing-chart positions numerically. | [Anthropic, 2026-06-30](https://www.anthropic.com/news/claude-sonnet-5) · [system card](https://www.anthropic.com/claude-sonnet-5-system-card) |
| GLM-5.2 | SWE-Bench Pro: **58.4%**. Terminal-Bench 2.1: **81.0%**. Z.ai also reports that the model trails Opus 4.8 by 1 point on FrontierSWE. | [Z.ai developer docs](https://docs.z.ai/guides/llm/glm-5.2) |
| Kimi K3 | Kimi positions K3 below GPT-5.6 Sol and Claude Fable 5 overall, while calling its coding, knowledge-work, and reasoning results frontier-level. The published comparison is image-only, so no numeric score is recorded here without an independently parseable result table. | [Kimi technical blog](https://www.kimi.com/blog/kimi-k3) |
| Grok 4.5 | SWE-Bench Pro resolve rate: **64.7%**. Terminal-Bench 2.1: **83.3%**. xAI notes that competitor figures are gathered from their providers, so they remain cross-harness comparisons. | [xAI, 2026-07](https://x.ai/news/grok-4-5) |

### Interpretation

- Use the GPT-5.6 tiers for the current Luna → Terra → Sol routing: their single-model results are published on the same two coding evaluations, and their capability/cost split is deliberate.
- Retain K3's `plan:high` and `commit:minimal` settings. K3's public material supports its frontier positioning but not a score-based role change.
- Treat provider claims for Frontier-Bench, CursorBench, and other agent evaluations as non-comparable when the harness or effort level differs. A role change requires either a common-harness source or a local OMP task evaluation.

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
