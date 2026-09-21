# Model profile capability registry

This document records the models currently selected by OMP profiles and the publicly reported benchmark evidence relevant to their routing. It is **not** a unified leaderboard: scores are comparable only when the benchmark, harness, effort setting, and agent scaffold match.

**Registry source:** `~/.omp/agent/models.db`. **Benchmark review:** 2026-09-07. Run `bin/omp-profile-check.sh` after a registry or profile change.

## Selected models

| Provider | Model | Confirmed registry capabilities | Profile use |
|---|---|---|---|
| OpenAI Codex | GPT-6 Astra | text/image, 1,050,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | `slow:high`, `vision:high`, `plan:xhigh` in `gpt`, `combo-gpt`, `combo-grok`, and `combo-claude`; `default:high`, `vision:high`, `plan:xhigh` in `combo-astra` |
| OpenAI Codex | GPT-5.6 Luna | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | `gpt` `smol`, `commit`; `combo-astra` `smol`, `commit` |
| OpenAI Codex | GPT-5.6 Terra | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | `gpt` `default`, `task`; GPT-side combo execution roles |
| OpenAI Codex | GPT-5.6 Sol | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | `designer` in GPT-side profiles and `combo-astra` |
| Anthropic | Claude Fable 5.1 | text/image, 1,000,000 context, 128,000 output, low–max effort | `claude` `default:medium`, `slow:high`, `plan:xhigh`; `combo-astra` `slow:high` |
| Anthropic | Claude Opus 5 | text/image, 1,000,000 context, 128,000 output, low–max effort | `combo-claude` `default:xhigh`; `claude` `vision:medium`; `combo-astra` `task:medium` |
| Anthropic | Claude Sonnet 5 | text/image, 1,000,000 context, 128,000 output, low–max effort | `claude` `designer`, `task` |
| Anthropic | Claude Haiku 4.5 | text/image, 200,000 context, 64,000 output, minimal–xhigh effort | Claude utility roles |
| xAI | Grok 4.6 | text/image, 500,000 context, 500,000 output, minimal–xhigh effort | `grok` all roles; `combo-grok` `default:medium` |

## Public benchmark evidence

All figures below are provider-published. They are decision context, not routing gates: the published agent results use different scaffolds and effort settings.

| Model | Coding evidence | Source |
| --- | --- | --- |
| GPT-6 Astra | Terminal-Bench 4.0: **57.9%** (GPT-5.6 Sol: **37.3%**). DeepSWE v1.1: **74.1%** (Sol: **70.8%**). OSWorld 2.0: **72.6%** (Sol: **65.7%**). MRCR v2 8-needle: **96.3%** at 512K–1M (Sol: **73.8%**). | [OpenAI, 2026-09-03](https://openai.com/index/gpt-6-astra/) · [The New Stack](https://thenewstack.io/openai-gpt6-astra-benchmarks/) |
| GPT-5.6 Sol / Terra / Luna | Terminal-Bench 2.1: **88.8% / 87.4% / 84.7%**. SWE-Bench Pro: **64.6% / 63.4% / 62.7%**. Sol Ultra reaches **91.9%** on Terminal-Bench 2.1, but is a multi-agent setting and is not comparable to a single-model role. | [OpenAI, 2026-07-09](https://openai.com/index/gpt-5-6/) |
| Claude Fable 5.1 | Terminal-Bench 4.0: **55.8%** (Fable 5: **42.0%**). Terminal-Bench-Science 0.1: **52.6%** (Fable 5: **24.7%**). CursorBench 3.2: **73.4%** at max effort. Terminal-Bench 2.1: **85.02%** (GPT-5.6 Sol: **85.77%**). LiveCodeBench: **90.52%** (#1). | [Anthropic, 2026-09-01](https://www.anthropic.com/claude-fable-and-mythos-5-1) · [Vals AI](https://www.vals.ai/models/anthropic_claude-fable-5-1) |
| Claude Opus 5 | Anthropic reports state-of-the-art results on Frontier-Bench v0.1 and GDPval-AA, and near-Fable-5 performance on CursorBench 3.2 at max effort. Its release page publishes charts rather than a machine-readable score table. | [Anthropic, 2026-07-24](https://www.anthropic.com/news/claude-opus-5) |
| Claude Sonnet 5 | Anthropic reports gains over Sonnet 4.6 across coding, agentic search, multimodal reasoning, and professional-task evaluations; use its system card for evaluation methodology rather than comparing its marketing-chart positions numerically. | [Anthropic, 2026-06-30](https://www.anthropic.com/news/claude-sonnet-5) · [system card](https://www.anthropic.com/claude-sonnet-5-system-card) |
| Grok 4.6 | Terminal-Bench 3.0: **26.0%**. DeepSWE v1.1: **65.9%** (Grok 4.6 High). | [xAI release, 2026-08-12](https://x.ai/news/grok-4-6) · [xAI model docs](https://docs.x.ai/developers/models/grok-4.6) |

### Interpretation

- GPT-6 Astra's published agent and long-context results support placing it in the high-cost `slow`, `vision`, and `plan` roles across GPT-side profiles: its text/image input and OSWorld 2.0 result (**72.6%** vs GPT-5.6 Sol's **65.7%**) support owning `vision`; its price is 2.5x GPT-5.6 Sol.
- Keep GPT-5.6 Sol for `designer` only, and Terra for `default` and `task` in GPT-only profiles; Luna remains the lightweight `smol`/`commit` tier.
- Claude Fable 5.1 owns the Claude-only profile's top roles and uses its separate Anthropic Fable quota bucket. Opus 5 is instead the formalized `combo-claude` default orchestrator at `xhigh` and the Claude-only vision model.
- Treat provider claims for Frontier-Bench, CursorBench, and other agent evaluations as non-comparable when the harness or effort level differs. A role change requires either a common-harness source or a local OMP task evaluation.

## Routing policy

- Route GPT-6 Astra to `slow:high`, `vision:high`, and `plan:xhigh` in every GPT-side profile; retain Sol `high` for `designer`, and Terra for `default` and `task` in GPT-only profiles.
- Use Claude Fable 5.1 for the Claude-only profile's `default`, `slow`, and `plan` roles. Keep Opus 5 as `combo-claude` `default:xhigh` and Claude-only `vision`.
- `combo-astra`는 Astra 오케스트레이터와 Opus 5 워커를 짝지어 가장 호출량이 많은 두 역할을 서로 다른 provider 쿼터 풀에 과금하고, `slow`는 Fable 5.1의 전용 Anthropic 버킷에 둔다. 다만 `default`의 Astra는 $10/$50, `task`의 Opus 5는 $5/$25로, 저비용 프로필의 Terra $2/$12와 Sonnet 5 $2/$10보다 비싸다.
- Keep Grok 4.6 as the `grok` and `combo-grok` default. Grok 4.20 variants are prohibited and must not be selected by current profiles.
- Do not route `anthropic/claude-mythos-5`: it is registry-visible but Anthropic trusted-access-only for cyber/bio.

## Verification

```sh
bin/omp-profile-check.sh
zsh -n zshrc bin/omp-save-panes bin/omp-restore-panes
bash -n bin/omp-profile-check.sh
```
