# 04. Asset List

> **2026-08-22 안내:** 이 문서는 초기 HTML 마을/Blueprint 기준의 기획 기록이다.
> 최신 게임은 Godot으로 전환됐고 자동 주문 목록은 `필수 170장 + 선택 110장`을 가리킨다.
> 확인 기준은 Claude 브랜치 `5dacb82`, 현재 필수 상태는 `확정 0 / 초안 101 / 없음 69`이다.
> 필수에는 물건 80장·손님 필드 30장·카드 1단 30장·좌판 10장·뽑기/룰렛 UI 3장이 포함되고, 선택에는 성장 카드 90장과 전용 점장 20장이 포함된다.
> 직원 8장, 점장·촌장 6장, 손님 30장(토끼 구규격 포함), 손님 카드 1단 30장, 뽑기·룰렛 3장, 상호작용 3장, 물건 21장은 초안으로 들어왔지만 파일 존재만으로 확정하지 않는다.
> 현재 제작 순서와 실제 이미지는 [IMAGE_ARCHIVE.md](./IMAGE_ARCHIVE.md)를 우선한다.

## 상태 기준

- 기획 상태: `Decision`, `Hypothesis`, `Locked`
- 제작 상태: `Not started`, `Prompt ready`, `Generated`, `Implemented`, `Revision`, `Approved`, `Rejected`

## A-0. Game Integration — 현재 구현

| ID | 대상 | 기획 상태 | 제작 상태 | 비고 |
|---|---|---|---|---|
| UI-MAP-001 | 상호작용 가능한 세로형 마을 맵 | Hypothesis | Implemented | 실제 390×844 검증, 사용자 검토 대기 |
| UI-BLD-CSS-001 | 상태 기반 CSS 건물 컴포넌트 | Hypothesis | Implemented | 영업/다음 복구/잠김, 제작 이미지로 교체 예정 |
| UI-CHAR-CSS-001 | 작은 점주 DOM 실루엣 | Hypothesis | Implemented | 임시 표현, 최종 스프라이트 아님 |
| UI-PATH-001 | 복구 진행선 역할의 흙길 | Hypothesis | Implemented | 가게 상태 변화와 함께 검증 |
- 승인 상태는 이미지 단위로 [05_GENERATION_LOG.md](./05_GENERATION_LOG.md)에 근거를 남긴다.

## A. Blueprint V0.1 — 승인 범위

| ID | 에셋 | 수량 | 기획 상태 | 제작 상태 | 비고 |
|---|---|---:|---|---|---|
| BP-001 | 통합 Art Concept Blueprint 장면 | 1 | Decision | Approved | P01 사용자 승인, LOG-BP-001 |
| CH-001 | 한국 너구리 점주 | 1 | Decision + Hypothesis | Generated | V0.1 전신복식·V0.2 무복식은 Revision, V0.3 짧은 앞치마 make/sell 현재 후보 |
| CH-002 | 손님 동물 | 2~3 | Hypothesis | Not started | 종 구성 미승인 |
| ENV-001 | 굽은 흙길 | 1 | Hypothesis | Not started | 중앙 동선 시험 |
| BLD-BASE-01 | 복구된 기본 상점 | 1 | Decision + Hypothesis | Not started | 전문 업종 특징 없음 |
| BLD-RUIN-01 | 수선 가능한 폐허 | 1 | Decision + Hypothesis | Not started | BLD-BASE-01과 같은 건축 DNA |
| PROP-001 | 장독/옹기 묶음 | 1 | Decision + Hypothesis | Not started | 종류는 합의, 2~3개 배치는 검증 필요 |
| PROP-002 | 지게 | 1 | Decision + Hypothesis | Not started | 종류는 합의, 단일 배치는 검증 필요 |
| PROP-003 | 광주리 | 1~2 | Decision + Hypothesis | Not started | 종류는 합의, 수량은 검증 필요 |
| PROP-004 | 멍석 | 0~1 | Decision + Hypothesis | Not started | 종류는 합의, 사용 여부는 검증 필요 |
| ENV-002 | 낮은 담장 | 1~2조각 | Decision + Hypothesis | Not started | 요소는 합의, 배치와 길이는 검증 필요 |
| ENV-003 | 마른 풀/작은 녹색 식생 | 소량 | Hypothesis | Not started | Recovery 대비용 |

## B. Blueprint 승인 직후

| ID | 에셋 | 기획 상태 | 선행 조건 |
|---|---|---|---|
| CH-SHEET-01 | 점주 게임 스케일 턴어라운드 | Hypothesis | BP-001 승인 완료, 다음 제작 대상 |
| CH-POSE-01 | 점주 기본 작업 포즈 3종 | Locked | CH-SHEET-01 승인 |
| BLD-SHEET-01 | 기본 건물 정면/측면 기준 | Locked | CH-SHEET-01 승인 |
| BLD-STATE-01 | 폐허/수선/영업 상태 시트 | Locked | BLD-SHEET-01 승인 |
| PROP-SHEET-01 | 공통 한국 생활소품 시트 | Locked | BLD-SHEET-01 승인 |

## C. 향후 상점 큐 — 현재 제작 금지

| ID | 후보 | 상태 | 비고 |
|---|---|---|---|
| SHOP-001 | 첫 전문 상점 1종 | Locked | 기본 건물 시트 승인 후 업종 선택 |
| SHOP-002 | 대장간 | Locked | 디자인 금지 |
| SHOP-003 | 붓가게 | Locked | 디자인 금지 |
| SHOP-004 | 종이가게 | Locked | 디자인 금지 |
| SHOP-005 | 도자기가게 | Locked | 디자인 금지 |
| SHOP-006 | 약재상 | Locked | 디자인 금지 |

## 업데이트 규칙

1. 에셋이 생성되면 제작 상태를 `Generated`로 바꾸고 로그 ID를 연결한다.
2. 이미지가 반려되면 에셋 자체를 삭제하지 않고 `Revision` 또는 `Rejected`로 표시한다.
3. 하나의 시안에서 새로 발견한 규칙은 곧바로 `Decision`으로 바꾸지 않는다.
4. 승인된 결과에서 반복 사용 가능한 기준만 관련 문서에 승격한다.
