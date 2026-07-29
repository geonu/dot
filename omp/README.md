# omp model roles

`config.yml`의 `modelRoles` 운용 노트. 구독제(Anthropic + OpenAI Codex) 기준이므로
토큰 단가가 아니라 **작업 완결까지의 총 토큰**과 **구독 쿼터 여유**가 효율 기준.
모델 존재/effort 메타데이터는 `~/.omp/agent/models.db`, 레벨 문법은 omp://models.md
(`off|minimal|low|medium|high|xhigh`, 모델별 effortMap/budget으로 변환).

## 모드 구분

- **GPT only**: Claude 구독 쿼터를 이미 소진했거나 Anthropic 호출을 의도적으로 막을 때.
- **GPT+GLM**: Claude 쿼터 소진 시 GPT가 오케스트레이션을 맡고 GLM-5.2가 `slow`/`task` worker를 맡는 백업.
- **Claude only**: Claude 구독 쿼터가 충분하고 OpenAI/Codex 쿼터를 아낄 때.
- **combo-claude**: Claude가 장기 컨텍스트의 주 모델, Codex/GPT는 고추론·비전 버스트.
- **combo-gpt**: Codex/GPT가 장기 컨텍스트의 주 모델, Claude는 smol/commit 보조.
- **combo-grok**: Grok이 장기 컨텍스트의 주 모델, Codex/GPT는 고추론·비전 버스트, Claude는 smol/commit 보조.


## 프로필 파일과 tmux 재시작

모델 조합은 `omp/profiles/*.yml`에 같은 이름으로 보관한다. `config.yml`은 현재 기본값
(`gpt` active config)이고, 프로필은 실행 시 `--config ~/.dotfiles/omp/profiles/<profile>.yml`로
overlay한다.

| profile | 파일 | 용도 |
|---------|------|------|
| `gpt` | `omp/profiles/gpt.yml` | Claude 쿼터 소진/Anthropic 차단 시 |
| `gpt-glm` | `omp/profiles/gpt-glm.yml` | Claude 쿼터 소진 시 GPT default + GLM worker |
| `claude` | `omp/profiles/claude.yml` | Claude 쿼터 여유, Codex 쿼터 보호 시 |
| `combo-claude` | `omp/profiles/combo-claude.yml` | Claude default + Codex burst |
| `combo-gpt` | `omp/profiles/combo-gpt.yml` | GPT default + Claude utility/task |
| `combo-grok` | `omp/profiles/combo-grok.yml` | Grok default + Codex burst + Claude utility/task |
| `config` | 없음 | override 없이 현재 `config.yml` 그대로 resume |

