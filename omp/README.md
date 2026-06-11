# omp model roles

`config.yml`의 `modelRoles` 운용 노트. 구독제(Anthropic + OpenAI Codex) 기준이므로
토큰 단가가 아니라 **작업 완결까지의 총 토큰**과 **구독 쿼터 여유**가 효율 기준.
모델 존재/effort 메타데이터는 `~/.omp/agent/models.db`, 레벨 문법은 omp://models.md
(`off|minimal|low|medium|high|xhigh`, 모델별 effortMap/budget으로 변환).

## 모드 구분

- **GPT only**: Claude 구독 쿼터를 이미 소진했거나 Anthropic 호출을 의도적으로 막을 때. 현재 `config.yml`.
- **Claude only**: Claude 구독 쿼터가 충분하고 OpenAI/Codex 쿼터를 아낄 때.
- **combo-claude**: Claude가 장기 컨텍스트의 주 모델, Codex/GPT는 고추론·비전 버스트.
- **combo-gpt**: Codex/GPT가 장기 컨텍스트의 주 모델, Claude는 smol/commit/task 보조.


## 프로필 파일과 tmux 재시작

모델 조합은 `omp/profiles/*.yml`에 같은 이름으로 보관한다. `config.yml`은 현재 기본값
(`GPT only`)이고, 프로필은 실행 시 `--config ~/.dotfiles/omp/profiles/<profile>.yml`로
overlay한다.

| profile | 파일 | 용도 |
|---------|------|------|
| `gpt` | `omp/profiles/gpt.yml` | Claude 쿼터 소진/Anthropic 차단 시 |
| `claude` | `omp/profiles/claude.yml` | Claude 쿼터 여유, Codex 쿼터 보호 시 |
| `combo-claude` | `omp/profiles/combo-claude.yml` | Claude default + Codex burst |
| `combo-gpt` | `omp/profiles/combo-gpt.yml` | GPT default + Claude utility/task |
| `config` | 없음 | override 없이 현재 `config.yml` 그대로 resume |

tmux 안에서는 `Ctrl-a R`을 누르면 현재 pane에서 실행 중인 OMP 프로세스의 session id를
먼저 읽고, 같은 cwd에서 pane을 respawn한다. 프롬프트에 `gpt`, `claude`,
`combo-claude`, `combo-gpt`, `config` 중 하나를 입력하면 **현재 pane의 세션**을 해당
프로필로 이어간다. OMP TUI의 config hot reload가 없고 resume이 세션의 active model을
복원할 수 있어, wrapper가 현재 pane의 `--resume <session-id>`와 provider override를 함께
전달한다. 세션 id를 못 읽은 경우에만 cwd의 최신 세션으로 fallback한다.

정합성 체크는 `bin/omp-profile-check.sh`로 한다. 이 스크립트는 `omp/config.yml`,
`omp/profiles/*.yml`, 이 README의 프로필 목록, 그리고 로컬 `~/.omp/agent/models.db`의
모델/effort 메타데이터를 함께 검증한다. 모델 가이드를 바꾸거나 OMP 업데이트 후에는 이
체크를 먼저 돌린다.

## 현재 세팅: GPT only (Claude 쿼터 소진 대응)

| role     | model                         | 비고 |
|----------|-------------------------------|------|
| default  | openai-codex/gpt-5.5:medium   | 장기·복합 기본. high 대비 토큰 절반 수준에서 -2pt [S10] |
| smol     | openai-codex/gpt-5.4-nano:low | gpt 계열은 `minimal` 미지원 |
| slow     | openai-codex/gpt-5.5:high     | 고추론 버스트. xhigh는 +1pt에 토큰 +67%라 제외 [S10] |
| vision   | openai-codex/gpt-5.5:high     | 이미지 QA 실패 비용이 큰 경우 high |
| plan     | openai-codex/gpt-5.5:xhigh    | 설계·계획은 호출 빈도가 낮고 실패 비용이 커서 OpenAI 공식 xhigh 벤치 조건에 맞춤 [S13] |
| designer | openai-codex/gpt-5.5:high     | UI/디자인 구현 전용 |
| commit   | openai-codex/gpt-5.4-nano:off | thinking 비활성 |
| task     | openai-codex/gpt-5.5:medium   | 병렬 서브태스크 품질 하한 보강. high는 토큰 2x라 미사용 [S10] |

## Claude only 참고안: 무료 윈도우 공격 모드 (2026-06-22까지)

fable-5는 2026-06-09 출시~**06-22까지** 유료 구독(Pro/Max/Team/Enterprise)에 추가 비용
없이 포함, **06-23부터 플랜에서 제거**되어 사용 시 API 단가($10/$50)로 크레딧 과금 [S7].
Claude 쿼터와 무료 윈도우가 모두 남아 있을 때만 아래 구성을 쓴다.

