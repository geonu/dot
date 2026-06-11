# omp model roles

`config.yml`의 `modelRoles` 운용 노트. 구독제(Anthropic + OpenAI Codex) 기준이므로
토큰 단가가 아니라 **작업 완결까지의 총 토큰**과 **구독 쿼터 여유**가 효율 기준.
모델 존재/effort 메타데이터는 `~/.omp/agent/models.db`, 레벨 문법은 omp://models.md
(`off|minimal|low|medium|high|xhigh`, 모델별 effortMap/budget으로 변환).

## 현재 세팅: 무료 윈도우 공격 모드 (2026-06-22까지)

fable-5는 2026-06-09 출시~**06-22까지** 유료 구독(Pro/Max/Team/Enterprise)에 추가 비용
없이 포함, **06-23부터 플랜에서 제거**되어 사용 시 API 단가($10/$50)로 크레딧 과금 [S7].
현재 사용량이 정액 한도에 여유가 있어 윈도우 동안 fable/opus를 적극 투입.

| role     | model                              | 비고 |
|----------|------------------------------------|------|
| default  | anthropic/claude-fable-5:low       | API "medium". :low 유지는 레이턴시 때문(fable은 +30% 느림 [S3]) |
| smol     | anthropic/claude-haiku-4-5:minimal | budget 모드 최소 thinking |
| slow     | anthropic/claude-fable-5:high      | API "xhigh". 어려운 단발 작업 최강 [S2] |
| vision   | openai-codex/gpt-5.5:high          | Codex 구독 활용 유지 |
| plan     | anthropic/claude-fable-5:high      | 복합 계획 = fable 본령, 1M ctx |
| designer | openai-codex/gpt-5.5:high          | Codex 구독 활용 유지 |
| commit   | anthropic/claude-haiku-4-5:off     | thinking 비활성 |
| task     | anthropic/claude-opus-4-8:low      | opus 적극 투입 슬롯. adaptive thinking [S5] |

## 복귀 플랜 (06-23 적용)

06-23부터 fable-5는 구독 미포함(크레딧 추가 과금 [S7]). 구독제만 유지할 것이므로
fable을 전 역할에서 제거하고, 구독 포함 최상위인 opus-4-8을 default로 승격.

```yaml
# 구독 내 분산 모드: 버스트는 Codex로, Anthropic 쿼터는 default 전용 보호
default: anthropic/claude-opus-4-8:low      # 구독 포함 최상위. adaptive thinking
slow: openai-codex/gpt-5.5:high
plan: openai-codex/gpt-5.5:xhigh
task: anthropic/claude-sonnet-4-6:medium    # 고볼륨은 경량으로 복귀
# smol/vision/designer/commit 그대로
```

default 다운시프트 순서(쿼터 압박 정도에 따라): ① opus-4-8:low ② sonnet-4-6:medium
(effortMap 다름 — :low 시프트 없음, medium부터). fable-5는 추가 과금 의사가 생길 때만 복귀.
Anthropic이 "capacity 확보 시 일부 표준 플랜 접근 복원 계획"을 언급했으므로 [S7] 추후 재확인.

주의: `claude-mythos-5`는 카탈로그에 ID가 있지만 **일반 구독/API로 사용 불가** — Project
Glasswing 승인 고객 한정 [S6]. fable-5와 동일 가중치(안전 분류기 3종 차이만 [S6])라
백업으로서의 의미도 없음. *카탈로그 존재 ≠ 호출 가능.*

## 운용 원칙 (구독 내 기준)

1. **장기·복합(default)**: 구독 포함 최상위 Claude를 낮은 effort로 — adaptive thinking이
   필요한 곳에만 컴퓨트 배분 [S5]. (fable-5:low는 무료 윈도우 한정 특례 [S3])
2. **고볼륨(task/smol/commit)**: 평시엔 경량 Claude(sonnet/haiku) [S3]. Mythos급을 task에
   쓰면 쿼터 소진 가속 — 무료 윈도우/쿼터 여유에서만 opus 이상 투입.
3. **고추론 버스트(slow/plan)**: 평시엔 Codex로 오프로드해 Anthropic 쿼터 보호.
4. effort는 한계효용 기준. vision은 이미지 QA 한계효용이 낮아 high.

## 프리셋 B: GPT 메인 + Claude 보조 (역구성)

```yaml
modelRoles:
  default: openai-codex/gpt-5.5:medium
  smol: openai-codex/gpt-5.4-nano:low
  slow: anthropic/claude-opus-4-8:high     # 무료 윈도우 중엔 fable-5:high 가능
  vision: openai-codex/gpt-5.5:high
  plan: anthropic/claude-opus-4-8:xhigh    # 무료 윈도우 중엔 fable-5:high 가능
  designer: anthropic/claude-sonnet-4-6:high
  commit: openai-codex/gpt-5.4-nano:off
  task: openai-codex/gpt-5.4:medium
```

주의: gpt 계열은 `minimal` 미지원(low부터). `:off`는 effort가 아닌 thinking 비활성로 전 모델 유효.

## 근거와 신빙성

표기: ◎ 공식/1차 · ○ 벤더 발표(이해관계 있음, 독립 재현 없음) · △ 서드파티 집계/일화

- **[S1] ○ SWE-bench 점수** — fable-5 95.0 (Verified) / 80.0~80.3 (Pro), opus-4.8 88.6 / 69.2.
  Anthropic 시스템 카드 수치의 재인용이며 독립 재현 아님. Pro 점수가 출처 간 80.0
  ([llm-stats](https://llm-stats.com/blog/research/claude-fable-5-review)) vs 80.3
  ([truefoundry](https://www.truefoundry.com/blog/claude-fable-5-api-benchmarks-pricing-how-to-use-it)) 불일치.
  Verified는 천장 근접이라 Pro 격차(+10.8pt)가 더 의미 있는 신호라는 해석도 동일 출처.
- **[S2] △ gpt-5.5 대비** — SWE-Pro 58.6
  ([vellum](https://www.vellum.ai/blog/claude-fable-5-and-mythos-5-benchmarks-explained)).
  ⚠️ 같은 58.6이 다른 집계([cloudzero](https://www.cloudzero.com/blog/claude-opus-4-8-pricing/))에선
  sonnet-4.6 점수로 표기됨 — 교차 출처 불일치, 절대값보다 순위(fable > opus > gpt-5.5)만 신뢰.
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
- **[S7] △ 무료 윈도우** — 06-09~06-22 유료 플랜 무료 포함, 06-23부터 플랜 제거·크레딧 과금($10/$50),
  capacity 확보 시 일부 복원 계획 ([apidog](https://apidog.com/blog/how-to-use-claude-fable-5-for-free/),
  [yellow.com](https://yellow.com/news/claude-fable-5-free-until-june-22),
  [BleepingComputer](https://www.bleepingcomputer.com/news/artificial-intelligence/anthropic-rolls-out-claude-fable-5-but-its-available-for-a-limited-time/)).
  Anthropic 공식 공지 원문은 미확보 — 날짜는 06-22 종료로 복수 출처 일치.
- **[S8] ◎ 가격** — fable $10/$50, opus $5/$25, sonnet $3/$15 (M토큰당, 출처 전반 일치;
  fable 배치 $5/$25 [agentpedia](https://agentpedia.codes/blog/claude-fable-5-benchmark-prompting-guide)).
- **[S9] ◎ effort 매핑** — `~/.omp/agent/models.db`의 `thinking.effortMap`/`mode` 필드 + omp://models.md.
  로컬에서 직접 검증 가능.
