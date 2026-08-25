# GUESTS-FIELD-BATCH-06-P01

## 목적

필드 손님 목록의 마지막 3종을 채우고, 진귀·영물 등급도 64px에서 종과 성격이 먼저 읽히게 한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성 모드
- 참조: 기존 노루·산양·곰·호랑이 필드 초안의 크기와 외곽선
- 오른쪽을 보는 side/three-quarter 걷기 자세
- 따뜻한 flat painted fills, 일정한 짙은 갈색 외곽선, 제한된 명암
- 의상·장신구·소지품·배경·바닥·그림자·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤

## 종별 프롬프트 차이

| 파일 | 실루엣·색 기준 |
|---|---|
| `muskdeer.png` | 뿔 없는 작은 사슴, 큰 둥근 귀, 짙은 갈색 몸, 아래로 보이는 짧은 송곳니 두 개 |
| `moonbear.png` | 검갈색의 단단한 곰 몸, 둥근 귀와 큰 발, 가슴의 넓은 미색 반달 |
| `haetae.png` | 청회색 사자형 몸, 짧은 외뿔, 큰 덩어리로 말린 갈기와 꼬리 술 |

## 투명도 처리 기록

- 사향노루와 해태는 생성본의 무채색 체크 배경 연결 영역만 제거했다.
- 반달곰은 생성 단계에서 진짜 알파가 출력됐다.

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-06.png`
