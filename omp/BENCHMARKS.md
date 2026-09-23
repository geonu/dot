# Model profile capability registry

This document records the models currently selected by OMP profiles and the publicly reported benchmark evidence relevant to their routing. It is **not** a unified leaderboard: scores are comparable only when the benchmark, harness, effort setting, and agent scaffold match.

**Registry source:** `~/.omp/agent/models.db`. **Benchmark review:** 2026-09-23. Run `bin/omp-profile-check.sh` after a registry or profile change.

## Selected models

| Provider | Model | Confirmed registry capabilities | Profile use |
|---|---|---|---|
| OpenAI Codex | GPT-6 Astra | text/image, registry `contextWindow` 272,000 of a 1,050,000-token model window, 128,000 output, low–max effort. The registry caps the window at OpenAI's long-context price threshold: once a single request exceeds 272,000 input tokens, the **entire** request reprices to $20/$75 with $2 cache reads. | `slow:high`, `vision:high`, `plan:xhigh` in `gpt`, `grok-gpt`, and `claude-gpt`; `default:high`, `vision:high`, `plan:xhigh` in `gpt-claude` |
| OpenAI Codex | GPT-6 Luna | text/image, registry `contextWindow` 272,000, `maxContextWindow` 872,000, 128,000 output, low–max effort (`off` accepted without `requiresEffort`) | `smol:low`, `commit:off` in `gpt`, `gpt-claude`, `claude-gpt`, and `grok-gpt` |
| OpenAI Codex | GPT-6 Sol | text/image, registry `contextWindow` 272,000 (the same long-context price-threshold cap as GPT-6 Astra), `maxContextWindow` 872,000, 128,000 output, low–max effort | `task:medium` in `claude-gpt`, `gpt`, and `grok-gpt` |
| OpenAI Codex | GPT-5.6 Luna (superseded baseline; unrouted) | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | — |
| OpenAI Codex | GPT-5.6 Terra | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | `gpt` `default:medium` only |
| OpenAI Codex | GPT-5.6 Sol (unrouted) | text/image, 1,000,000 context (872,000 usable via `maxContextWindow`), 128,000 output, low–max effort | — (its only role, `designer`, was removed upstream in OMP 18.1.5, 2026-09-03) |
| Anthropic | Claude Fable 5.1 | text/image, 1,000,000 context, 128,000 output, low–max effort | `claude` `default:medium`, `slow:high`, `plan:xhigh`; `gpt-claude` `slow:high` |
| Anthropic | Claude Opus 5.5 | text/image, 1,000,000 context, 128,000 output, low–max effort | `claude-gpt` `default:xhigh`; `claude` `vision:medium`; `gpt-claude` `task:medium` |
| Anthropic | Claude Sonnet 5 | text/image, 1,000,000 context, 128,000 output, low–max effort | `claude` `task` |
| Anthropic | Claude Haiku 4.5 | text/image, 200,000 context, 64,000 output, minimal–xhigh effort | `claude` `smol`, `commit` only |
| xAI | Grok 4.7 | text/image, 500,000 context, 500,000 output, minimal–xhigh effort | `grok` all roles; `grok-gpt` `default:medium` |

## Public benchmark evidence

All figures below are provider-published. They are decision context, not routing gates: the published agent results use different scaffolds and effort settings.

