# 05. Generation Log

## 목적

생성 이미지를 단순 보관하지 않고, 무엇을 시험했고 왜 승인/반려했는지 기록한다. 특히 `라쿤화`, `중국풍/일본풍 드리프트`, `잘못된 카메라`, `캐릭터 과대`, `모바일 축소 가독성`을 반복 추적한다.

## 상태

- `Generated` — 생성 완료, 아직 판정 전
- `Approved` — 현재 게이트를 통과해 기준 이미지로 채택
- `Rejected` — 기준으로 사용할 수 없음
- `Revision` — 일부 방향은 맞지만 같은 가설의 수정 생성 필요

그림 장부에서는 `Generated`와 `Revision`을 `초안`, `Approved`를 `확정`으로 표시한다.
파일이 아직 없으면 `없음`이다.

## 로그 인덱스

| Log ID | 날짜 | Prompt ID | 파일/링크 | 상태 | 한 줄 판정 |
|---|---|---|---|---|---|
| LOG-BP-001 | 2026-08-18 | BP-V0.1-P01 | [BP-V0.1-P01.png](./generated/BP-V0.1-P01.png) | Approved | 사용자가 현재 시안을 최종 V0.1 기준으로 승인 |
| LOG-HERO-001 | 2026-08-19 | HERO-V0.1-P01 | [hero/](./generated/hero/) | Revision | 전신 복식이 소형 캐릭터에 필요한지 사용자 문제 제기 |
| LOG-HERO-002 | 2026-08-19 | HERO-V0.2-P01 | [hero/](./generated/hero/) | Revision | 무복식 방향은 개선됐으나 사용자가 작은 앞치마 추가를 제안 |
| LOG-HERO-003 | 2026-08-19 | HERO-V0.3-P01 | [hero/](./generated/hero/) | Generated | 자연 털 실루엣 + 짧은 허리 앞치마 make/sell 현재 후보 |
| LOG-STAFF-001 | 2026-08-21 | STAFF-BAND-V0.1-P01 | [band-work.png](../../godot/art/staff/band-work.png) · [band-sleep.png](../../godot/art/staff/band-sleep.png) | Generated | 머리띠만 두른 알바의 작업·수면 144×144 초안 |
| LOG-STAFF-002 | 2026-08-21 | STAFF-BAND-V0.2-P01 | [band-work.png](../../godot/art/staff/band-work.png) · [band-sleep.png](../../godot/art/staff/band-sleep.png) | Generated | 차렷 작업 포즈와 몽글 수면방울로 사용자 피드백 반영 |
| LOG-STAFF-003 | 2026-08-22 | STAFF-RANKS-V0.3-P01 | [staff/](../../godot/art/staff/) | Generated | 초립·패랭이·백립 작업/수면 6장으로 직원 4등급 초안 완성 |
| LOG-HERO-004 | 2026-08-22 | HERO-V0.4-P01 | [hero/](../../godot/art/hero/) | Generated | 걷기 2장·수면·촌장으로 공용 점장 필수 자세를 채움 |
| LOG-GUEST-001 | 2026-08-22 | GUEST-MAGPIE-V0.1-P01 | [magpie.png](../../godot/art/guests/magpie.png) | Generated | 필드용 128×128 까치 손님 초안 |
| LOG-UI-002 | 2026-08-22 | INTERACTION-ITEMS-BATCH-01-P01 | [needle.png](../../godot/art/ui/needle.png) | Generated | 룰렛 축과 적색 촉이 64×96에서도 분리되는 바늘 초안 |
| LOG-PEST-001 | 2026-08-22 | INTERACTION-ITEMS-BATCH-01-P01 | [pests/](../../godot/art/pests/) | Generated | 쥐·까마귀·삽살개 한 장씩으로 이동·도난·경비 실루엣을 채움 |
| LOG-ITEM-001 | 2026-08-22 | INTERACTION-ITEMS-BATCH-01-P01 | [pick.png](../../godot/art/items/pick.png) | Generated | 독립 물건 제작의 첫 규격으로 대장간 곡괭이를 채움 |
| LOG-ITEM-002 | 2026-08-22 | ITEMS-SMITH-BATCH-01-P01 | [items/](../../godot/art/items/) | Generated | 낫·호미·도끼·가위·부엌칼을 같은 무쇠·나무 세트로 채움 |
| LOG-ITEM-003 | 2026-08-22 | ITEMS-SMITH-BRUSH-BATCH-02-P01 | [items/](../../godot/art/items/) | Generated | 자물쇠·가마솥으로 대장간을 닫고 붓·먹·벼루로 필방을 시작 |
| LOG-ITEM-004 | 2026-08-22 | ITEMS-BRUSH-BATCH-03-P01 | [items/](../../godot/art/items/) | Generated | 연적·필통·서산·붓걸이·화첩으로 필방 8종을 모두 채움 |
| LOG-ITEM-005 | 2026-08-22 | ITEMS-PAPER-BATCH-04-P01 | [items/](../../godot/art/items/) | Generated | 한지·부채·창호지·장지·연을 쓰임새 실루엣으로 구분 |
| LOG-ITEM-006 | 2026-08-22 | ITEMS-PAPER-POT-BATCH-05-P01 | [items/](../../godot/art/items/) | Generated | 지우산·지등·병풍으로 지물포를 닫고 옹기·사발로 옹기점을 시작 |
| LOG-ITEM-007 | 2026-08-22 | ITEMS-POT-BATCH-06-P01 | [items/](../../godot/art/items/) | Generated | 청자·시루·술병·다기·향로를 색과 용도 실루엣으로 구분 |
| LOG-ITEM-008 | 2026-08-22 | ITEMS-POT-HERB-BATCH-07-P01 | [items/](../../godot/art/items/) | Generated | 달항아리로 옹기점을 닫고 도라지·산삼·녹용·우황으로 약재상을 시작 |
| LOG-ITEM-009 | 2026-08-22 | ITEMS-HERB-SOUP-BATCH-08-P01 | [items/](../../godot/art/items/) | Generated | 당귀·영지·침향·경옥고로 약재상을 닫고 첫 국밥을 시작 |
| LOG-ITEM-010 | 2026-08-22 | ITEMS-SOUP-BATCH-09-P01 | [items/](../../godot/art/items/) | Generated | 장국·수제비·냉국·곰탕·삼계탕을 국물색과 대표 건더기로 구분 |
| LOG-ITEM-011 | 2026-08-22 | ITEMS-SOUP-INN-BATCH-10-P01 | [items/](../../godot/art/items/) | Generated | 추어탕·용봉탕으로 국밥집을 닫고 막걸리·파전·동동주로 주막을 시작 |
| LOG-ITEM-012 | 2026-08-22 | ITEMS-INN-BATCH-11-P01 | [items/](../../godot/art/items/) | Generated | 묵무침·청주·보쌈·법주·구절판으로 주막 8종을 마무리 |
| LOG-ITEM-013 | 2026-08-22 | ITEMS-SKEWER-BATCH-12-P01 | [items/](../../godot/art/items/) | Generated | 떡·닭·버섯·생선·산적을 막대 위 재료 리듬으로 구분 |
| LOG-ITEM-014 | 2026-08-22 | ITEMS-SKEWER-RICECAKE-BATCH-13-P01 | [items/](../../godot/art/items/) | Generated | 장어·너비아니·육회로 꼬치집을 닫고 가래떡·인절미로 떡집을 시작 |
| LOG-ITEM-015 | 2026-08-22 | ITEMS-RICECAKE-BATCH-14-P01 | [items/](../../godot/art/items/) | Generated | 반달·큰 흰 네모·찰밥 사각·꽃 원·찍음 과자로 떡집 다섯 품목을 구분 |
| LOG-ITEM-016 | 2026-08-22 | ITEMS-RICECAKE-BUTCHER-BATCH-15-P01 | [items/](../../godot/art/items/) | Generated | 유과로 떡집을 닫고 지방층·닭다리·살코기·뼈로 푸줏간을 시작 |
| LOG-ITEM-017 | 2026-08-22 | ITEMS-BUTCHER-STALL-BATCH-16-P01 | [items/](../../godot/art/items/) | Generated | 잎 묶음·미색 고리·긴 필렛·마블링 타원으로 물건 80종을 마무리 |
| LOG-STALL-001 | 2026-08-22 | ITEMS-BUTCHER-STALL-BATCH-16-P01 | [smith.png](../../godot/art/stalls/smith.png) | Generated | 중앙을 비운 낮은 대장간 좌판과 실제 물건 합성 기준을 시험 |
| LOG-STALL-002 | 2026-08-22 | STALLS-BATCH-17-P01 | [stalls/](../../godot/art/stalls/) | Generated | 같은 낮은 골격을 한지·종이·흙·약장·온장판 재료로 확장 |
| LOG-STALL-003 | 2026-08-22 | STALLS-BATCH-18-P01 | [stalls/](../../godot/art/stalls/) | Generated | 술상·숯홈·떡판·도마로 좌판 10종과 필수 170장을 마무리 |
| LOG-CLERK-001 | 2026-08-22 | CLERKS-BATCH-19-P01 | [clerks/](../../godot/art/clerks/) | Generated | 공용 점주에 가죽·먹색·한지색의 최소 업종 표식만 추가 |
| LOG-CLERK-002 | 2026-08-22 | CLERKS-BATCH-20-P01 | [clerks/](../../godot/art/clerks/) | Generated | 한지·황토·쑥빛 앞치마로 지물포·옹기점·약재상 두 포즈를 채움 |
| LOG-CLERK-003 | 2026-08-22 | CLERKS-BATCH-21-P01 | [clerks/](../../godot/art/clerks/) | Generated | 밤색·자주색·먹색 앞치마로 국밥집·주막과 꼬치집 제작을 구분 |
| LOG-CLERK-004 | 2026-08-22 | CLERKS-BATCH-22-P01 | [clerks/](../../godot/art/clerks/) | Generated | 꼬치집·떡집·푸줏간을 닫아 가게별 점장 20장 초안 완성 |
| LOG-CARD-007 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-01-P01 | [cards/](../../godot/art/cards/) | Generated | 같은 개체와 자연 자세를 유지하고 수선된 마을 안쪽으로 2단 성장 규칙 시험 |
| LOG-CARD-008 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-02-P01 | [cards/](../../godot/art/cards/) | Generated | 계절과 등급이 달라도 수선된 생활 공간만으로 2단 성장 규칙 유지 |
| LOG-CARD-009 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-03-P01 | [cards/](../../godot/art/cards/) | Generated | 등급 양끝도 풍경 규모와 생활 정돈만으로 2단 성장 차이 유지 |
| LOG-CARD-010 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-04-P01 | [cards/](../../godot/art/cards/) | Generated | 뒤뜰·물가·꽃길·장독대의 1단 생활 장소를 수선해 2단으로 확장 |
| LOG-CARD-011 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-05-P01 | [cards/](../../godot/art/cards/) | Generated | 황혼 산길·단풍 숲·연못·겨울길의 개체 연속성을 유지하며 2단으로 확장 |
| LOG-CARD-012 | 2026-08-22 | GUEST-CARDS-TIER2-BATCH-06-P01 | [cards/](../../godot/art/cards/) | Generated | 논·산길·약초밭·눈길·마을 입구를 수선해 30종의 2단 카드 초안을 완성 |
| LOG-CARD-013 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-01-P01 | [cards/](../../godot/art/cards/) | Generated | 열린 문·낮은 좌판·준비된 물건으로 3단 장날 생활권 가정을 시험 |
| LOG-CARD-014 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-02-P01 | [cards/](../../godot/art/cards/) | Generated | 산물·곡식·겨울 저장품·물가 쉼터·나루 장터로 3단 장소 언어 확장 |
| LOG-CARD-015 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-03-P01 | [cards/](../../godot/art/cards/) | Generated | 논머리·산길·곡식마당·물길·텃밭으로 등급 양끝의 3단 장날 언어 확장 |
| LOG-CARD-016 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-04-P01 | [cards/](../../godot/art/cards/) | Generated | 열매·연못·나루·묘목·옹기마당으로 장소별 3단 장날 언어 확장 |
| LOG-CARD-017 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-05-P01 | [cards/](../../godot/art/cards/) | Generated | 황혼·산길·단풍·연못·겨울의 색을 지키며 3단 장날 언어 확장 |
| LOG-CARD-018 | 2026-08-22 | GUEST-CARDS-TIER3-BATCH-06-P01 | [cards/](../../godot/art/cards/) | Generated | 희귀도가 높은 다섯 종까지 장식 없는 3단 장소 언어로 완성 |
| LOG-CARD-019 | 2026-08-22 | GUEST-CARDS-TIER4-BATCH-01-P01 | [cards/](../../godot/art/cards/) | Generated | 연결된 담·길·배수로와 공동마당으로 4단 최종 성장 가정 시험 |
| LOG-CARD-020 | 2026-08-22 | GUEST-CARDS-TIER4-BATCH-02-P01 | [cards/](../../godot/art/cards/) | Generated | 가을·수확·눈·연못·나루의 길과 물길로 4단 가정 확장 |
| LOG-CARD-021 | 2026-08-23 | GUEST-CARDS-TIER4-BATCH-03-P01 | [cards/](../../godot/art/cards/) | Generated | 논·산길·곡식마당·수로·텃밭을 잇는 4단 기반시설 가정 확장 |

## 최초 실행 결과

- Prompt ID: `BP-V0.1-P01`
- Prompt source: [prompts/BP-V0.1-P01.md](./prompts/BP-V0.1-P01.md)
- 생성물: [generated/BP-V0.1-P01.png](./generated/BP-V0.1-P01.png)
- 상태: `Approved`
- 검증 범위: 9:16, 통합 장면, 카메라, 상대 축척, 한국성, 너구리 DNA, Recovery 대비

### LOG-BP-001 — Gameplay Art Concept Blueprint P01

- 날짜: `2026-08-18`
- Prompt ID: `BP-V0.1-P01`
- 기반 Blueprint 버전: `V0.1-draft`
- 이미지: [BP-V0.1-P01.png](./generated/BP-V0.1-P01.png)
- 상태: `Approved`

#### 관찰

- 잘 된 점: 9:16 통합 플레이 장면, 폐허와 복구 상점의 대비, 한국 건축과 생활소품, 텍스트/UI 없는 화면, 길과 손님 동선이 읽힌다.
- 최초 내부 우려: 초기 문서의 flat vector 기준보다 회화적이고 표면 묘사가 많았으며 캐릭터 크기, 얼굴, 폐허 손상에 수정 가능성이 있다고 판단했다. 사용자는 현재 결과 전체를 매우 마음에 들어 했으므로 P01의 실제 렌더링과 분위기가 기존의 엄격한 스타일 문구보다 우선한다.
- 축소 화면 가독성: 건물과 길은 읽히지만 캐릭터가 시선을 과도하게 차지한다.
- 사용자 반응 1: “비슷하긴해.” 세계관과 전체 분위기가 목표에 근접했다는 긍정 신호.
- 사용자 반응 2: “지금걸로 아주 맘에 들어.” P01을 V0.1 기준 이미지로 명시적 승인.

