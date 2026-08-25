# STAFF-BAND-V0.2-P01 — 차렷 작업·몽글 수면 수정

## 상태

- 제작 상태: `Generated`
- 장부 상태: `초안`
- 승인 상태: 사용자 1차 확인 후 수정, 최종 화면 검수 전
- 사용자 피드백: 작업은 허리를 숙이지 않고 차렷 자세에서 손만 움직인다. 수면은 `zzz` 또는 몽글몽글한 표식을 보여줘도 된다.

## 수정 1 — `band-work.png`

- 편집 대상: `band-work` V0.1
- 몸통은 수직으로 세우고 두 발을 바닥에 붙인다.
- 작업 동작은 가슴 아래의 빈 두 앞발만 작게 엇갈리도록 표현한다.
- 허리 숙임, 달리기, 걷기, 무릎 꿇기, 연장, 동작선은 금지한다.
- 수면 포즈와 몸 높이를 맞춰 같은 알바로 보이게 한다.

## 수정 2 — `band-sleep.png`

- 편집 대상: `band-sleep` V0.1
- 캐릭터 본체와 크기는 그대로 유지한다.
- 머리 위 빈 공간에 미색의 작은 몽글 수면방울 세 개를 배치한다.
- 글자 `Z`·`zzz`, 말풍선 테두리, 별·달·베개는 사용하지 않는다.
- 생성 수정본이 캐릭터 본체까지 다시 그려서, 수면방울만 분리해 기존 본체에 합성했다.

## 공통 불변값

- 한국 너구리, 고리 없는 꼬리, 미색 머리띠, 점장과 같은 몸 크기
- 앞치마·전신 복식·모자·연장 없음
- 오른쪽을 보는 정면 3/4, 투명 PNG, 발끝 아래 변 정렬
- 원본 `144×144`, 화면 표시 `72×72`

## 산출물

- 수정 작업 마스터: `../generated/staff/STAFF-BAND-V0.2-work-master.png`
- 수면방울 소스: `../generated/staff/STAFF-BAND-V0.2-sleep-puffs-source.png`
- 수정 수면 합성본: `../generated/staff/STAFF-BAND-V0.2-sleep-master.png`
- V0.1 런타임 보존본: `../generated/staff/STAFF-BAND-V0.1-*-runtime.png`
- 게임용 현재 초안: `../../../godot/art/staff/band-work.png`, `../../../godot/art/staff/band-sleep.png`
