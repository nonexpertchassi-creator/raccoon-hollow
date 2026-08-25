/* art.mjs — 아직 없는 그림이 뭔지 세어서 주문서(ASSETS.md)를 갱신한다.
 *
 * 실행:  node tools/art.mjs          남은 그림을 화면에 뿌린다
 *        node tools/art.mjs --write  ASSETS.md의 목록 칸을 다시 쓴다
 *
 * 왜 도구로 만드나: 목록을 손으로 관리하면 반드시 어긋난다 — 그림을 넣고
 * 목록에서 지우는 걸 잊거나, 품목을 추가하고 목록에 안 적거나. 목록은
 * **content.js와 art/ 폴더에서 계산**하면 절대 안 어긋난다.
 */
import { readdirSync, existsSync, readFileSync, writeFileSync } from 'fs';
import { SHOPS, GUESTS, PESTS, STAFF_RANKS, CARD_GRADES } from '../content.js';

const ROOT = new URL('..', import.meta.url).pathname;
/* ★ 그림은 **godot/art/** 안에 산다. 저장소 뿌리(art/)가 아니다.
 *   Godot은 제 프로젝트 폴더(godot/) 밖의 파일을 못 읽는다 — 밖에 두면
 *   목록은 채워지는데 화면에는 영영 안 나오는, 제일 나쁜 종류가 된다. */
