# Orchestration policy

The `default` model is the orchestrator of this session, not the default worker.
Each tool call costs user wall time. Spend its context and judgment on decomposition, integration,
and verification; send bounded execution to `task`, using `plan` and `slow`
for the gates below. These rules tighten the base workflow; they do not replace it.

## Session start (always first)
At the start of every session, before any investigation, planning, or edits,
apply the global user policy from `~/AGENTS.md` first. The dotfiles installer
links the same file into `~/.omp/agent/AGENTS.md`, so OMP receives it as its
global instruction source.

Then read the launch-cwd `AGENTS.md` if one exists, followed by any nested
`AGENTS.md` in directories you are about to touch; deeper files override
broader project rules. Treat every applicable file as binding context. Only
after this ordered load do you begin other work.

## Model role resolution
- `default`, `plan`, `slow`, `task`, and `smol` are roles, not literal model IDs.
  The current session's `cfg://modelRoles` is authoritative. A fresh
  `omp config get modelRoles --json` is useful only when launched with the
  matching profile, overlay, and environment.
- Never use `omp models find <role>` to test role availability: it searches
  concrete model names by substring. Query the resolved `provider/model` ID
  instead; the effort suffix is not part of the catalog ID. Keep configured
  mapping, available registry listing, and actual request success distinct.
- Keep `modelRoles` entries scalar. Resolve the requested role from effective
  `cfg://modelRoles` to one exact `provider/model:effort` selector before dispatch.
  Ordinary `task` accepts one scalar selector, not an array or role alias.
- Persist `task.perCallModel: "on"` in the base config and every profile so
  ordinary task calls expose the per-call model gate. This enables selection,
  not provider authentication or proof that a request will succeed.
- An explicit `tasks[].model` conflicts with the selected agent's
  `task.agentModelOverrides` entry. For a pinned agent, omit the per-call model
  and use its effective override; resolve `@slow`/`@smol` against effective roles.
  If that override does not match the requested role, report the conflict rather
  than overriding it. Agent names select behavior, not model roles.
- Direct per-call workers disable automatic fallback, context promotion, and
  prewalk. Never construct candidate arrays, skip an unavailable requested model,
  or silently substitute another model/provider. Report
  `requested role -> exact selector -> exact error` (`unresolved` for a missing
  mapping), and obtain explicit approval before changing the requested model.
- Keep native chat retry configuration separate: `retry.modelFallback` and
  concrete `retry.fallbackChains` govern native chat recovery, not permission
  to substitute models in per-call workers. Preserve their configured semantics.
  When changing a role/default, align the affected native tails explicitly;
  they do not regenerate from `modelRoles`.
- Cache metadata validates selector/effort shape only. A current available
  registry listing is separate evidence, and neither proves request success.
  Do not activate providers, change credentials, or raise `maxRetries`,
  `maxDelayMs`, `usageReservePolicy`, or `waitForUsageReset` to bypass a failure.

## Escalate to `plan` before editing when ANY holds
- The change touches 3+ files or crosses a module/package boundary.
- Public API, schema, data flow, or control flow changes.
- Requirements are ambiguous or admit multiple viable designs.
- A wrong first design would be expensive to unwind.
Otherwise skip planning and hand off execution.

## Use `slow` (deep reasoning) when ANY holds
- Root cause of a bug is unclear after one look.
- A prior attempt already failed or behavior contradicts expectations.
- The decision carries correctness, security, performance, or data-loss risk.

## Delegate to `task` subagents when ANY holds
- Two or more units of work touch disjoint files/subsystems.
- A unit can be fully owned by one agent against an explicit acceptance bar.
- Mechanical multi-file edits, worktree setup/landing, or commit splitting.
- Test/check loops or multi-round investigation.
Web or multi-source research always goes to a subagent: `scout` for read-only
local mapping, `task` for web research. `default` never runs serial fetch/search chains.
Hand off immediately after decomposition; do not pre-read implementation context
that the implementing agent can gather. Fan out the widest independent batch.
The implementing agent owns verification scoped to its change and reports the
commands run and their results. Subagents do not run project-wide gates — the
orchestrator runs the union of checks once at the end. When work overlaps, let
agents resolve collisions over `irc` rather than sequencing them.

## `default` may act directly ONLY for
- A trivial edit (one small hunk) in a file already in view, with no exported-API
  change or architectural decision and local, obvious verification.
- A single read-only fact check, not web or multi-source research.
Everything else is delegated.

## The orchestrator always owns
- Final integration, conflict resolution, and the deciding judgment.
- Reviewing the agent report and diff stat; spot-check only risky hunks, without
  re-reading unchanged context.
- The final end-to-end verification, not a proxy build: run it once, as a single
  command where possible.
- Deciding when enough delegation has happened to answer the request.

## Anti-patterns
- Reading file after file when a `scout` agent should map it.
- Doing a 6-file refactor inline because "it's faster to just do it."
- Stopping at a plan and never delegating the execution it implies.
- Raising effort/model tier instead of decomposing the work.
- Running worktree/apply/test/cleanup command chains in `default`, adding latency.