#### 판정

- 결과: `Approved`
- Why: 사용자가 현재 시안의 전체 결과를 명시적으로 승인했다. P01의 렌더링 밀도와 분위기를 이후 이미지의 기준으로 사용한다.
- Hard fail 여부: 사용자 승인 시점에 차단 요소 없음.

#### 다음 작업

- `BP-V0.1-P02` 수정 시안은 만들지 않는다.
- P01을 시각 참조로 사용해 한국 너구리 점주 캐릭터 시트로 진행한다.
- P01의 정확한 화면 배치와 손님 종은 개별 규칙으로 고정하지 않는다.

### LOG-HERO-001 — 한국 너구리 점주 make/sell P01

- 날짜: `2026-08-19`
- Prompt ID: `HERO-V0.1-P01`
- 기반 Blueprint 버전: `V0.1 Approved / BP-V0.1-P01`
- Prompt source: [prompts/HERO-V0.1-P01.md](./prompts/HERO-V0.1-P01.md)
- 원본 이미지: [generated/hero/](./generated/hero/)
- 게임용 보존본: `../../art/hero/raccoon-make-v001.png`, `../../art/hero/raccoon-sell-v001.png`
- 상태: `Revision`
- 이번에 시험한 Hypothesis: 같은 점주를 구부린 제작 포즈와 양손을 내민 판매 포즈로 나누면 34×34 표시 크기에서도 행동이 구분된다.

#### 관찰

- 잘 된 점: 고리무늬 없는 복슬한 꼬리, 베이지 저고리/흙갈색 바지/작업 앞치마가 두 포즈에 공통으로 유지됐다.
- 잘 된 점: make는 구부린 몸과 비대칭 팔, sell은 몸 밖으로 뻗은 양팔로 실루엣 차이가 난다.
- 어긋난 점: 큰 눈과 밝은 얼굴 무늬가 한국 너구리보다 라쿤 또는 어린 캐릭터로 읽힐 가능성은 사용자 검토가 필요하다.
- 축소 화면 가독성: 34×34 시험에서 몸, 꼬리, 제작/판매 팔 방향은 구분된다. 옷의 세부 주름과 털 질감은 대부분 사라지므로 최종 승인 뒤 더 단순화할 수 있다.
- 파일 검증: 두 런타임 PNG 모두 `72×72`, RGBA, 투명 배경.

#### 판정

- 결과: `Revision`
- Why: 사용자가 작은 게임 캐릭터에 전신 복식이 꼭 필요한지 문제를 제기하고 더 단순한 소형 캐릭터 참고 방향을 제시했다.
- Hard fail 여부: 선명한 고리 꼬리, 배경, 텍스트, UI는 없음. 종 인상과 babyish 정도는 승인 게이트에 남긴다.

#### 다음 수정

- 프롬프트 수정: 전신 복식을 제거하고 털 실루엣과 행동 포즈만 남긴 V0.2를 비교 생성한다.
- Blueprint 규칙 수정 후보: 없음. 단일 생성 결과를 Decision으로 승격하지 않는다.
- Hypothesis → Decision 승격 후보: 2포즈 구성, 72×72 제작 규격, 34×34 표시 크기.
- 다음 Prompt ID: 사용자 승인 또는 수정 요청 후 결정.

### LOG-HERO-002 — 무복식 소형 점주 make/sell P01

- 날짜: `2026-08-19`
- Prompt ID: `HERO-V0.2-P01`
- 기반 Blueprint 버전: `V0.1 Approved / CH-H07 추가`
- Prompt source: [prompts/HERO-V0.2-P01.md](./prompts/HERO-V0.2-P01.md)
- 원본 이미지: `generated/hero/HERO-V0.2-*-master.png`
- 게임용 현재 후보: `../../art/hero/raccoon-make.png`, `../../art/hero/raccoon-sell.png`
- 비교 보존본: `../../art/hero/raccoon-*-v002.png`
- 상태: `Revision`
- 이번에 시험한 Hypothesis: 전신 복식을 제거한 단순한 털 실루엣이 34×34에서 점주의 종과 행동을 더 잘 보여준다.

#### 관찰

- 잘 된 점: V0.1보다 외곽 형태와 팔 동작이 단순하며 make/sell의 자세 차이가 즉시 보인다.
- 잘 된 점: 고리무늬 없는 꼬리와 복식 없는 몸이 한 덩어리로 읽힌다.
- 어긋난 점: 귀와 눈 주변 무늬가 여전히 라쿤 또는 유아형 마스코트로 읽힐 가능성이 있어 사용자 검토가 필요하다.
- 축소 화면 가독성: 34×34에서 얼굴, 꼬리, 팔 방향이 V0.1보다 또렷하다.
- 파일 검증: 두 후보 모두 `72×72`, RGBA, 투명 배경.

#### 판정

- 결과: `Revision`
- Why: 무복식 방향은 V0.1보다 낫다는 사용자 반응을 얻었지만, 역할 표식으로 일부 앞치마를 추가하는 방향이 새로 제안됐다.
- Hard fail 여부: 고리 꼬리, 의상 과밀, 배경, 텍스트, UI는 없음. 종 인상과 babyish 정도는 검토 대상.

#### 다음 수정

- 프롬프트 수정: 얼굴·몸·포즈는 유지하고 허리 아래의 짧은 작업 앞치마만 추가한다.
- Blueprint 규칙 수정 후보: 점주 무복식 여부.
- Hypothesis → Decision 승격 후보: CH-H07.
- 다음 Prompt ID: 사용자 승인 또는 수정 요청 후 결정.

### LOG-HERO-003 — 짧은 허리 앞치마 점주 make/sell P01

- 날짜: `2026-08-19`
- Prompt ID: `HERO-V0.3-P01`
- 기반 Blueprint 버전: `V0.1 Approved / CH-H08 추가`
- Prompt source: [prompts/HERO-V0.3-P01.md](./prompts/HERO-V0.3-P01.md)
- 원본 이미지: `generated/hero/HERO-V0.3-*-master.png`
- 게임용 현재 후보: `../../art/hero/raccoon-make.png`, `../../art/hero/raccoon-sell.png`
- 비교 보존본: `../../art/hero/raccoon-*-v003.png`
- 상태: `Generated`
- 이번에 시험한 Hypothesis: 털 실루엣은 그대로 두고 짧은 허리 앞치마만 추가하면 34×34에서 점주 역할과 행동을 함께 읽을 수 있다.

#### 관찰

- 잘 된 점: 가슴 털, 팔, 다리, 꼬리가 가려지지 않고 황토갈색 앞치마가 한 색면으로 보인다.
- 잘 된 점: 전신 서민복 V0.1보다 단순하고, 완전 무복식 V0.2보다 점주 역할 표식이 생겼다.
- 어긋난 점: make와 sell의 앞치마 매듭 위치와 곡선이 완전히 동일하지 않으므로 최종 확정 뒤 통일 보정이 필요할 수 있다.
- 축소 화면 가독성: 34×34에서도 앞치마 색면과 make/sell 팔 방향이 구분된다.
- 파일 검증: 두 후보 모두 `72×72`, RGBA, 투명 배경.

#### 판정

- 결과: `Generated`
- Why: 사용자 제안을 반영한 V0.3 제작과 축소 검증은 끝났지만 최종 승인 전이다.
- Hard fail 여부: 고리 꼬리, 전신 의상, 배경, 텍스트, UI는 없음. 종 인상과 앞치마 크기는 사용자 검토 대상.

#### 다음 수정

- 프롬프트 수정: 사용자 피드백이 있으면 앞치마 크기 또는 색 중 한 항목만 조절한다.
- Blueprint 규칙 수정 후보: 작은 허리 앞치마만 허용.
- Hypothesis → Decision 승격 후보: CH-H08.
- 다음 Prompt ID: 사용자 승인 또는 수정 요청 후 결정.

### LOG-STAFF-001 — 머리띠 알바 work/sleep P01

- 날짜: `2026-08-21`
- Prompt ID: `STAFF-BAND-V0.1-P01`
- 기반 규격: 최신 Godot 주문서 `02d03ae` · 직원 144×144 → 화면 72×72
- Prompt source: [prompts/STAFF-BAND-V0.1-P01.md](./prompts/STAFF-BAND-V0.1-P01.md)
- 마스터 이미지: `generated/staff/STAFF-BAND-V0.1-*-master.png`
- 게임용 초안: `../../godot/art/staff/band-work.png`, `../../godot/art/staff/band-sleep.png`
- 상태: `Generated` / 그림 장부 `초안`
- 이번에 시험한 Hypothesis: 점장과 같은 몸 크기를 유지하고 미색 머리띠만 사용하면 연장 없이도 직원 역할이 읽힌다.

#### 관찰

- 잘 된 점: 고리무늬 없는 꼬리, 짧은 다리, 통통한 몸, 미색 머리띠가 두 포즈에 유지됐다.
- 잘 된 점: 작업은 빈 양 앞발을 앞으로 내밀고, 수면은 눈을 감고 앞발을 모아 행동 실루엣이 다르다.
- 잘 된 점: 두 런타임 PNG 모두 `144×144`, RGBA, 실제 투명 배경이며 발끝이 아래 변에 닿는다.
- 어긋날 수 있는 점: 기존 점장보다 털 질감과 눈 표현이 자세하므로 실제 72×72 화면에서 한 세트처럼 보이는지 확인해야 한다.
- 생성 이슈: 최초 결과에 체크무늬 배경이 픽셀로 들어가 background extraction으로 실제 알파를 복구했다.

#### 판정

- 결과: `Generated`
- Why: 규격 파일과 두 행동 포즈는 완성됐지만 사용자 승인과 실제 Godot 화면 검수를 아직 거치지 않았다.
- Hard fail 여부: 고리 꼬리, 도구, 앞치마, 전신 복식, 텍스트, UI, 불투명 배경은 없음.

#### 다음 수정

- 실제 화면에서 점장과 나란히 놓고 몸 크기·선 굵기·얼굴 대비를 확인한다.
- 사용자 피드백이 있으면 머리띠 크기, 눈 표현, 작업 포즈 중 한 항목만 수정한다.
- 통과하면 `band-work`·`band-sleep`을 확정하고 같은 몸으로 초립 등급을 확장한다.

### LOG-STAFF-002 — 차렷 작업·몽글 수면 P01

- 날짜: `2026-08-21`
- Prompt ID: `STAFF-BAND-V0.2-P01`
- 기반 이미지: `STAFF-BAND-V0.1-P01`
- Prompt source: [prompts/STAFF-BAND-V0.2-P01.md](./prompts/STAFF-BAND-V0.2-P01.md)
- 게임용 현재 초안: `../../godot/art/staff/band-work.png`, `../../godot/art/staff/band-sleep.png`
- 상태: `Generated` / 그림 장부 `초안`
- 사용자 피드백: 작업 포즈는 허리를 숙이지 않고 차렷 상태에서 손만 움직인다. 수면 포즈에는 `zzz` 또는 몽글 표식이나 작은 움직임을 허용한다.

#### 관찰

- 작업 포즈: 몸을 수직으로 세우고 빈 두 앞발만 앞에서 엇갈리게 바꿨다.
- 수면 포즈: 글자 대신 작은 미색 몽글 방울 세 개를 머리 위에 배치했다.
- 동일 캐릭터 크기: 두 포즈의 몸 높이를 약 `111px`로 맞추고 144×144 하단에 정렬했다.
- 수면 생성본은 캐릭터까지 다시 그려져 본체는 쓰지 않고, 수면방울만 분리해 V0.1 본체에 합성했다.
- 두 런타임 PNG 모두 `144×144`, RGBA, 실제 투명 배경이다.

#### 판정

- 결과: `Generated`
- Why: 사용자 피드백은 반영했지만 72×72 실제 Godot 화면에서 손 동작과 수면방울의 가독성을 아직 확인하지 않았다.
- Hard fail 여부: 허리 숙임, 연장, 고리 꼬리, 전신 복식, 불투명 배경, 텍스트·UI는 없음.

#### 다음 수정

- Godot에서 작업 손동작과 수면방울이 0.45배 줌에서도 읽히는지 확인한다.
- 수면 움직임은 그림을 추가하지 않고 Godot에서 1~2px 정도 천천히 흔드는 방식을 후보로 둔다.
- 사용자 승인 후 `확정`으로 승격하거나 한 항목만 추가 수정한다.

### LOG-STAFF-003 — 직원 4등급 모자 확장 P01

- 날짜: `2026-08-22`
- Prompt ID: `STAFF-RANKS-V0.3-P01`
- 기반 이미지: `band-work.png`, `band-sleep.png`
- Prompt source: [prompts/STAFF-RANKS-V0.3-P01.md](./prompts/STAFF-RANKS-V0.3-P01.md)
- 게임용 초안: `../../godot/art/staff/`의 초립·패랭이·백립 작업/수면 6장
- 상태: `Generated` / 그림 장부 `초안`
- 이번에 시험한 Hypothesis: 같은 한국 너구리 몸을 유지하고 모자의 관·챙·색만 바꾸면 72×72에서도 직원 등급이 읽힌다.

#### 관찰

- 초립은 짧은 챙, 패랭이는 넓은 대나무 챙, 백립은 한지빛 흰 갓으로 실루엣이 구분된다.
- 작업 자세는 서 있는 몸과 빈 앞발, 수면 자세는 감은 눈과 몽글방울을 공통으로 유지했다.
- 여섯 런타임 파일은 모두 `144×144`, RGBA, 실제 투명 배경이며 발끝이 아래 변에 닿는다.
- 모자가 커질수록 전체 캔버스에 맞추는 과정에서 몸의 화면 크기가 조금 달라 보일 수 있어 Godot 배치 화면 검수가 필요하다.
- 이미지 생성은 built-in image generation/edit 모드로 진행했고, 체크무늬 결과 다섯 장은 배경 추출 편집으로 투명도를 복구했다.

#### 판정

- 결과: `Generated`
- Why: 최신 자동 주문서의 직원 8장을 모두 채웠지만 실제 Godot 화면 검수와 사용자 승인은 아직이다.
- Hard fail 여부: 고리 꼬리, 도구, 전신 복식, 중국식·일본식 대표 모자, 불투명 배경, 텍스트·UI는 없음.

#### 다음 수정

