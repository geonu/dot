# Global agent prompt

| File | Loaded | Holds |
|---|---|---|
| [CORE.md](CORE.md) | Every session of OMP, Codex, and Claude (`install.conf.yaml` links it to `~/AGENTS.md`, `~/agents.md`, `~/.codex/AGENTS.md`; OMP and Claude reach it through those) | Rules that apply on every turn |
| [PLAYBOOK.md](PLAYBOOK.md) | On demand, through the link in `CORE.md` (installed path `~/.dotfiles/agents/PLAYBOOK.md`) | Procedures for failed attempts, logins, and decision requests |

Keep `CORE.md` to always-apply rules. Every injected word costs tokens on every turn, and adherence drops as instructions accumulate, so move situational detail to the playbook and remove duplicates.

## Changing the prompt

No published study shows that a particular context-file wording improves agents. The supported method is a measured loop: measure, change a little, measure again.

1. **Measure.** `bin/agent-handoff-audit` counts OMP turn endings that hand work back to the user. Run `bin/agent-handoff-audit -v --since DATE` and classify a sample of matches by hand: a step only the user could do, avoidable handoff, or an ending that only announces intent. The regex also catches legitimate requests, so compare classified samples, not raw percentages alone.
2. **Change a little.** Edit or add the few rules that address the classified failures. Avoid wholesale rewrites, which tend to drop details that were working.
3. **Re-measure** on sessions started after the change (`--since` the landing date) and keep the change only if the classified failure rate drops.

Baseline before the problem-solving rules (OMP sessions, 2026-11-10 to 2026-11-19): 71 of 392 turn endings (18%) matched. Login and verification-code requests were among them; several were doable with configured access, so do not count them as legitimate by default.

## Model guidance to recheck when models change

- OpenAI's [GPT-6.2 guide](https://developers.openai.com/api/docs/guides/latest-model#task-completion) recommends telling the model to take suggested next steps itself and to stop only for scope changes, real blockers, user decisions, or irreversible actions.
- Anthropic's [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) warn that recent Claude models overreact to aggressive or anti-laziness wording; prefer plain, positive instructions. The effort limit in `CORE.md` Problem Solving bounds the persistence rules.
- [Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) found that agents follow context-file instructions, but the files did not raise task success on average and added more than 20% inference cost.
- [ACE](https://arxiv.org/abs/2510.04618) improved agents by updating contexts incrementally from execution feedback; full rewrites caused context collapse.