tmux 안에서는 `Ctrl-a R`을 누르면 현재 pane에서 실행 중인 OMP 프로세스의 session id를
먼저 읽고, 같은 cwd에서 pane을 respawn한다. 프롬프트 기본값은 `gpt`이며,
`gpt-glm`, `gpt`, `claude`, `combo-claude`, `combo-gpt`, `combo-grok`, `config` 중 하나를 입력하면 **현재 pane의 세션**을 해당
프로필로 이어간다. OMP TUI의 config hot reload가 없고 resume이 세션의 active model을
복원할 수 있어, wrapper가 현재 pane의 `--resume <session-id>`와 provider override를 함께
전달한다. 세션 id 결정 우선순위는 ① pane의 라이브 omp 프로세스(`ps --resume` / 열린
.jsonl`, 새 세션 파일이 보일 때까지 짧게 재시도) → ② pane에 기록해 둔 `@omp_session`
tmux 옵션(omp가 종료돼도 남아 다음 전환에서 같은 대화로 복귀) → ③ pane cwd의 최신
세션(`run-shell`은 pane cwd를 상속하지 않으므로 pane 디렉토리 기준으로 조회)이다. 그래도
세션이 없으면 stale pane 옵션을 비우고 해당 프로필로 새 세션을 띄운다. respawn은 항상 수행되어 pane이 죽지 않는다.

정합성 체크는 `bin/omp-profile-check.sh`로 한다. 이 스크립트는 `omp/config.yml`이
기본 active profile인 `gpt`와 같은 role map인지, `omp/profiles/*.yml`, 이 README의
프로필 목록, `zshrc` profile dispatcher, `tmux.conf`의 `@omp-default-profile`/`@omp-profile-choices`,
save/restore helper의 profile 보존 규칙, 그리고 로컬 `~/.omp/agent/models.db`의 모델/effort
메타데이터를 함께 검증한다. 모델 가이드나 profile 기본값을 바꾸거나 OMP 업데이트 후에는 이 체크를 먼저 돌린다.

## GPT only (Claude 쿼터 소진 대응)

| role     | model                         | 비고 |
|----------|-------------------------------|------|
| default  | openai-codex/gpt-5.6-terra:medium   | 장기·복합 기본. high 대비 토큰 절반 수준에서 -2pt [S10] |
| smol     | openai-codex/gpt-5.4-mini:low | gpt 계열은 `minimal` 미지원 |
| slow     | openai-codex/gpt-5.6-terra:high     | 고추론 버스트. xhigh는 +1pt에 토큰 +67%라 제외 [S10] |
| vision   | openai-codex/gpt-5.6-terra:high     | 이미지 QA 실패 비용이 큰 경우 high |
| plan     | openai-codex/gpt-5.6-terra:xhigh    | 설계·계획은 호출 빈도가 낮고 실패 비용이 커서 OpenAI 공식 xhigh 벤치 조건에 맞춤 [S13] |
| designer | openai-codex/gpt-5.6-terra:high     | UI/디자인 구현 전용 |
| commit   | openai-codex/gpt-5.4-mini:off | thinking 비활성 |
| task     | openai-codex/gpt-5.6-terra:medium   | 병렬 서브태스크 품질 하한 보강. high는 토큰 2x라 미사용 [S10] |

## GPT+GLM (Claude 쿼터 소진 + GLM worker 백업)

`omp/profiles/gpt-glm.yml`. GPT-5.5가 장기 컨텍스트, 실패 비용이 큰 `slow` escalation,
계획, UI/vision을 맡고, GLM-5.2는 별도 Z.ai 쿼터를 쓰는 `smol`/`commit`/`task`
역할을 맡는다. 이렇게 하면 Claude 없이도 OpenAI/GPT 쿼터와 Z.ai/GLM 쿼터를 병행
사용한다. GLM-5.2는 코딩 task에서 Max effort 권장이므로 `task`는 `xhigh`, 사소한
lookup/commit은 `minimal`/`off`로 둔다.

| role     | model                         | 비고 |
|----------|-------------------------------|------|
| default  | openai-codex/gpt-5.5:medium   | Claude-free 오케스트레이터. 순수 `gpt`와 동일 |
| smol     | zai/glm-5.2:minimal           | trivial lookup도 GLM 쿼터로 분산 |
| slow     | openai-codex/gpt-5.5:xhigh    | 실패 비용 큰 escalation은 GPT max |
| vision   | openai-codex/gpt-5.5:high     | GLM-5.2는 text-only |
| plan     | openai-codex/gpt-5.5:xhigh    | 설계 실패 비용이 커서 GPT 유지 |
| designer | openai-codex/gpt-5.5:high     | UI/디자인 구현은 GPT 유지 |
| commit   | zai/glm-5.2:off               | 커밋 메시지도 GLM 쿼터로 분산 |
| task     | zai/glm-5.2:xhigh             | 병렬 코딩 worker는 GLM Max |

## Claude only (Fable 과금 회피)

`omp/profiles/claude.yml`. 06-23 이후 fable-5가 구독 미포함 크레딧 과금으로 전환되는
상황을 기본으로 둔다 [S7]. OpenAI/Codex 쿼터를 보호해야 할 때만 사용한다.

| role     | model                              | 비고 |
|----------|------------------------------------|------|
| default  | anthropic/claude-opus-4-8:medium   | 구독 포함 최상위 Claude. AA 61.4로 GPT-5.5 xhigh보다 높음 [S11] |
| smol     | anthropic/claude-haiku-4-5:minimal | budget 모드 최소 thinking |
| slow     | anthropic/claude-opus-4-8:high     | Claude-only 고추론 버스트 |
| vision   | anthropic/claude-opus-4-8:medium   | 이미지 입력 QA |
| plan     | anthropic/claude-opus-4-8:high     | Claude-only 복합 계획 |
| designer | anthropic/claude-sonnet-5:high   | UI/디자인 구현 전용. sonnet-5는 4.6 대비 $2/$10 + 128K 출력 |
| commit   | anthropic/claude-haiku-4-5:off     | thinking 비활성 |
| task     | anthropic/claude-sonnet-5:medium | 고볼륨 task용. Opus task는 쿼터 소진 가속 |

### `fable-codex`: Fable 계획 + Codex 실행 (06-22까지 임시)

`omp/profiles/fable-codex.yml`. X 사례 [S15]의 라우팅과 DeepSWE [S14]를 반영한
무료 윈도우용 공격 모드다. Fable은 intent 해석·계획·리뷰 품질에 쓰고, 실행 fan-out은
DeepSWE에서 강한 GPT-5.5 xhigh에 맡긴다. 06-23 이후에는 fable 호출이 크레딧 과금이므로
이 프로필을 기본값으로 두지 않는다.

```yaml
default: anthropic/claude-fable-5:low
smol: anthropic/claude-haiku-4-5:minimal
slow: anthropic/claude-fable-5:high
vision: anthropic/claude-fable-5:medium
plan: anthropic/claude-fable-5:high
designer: openai-codex/gpt-5.5:high
commit: anthropic/claude-haiku-4-5:off
task: openai-codex/gpt-5.5:xhigh
```


### 상위 모델 직접 비교 (공식/독립 벤치마크)

| 지표 | fable-5 | opus-4.8 | gpt-5.5 | 신빙성 |
|------|---------|----------|---------|--------|
| SWE-bench Pro | 80.3% | 69.2% | 58.6% | Anthropic 공식 표 [S1] |
| FrontierCode Diamond | 29.3% | 13.4% | 5.7% | Anthropic 공식 표 [S1] |
| OSWorld-Verified | 85.0% | 83.4% | 78.7% | Anthropic 공식 표 [S1] |
| HLE(no tools / tools) | 59.0% / 64.5% | 49.8% / 57.9% | 41.4% / 52.2% | Anthropic 공식 표 [S1] |
| AA Intelligence Index | 64.9 | 61.4 | medium 57 / high 59 / xhigh 60 | Artificial Analysis 독립 측정 [S10][S11][S12] |
| GDPval-AA Elo | 1932 | 1890 | 1769 | Anthropic/AA 공통 [S1][S12] |
| DeepSWE pass@1 / median cost | 미공개 | 미공개 | 70.0% / $5.76 | Datacurve 독립 벤치. fable 수치는 미공개/비공식 유출만 존재 [S14] |

결론: 일반 지능·장기추론 벤치에서는 `fable-5 > opus-4.8 > gpt-5.5` 순서가 가장 강한
신호다. 반면 실제 coding execution 벤치인 DeepSWE에서는 **공식 공개 수치 기준 GPT-5.5
xhigh가 가장 신뢰 가능한 선택지**다 [S14]. AA의 fable-5 측정은 **adaptive max effort +
Opus 4.8 fallback** 조건 [S12]이고, OMP의 `fable-5:low`는 같은 max 조건이 아닐 수 있다.
따라서 role 점수는 벤치마크 순위를 반영한 운용 추정이지, 동일 harness 실측값이 아니다.

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

### 모델 × effort 통합 랭킹 (구독 내)

한 줄 = (모델, OMP effort suffix). effort는 `models.db`의 `efforts`에서 가져온 실제 지원
레벨을 전부 넣는다. **정렬 = SWE-bench Pro 내림차순 → AA Index 내림차순 → 출력 $/Mtok
오름차순** (`#`은 그 랭크). 읽는 법:
- effort 행끼리는 SWE-Pro가 같으므로(모델 단위 측정) AA Index가 타이브레이커다. AA가
  effort별 실측인 모델은 gpt-5.5뿐 [S10]; Claude 계열은 모델 단위 1회 측정값(§)을 최상위
  effort 행에만 싣고 하위 행 AA는 `—`(미측정)다.
- **§ = 모델 단위 1회 측정**(effort별 분해 아님). SWE-Pro는 전부 §. fable/opus AA도 §.
- **내부 effort**: OMP suffix는 `effortMap`을 거친다 — adaptive(fable/opus)는 +1 시프트
  (`xhigh→max`…), sonnet은 `minimal→low`만, haiku는 budget(매핑 없음), gpt는 항등 [S9].
- **cost = $/Mtok `in/out/cacheRead/cacheWrite`**, `models.db` 실측 [S8][S9]. `rel tok`은
  AA Index 평가 전체 토큰 상대비(gpt-5.5만 실측) [S10]. `—` = 미공개/미측정.

| # | model:suffix | 내부 effort | SWE-Pro§ | AA Index | DeepSWE§ | $/Mtok (i/o/cR/cW) | rel tok | role/근거 |
|---|--------------|-------------|----------|----------|----------|--------------------|---------|-----------|
| 1 | fable-5:xhigh | max | 80.3 | 64.9§ | — | 10/50/1/12.5 | — | AA=max+fallback [S12], SWE [S1] |
| 2 | fable-5:high | xhigh | 80.3 | — | — | 10/50/1/12.5 | — | |
| 3 | fable-5:medium | high | 80.3 | — | — | 10/50/1/12.5 | — | |
| 4 | fable-5:low | medium | 80.3 | — | — | 10/50/1/12.5 | — | 무료 윈도우 default 특례 [S3] |
| 5 | fable-5:minimal | low | 80.3 | — | — | 10/50/1/12.5 | — | |
| 6 | opus-4.8:xhigh | max | 69.2 | 61.4§ | — | 5/25/0.5/6.25 | — | AA 모델단위 [S11], SWE [S1] |
| 7 | opus-4.8:high | xhigh | 69.2 | — | — | 5/25/0.5/6.25 | — | claude-only slow/plan; combo-claude default |
| 8 | opus-4.8:medium | high | 69.2 | — | — | 5/25/0.5/6.25 | — | vision |
| 9 | opus-4.8:low | medium | 69.2 | — | — | 5/25/0.5/6.25 | — | |
| 10 | opus-4.8:minimal | low | 69.2 | — | — | 5/25/0.5/6.25 | — | |
| 11 | gpt-5.5:xhigh | xhigh | 58.6 | 60 | 70.0% / $5.76 | 5/30/0.5/0 | 3.4x | plan 전용; DeepSWE xhigh 실측 [S14] |
| 12 | gpt-5.5:high | high | 58.6 | 59 | — | 5/30/0.5/0 | 2.0x | slow/vision/designer |
| 13 | gpt-5.5:medium | medium | 58.6 | 57 | — | 5/30/0.5/0 | 1.0x | default/task 기본 [S10] |
| 14 | gpt-5.5:low | low | 58.6 | — | — | 5/30/0.5/0 | — | AA low 미게재 [S10] |
| 15 | gpt-5.4-nano:xhigh..:low | 항등 | — | — | — | 0.2/1.25/0.02/0 | — | gpt smol/commit; 벤치 비대상 |
| 16 | haiku-4.5:xhigh..:minimal | budget(매핑 없음) | — | — | — | 1/5/0.1/1.25 | — | smol/commit; 벤치 비대상 |
| 17 | sonnet-5:high..:minimal | (minimal→low) | — | — | — | 2/10/0.2/2.5 | — | claude task/designer; effort별 점수 없음 |

읽기 결론: SWE-Pro 순위는 `fable-5(80.3) > opus-4.8(69.2) > gpt-5.5(58.6)`. 단 출력 토큰
단가는 그 반대로 `opus 25 < gpt-5.5 30 < fable 50`이고, gpt-5.5는 cacheWrite=0(캐시 쓰기
무료)이라 장기 agentic 반복 호출에서 유효 단가가 더 눌린다. 그래서 정확도 상한은 fable,
토큰 효율 균형은 opus(default)·gpt-5.5(execution)로 갈린다. 15~17행은 벤치 미공개 유틸
모델이라 출력단가 오름차순으로만 둔다. 이 표는 위 [랭킹 갱신 규약]대로 새 데이터가 나오면
갱신한다. 구독 밖(GLM-5.2/Kimi)은 [오픈웨이트 코딩 모델 검토] 표 참조.

DeepSWE 각주: 표의 DeepSWE 칸은 공식 leaderboard(gpt-5.5 xhigh 70.0% / median $5.76)만
싣는다. fable-5·opus-4.8 칸이 `—`인 건 미측정이 아니라 **공식 미등재**다 — 비공식 X 유출
(fable 70% @ $10.3/task, opus 58% @ $12.6/task, gpt-5.5 70% @ $6.6/task)은 △ 신호라 랭킹
셀로 올리지 않는다. 다만 방향은 본문 결론과 일치한다: 성공률 fable≈gpt-5.5인데 task당 비용은
gpt가 절반 수준 → execution은 gpt-5.5 [S15].

## Combination 복귀 플랜 (06-23 적용)

06-23부터 fable-5는 구독 미포함(크레딧 추가 과금 [S7]). Claude 쿼터가 회복되고
구독제만 유지할 때는 fable을 전 역할에서 제거한다. 이때 주 모델을 누구로 둘지에 따라
프로필을 둘로 나눈다.

### 현재 세팅 · `config`: `gpt` active config

`omp/config.yml`. 새 OMP 세션이 profile wrapper 없이 떠도 기본 active profile인
`gpt`와 같은 role map을 쓴다. `Ctrl-a R`에서 `config`를 고르면 profile overlay 없이도
GPT-only 구성으로 resume한다.

```yaml
default: openai-codex/gpt-5.6-terra:medium
smol: openai-codex/gpt-5.4-mini:low
slow: openai-codex/gpt-5.6-terra:high
vision: openai-codex/gpt-5.6-terra:high
plan: openai-codex/gpt-5.6-terra:xhigh
designer: openai-codex/gpt-5.6-terra:high
commit: openai-codex/gpt-5.4-mini:off
task: openai-codex/gpt-5.6-terra:medium
```
### 현재 세팅 · `combo-claude`: Claude 메인 + Codex 버스트

`omp/profiles/combo-claude.yml`. 장기 컨텍스트 안정성과 Anthropic 품질을 우선한다.
Codex/GPT는 slow/plan/vision/designer처럼 실패 비용이 큰 버스트 역할에 투입한다.

```yaml
default: anthropic/claude-opus-4-8:high
smol: anthropic/claude-haiku-4-5:minimal
slow: openai-codex/gpt-5.6-terra:high
vision: openai-codex/gpt-5.6-terra:high
plan: openai-codex/gpt-5.6-terra:xhigh
designer: openai-codex/gpt-5.6-terra:high
commit: anthropic/claude-haiku-4-5:off
task: openai-codex/gpt-5.6-terra:high
```

### `combo-gpt`: Codex/GPT 메인 + Claude 보조

`omp/profiles/combo-gpt.yml`. Claude 쿼터를 아끼면서 GPT를 기본 장기 작업에 둔다.
Claude는 smol/commit으로 남기고, coding execution 성격의 task는 GPT-5.6-Terra로 유지한다.

```yaml
default: openai-codex/gpt-5.6-terra:medium
smol: anthropic/claude-haiku-4-5:minimal
slow: openai-codex/gpt-5.6-terra:high
vision: openai-codex/gpt-5.6-terra:high
plan: openai-codex/gpt-5.6-terra:xhigh
designer: openai-codex/gpt-5.6-terra:high
commit: anthropic/claude-haiku-4-5:off
task: openai-codex/gpt-5.6-terra:medium
```

### `combo-grok`: Grok 메인 + Codex 버스트 + Claude 보조

`omp/profiles/combo-grok.yml`. xAI 접근이 가능할 때 Grok을 장기 컨텍스트의 기본 모델로 쓰고,
Codex/GPT는 slow/plan/vision/designer의 고추론·비전 역할을 맡는다. Claude는 smol/commit에만 쓴다.

```yaml
default: xai-oauth/grok-4.5:medium
smol: anthropic/claude-haiku-4-5:minimal
slow: openai-codex/gpt-5.6-terra:high
vision: openai-codex/gpt-5.6-terra:high
plan: openai-codex/gpt-5.6-terra:xhigh
designer: openai-codex/gpt-5.6-terra:high
commit: anthropic/claude-haiku-4-5:off
task: openai-codex/gpt-5.6-terra:medium
```

default 다운시프트 순서(쿼터 압박 정도에 따라): ① opus-4-8:low ② sonnet-5:medium
(effortMap 다름 — :low 시프트 없음, medium부터). fable-5는 추가 과금 의사가 생길 때만 복귀.
Anthropic이 "capacity 확보 시 일부 표준 플랜 접근 복원 계획"을 언급했으므로 [S7] 추후 재확인.

주의: `claude-mythos-5`는 카탈로그에 ID가 있지만 **일반 구독/API로 사용 불가** — Project
Glasswing 승인 고객 한정 [S6]. fable-5와 동일 가중치(안전 분류기 3종 차이만 [S6])라
백업으로서의 의미도 없음. *카탈로그 존재 ≠ 호출 가능.*

## 오픈웨이트 코딩 모델 검토 (Kimi K2.7-Code / GLM-5.2)

06-12 Moonshot **Kimi K2.7-Code** [S16], 06-13 Zhipu **GLM-5.2** [S17]가 연달아 공개됐다.
둘 다 coding-first 오픈웨이트에 Claude Code 호환을 표방하지만, **현 구독 조합(Anthropic +
OpenAI Codex) 밖**이라 토큰/쿼터 효율 기준에 그대로 들어오지 않는다. 결론부터: **지금은
어느 프로필에도 편입하지 않는다.** 두 가지가 동시에 막는다 — (a) 별도 유료 접근이 필요해
구독 쿼터 효율 전제를 깨고, (b) 이 README가 쓰는 표준 벤치(SWE-bench Pro, DeepSWE, AA
Index)의 **독립 수치가 아직 없다**.

| 항목 | Kimi K2.7-Code | GLM-5.2 |
|------|----------------|---------|
| 공개일 | 2026-06-12 [S16] | 2026-06-13 [S17] |
| 구조/컨텍스트 | 1T MoE(32B active, 384 expert), 256K | 1M 컨텍스트(`glm-5.2[1m]`), 출력 최대 131,072 |
| OMP 카탈로그 | **없음** — `google-vertex/moonshotai/kimi-k2-thinking-maas`만 존재(K2 thinking, 2.7-Code 아님) [S9] | **있음** — `zai/glm-5.2` (단 `authoritative=0` 정적 카탈로그) [S9] |
| 접근 경로 | Kimi API + Kimi Code CLI(오픈소스 TS/npm), 멤버십 $19~199/mo, Modified MIT 가중치(HF)·OpenRouter/Moonshot 별도 키. Claude Code/Cline/Roo 호환 엔드포인트 [S16] | Z.ai GLM Coding Plan(별도 구독, effort **High/Max** 2단·코딩은 Max 권장) 또는 다음 주 MIT 가중치. Claude Code 호환 [S17] |
| 공개 벤치 | **1차 자체 벤치 델타만** (Kimi Code Bench v2 50.9→62.0 +21.8%, Program Bench +11%, MLS Bench Lite +31.5%, MCP Atlas/Mark/Claw ~+10%, reasoning 토큰 -30% vs K2.6). 표준 SWE-bench Pro/Terminal-Bench/LiveCodeBench **미공개** [S16] | **출시 시 공식 0개** (SWE-bench·LiveCodeBench·AIDER 전부 미공개) [S17] |
| 독립 검증 | 초기 시그널: MCPMark Verified **81.1% > Opus 4.8 76.4**(툴호출/MCP 한정, 모델카드 분석·leaderboard 재실행 아님; raw 코드생성은 Opus 4.8/GPT-5.5 우세). KernelBench-Hard는 K2.6 대비 후퇴(0.222→0.157) [S16] | BridgeBench 추론 스위트 **42.8%**(30태스크, niche). GLM-5 base SWE-bench Verified 77.8 보조 신호 [S17] |

재평가 트리거: ① GLM-5.2/K2.7-Code의 **SWE-bench Pro·DeepSWE·AA Index 독립 수치**가
나오고(현재 나온 MCPMark 81.1·BridgeBench 42.8은 niche 스위트라 이 README의 랭킹 기준이
아니다), ② 사용자가 GLM Coding Plan/Kimi 멤버십 등 별도 구독 의사를 보일 때. 그 시점에
후보가 되는 건 GLM-5.2 쪽이다 — OMP 카탈로그에 ID가 이미 있고(`zai/glm-5.2`), effort가
High/Max 2단이라 OMP effortMap으로 `:high`/상한 suffix에 매핑 가능하며, Claude Code 하네스
호환에 GLM-5.1 대비 추가 과금이 없다 [S17]. 들어온다면 `slow` 같은 단발 고난도·대체 관점
역할 후보가 우선이다. Kimi K2.7-Code는 카탈로그 부재(현 catalog는 K2 thinking뿐) +
표준 벤치 공백 + KernelBench 회귀 신호로 우선순위가 더 낮다. *카탈로그 존재 ≠ 호출 가능*은
mythos-5와 동일하게 적용된다.

## 운용 원칙 (구독 내 기준)

1. **모드 선택**: Claude 쿼터 소진 시 먼저 GPT only, GLM Coding Plan/API가 준비됐고
   고볼륨 worker 분산이 필요하면 `gpt-glm`, OpenAI/Codex 쿼터 압박 시 Claude only,
   06-22까지 Fable 무료 윈도우와 Codex 쿼터가 모두 남아 있으면 `fable-codex`, 이후에는
   `combo-claude` 또는 `combo-gpt`.
2. **장기·복합(default)**: 선택한 모드 안에서 가장 안정적인 상위 모델을 낮은~중간 effort로 둔다.
   adaptive thinking은 필요한 곳에만 컴퓨트 배분 [S5]. (fable-5:low는 무료 윈도우 한정 특례 [S3])
3. **고볼륨(task/smol/commit)**: 반복 서브태스크와 커밋 메시지는 경량 모델이 기본. 다만 coding
   execution 품질이 중요한 프로필은 task를 GPT-5.5나 GLM-5.2로 올린다. `fable-codex`만 xhigh,
   일반 GPT/Combo/GLM worker는 medium~high.
4. **고추론 버스트(slow/plan)**: 단발 고난도 작업, 설계 결정, 실패 재시도 비용이 큰 작업에만 high.
   GPT-5.5의 xhigh는 기본적으로 plan 전용. execution one-shot이 중요할 때만 task xhigh [S14][S15].
5. **vision**: 이미지 QA는 기본 medium. 실패 비용이 큰 시각 검증만 high.

주의: gpt 계열은 `minimal` 미지원(low부터). `:off`는 effort가 아닌 thinking 비활성로 전 모델 유효.

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
`gpt`/`gpt-glm`/`claude`/`fable-codex`/`combo-*` 어디서나 동일하게 적용된다.

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

## 랭킹 갱신 규약 (에이전트가 직접 수행)

이 표들이 곧 "랭킹"이다. 별도 프로그램을 짜지 않는다 — **새 모델/벤치/단가 데이터가 나오면
에이전트가 실시간 리서치로 확인해 이 README를 직접 갱신**한다. 매번 같은 절차를 밟는다:

1. 실시간 리서치로 모델/effort 레벨별 (벤치 점수 · 토큰 비용 · 효율)을 확인한다.
   입력원: `~/.omp/agent/models.db`의 effortMap/budget, AA Intelligence Index·SWE-bench
   Pro·DeepSWE 등 공개 벤치, 구독/크레딧 단가.
2. 출처마다 신빙성 등급(◎/○/△)을 매기고 `## 근거와 신빙성`에 `[S*]`로 추가한다.
   1차 자체 벤치/niche 스위트는 랭킹 근거로 승격하지 않는다(보조 신호로만).
3. 그 근거로 비교 표·role 추천·프로필을 갱신하고, 구독(Anthropic+OpenAI Codex) 안인지
   밖인지 명시한다.
4. `bin/omp-profile-check.sh`로 README·프로필·`models.db` 정합성을 검증한 뒤 커밋한다.

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
- **[S8] ◎ 가격** — fable $10/$50, opus $5/$25, sonnet-5 $2/$10, sonnet-4.6 $3/$15 (M토큰당, `models.db` 실측;
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
- **[S14] ◎ DeepSWE / Datacurve** — contamination-free long-horizon coding benchmark.
  113개 task, 91개 repo, mini-swe-agent 고정. 공식 공개 leaderboard 기준 GPT-5.5 xhigh
  pass@1 70.0%, pass@4 88.3%, median cost $5.76; GPT-5.4 xhigh 55.5%;
  Claude Opus 4.7 max 54.2%; Sonnet 4.6 high 31.6%
  ([DeepSWE](https://deepswe.datacurve.ai/),
  [leaderboard JSON](https://deepswe.datacurve.ai/artifacts/leaderboard.json)).
  비공식 X 유출(Haider, 06-11)은 같은 DeepSWE 하네스에서 fable-5 70% @ $10.3/task,
  gpt-5.5 70% @ $6.6/task, opus-4.8 58% @ $12.6/task로 인용하나 Datacurve 공식 leaderboard에
  미등재이고 cost도 공식 median $5.76과 어긋난다(△, [S15]). mythos-5 수치는 Theo 유튜브 유출뿐.
- **[S15] △ X 운용 사례** — CJ Zafir는 “Fable 5 high planning → Codex 5.5 xhigh execution
  → Fable 5 max review”로 Claude Code limits를 50% 덜 태운다고 보고. Justin Schroeder는
  GPT-5.5 xhigh가 Opus 4.8 low보다 낫다고 주장하면서 UI는 Opus 우세 가능성을 별도 언급.
  Haider(06-11)는 DeepSWE 비공식 유출로 fable-5 70% @ $10.3/task·gpt-5.5 70% @ $6.6/task·
  opus-4.8 58% @ $12.6/task를 공유 — 성공률은 fable≈gpt-5.5지만 task당 비용은 gpt가 약 60%.
  답글에선 fable 점수가 Opus fallback으로 오염됐을 수 있다는 지적도 있음
  ([haider1](https://x.com/haider1/status/2065046388254056944)).
  모두 실사용/전언이라 보조 신호이며, 공식 설정 판단은 [S1][S10][S13][S14]가 우선.
- **[S16] ○/△ Kimi K2.7-Code (Moonshot)** — 2026-06-12 공개, 1T MoE(32B active, 384 expert),
  256K, Modified MIT 가중치(HF). 배포는 Kimi API + 오픈소스 Kimi Code CLI(TS/npm), 멤버십
  $19(Moderato)~199(Vivace)/mo, 6x High-Speed Mode 예고(미정). Claude Code/Cline/Roo 호환
  엔드포인트. 런치 수치는 전부 1차 자체 벤치(Kimi Code Bench v2 50.9→62.0 +21.8%, Program
  Bench +11%, MLS Bench Lite +31.5%, MCP Atlas/Mark/Claw ~+10%, reasoning 토큰 -30% vs K2.6)
  이고 표준 SWE-bench Verified/Pro·Terminal-Bench·LiveCodeBench는 미공개. 초기 독립 시그널은
  MCPMark Verified 81.1%로 Opus 4.8 76.4 상회(툴호출/MCP 한정, 모델카드 분석이지 leaderboard
  재실행 아님; raw 코드생성은 Opus 4.8/GPT-5.5 우세). 다른 독립 테스트(Elliot Arledge,
  KernelBench-Hard)는 K2.6 대비 후퇴(MoE 커널 0.222→0.157), "more honest but not more
  capable". 참고로 K2.6은 SWE-bench Verified 80.2%(Opus 4.7 87.6% 미달)·SWE-bench Pro 58.6%,
  AA Intelligence Index 54
  ([codersera](https://codersera.com/blog/kimi-k2-7-complete-guide-2026/),
  [digitalapplied](https://www.digitalapplied.com/blog/kimi-k2-7-code-release-open-source-coding-model),
  [VentureBeat](https://venturebeat.com/technology/kimi-k2-7-code-cuts-thinking-tokens-30-practitioners-say-benchmarks-dont-check-out),
  [HF 가중치](https://huggingface.co/moonshotai/Kimi-K2.7-Code)).
- **[S17] ○/△ GLM-5.2 (Zhipu/Z.ai)** — 2026-06-13 공개, 1M 컨텍스트(`glm-5.2[1m]`), 출력
  최대 131,072, GLM Coding Plan 전 티어(Lite/Pro/Max/Team), 기존 구독자는 GLM-5.1 대비 추가
  과금 없음, MIT 가중치·standalone API는 다음 주. effort는 **High/Max 2단**(코딩은 Max 권장,
  Z.ai 공식). **출시 시 공식 벤치 0개**(SWE-bench·LiveCodeBench·AIDER 전부 미공개). 독립
  측정으로는 BridgeBench 추론 스위트 42.8%(30태스크, niche 스위트라 SWE-bench/AA Index 대체
  아님)만 존재. 참고: GLM-5 base는 SWE-bench Verified 77.8%(Opus 4.5 80.9·GPT-5.2 80.0 근접,
  당시 오픈소스 최고), GLM-5.1은 Claude Code 하네스에서 Opus 4.6 코딩의 ~94.6% 주장(자체 보고,
  독립 미검증). Claude Code/Cline/OpenCode 등 기본 호환
  ([codersera](https://codersera.com/blog/glm-5-2-release-1m-context-coding-2026/),
  [digitalapplied](https://www.digitalapplied.com/blog/glm-5-2-zai-flagship-coding-plan-release),
  [BridgeBench](https://www.bridgebench.ai/reasoning/glm-5-2)).
