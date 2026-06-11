# omp model roles

`config.yml`의 `modelRoles` 운용 노트. 구독제(Anthropic + OpenAI Codex) 기준이므로
토큰 단가가 아니라 **작업 완결까지의 총 토큰**과 **구독 쿼터 여유**가 효율 기준.
모델 존재/effort 메타데이터는 `~/.omp/agent/models.db`, 레벨 문법은 omp://models.md
(`off|minimal|low|medium|high|xhigh`, 모델별 effortMap/budget으로 변환).

## 현재 세팅: 무료 윈도우 공격 모드 (~2026-06-23)

fable-5가 6/23까지 추가 비용 없이 제공되고 현재 사용량이 정액 한도에 여유가 있어,
분산 원칙 대신 fable/opus를 적극 투입 중. **6/23 이후 아래 "복귀 플랜" 적용.**

| role     | model                              | 비고 |
|----------|------------------------------------|------|
| default  | anthropic/claude-fable-5:low       | API "medium". :low 유지는 레이턴시 때문(fable은 +30% 느림) |
| smol     | anthropic/claude-haiku-4-5:minimal | budget 모드 최소 thinking |
| slow     | anthropic/claude-fable-5:high      | API "xhigh". 어려운 단발 작업 최강(SWE-Pro 80.3) |
| vision   | openai-codex/gpt-5.5:high          | Codex 구독 활용 유지 |
| plan     | anthropic/claude-fable-5:high      | 복합 계획 = fable 본령, 1M ctx |
| designer | openai-codex/gpt-5.5:high          | Codex 구독 활용 유지 |
| commit   | anthropic/claude-haiku-4-5:off     | thinking 비활성 |
| task     | anthropic/claude-opus-4-8:low      | opus 적극 투입 슬롯. adaptive thinking |

## 복귀 플랜 (6/23 무료 윈도우 종료 시 적용)

6/23 이후 fable-5는 **구독 미포함**(정액제 위에 추가 과금). 구독제만 유지할 것이므로
fable은 전 역할에서 제거하고, 구독 포함 최상위인 opus-4-8을 default로 승격.

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

주의: `claude-mythos-5`는 카탈로그에 ID가 있지만 **일반 구독으로 사용 불가**
(Project Glasswing 승인 고객 한정). fable-5와 동일 가중치 모델(안전 분류기 차이만)이라
백업으로서의 의미도 없음 — 백업 목록에서 제외.

## 운용 원칙 (구독 내 기준)

1. **장기·복합(default)**: 구독 포함 최상위 Claude를 낮은 effort로 — adaptive thinking이
   필요한 곳에만 컴퓨트 배분. (fable-5:low는 무료 윈도우 한정 특례: opus-4.8:high 대비
   +20% 정확·툴콜 -12%, 단 구독 미포함이라 6/23 이후 제외)
2. **고볼륨(task/smol/commit)**: 평시엔 경량 Claude(sonnet/haiku). Mythos급을 task에
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

## 근거

- SWE-Bench Pro: fable-5 80.3 / opus-4.8 69.2 / gpt-5.5 58.6 (vellum.ai)
- fable-5 vs opus-4.8: +20% 정확, 툴콜 -12%, 출력 토큰 2.5x, +30% 느림 — 복합 장기
  작업에서만 총 토큰 우위 (databricks.com, finout.io)
- fable-5/mythos-5는 Anthropic 첫 Mythos-class(동일 가중치, 안전 분류기 차이) —
  opus의 다음 메이저 세대. mythos-5는 Glasswing 한정 (vellum.ai, platform.claude.com)
- 고볼륨·정형 워크플로는 opus-4.8/sonnet-4.6 권장 (finout.io)
