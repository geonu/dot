# omp model roles

`config.yml`의 `modelRoles` 운용 노트. 호출 가능 모델과 지원 effort의 단일 근거는
`~/.omp/agent/models.db`다. 레지스트리가 갱신되면 `bin/omp-profile-check.sh`를 먼저
실행해 현재 프로필이 호출 가능한 모델만 참조하는지 확인한다.

## 모드 구분

- **GPT only**: Luna(경량)·Terra(기본 실행)·Sol(고추론)을 모두 쓰는 Codex-only 구성.
- **GPT+GLM**: GPT 역할 분리와 GLM-5.2의 별도 task 쿼터를 결합한 fallback.
- **Grok only**: Grok 4.5 단독. 장기 컨텍스트·비전·고추론을 한 모델이 처리.
- **Kimi only**: Kimi K3의 1M-context coding endpoint를 단독 사용.
- **Claude only**: Opus 5를 장기·고위험 역할에, Sonnet 5/Haiku 4.5를 보조 역할에 배정.
- **combo-claude**: Opus 5가 장기 컨텍스트를, Sol/Terra가 burst/task를 맡음.
- **combo-gpt**: Terra가 장기 기본·task를, Sol이 고위험 판단을 맡음.
- **combo-grok**: Grok 4.5가 장기 컨텍스트를, Sol/Terra가 burst/task를 맡음.


## 프로필 파일과 tmux 재시작

모델 조합은 `omp/profiles/*.yml`에 같은 이름으로 보관한다. `config.yml`은 현재 기본값
(`grok` active config)이고, 프로필은 실행 시 `--config ~/.dotfiles/omp/profiles/<profile>.yml`로
overlay한다.

| profile | 파일 | 용도 |
|---------|------|------|
| `gpt` | `omp/profiles/gpt.yml` | Claude를 쓰지 않는 Luna/Terra/Sol 구성 |
| `gpt-glm` | `omp/profiles/gpt-glm.yml` | Terra/Sol orchestration + GLM-5.2 task |
| `grok` | `omp/profiles/grok.yml` | Grok 4.5 단독 구성 |
| `kimi` | `omp/profiles/kimi.yml` | Kimi K3 단독 구성 |
| `claude` | `omp/profiles/claude.yml` | Opus 5 중심 Claude-only 구성 |
| `combo-claude` | `omp/profiles/combo-claude.yml` | Opus 5 + Sol/Terra burst |
| `combo-gpt` | `omp/profiles/combo-gpt.yml` | Terra/Sol + Claude utility |
| `combo-grok` | `omp/profiles/combo-grok.yml` | Grok 4.5 + Sol/Terra + Claude utility |
| `config` | 없음 | override 없이 현재 `config.yml` 그대로 resume |

tmux 안에서는 `Ctrl-a R`을 누르면 현재 pane에서 실행 중인 OMP 프로세스의 session id를
먼저 읽고, 같은 cwd에서 pane을 respawn한다. 프롬프트 기본값은 `grok`이며,
`gpt-glm`, `gpt`, `grok`, `kimi`, `claude`, `combo-claude`, `combo-gpt`, `combo-grok`, `config` 중 하나를 입력하면 **현재 pane의 세션**을 해당
프로필로 이어간다. OMP TUI의 config hot reload가 없고 resume이 세션의 active model을
복원할 수 있어, wrapper가 현재 pane의 `--resume <session-id>`와 provider override를 함께
전달한다. 세션 id 결정 우선순위는 ① pane의 라이브 omp 프로세스(`ps --resume` / 열린
`.jsonl` / per-pid 로그의 `sessionId`, 새 세션 단서가 보일 때까지 짧게 재시도) → ② pane에 기록해 둔 `@omp_session`
tmux 옵션(omp가 종료돼도 남아 다음 전환에서 같은 대화로 복귀; live 추출이 실패해도 사용) → ③ pane cwd의 최신
세션(`run-shell`은 pane cwd를 상속하지 않으므로 pane 디렉토리 기준으로 조회)이다. 그래도
세션이 없으면 stale pane 옵션을 비우고 해당 프로필로 새 세션을 띄운다. respawn은 항상 수행되어 pane이 죽지 않는다.

정합성 체크는 `bin/omp-profile-check.sh`로 한다. 이 스크립트는 `omp/config.yml`이
기본 active profile인 `grok`와 같은 role map인지, `omp/profiles/*.yml`, 이 README의
프로필 목록, `zshrc` profile dispatcher, `tmux.conf`의 `@omp-default-profile`/`@omp-profile-choices`,
save/restore helper의 profile 보존 규칙, 그리고 로컬 `~/.omp/agent/models.db`의 모델/effort
메타데이터를 함께 검증한다. 모델 가이드나 profile 기본값을 바꾸거나 OMP 업데이트 후에는 이 체크를 먼저 돌린다.

## GPT only

| role | model | 배정 원칙 |
|------|-------|----------|
| `smol`, `commit` | GPT-5.6 Luna | 경량 lookup 및 thinking-off 메시지 |
| `default`, `task` | GPT-5.6 Terra | 일반 장기 작업과 coding fan-out |
| `slow`, `vision`, `plan`, `designer` | GPT-5.6 Sol | 실패 비용이 높은 추론·시각·설계 작업 |

`plan`만 `xhigh`이고 나머지 Sol 역할은 `high`다. Luna·Terra·Sol은 모두 text/image,
272K context, 128K output을 지원한다.

