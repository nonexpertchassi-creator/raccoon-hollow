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
