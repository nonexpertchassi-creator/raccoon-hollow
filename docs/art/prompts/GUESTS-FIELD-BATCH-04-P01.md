# GUESTS-FIELD-BATCH-04-P01

## 목적

드묾 등급의 한국 야생동물 5종을 서로 겹치지 않는 긴 몸·뿔·무늬 실루엣으로 제작한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성·키 배경 편집 모드
- 참조: `fox.png`, `badger.png`, `deer.png`
- 오른쪽을 보는 side/three-quarter 걷기 자세
- 따뜻한 flat painted fills, 일정한 짙은 갈색 외곽선, 제한된 명암
- 의상·장신구·소지품·배경·바닥·그림자·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤

## 종별 프롬프트 차이

| 파일 | 실루엣·색 기준 |
|---|---|
| `otter.png` | 낮고 긴 수달 몸, 미색 주둥이·목, 두꺼운 긴 꼬리와 짧은 발 |
| `roe.png` | 노루의 작은 갈래뿔, 붉은 갈색 몸, 흰 엉덩이 반점과 작은 꼬리 |
| `weasel.png` | 족제비의 아주 길고 가는 황갈색 몸, 짧은 다리, 끝이 짙은 꼬리 |
| `wildcat.png` | 한국 살쾡이의 이마선·몸 점무늬·다리 줄무늬와 굵은 고리 꼬리 |
| `goral.png` | 한국 산양의 회갈색 긴 털, 미색 목, 짧게 뒤로 휜 검은 뿔과 발굽 |

## 투명도 처리 기록

- 수달과 족제비는 생성본의 어두운 비네트를 순수 자홍색 키 배경으로 바꾼 뒤 그 색만 제거했다.
- 노루와 살쾡이는 생성본의 무채색 체크 배경 연결 영역만 제거했다.
- 산양은 생성 단계에서 진짜 알파가 출력됐다.

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-04.png`
