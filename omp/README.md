# omp model roles

`config.yml` role operations: `~/.omp/agent/models.db` is cached model/effort
metadata, not proof of current availability or request success. Run
`bin/omp-profile-check.sh` after registry/profile updates to validate metadata.

## 모드 구분

- **GPT only (default)**: GPT-6 Luna utilities, GPT-6.2 Sol default (global auto effort) and task (medium), and GPT-6.2 Astra slow/vision/plan; Codex only.
- **Grok only**: Grok 4.7 단독. 장기 컨텍스트·비전·고추론을 한 모델이 처리.
- **Claude only**: Fable 5.1을 상위 역할에, Opus 5.5를 비전에, Sonnet 5.5/Haiku 4.5를 보조 역할에 배정.
- **claude-gpt**: Opus 5.5가 `default:high` 오케스트레이터를, GPT-6.2 Astra가 `slow`/`vision`/`plan`을, GPT-6.2 Sol이 `task:medium`을, GPT-6 Luna가 유틸리티 역할을 맡음.
- **gpt-claude (opt-in)**: GPT-6.1 Sol `default:high`, GPT-6.2 Astra vision/plan/reviewer, Sonnet 5.5 task/slow, GPT-6 Luna utilities, and GPT-6.1 Sol `sonic:low`; separate provider quota pools.
- **grok-gpt**: Grok 4.7이 장기 컨텍스트를, GPT-6.2 Astra가 `slow`/`vision`/`plan`을, GPT-6.2 Sol이 `task:medium`을, GPT-6 Luna가 유틸리티 역할을 맡음.


## 프로필 파일과 tmux 재시작

`omp/profiles/*.yml` stores the six named overlays. The base `config.yml`
matches `gpt`; launch with `--config ~/.dotfiles/omp/profiles/<profile>.yml`
to opt into another profile. Mixed names identify the default provider first.

OMP deep-merges overlays over `config.yml`. Every profile therefore explicitly
pins `reviewer`/`sonic` overrides and `task.perCallModel: "on"`. The base and GPT
profile use neutral `reviewer: "@slow"` / `sonic: "@smol"`; `gpt-claude` retains
its explicit Astra/Sol overrides only when selected.

| profile | 파일 | 용도 |
|---------|------|------|
| `gpt` | `omp/profiles/gpt.yml` | GPT-6 Luna + GPT-6.2 Sol `default` (global auto) + GPT-6.2 Sol `task:medium` + GPT-6.2 Astra `slow`/`vision`/`plan` Codex-only 구성 |
| `grok` | `omp/profiles/grok.yml` | Grok 4.7 단독 구성 |
| `claude` | `omp/profiles/claude.yml` | Fable 5.1 상위 역할 + Opus 5.5 비전 Claude-only 구성 |
| `claude-gpt` | `omp/profiles/claude-gpt.yml` | Opus 5.5 `default:high` + GPT-6.2 Astra `slow`/`vision`/`plan` + GPT-6.2 Sol `task:medium` + GPT-6 Luna utility |
| `gpt-claude` | `omp/profiles/gpt-claude.yml` | Opt-in GPT-6.1 Sol `default:high` + GPT-6.2 Astra vision/plan/reviewer + Sonnet 5.5 task/slow + Luna utilities + Sol sonic |
| `grok-gpt` | `omp/profiles/grok-gpt.yml` | Grok 4.7 + GPT-6.2 Astra `slow`/`vision`/`plan` + GPT-6.2 Sol `task:medium` + GPT-6 Luna utility |
| `config` | 없음 | override 없이 현재 `config.yml` 그대로 resume |

Inside tmux, `Ctrl-a R` resumes the current pane's session in the selected
profile. The prompt defaults to `gpt`; choices remain
`gpt`, `grok`, `claude`, `claude-gpt`, `gpt-claude`, `grok-gpt`, and `config`.
OMP has no config hot reload; resume can restore the session's active model,
so the wrapper passes both `--resume <session-id>` and provider overrides.
Session lookup uses the live pane process first (`ps --resume`, open `.jsonl`,
or per-pid log `sessionId`, with brief retries for a new session), then saved
`@omp_session`, then the newest session in the pane cwd. Without a session,
the wrapper clears stale pane metadata and starts a fresh selected profile.

