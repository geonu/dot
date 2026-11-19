# Orchestration policy

The main session owns scoping, judgment, integration, and verification. Start
inline and delegate only when bounded work benefits from it. These rules
supplement the base workflow; they do not replace its delegation gates.

## Session start (always first)
Apply the global user policy, `~/AGENTS.md`, before investigation, planning,
or edits. The installer links the same policy into `~/.omp/agent/AGENTS.md`.
Then read applicable project policies from broadest ancestor through the
launch cwd and nested `AGENTS.md` files for the target paths. Recheck that
scope in the assigned worktree before editing; more specific project
instructions apply within their subtree.

## Model routing

Follow [the always-apply rules](RULES.md) (installed:
`~/.dotfiles/omp/RULES.md`) for exact effective selectors, pin conflicts, and
failure reporting. A role name and an agent name are not model selectors.
For catalog checks, runtime diagnostics, and native chat retry configuration,
see [Model routing diagnostics](README.md#model-routing-diagnostics)
(installed: `~/.dotfiles/omp/README.md`). When editing, use the assigned
worktree copies of these references.

## Scope inline, then decide how to execute

Start with an inline search or read to identify the affected paths, shared
contracts, risks, and acceptance criteria. Handle a small direct change or
fact check yourself; a single slice is not a reason to delegate.

- **Design (`plan`):** Before editing, settle design questions when requirements
  allow meaningful alternatives, a public contract or control flow changes, or
  a wrong design would be costly to undo. File count or a module boundary
  prompts a scope check, not an automatic model escalation. Main owns the
  overall plan; use `plan` for a bounded design question only when delegation
  is warranted.
- **Diagnosis (`slow`):** Use deeper reasoning when focused inspection leaves
  the cause unclear, evidence contradicts a prior attempt or expectation, or
  a decision risks correctness, security, performance, or data loss. Use
  `slow` for a bounded diagnostic question only when delegation is warranted.
  Do not escalate model effort in place of scoping or gathering evidence.
- **Execution (`task`):** After inline scoping, delegate when at least two
  genuinely independent, bounded slices each justify the handoff, or an
  independent read set would overwhelm the main context. Do not delegate a
  lone slice. Batch independent work; serialize true dependencies only.
  Map shared contracts first and give each worker clear ownership and
  acceptance criteria. Use `scout` only for read-only local mapping when
  inline scoping stalls; research does not automatically require delegation.

## Assign, integrate, and verify

- Apply `RULES.md` to assignments: give the exact worktree or read-only
  checkout, owned paths, applicable ancestor and nested policies, and
  load-bearing restrictions. Prefer the existing assigned worktree.
- Keep one integration owner (main by default). Give workers disjoint edits;
  the owner handles shared changes and resolves conflicts. Work on independent
  steps while workers run rather than polling or duplicating their work.
- Workers hand off the changed scope, acceptance criteria, and narrow checks;
  do not duplicate those checks or run them mid-flight. Inspect the handoff
  and any risky changed hunks instead of rereading unchanged context.
- The integration owner runs the necessary final checks once after all
  changes land. Exercise the requested behavior when applicable, rather than
  treating a proxy build as proof. For read-only work, cite the inspected
  sources and observations instead of requiring a test run.
- Finish the requested work after any design or diagnosis step; a plan
  alone is only a deliverable when requested.
