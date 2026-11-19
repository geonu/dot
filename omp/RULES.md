# Always-apply rules

These requirements bind the main session and every subagent, including workers
that delegate further. `APPEND_SYSTEM.md` and project `AGENTS.md` are not
automatically inherited by workers.

## Project rules bind subagents too (MUST)

An assignment must name the exact worktree (or checkout for read-only work),
owned paths, and applicable ancestor and nested `AGENTS.md` paths. Restate the
rules that affect the assignment, including any restrictions and acceptance
criteria. Before non-trivial work, the worker must read applicable policies
broadest first, including governing ancestors outside the checkout and nested
policies for newly scoped paths. Use the assigned checkout for repo-local
policies. If no project `AGENTS.md` applies, read the nearest `README`.

## Worktree isolation, when the repo defines it (MUST)

When the repo defines a worktree convention, edit in the assigned isolated
worktree, never the primary checkout. Reuse an existing assigned worktree;
if none exists, the orchestrator creates one explicitly using the repo's safe
creation mode. Worktree creation does not authorize cleanup. Read-only
questions, reviews, and diagnosis do not require an isolated worktree.

## Worker model selection (MUST)

- Resolve each requested role against effective `cfg://modelRoles` to one exact
  scalar `provider/model-id[@upstream][:level]` selector. Keep the configured
  upstream and effort (or their absence); never pass a role alias, wildcard,
  or candidate array.
- Pass the exact scalar as `tasks[].model` for an unpinned agent. Check
  effective `cfg://task.agentModelOverrides`; if pinned, resolve any role
  alias in the pin against the same mapping. Omit the per-call selector only
  to use a pin that exactly matches the requested selector. On a mismatch,
  stop that dispatch; do not bypass or change the pin. Agent names select
  behavior, not model roles.
- If resolution or dispatch fails, report `requested role -> exact selector ->
  exact error` (`unresolved` for a missing mapping). No automatic fallback,
  context promotion, or prewalk for direct per-call workers. Never substitute
  a model or provider without explicit approval. Do not change provider
  activation, credentials, retry settings, or usage caps to get past the
  failure. Native chat retry is separate and does not authorize worker fallback.

## Verification handoff (MUST)

Workers report changed scope, observable acceptance criteria, and the narrow
checks to run, without running builds, tests, linters, formatters, or smoke checks
mid-flight. The integrator runs the necessary checks once after landing the
changes. Read-only work hands off the inspected sources and observed evidence,
not a test run; distinguish what was observed from what was inferred.

## Korean prose documents: humanize before delivery (MUST)

Before delivering Korean prose for human readers (Notion pages, reports, docs,
READMEs, long email or Slack messages), use `humanize-korean` (plugin
`humanize-korean@im-not-ai`), or `korean-humanizer` if the preferred skill is
unavailable. If neither is available, apply the project-authored
[Korean prose quick rules](references/korean-quick-rules.md); installed:
`~/.dotfiles/omp/references/korean-quick-rules.md`. Use the assigned worktree
copy for edits. In every case, keep facts, numbers, names, links, quotes, and
table values byte-identical; warn above 30% change and stop above 50%.
Short chat replies, code, and logs are exempt.