`bin/omp-profile-check.sh` checks profile contracts, base/default equality,
launcher/tmux/save/restore integration, and cached selector/effort metadata.
Set `OMP_AVAILABLE_MODELS_JSON=/path/to/saved-omp-models.json` to additionally
compare selectors with a saved `omp models --json` available-registry snapshot.
A missing or malformed supplied snapshot fails; the checker does not refresh
registries, activate authentication, or send requests. Even a matching snapshot
does not prove request success. Unavailable opt-in profiles remain diagnostics,
not permission to rewrite them or substitute providers.

## GPT only

| role | model | 배정 원칙 |
|------|-------|----------|
| `smol`, `commit` | GPT-6 Luna | 경량 lookup 및 thinking-off 메시지 |
| `default` | GPT-6.2 Sol | 일반 장기 작업, global auto effort |
| `task` | GPT-6.2 Sol | coding fan-out, medium effort |
| `slow`, `vision`, `plan` | GPT-6.2 Astra | 실패 비용이 높은 추론·시각 작업 |

`default`는 `openai-codex/gpt-6.2-sol`로 effort suffix 없이 global auto를 따른다. `task`는 GPT-6.2 Sol `medium`을 쓴다. `plan`만 GPT-6.2 Astra의 `xhigh`이고 `slow`와 `vision`은 `high`다. GPT-6 Luna는 text/image, registry `contextWindow` 272,000, `maxContextWindow` 872,000, 128,000 output과 `low`~`max` effort를 지원하며 `off`도 별도 effort 없이 허용한다. GPT-6.1 Sol은 text/image, registry `contextWindow` 272,000, `maxContextWindow` 872,000, 128,000 output과 `low`~`max` effort를 지원한다.

현재 로컬 registry에서 GPT-6.2 Sol은 text/image, `contextWindow` 500,000, `maxContextWindow` 872,000, `maxTokens` 128,000, `low`~`max` effort를 지원한다. GPT-6.2 Astra는 text/image, `contextWindow` 272,000, `maxContextWindow` 872,000, `maxTokens` 128,000, `low`~`max` effort를 지원한다. 이전 모델의 벤치마크와 가격은 새 모델의 근거로 쓰지 않는다. 날짜별 과거 자료는 `BENCHMARKS.md`에 남긴다.

## Grok only

모든 역할이 Grok 4.7이다. `smol`은 `low`, `commit`은 `minimal`, `default`/`task`/`vision`은
`medium`, `slow`는 `high`, `plan`만 `xhigh`다. text/image, 500K context,
500K output을 지원한다.


## Claude only

Fable 5.1은 `default:medium`/`slow:high`/`plan:xhigh`, Opus 5.5는 `vision:medium`, Sonnet 5.5는
`task:medium`, Haiku 4.5는 `smol`/`commit`을 맡는다. Fable 5.1·Opus 5.5·Sonnet 5.5는 1M context·128K output을 지원한다.

## 현재 프로필 정책

The approved base/default matches the GPT-only profile: GPT-6.2 Sol without
an effort suffix (global auto) for default, GPT-6.2 Sol `medium` for task,
GPT-6.2 Astra `high` for slow/vision and `xhigh` for plan, and Luna for
smol/commit. Native chat retry tails follow `gpt.yml` (plan/slow →
`openai-codex/gpt-6.2-sol`, no effort suffix; task → Luna `medium`);
retry budgets and limits are unchanged.
Named mixed/Claude/Grok profiles remain explicit opt-ins.

### Model routing diagnostics

1. **Effective configuration.** Read `cfg://modelRoles` in the current
   session. A fresh `omp config get modelRoles --json` is comparable only when
   launched with the same profile, overlays, and environment. Resolve the
   requested role to its exact scalar `provider/model-id[@upstream][:level]`;
   the optional upstream and effort are part of the dispatch selector when
   configured. Keep `task.perCallModel: "on"` in the base and every profile;
   it enables selection, not authentication or availability.
2. **Dispatch and pins.** For an unpinned agent, pass the resolved selector in
   `tasks[].model`. For a pinned agent, read `cfg://task.agentModelOverrides`
   and resolve any `@role` against the same effective mapping. Omit the
   per-call selector only if the pin exactly matches the requested selector.
   A mismatch stops dispatch; an explicit model cannot override the pin.
   Direct per-call workers disable automatic fallback, context promotion, and
   prewalk. Report `requested role -> exact selector -> exact error` for any
   selection or dispatch failure (`unresolved` if the mapping is missing).
   Do not try another model or provider without explicit approval.
3. **Metadata, availability, and execution.** Cached metadata validates the
   selector/effort contract. Check the current available registry separately
   (`omp models --json`); compare the concrete provider and model ID, without
   the effort suffix. Do not use `omp models find <role>`: it substring-matches
   concrete model names. Neither cached metadata nor a registry listing proves
   that an actual request succeeds.