| role     | model                              | 비고 |
|----------|------------------------------------|------|
| default  | anthropic/claude-fable-5:low       | API "medium". :low 유지는 레이턴시 때문(fable은 +30% 느림 [S3]) |
| smol     | anthropic/claude-haiku-4-5:minimal | budget 모드 최소 thinking |
| slow     | anthropic/claude-fable-5:high      | API "xhigh". 어려운 단발 작업 최강 [S2] |
| vision   | anthropic/claude-fable-5:medium    | 이미지 입력 QA. 실패 비용이 큰 경우 high |
| plan     | anthropic/claude-fable-5:high      | 복합 계획 = fable 본령, 1M ctx |
| designer | anthropic/claude-sonnet-4-6:high   | UI/디자인 구현 전용. fable 쿼터 보호 |
| commit   | anthropic/claude-haiku-4-5:off     | thinking 비활성 |
| task     | anthropic/claude-opus-4-8:low      | API "medium" 착지(effortMap [S9]). opus 적극 투입 슬롯 [S5] |

### 상위 모델 직접 비교 (공식/독립 벤치마크)

| 지표 | fable-5 | opus-4.8 | gpt-5.5 | 신빙성 |
|------|---------|----------|---------|--------|
| SWE-bench Pro | 80.3% | 69.2% | 58.6% | Anthropic 공식 표 [S1] |
| FrontierCode Diamond | 29.3% | 13.4% | 5.7% | Anthropic 공식 표 [S1] |
| OSWorld-Verified | 85.0% | 83.4% | 78.7% | Anthropic 공식 표 [S1] |
| HLE(no tools / tools) | 59.0% / 64.5% | 49.8% / 57.9% | 41.4% / 52.2% | Anthropic 공식 표 [S1] |
| AA Intelligence Index | 64.9 | 61.4 | medium 57 / high 59 / xhigh 60 | Artificial Analysis 독립 측정 [S10][S11][S12] |
| GDPval-AA Elo | 1932 | 1890 | 1769 | Anthropic/AA 공통 [S1][S12] |

결론: 공식·독립 수치 모두 `fable-5 > opus-4.8 > gpt-5.5` 순서다. 다만 AA의
fable-5 측정은 **adaptive max effort + Opus 4.8 fallback** 조건 [S12]이고,
OMP의 `fable-5:low`는 실제 API에서 같은 max 조건이 아닐 수 있다. 따라서 아래 역할별
점수는 벤치마크 순위를 반영한 운용 추정이지, 동일 harness 실측값이 아니다.

### Effort 레벨별 정량 비교 (gpt-5.5, 독립 측정 [S10])

| effort | AA 지능지수 | 토큰 사용량(Index 전체) | 상대 토큰 | 속도 |
|--------|------------|------------------------|-----------|------|
| xhigh  | 60         | 75M                    | 3.4x      | 71.7 tok/s |
| high   | 59         | 45M                    | 2.0x      | 52.4 tok/s |
| medium | 57         | 22M                    | 1.0x      | 48.5 tok/s |

→ medium→high는 +2pt에 토큰 약 2x라 고난도 역할(slow/designer/vision)에만 사용.
high→xhigh는 +1pt에 추가 1.7x라 기본 상한은 high, 예외적으로 plan만 xhigh.

opus-4.8은 AA Intelligence Index 61.4로 gpt-5.5 xhigh(60)보다 높지만, effort별
독립 점수표는 없다 [S11]. fable-5는 AA 64.9로 그 위이며, AA 측정은 max effort +
fallback 조건 [S12]. OMP의 `:low/:medium/:high` suffix는 모델별 effortMap을 거치므로
동일 벤치의 effort 레벨과 1:1 대응한다고 보면 안 된다 [S9].

## Combination 복귀 플랜 (06-23 적용)

06-23부터 fable-5는 구독 미포함(크레딧 추가 과금 [S7]). Claude 쿼터가 회복되고
구독제만 유지할 때는 fable을 전 역할에서 제거한다. 이때 주 모델을 누구로 둘지에 따라
프로필을 둘로 나눈다.

### `combo-claude`: Claude 메인 + Codex 버스트

`omp/profiles/combo-claude.yml`. 장기 컨텍스트 안정성과 Anthropic 품질을 우선한다.
Codex/GPT는 slow/plan/vision/designer처럼 실패 비용이 큰 버스트 역할에 투입한다.

```yaml
default: anthropic/claude-opus-4-8:low
smol: anthropic/claude-haiku-4-5:minimal
slow: openai-codex/gpt-5.5:high
vision: openai-codex/gpt-5.5:high
plan: openai-codex/gpt-5.5:high
designer: openai-codex/gpt-5.5:high
commit: anthropic/claude-haiku-4-5:off
task: anthropic/claude-sonnet-4-6:medium
```

