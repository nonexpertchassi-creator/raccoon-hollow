# UI-GACHA-BATCH-01-P01

## 목적

뽑기와 룰렛 연출에 코드가 바로 연결할 수 있는 정지 그림 2장을 만든다. 등급 빛, 글자, 보상, 회전은 그림에 굽지 않고 코드가 얹는다.

## 카드 뒷면 `ui/back.png`

- 512×768, 2:3 세로 카드
- 한지 바탕, 숯빛 이중 테두리, 절제된 황동 모서리
- 중앙에는 기와 지붕마루와 복슬한 너구리 꼬리를 합친 단순 문장
- 잎 장식과 종이 엮임 무늬만 약하게 사용
- 글자·숫자·별·등급색·광효과 없음
- 둥근 카드 바깥은 투명 알파

## 룰렛 `ui/wheel.png`

- 512×512, 정면 원형
- 정확히 같은 크기의 12칸
- 한지 미색·단청 적색·황토색·연한 녹색을 반복
- 짙은 목재 테두리, 칸마다 황동 못 하나, 엽전형 중심축
- 보상 그림·문자·숫자·바늘·광효과 없음
- 원 바깥은 투명 알파

## 출력

- 마스터: `docs/art/generated/cards/UI-CARD-BACK-V0.1-master.png`, `docs/art/generated/ui/UI-WHEEL-V0.1-master.png`
- 런타임: `godot/art/ui/back.png`, `godot/art/ui/wheel.png`
- 축소 보관본: `docs/art/generated/cards/back-runtime.png`, `docs/art/generated/ui/wheel-runtime.png`
- QA: `docs/art/qa/ui-gacha-batch-01.png`
