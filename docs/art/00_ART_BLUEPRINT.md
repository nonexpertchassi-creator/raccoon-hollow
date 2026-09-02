# 00. Art Concept Blueprint

## 문서 상태

- 프로젝트: 너구리 만물상 (Raccoon General Store)
- 버전: `V0.1-approved`
- 상태: `Approved — LOG-BP-001`
- 업데이트: `2026-08-18`
- 현재 산출물: 한 장짜리 Art Concept Blueprint 이미지 + 이 문서
- 현재 게이트: `Complete`
- 승인 이미지: [BP-V0.1-P01.png](./generated/BP-V0.1-P01.png)

## 1. North Star

> 쇠락했던 조선 후기풍 서민 마을이 너구리 점주가 상점을 복구하고 손님을 맞으며 다시 따뜻하고 활기찬 생활 공간으로 살아나는, 작고 읽기 쉬운 모바일 타이쿤 세계.

생성 프롬프트용 영문 앵커:

> A cozy mobile idle tycoon game world inspired by the everyday life of a late-Joseon Korean commoners' village, where a small raccoon dog shopkeeper restores a faded village into a warm and lively marketplace.

이 문장은 역사 재현을 요구하지 않는다. 핵심은 `Recovery / Revival`, 한국 서민 생활의 단서, 모바일 플레이 화면에서의 명료성이다.

---

## 2. Discussion

### D-01. 한 장 안에서 무엇을 보여줄 것인가

V0.1은 완성된 게임 화면도, 여러 상점의 콘셉트 모음도 아니다. 다음 항목을 한 번에 비교 가능한 최초 기준 이미지다.

- 전체 플레이 화면의 분위기
- 건물 : 캐릭터 : 생활소품의 상대 크기
- 한국 너구리 점주의 실루엣과 종 구분
- 폐허와 복구된 기본 상점의 대비
- 건축과 생활소품이 만드는 한국성
- 화면이 중국풍·일본풍·일반 판타지 마을로 이탈하지 않는지

### D-02. DO/DON'T를 이미지에 어떻게 포함할 것인가

이미지 안에는 텍스트, UI, 워터마크, 테두리를 넣지 않기로 했다. 따라서 V0.1에서는 금지 요소를 실제로 그린 비교 패널보다, **목표 장면만 시각화하고 DO/DON'T는 이 문서의 검수 규칙으로 운용**하는 편이 이미지 오염과 잘못된 스타일 학습을 줄일 가능성이 높다.

이 운용 방식은 아직 `Decision`이 아니라 아래 가설 H-06으로 검증한다.

---

## 3. Hypothesis — V0.1에서 검증할 값

아래 값은 첫 이미지의 구성안이며 승인 전에는 확정 규칙이 아니다.

| ID | 가설 | 검증 질문 |
|---|---|---|
| H-01 | 9:16 세로 화면 안에서 고정된 상·중·하 구획 없이 자연스러운 플레이 공간을 구성한다. | 좁은 가로폭에서도 카메라와 거리감이 즉시 읽히는가? |
| H-02 | 폐허와 복구 상점을 같은 축척으로 보여주되 정확한 좌우·상하 위치는 생성 과정에서 탐색한다. | 두 건물이 비교 패널처럼 갈라지지 않으면서 Recovery 대비가 보이는가? |
| H-03 | 흙길이 두 건물과 손님 동선을 연결하되 정확한 시작점과 진행 방향은 확정하지 않는다. | 동선과 상업 활동이 자연스럽게 읽히는가? |
| H-04 | 보이는 건물 높이를 점주 높이의 약 4배, 문 높이를 점주 높이의 약 1.7배로 시작한다. | 캐릭터가 너무 크거나 미니어처처럼 작지 않은가? |
| H-05 | 손님은 토끼·들쥐·작은 토종개 계열 중 2~3마리를 단순 실루엣으로 시험한다. | 점주보다 시선을 빼앗지 않으면서 마을이 살아 보이는가? |
| H-06 | 한 이미지에는 좋은 기준만 그리고, DO/DON'T는 문서 검수표로 분리한다. | 이미지가 깔끔하면서도 판정에 충분한가? |
| H-07 | 장독, 지게, 광주리, 멍석 중 3~4개만 중경에 배치한다. | 한국성이 읽히되 소품 과밀이 생기지 않는가? |
| H-08 | 폐허는 붕괴보다 방치와 수선 가능성이 보이도록 표현한다. | 복구 게임의 희망적인 톤과 맞는가? |

