# GUESTS-FIELD-BATCH-03-P01

## 목적

흔함 등급 손님 5종을 소박하고 즉시 알아볼 수 있는 필드 실루엣으로 제작한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성·배경 추출 편집 모드
- 참조: `magpie.png`, `squirrel.png`, `turtle.png`
- 오른쪽을 보는 side/three-quarter 걷기 또는 걷기 직전 자세
- 따뜻한 flat painted fills, 일정한 짙은 갈색 외곽선, 흔함 등급답게 무늬 단순화
- 의상·장신구·소지품·배경·바닥·그림자·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤

## 종별 프롬프트 차이

| 파일 | 실루엣·색 기준 |
|---|---|
| `sparrow.png` | 밤색 정수리, 미색 뺨과 배, 검은 뺨점·턱받이, 짧은 부리와 꼬리 |
| `frog.png` | 낮은 올리브빛 몸, 접힌 뒷다리, 앞으로 뻗은 긴 발가락 |
| `mole.png` | 벨벳빛 짙은 갈색, 긴 코, 작은 눈, 넓은 분홍빛 굴착 앞발 |
| `hedgehog.png` | 낮고 둥근 몸, 짧게 단순화한 갈색·미색 가시, 뾰족한 얼굴 |
| `duck.png` | 한국 흰뺨검둥오리 계열, 갈색 깃, 눈선, 노란 끝의 짙은 부리, 물갈퀴 |

## 투명도 처리 기록

- 두더지와 고슴도치는 배경 추출 편집 뒤 남은 무채색 체크 배경만 연결 영역으로 제거했다.
- 오리는 검은 배경 분리가 실패해 생성 편집으로 순수 자홍색 키 배경을 만든 뒤 그 색만 제거했다.
- 동물의 창작 요소나 외곽선은 후처리에서 다시 그리지 않았다.

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-03.png`