### `combo-gpt`: Codex/GPT 메인 + Claude 보조

`omp/profiles/combo-gpt.yml`. Claude 쿼터를 아끼면서 GPT를 기본 장기 작업에 둔다.
Claude는 smol/commit/task로 남겨 모델 다양성과 Anthropic 보조 경로를 유지한다.

```yaml
default: openai-codex/gpt-5.5:medium
smol: anthropic/claude-haiku-4-5:minimal
slow: openai-codex/gpt-5.5:high
vision: openai-codex/gpt-5.5:high
plan: openai-codex/gpt-5.5:high
designer: openai-codex/gpt-5.5:high
commit: anthropic/claude-haiku-4-5:off
task: anthropic/claude-sonnet-4-6:medium
```

default 다운시프트 순서(쿼터 압박 정도에 따라): ① opus-4-8:low ② sonnet-4-6:medium
(effortMap 다름 — :low 시프트 없음, medium부터). fable-5는 추가 과금 의사가 생길 때만 복귀.
Anthropic이 "capacity 확보 시 일부 표준 플랜 접근 복원 계획"을 언급했으므로 [S7] 추후 재확인.

주의: `claude-mythos-5`는 카탈로그에 ID가 있지만 **일반 구독/API로 사용 불가** — Project
Glasswing 승인 고객 한정 [S6]. fable-5와 동일 가중치(안전 분류기 3종 차이만 [S6])라
백업으로서의 의미도 없음. *카탈로그 존재 ≠ 호출 가능.*

## 운용 원칙 (구독 내 기준)

1. **모드 선택**: Claude 쿼터 소진 시 GPT only, OpenAI/Codex 쿼터 압박 시 Claude only,
   둘 다 여유가 있으면 `combo-claude` 또는 `combo-gpt`.
2. **장기·복합(default)**: 선택한 모드 안에서 가장 안정적인 상위 모델을 낮은~중간 effort로 둔다.
   adaptive thinking은 필요한 곳에만 컴퓨트 배분 [S5]. (fable-5:low는 무료 윈도우 한정 특례 [S3])
3. **고볼륨(task/smol/commit)**: 반복 서브태스크와 커밋 메시지는 경량 모델. Mythos급을 task에
   쓰면 쿼터 소진 가속 — 무료 윈도우/쿼터 여유에서만 opus 이상 투입.
4. **고추론 버스트(slow/plan)**: 단발 고난도 작업, 설계 결정, 실패 재시도 비용이 큰 작업에만 high.
   xhigh는 gpt-5.5 기준 +1pt에 토큰 +67%라 예외적으로만 쓴다 [S10].
5. **vision**: 이미지 QA는 기본 medium. 실패 비용이 큰 시각 검증만 high.

주의: gpt 계열은 `minimal` 미지원(low부터). `:off`는 effort가 아닌 thinking 비활성로 전 모델 유효.

## 근거와 신빙성

표기: ◎ 공식/1차 · ○ 벤더 발표(이해관계 있음, 독립 재현 없음) · △ 서드파티 집계/일화