---

## 4. Decision — 승인된 상위 규칙

### 4.1 세계와 감정

- 배경은 조선 후기 서민 마을에서 영감을 받는다.
- 역사 재현보다 따뜻하고 아기자기한 게임 세계로 단순화한다.
- 핵심 경험은 `쇠락 → 수선 → 손님 증가 → 활기 회복`의 Recovery / Revival이다.
- 귀엽지만 유아용처럼 보이지 않는 `Cute but not babyish` 톤을 유지한다.

### 4.2 카메라와 투영

- 기준 플레이 화면은 `9:16 portrait` 세로형이다.
- `top-down oblique`: 지면은 약 45도 위에서 내려다본다.
- 건물의 주요 파사드와 캐릭터 상체는 거의 정면으로 읽힌다.
- `parallel projection`을 사용한다.
- 소실점, 원근 수렴, 과장된 광각 왜곡을 사용하지 않는다.
- 아이소메트릭 다이아몬드 그리드와 30도 아이소메트릭 타일 감각을 사용하지 않는다.
- 화면 속 모든 주요 오브젝트는 같은 투영 규칙을 공유한다.

### 4.3 렌더링 스타일

- stylized 2D mobile game illustration
- 일정하고 진한 charcoal outline
- 따뜻한 큰 색면 위에 절제된 부드러운 명암
- 손으로 그린 듯한 가벼운 재료 질감과 세부 묘사
- 한지처럼 따뜻하고 미세한 화면 grain
- 짧고 단순한 접지 그림자
- 모바일 줌아웃에서도 실루엣과 역할이 읽히는 디테일 밀도
- P01의 초가, 기와, 옹기, 식생처럼 재료 구분에 도움이 되는 세부 묘사는 허용
- 텍스트, UI, 로고, 워터마크, 장식 테두리를 이미지에 넣지 않는다.

#### 4.3.1 챕터 물건 렌더링 — Decision 2026-09-02

- 물건은 확대 감상용 삽화가 아니라 작은 모바일 게임 아이콘으로 설계한다.
- 사실적인 묘사보다 큰 형태와 실루엣을 우선하고, 대표 특징은 1~3개만 남긴다.
- 주조색의 명암은 밝기 기준 최소 2단계, 최대 4단계로 제한한다.
- 광고·도감용 고밀도 일러스트처럼 매끈하고 화려한 렌더링은 피한다.
- 색이 부드럽게 번지고 겹치는 담백한 수채화 느낌을 사용하되, 종이 배경은 넣지 않는다.
- 재질 표현은 물건을 구분하는 데 필요한 만큼만 사용한다. 섬유, 직조, 나뭇결, 표면 입자를 빽빽하게 반복하지 않는다.
- `64~96px` 축소 상태에서 이름 없이 종류가 읽히는지 검수한다.
- 같은 매장 안에서는 시점, 캔버스 점유율, 외곽선 굵기를 통일한다.
- 내부 선이 축소 상태에서 뭉치거나 실루엣을 방해하면 삭제한다.
- 각 매장의 `20번`은 1,000레벨에서 만나는 프리미엄 최종 물품으로 제작한다.
- 20번의 프리미엄은 고밀도 묘사가 아니라 큰 존재감, 안정적인 구성과 품목에 맞는 고급 단서 1~2개로 표현한다.
- 금박·옻칠 받침·고급 포장·자수 등의 포인트를 허용하되 단순화, 수채화, 명암 2~4단계와 `96px` 가독성은 유지한다.

