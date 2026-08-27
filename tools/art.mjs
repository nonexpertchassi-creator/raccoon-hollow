/* art.mjs — 아직 없는 그림이 뭔지 세어서 주문서(ASSETS.md)를 갱신한다.
 *
 * 실행:  node tools/art.mjs          남은 그림을 화면에 뿌린다
 *        node tools/art.mjs --write  ASSETS.md의 목록 칸을 다시 쓴다
 *        node tools/art.mjs --audit  **주문서에 없는 그림**을 찾는다(지울 후보)
 *
 * 왜 도구로 만드나: 목록을 손으로 관리하면 반드시 어긋난다 — 그림을 넣고
 * 목록에서 지우는 걸 잊거나, 품목을 추가하고 목록에 안 적거나. 목록은
 * **content.js와 art/ 폴더에서 계산**하면 절대 안 어긋난다.
 */
import { readdirSync, existsSync, readFileSync, writeFileSync, statSync } from 'fs';
import { SHOPS, GUESTS, PESTS, STAFF_RANKS, CARD_GRADES } from '../content.js';

const ROOT = new URL('..', import.meta.url).pathname;
/* ★ 그림은 **godot/art/** 안에 산다. 저장소 뿌리(art/)가 아니다.
 *   Godot은 제 프로젝트 폴더(godot/) 밖의 파일을 못 읽는다 — 밖에 두면
 *   목록은 채워지는데 화면에는 영영 안 나오는, 제일 나쁜 종류가 된다. */
const DIR = 'godot/art';
/* webp든 png든 있으면 들어온 것으로 친다 — 형식을 갈아타는 중이다.
 * 코드(art.gd)도 webp를 먼저 찾고 없으면 png를 찾는다. 둘이 어긋나면
 * 주문서는 "없다"는데 화면에는 나오는 유령이 생긴다. */
const has = (dir, id) =>
  existsSync(`${ROOT}${DIR}/${dir}/${id}.webp`) || existsSync(`${ROOT}${DIR}/${dir}/${id}.webp`);

/* 점장 포즈. work·sell만 있으면 나머지는 코드가 돌려 쓴다 — 그래서 순서가 이렇다. */
const HERO = [
  ['raccoon-make',  '만드는 중 — 망치를 내려친다'],
  ['raccoon-sell',  '파는 중 — 오른팔을 뻗어 건넨다 (★손바닥은 비워 둘 것)'],
  ['raccoon-walk1', '걷기 1 — 왼발 앞'],
  ['raccoon-walk2', '걷기 2 — 오른발 앞'],
  ['raccoon-sleep', '조는 중 — 진열대가 다 차서 할 일이 없다'],
  ['mayor',         '촌장 — 마을을 돌아다닌다. 흰 수염과 지팡이. **마당 밖으로 나오는 유일한 너구리**'],
];

