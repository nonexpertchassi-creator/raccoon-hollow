# GUESTS-FIELD-BATCH-02-P01

## 목적

진귀·영물·신수 등급의 필드 손님 5종을 제작해 작은 스프라이트에서도 등급 차이가
장식이 아닌 자세·실루엣·무늬 정리로 읽히는지 시험한다.

## 공통 생성 기준

- Built-in image generation, 정밀 오브젝트 생성·배경 추출 편집 모드
- 참조: 1차 손님 필드 초안의 `boar.png`, `deer.png`, `fox.png`, `magpie.png`
- 오른쪽을 보는 side/three-quarter 걷기 자세, 전신 한 마리
- 따뜻한 flat painted fills, 일정한 짙은 갈색 외곽선, 제한된 부드러운 명암
- 의상·장신구·광효과·소지품·배경·바닥·그림자·문자·UI 없음
- 진짜 투명 알파, 여백 최소, 발끝을 아래 변에 맞춤

## 종별 프롬프트 차이

| 파일 | 등급 | 실루엣·색 기준 |
|---|---|---|
| `bear.png` | 진귀 | 네 발의 무거운 갈색 곰, 넓은 어깨와 큰 발, 부드러운 표정 |
| `turtle.png` | 진귀 | 낮은 민물거북, 올리브빛 피부와 읽기 쉬운 등딱지 판무늬 |
| `crane.png` | 영물 | 두루미의 긴 목·다리, 미색 몸과 검은 목·날개끝, 작은 붉은 정수리 |
| `ox.png` | 영물 | 밤갈색 일소, 넓은 몸, 완만하게 위로 휘는 상아빛 뿔 |
| `tiger.png` | 신수 | 민화처럼 순하지만 위엄 있는 한국 호랑이, 단순하고 강한 줄무늬 |

## 투명도 처리 기록

- 두루미와 호랑이는 생성 편집에서 배경을 실제 알파로 분리했다.
- 소는 배경 추출 편집이 체크무늬를 두 차례 남겨, 생성된 전경은 유지한 채 연결된
  무채색 배경만 기계적으로 제거했다. 창작적 재도색은 하지 않았다.

## 출력

- 마스터: `docs/art/generated/guests/GUEST-<ID>-V0.1-master.png`
- 런타임: `godot/art/guests/<id>.png`
- 축소 보관본: `docs/art/generated/guests/<id>-runtime.png`
- QA: `docs/art/qa/guests-field-batch-02.png`