### 4.4 컬러 팔레트

| 역할 | 색상 | 사용 원칙 |
|---|---:|---|
| 한지/밝은 바탕 | `#e8ddc8` | 벽, 한지, 밝은 천의 주조색 |
| 따뜻한 중간 바탕 | `#ddd0b6` | 초가, 흙벽, 중립 면 |
| 외곽선 | `#2b241b` | 순수 검정 대신 주요 outline |
| 차가운 중립 | `#4a4a52` | 기와, 그늘, 제한적 대비 |
| 목재/흙갈색 | `#8b6b4a` | 목재 구조와 기본 갈색 |
| 밝은 목재/황토 | `#a8763e` | 포인트 목재, 바닥 변화 |
| 식생 녹색 | `#4a7c59` | 작은 식생과 회복의 단서 |
| 절제된 적색 | `#a34a3a` | 단청·상품의 작은 포인트만 |
| 먼지 낀 베이지 | `#d3c3a2` | 길, 낡은 표면, 통합용 중립색 |

팔레트는 기준색 집합이다. 생성 과정에서 밝기 변형은 허용하지만, 고채도 금색·선홍색·보라색이 주조색이 되어서는 안 된다.

### 4.5 한국성의 우선순위

한국성은 다음 순서로 만든다.

`건축 > 생활소품 > 상품 > 복식 > 장식`

- 건축: 한옥 구조, 초가와 절제된 기와, 목재 기둥, 한지 창호, 낮은 담장
- 생활소품: 장독, 옹기, 지게, 광주리, 멍석, 한지와 붓
- 복식: 사용한다면 시대감이 느껴질 만큼만 단순화하되, 소형 스프라이트에서는 생략 가능성을 함께 시험
- 장식: 단청과 색 포인트는 작고 드물게 사용

중국식 등롱, 궁전형 지붕, 과도한 금색과 붉은 기둥, 일본식 상점 파사드, 신사·도리이 연상 요소를 사용하지 않는다.

### 4.6 캐릭터 핵심

- 주인공은 raccoon이 아니라 한국 너구리 `raccoon dog`다.
- 작은 둥근 귀, 회갈색/갈색 털, 약한 눈 주변 어두운 털, 짧은 다리, 통통한 몸, 고리무늬 없는 복슬한 꼬리를 사용한다.
- 라쿤식 선명한 검은 눈 마스크와 고리무늬 꼬리를 사용하지 않는다.
- 큰 캐릭터 일러스트를 축소하지 않고 실제 플레이 축척에서 처음부터 설계한다.
- 점주 복식 사용 여부는 아직 `Hypothesis`다. 전신 서민복 V0.1, 무복식 V0.2, 짧은 허리 앞치마만 사용한 V0.3을 실제 게임 크기에서 비교하며, 한국성은 복식보다 건축·생활소품에서 우선 만든다.

세부 기준은 [01_CHARACTER.md](./01_CHARACTER.md)를 따른다.

---

## 5. V0.1 이미지 구성

### 필수 장면 요소

- 쇠락한 조선 후기풍 서민 마을의 일부
- 같은 투영과 비슷한 크기로 보이는 폐허 1채와 복구된 기본 상점 1채
- 건물 사이를 연결하는 흙길
- 실제 플레이 크기의 한국 너구리 점주 1마리
- 작은 손님 동물 2~3마리
- 낮은 담장 또는 담장 조각
- 한지 창호와 목재 구조가 읽히는 복구 상점
- 장독/옹기, 지게, 광주리, 멍석 중 과밀하지 않은 3~4종
- 폐허 쪽의 마른 풀과 복구 상점 쪽의 작은 녹색 식생

### 화면 위계

1. 복구된 상점과 점주
2. 폐허와 복구 상태의 대비
3. 손님 동선
4. 한국 생활소품
5. 표면 질감과 배경 장식

### 시선 및 여백