- 네 등급을 한 화면에 놓고 몸 크기, 얼굴 대비, 모자 챙의 가림을 확인한다.
- 최신 `MOTION.md` 계약에 따라 `work2`는 추가하지 않고 한 장을 코드에서 약 3px 들썩인다.
- 수면방울도 별도 프레임을 필수로 늘리지 않고 현재 한 장을 유지한다.

### LOG-HERO-004 — 점장 걷기·수면과 촌장 P01

- 날짜: `2026-08-22`
- Prompt ID: `HERO-V0.4-P01`
- Prompt source: [prompts/HERO-V0.4-P01.md](./prompts/HERO-V0.4-P01.md)
- 기반 이미지: `HERO-V0.3` 짧은 앞치마 점장
- 게임용 초안: `raccoon-walk1.png`, `raccoon-walk2.png`, `raccoon-sleep.png`, `mayor.png`
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 걷기 두 장은 머리·몸·꼬리·앞치마를 비슷하게 유지하면서 발과 팔의 전후만 교차해 작은 화면에서도 차이가 난다.
- 수면은 서 있는 자세를 유지하고 눈·모은 앞발·몽글방울로 상태가 읽힌다.
- 촌장은 점장과 같은 크기지만 흰 수염, 지팡이, 앞치마 없음으로 구분된다.
- 네 런타임 파일은 `144×144`, RGBA, 진짜 투명 배경이며 하단 접점을 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 자동 주문서의 점장·촌장 파일명을 모두 채웠지만 게임 화면에서 걷기 프레임의 흔들림과 촌장 지팡이 가림은 아직 검수 전이다.
- Hard fail 여부: 고리 꼬리, 전신 관복, 중국·일본 대표 요소, 불투명 배경, 텍스트·UI 없음.

