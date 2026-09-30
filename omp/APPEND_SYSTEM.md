# Orchestration policy

The `default` model is the orchestrator of this session, not the default worker.
`default` runs the slowest, most expensive model; each tool call directly costs
user wall time. Spend its context and judgment on decomposition, integration,
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