| Model | Coding evidence | Source |
| --- | --- | --- |
| GPT-6 Astra | DeepSWE v1.1: **74.1%** (GPT-5.6 Sol: **70.8%**). OSWorld 2.0: **72.6%** (Sol: **65.7%**). MRCR v2 8-needle: **96.3%** at 512K–1M (Sol: **73.8%**). Anthropic's cross-vendor table adds Terminal-Bench 4.0 **57.9%**, FrontierCode v1.1 (Main) **53.3%**, Terminal-Bench-Science 0.1 **64.6%**, AutomationBench **41.4%**, GDPval-AA v2.1 **1542 Elo**. | [OpenAI, 2026-09-03](https://openai.com/index/gpt-6-astra/) · [Anthropic, 2026-09-22](https://www.anthropic.com/claude-opus-5-5) |
| GPT-5.6 Sol / Terra / Luna | Terminal-Bench 2.1: **88.8% / 87.4% / 84.7%**. SWE-Bench Pro: **64.6% / 63.4% / 62.7%**. Sol Ultra reaches **91.9%** on Terminal-Bench 2.1, but is a multi-agent setting and is not comparable to a single-model role. | [OpenAI, 2026-07-09](https://openai.com/index/gpt-5-6/) |
| Claude Opus 5.5 | Terminal-Bench 4.0: **66.4%** (±2.6 SE). FrontierCode v1.1 (Main): **54.4%**. CursorBench 4.0: **57.8%**. GDPval-AA v2.1: **1846 Elo**. AutomationBench: **40.0%**. Terminal-Bench-Science 0.1: **58.7%**. | [Anthropic, 2026-09-22](https://www.anthropic.com/claude-opus-5-5) |
| Claude Fable 5.1 | Terminal-Bench 4.0: **55.8%**. FrontierCode v1.1 (Main): **50.3%**. CursorBench 4.0: **51.8%**. GDPval-AA v2.1: **1735 Elo**. Terminal-Bench-Science 0.1: **52.6%**. | [Anthropic, 2026-09-22](https://www.anthropic.com/claude-opus-5-5) |
| Claude Opus 5 (superseded baseline; unrouted) | Terminal-Bench 4.0: **52.3%**. FrontierCode v1.1 (Main): **48.0%**. CursorBench 4.0: **46.6%**. GDPval-AA v2.1: **1708 Elo**. | [Anthropic, 2026-09-22](https://www.anthropic.com/claude-opus-5-5) |
| Claude Sonnet 5 | Anthropic reports gains over Sonnet 4.6 across coding, agentic search, multimodal reasoning, and professional-task evaluations; use its system card for evaluation methodology rather than comparing its marketing-chart positions numerically. | [Anthropic, 2026-06-30](https://www.anthropic.com/news/claude-sonnet-5) · [system card](https://www.anthropic.com/claude-sonnet-5-system-card) |
| Grok 4.7 | DeepSWE v1.1: **71.0%** at high effort (superseded Grok 4.6: **65.9%**). Terminal-Bench 4.0: **38.0%** on xAI's Grok Build harness. CursorBench 4.0: **46.3%**. | [xAI, 2026-09-21](https://x.ai/news/grok-4-7) · [Artificial Analysis, 2026-09-21](https://artificialanalysis.ai/articles/benchmarking-grok-4-7) |
| GPT-6 Sol | Artificial Analysis Intelligence Index v4.3.2 (max): **48**, **$1.06** per task, 77M output tokens (GPT-5.6 Terra: **42**, **$1.40**, 120M; GPT-5.6 Sol: **47**, **$1.99**). Coding Agent Index **57** (GPT-5.6 Sol: **55**); Terminal-Bench 4.0 **43%** (**37%**); SWE-Atlas-QnA **58%** (**54%**). Regression: GDPval-AA v2.1 about **-100 Elo** vs GPT-5.6 Sol. $2/$10 input/output per 1M (GPT-5.6 Terra: $2/$12). | [GPT-6 Sol](https://artificialanalysis.ai/models/gpt-6-sol) · [GPT-5.6 Terra](https://artificialanalysis.ai/models/gpt-5-6-terra) · [GPT-5.6 Sol](https://artificialanalysis.ai/models/gpt-5-6-sol) (fetched 2026-09-23) · [Artificial Analysis, 2026-09-22](https://artificialanalysis.ai/articles/gpt-6-sol-and-luna-push-the-cost-efficiency-frontier) |
| GPT-6 Luna | Luna: Intelligence Index v4.3.2 **37** (Claude 4.5 Haiku Reasoning: **17**; non-reasoning: **15**); Coding Agent Index **41** (GPT-5.6 Luna: **43**); SWE-Atlas-QnA **44%** (**49%**); DeepSWE v1.1 **64%** (**66%**); AA-Omniscience hallucination **77%** (**93%**); output speed **154 tok/s** (Haiku 4.5 Reasoning: **109 tok/s**); $0.10/$0.50 input/output per 1M (**$0.20/$1.20**) and $0.07 per Intelligence Index task (**$0.18**). | [GPT-6 Luna](https://artificialanalysis.ai/models/gpt-6-luna) · [Claude 4.5 Haiku Reasoning](https://artificialanalysis.ai/models/claude-4-5-haiku-reasoning) · [Artificial Analysis, 2026-09-22](https://artificialanalysis.ai/articles/gpt-6-sol-and-luna-push-the-cost-efficiency-frontier) |

### Interpretation

- GPT-6 Astra retains `slow`, `vision`, and `plan`: it leads the published same-table Terminal-Bench-Science 0.1 result (**64.6%** vs Opus 5.5's **58.7%**) and AutomationBench (**41.4%** vs **40.0%**). `vision` also rests on Astra's own OSWorld 2.0 (**72.6%**) and MRCR v2 long-context results; Anthropic reports Opus 5.5 at **81.8%** on OSWorld 2.0 but marks it partial, so the two numbers are not comparable. The mixed profiles deliberately split provider quota pools.
- GPT-6 Luna is the lightweight `smol`/`commit` tier. The accepted tradeoff against GPT-5.6 Luna is SWE-Atlas-QnA **44%** vs **49%** and a 272K Codex registry window, for half the input/output price ($0.10/$0.50 vs $0.20/$1.20 per 1M) and lower AA-Omniscience hallucination (**77%** vs **93%**).
- GPT-6 Sol takes `task` from GPT-5.6 Terra on a common harness: Artificial Analysis Intelligence Index v4.3.2 **48** vs **42** at **$1.06** vs **$1.40** per task, with 36% fewer output tokens (77M vs 120M). Its GDPval-AA regression concerns document and presentation deliverables, not code-execution tasks.
- Claude Opus 5.5 replaces superseded Opus 5 in every role previously assigned to it. Claude Fable 5.1 keeps the Claude-only profile's top roles on its separate Anthropic Fable quota bucket.
- Grok 4.7 replaces superseded Grok 4.6 at the identical price.
- Opus 5.5 is approximately one day old: LMArena, Aider Polyglot, LiveBench, and SWE-rebench have no Opus 5.5 data. [Artificial Analysis Intelligence Index v4.3.2](https://artificialanalysis.ai/leaderboards/models) and [Vals AI](https://www.vals.ai/models/anthropic_claude-opus-5-5) are the only third-party same-harness sources so far. Anthropic cautions that benchmark margins are a less reliable guide at this capability level and that the real gap to Fable 5.1 is narrower than the scores suggest.
- Treat provider claims for FrontierCode, CursorBench, and other agent evaluations as non-comparable when the harness or effort level differs. A role change requires either a common-harness source or a local OMP task evaluation.

## Routing policy

- Route GPT-6 Astra to `slow:high`, `vision:high`, and `plan:xhigh` in every GPT-side profile; keep Terra for `default` in the GPT-only profile, and run `task` on GPT-6 Sol `medium` in `gpt`, `claude-gpt`, and `grok-gpt`. The `designer` role was removed upstream in OMP 18.1.5 (2026-09-03), so no profile routes it. Astra keeps those roles because it leads Terminal-Bench-Science 0.1 (**64.6%** vs Opus 5.5's **58.7%**) and AutomationBench (**41.4%** vs **40.0%**), while mixed profiles deliberately split provider quota pools.
- Use Claude Fable 5.1 for the Claude-only profile's `default`, `slow`, and `plan` roles on its separate Anthropic Fable quota bucket. Use Opus 5.5 wherever superseded Opus 5 was routed: `claude-gpt` `default:xhigh`, Claude-only `vision:medium`, and `gpt-claude` `task:medium`.
- `gpt-claude`는 Astra 오케스트레이터와 Opus 5.5 워커를 짝지어 가장 호출량이 많은 두 역할을 서로 다른 provider 쿼터 풀에 과금하고, `slow`는 Fable 5.1의 전용 Anthropic 버킷에 둔다. 다만 `default`의 Astra는 $10/$50, `task`의 Opus 5.5는 $4/$20로, 저비용 프로필 `task`의 GPT-6 Sol $2/$10·Sonnet 5 $2/$10보다 비싸다.
- Keep Grok 4.7 as the `grok` and `grok-gpt` default at the identical price to superseded Grok 4.6. Grok 4.20 variants are prohibited and must not be selected by current profiles.
- Do not route `anthropic/claude-mythos-5`: it is registry-visible but Anthropic trusted-access-only for cyber/bio.

## Verification

```sh
bin/omp-profile-check.sh
zsh -n zshrc bin/omp-save-panes bin/omp-restore-panes
bash -n bin/omp-profile-check.sh
```

`bin/omp-profile-check.sh` now normalizes versioned provider cache keys; the registry stores the Codex provider as `openai-codex:0.155.1`.