### LOG-GUEST-001 — 까치 필드 손님 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-MAGPIE-V0.1-P01`
- Prompt source: [prompts/GUEST-MAGPIE-V0.1-P01.md](./prompts/GUEST-MAGPIE-V0.1-P01.md)
- 게임용 초안: [magpie.png](../../godot/art/guests/magpie.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 깊은 갈색 먹빛, 흰 배와 날개 반점, 긴 꼬리가 64×64 표시에서도 까치로 읽힌다.
- 카드를 위한 정면 초상이 아니라 마을에서 오른쪽을 향하는 필드 스프라이트로 제작했다.
- 런타임 파일은 `128×128`, RGBA, 실제 투명 배경이며 발끝이 아래 변에 닿는다.

#### 판정

- 결과: `Generated`
- Why: 필드 규격은 통과했지만 다른 손님들과 한 화면에서 크기·눈 크기·선 굵기를 비교하기 전이다.
- Hard fail 여부: 배경, 의상, 물건, 텍스트·UI 없음.

### LOG-GUEST-002 — 손님 필드 5종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-01-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-01-P01.md](./prompts/GUESTS-FIELD-BATCH-01-P01.md)
- 게임용 초안: `squirrel.png`, `badger.png`, `fox.png`, `deer.png`, `boar.png`
- QA: [qa/guests-field-batch-01.png](./qa/guests-field-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 종 모두 오른쪽을 보는 걷기 실루엣과 동일한 갈색 외곽선·따뜻한 색면을 유지했다.
- 다람쥐 꼬리, 오소리 얼굴 줄, 여우 꼬리끝, 물사슴의 무각·큰 귀, 멧돼지 주둥이가 64×64에서도 구분된다.
- 몸의 실제 종 비율을 살려 까치·다람쥐·오소리·여우·사슴·멧돼지의 높이와 폭이 서로 다르다.
- 다섯 런타임 파일은 모두 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 필드 규격과 종 구분은 통과했지만 실제 마을에서 코드 들썩임·좌우 뒤집기·가림 순서를 아직 검수하지 않았다.
- Hard fail 여부: 의상, 소지품, 배경, 바닥 그림자, 문자·UI 없음. 물사슴에 뿔 없음.

#### 다음 수정

- Godot에서 여섯 종을 같은 길에 놓고 64×64 표시와 0.45배 줌을 확인한다.
- 물사슴의 송곳니가 과하게 읽히거나 손님의 순한 인상을 깨면 다음 버전에서 줄인다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-GUEST-003 — 귀한 손님 필드 5종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-02-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-02-P01.md](./prompts/GUESTS-FIELD-BATCH-02-P01.md)
- 게임용 초안: `bear.png`, `turtle.png`, `crane.png`, `ox.png`, `tiger.png`
- QA: [qa/guests-field-batch-02.png](./qa/guests-field-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 곰과 소는 무거운 몸, 거북은 낮고 넓은 몸, 두루미는 긴 수직선, 호랑이는 큰 앞발과 줄무늬로 실루엣이 겹치지 않는다.
- 높은 등급을 왕관·옷·광효과로 표시하지 않고 자세의 안정감과 무늬 대비, 선 정돈으로 차이를 뒀다.
- 다섯 런타임 파일은 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.
- 소 생성본은 알파 추출이 반복 실패해 전경을 바꾸지 않는 연결 배경 제거 후처리를 사용했다.

#### 판정

- 결과: `Generated`
- Why: 등급별 실루엣 차이는 보이지만 64×64에서 두루미 다리 굵기와 호랑이 줄무늬 밀도를 실제 화면으로 확인해야 한다.
- Hard fail 여부: 의상, 장신구, 광효과, 소지품, 배경, 바닥 그림자, 문자·UI 없음.

#### 다음 수정

- 1·2차 손님 11종을 같은 길에 놓고 종별 화면 크기와 지면 가림을 확인한다.
- 두루미 다리가 0.45배 줌에서 끊겨 보이면 선 굵기만 보정한다.
- 호랑이가 지나치게 사실적으로 보이면 얼굴만 더 민화식으로 단순화하는 수정 후보를 남긴다.

### LOG-GUEST-004 — 흔한 손님 필드 5종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-03-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-03-P01.md](./prompts/GUESTS-FIELD-BATCH-03-P01.md)
- 게임용 초안: `sparrow.png`, `frog.png`, `mole.png`, `hedgehog.png`, `duck.png`
- QA: [qa/guests-field-batch-03.png](./qa/guests-field-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 참새의 뺨점, 개구리의 접힌 뒷다리, 두더지의 굴착 앞발, 고슴도치 가시, 오리 물갈퀴가 축소 뒤에도 종을 가른다.
- 흔함 등급은 장식이나 강한 명암 없이 친숙한 몸색과 간단한 무늬만 사용했다.
- 다섯 런타임 파일은 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.
- 배경 분리가 어려운 세 장은 생성 편집과 색 키 후처리를 사용했고, 후처리 과정에서 동물 자체는 다시 그리지 않았다.

#### 판정

- 결과: `Generated`
- Why: 종 구분과 투명 규격은 통과했지만 두더지만 눈 크기와 선 굵기가 다른 손님보다 사실적으로 작아 실제 화면 비교가 필요하다.
- Hard fail 여부: 의상, 장신구, 소지품, 배경, 바닥 그림자, 문자·UI 없음.

#### 다음 수정

- 64×64에서 두더지 얼굴이 뭉개지면 눈과 외곽선만 한 단계 굵게 만든다.
- 오리의 가는 다리가 코드 들썩임에서 끊겨 보이는지 확인한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-GUEST-005 — 드문 손님 필드 5종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-04-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-04-P01.md](./prompts/GUESTS-FIELD-BATCH-04-P01.md)
- 게임용 초안: `otter.png`, `roe.png`, `weasel.png`, `wildcat.png`, `goral.png`
- QA: [qa/guests-field-batch-04.png](./qa/guests-field-batch-04.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 수달과 족제비는 모두 긴 몸이지만 수달은 낮고 굵으며, 족제비는 높고 가늘어 64×64에서도 구분된다.
- 물사슴과 노루는 노루의 짧은 갈래뿔과 흰 엉덩이 반점으로 구분했다.
- 살쾡이는 집고양이처럼 보이지 않도록 이마선·몸 점·다리 줄·꼬리 고리를 함께 남겼다.
- 산양은 짧게 뒤로 휜 뿔과 회갈색 긴 털, 발굽으로 다른 사슴류와 구분된다.
- 다섯 런타임 파일은 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 종 구분과 투명 규격은 통과했지만 족제비가 작은 화면에서 여우처럼 읽히는지 실제 길 배치 검수가 필요하다.
- Hard fail 여부: 의상, 장신구, 소지품, 배경, 바닥 그림자, 문자·UI 없음.

#### 다음 수정

- 족제비가 여우처럼 보이면 귀와 얼굴을 줄이고 몸을 더 낮추는 V0.2 후보를 둔다.
- 살쾡이 점무늬가 0.45배 줌에서 노이즈가 되면 큰 점만 남긴다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-GUEST-006 — 귀한 손님 필드 5종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-05-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-05-P01.md](./prompts/GUESTS-FIELD-BATCH-05-P01.md)
- 게임용 초안: `marten.png`, `mandarin.png`, `wolf.png`, `egret.png`, `leopard.png`
- QA: [qa/guests-field-batch-05.png](./qa/guests-field-batch-05.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 담비와 족제비는 담비의 넓은 황금빛 가슴과 더 굵은 몸으로 구분된다.
- 원앙은 자연색이 많지만 작은 줄무늬 대신 볏·얼굴선·가슴·돛깃의 큰 다섯 색면으로 정리했다.
- 백로는 두루미와 달리 검은 목·날개끝·붉은 정수리가 없고 얕은 S자 목과 노란 부리를 쓴다.
- 표범은 살쾡이보다 몸과 발을 키우고 점을 큰 장미무늬로 줄였다.
- 다섯 런타임 파일은 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 필드 손님 27종이 채워졌지만 원앙 돛깃과 표범 무늬가 0.45배 줌에서 얼마나 남는지 실제 화면 검수가 필요하다.
- Hard fail 여부: 의상, 장신구, 광효과, 소지품, 배경, 바닥 그림자, 문자·UI 없음.

#### 다음 수정

- 원앙이 너무 화려해 카드 초상처럼 보이면 몸 무늬를 더 줄이고 돛깃만 남긴다.
- 표범 무늬가 노이즈면 몸통 장미무늬 수를 절반으로 줄이는 V0.2 후보를 둔다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-GUEST-007 — 마지막 손님 필드 3종 묶음 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUESTS-FIELD-BATCH-06-P01`
- Prompt source: [prompts/GUESTS-FIELD-BATCH-06-P01.md](./prompts/GUESTS-FIELD-BATCH-06-P01.md)
- 게임용 초안: `muskdeer.png`, `moonbear.png`, `haetae.png`
- QA: [qa/guests-field-batch-06.png](./qa/guests-field-batch-06.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 사향노루는 뿔 없는 몸, 큰 귀, 아래 송곳니로 노루·사슴과 구분된다.
- 반달곰은 검갈색 큰 몸과 가슴의 넓은 미색 반달이 축소 화면에서도 남는다.
- 해태는 청회색 몸, 외뿔, 덩어리형 갈기와 말린 꼬리로 자연 동물과 구분된다.
- 세 런타임 파일은 `128×128`, RGBA, 진짜 투명 배경이며 접지점을 아래 변에 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 필드 손님 30종을 모두 채웠지만 사향노루의 송곳니 크기와 해태의 영물감은 실제 길 배치에서 검수해야 한다.
- Hard fail 여부: 의상, 장신구, 광효과, 소지품, 배경, 바닥 그림자, 문자·UI 없음.

#### 다음 수정

- 사향노루가 맹수처럼 보이면 송곳니를 절반으로 줄이는 V0.2 후보를 둔다.
- 해태가 지나치게 아기 사자처럼 보이면 눈을 줄이고 다리를 조금 길게 한다.
- 사용자 승인 전까지 세 장 모두 `초안`을 유지한다.

### LOG-UI-001 — 뽑기 카드 뒷면·12칸 룰렛 P01

- 날짜: `2026-08-22`
- Prompt ID: `UI-GACHA-BATCH-01-P01`
- Prompt source: [prompts/UI-GACHA-BATCH-01-P01.md](./prompts/UI-GACHA-BATCH-01-P01.md)
- 게임용 초안: `ui/back.png`, `ui/wheel.png`
- QA: [qa/ui-gacha-batch-01.png](./qa/ui-gacha-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 카드 뒷면은 기와와 복슬한 꼬리 문장을 중심으로 두고 글자와 등급색을 비웠다.
- 룰렛은 정확히 12칸이며 칸 안을 비워 코드가 보상 글자와 효과를 얹을 수 있다.
- 두 파일 모두 목표 크기와 RGBA 투명 배경을 충족한다.

#### 판정

- 결과: `Generated`
- Why: 정지 그림 계약은 맞지만 실제 뒤집기·회전 화면에서 테두리 두께와 중심축 크기를 확인해야 한다.
- Hard fail 여부: 카드 글자·등급 효과 없음, 룰렛 문자·보상·바늘 없음.

#### 다음 수정

- 카드가 화면에서 너무 복잡하면 중앙 문장 외의 잎 장식을 줄인다.
- 룰렛 보상 글자 공간이 부족하면 중심축과 칸 구분선을 약간 줄인다.
- 사용자 승인 전까지 두 장 모두 `초안`을 유지한다.

### LOG-CARD-001 — 손님 카드 1단 첫 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-01-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-01-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-01-P01.md)
- 게임용 초안: `rabbit-1.png`, `magpie-1.png`, `squirrel-1.png`, `badger-1.png`, `fox-1.png`
- QA: [qa/guest-cards-tier1-batch-01.png](./qa/guest-cards-tier1-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 흙길·돌담·낮은 서민 건축과 같은 한지 질감을 사용해 한 묶음으로 읽힌다.
- 흔함 3종은 밝고 익숙한 낮 장면, 드묾 2종은 해질녘과 늦은 오후를 써 분위기 차이를 뒀다.
- 카드 프레임과 정보가 올라갈 가장자리 여백을 남기고 동물은 250px 표시에서도 얼굴과 종이 읽힌다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 카드 그림의 공통 밀도와 장면 언어는 잡혔지만, 현재 `card.gd`가 아직 필드 손님 그림을 읽으므로 실제 카드 프레임 결합 검수가 남았다.
- Hard fail 여부: 의상·장신구·글자·별·등급색·프레임·UI·워터마크 없음.

#### 다음 수정

- 코드 프레임이 동물 귀나 꼬리를 덮으면 이후 카드부터 안전 여백을 9%로 늘린다.
- 배경이 250px에서 동물을 방해하면 돌담·식물 디테일을 한 단계 줄인다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-002 — 손님 카드 1단 등급 확장 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-02-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-02-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-02-P01.md)
- 게임용 초안: `deer-1.png`, `boar-1.png`, `bear-1.png`, `turtle-1.png`, `crane-1.png`
- QA: [qa/guest-cards-tier1-batch-02.png](./qa/guest-cards-tier1-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 사슴·멧돼지는 단풍과 추수 뒤 볏단으로 귀함 등급의 또렷한 계절감을 만든다.
- 곰은 첫눈과 큰 체구, 거북은 연못의 정돈된 공간으로 진귀 등급을 구분했다.
- 두루미는 넓은 하늘과 긴 흑백 실루엣만으로 영물의 고요한 위계를 만든다.
- 다섯 파일 모두 `512×768`이며 카드 프레임·글자·등급 효과를 포함하지 않는다.

#### 판정

- 결과: `Generated`
- Why: 광효과 없이도 등급 차이가 읽히지만 실제 코드 프레임과 제목 영역을 얹은 화면 검수가 필요하다.
- Hard fail 여부: 의상·장신구·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 거북이 250px에서 배경에 묻히면 몸 크기를 약 8% 키운다.
- 곰의 눈 배경이 너무 밝아 카드 프레임과 충돌하면 설경 밝기를 한 단계 낮춘다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-003 — 손님 카드 1단 등급 양끝 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-03-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-03-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-03-P01.md)
- 게임용 초안: `ox-1.png`, `tiger-1.png`, `sparrow-1.png`, `frog-1.png`, `mole-1.png`
- QA: [qa/guest-cards-tier1-batch-03.png](./qa/guest-cards-tier1-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 소와 호랑이는 넓은 하늘·산줄기·큰 체구로 영물·신수 등급을 만든다.
- 참새·개구리·두더지는 곡식 광주리·논물길·무밭 같은 평범한 생활 공간에 붙여 흔함을 유지한다.
- 호랑이는 장식 없이도 카드 묶음에서 가장 강한 실루엣과 시선 집중도를 가진다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 등급 양끝의 간격은 읽히지만 호랑이와 소가 코드 프레임 안에서 지나치게 꽉 차는지 확인해야 한다.
- Hard fail 여부: 의상·장신구·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 호랑이 이마가 제목 영역과 충돌하면 전체를 4% 축소한 V0.2를 만든다.
- 개구리와 두더지가 배경에 작아 보이면 다음 흔함 카드의 몸 비율을 기준으로 5% 키운다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-004 — 손님 카드 1단 생활 반경 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-04-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-04-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-04-P01.md)
- 게임용 초안: `hedgehog-1.png`, `duck-1.png`, `otter-1.png`, `roe-1.png`, `weasel-1.png`
- QA: [qa/guest-cards-tier1-batch-04.png](./qa/guest-cards-tier1-batch-04.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 소박한 마을 생활권이지만 대추나무·연못·돌다리·진달래·장독대로 장소가 겹치지 않는다.
- 수달의 긴 꼬리, 노루의 뿔 없는 큰 귀, 족제비의 낮고 긴 몸이 250px에서도 구분된다.
- 흔함은 밝은 일상, 드묾은 물가와 뒷마당의 조금 숨은 공간으로 분위기를 갈랐다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 한 세트로 읽히면서 배경 반복도 줄었지만 수달의 상체가 사람처럼 보이지 않는지 사용자 검수가 필요하다.
- Hard fail 여부: 의상·장신구·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 수달이 의인화돼 보이면 앞발을 바위에 짚는 낮은 자세의 V0.2를 후보로 둔다.
- 족제비가 여우처럼 보이면 귀와 얼굴을 줄이고 몸을 더 길게 한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-005 — 손님 카드 1단 자연 무늬 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-05-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-05-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-05-P01.md)
- 게임용 초안: `wildcat-1.png`, `goral-1.png`, `marten-1.png`, `mandarin-1.png`, `wolf-1.png`
- QA: [qa/guest-cards-tier1-batch-05.png](./qa/guest-cards-tier1-batch-05.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 살쾡이 점·산양 뿔·담비 금빛 목·원앙 돛깃·늑대 체구가 각 카드의 첫 실루엣으로 남는다.
- 배경은 황혼·산길·단풍·연못·푸른 저녁으로 갈랐지만 동물보다 대비를 낮췄다.
- 원앙은 색이 많아도 큰 색면으로 묶여 250px에서 무늬가 뭉치지 않는다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 종 구분은 강하지만 살쾡이와 늑대의 어두운 배경이 코드 프레임 색과 겹치는지 확인해야 한다.
- Hard fail 여부: 의상·장신구·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 살쾡이 카드가 지나치게 어두우면 하늘과 흙길을 한 단계 밝힌다.
- 원앙 카드가 다른 귀함 카드보다 과하게 화려하면 배경 단풍 채도를 줄인다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-006 — 손님 카드 1단 마지막 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER1-BATCH-06-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER1-BATCH-06-P01.md](./prompts/GUEST-CARDS-TIER1-BATCH-06-P01.md)
- 게임용 초안: `egret-1.png`, `leopard-1.png`, `muskdeer-1.png`, `moonbear-1.png`, `haetae-1.png`
- QA: [qa/guest-cards-tier1-batch-06.png](./qa/guest-cards-tier1-batch-06.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 백로는 검은 목과 붉은 정수리가 없어 두루미와, 표범은 큰 체구와 장미무늬로 살쾡이와 구분된다.
- 사향노루는 뿔 없는 큰 귀와 짧은 송곳니, 반달곰은 검은 몸의 넓은 가슴 반달이 핵심이다.
- 해태는 광효과 없이 청회색 몸·외뿔·말린 갈기만으로 자연 동물 사이에서 영물로 읽힌다.
- 다섯 런타임 파일은 정확한 `512×768`이며 손님 카드 1단 30종이 모두 채워졌다.

#### 판정

- 결과: `Generated`
- Why: 필수 카드 30장은 완성됐지만 해태의 단순화 정도와 사향노루 송곳니 크기는 사용자 미감 검수가 필요하다.
- Hard fail 여부: 의상·장신구·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 해태가 다른 카드보다 너무 만화적으로 보이면 갈기 덩어리만 유지하고 몸 명암을 한 단계 자연스럽게 맞춘다.
- 사향노루가 맹수처럼 보이면 송곳니를 절반으로 줄인다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-CARD-007 — 손님 성장 카드 2단 첫 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-01-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-01-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-01-P01.md)
- 게임용 초안: `rabbit-2.png`, `magpie-2.png`, `squirrel-2.png`, `badger-2.png`, `fox-2.png`
- QA: [qa/guest-cards-tier2-batch-01.png](./qa/guest-cards-tier2-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 각 1단의 종·털/깃 무늬·몸 비율·자연 자세를 유지해 같은 손님으로 읽힌다.
- 수선된 돌담, 쓸린 흙길, 정돈된 광주리와 장작, 따뜻한 창호로 ‘외곽 방문객 → 마을에 익숙한 단골’ 변화를 만든다.
- 1단보다 배경의 생활 밀도와 온도는 높지만 의상·장신구·마법광·등급 프레임은 없다.
- 토끼·까치·다람쥐의 낮 장면과 오소리·여우의 저녁 장면이 각 1단의 시간대 성격을 이어간다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 2단 성장 언어는 성립했지만 실제 카드 화면에서 1단과 나란히 보이는 차이, 성 구간 전환 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·인간 자세·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 2단 나머지 손님도 같은 개체와 기존 계절을 유지하고, 마을 회복·생활 반경만 한 단계 올린다.
- 3단 전에는 1단/2단 한 쌍을 실제 카드 프레임에 넣어 변화가 너무 약하거나 강하지 않은지 검수한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CARD-008 — 손님 성장 카드 2단 두 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-02-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-02-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-02-P01.md)
- 게임용 초안: `deer-2.png`, `boar-2.png`, `bear-2.png`, `turtle-2.png`, `crane-2.png`
- QA: [qa/guest-cards-tier2-batch-02.png](./qa/guest-cards-tier2-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 각 1단의 동물 정체성·자연 자세·단풍/추수/첫눈/연못/일출 계절을 유지한다.
- 묶은 멍석과 볏단, 쓸어 낸 눈길, 손본 정자·물길·다리로 회복된 생활 반경을 보여준다.
- 진귀·영물도 의상이나 광효과 없이 공간 완성도만 올렸다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 등급이 달라도 2단 성장 언어는 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·인간 자세·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 다음 2단 묶음도 각 1단 계절과 자세를 유지한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CARD-009 — 손님 성장 카드 2단 세 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-03-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-03-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-03-P01.md)
- 게임용 초안: `ox-2.png`, `tiger-2.png`, `sparrow-2.png`, `frog-2.png`, `mole-2.png`
- QA: [qa/guest-cards-tier2-batch-03.png](./qa/guest-cards-tier2-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 소·호랑이는 논과 산길의 규모, 참새·개구리·두더지는 곡식마당·물길·텃밭의 정돈으로 성장 차이를 만든다.
- 호랑이는 마을 지붕이 더 많이 보이지만 장식·광효과 없이 신수 위계를 유지한다.
- 흔한 세 종은 각 1단의 소박한 자세와 생활 장소를 그대로 잇는다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 등급 양끝의 2단 규칙은 유지되지만 실제 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·인간 자세·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 호랑이 배경의 지붕 밀도가 실제 카드 UI에서 지나치게 복잡한지 확인한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CARD-010 — 손님 성장 카드 2단 네 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-04-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-04-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-04-P01.md)
- 게임용 초안: `hedgehog-2.png`, `duck-2.png`, `otter-2.png`, `roe-2.png`, `weasel-2.png`
- QA: [qa/guest-cards-tier2-batch-04.png](./qa/guest-cards-tier2-batch-04.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 각 1단의 대추 뒤뜰·연못·돌다리·진달래 길·장독대를 유지한다.
- 모은 대추, 손본 물가와 다리, 어린나무 지지대, 돌 받침 장독으로 생활 공간 회복을 보여준다.
- 수달의 세운 상체는 1단 자세를 잇고 긴 꼬리와 물가로 종 정체성을 보강한다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 생활 반경 연속성은 성립했지만 실제 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 수달의 상체가 지나치게 의인화돼 보이는지 1단과 함께 검수한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CARD-011 — 손님 성장 카드 2단 다섯 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-05-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-05-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-05-P01.md)
- 게임용 초안: `wildcat-2.png`, `goral-2.png`, `marten-2.png`, `mandarin-2.png`, `wolf-2.png`
- QA: [qa/guest-cards-tier2-batch-05.png](./qa/guest-cards-tier2-batch-05.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 각 1단의 개체·자세·계절과 황혼 산길·바위 비탈·단풍 숲·연못·겨울길을 유지한다.
- 돌담·계단·연못축대·디딤돌·장작을 수선하거나 정돈해 장식 없이 2단 회복을 보여준다.
- 원앙은 화려한 개체색에 맞춰 배경 채도를 억제했고, 늑대는 따뜻한 창빛을 작게 제한했다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 개체와 장소의 연속성은 성립했지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 산양 카드의 먼 마을 지붕 밀도와 원앙 카드의 정자 크기가 실제 프레임 안에서 과밀하지 않은지 확인한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CARD-012 — 손님 성장 카드 2단 여섯 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER2-BATCH-06-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER2-BATCH-06-P01.md](./prompts/GUEST-CARDS-TIER2-BATCH-06-P01.md)
- 게임용 초안: `egret-2.png`, `leopard-2.png`, `muskdeer-2.png`, `moonbear-2.png`, `haetae-2.png`
- 묶음 QA: [qa/guest-cards-tier2-batch-06.png](./qa/guest-cards-tier2-batch-06.png)
- 2단 전체 QA: [qa/guest-cards-tier2-all-30.png](./qa/guest-cards-tier2-all-30.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 각 1단의 종 특징·자세·계절을 유지한다.
- 논 관개축대·산길 난간·약초길 돌담·눈길 대문·마을 입구 물길로 서로 다른 가장자리 회복을 보여준다.
- 해태를 포함한 희귀 손님도 발광·등급색·궁전 장식 없이 생활 기반 수선만 사용했다.
- 다섯 런타임 파일은 정확한 `512×768`이며 이 묶음으로 2단 30종을 모두 채웠다.

#### 판정

- 결과: `Generated`
- Why: 2단 세트의 제작 규칙과 파일 계약은 완성됐지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·마법 효과·프레임·문자·별·등급색·워터마크 없음.

#### 다음 수정

- 30종 전체 시트에서 배경 복구 밀도가 급격히 뛰는 카드가 없는지 사용자와 함께 확인한다.
- 3단은 같은 개체·계절을 유지하되 `익숙한 단골 → 장날의 오래된 벗`으로 상업 흔적만 한 단계 늘린다.
- 사용자 승인 전까지 30장 모두 `초안`이다.

### LOG-CARD-013 — 손님 성장 카드 3단 첫 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-01-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-01-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-01-P01.md)
- 게임용 초안: `rabbit-3.png`, `magpie-3.png`, `squirrel-3.png`, `badger-3.png`, `fox-3.png`
- QA: [qa/guest-cards-tier3-batch-01.png](./qa/guest-cards-tier3-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절·장소를 유지한다.
- 열린 문, 낮은 좌판, 삼베 그늘막, 광주리·곡식자루·옹기·손수레로 장날의 생활 흔적만 늘렸다.
- 사람이나 추가 동물 없이도 장터가 준비된 상태를 읽을 수 있고, 손님은 자연 상태를 유지한다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 3단 가정은 시각적으로 구분되지만 실제 프레임에서 배경 밀도와 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·마법 효과·워터마크 없음.

#### 다음 수정

- 작은 카드 프레임에서 좌판이 동물 실루엣을 침범하지 않는지 2단과 나란히 확인한다.
- 이후 3단도 상업 흔적을 배경 가장자리에 제한하고 개체 크기와 자세를 바꾸지 않는다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-014 — 손님 성장 카드 3단 두 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-02-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-02-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-02-P01.md)
- 게임용 초안: `deer-3.png`, `boar-3.png`, `bear-3.png`, `turtle-3.png`, `crane-3.png`
- QA: [qa/guest-cards-tier3-batch-02.png](./qa/guest-cards-tier3-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절과 단풍길·추수마당·눈길·연못·나루를 유지한다.
- 산물·곡식·겨울 저장품·물가 쉼터·여행 물품으로 장소마다 다른 장날 쓰임을 부여했다.
- 거북과 두루미는 물가와 긴 실루엣을 가리지 않도록 좌판을 가장자리에 제한했다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 서로 다른 계절과 장소에서도 3단 가정이 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·마법 효과·워터마크 없음.

#### 다음 수정

- 눈 장면과 나루 장면에서 물건 밀도가 카드 프레임 안에서 지나치게 높지 않은지 확인한다.
- 이후 3단도 장소의 기존 기능을 장날 쓰임으로 확장하되 배경 요소 수를 제한한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-015 — 손님 성장 카드 3단 세 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-03-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-03-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-03-P01.md)
- 게임용 초안: `ox-3.png`, `tiger-3.png`, `sparrow-3.png`, `frog-3.png`, `mole-3.png`
- QA: [qa/guest-cards-tier3-batch-03.png](./qa/guest-cards-tier3-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절과 논머리·산길·곡식마당·물길·텃밭을 유지한다.
- 호랑이는 산세와 몸집을 우선하고 쉼터를 작게, 참새·개구리·두더지는 생활 반경에 맞춘 소형 좌판을 사용했다.
- 소 카드에는 곡식과 채소가 함께 들어가 논머리 복합 산물장으로 읽힌다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 등급 양끝에서도 3단 가정이 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·마법 효과·워터마크 없음.

#### 다음 수정

- 소의 복합 산물장이 곡식 중심의 2단 연속성을 해치지 않는지 2·3단 병렬 검수한다.
- 호랑이의 먼 마을 지붕과 쉼터가 실루엣보다 강하지 않은지 확인한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-016 — 손님 성장 카드 3단 네 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-04-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-04-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-04-P01.md)
- 게임용 초안: `hedgehog-3.png`, `duck-3.png`, `otter-3.png`, `roe-3.png`, `weasel-3.png`
- QA: [qa/guest-cards-tier3-batch-04.png](./qa/guest-cards-tier3-batch-04.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절과 열매마당·연못가·나루·봄길·옹기마당을 유지한다.
- 대추 건조·연못 산물·여행 준비·묘목·옹기와 마른 산물로 장소마다 다른 장날 쓰임을 부여했다.
- 수달의 세운 자세와 족제비의 긴 몸·꼬리 주변은 물건을 비워 실루엣을 우선했다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 장소별 장터 언어와 동물 실루엣이 함께 읽히지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·마법 효과·워터마크 없음.

#### 다음 수정

- 수달 카드의 여행 물품 밀도가 세운 몸보다 강하지 않은지 실제 카드 프레임에서 확인한다.
- 노루의 묘목장이 사육 시설처럼 읽히지 않도록 열린 길과 자생 꽃 비중을 유지한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-017 — 손님 성장 카드 3단 다섯 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-05-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-05-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-05-P01.md)
- 게임용 초안: `wildcat-3.png`, `goral-3.png`, `marten-3.png`, `mandarin-3.png`, `wolf-3.png`
- QA: [qa/guest-cards-tier3-batch-05.png](./qa/guest-cards-tier3-batch-05.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절과 황혼길·산길·단풍마당·연못가·겨울길을 유지한다.
- 살쾡이와 늑대는 건물에 붙은 한지 창호만 밝히고, 산양·담비·원앙은 산물장을 한쪽 가장자리에 제한했다.
- 원앙의 깃색이 가장 강하게 남고 새 연못 물건은 미색·갈색·쑥빛으로 낮아 카드 초점이 유지된다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 명암과 계절 차이가 큰 다섯 장에서도 동물 우선순위가 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·등롱·마법 효과·워터마크 없음.

#### 다음 수정

- 산양과 담비의 산물장 밀도가 축소 카드에서 동물의 외곽선과 경쟁하지 않는지 확인한다.
- 늑대 카드에서 푸른 배경과 회색 털 사이의 얼굴·앞다리 대비를 실제 화면에서 확인한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-018 — 손님 성장 카드 3단 여섯 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER3-BATCH-06-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER3-BATCH-06-P01.md](./prompts/GUEST-CARDS-TIER3-BATCH-06-P01.md)
- 게임용 초안: `egret-3.png`, `leopard-3.png`, `muskdeer-3.png`, `moonbear-3.png`, `haetae-3.png`
- 묶음 QA: [qa/guest-cards-tier3-batch-06.png](./qa/guest-cards-tier3-batch-06.png)
- 전체 QA: [qa/guest-cards-tier3-all-30.png](./qa/guest-cards-tier3-all-30.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 2단의 같은 개체·자세·계절과 논물길·산길·약초길·눈길·마을 입구를 유지한다.
- 백로의 긴 다리, 표범 무늬, 사향노루의 작은 몸, 반달곰의 검은 덩어리, 해태의 청록색이 새 물건보다 먼저 읽힌다.
- 해태도 금장·붉은 기둥·광효과 없이 마을 입구 공용 장터의 쓰임으로만 3단을 설명한다.
- 다섯 런타임 파일은 정확한 `512×768`이며, 이 묶음으로 3단 30종이 모두 채워졌다.

#### 판정

- 결과: `Generated`
- Why: 30종 전체에서 같은 3단 가정이 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·금장·등롱·마법 효과·워터마크 없음.

#### 다음 수정

- 3단 전체 시트에서 소형 동물과 대형 동물의 장터 물건 상대 밀도를 비교한다.
- 4단은 물건 수를 더 늘리지 말고 완전히 복구된 공동 생활권과 잘 관리된 기반시설로 차이를 시험한다.
- 사용자 승인 전까지 30장 모두 `초안`, 3단 규칙은 `Hypothesis`다.

### LOG-CARD-019 — 손님 성장 카드 4단 첫 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER4-BATCH-01-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER4-BATCH-01-P01.md](./prompts/GUEST-CARDS-TIER4-BATCH-01-P01.md)
- 게임용 초안: `rabbit-4.png`, `magpie-4.png`, `squirrel-4.png`, `badger-4.png`, `fox-4.png`
- QA: [qa/guest-cards-tier4-batch-01.png](./qa/guest-cards-tier4-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 3단의 같은 개체·자세·계절과 마을 입구·감나무마당·수확마당·창고골목·장터길을 유지한다.
- 열린 문·연속된 석축·배수로·정돈된 공동길로 장소 전체가 함께 관리되는 최종 단계 가정을 시험했다.
- 토끼·오소리·여우는 물건 수보다 길의 연결이 먼저 읽히며, 까치·다람쥐는 감과 수확물 밀도가 3단보다 풍성해졌다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 동물 장식 없이도 4단과 3단의 차이가 읽히지만, 풍성한 두 장의 과밀 여부와 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·금장·등롱·마법 효과·워터마크 없음.

#### 다음 수정

- 까치와 다람쥐는 3·4단 병렬 축소 검수에서 수확물 증가보다 기반시설 연결이 먼저 읽히는지 확인한다.
- 다음 4단 묶음은 새 물건을 늘리지 않고 물길·공동마당·집 사이 연결을 우선한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 4단 규칙은 `Hypothesis`다.

### LOG-CARD-020 — 손님 성장 카드 4단 두 번째 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `GUEST-CARDS-TIER4-BATCH-02-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER4-BATCH-02-P01.md](./prompts/GUEST-CARDS-TIER4-BATCH-02-P01.md)
- 게임용 초안: `deer-4.png`, `boar-4.png`, `bear-4.png`, `turtle-4.png`, `crane-4.png`
- QA: [qa/guest-cards-tier4-batch-02.png](./qa/guest-cards-tier4-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 3단의 같은 개체·자세·계절과 가을길·수확마당·눈길·연못·나루를 유지한다.
- 사슴·멧돼지는 이어진 마을길, 곰은 눈이 치워진 동선, 거북·두루미는 물길·다리·선착장의 연결로 4단을 설명한다.
- 대형 동물과 긴 다리 주변의 빈 공간이 남아 장터 물건보다 동물 실루엣이 먼저 읽힌다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 계절과 물가가 달라도 공동 기반시설 중심의 4단 가정이 유지되지만 실제 카드 프레임 및 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·금장·등롱·마법 효과·워터마크 없음.

#### 다음 수정

- 두루미의 포장품과 대나무 묶음이 축소 프레임에서 긴 다리와 경쟁하지 않는지 확인한다.
- 다음 4단도 동물 크기보다 기반시설 연결 범위를 먼저 조정한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 4단 규칙은 `Hypothesis`다.

### LOG-CARD-021 — 손님 성장 카드 4단 세 번째 5종 P01

- 날짜: `2026-08-23`
- Prompt ID: `GUEST-CARDS-TIER4-BATCH-03-P01`
- Prompt source: [prompts/GUEST-CARDS-TIER4-BATCH-03-P01.md](./prompts/GUEST-CARDS-TIER4-BATCH-03-P01.md)
- 게임용 초안: `ox-4.png`, `tiger-4.png`, `sparrow-4.png`, `frog-4.png`, `mole-4.png`
- QA: [qa/guest-cards-tier4-batch-03.png](./qa/guest-cards-tier4-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 3단의 같은 개체·자세·계절과 논·산길·곡식마당·수로·텃밭을 유지한다.
- 소는 관개수로, 호랑이는 산비탈 계단망, 참새는 배수되는 건조마당, 개구리는 이어진 논수로, 두더지는 구획 텃밭으로 4단을 설명한다.
- 축소 묶음에서도 각 동물 실루엣이 먼저 읽히지만 호랑이 뒤의 지붕과 계단 밀도는 실제 카드 틀 확인이 필요하다.
- 다섯 런타임 파일은 정확한 `512×768`이다.

#### 판정

- 결과: `Generated`
- Why: 크고 작은 동물과 논·산·마당·물길 모두에서 기반시설 중심의 4단 가정이 유지되지만 사용자 승인이 남았다.
- Hard fail 여부: 의상·직업 자세·추가 동물·프레임·문자·별·등급색·금장·등롱·마법 효과·워터마크 없음.

#### 다음 수정

- 호랑이의 마을 지붕 밀도가 산세와 줄무늬보다 강하지 않은지 실제 프레임에서 확인한다.
- 다음 4단은 작은 몸 주변의 빈 공간과 기반시설 연결 범위를 함께 유지한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`, 4단 규칙은 `Hypothesis`다.

### LOG-UI-002 — 룰렛 바늘 P01

- 날짜: `2026-08-22`
- Prompt ID: `INTERACTION-ITEMS-BATCH-01-P01`
- Prompt source: [prompts/INTERACTION-ITEMS-BATCH-01-P01.md](./prompts/INTERACTION-ITEMS-BATCH-01-P01.md)
- 게임용 초안: [needle.png](../../godot/art/ui/needle.png)
- QA: [qa/interaction-items-batch-01.png](./qa/interaction-items-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 황동 축·짙은 목재 몸통·넓은 적색 촉이 세 덩어리로 분리돼 `64×96`에서도 아래 방향이 읽힌다.
- 바늘 그림에는 진동이나 각도를 고정하지 않아 룰렛 코드가 회전축을 기준으로 자유롭게 움직일 수 있다.
- 런타임 파일은 정확한 `64×96`, RGBA, 실제 투명 배경이다.

#### 판정

- 결과: `Generated`
- Why: 필수 경로와 규격은 채웠지만 실제 원판 위의 축 정렬과 대비를 Godot 화면에서 확인해야 한다.
- Hard fail 여부: 글자·테두리·배경·그림자판·마법 효과 없음.

#### 다음 수정

- 원판 중심축과 겹쳤을 때 황동 원이 커 보이면 원형 축만 10% 줄인다.
- 클릭 애니메이션은 추가 PNG가 아니라 코드 진동으로 처리한다.
- 사용자 승인 전까지 `초안`을 유지한다.

### LOG-PEST-001 — 필드 상호작용 3종 P01

- 날짜: `2026-08-22`
- Prompt ID: `INTERACTION-ITEMS-BATCH-01-P01`
- Prompt source: [prompts/INTERACTION-ITEMS-BATCH-01-P01.md](./prompts/INTERACTION-ITEMS-BATCH-01-P01.md)
- 게임용 초안: [rat.png](../../godot/art/pests/rat.png) · [crow.png](../../godot/art/pests/crow.png) · [dog.png](../../godot/art/pests/dog.png)
- QA: [qa/interaction-items-batch-01.png](./qa/interaction-items-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 쥐는 낮게 뻗은 몸과 긴 꼬리, 까마귀는 오른쪽 비행 자세와 부리의 엽전, 삽살개는 크고 안정적인 앉은 실루엣으로 역할이 구분된다.
- 까마귀의 밝은 체크 배경과 삽살개의 밝은 체크 배경은 가장자리 연결 영역만 제거해 실제 알파로 복구했다.
- 세 런타임 파일은 정확한 `128×128`, RGBA이며 하단 접점을 맞췄다.

#### 판정

- 결과: `Generated`
- Why: 정지 실루엣만으로 기능은 읽히지만 실제 필드 크기에서 쥐의 꼬리와 까마귀의 엽전이 보이는지 확인해야 한다.
- Hard fail 여부: 옷·무기·인간 손·문자·효과선·불투명 배경 없음.

#### 다음 수정

- 이동은 수평 위치·1~2px 들썩임·좌우 반전으로 처리하고 추가 프레임은 만들지 않는다.
- 엽전이 64px에서 사라지면 까마귀 본체가 아니라 엽전만 약 15% 키운다.
- 삽살개의 경비 반응은 코드의 작은 튕김으로 우선 시험한다.

### LOG-ITEM-001 — 대장간 곡괭이 P01

- 날짜: `2026-08-22`
- Prompt ID: `INTERACTION-ITEMS-BATCH-01-P01`
- Prompt source: [prompts/INTERACTION-ITEMS-BATCH-01-P01.md](./prompts/INTERACTION-ITEMS-BATCH-01-P01.md)
- 게임용 초안: [pick.png](../../godot/art/items/pick.png)
- QA: [qa/interaction-items-batch-01.png](./qa/interaction-items-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 철날과 나무 자루가 큰 두 색면으로 나뉘어 `64×112` 표시 크기에서도 곡괭이로 읽힌다.
- 얕은 사선으로 세워 점장 손 오버레이와 물건 카드 양쪽에 재사용할 여백을 남겼다.
- 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경이다.

#### 판정

- 결과: `Generated`
- Why: 물건 공통 규격의 첫 사례는 채웠지만 점장 손 사이에 올린 실제 화면 검수가 남았다.
- Hard fail 여부: 받침대·글자·등급 광효과·배경·과도한 금속 반사 없음.

#### 다음 수정

- 같은 대장간 8종은 숯색 철·황토 나무·굵은 실루엣을 공유한다.
- 점장 손에서 너무 길면 원본을 다시 그리지 않고 오버레이 표시 비율을 먼저 낮춘다.
- 사용자 승인 전까지 `초안`을 유지한다.

### LOG-ITEM-002 — 대장간 기본 도구 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SMITH-BATCH-01-P01`
- Prompt source: [prompts/ITEMS-SMITH-BATCH-01-P01.md](./prompts/ITEMS-SMITH-BATCH-01-P01.md)
- 게임용 초안: `sickle.png`, `hoe.png`, `axe.png`, `shears.png`, `knife.png`
- QA: [qa/items-smith-batch-01.png](./qa/items-smith-batch-01.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 낫의 큰 곡선, 호미의 직각 날, 도끼의 쐐기, 가위의 고리, 부엌칼의 넓은 날이 축소 뒤에도 서로 겹치지 않는다.
- 숯빛 무쇠와 황토갈색 나무가 곡괭이와 같은 두 주재료로 묶인다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경이다.
- 원화의 금속 표면은 곡괭이보다 다소 세밀하지만 `64×112` 축소에서는 큰 명암 덩어리로 정리된다.

#### 판정

- 결과: `Generated`
- Why: 대장간 세트와 파일 규격은 통과했지만 실제 물건 카드와 점장 손 오버레이에서의 상대 크기 검수가 남았다.
- Hard fail 여부: 손·캐릭터·바닥·글자·등급 효과·불투명 배경 없음.

#### 다음 수정

- 도구별 원본 높이는 유지하고 점장 손에서는 공통 최대 높이로 축소한다.
- 철 질감이 실제 화면에서 번져 보이면 새로 그리기보다 축소 필터와 대비를 먼저 조정한다.
- 남은 대장간 자물쇠·가마솥도 같은 철색과 외곽선으로 이어간다.
- 사용자 승인 전까지 다섯 장 모두 `초안`을 유지한다.

### LOG-ITEM-003 — 대장간 마무리·필방 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SMITH-BRUSH-BATCH-02-P01`
- Prompt source: [prompts/ITEMS-SMITH-BRUSH-BATCH-02-P01.md](./prompts/ITEMS-SMITH-BRUSH-BATCH-02-P01.md)
- 게임용 초안: `lock.png`, `cauldr.png`, `brush.png`, `ink.png`, `inkstone.png`
- QA: [qa/items-smith-brush-batch-02.png](./qa/items-smith-brush-batch-02.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 자물쇠는 옆으로 긴 철 몸체, 가마솥은 둥근 뚜껑과 세 발, 붓은 대나무와 털, 먹은 긴 검은 막대, 벼루는 두 홈으로 구분된다.
- 가로 물건을 `128×224` 캔버스 아래에 붙이지 않고 중앙에 놓으니 카드 안에서 시각 중심이 맞는다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경이다.
- 최초 자물쇠는 높은 U자 고리와 많은 금장이 현대 판타지 물건처럼 보여 `Revision`으로 보존하고 V0.2로 교체했다.

#### 판정

- 결과: `Generated` (`ITEM-LOCK-V0.1`만 `Revision`)
- Why: 대장간 8종이 모두 채워졌고 필방 재료 방향도 읽히지만 실제 카드·점장 손 검수와 사용자 승인이 남았다.
- Hard fail 여부: V0.2와 나머지 네 장에는 글자·금박 장식·불투명 배경·캐릭터·등급 효과 없음.

#### 다음 수정

- 물건 PNG는 발접점이 아니라 투명 캔버스 중앙 정렬을 공통 규칙 후보로 유지한다.
- 점장 손 오버레이는 캔버스 전체가 아니라 알파 경계 기준으로 표시 크기를 정한다.
- 필방의 연적·필통·서산·붓걸이·화첩도 금박 없이 재료와 실루엣으로 이어간다.
- 사용자 승인 전까지 다섯 런타임은 `초안`이다.

### LOG-ITEM-004 — 필방 문방구 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-BRUSH-BATCH-03-P01`
- Prompt source: [prompts/ITEMS-BRUSH-BATCH-03-P01.md](./prompts/ITEMS-BRUSH-BATCH-03-P01.md)
- 게임용 초안: `waterp.png`, `brushpot.png`, `bookmk.png`, `brushrk.png`, `album.png`
- QA: [qa/items-brush-batch-03.png](./qa/items-brush-batch-03.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 연적은 위·옆 두 구멍, 필통은 세워 둔 붓 자루, 서산은 겹친 한지 표식, 붓걸이는 네 홈, 화첩은 제본과 빈 제목지로 용도가 갈린다.
- 서산은 국립민속박물관 소장품의 종이 재질·길고 좁은 비율·독서 횟수 계수 기능을 게임 실루엣으로 단순화했다.
- 백자 청화는 대나무·풀 한두 획으로 제한해 중국 궁중 도자기 인상을 피했다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 필방 8종이 모두 채워졌고 낯선 서산도 자료 근거가 있지만 실제 목록에서 이름과 함께 보이는지 사용자 검수가 남았다.
- Hard fail 여부: 문자·숫자·금박·붉은 칠·용무늬·불투명 배경·등급 효과 없음.

#### 다음 수정

- 서산이 화살표 묶음처럼 보이면 종이 가장자리의 한지 결을 조금 키우고 끈 고리를 줄인다.
- 필통이 붓 세트처럼 보이면 내부 붓 자루 노출 높이를 15% 낮춘다.
- 다음 지물포는 한지·창호지·장지의 종이 종류를 색보다 접힘·묶음·쓰임새 실루엣으로 구분한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-005 — 지물포 종이 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-PAPER-BATCH-04-P01`
- Prompt source: [prompts/ITEMS-PAPER-BATCH-04-P01.md](./prompts/ITEMS-PAPER-BATCH-04-P01.md)
- 게임용 초안: `hanji.png`, `fan.png`, `window.png`, `floorp.png`, `kite.png`
- QA: [qa/items-paper-batch-04.png](./qa/items-paper-batch-04.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 한지는 말린 두루마리, 부채는 반원, 창호지는 창살, 장지는 두꺼운 적층, 연은 중앙 바람구멍과 살대로 구분된다.
- 모두 한지빛을 공유하지만 쓰임새 형태가 달라 `64×112` 축소에서도 다섯 종을 가를 수 있다.
- `floorp.png`의 장지는 자료 확인에 따라 바닥 종이가 아닌 두껍고 잘 도련한 문서지 묶음으로 그렸다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 종이류 중복 문제와 역사 용도 혼동을 해결했지만 실제 게임의 이름·가격과 함께 놓인 사용자 검수가 남았다.
- Hard fail 여부: 글자·도장·금박·궁전풍 장식·불투명 배경·등급 효과 없음.

#### 다음 수정

- 창호지가 문 자체로만 보이면 뒤의 여분 종이 면적을 키우고 창살 폭을 줄인다.
- 연의 붉고 푸른 원이 현대 국기처럼 보이면 면적을 줄이고 한지 여백을 늘린다.
- 지물포 남은 지우산·지등·병풍도 종이빛을 공유하되 구조 실루엣을 우선한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-006 — 지물포 마무리·옹기점 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-PAPER-POT-BATCH-05-P01`
- Prompt source: [prompts/ITEMS-PAPER-POT-BATCH-05-P01.md](./prompts/ITEMS-PAPER-POT-BATCH-05-P01.md)
- 게임용 초안: `umbrel.png`, `lantrn.png`, `screen.png`, `jar.png`, `bowl.png`
- QA: [qa/items-paper-pot-batch-05.png](./qa/items-paper-pot-batch-05.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 지우산은 길고 접힌 한지, 지등은 밝은 타원 골조, 병풍은 네 폭 지그재그로 지물포 세 종이 분리된다.
- 지등은 붉은색·글자·술 없이 미색 종이와 대나무 프레임만 사용해 특정 중국식 등롱 인상을 줄였다.
- 옹기는 갈색 저장 항아리, 사발은 밝은 회미색 열린 그릇이라 같은 도자기 묶음 안에서도 용도가 갈린다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 지물포 8종이 모두 채워지고 옹기점의 흙·유약 기준도 시작됐지만 실제 카드와 점장 손 검수가 남았다.
- Hard fail 여부: 붉은 등롱·긴 술·글자·금박·불투명 배경·등급 효과 없음.

#### 다음 수정

- 지등이 여전히 중국 등롱처럼 보이면 타원 폭을 줄이고 목재 상하판을 더 소박하게 만든다.
- 병풍의 산수가 축소에서 번지면 새로 그리기보다 내부 그림 대비를 낮춘다.
- 옹기점 나머지는 청자·시루·술병·다기·향로·달항아리로 재료와 쓰임새 범위를 넓힌다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-007 — 옹기점 그릇 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-POT-BATCH-06-P01`
- Prompt source: [prompts/ITEMS-POT-BATCH-06-P01.md](./prompts/ITEMS-POT-BATCH-06-P01.md)
- 게임용 초안: `celad.png`, `steamr.png`, `bottle.png`, `teaset.png`, `censer.png`
- QA: [qa/items-pot-batch-06.png](./qa/items-pot-batch-06.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 청자·술병은 긴 목과 세로 몸, 시루는 열린 구멍 바닥, 다기는 두 잔, 향로는 뚜껑 구멍과 세 발로 구분된다.
- 비취색·적갈색·백자색·분청색·노쇠 금속색이 서로 갈리면서도 모두 절제된 흙빛 팔레트 안에 있다.
- 다기는 주전자와 잔 두 개를 붙여 하나의 판매 단위로 만들었고, 향로에는 연기를 넣지 않았다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 옹기점의 재료와 용도 범위는 넓어졌지만 실제 카드에서 청자·술병의 높이와 가로 물건의 가격 위계가 어울리는지 검수가 남았다.
- Hard fail 여부: 용·봉황·금박·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 다기 주전자의 옆손잡이가 일본식으로 읽히면 손잡이를 뒤쪽 낮은 고리형으로 바꾼다.
- 향로가 궁중품처럼 보이면 귀와 뚜껑 장식을 한 단계 더 줄인다.
- 옹기점 마지막 달항아리는 백자 술병보다 넓고 둥근 무장식 실루엣으로 마무리한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-008 — 옹기점 마무리·약재상 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-POT-HERB-BATCH-07-P01`
- Prompt source: [prompts/ITEMS-POT-HERB-BATCH-07-P01.md](./prompts/ITEMS-POT-HERB-BATCH-07-P01.md)
- 게임용 초안: `moonjr.png`, `root.png`, `ginseng.png`, `antler.png`, `bezoar.png`
- QA: [qa/items-pot-herb-batch-07.png](./qa/items-pot-herb-batch-07.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 달항아리는 넓은 둥근 몸과 희미한 이음선으로 긴 목의 술병과 즉시 구분된다.
- 도라지는 묶음과 보랏빛 종꽃, 산삼은 한 뿌리와 오엽·붉은 열매로 같은 뿌리 약재 안에서도 역할이 갈린다.
- 녹용은 사슴 머리 없이 절단면과 벨벳 질감만 남겼고, 우황은 약포와 접시로 약재 문맥을 보강했다.
- 생성 원화의 산삼 주변 어두운 미리보기는 실제 픽셀이 아닌 투명 영역 표시였으며 런타임 PNG에는 배경·광원이 없다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 옹기점 8종을 모두 채우고 약재상 재료군을 시작했지만 우황의 낯선 형태와 뿌리 약재의 실제 카드 가독성은 사용자 검수가 남았다.
- Hard fail 여부: 사슴 머리·두개골·혈흔·알약·마법 광원·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 도라지와 산삼이 축소 카드에서 비슷하면 꽃·열매의 색면만 키우고 뿌리 자체는 다시 그리지 않는다.
- 우황이 음식처럼 보이면 접시를 약연 또는 약절구 문맥으로 바꾸는 V0.2를 검토한다.
- 약재상 남은 당귀·영지·침향·경옥고는 마른 뿌리·버섯·향목·도자기 약단지로 재료 실루엣을 넓힌다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-009 — 약재상 마무리·국밥집 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-HERB-SOUP-BATCH-08-P01`
- Prompt source: [prompts/ITEMS-HERB-SOUP-BATCH-08-P01.md](./prompts/ITEMS-HERB-SOUP-BATCH-08-P01.md)
- 게임용 초안: `danggui.png`, `reishi.png`, `agar.png`, `elixir.png`, `bap.png`
- QA: [qa/items-herb-soup-batch-08.png](./qa/items-herb-soup-batch-08.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 당귀는 마른 뿌리와 밝은 절편, 영지는 붉은 동심 갓, 침향은 검은 수지결로 세 약재가 즉시 구분된다.
- 경옥고는 열린 갈색 약단지와 검은 약고, 작은 숟가락이 한 묶음으로 읽힌다.
- 국밥은 맑은 국물 속 밥알과 파, 두 점의 고기, 짧은 김 두 줄만 남겨 작은 화면에서도 한 그릇으로 정리된다.
- 생성 원화의 침향 주변 어두운 미리보기는 실제 픽셀이 아닌 투명 영역 표시였으며 런타임 PNG에는 배경·광원이 없다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 약재상 8종이 모두 채워지고 국밥집의 그릇·국물 기준도 시작됐지만 실제 카드에서 당귀 절편과 국밥의 밥알 가독성은 사용자 검수가 남았다.
- Hard fail 여부: 잎 달린 생당귀·귀여운 버섯 얼굴·향 연기·금장식·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 당귀가 산삼처럼 보이면 절편의 밝은 원 세 개를 키우고 가는 잔뿌리를 줄인다.
- 침향이 장작처럼 보이면 검은 수지결 면적만 키우고 묶음 개수는 유지한다.
- 국밥집 남은 품목은 그릇색을 공유하되 국물색·건더기·그릇 위 실루엣으로 구분한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-010 — 국밥집 국물 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SOUP-BATCH-09-P01`
- Prompt source: [prompts/ITEMS-SOUP-BATCH-09-P01.md](./prompts/ITEMS-SOUP-BATCH-09-P01.md)
- 게임용 초안: `kuk.png`, `sujebi.png`, `naeng.png`, `gomtang.png`, `samgye.png`
- QA: [qa/items-soup-batch-09.png](./qa/items-soup-batch-09.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 장국은 간장빛 국물과 표고, 수제비는 밝은 반죽 조각, 냉국은 오이·무채와 얼음으로 중심 무늬가 갈린다.
- 곰탕은 뽀얀 국물과 넓은 편육, 삼계탕은 작은 통닭 한 마리가 가장 큰 식별점이다.
- 냉국만 김이 없고 청회색 그릇을 써 뜨거운 국물 네 종과도 구분된다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 같은 사발 묶음에서도 다섯 음식이 구분되지만 실제 판매 오버레이에서 김과 작은 채소가 남는지 사용자 검수가 필요하다.
- Hard fail 여부: 현대 식기·쟁반·반찬·붉은 중국식 탕색·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 장국이 국밥과 비슷하면 버섯 갈색 면적을 키우고 국밥의 밥알 대비는 유지한다.
- 냉국의 얼음이 보석처럼 보이면 투명도를 낮추고 오이채 비중을 키운다.
- 국밥집 마지막 추어탕·용봉탕은 붉지 않은 짙은 탕색과 대표 재료 표식으로 마무리한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-011 — 국밥집 마무리·주막 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SOUP-INN-BATCH-10-P01`
- Prompt source: [prompts/ITEMS-SOUP-INN-BATCH-10-P01.md](./prompts/ITEMS-SOUP-INN-BATCH-10-P01.md)
- 게임용 초안: `chueo.png`, `yongbong.png`, `makgeol.png`, `jeon.png`, `dongdong.png`
- QA: [qa/items-soup-inn-batch-10.png](./qa/items-soup-inn-batch-10.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 추어탕은 짙은 녹갈색 탕과 미꾸라지 표식, 용봉탕은 밝은 탕의 닭다리와 비늘 생선 토막으로 구분된다.
- 용봉탕은 자료로 확인한 닭·잉어 조합만 쓰고 이름에서 연상될 수 있는 용·봉황·궁중 장식을 배제했다.
- 막걸리는 미색 병과 작은 흰 술잔, 동동주는 넓은 갈색 사발과 떠 있는 쌀알, 파전은 둥근 초록 파무늬로 갈린다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 국밥집 8종이 모두 채워지고 주막 첫 세 종도 분리됐지만 추어탕의 생선 표식과 용봉탕의 재료 가독성은 사용자 검수가 남았다.
- Hard fail 여부: 용·봉황·중국 궁전 문양·현대 술병 라벨·쟁반·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 추어탕의 미꾸라지가 너무 직접적으로 보이면 머리 디테일을 줄이고 굽은 몸 실루엣만 남긴다.
- 막걸리가 옹기점 술병과 비슷하면 작은 놋그릇의 흰 술 면적을 키운다.
- 주막 남은 묵무침·청주·보쌈·법주·구절판은 재료·그릇 구조를 먼저 다르게 한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-012 — 주막 나머지 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-INN-BATCH-11-P01`
- Prompt source: [prompts/ITEMS-INN-BATCH-11-P01.md](./prompts/ITEMS-INN-BATCH-11-P01.md)
- 게임용 초안: `muk.png`, `cheongju.png`, `bossam.png`, `beopju.png`, `gujeol.png`
- QA: [qa/items-inn-batch-11.png](./qa/items-inn-batch-11.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 묵무침은 갈색 정육면체, 보쌈은 배추 위 지방띠 편육, 구절판은 팔각 아홉 칸으로 서로 다른 위쪽 무늬를 가진다.
- 청주는 짧은 주둥이의 미색 주전자와 맑은 잔, 법주는 천을 묶은 넓은 황갈색 항아리와 진한 잔이다.
- 구절판은 화려한 색을 식재료에만 두고 상자는 금박 없는 짙은 목재로 제한했다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 주막 8종이 모두 채워졌고 술과 안주가 형태로 분리됐지만 실제 카드에서 구절판 칸 수와 술색 차이는 사용자 검수가 남았다.
- Hard fail 여부: 일본 사케병·중국 술항아리 문양·붉은 술·금박·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 청주가 일반 주전자로 보이면 잔의 맑은 황금빛 면적을 키운다.
- 구절판 칸 수가 축소에서 사라지면 상자 크기를 키우고 내부 재료 세부를 줄인다.
- 다음 꼬치집은 꼬치 재료의 색과 외곽선보다 막대 위 덩어리 구조를 우선한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-013 — 꼬치집 첫 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SKEWER-BATCH-12-P01`
- Prompt source: [prompts/ITEMS-SKEWER-BATCH-12-P01.md](./prompts/ITEMS-SKEWER-BATCH-12-P01.md)
- 게임용 초안: `tteokggo.png`, `dakggo.png`, `beoseot.png`, `saengseon.png`, `sanjeok.png`
- QA: [qa/items-skewer-batch-12.png](./qa/items-skewer-batch-12.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 떡꼬치는 흰 원통, 닭꼬치는 네모 닭과 파 토막, 버섯꼬치는 표고 갓과 느타리 송이가 반복된다.
- 생선꼬치는 통생선 한 마리, 산적은 납작한 고기·달걀·파·버섯 줄무늬라 내부 리듬이 다르다.
- 불꽃과 연기 없이 작은 그을음만 넣어 굽기 상태를 표시했다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 같은 대각선 막대 구조 안에서 다섯 품목이 분리됐지만 실제 점장 손 오버레이에서 긴 품목이 지나치게 작아지지 않는지 검수가 남았다.
- Hard fail 여부: 현대 빨간 소스·접시·불꽃·연기·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 꼬치가 점장 손에서 너무 작으면 PNG를 다시 그리기보다 실제 알파 경계 기반 최대 폭 규칙을 조정한다.
- 버섯꼬치의 표고 별무늬가 장식처럼 보이면 칼집 폭만 줄인다.
- 꼬치집 마지막 장어구이·너비아니·육회는 막대가 아닌 접시 구조로 전환해 반복을 끊는다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-014 — 꼬치집 마무리·떡집 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-SKEWER-RICECAKE-BATCH-13-P01`
- Prompt source: [prompts/ITEMS-SKEWER-RICECAKE-BATCH-13-P01.md](./prompts/ITEMS-SKEWER-RICECAKE-BATCH-13-P01.md)
- 게임용 초안: `jangeo.png`, `neobiani.png`, `yukhoe.png`, `garae.png`, `injeol.png`
- QA: [qa/items-skewer-ricecake-batch-13.png](./qa/items-skewer-ricecake-batch-13.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 장어구이는 긴 쌍, 너비아니는 넓은 격자 고기 세 장, 육회는 배채가 섞인 붉은 가는 채 무더기다.
- 가래떡은 볏짚 묶음의 흰 원통, 인절미는 콩고물 네모라 첫 떡 두 종이 형태와 색으로 함께 갈린다.
- 육회는 피·방울·날달걀 없이 정돈된 재료 무더기로 비그래픽하게 표현했다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 꼬치집 8종이 모두 채워지고 떡집의 흰쌀·콩고물 기준도 시작됐지만 실제 카드에서 가래떡이 소품 막대처럼 보이지 않는지 검수가 남았다.
- Hard fail 여부: 피·날달걀·현대 장식·불꽃·연기·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 육회가 붉은 면처럼 보이면 배채를 줄이고 고기채의 짧은 굽음을 키운다.
- 가래떡이 나무 막대처럼 보이면 잘린 단면의 흰쌀 결만 조금 키운다.
- 떡집 남은 송편·백설기·약식·화전·다식·유과는 색보다 빚기·쌓기·찍기 구조를 우선한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-015 — 떡집 형태 대비 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-RICECAKE-BATCH-14-P01`
- Prompt source: [prompts/ITEMS-RICECAKE-BATCH-14-P01.md](./prompts/ITEMS-RICECAKE-BATCH-14-P01.md)
- 게임용 초안: `songpyeon.png`, `baekseol.png`, `yaksik.png`, `hwajeon.png`, `dasik.png`
- QA: [qa/items-ricecake-batch-14.png](./qa/items-ricecake-batch-14.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 송편은 반달과 솔잎, 백설기는 잘린 모서리가 있는 큰 흰 입방체, 약식은 재료가 박힌 짙은 찰밥 사각이다.
- 화전은 분홍꽃이 중심인 납작한 원, 다식은 팔각판 안의 작은 3×3 반복이라 접시 음식끼리도 외곽과 내부 리듬이 갈린다.
- 다섯 품목을 나란히 줄인 QA에서 색을 보지 않아도 높이·개수·배치 구조로 구분된다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 떡집의 형태 대비는 확보됐지만 실제 점장 손 오버레이와 사용자 미감 승인이 남았다.
- Hard fail 여부: 현대 포장·라벨·금박·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 송편의 접시가 다른 음식과 겹쳐 보이면 솔잎보다 반달 개수와 겹침을 먼저 조정한다.
- 백설기가 건축 블록처럼 보이면 잘린 단면의 쌀알 결만 약하게 키운다.
- 다식의 개별 문양은 화면에서 사라져도 3×3 배열이 읽히므로 런타임용 선을 추가하지 않는다.
- 떡집 마지막 유과와 푸줏간 4종은 밝은 튀김·원육·손질 고기의 재료 실루엣을 먼저 구분한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-016 — 떡집 마무리·푸줏간 시작 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-RICECAKE-BUTCHER-BATCH-15-P01`
- Prompt source: [prompts/ITEMS-RICECAKE-BUTCHER-BATCH-15-P01.md](./prompts/ITEMS-RICECAKE-BUTCHER-BATCH-15-P01.md)
- 게임용 초안: `yugwa.png`, `dwaeji.png`, `dak.png`, `sogogi.png`, `galbi.png`
- QA: [qa/items-ricecake-butcher-batch-15.png](./qa/items-ricecake-butcher-batch-15.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 유과는 볶은 쌀알 결이 붙은 밝은 긴 타원 여섯 개라 떡집의 다른 매끈한 떡과 구분된다.
- 돼지고기는 층진 지방과 볏짚 묶음, 닭고기는 교차한 닭다리, 쇠고기는 넓은 둥근 살코기, 갈비는 미색 뼈가 돌출된 직사각이다.
- 네 고기 품목은 모두 피·칼·도축 없이 정돈된 식재료로 표현됐고 축소 QA에서도 받침보다 재료 외곽이 먼저 읽힌다.
- 다섯 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 푸줏간 첫 네 품목이 색만이 아니라 구조로 갈렸지만 실제 판매 오버레이와 사용자 미감 승인이 남았다.
- Hard fail 여부: 피·도축·사체·머리·발·칼·현대 포장·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 쇠고기와 갈비가 비슷하게 보이면 쇠고기의 둥근 외곽보다 갈비의 짧은 돌출 뼈를 우선 키운다.
- 닭다리의 뼈 끝이 과도하게 커 보이면 고기 덩이 비율을 유지한 채 뼈 길이만 줄인다.
- 푸줏간 남은 우거지·곱창·안심·한우 등심은 잎 묶음·둥근 고리·길쭉한 필렛·굵은 마블링으로 가른다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-ITEM-017 — 푸줏간 마무리 4종 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-BUTCHER-STALL-BATCH-16-P01`
- Prompt source: [prompts/ITEMS-BUTCHER-STALL-BATCH-16-P01.md](./prompts/ITEMS-BUTCHER-STALL-BATCH-16-P01.md)
- 게임용 초안: `ugeoji.png`, `gopchang.png`, `ansim.png`, `hanwoo.png`
- QA: [qa/items-butcher-stall-batch-16.png](./qa/items-butcher-stall-batch-16.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 우거지는 짙은 잎 묶음, 곱창은 밝은 세 겹 고리, 안심은 끝이 가는 긴 필렛, 한우 등심은 굵은 마블링의 두꺼운 타원이다.
- 기존 푸줏간 네 종과 함께 봐도 색만이 아니라 외곽과 내부 구조로 여덟 품목이 갈린다.
- 피·칼·도축 표현 없이 모두 정돈된 판매 식재료로 보인다.
- 네 런타임 파일은 정확한 `128×224`, RGBA, 실제 투명 배경, 중앙 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 자동 주문서의 물건 80종을 모두 채웠지만 실제 좌판·점장 손 오버레이와 사용자 미감 승인이 남았다.
- Hard fail 여부: 피·도축·사체·칼·현대 포장·문자·불투명 배경·등급 효과 없음.

#### 다음 수정

- 곱창이 소시지나 밧줄처럼 보이면 절단면보다 불규칙한 굵기와 짧은 고리 개수를 조정한다.
- 한우 등심의 마블링이 등급 빛처럼 보이면 선 굵기는 유지하되 면적을 줄인다.
- 사용자 승인 전까지 네 장 모두 `초안`이다.

### LOG-STALL-001 — 대장간 좌판 P01

- 날짜: `2026-08-22`
- Prompt ID: `ITEMS-BUTCHER-STALL-BATCH-16-P01`
- Prompt source: [prompts/ITEMS-BUTCHER-STALL-BATCH-16-P01.md](./prompts/ITEMS-BUTCHER-STALL-BATCH-16-P01.md)
- 게임용 초안: `godot/art/stalls/smith.png`
- QA: [qa/stall-smith-overlay-test-16.png](./qa/stall-smith-overlay-test-16.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 좌판은 낮고 넓은 U자형 목재·무쇠 받침이며 왼쪽 작은 모루와 오른쪽 짧은 쇠받침으로 대장간 업종을 표시한다.
- 중앙 윗부분은 비어 있어 곡괭이·가마솥·자물쇠가 좌판 그림 자체와 충돌하지 않는다.
- 현재 Godot의 `_stall()` 좌표를 2배로 재현하면 곡괭이는 상판에 닿지만 가마솥과 자물쇠는 투명 캔버스의 아래 여백만큼 뜬다.
- 런타임 파일은 정확한 `192×176`, RGBA, 실제 투명 배경, 하단 접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 첫 좌판의 공통 구조는 성립하지만 실제 알파 경계 기반 물건 바닥 정렬이 구현되고 Godot 화면에서 격자·계기·이름표 가림을 확인해야 한다.
- Hard fail 여부: 지붕·건물·불꽃·연기·상품 내장·문자·이름패·불투명 배경 없음.

#### 다음 수정

- 좌판 그림을 품목별로 바꾸지 않고 `낮은 공통 받침 + 양옆 업종 표식 + 빈 중앙`을 다음 아홉 좌판의 Hypothesis로 재사용한다.
- 클로드 요청 메모 12대로 좌판 물건은 실제 알파 경계 아랫변을 상판 기준선에 맞춘다.
- 실제 화면에서 모루가 물건보다 먼저 읽히면 모루 크기만 한 단계 줄인다.
- 사용자 승인 전까지 대장간 좌판은 `초안`이다.

### LOG-STALL-002 — 필방부터 국밥집까지 좌판 5종 P01

- 날짜: `2026-08-22`
- Prompt ID: `STALLS-BATCH-17-P01`
- Prompt source: [prompts/STALLS-BATCH-17-P01.md](./prompts/STALLS-BATCH-17-P01.md)
- 게임용 초안: `brush.png`, `paper.png`, `pot.png`, `herb.png`, `soup.png`
- QA: [qa/stalls-batch-17.png](./qa/stalls-batch-17.png) · [qa/stalls-overlay-test-17.png](./qa/stalls-overlay-test-17.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 대장간 좌판의 폭·높이·바닥 접점·빈 중앙을 유지하면서 필방은 한지 작업면, 지물포는 밝은 종이 옆선반, 옹기점은 흙 기단, 약재상은 양쪽 약장, 국밥집은 검은 온장판으로 갈렸다.
- 대표 물건을 현재 Godot 좌표로 겹쳐도 양옆 고정 설비가 남아 업종을 보조한다.
- 국밥집 최초 P01은 투명 배경 대신 회색 체크무늬가 픽셀로 포함돼 즉시 반려했고, 형태를 유지하며 실제 알파 배경으로 다시 만든 P02를 게임용 초안에 사용했다.
- 다섯 런타임 파일은 정확한 `192×176`, RGBA, 실제 투명 배경, 하단 접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 공통 골격과 업종 구분은 성립했지만 실제 Godot 격자에서 진행 계기·이름표·옆 좌판과의 간격 및 사용자 미감 승인이 남았다.
- Hard fail 여부: 게임용 다섯 장에는 건물·지붕·문자·이름패·불투명 배경 없음. 국밥집 P01의 체크무늬 배경은 `Rejected`로 별도 보존.

#### 다음 수정

- 옹기점의 흙 작업판과 국밥집의 검은 온장판처럼 큰 중앙 재료면은 물건을 가리지 않는 범위에서만 유지한다.
- 약재상 서랍 손잡이가 장식처럼 먼저 읽히면 손잡이 대비를 줄이고 서랍 덩어리를 유지한다.
- 남은 주막·꼬치집·떡집·푸줏간도 같은 골격에서 술상·숯홈·떡판·도마 고정 설비만 바꾼다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-STALL-003 — 주막부터 푸줏간까지 좌판 4종 P01

- 날짜: `2026-08-22`
- Prompt ID: `STALLS-BATCH-18-P01`
- Prompt source: [prompts/STALLS-BATCH-18-P01.md](./prompts/STALLS-BATCH-18-P01.md)
- 게임용 초안: `inn.png`, `skewer.png`, `ricecake.png`, `butcher.png`
- QA: [qa/stalls-batch-18.png](./qa/stalls-batch-18.png) · [qa/stalls-overlay-test-18.png](./qa/stalls-overlay-test-18.png) · [qa/stalls-all-10.png](./qa/stalls-all-10.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 주막은 멍석 술상과 잔받침, 꼬치집은 돌 숯홈과 빈 꼬치받침, 떡집은 밝은 떡판과 돌절구, 푸줏간은 두꺼운 도마와 저울·갈고리로 갈렸다.
- 대표 상품을 현재 Godot 좌표로 겹쳐도 양옆 고정 설비가 남아 업종을 보조한다.
- 열 좌판 전체가 같은 폭·높이·하단 접점·빈 중앙을 공유하면서 작업면 재료와 옆 설비만 달라 한 시스템으로 읽힌다.
- 떡집 최초 P01은 투명 배경 대신 체크무늬와 바닥 그림이 포함돼 즉시 반려했고, 형태를 유지하며 실제 알파 배경으로 다시 만든 P02를 게임용 초안에 사용했다.
- 네 런타임 파일은 정확한 `192×176`, RGBA, 실제 투명 배경, 하단 접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 필수 좌판 10종과 자동 주문서 170장을 모두 채웠지만 실제 Godot 마을 화면에서 이웃 좌판·진행 계기·이름표 가림 및 사용자 미감 승인이 남았다.
- Hard fail 여부: 게임용 네 장에는 건물·지붕·문자·이름패·불투명 배경 없음. 떡집 P01의 체크무늬 배경은 `Rejected`로 별도 보존.

#### 다음 수정

- 클로드 요청 메모 12의 실제 알파 경계 바닥 정렬을 적용한 뒤 가로형 물건이 좌판에 닿는지 다시 찍는다.
- 실제 화면에서 양옆 설비가 인접 격자와 겹치면 좌판 폭을 바꾸기보다 양옆 장식 대비와 높이를 줄인다.
- 필수 그림은 파일 존재만으로 확정하지 않고 실제 화면 검수와 사용자 승인을 기다린다.
- 다음 선택 제작은 가게별 점장 20장이다.

### LOG-CLERK-001 — 가게별 점장 첫 5장 P01

- 날짜: `2026-08-22`
- Prompt ID: `CLERKS-BATCH-19-P01`
- Prompt source: [prompts/CLERKS-BATCH-19-P01.md](./prompts/CLERKS-BATCH-19-P01.md)
- 게임용 초안: `smith-make.png`, `smith-sell.png`, `brush-make.png`, `brush-sell.png`, `paper-make.png`
- QA: [qa/clerks-batch-19.png](./qa/clerks-batch-19.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 다섯 장 모두 공용 V0.3 점주의 얼굴·몸·고리 없는 꼬리와 make/sell 팔 방향을 유지한다.
- 대장간은 짙은 가죽 앞치마와 한쪽 손목 보호대, 필방은 미색 앞치마·먹색 밑단·옆 붓, 지물포는 밝은 한지색 앞치마로 구분된다.
- `72×72` 축소에서는 작은 붓과 종이 조각보다 앞치마의 큰 색면이 먼저 읽히며, 전신 의상은 없다.
- 대장간 제작 P01과 필방 판매 P01의 체크무늬 배경은 반려 보존했다. 게임용은 실제 알파 배경 보정본을 사용한다.
- 다섯 런타임 파일은 정확한 `144×144`, RGBA, 실제 투명 배경, 하단 발접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 최소 업종 표식과 캐릭터 일관성은 성립했지만 실제 Godot 마을에서 공용 점장·직원과의 크기 비교 및 사용자 승인이 남았다.
- Hard fail 여부: 게임용 다섯 장에는 전신 옷·고리 꼬리·문자·UI·불투명 배경 없음. 반려 원본 2장은 체크무늬 배경이 있어 게임에 연결하지 않는다.

#### 다음 수정

- 다음 묶음도 앞치마의 큰 색면 하나와 작은 옆 표식 하나만 바꾼다.
- sell 포즈의 양손은 별도 판매 물건 오버레이를 위해 계속 비운다.
- 업종 표식이 `72×72`에서 사라져도 더 크게 그리지 않고 좌판과 상품이 함께 업종을 설명하게 한다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CLERK-002 — 가게별 점장 두 번째 5장 P01

- 날짜: `2026-08-22`
- Prompt ID: `CLERKS-BATCH-20-P01`
- Prompt source: [prompts/CLERKS-BATCH-20-P01.md](./prompts/CLERKS-BATCH-20-P01.md)
- 게임용 초안: `paper-sell.png`, `pot-make.png`, `pot-sell.png`, `herb-make.png`, `herb-sell.png`
- QA: [qa/clerks-batch-20.png](./qa/clerks-batch-20.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 지물포 판매는 먼저 만든 제작 포즈와 같은 밝은 한지색 앞치마·황갈색 단을 유지한다.
- 옹기점은 황토색 앞치마와 적갈색 단, 약재상은 쑥빛 앞치마와 미색 단으로 구분된다.
- 다섯 장 모두 공용 V0.3 점주의 얼굴·몸·고리 없는 꼬리와 make/sell 팔 방향을 유지한다.
- `72×72` 축소에서는 종이 조각·흙 얼룩·잎보다 앞치마 색면이 먼저 읽힌다.
- 지물포 판매와 옹기점 두 포즈의 생성 원본에는 픽셀 체크무늬가 들어와 원본으로 보존했고, 게임용은 가장자리 연결 배경만 투명 처리했다.
- 다섯 런타임 파일은 정확한 `144×144`, RGBA, 실제 투명 배경, 하단 발접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 색면과 포즈 일관성은 성립했지만 실제 Godot 마을에서 좌판·직원·판매 물건과 함께 보는 화면 검수 및 사용자 승인이 남았다.
- Hard fail 여부: 게임용 다섯 장에는 전신 옷·고리 꼬리·문자·UI·불투명 배경 없음. 체크무늬가 있던 원본은 게임에 연결하지 않는다.

#### 다음 수정

- 국밥집·주막·꼬치집도 앞치마 큰 색면 하나와 작은 옆 표식 하나만 바꾼다.
- sell 포즈의 양손은 별도 판매 물건 오버레이를 위해 계속 비운다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CLERK-003 — 가게별 점장 세 번째 5장 P01

- 날짜: `2026-08-22`
- Prompt ID: `CLERKS-BATCH-21-P01`
- Prompt source: [prompts/CLERKS-BATCH-21-P01.md](./prompts/CLERKS-BATCH-21-P01.md)
- 게임용 초안: `soup-make.png`, `soup-sell.png`, `inn-make.png`, `inn-sell.png`, `skewer-make.png`
- QA: [qa/clerks-batch-21.png](./qa/clerks-batch-21.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 국밥집은 짙은 밤색 앞치마와 수건 끝, 주막은 탁한 자주색 앞치마와 접은 흰 천, 꼬치집은 먹색 앞치마와 적갈색 옆끈으로 구분된다.
- 음식·술병·꼬치·불을 캐릭터에 고정하지 않아 판매 물건 오버레이와 다른 품목에 재사용할 수 있다.
- 다섯 장 모두 공용 V0.3 점주의 얼굴·몸·고리 없는 꼬리와 make/sell 팔 방향을 유지한다.
- 꼬치집 밑단의 작은 그을음은 확대에서는 보이지만 `72×72`에서는 먹색 큰 면만 먼저 읽힌다.
- 국밥집 제작과 주막 두 포즈의 생성 원본에는 픽셀 체크무늬가 들어와 원본으로 보존했고, 게임용은 가장자리 연결 배경만 투명 처리했다.
- 다섯 런타임 파일은 정확한 `144×144`, RGBA, 실제 투명 배경, 하단 발접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 음식점 세 업종의 색면 구분과 빈손 재사용성은 성립했지만 실제 Godot 합성 화면 및 사용자 승인이 남았다.
- Hard fail 여부: 게임용 다섯 장에는 전신 옷·고리 꼬리·고정 음식·문자·UI·불투명 배경 없음.

#### 다음 수정

- 꼬치집 판매를 같은 먹색 앞치마로 닫고, 떡집과 푸줏간 두 포즈를 만든다.
- 사용자 승인 전까지 다섯 장 모두 `초안`이다.

### LOG-CLERK-004 — 가게별 점장 마지막 5장 P01

- 날짜: `2026-08-22`
- Prompt ID: `CLERKS-BATCH-22-P01`
- Prompt source: [prompts/CLERKS-BATCH-22-P01.md](./prompts/CLERKS-BATCH-22-P01.md)
- 게임용 초안: `skewer-sell.png`, `ricecake-make.png`, `ricecake-sell.png`, `butcher-make.png`, `butcher-sell.png`
- QA: [qa/clerks-batch-22.png](./qa/clerks-batch-22.png)
- 상태: `Generated` / 그림 장부 `초안`

#### 관찰

- 꼬치집 판매는 앞서 만든 먹색 앞치마·적갈색 옆끈·그을음 밑단을 유지한다.
- 떡집은 따뜻한 아이보리 앞치마와 작은 쌀가루 자국, 푸줏간은 깊은 적갈색 가죽 앞치마와 한쪽 보호대로 구분된다.
- 칼·고기·떡·꼬치 같은 직접 상품 기호를 캐릭터에 고정하지 않아 별도 품목 오버레이를 계속 재사용할 수 있다.
- 푸줏간 보호대 방향은 두 포즈에서 미세하게 다르지만 `72×72`에서는 앞치마 큰 색면과 팔 자세가 먼저 읽힌다.
- 다섯 생성 원본의 픽셀 체크무늬는 원본으로 보존했고, 게임용은 가장자리 연결 배경만 투명 처리했다.
- 다섯 런타임 파일은 정확한 `144×144`, RGBA, 실제 투명 배경, 하단 발접점 정렬이다.

#### 판정

- 결과: `Generated`
- Why: 가게 10곳 × make/sell 전용 점장 20장 규격과 색면 체계를 모두 채웠지만 실제 Godot 이동·수면 폴백 및 사용자 승인이 남았다.
- Hard fail 여부: 게임용 다섯 장에는 전신 옷·고리 꼬리·날붙이·피·고정 상품·문자·UI·불투명 배경 없음.

#### 다음 수정

- 전용 점장 make/sell에서 공용 walk/sleep으로 바뀌는 순간의 앞치마 연속성을 실제 화면에서 검수한다.
- 다음 선택 제작은 손님 성장 카드 2단 첫 5장이다.
- 사용자 승인 전까지 전용 점장 20장 모두 `초안`이다.

## 새 로그 템플릿

아래 블록을 복제해 사용한다.

```markdown
### [LOG-ID] [짧은 이름]

- 날짜:
- Prompt ID:
- 기반 Blueprint 버전:
- 이미지 파일/링크:
- 상태: Generated
- 이번에 시험한 Hypothesis:

#### 관찰

- 잘 된 점:
- 어긋난 점:
- 축소 화면 가독성:

#### 판정

- 결과: Approved / Revision / Rejected
- Why:
- Hard fail 여부:

#### 다음 수정

- 프롬프트 수정:
- Blueprint 규칙 수정 후보:
- Hypothesis → Decision 승격 후보:
- 다음 Prompt ID:
```

## 검수 순서

### 1. 즉시 반려 항목

- 라쿤식 고리 꼬리 또는 선명한 검은 눈 마스크
- 중국식/일본식 대표 요소
- 소실점, 원근 수렴, 아이소메트릭 다이아몬드 그리드
- 큰 캐릭터 일러스트 중심 구도
- 텍스트, UI, 로고, 워터마크, 테두리

하나라도 있으면 세부 미감을 보기 전에 `Rejected` 또는 큰 수정이 필요한 `Revision`으로 판정한다.

### 2. 핵심 구조

- 9:16 세로형 실제 플레이 화면으로 구성되었는가?
- 폐허와 복구 상점이 같은 축척인가?
- 건물과 캐릭터 비율이 실제 게임 화면 같은가?
- 길, 상점 입구, 손님 동선이 읽히는가?
- 건축과 생활소품이 한국성을 우선 전달하는가?

### 3. 스타일

- charcoal outline이 일정한가?
- P01처럼 따뜻한 큰 색면, 절제된 부드러운 명암, 손으로 그린 가벼운 재료 질감인가?
- hanji grain이 미세한가?
- 그림자가 짧고 단순한가?
- 팔레트의 따뜻한 중립색이 주조색인가?

### 4. 감정과 성장성

- 폐허가 지나치게 참혹하지 않은가?
- 복구 상점 쪽이 손님과 정돈으로 더 살아 보이는가?
- 이후 수선과 번영 단계가 확장될 여지가 있는가?

## Decision 승격 규칙

- 이미지 한 장에서 우연히 잘 나온 요소는 곧바로 `Decision`이 아니다.
- 승인 질문에 명확히 답하고 재사용 가능한 값일 때만 승격한다.
- 승격 시 이 로그의 `LOG-ID`를 관련 문서 옆에 근거로 남긴다.
- 반려된 결과도 Why를 남겨 같은 실패가 다시 나오지 않게 한다.