const GROUPS = [
  /* 공통 점장(걷기·자세들)과 촌장 — 겹그림 본체가 오기 전의 폴백이고,
   * 촌장은 계속 이 그림을 쓴다. 추가 주문 없음(전부 들어왔다). */
  { dir: 'hero', size: '144×144', title: '점장 너구리 (폴백) · 촌장',
    rows: HERO.map(([id, why]) => ({ id, why })) },
  { dir: 'items', size: '128×224', title: '물건 (등장하는 단의 그림만)',
    note: '**두 군데에 쓰인다** — 매대 위(원래 크기)와 가게 창의 목록 썸네일(작게 줄여서).\n' +
          '그래서 작게 줄여도 뭔지 알아볼 수 있어야 한다 — 잔무늬보다 **실루엣**이 중요하다.\n\n' +
          '★ **없는 그림은 목록에 없다**(2026-08-27). 마당의 매대가 4 → 6 → 8칸이라\n' +
          '물건도 그 수만큼만 열린다: 가게의 1~4번째 물건은 1단부터, 5~6번째는 2단부터,\n' +
          '7~8번째는 3단부터 나온다. **2단에 나오는 물건의 1단 그림은 영영 안 쓰인다** —\n' +
          '그런 그림을 그리게 만드는 목록이 제일 비싼 낭비다(유저가 잡았다).\n' +
          '그래서 가게 하나가 24장이 아니라 **18장**이다(4×3 + 2×2 + 2×1). 15가게면 270장.\n\n' +
          '파일명: 1단은 `<물건id>.webp`, 2단은 `<물건id>-1.webp`, 3단은 `<물건id>-2.webp`.\n' +
          '같은 물건이 격이 오른 모습으로 — 무쇠도끼 → 참쇠도끼(날이 서고) → 강철도끼(광이 난다).\n' +
          '등급 테두리(은·금 고리)는 코드가 안 그린다. **그림이 곧 등급이다.**',
    rows: SHOPS.flatMap((sh) => sh.items.flatMap((it, k) => {
      /* 이 물건이 처음 나오는 단: 1~4번째=1단(0) · 5~6번째=2단(1) · 7~8번째=3단(2).
         매대 칸 수(4·6·8)와 같은 규칙이다 — sim.stall_cap과 한 몸으로 움직인다. */
      const from = k < 4 ? 0 : (k < 6 ? 1 : 2);
      const tiers = [];
      for (let r = from; r < 3; r++) tiers.push(r);
      return tiers.map((r) => ({
        id: r === 0 ? it.id : `${it.id}-${r}`,
        why: `${sh.ranks[r]}${it.name} (${sh.name} ${r + 1}단${from === r ? ' — 여기서 처음 나온다' : ''})`,
      }));
    })) },
  /* ★ 직원 개념 폐지(2026-08-26, 유저) — 승급하면 같은 가게 너구리가 한
   * 마리 더 온다(전원 완성형 점장 그림). 두건 직원 그림은 은퇴 — 이미 온
   * 20장은 폴백으로만 남고, **추가 제작 금지.** */
  /* ★ 걷는 모습이 목록에 아예 없었다(2026-08-27에 잡았다) — 손님 그림의
   * **기본**인데 주문서가 한 번도 달라고 하지 않았다. 도감을 갈아 새 짐승이
   * 아홉 들어왔을 때 그들만 조용히 빠져 있었다. 주문서에 없는 그림은
   * 그려지지 않는다. */
  { dir: 'guests', size: '144×144', title: '손님 걷는 모습 (기본)',
    note: '**손님 그림의 기본이자 필수.** 마을 길을 걸어와 줄을 선다.\n' +
          '옆에서 본 걷는 모습 한 장이면 된다 — 왼쪽으로 갈 때는 코드가 뒤집는다.\n' +
          '2등신(머리 둘 높이)으로, 배경 없이. 발이 그림 맨 아래에 닿게 그린다.',
    rows: GUESTS.map((g) => ({ id: g.id, why: `${g.face} ${g.name} — ${g.desc}` })) },
  { dir: 'guests', size: '144×144', title: '손님 정면·뒷모습',
    note: '**옆모습 한 장으로 때우려던 것을 되돌렸다**(만드는 사람 결정).\n' +
          '`-front`(정면) — 줄에 서서 계산할 때 카메라를 본다.\n' +
          '`-back`(뒷모습) — 화면 위로 걸어 올라갈 때. 좌우는 여전히 코드가 뒤집는다.\n' +
          '없는 방향은 옆모습으로 때우니, 흔한 손님부터 한 장씩 넣으면 된다.',
    rows: GUESTS.flatMap((g) => [['front', '정면 — 줄 설 때'], ['back', '뒷모습 — 올라갈 때']]
      .map(([d, why]) => ({ id: `${g.id}-${d}`, why: `${g.name} ${why}` }))) },
  /* 카드는 5성 단위로 갈아입는다. 30종 × 4장 = 120장이라 **한꺼번에 하지 않는다** —
   * 1단(1~5성)만 있어도 게임이 다 돌아간다. 그래서 1단만 합계에 넣고 나머지는 선택. */
  { dir: 'cards', size: '512×768', title: '손님 카드 1단 (1~5성)',
    note: '**세로로 긴 초상.** 정면을 보고 서 있는 모습, 배경까지 그린 한 장.\n' +
          '뽑기에서 크게 뜨고 도감에 모인다 — 이 게임에서 제일 오래 들여다보는 그림이다.\n' +
          '테두리·등급 표시는 코드가 그린다. **짐승과 배경만** 그리면 된다.\n' +
          '파일 이름은 `<손님id>-1.webp`. 6~10성은 `-2`, 11~15성은 `-3`, 16~20성은 `-4`.',
    rows: GUESTS.map((g) => ({ id: `${g.id}-1`,
      why: `${g.name} (${CARD_GRADES[g.grade - 1].name}) — 1~5성` })) },
  { dir: 'cards', size: '512×768', title: '점장 카드 (가게를 열 때 뜨는 초상)',
    note: '가게를 되살리거나 승급하면 화면 가운데에 카드가 뜬다 — **그 초상이 여태 없었다.**\n' +
          '손님 카드와 같은 규격(세로 초상, 배경까지). 그 가게 점장 너구리가 제 일터에서\n' +
          '일하는 모습으로. 파일명은 `<가게id>-1.webp`(첫 등급). 승급 등급(-2, -3)은 선택.',
    rows: SHOPS.map((sh) => ({ id: `${sh.id}-1`, why: `${sh.name} 점장 초상 — ${sh.desc}` })) },
  { dir: 'cards', size: '512×768', title: '점장 카드 승급판 (2·3등급)', optional: true,
    rows: SHOPS.flatMap((sh) => [2, 3].map((k) => ({ id: `${sh.id}-${k}`,
      why: `${sh.name} — ${sh.ranks[k - 1]} 등급` }))) },
  { dir: 'counters', size: '168×144', title: '계산대', optional: true,
    note: '점장이 서서 파는 곳. **정면치기 한 장이면 된다** — 마당 문 방향에 따라\n' +
          '코드가 좌우로 뒤집는다. 좌우 비대칭 소품(주판·엽전함)을 올려도 뒤집혀\n' +
          '어색하지 않게, 되도록 가운데 배치로. 없으면 나무 상자를 그린다.\n' +
          '★ **방향 약속**: 손님이 받아 가는 넓은 면이 그림의 **오른쪽 아래**를\n' +
          '보게 그린다(길이 그쪽이다). 왼쪽 골목을 보는 가게는 코드가 뒤집는다 —\n' +
          '지금 임시 상자가 어색해 보이는 건 방향이 없어서다(유저가 필방·옹기점·\n' +
          '약재상에서 잡았다). 그림이 오면 이 약속대로 방향이 생긴다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} 계산대` })) },
  { dir: 'kilns', size: '168×192', title: '가마·풀무',
    note: '마당 뒤쪽의 만드는 기계 — 대장간은 풀무·화덕, 옹기점은 가마, 국밥집은 가마솥.\n' +
          '승급 그림(`smith-1.webp`·`smith-2.webp`)을 넣으면 등급 따라 갈아입는다(선택).\n' +
          '없으면 코드가 등급 따라 키우고 불을 세게 피운다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} — ${sh.desc}` })) },
  { dir: 'cards', size: '512×768', title: '손님 카드 2~4단 (6~20성)', optional: true,
    note: '**나중에.** 없으면 1단 그림을 계속 쓴다.\n' +
          '같은 짐승이 성이 오를수록 차림이 좋아지는 식으로 — 옷·장신구·배경이 달라진다.',
    rows: GUESTS.flatMap((g) => [2, 3, 4].map((k) => ({ id: `${g.id}-${k}`,
      why: `${g.name} — ${[6, 11, 16][k - 2]}~${[10, 15, 20][k - 2]}성` }))) },
  { dir: 'pests', size: '128×128', title: '나쁜 놈',
    rows: [...PESTS.map((p) => ({ id: p.id, why: `${p.name} — 눌러서 잡는다` })),
           { id: 'dog', why: '삽살개 — 앉아서 지킨다' }] },
  { dir: 'stalls', size: '192×176', title: '매대(좌판)',
    note: '가게마다 **다르게 생겨야 한다.** 지금은 다섯 가게가 똑같은 나무 상자다.\n' +
          '그 가게에서 무엇을 파는지가 좌판에서 먼저 읽혀야 한다 —\n' +
          '대장간은 모루·쇠받침, 필방은 낮은 서안, 지물포는 종이 두루마리 선반,\n' +
          '옹기점은 흙바닥 좌판, 약재상은 약재 서랍장 같은 식으로.\n' +
          '**물건 그림이 이 위에 얹힌다** — 가운데 위쪽을 비워 둘 것.\n' +
          '승급 그림(`smith-1.webp`)도 넣을 수 있다. 없으면 기본 것을 쓴다.\n' +
          '★ **↙ 한 장만 그리면 된다** — ↘쪽은 코드가 거울로 뒤집는다. 다만 거울은\n' +
          '빛 방향(왼쪽 위 광원)까지 뒤집으므로, 비대칭이 심해 어색한 가게만\n' +
          '`<가게id>-r.webp`(↘판)를 따로 주면 그걸 쓴다. 되도록 좌우 대칭에 가깝게\n' +
          '구성하면 ↘판 없이도 자연스럽다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} — ${sh.desc || ''}`.trim() })) },
  { dir: 'ui', size: '아래 참고', title: '뽑기와 룰렛 판',
    note: '움직임은 `MOTION.md`에 적어 뒀다.\n' +
          '· `back.webp` 512×768 — 카드 뒷면. 뒤집기 연출에 쓴다. 등급 빛은 코드가 얹는다\n' +
          '· `wheel.webp` 512×512 — 룰렛 원판. **열두 칸**이 그려진 바퀴. 칸 안 글자는 코드가 얹는다\n' +
          '· `needle.webp` 64×96 — 룰렛 바늘. 위에서 아래를 가리킨다',
    rows: [
      { id: 'back', why: '카드 뒷면 512×768 — 뒤집기 전에 보이는 면' },
      { id: 'wheel', why: '룰렛 원판 512×512 — 칸 열둘이 나뉜 바퀴' },
      { id: 'needle', why: '룰렛 바늘 64×96 — 위에서 아래를 가리킨다' },
      { id: 'coin', why: '엽전 64×64 — 계산대 위·팔린 표에 쓴다 (상평통보처럼 가운데 네모 구멍)' },
      { id: 'gem', why: '젬 64×64 — 💎 이모지 자리를 물려받는다' },
    ] },
  /* 선택 — 프로필 초상. 없으면 이모지 얼굴로 돈다. */
  { dir: 'portraits', size: '256×256', title: '프로필 초상', optional: true,
    note: '머리띠(위 표시줄) 왼쪽의 동그란 얼굴. 규격 네 줄이면 된다:\n' +
          '1. **동그란 틀 안에** 그린다 — 원 밖은 투명. 코드가 네모로 자르지 않는다.\n' +
          '2. **어깨까지 상반신**, 살짝 위에서 본 정면(3/4). 얼굴이 원의 7~8할.\n' +
          '3. 배경은 투명. 테두리 띠(칭호 색)와 바탕은 코드가 두른다.\n' +
          '4. 표정은 그 짐승의 성격대로(BESTIARY.md 참고) — 호랑이는 위엄, 토끼는 촐랑.\n' +
          '카드(512×768)와 같은 그림체·팔레트다. 카드가 이미 있는 손님은 그 얼굴을\n' +
          '동그란 틀에 다시 앉히면 된다 — 새로 창작할 필요 없다.',
    rows: [{ id: 'raccoon', why: '기본 얼굴 — 주인공 너구리' }]
      .concat(GUESTS.map((g) => ({ id: g.id, why: `${g.name} — 뽑으면 고를 수 있다` }))) },
  /* ★ 겹그림(조립) 계약은 2026-08-26에 접었다 — **완성형으로 회귀**(유저 결정).
   * 이유: 장수가 비슷하고(155 vs 135), 스티커 핀 맞추기가 AI 그림의 제일
   * 약한 고리이며, "대장간 점장 = 망치 든 너구리"라는 가게 정체성이 무늬
   * 다양성보다 값지다. hero-body/·hero-tail/·gear/ 폴더는 **쓰지 않는다 —
   * 추가 제작 금지.** (들어온 A무늬는 새 점장이 올 때까지 임시로 돈다) */
  /* ★ 최종 확정(2026-08-26, 유저): **가게마다 일꾼 세트가 따로 있다.**
   * 한 세트 = 무늬 4(a주황·b회색·c적갈·d삼색) × 방향 2(side·back) ×
   * 앞치마 3단(없음·-1·-2) = 24장. 대장간 시트가 첫 세트다.
   * 무늬는 채용마다 랜덤, 복장은 가게가, 앞치마는 등급이 정한다. */
  /* ★ 일꾼 너구리는 **가게를 안 가린다**(2026-08-27, 유저).
   *
   *   가게마다 전용으로 그리면 무늬 4 × 방향 2 × 가게 20 = 160장이고,
   *   가게가 늘 때마다 8장씩 늘어 "무한히 계속 뽑아야" 한다.
   *   게다가 그동안 이름 체계가 셋으로 갈려 싸우고 있었다 —
   *   `<가게>-<자세>`(20장 있음) · `<가게>-<무늬>-<방향>`(0장, 주문서만 시킴) ·
   *   `hero-body/<무늬>-<방향>`(5장). 그래서 걷는 점장과 일하는 점장이
   *   다르게 생겼다. **주문서가 코드에 없는 걸 시키고 있었던 것이다.**
   *
   *   이제 한 갈래다: `hero-body/<무늬>-<자세>`.
   *   가게가 늘어도 **0장**. 무늬(타입)를 하나 그리면 **모든 가게에서 동시에**
   *   쓰인다 — 그래서 무늬는 일감이 아니라 **모으는 재미**다.
   *
   *   아래 목록은 코드가 실제로 찾는 이름 그대로다(village.gd `_clerk_layers`). */
  { dir: 'hero-body', size: '144×144', title: '일꾼 너구리 (무늬 × 자세) — 모든 가게가 같이 쓴다',
    note: '파일명: `<무늬>-<자세>.webp`. 자세 다섯: `side`(옆·걷기 겸용) ·\n' +
          '`back`(뒷모습) · `make`(만드는 중) · `sell`(파는 중, ★손바닥은 비워 둘 것) ·\n' +
          '`sleep`(조는 중). side는 오른쪽 훼이크 측면 — 왼쪽은 코드가 뒤집는다.\n' +
          '**앞치마·연장은 안 그린다.** 가게 정체성은 마당(가마·매대·현판)과\n' +
          '손에 든 물건이 낸다 — 그 그림은 이미 있다.\n' +
          '그림자·꼬리 낱장 금지. 발끝은 아래 변, 몸은 가로 정중앙.\n' +
          '없는 자세는 코드가 옆모습으로, 없는 무늬는 무늬 A로 때운다 —\n' +
          '**무늬 하나를 다섯 자세까지 끝내는 편이** 넷을 반쯤 하는 것보다 낫다.',
    rows: ['a', 'b', 'c', 'd'].flatMap((f) =>
      [['side', '옆(걷기 겸용)'], ['back', '뒤'], ['make', '만드는 중'],
       ['sell', '파는 중'], ['sleep', '조는 중']].map(([q, ko]) => (
        { id: `${f}-${q}`, why: `무늬 ${f.toUpperCase()} · ${ko}` }))) },
  /* 꼬리·차림·가게 전용 — **셋 다 안 시킨다.** 코드가 층으로 받아 줄 준비만
   * 되어 있고, 넣으면 저절로 얹힌다. 없어도 게임은 멀쩡히 돈다. */
  { dir: 'hero-tail', size: '144×144', title: '꼬리 낱장 (선택 — 몸 뒤에 깔린다)', optional: true,
    note: '몸에 꼬리를 같이 그리면 **안 그려도 된다**. 꼬리를 따로 흔들고 싶어질 때만.\n' +
          '몸과 같은 액자·같은 자리로 그린다 — 코드는 자리를 몸 하나로 정하고\n' +
          '꼬리를 그 위에 그대로 얹는다. 액자가 다르면 꼬리가 몸에서 떨어져 나간다.',
    rows: ['a', 'b', 'c', 'd'].flatMap((f) => [
      { id: `${f}-side`, why: `무늬 ${f.toUpperCase()} 꼬리 옆` },
      { id: `${f}-back`, why: `무늬 ${f.toUpperCase()} 꼬리 뒤` },
    ]) },
  { dir: 'gear', size: '144×144', title: '가게 앞치마·연장 (선택 — 몸 위에 얹는다)', optional: true,
    note: '파일명: `<가게>-<자세>.webp`. **너구리를 그리지 않는다** —\n' +
          '앞치마·머리쓰개·연장만, 나머지는 투명. 몸과 같은 액자·같은 자리.\n' +
          '무늬와 상관없이 한 벌만 그리면 무늬 넷에 다 얹힌다.\n' +
          '**안 그려도 된다** — 가게 정체성은 마당과 손에 든 물건이 이미 낸다.\n' +
          '가게 색을 내고 싶어질 때 한 가게씩 넣으면 그때부터 보인다.',
    rows: SHOPS.flatMap((sh) => [
      { id: `${sh.id}-make`, why: `${sh.name} · 차림 (만드는 중)` },
      { id: `${sh.id}-side`, why: `${sh.name} · 차림 (옆)` },
    ]) },
  { dir: 'clerks', size: '144×144', title: '가게 전용 점장 (선택 — 겹치기를 통째로 덮는다)', optional: true,
    note: '파일명: `<가게>-<자세>.webp` — 이미 스무 장이 들어와 있고 그대로 쓰인다.\n' +
          '**새로 안 시킨다.** 공통 너구리로 안 나오는 특별한 가게가 생겼을 때만.\n' +
          '있으면 그 가게는 겹치기를 건너뛰고 이 한 장으로 그려진다.',
    rows: SHOPS.flatMap((sh) => [
      { id: `${sh.id}-make`, why: `${sh.name} · 만드는 중` },
      { id: `${sh.id}-sell`, why: `${sh.name} · 파는 중` },
    ]) },
];

/* --audit — **주문서에 없는 그림**을 일러 준다.
 * 손님이 바뀌거나(박쥐→매) 물건이 갈리면 옛 그림이 폴더에 남는다. 그건
 * 화면에 안 나오면서 저장소만 불린다 — 그런데 눈으로는 절대 안 보인다.
 * 여기서 세면 다음에 또 셀 일이 없다. */
if (process.argv.includes('--audit')) {
  const want = new Map();               // dir → 기대하는 id 집합
  for (const g of GROUPS) {
    if (!want.has(g.dir)) want.set(g.dir, new Set());
    for (const r of g.rows) want.get(g.dir).add(r.id);
  }
  /* ★ 주문서에 없어도 **코드가 읽는** 그림이 있다. 이걸 모르면 이 도구는
   *   "안 쓴다"고 거짓말을 하고, 그 말을 믿고 지우면 화면에서 그림이 사라진다.
   *   실제로 한 번 그럴 뻔했다(2026-08-27).
   *   - items/<id>  : 주문서는 등장하는 단의 그림(-2·-3)만 시키지만,
   *                   art.gd의 ranked()가 못 찾으면 **기본 이름으로 내려온다**.
   *   - staff/band-*: clerks/ 그림이 없을 때 쓰는 폴백(village.gd).
   *                   band 말고 다른 무늬는 코드가 안 읽는다 — 그건 진짜 찌꺼기다. */
  for (const g of GROUPS) if (g.dir === 'items') for (const r of g.rows)
    want.get('items').add(r.id.replace(/-[123]$/, ''));
  want.set('staff', new Set(['band-work', 'band-sleep']));
  let n = 0, bytes = 0;
  for (const dir of readdirSync(`${ROOT}${DIR}`, { withFileTypes: true })) {
    if (!dir.isDirectory()) continue;
    const ok = want.get(dir.name);
    if (!ok) { console.log(`## ${dir.name}/ — 주문서에 없는 폴더 통째`); }
    for (const f of readdirSync(`${ROOT}${DIR}/${dir.name}`)) {
      if (!/\.(png|webp)$/.test(f)) continue;
      const id = f.replace(/\.(png|webp)$/, '');
      if (ok && ok.has(id)) continue;
      const { size } = statSync(`${ROOT}${DIR}/${dir.name}/${f}`);
      console.log(`  ${dir.name}/${f}  ${(size / 1024).toFixed(0)}KB`);
      n++; bytes += size;
    }
  }
  console.log(`\n주문서에 없는 그림 ${n}장 · ${(bytes / 1048576).toFixed(1)}MB`);
  process.exit(0);
}

let done = 0, total = 0;
const lines = [];
for (const g of GROUPS) {
  const left = g.rows.filter((r) => !has(g.dir, r.id));
  if (!g.optional) { done += g.rows.length - left.length; total += g.rows.length; }
  lines.push(`### ${g.title}${g.optional ? ' (선택)' : ''} — \`${DIR}/${g.dir}/\` · ${g.size} · **${left.length}장 남음**`, '');
  if (g.note) lines.push(g.note, '');
  if (!left.length) lines.push('전부 들어왔다. ✅', '');
  else {
    for (const r of left) lines.push(`- [ ] \`${r.id}.webp\` — ${r.why}`);
    lines.push('');
  }
}

const head = `> 이 칸은 \`node tools/art.mjs --write\`가 다시 쓴다.\n` +
  `> **그림을 폴더에 넣으면 목록에서 저절로 빠진다** — 손으로 지울 필요 없다.\n\n` +
  `**${done} / ${total}장** 들어왔다.\n`;
const body = head + '\n' + lines.join('\n').trimEnd() + '\n';

if (process.argv.includes('--write')) {
  const p = `${ROOT}ASSETS.md`;
  const md = readFileSync(p, 'utf8');
  const A = '<!-- 목록시작 -->', B = '<!-- 목록끝 -->';
  const i = md.indexOf(A), j = md.indexOf(B);
  if (i < 0 || j < 0) { console.error('ASSETS.md에 목록 표시가 없다'); process.exit(1); }
  writeFileSync(p, md.slice(0, i + A.length) + '\n' + body + '\n' + md.slice(j));
  console.log(`ASSETS.md 갱신 — ${done}/${total}장`);
} else {
  console.log(body);
}
