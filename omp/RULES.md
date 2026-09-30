# Always-apply rules

Hard requirements that must stay active across long sessions AND bind every
spawned subagent. An always-apply rule reaches subagents; APPEND_SYSTEM.md and a
project AGENTS.md do not. Keep this minimal — durable policy lives in
APPEND_SYSTEM.md and each project's AGENTS.md.

## Project rules bind subagents too (MUST)

A project `AGENTS.md` is injected only into the main session's opening context;
a spawned subagent never receives it. So as a subagent, follow the rules given
in your assignment and read the launch-cwd `AGENTS.md` / nearest `README`
yourself before non-trivial work. As the orchestrator, restate the load-bearing
project rules in each subagent's assignment rather than assuming inheritance.

## Worktree isolation, when the repo defines it (MUST)

If the repo provides a worktree convention (`scripts/new-worktree.sh`, a
`.claude/worktrees/` directory, or an AGENTS.md that requires it), do
file-modifying work inside an isolated worktree — never the primary checkout.
OMP does not create worktrees automatically; create one explicitly. Read-only
work (questions, review, diagnosis) is exempt.

## Korean prose documents: humanize before delivery (MUST)

Before publishing Korean prose written for a human reader (Notion pages,
reports, docs, READMEs, long email/Slack bodies), run the final draft through
the `humanize-korean` skill (plugin `humanize-korean@im-not-ai`), or at minimum
apply its `references/quick-rules.md`. Keep facts, numbers, names, links,
quotes, and table values byte-identical, and obey its change-rate gates
(warn above 30%, stop above 50%). Short chat replies, code, and logs are
exempt. If the plugin is missing, use `korean-humanizer` where available.
