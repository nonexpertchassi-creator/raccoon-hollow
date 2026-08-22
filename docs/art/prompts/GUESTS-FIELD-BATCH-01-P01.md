# GUESTS-FIELD-BATCH-01-P01

## 목적

Godot 마을 길에서 64×64로 보이는 손님 5종을 같은 붓과 같은 카메라로 제작한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성 모드
- 참조: `godot/art/guests/magpie.png`, `godot/art/staff/band-work.png`
- 따뜻한 flat painted fills, 일정한 짙은 charcoal-brown outline, 미세한 손그림 질감
- 오른쪽을 보는 side/three-quarter 걷기 자세, 전신 한 마리만
- 의상·모자·소지품·바닥·그림자·배경·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤
- 마스터 생성 뒤 `128×128` RGBA로 축소해 `godot/art/guests/`에 저장

## 종별 프롬프트 차이

| 파일 | 종과 등급 | 실루엣·색 기준 |
|---|---|---|
| `squirrel.png` | 다람쥐 · 흔함 | 밤갈색, 미색 배, 크게 휘는 복슬 꼬리, 소박함 |
| `badger.png` | 오소리 · 드묾 | 낮고 통통한 몸, 회갈색, 코부터 눈을 지나는 두 줄, 짧은 꼬리 |
| `fox.png` | 여우 · 드묾 | 가는 몸, 뾰족귀, 적갈색, 미색 목과 꼬리끝, 짙은 다리 |
| `deer.png` | 한국 물사슴 · 귀함 | 뿔 없음, 큰 둥근 귀, 가는 다리, 황갈색, 작은 송곳니 |
| `boar.png` | 멧돼지 · 귀함 | 단단한 몸, 긴 주둥이, 거친 밤갈색 털, 작은 엄니와 갈라진 발굽 |

## 금지

- 사람처럼 직립한 모든 종, 과장된 아기 비율, 카드 초상 구도
- 한국 물사슴에 뿔 추가
- 오소리를 라쿤처럼 고리 꼬리로 표현
- 배경 체크무늬를 실제 픽셀로 출력

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-01.png`