- 장면 중심은 복구된 상점과 그 앞 점주다.
- 세로 화면 안의 건물·길·캐릭터 위치는 H-01~H-03의 탐색 대상이며 승인 전에는 고정하지 않는다.
- 캐릭터 얼굴 확대나 초상화식 강조를 하지 않는다.
- 오브젝트를 카탈로그처럼 분리된 칸에 넣지 않는다.
- 화면 가장자리에는 후속 모바일 크롭을 위한 숨 쉴 여백을 둔다.

---

## 6. 이미지 생성용 Master Prompt V0.1

아래 프롬프트는 첫 생성의 기준이다. 세로 비율만 고정하고 건물·길·캐릭터의 정확한 위치는 자연스러운 플레이 구도를 찾도록 열어둔다.

```text
Create one cohesive vertical 9:16 portrait art concept blueprint image for a cozy mobile idle tycoon game called Raccoon General Store. It must feel like an actual portrait mobile gameplay view, not a landscape illustration cropped into a vertical canvas. Show a small part of a faded late-Joseon-inspired Korean commoners' village beginning to come back to life. This is a warm, simplified game world, not strict historical reconstruction.

Use a top-down oblique camera: the ground is viewed from about 45 degrees above, while building facades and small characters remain almost front-facing and easy to read. Use parallel projection with no vanishing point, no perspective convergence, no wide-angle distortion, and no isometric diamond grid.

Design a natural portrait-mobile composition without fixed horizontal bands or predetermined left/right placement. In one unified playable scene, include one repairable abandoned house and one restored basic Korean shop at the same visual scale rather than arranged as two flat comparison panels. Connect them with a clearly readable gently curving dirt road and leave enough open space for customer movement. The restored shop should use a modest hanok structure, timber framing, pale earthen walls, hanji lattice doors, a restrained thatched or simple tiled roof, and a low wall. The abandoned house should look neglected and weathered but still repairable, not violently destroyed.

Place one small raccoon dog shopkeeper at actual mobile gameplay scale in front of the restored shop, plus two or three simple small animal customers moving between the road and shop. The shopkeeper is a Korean raccoon dog, not a North American raccoon: small rounded ears, warm gray-brown fur, only soft dark shading around the eyes, short legs, a plump compact body, and one fluffy tail with absolutely no bold rings. Dress the shopkeeper only in simplified late-Joseon commoner work clothes: a short beige jeogori-like jacket, loose earth-brown trousers, and a small plain work apron. Cute but not babyish.

Use Korean everyday-life details sparingly: a few onggi jars or jangdok, one jige, one woven basket, and a rolled or laid straw mat. Add dry grass near the abandoned house and a few muted green plants near the restored shop to support the recovery theme.

Render as a warm stylized 2D mobile game illustration matching the approved P01 direction: consistent dark charcoal outlines, broad readable color shapes, restrained soft shading, lightly hand-painted material detail, subtle warm paper grain, and short simple contact shadows. Details may distinguish thatch, roof tiles, wood, onggi, earth, and foliage, but the scene must remain readable when zoomed out on a phone. Base the palette on warm hanji beige #e8ddc8, muted straw #ddd0b6, charcoal brown #2b241b, roof gray #4a4a52, wood brown #8b6b4a, warm ochre #a8763e, muted leaf green #4a7c59, restrained red accent #a34a3a, and dusty beige #d3c3a2.

Do not include any text, labels, UI, icons, title, logo, watermark, frame, panel border, or decorative border.
```

### Negative constraints

```text
No North American raccoon, no striped or ringed tail, no sharp black eye mask, no oversized mascot head, no baby proportions, no character close-up. No Chinese lanterns, paifang, palace roofs, dramatic upturned eaves, dominant red columns, excessive gold, or generic Chinese fantasy styling. No Japanese torii, shrine, machiya storefront, noren shop curtains, or Japanese signage. No royal palace mood, noble costume, elaborate hanbok, ceremonial hat, weapons, fantasy armor, neon colors, photorealism, fully rendered cinematic painting, 3D render, cinematic depth of field, dramatic long shadows, perspective convergence, or isometric diamond tiles.
```