4. **Native chat retry.** `retry.modelFallback` and the concrete selectors in
   `retry.fallbackChains` govern native chat recovery, not worker selection.
   Preserve those semantics. If an approved role/default change affects the
   native tails, align them explicitly; they do not regenerate from `modelRoles`.
   Never activate a provider, change credentials, or adjust `maxRetries`,
   `maxDelayMs`, `usageReservePolicy`, or `waitForUsageReset` to bypass a
   dispatch failure.

### Applying the GPT default change

After landing into the existing symlink target, open a new shell (or reload
`~/.zshrc`) and use a fresh/default GPT launch. Explicit `OMP_DEFAULT_PROFILE`
still takes precedence. For a running tmux server, apply only
`tmux set-option -g @omp-default-profile gpt`; do not respawn healthy panes or
rewrite saved profiles. Existing OMP sessions keep their active runtime roles
until restarted. No `./install`, provider activation, or re-auth is needed.

`claude-gpt`는 Opus 5.5를 `default:high`, GPT-6.2 Astra를 `slow:high`/`vision:high`/`plan:xhigh`,
GPT-6.2 Sol을 `task:medium`에 둔다. `grok-gpt`는 Grok 4.7을 `default`에
`medium` effort로 유지하고 같은 GPT-6.2 Astra/GPT-6.2 Sol 역할 분리를 쓴다. 세 혼합 프로필 모두 GPT-6 Luna를 `smol`/`commit`에 둔다.


## 모델 갱신 기준

모델 이름의 숫자만으로 우선순위를 정하지 않는다. provider가 제공하는 현재 레지스트리,
지원 modality/effort, 해당 프로필의 구독·역할 목적을 함께 확인한다. Grok 4.20 계열은
구버전이므로 프로필에서 사용하지 않고, 현재 범용 coding/vision 모델인 Grok 4.7을 쓴다.

## 운용 원칙

1. `smol`/`commit`은 경량 effort, `default`/`task`는 실행 균형, `slow`/`plan`/`vision`은 고추론으로 분리한다. `designer` 역할은 OMP 18.1.5(2026-09-03)에서 제거되어 프로필에 두지 않는다. single-model 프로필은 같은 모델에 effort 티어만 나눈다.
2. GPT profile은 GPT-6 Luna 유틸리티, GPT-6.2 Sol `default`(global auto), GPT-6.2 Sol `task:medium`, GPT-6.2 Astra `slow`/`vision`/`plan`으로 역할을 나눈다. Grok-only는 Grok 4.7 한 모델에 effort 티어만 적용한다.
3. `plan`만 예외적으로 `xhigh`를 쓴다. GPT-6.2 Astra, Fable 5.1, Opus 5.5처럼 registry가 `xhigh`를 제공하는 모델에만 배정하며, metadata가 지원하지 않는 effort는 배정하지 않는다.
4. registry 갱신 뒤에는 `bin/omp-profile-check.sh`를 실행하고, 모든 기존 provider selector가 현재 metadata에 존재하는지 확인한다.

## 오케스트레이션 정책 (APPEND_SYSTEM)

OMP에서 `SYSTEM.md`는 기본 프롬프트를 교체한다. `APPEND_SYSTEM.md`는 기본 지침과
skills/rules/tool 가이드를 유지한 채 오케스트레이션 정책을 추가한다.

- 글로벌: `~/.omp/agent/APPEND_SYSTEM.md` ← `omp/APPEND_SYSTEM.md` 심링크(`install.conf.yaml`).
- 프로젝트: 해당 repo에서 `omp`를 띄우는 cwd에 `<repo>/.omp/APPEND_SYSTEM.md`를 둔다.
  조상 디렉토리 walk-up은 없으므로 launch cwd 바로 아래여야 한다.
- 우선순위: `--append-system-prompt` > 프로젝트 `APPEND_SYSTEM.md` > 유저 `APPEND_SYSTEM.md`.
  단 셋 다 누적이 아니라 가장 높은 한 경로만 적용된다 — 프로젝트 파일을 두면 글로벌은
  무시되므로 프로젝트 파일에 글로벌 규칙을 포함하거나 글로벌만 유지한다.

