# GUESTS-FIELD-BATCH-05-P01

## 목적

귀함·진귀 등급 5종의 자연 무늬를 64px에서 뭉치지 않는 큰 색면으로 정리한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성 모드
- 참조: 기존 담비 계열·조류·큰 고양잇과 필드 초안
- 오른쪽을 보는 side/three-quarter 걷기 자세
- 따뜻한 flat painted fills, 일정한 짙은 갈색 외곽선, 제한된 명암
- 의상·장신구·광효과·소지품·배경·바닥·그림자·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤

## 종별 프롬프트 차이

| 파일 | 실루엣·색 기준 |
|---|---|
| `marten.png` | 담비의 초콜릿빛 머리·다리·꼬리와 넓은 황금빛 목·어깨 |
| `mandarin.png` | 원앙 수컷의 밤색 볏·미색 얼굴선·청록 정수리·자주 가슴·주황 돛깃 |
| `wolf.png` | 늑대의 큰 발·넓은 주둥이·긴 다리·낮게 든 굵은 회갈색 꼬리 |
| `egret.png` | 백로의 온통 미색인 몸, 얕은 S자 목, 노란 부리, 검은 긴 다리 |
| `leopard.png` | 표범의 큰 어깨·앞발과 적은 수의 큰 장미무늬, 굵고 긴 꼬리 |

## 투명도 처리 기록

- 담비와 표범은 생성본의 무채색 체크 배경 연결 영역만 제거했다.
- 원앙·늑대·백로는 생성 단계에서 진짜 알파가 출력됐다.

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-05.png`