## Grok only

모든 역할이 Grok 4.5다. `smol`은 `low`, `commit`은 `minimal`, `default`/`task`/`vision`은
`medium`, `slow`/`designer`는 `high`, `plan`만 `xhigh`다. text/image, 500K context,
500K output을 지원한다.

## GPT+GLM

`gpt-glm`은 Terra를 `default`, Sol을 `slow`/`vision`/`plan`/`designer`, Luna를 `smol`에
둔다. GLM-5.2는 text-only이며 High/Max effort만 지원하므로 `commit:off`와 `task:max`에
한정한다.

## Claude only

Opus 5는 `default`/`slow`/`vision`/`plan`, Sonnet 5는 `designer`/`task`, Haiku 4.5는
`smol`/`commit`을 맡는다. Opus 5와 Sonnet 5는 1M context·128K output을 지원한다.

## 현재 프로필 정책

`omp/config.yml`은 `grok`와 같은 role map이다. 새 세션 또는 `config` resume은 Grok 4.5를
전 역할에 사용한다.

`combo-claude`는 Opus 5를 `default`, Sol을 `slow`/`vision`/`plan`/`designer`, Terra를
`task`에 둔다. `combo-gpt`는 Terra를 `default`/`task`, Sol을 고추론 역할에 둔다.
`combo-grok`은 Grok 4.5를 `default`로 유지하며 같은 Sol/Terra 역할 분리를 쓴다.

## Kimi와 GLM

Kimi Code provider에는 K3가 등록되어 있다. K3는 text/image, 1,048,576 context, 131,072
output, `minimal`~`high` effort를 지원하므로 `kimi` profile에서 모든 역할을 단독 처리한다.
K3는 `xhigh`와 `off`를 지원하지 않아 `plan`은 `high`, `commit`은 `minimal`이다.

GLM provider의 최신 등록 모델은 GLM-5.2다. 1M context와 131,072 output을 제공하지만
text-only이고 High/Max effort만 지원한다. 따라서 `gpt-glm`에서 고볼륨 task에만 유지한다.

## 모델 갱신 기준

모델 이름의 숫자만으로 우선순위를 정하지 않는다. provider가 제공하는 현재 레지스트리,
지원 modality/effort, 해당 프로필의 구독·역할 목적을 함께 확인한다. 예를 들어
`grok-4.20-0309-reasoning`은 registry에 있어도 Grok 4.5를 자동으로 대체하지 않는다.

## 운용 원칙

1. `smol`/`commit`은 경량 effort, `default`/`task`는 실행 균형, `slow`/`plan`/`vision`/`designer`는 고추론으로 분리한다. single-model 프로필은 같은 모델에 effort 티어만 나눈다.
2. GPT profile은 Luna → Terra → Sol의 비용·추론 티어를 유지한다. Grok-only는 Grok 4.5 한 모델에 effort 티어만 적용한다.
3. `plan`만 예외적으로 `xhigh`를 쓴다. model metadata가 지원하지 않는 effort는 배정하지 않는다.
4. `gpt-glm`의 GLM-5.2는 text-only High/Max model이므로 일반 orchestration이나 vision에 쓰지 않는다.
5. registry 갱신 뒤에는 `bin/omp-profile-check.sh`를 실행하고, 모든 기존 provider selector가 현재 metadata에 존재하는지 확인한다.

## 오케스트레이션 정책 (APPEND_SYSTEM)

모델 effort를 올리는 것보다, `default`(메인 루프)가 언제 `plan`/`slow`/`task`로
넘기는지를 강제하는 게 효율적이다. OMP는 `SYSTEM.md`(기본 블록 교체)와
`APPEND_SYSTEM.md`(기본 지침 + skills/rules/tool 가이드 유지하고 블록 추가) 두 경로를
제공한다. delegation 규칙은 기본 지침을 살려야 하므로 `APPEND_SYSTEM.md`를 쓴다.

- 글로벌: `~/.omp/agent/APPEND_SYSTEM.md` ← `omp/APPEND_SYSTEM.md` 심링크(`install.conf.yaml`).
- 프로젝트: 해당 repo에서 `omp`를 띄우는 cwd에 `<repo>/.omp/APPEND_SYSTEM.md`를 둔다.
  조상 디렉토리 walk-up은 없으므로 launch cwd 바로 아래여야 한다.
- 우선순위: `--append-system-prompt` > 프로젝트 `APPEND_SYSTEM.md` > 유저 `APPEND_SYSTEM.md`.
  단 셋 다 누적이 아니라 가장 높은 한 경로만 적용된다 — 프로젝트 파일을 두면 글로벌은
  무시되므로 프로젝트 파일에 글로벌 규칙을 포함하거나 글로벌만 유지한다.

글로벌 정책은 default를 "작업자"가 아닌 "오케스트레이터"로 규정하고, plan/slow/task
escalation 임계값과 default가 직접 처리해도 되는 범위를 못박는다. 모델 프로필과 독립이라
`gpt`/`gpt-glm`/`grok`/`kimi`/`claude`/`combo-*` 어디서나 동일하게 적용된다.

로드 확인: 새 세션에서
`omp -p --no-tools "output verbatim the bullet lines under 'Anti-patterns'"`로
정책 문구가 시스템 프롬프트에 들어갔는지 검증한다.

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