---

## 7. DO / DON'T 검수 규칙

### DO

- 첫눈에 작은 한국 서민 마을로 읽힌다.
- 건물과 소품이 한국성을 만들고 복식은 보조한다.
- 점주가 라쿤이 아닌 너구리로 읽힌다.
- 건물, 점주, 손님, 소품의 상대 크기가 모바일 게임 화면에 맞는다.
- 폐허와 복구 상점이 같은 세계의 전후 상태처럼 보인다.
- charcoal 외곽선, 따뜻한 색면, 절제된 부드러운 명암, 짧은 그림자가 장면 전체에서 일관된다.
- 축소해도 점주와 상점 입구, 길의 방향이 읽힌다.

### DON'T — Hard fail

- 점주 꼬리에 선명한 고리무늬가 있다.
- 눈 주변이 라쿤식 검은 마스크로 강하게 분리된다.
- 원근이 한 점으로 수렴하거나 아이소메트릭 다이아몬드 그리드가 보인다.
- 중국식 등롱/궁전 지붕/붉은 기둥/금색이 장면의 정체성을 지배한다.
- 일본식 신사·도리이·상점 요소가 보인다.
- 캐릭터가 홍보 일러스트처럼 너무 크고 건물이 배경 장식이 된다.
- 이미지 안에 텍스트, UI, 로고, 워터마크, 프레임이 생긴다.

### DON'T — Revise

- 소품이 많아 길과 상점 입구가 막힌다.
- 디테일과 질감 때문에 작은 화면에서 형태가 뭉친다.
- 폐허가 재난 현장처럼 과격하거나 우울하다.
- 복구 상태의 차이가 식생과 청결 외에는 거의 보이지 않는다.
- 색 포인트가 넓게 퍼져 따뜻한 중립 팔레트가 약해진다.

---

## 8. Blueprint V0.1 승인 게이트

다음 질문을 기준으로 검수했고 `2026-08-18`에 사용자가 P01을 승인했다.

- [x] 라쿤이 아니라 한국 너구리로 보이는가?
- [x] 9:16 세로형 실제 플레이 화면으로 구성되었는가?
- [x] 45도 top-down oblique이면서 건물과 캐릭터가 정면에 가깝게 읽히는가?
- [x] 소실점과 아이소메트릭 다이아몬드 그리드가 없는가?
- [x] 캐릭터가 실제 모바일 플레이 크기로 보이는가?
- [x] 한국성이 건축과 생활소품에서 먼저 느껴지는가?
- [x] 폐허와 복구 상점의 Recovery 대비가 따뜻하게 읽히는가?
- [x] 줌아웃해도 길, 상점 입구, 점주, 손님이 구분되는가?
- [x] 팔레트, 외곽선, 색면, 명암, 질감이 승인된 P01 방향과 맞는가?
- [x] 중국풍·일본풍·궁전풍으로 쏠리는 요소가 없는가?
- [x] 텍스트, UI, 워터마크, 테두리가 없는가?

### 승인 범위

- P01의 전체 분위기, 따뜻한 팔레트, 렌더링 밀도, 한국 마을 정체성, Recovery 대비
- 9:16 실제 플레이 화면과 top-down oblique 방향
- 건물·길·작은 동물 캐릭터가 함께 보이는 통합 장면 방식

### 여전히 고정하지 않는 항목

- 건물·길·캐릭터의 정확한 좌우·상하 배치
- P01에 등장한 손님 종을 최종 손님 목록으로 사용하는 것
- 개별 상점의 형태와 상품 진열
- 캐릭터 시트에서 확정할 점주의 정확한 얼굴·몸·꼬리 비율

다음 게이트는 Art Direction과 실제 게임의 연결 방식이다. 현재 구현과 제작 에셋 분리는 [06_GAME_INTEGRATION.md](./06_GAME_INTEGRATION.md)를 따른다.