const DIR = 'godot/art';
const has = (dir, id) => existsSync(`${ROOT}${DIR}/${dir}/${id}.png`);

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
  { dir: 'hero', size: '144×144', title: '점장 너구리',
    rows: HERO.map(([id, why]) => ({ id, why })) },
  { dir: 'items', size: '128×224', title: '물건',
    note: '**두 군데에 쓰인다** — 매대 위(원래 크기)와 가게 창의 목록 썸네일(작게 줄여서).\n' +
          '그래서 작게 줄여도 뭔지 알아볼 수 있어야 한다 — 잔무늬보다 **실루엣**이 중요하다.\n\n' +
          '**등급 그림은 그리고 싶은 것만.** 가게를 승급하면 물건 이름이 바뀐다\n' +
          '(무쇠곡괭이 → 참쇠곡괭이 → 강철곡괭이). 그 등급 그림을 따로 주고 싶으면\n' +
          '`pick-1.png`(2등급) · `pick-2.png`(3등급)로 넣으면 그것부터 쓴다.\n' +
          '**없어도 된다** — 없으면 기본 그림에 등급 테(은·금)를 둘러 표시한다.\n' +
          '40종 × 3등급 = 120장을 다 그릴 이유는 없다.',
    rows: SHOPS.flatMap((s) => s.items.map((i) =>
      ({ id: i.id, why: `${s.name} · ${i.name} (지금 ${i.icon})` }))) },
  { dir: 'items', size: '128×224', title: '물건 승급판 (2·3등급)',
    note: '**등급 테두리(은·금 고리)를 지웠다** — 승급은 물건 그림 자체가 바뀌는 것으로 보여준다.\n' +
          '같은 물건이 격이 오른 모습으로: 무쇠도끼 → 참쇠도끼(날이 서고) → 강철도끼(광이 난다).\n' +
          '파일명은 `<물건id>-1.png`(2등급) · `<물건id>-2.png`(3등급).',
    rows: SHOPS.flatMap((sh) => sh.items.flatMap((i) => [1, 2].map((k) =>
      ({ id: `${i.id}-${k}`, why: `${sh.ranks[k]}${i.name} (${sh.name})` })))) },
  { dir: 'staff', size: '144×144', title: '직원 너구리',
    note: '**점장과 같은 몸, 같은 크기다.** 크기로 가르면 덜 자란 너구리처럼 보인다 —\n' +
          '둘은 같은 너구리고 맡은 일만 다르다. 가르는 것은 **머리에 쓴 것**이다.\n' +
          '점장은 손에 연장(망치 같은 것)을 들고, 직원은 그냥 모자만 쓴다.\n' +
          '등급도 모자로만 가른다 — 몸은 네 등급이 똑같아도 된다. 위로 갈수록 격이 오른다.\n' +
          '`work`는 일하는 자세, `sleep`은 조는 자세 — 진열대가 다 차면 존다.\n' +
          '★ **틀 안 채움을 점장과 똑같이** — 지금 직원 그림이 점장보다 작게 차 있어\n' +
          '화면에서 몸집이 달라 보인다(코드 크기는 둘 다 72로 같다). 발끝~정수리가\n' +
          '틀의 9할을 차게 그리면 같은 몸집이 된다. 등급 이름이 바뀌었다:\n' +
          '머리띠 → 흰 두건 → 회색 두건 → 검정 두건(whitehood·grayhood·blackhood).',
    rows: STAFF_RANKS.flatMap((r) => [['work', '일하는 중'], ['sleep', '조는 중 — 만들 데가 없다']]
      .map(([pose, why]) => ({ id: `${r.id}-${pose}`, why: `${r.name} · ${r.hat} — ${why}` }))) },
  { dir: 'guests', size: '128×128', title: '손님',
    note: '마을에 걸어 들어오는 모습. **카드 그림과 다르다** — 이건 옆에서 본 걷는 모습이고,\n' +
          '카드는 정면으로 선 초상이다. 여기부터 있어야 마을이 회색 덩어리를 벗는다.\n' +
          '괄호 안이 카드 등급이다 — 귀한 짐승일수록 귀티가 나야 한다.',
    rows: GUESTS.map((g) => ({ id: g.id,
      why: `${g.name} (${CARD_GRADES[g.grade - 1].name}) — ${g.desc}` })) },
  { dir: 'guests', size: '128×128', title: '손님 정면·뒷모습',
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
          '파일 이름은 `<손님id>-1.png`. 6~10성은 `-2`, 11~15성은 `-3`, 16~20성은 `-4`.',
    rows: GUESTS.map((g) => ({ id: `${g.id}-1`,
      why: `${g.name} (${CARD_GRADES[g.grade - 1].name}) — 1~5성` })) },
  { dir: 'cards', size: '512×768', title: '점장 카드 (가게를 열 때 뜨는 초상)',
    note: '가게를 되살리거나 승급하면 화면 가운데에 카드가 뜬다 — **그 초상이 여태 없었다.**\n' +
          '손님 카드와 같은 규격(세로 초상, 배경까지). 그 가게 점장 너구리가 제 일터에서\n' +
          '일하는 모습으로. 파일명은 `<가게id>-1.png`(첫 등급). 승급 등급(-2, -3)은 선택.',
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
          '승급 그림(`smith-1.png`·`smith-2.png`)을 넣으면 등급 따라 갈아입는다(선택).\n' +
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
          '승급 그림(`smith-1.png`)도 넣을 수 있다. 없으면 기본 것을 쓴다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} — ${sh.desc || ''}`.trim() })) },
  { dir: 'ui', size: '아래 참고', title: '뽑기와 룰렛 판',
    note: '움직임은 `MOTION.md`에 적어 뒀다.\n' +
          '· `back.png` 512×768 — 카드 뒷면. 뒤집기 연출에 쓴다. 등급 빛은 코드가 얹는다\n' +
          '· `wheel.png` 512×512 — 룰렛 원판. **열두 칸**이 그려진 바퀴. 칸 안 글자는 코드가 얹는다\n' +
          '· `needle.png` 64×96 — 룰렛 바늘. 위에서 아래를 가리킨다',
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
  /* ★ 점장은 이제 **겹그림 계약**이다(2026-08-25, 유저 설계).
   * 완성형으로 그리면 무늬 4 × 가게 15 × 등급 3이 곱해져 수백 장이 된다 —
   * 겹치면 본체 4 + 꼬리 4 + 팔 1 + 장비 45로 끝난다. 규칙:
   *  · 네 겹 전부 **같은 144×144 판**에, 본체 기준으로 핀을 맞춰 그린다
   *  · 저장본마다 가게에 무늬(a~d)가 한 번 배정된다 — 대장간이 A면 영원히 A
   *  · 측면은 훼이크 — 몸·얼굴은 정면 그대로, 팔 한 장만 얹고 좌우는 코드가 뒤집는다
   *  · 꼬리는 붙이지 말 것 — 코드가 엉덩이 축으로 천천히 흔든다
   *  · 손님 중 너구리는 없다 — 이 겹그림은 점장 전용이다
   *  · 아래 clerks/의 옛 완성형 20장은 본체가 올 때까지의 폴백으로만 쓰인다 */
  { dir: 'hero-body', size: '144×144', title: '점장 본체 무늬', optional: true,
    note: '벌거벗은 너구리 정면 본체. **장비도 꼬리도 없이** 몸통·팔·얼굴만.\n' +
          '네 무늬는 몸 윤곽이 완전히 같고 털 무늬(색·줄·점)만 다르다.',
    rows: ['a', 'b', 'c', 'd'].map((f) => ({ id: f, why: `무늬 ${f.toUpperCase()} — 같은 몸, 다른 털` })) },
  { dir: 'hero-tail', size: '144×144', title: '점장 꼬리', optional: true,
    note: '꼬리만 따로 한 장. 뿌리를 판의 한가운데 근처(엉덩이 자리)에 두면\n' +
          '코드가 그 축으로 천천히 흔든다 — 여러 프레임을 그리지 않는다.',
    rows: ['a', 'b', 'c', 'd'].map((f) => ({ id: f, why: `무늬 ${f.toUpperCase()} 꼬리` })) },
  { dir: 'hero-arm', size: '144×144', title: '점장 훼이크 측면 팔', optional: true,
    rows: [{ id: 'arm', why: '옆으로 뻗은 팔 한 장 — 걷기·계산 때 몸은 정면인 채 이것만 얹는다' }] },
  { dir: 'gear', size: '144×144', title: '가게 장비 (등급별)', optional: true,
    note: '본체 위에 겹치는 옷+도구 한 장. 1단은 수수하게, 3단은 화려하게 —\n' +
          '승급하면 너구리는 그대로고 **이 장비만** 갈아입는다.',
    rows: SHOPS.flatMap((sh) => [1, 2, 3].map((r) =>
      ({ id: `${sh.id}-${r}`, why: `${sh.name} ${r}단 장비와 도구` }))) },
  /* 옛 완성형 — 폴백용. 새로 그리지 말 것(위 겹그림 계약으로 대체됐다). */
  { dir: 'clerks', size: '144×144', title: '가게별 점장 (옛 계약 · 폴백)', optional: true,
    note: '이미 들어온 20장은 본체 무늬가 올 때까지 그대로 쓰인다. **추가 주문 없음.**',
    rows: [] },
];

let done = 0, total = 0;
const lines = [];
for (const g of GROUPS) {
  const left = g.rows.filter((r) => !has(g.dir, r.id));
  if (!g.optional) { done += g.rows.length - left.length; total += g.rows.length; }
  lines.push(`### ${g.title}${g.optional ? ' (선택)' : ''} — \`${DIR}/${g.dir}/\` · ${g.size} · **${left.length}장 남음**`, '');
  if (g.note) lines.push(g.note, '');
  if (!left.length) lines.push('전부 들어왔다. ✅', '');
  else {
    for (const r of left) lines.push(`- [ ] \`${r.id}.png\` — ${r.why}`);
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
