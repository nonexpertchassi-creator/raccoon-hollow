# 너구리 만물상 — Art Project

모바일 방치형/타이쿤 게임 「너구리 만물상 (Raccoon General Store)」의 아트 기준과 이미지 생성 이력을 관리한다.

## 현재 단계

- 현재 게이트: `Art Concept Blueprint V0.1` 승인 완료
- 현재 상태: `Approved — LOG-BP-001`
- 승인 이미지: [generated/BP-V0.1-P01.png](./generated/BP-V0.1-P01.png)
- 현재 게임 구현: Godot 전환 진행 중 — `5dacb82` 기준 가게 10채·30종 손님·카드 뽑기·룰렛까지 확장
- 현재 그림 현황: 필수 170장 중 초안 151장, 확정 0장, 없음 19장
- 다음 목표: 남은 물건 9장과 좌판 10장을 5장 단위로 제작하고 실제 표시 크기를 검수
- 선택 범위: 손님 성장 카드 90장과 가게별 전용 점장 20장

## 문서 지도

1. [00_ART_BLUEPRINT.md](./00_ART_BLUEPRINT.md) — 최상위 시각 기준, V0.1 구성, 생성 프롬프트, 승인 게이트
2. [01_CHARACTER.md](./01_CHARACTER.md) — 한국 너구리 점주와 플레이 스케일 기준
3. [02_ENVIRONMENT.md](./02_ENVIRONMENT.md) — 마을, 건축, 길, 생활소품 기준
4. [03_BUILDINGS.md](./03_BUILDINGS.md) — Blueprint 승인 후 상점별 디자인을 기록할 잠금 문서
5. [04_ASSET_LIST.md](./04_ASSET_LIST.md) — 현재 범위와 후속 에셋 큐
6. [05_GENERATION_LOG.md](./05_GENERATION_LOG.md) — 생성 결과, 승인/반려, 원인 및 규칙 수정 기록
7. [06_GAME_INTEGRATION.md](./06_GAME_INTEGRATION.md) — 실제 게임 화면 구조와 제작 에셋 연결 계획
8. [image-archive.html](./image-archive.html) — 실제 이미지와 필수 170장 + 선택 110장을 함께 보는 시각 장부
9. [IMAGE_ARCHIVE.md](./IMAGE_ARCHIVE.md) — 시각 장부의 판단 근거와 텍스트 기록

## 상태 언어

- `Discussion` — 아직 선택지를 비교하거나 문제를 정의하는 단계
- `Hypothesis` — 이미지로 시험할 구체적 가정. 승인 전에는 다음 생성의 참고값일 뿐 확정 규칙이 아님
- `Decision` — 이미 합의되었거나 이미지 검수에서 승인된 규칙
- `Locked` — 선행 게이트 승인 전에는 작업하지 않는 범위

## 작업 원칙

1. 모든 생성은 [00_ART_BLUEPRINT.md](./00_ART_BLUEPRINT.md)의 현재 승인 규칙에서 시작한다.
2. 새로 시도하는 값은 `Hypothesis`로 기록하고 이미지 승인 뒤에만 `Decision`으로 승격한다.
3. 실패한 이미지는 삭제하듯 잊지 않고 [05_GENERATION_LOG.md](./05_GENERATION_LOG.md)에 실패 원인과 다음 수정값을 남긴다.
4. 한 이미지의 문제를 임시 문구로만 때우지 않는다. 반복 가능성이 있으면 해당 기준 문서를 수정한다.
5. `V0.1 승인 완료 → 캐릭터 시트 → 기본 건물 → 폐허/복구 단계 → 상점 1종 → 나머지 상점` 순서를 지킨다.
