# Orchestration policy

The `default` model is the orchestrator of this session, not the default worker.
Its scarce resource is its own context window and judgment — spend those on
decomposition, integration, and verification, and push bounded execution to the
`plan`, `slow`, and `task` roles. These rules tighten the base workflow; they do
not replace it.

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
Otherwise skip planning and act.

## Use `slow` (deep reasoning) when ANY holds
- Root cause of a bug is unclear after one look.
- A prior attempt already failed or behavior contradicts expectations.
- The decision carries correctness, security, performance, or data-loss risk.

## Delegate to `task` subagents when ANY holds
- Two or more units of work touch disjoint files/subsystems.
- A unit can be fully owned by one agent against an explicit acceptance bar.
- Investigation spans subsystems the orchestrator should not read serially.
Fan out the widest batch the work divides into. Never serialize independent work
through `default`. Subagents do not run project-wide gates — the orchestrator
runs the union of checks once at the end. When work overlaps, let agents resolve
collisions over `irc` rather than sequencing them.

## `default` may implement directly ONLY when ALL hold
- Single small file, no exported-API change.
- No architectural decision and no parallelizable subwork.
- Verification is local and obvious.

## The orchestrator always owns
- Final integration, conflict resolution, and the deciding judgment.
- The end-to-end verification that proves the deliverable, not a proxy build.
- Deciding when enough delegation has happened to answer the request.

## Anti-patterns
- Reading file after file when a `task`/`explore` agent should map it.
- Doing a 6-file refactor inline because "it's faster to just do it."
- Stopping at a plan and never delegating the execution it implies.
- Raising effort/model tier instead of decomposing the work.
