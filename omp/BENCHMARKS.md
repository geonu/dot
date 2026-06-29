# Model profile benchmarks — agentic & orchestrator fitness

Records how each model behind the OMP `modelRoles` performs on **agentic** work
(end-to-end tool use, terminal workflows, multi-file coding) and how well it
serves as the session **orchestrator** (the `default` role).

Two kinds of numbers live here, kept strictly separate:
- **Published** — third-party / vendor benchmark scores, cited. Facts.
- **Orchestrator fitness** — a derived 1–10 heuristic (mine, not a benchmark)
  scoring the model against what `APPEND_SYSTEM.md` says the orchestrator owns:
  decomposition, long-context integration, delegation discipline, end-to-end
  verification, judgment. Capability is weighted over raw cost because the
  orchestrator spends its own context/judgment, not execution throughput.

Last grounded: 2026-06-22 (GLM-5.2 added). Re-verify before trusting; model leaderboards move weekly.

---

## Published agentic benchmarks

| Model | OMP id | SWE-bench Verified | SWE-bench Pro | Terminal-Bench | Other |
|---|---|---|---|---|---|
| Claude Fable 5 | `anthropic/claude-fable-5` | **95.0%** | **80.3%** (vendor) | — | FrontierCode Diamond 29.3% |
| Claude Opus 4.8 | `anthropic/claude-opus-4-8` | 88.6% | 69.2% (vendor) / ~51.9% SEAL¹ | 74.6% (TB 2.1) | GDPval-AA 1890 Elo; native parallel-subagent, ~2.5× faster |
| GPT-5.5 | `openai-codex/gpt-5.5` | — | 58.6% | **82.7%** (TB 2.0, SOTA) | GDPval 84.9% — "strongest agentic coding model" (OpenAI) |
| GLM-5.2 (open) | `zai/glm-5.2` (unwired) | — | **62.1%** (vendor)² | 81.0% (TB 2.1)² | FrontierSWE 74.4%; MCP-Atlas 77.0; PostTrainBench 34.3; MIT/753B, 1M ctx, $1.40/$4.40 — ~14 Pro-pts/output-$ |
| Claude Sonnet 4.6 | `anthropic/claude-sonnet-4-6` | 79.6% | — | 65.4% (TB 2.0) | OSWorld-Verified 72.5% |
| GPT-5.4 (ref) | — | — | 57.7% / 59.1% SEAL-lead | — | Agentic tool use #8/115, avg 87.6 |
| GPT-5.4 nano | `openai-codex/gpt-5.4-nano` | — | 52.4% | — | edge/efficiency variant (vs GPT-5 mini 45.7%) |
| Claude Haiku 4.5 | `anthropic/claude-haiku-4-5` | — | budget tier | — | best cost-efficiency: 7.9 SWE-Pro pts / output-$ |

¹ Vendor SWE-bench Pro scores run 10–30 pts above the standardized Scale/SEAL
leaderboard; Opus's best *standardized* Claude run (Opus 4.6 thinking) was 51.9%.
Compare like-for-like (vendor-vs-vendor, SEAL-vs-SEAL) only.

² GLM-5.2 scores are z.ai vendor-scaffold (published 2026-06-16); there is **no**
Scale/SEAL standardized entry yet, so they are *not* comparable to SEAL columns —
same caveat as Opus's 69.2%. z.ai's launch chart cites Opus 4.8 at 85.0 on TB 2.1,
conflicting with the 74.6% standardized figure above; treat cross-vendor
Terminal-Bench comparisons cautiously. GLM-5.1 (predecessor) led open-weights Pro
at 58.4%; GLM-5.2's 62.1% now edges GPT-5.5's 58.6% vendor number.

