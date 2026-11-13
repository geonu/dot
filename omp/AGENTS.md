# omp/ — OMP (oh-my-pi) agent configuration

## OVERVIEW
Source for `~/.omp/agent/*`: role map, named model profiles, the tmux-attention extension,
and the orchestration policy. Own file because it is a distinct domain (own config schema,
own check script) whose edits must stay in lockstep with `zshrc`, `tmux.conf`,
`bin/omp-*-panes`, and `tests/omp-*`.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Base role map, retry tails, agent overrides | `config.yml` | Linked to `~/.omp/agent/config.yml`; the `config` choice uses it as-is |
| Named profiles (`gpt`, `grok`, `claude`, `claude-gpt`, `gpt-claude`, `grok-gpt`) | `profiles/<name>.yml` | Deep-merged over `config.yml` when selected |
| Orchestration policy (main session) | `APPEND_SYSTEM.md` | Role resolution, plan/slow/task escalation |
| Rules that must reach subagents | `RULES.md` | Keep minimal |
| Pane "needs you" markers | `extensions/tmux-attention.ts` | Sets `@omp_attn_pane` / `@omp_attn_win` |
| Model/effort rationale | `README.md`, `BENCHMARKS.md` | README profile table is machine-checked |
| MCP servers | `mcp.json` | Only disables servers; `mcpServers` empty |

## CONVENTIONS
- Profile naming: single provider = provider name; mixed = `<default-provider>-<rest-provider>`.
- `modelRoles` values stay scalar `provider/model:effort`; fallback candidates live only in
  `retry.fallbackChains` per role.
- Profiles deep-merge over `config.yml`, so every profile pins `task.agentModelOverrides`
  (`reviewer`, `sonic`) and `task.perCallModel: "on"` explicitly; base uses `"@slow"`/`"@smol"`.

## ADDING OR RENAMING A PROFILE
Touch all of these in one change, then run the check:
1. `profiles/<name>.yml`
2. `README.md` mode list and profile table
3. `zshrc`: `omp<name>()` / `omp<name>r()` and the profile choice list
4. `tmux.conf`: `@omp-profile-choices`
5. `bin/omp-profile-check.sh`: `profile_names` / `profile_choices`
6. `bin/omp-save-panes`, `bin/omp-restore-panes`: known-profile `case` patterns
7. A newly linked file also needs an `install.conf.yaml` entry

## ANTI-PATTERNS
- Do not change `config.yml` and assume running sessions pick it up: no hot reload; only new
  sessions or a `Ctrl-a R` respawn apply it.
- Do not use `omp models find <role>` to test availability; it substring-matches model names.
- Do not hardcode concrete model IDs in `RULES.md` or policy prose; resolve roles instead.
- Do not commit `config.yml.lock` (runtime artifact, gitignored).

## VERIFY
```bash
bin/omp-profile-check.sh                  # OMP_ACTIVE_PROFILE defaults to gpt; reads ~/.omp/agent/models.db
zsh tests/omp-profile-check-drift.zsh     # check-script regression
zsh tests/omp-active-config-profile.zsh   # pane profile selection
```
The check validates references, not auth or live call success.