메인은 먼저 작업 범위를 확인한다. 작업이 작거나 나눌 필요가 없으면 직접 처리한다.
독립적으로 맡길 작업이 둘 이상일 때는 위임할 실익을 따진다. 별도 검토가 필요한 설계는
`plan`으로, 원인 분석은 `slow`로 검토하고, 독립적인 구현은 `task`에 맡길 수 있다.
통합 책임자가 변경을 모아 한 번 검증한다.
[오케스트레이션 정책](APPEND_SYSTEM.md) (설치 후: `~/.dotfiles/omp/APPEND_SYSTEM.md`)은
프로필과 별개로 적용한다. 워커는 [공통 규칙](RULES.md) (설치 후: `~/.dotfiles/omp/RULES.md`)도
따른다. 편집할 때는 설치 경로 대신 배정된 작업트리의 파일을 사용한다.

로드를 확인하려면 새 세션에서 OMP가 실제로 선택한 소스나 렌더링한 프롬프트를 살핀다.
이를 직접 볼 수 없으면 파일과 링크를 확인한 범위까지만 보고한다. 모델이 정책 문구를
되풀이해도 주입 여부를 판단하는 간접 단서일 뿐, 우선순위나 워커 상속, 실제 준수를
증명하지는 않는다.

## MCP → CLI 대체 (`omp/mcp.json`)

omp는 시작 시 Claude 플러그인(`~/.claude/plugins/*/.mcp.json`)과 프로젝트
`.mcp.json`에서 MCP 서버를 발견해 연결한다. 같은 일을 하는 CLI/내장 툴이 있으면
MCP 핸드셰이크 비용·툴 표면 노이즈를 줄이기 위해 MCP를 끄고 CLI로 대체한다.

`~/.omp/agent/mcp.json`의 `disabledServers`는 이름으로 서버를 억제하는 유저 레벨
denylist다([mcp-config.md](omp://mcp-config.md)). 플러그인의 skill/command와 프로젝트
`.mcp.json`(Claude Code와 공유)은 그대로 두고 omp의 MCP 연결만 끊으므로 플러그인 제거보다
외과적이다. 이 파일은 `omp/mcp.json`으로 트래킹하고 `install.conf.yaml`이
`~/.omp/agent/mcp.json`에 심링크한다.

**매칭 키는 출처별로 다르다**(실측). 같은 서버라도 두 형식을 모두 넣어야 확실히 막힌다:

- 프로젝트/standalone `.mcp.json` 출처 → **bare 이름**(`vercel`). 로그 path는 `mcp:vercel`.
- Claude 플러그인 출처 → **`provider:server` 형식**(`vercel:vercel`). 로그 path는 `mcp:vercel:vercel`.

bare 이름만 넣으면 플러그인 출처(github/vercel 등)는 계속 연결을 시도하고 인증 미설정 시
401/400으로 실패해 시작 로그를 더럽힌다. 그래서 plugin+project 양쪽에 있는 서버는 두 키를 다 넣는다.

| MCP 서버 | 출처 | 대체 | 비고 |
|----------|------|------|------|
| `github` | 플러그인(전역) | `gh` CLI + omp 내장 `issue://`/`pr://` | gh는 Brewfile |
| `vercel` | 플러그인 + 프로젝트 | `vercel-cli` | docs 검색만 손실 |
| `supabase` | 플러그인 + 프로젝트 | `supabase` CLI | db/migration/functions/gen |
| `chrome-cdp` | 프로젝트 | omp 내장 `browser` 툴 | bare 키로 충분 |
| `chrome-devtools` | 프로젝트 | omp 내장 `browser` 툴 | 〃 |
| `playwright` | 프로젝트 | omp 내장 `browser` 툴 | 〃 |
| `slack` | 플러그인(전역) | **제거** | 공식 CLI 없으나 OAuth 미인증이라 401만 내던 노이즈. 인증해 쓸 거면 `slack`,`slack:slack` 두 줄 삭제 |

대체 CLI는 Brewfile에 둔다: `gh`(기존), `vercel-cli`, `supabase/tap/supabase`.
검증(결정적): 대상 MCP를 쓰는 cwd(예: moody)에서 `omp -p "say ok"`를 한 번 돌린 뒤
`grep -oE '"path":"mcp:[^"]+"' ~/.omp/logs/omp.$(date +%F).log | sort -u`로 시도된 서버를
본다. 출력이 비면(MCP 연결 0건) 성공. (`-p` 단독 모델 자기보고나 `--no-tools`는
MCP 자체를 꺼서 무효한 검증이다.) 새 서버를 더 끄려면 bare + `provider:server` 두 키를 추가한다.