- **[S1] ◎ Anthropic 공식 Fable 5 표** — Fable/Mythos 5가 Opus 4.8과 GPT-5.5를
  주요 벤치에서 앞섬: SWE-bench Pro 80.3 / 69.2 / 58.6, FrontierCode Diamond
  29.3 / 13.4 / 5.7, OSWorld-Verified 85.0 / 83.4 / 78.7, HLE no-tools
  59.0 / 49.8 / 41.4, HLE tools 64.5 / 57.9 / 52.2
  ([Anthropic launch](https://www.anthropic.com/news/claude-fable-5-mythos-5)).
  Fable은 일반 공개용 Mythos-class 모델이며, 안전 플래그 시 Opus 4.8 fallback 발생
  (<5% 세션 평균). 공식 출처지만 벤더 발표이므로 독립 재현은 [S12]로 보강.
- **[S2] △ SWE-bench Verified 95.0 주장** — 일부 서드파티는 fable-5 95.0,
  opus-4.8 88.6, gpt-5.5 82.6을 인용하지만 Anthropic 공식 표에서 직접 확인한
  주 지표는 SWE-bench **Pro** 80.3. Verified 95.0은 보조 신호로만 취급.
- **[S3] ○ fable vs opus-4.8 효율 특성** — +20% 정확, 툴콜 -12%, 출력 토큰 2.5x, +30% 느림.
  단일 출처([Databricks](https://www.databricks.com/blog/claude-fable-5-now-available-databricks-fully-governed-through-unity-ai-gateway),
  fable 판매 파트너)의 자체 평가. "quality-first, not an efficiency point" 결론 포함.
- **[S4] △ opus-4.8 토큰 효율** — "같은 지능에 더 적은 스텝·툴콜" (CursorBench, Cursor CEO 증언,
  [vellum](https://www.vellum.ai/blog/claude-opus-4-8-benchmarks-explained)). 정량 수치 없는 일화.
- **[S5] ◎ adaptive thinking** — fable/mythos는 thinking 상시 활성·adaptive 단일 모드, opus-4.8은
  복잡도 따라 자동 배분 ([Anthropic docs](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking),
  [anthropic.com](https://www.anthropic.com/claude/opus)).
- **[S6] ◎ Mythos 5 접근 제한** — 일반 제공 아님, Project Glasswing 승인 고객 한정. fable과 동일
  가중치, 차이는 안전 분류기 ([Anthropic docs](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5),
  [TechCrunch](https://techcrunch.com/2026/06/09/anthropics-claude-fable-5-is-a-version-of-mythos-the-public-can-access-today/)).
- **[S7] ◎ 무료 윈도우** — AA가 Fable 5를 Pro/Max/Team/seat-based Enterprise에
  06-22까지 포함, 06-23부터 credits 필요, 용량 확보 시 subscription access 복원 계획이라고
  정리 ([AA Fable 5](https://artificialanalysis.ai/articles/claude-fable-5-mythos-intelligence-index/)).
  Anthropic 공식 launch도 가격 $10/$50과 일반 공개를 확인 [S1].
- **[S8] ◎ 가격** — fable $10/$50, opus $5/$25, sonnet $3/$15 (M토큰당, 출처 전반 일치;
  fable 배치 $5/$25 [agentpedia](https://agentpedia.codes/blog/claude-fable-5-benchmark-prompting-guide)).
- **[S9] ◎ effort 매핑** — `~/.omp/agent/models.db`의 `thinking.effortMap`/`mode` 필드 + omp://models.md.
  로컬에서 직접 검증 가능.
- **[S10] ◎ gpt-5.5 effort별 독립 측정** — Artificial Analysis가 전 effort 레벨 직접 평가:
  지능지수 xhigh 60 / high 59 / medium 57, Index 평가 토큰 75M / 45M / 22M, 속도는
  medium 48.5 / high 52.4 / xhigh 71.7 tok/s
  ([AA xhigh](https://artificialanalysis.ai/models/gpt-5-5),
  [AA high](https://artificialanalysis.ai/models/gpt-5-5-high),
  [AA medium](https://artificialanalysis.ai/models/gpt-5-5-medium),
  [AA 분석](https://artificialanalysis.ai/articles/openai-gpt5-5-is-the-new-leading-AI-model)).
  medium→high는 +2pt에 출력 토큰 약 2.0x, high→xhigh는 +1pt에 추가 1.7x.
  low/non-reasoning은 미게재.
- **[S11] ◎ opus-4.8 공식/독립 측정** — Anthropic 공식 Opus 4.8 system card의
  SWE-bench Pro 69.2. AA는 Opus 4.8 출시 시 Intelligence Index 61.4, 당시 #1로 평가
  ([Anthropic Opus 4.8](https://www.anthropic.com/news/claude-opus-4-8),
  [AA Opus 4.8](https://artificialanalysis.ai/articles/claude-opus-4-8-analysis-and-benchmarks/)).
  단, fable-5 출시 후 #1은 fable-5로 이동.
- **[S12] ◎ fable-5 독립 측정** — AA가 Anthropic pre-release 평가를 지원했고,
  fable-5를 Intelligence Index 64.9 / #1로 측정. 가까운 non-Anthropic 모델(gpt-5.5)보다
  약 5pt 앞서며, GDPval-AA Elo 1932. 측정 조건은 adaptive reasoning max effort +
  Opus 4.8 fallback; AA Index 전체에서 fallback routing 약 8%, HLE에서 9%
  ([AA Fable 5](https://artificialanalysis.ai/articles/claude-fable-5-mythos-intelligence-index/)).
- **[S13] ◎ OpenAI 공식 GPT-5.5 발표** — OpenAI의 GPT-5.5 공식 벤치 표는 GPT 평가를
  `xhigh` reasoning effort로 실행했다고 명시. 주요 수치: SWE-bench Pro Public 58.6,
  Terminal-Bench 2.0 82.7, Expert-SWE Internal 73.1. OpenAI는 medium을 기본 균형점,
  high를 어려운 reasoning/debugging/planning, xhigh를 deep research·long rollout·hard coding에
  권장한다 ([OpenAI GPT-5.5](https://openai.com/index/introducing-gpt-5-5/)).