> ⚠️ **Fable 5 availability:** GA 2026-06-09, then **suspended 2026-06-12** under a
> US export-control directive (cannot gate access by nationality in real time, so
> offline for all). Treat `fable-codex` profile's `default`/`plan` as unavailable
> until lifted; fall back to `combo-claude`. (Local memory's "free window expires
> 2026-06-22" is the credit window, not the availability state.)
> Per Scale/Anthropic (2026-06-18), access is expected to return for US-based
> users around 2026-07-01; Mythos 5 is suspended alongside Fable 5.

---
## Effort / reasoning levels

`modelRoles` use `model:effort` syntax. **Effort** = the reasoning/thinking
budget a model spends before acting, ordered low→high:

`off` < `minimal` < `low` < `medium` < `high` < `xhigh`

| Effort | Reasoning budget | Used for |
|---|---|---|
| `off` | none — one-shot, no extended thinking | `commit` (mechanical message gen) |
| `minimal` | trivial | `smol` utility lookups |
| `low` | light | `fable-codex` `default` (Fable) — judgment is cheap for it; fan-out carries the load, keeps orchestrator latency/context low |
| `medium` | moderate | Opus 4.8 / GPT-5.5 `default` (active + Claude/GPT profiles); mid-weight `task`/`vision` |
| `high` | deep | `slow`, `task`, `designer`, `vision` heavy fan-out |
| `xhigh` | maximum | `plan` (architecture) only |

`config.yml` also sets `defaultThinkingLevel: auto` — the harness picks within a
role's budget rather than pinning it.

### Role × profile matrix (`model:effort`)

Models: **O4.8**=Opus 4.8 · **F5**=Fable 5 · **G5.5**=GPT-5.5 · **GLM5.2**=GLM-5.2 · **S4.6**=Sonnet 4.6 · **H4.5**=Haiku 4.5 · **N**=GPT-5.4 nano

| Role | config (active) | claude | combo-claude | combo-gpt | gpt | gpt-glm | fable-codex |
|---|---|---|---|---|---|---|---|
| `default` | G5.5:xhigh | O4.8:medium | O4.8:medium | G5.5:medium | G5.5:medium | G5.5:medium | F5:low |
| `plan` | G5.5:xhigh | O4.8:high | G5.5:xhigh | G5.5:xhigh | G5.5:xhigh | G5.5:xhigh | F5:high |
| `slow` | G5.5:high | O4.8:high | G5.5:high | G5.5:high | G5.5:high | GLM5.2:xhigh | F5:high |
| `task` | G5.5:high | S4.6:medium | G5.5:high | G5.5:medium | G5.5:medium | G5.5:medium | G5.5:xhigh |
| `designer` | G5.5:high | S4.6:high | G5.5:high | G5.5:high | G5.5:high | G5.5:high | G5.5:high |
| `vision` | G5.5:high | O4.8:medium | G5.5:high | G5.5:high | G5.5:high | G5.5:high | F5:medium |
| `smol` | H4.5:minimal | H4.5:minimal | H4.5:minimal | H4.5:minimal | N:low | N:low | H4.5:minimal |
| `commit` | H4.5:off | H4.5:off | H4.5:off | H4.5:off | N:off | N:off | H4.5:off |

**Effort-design notes**
- Orchestrator runs at `low`/`medium`, not `high`: the policy spends Opus/GPT
  judgment on *decomposition + integration*, then pushes deep reasoning down to
  `plan`/`slow`/`task` workers — matching "raise fan-out, not the tier."
- `plan` is the only `xhigh` slot (except `fable-codex`'s `task`, which buys
  max-effort GPT-5.5 execution because Fable owns planning).
- Utility roles (`smol`/`commit`) stay at `minimal`/`off` — no reasoning spend on
  lookups or commit messages.

---

## Orchestrator fitness (derived, 1–10)

Scored on the `default`-role mandate, not raw coding throughput.

| Model | Decompose / judgment | Long-context integration | Delegation & tool routing | Verification rigor | **Fitness** | Verdict as orchestrator |
|---|---|---|---|---|---|---|
| Claude Opus 4.8 | 9 | 9 | 9 (native parallel-subagent) | 9 | **9.0** | Best all-round orchestrator. Highest standardized judgment + purpose-built fan-out. The default for a reason. |
| Claude Fable 5 | 10 | 10 | 9 | 9 | **9.5*** | Highest ceiling, but `*` = suspended + $50/Mtok. Use only when available and the task justifies the spend. |
| GPT-5.5 | 8 | 8 | 9 (SOTA Terminal-Bench, token-efficient) | 8 | **8.5** | Strongest tool/terminal coordinator; best when GPT should own long-running context. Slightly behind Opus on deep multi-file judgment. |
| GLM-5.2 (open) | 7 | 8 (1M ctx, long-horizon-trained) | 8 (MCP-Atlas 77.0, near Opus) | 7 | **7.5** | Strongest open-weights model; viable budget orchestrator at ~1/6 the cost. Vendor-heavy scores, open-weight hosting, and slightly softer hard-decomposition judgment keep it below Opus/GPT-5.5 for `default`. Ideal cheap `task`/`slow` worker; wired into `gpt-glm`. |
| Claude Sonnet 4.6 | 7 | 7 | 7 | 7 | **7.0** | Capable worker, not an orchestrator. Fine as `task` fan-out; under-powers `default` on hard decomposition. |
| GPT-5.4 nano | 3 | 3 | 4 | 3 | **3.0** | Utility only (`smol`). Never orchestrate. |
| Claude Haiku 4.5 | 3 | 2 | 3 | 3 | **2.5** | Cheap utility (`smol`/`commit`). Never orchestrate. |

---

## Per-profile orchestrator (`default` role)

| Profile | `default` (orchestrator) | Fitness | Notes |
|---|---|---|---|
| `config.yml` (active) | GPT-5.5 `:xhigh` | **8.5** | Claude-free active config. GPT orchestrates at max budget; profile overlays remain available via `Ctrl-a R`. |
| `claude.yml` | Opus 4.8 `:medium` | **9.0** | All-Anthropic; protects OpenAI quota. `task` drops to Sonnet 4.6. |
| `combo-claude.yml` | Opus 4.8 `:medium` | **9.0** | Claude owns context; GPT-5.5 reserved for burst reasoning / design. |
| `combo-gpt.yml` | GPT-5.5 `:medium` | **8.5** | GPT owns long-running context; Haiku for cheap utility. |
| `gpt.yml` | GPT-5.5 `:medium` | **8.5** | All-OpenAI; used when Anthropic quota is gone. |
| `gpt-glm.yml` | GPT-5.5 `:medium` | **8.5** | Claude-free backup; GPT owns review-heavy `task` fan-out while GLM-5.2 supplies the `slow` alternate deep-reasoning path. |
| `fable-codex.yml` | Fable 5 `:low` | **9.5*** | Highest ceiling but **suspended** — see warning above; prefer `combo-claude` meanwhile. |

**Takeaways**
- Every profile orchestrates with a top-tier model (Opus 4.8 / GPT-5.5 / Fable 5),
  fitness ≥ 8.5 — including `gpt-glm`, which keeps GPT-5.5 in `default`.
- Opus 4.8's native parallel-subagent support is the differentiator for the
  `default`-as-orchestrator design: it fans out without paying a context tax.
- GPT-5.5 leads agentic *terminal* execution (82.7% TB 2.0); that strength is
  exploited by routing `task`/`slow` fan-out to it even in Claude-primary profiles.
- Never let a `smol`/`commit` model (Haiku 4.5, GPT-5.4 nano) reach the `default`
  slot — fitness ≤ 3.
- **GLM-5.2 (2026-06-16) is a new open-weights, frontier-adjacent contender** —
  vendor 62.1% SWE-bench Pro (> GPT-5.5's 58.6) and MCP-Atlas 77.0 at $1.40/$4.40
  per M (~1/6 GPT-5.5, ~14 Pro-pts/output-$, beating Haiku's 7.9 on cost-efficiency).
  Wired into `gpt-glm` as an alternate `slow` path; keep review-heavy `task` on
  GPT-5.5 because DeepSWE/tool orchestration still favors GPT.
  Keep it off `default` on closed-frontier profiles for now: scores are vendor-only
  (no SEAL) and the Z.ai API carries China data-residency considerations —
  self-host or a non-Z.ai provider (FriendliAI/Novita) sidesteps that.

## Sources
- Claude Opus 4.8: vellum.ai/blog/claude-opus-4-8-benchmarks-explained · llm-stats.com/blog/research/claude-opus-4-8-launch
- Fable 5 + tiers/suspension: morphllm.com/claude-benchmarks
- Sonnet 4.6: cosmicjs.com/blog/claude-sonnet-46-vs-sonnet-45-a-real-world-comparison
- GPT-5.5: openai.com/index/introducing-gpt-5-5 · interestingengineering.com/ai-robotics/opanai-gpt-5-5-agentic-coding-gains
- GPT-5.4 / nano: datacamp.com/blog/gpt-5-4-mini-nano · morphllm.com/swe-bench-pro
- SWE-bench Pro standardized vs vendor: morphllm.com/swe-bench-pro · labs.scale.com/leaderboard/swe_bench_pro_public
- GLM-5.2: huggingface.co/blog/zai-org/glm-52-blog · docs.z.ai/guides/llm/glm-5.2 · llm-stats.com/models/glm-5.2 · venturebeat.com (z-ai-glm-5-2-beats-gpt-5-5) · arxiv.org/abs/2602.15763
- GLM standardized vs vendor + open-weights leader (GLM-5.1 58.4): morphllm.com/swe-bench-pro (2026-06-18)