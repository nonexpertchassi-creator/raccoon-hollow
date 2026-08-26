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
  /* 공통 점장(걷기·자세들)과 촌장 — 겹그림 본체가 오기 전의 폴백이고,
   * 촌장은 계속 이 그림을 쓴다. 추가 주문 없음(전부 들어왔다). */
  { dir: 'hero', size: '144×144', title: '점장 너구리 (폴백) · 촌장',
    rows: HERO.map(([id, why]) => ({ id, why })) },
  { dir: 'items', size: '128×224', title: '물건',
    note: '**두 군데에 쓰인다** — 매대 위(원래 크기)와 가게 창의 목록 썸네일(작게 줄여서).\n' +
          '그래서 작게 줄여도 뭔지 알아볼 수 있어야 한다 — 잔무늬보다 **실루엣**이 중요하다.\n\n' +
          '**등급 그림은 그리고 싶은 것만.** 가게를 승급하면 물건 이름이 바뀐다\n' +
          '(무쇠곡괭이 → 참쇠곡괭이 → 강철곡괭이). 그 등급 그림을 따로 주고 싶으면\n' +
          '`pick-1.png`(2등급) · `pick-2.png`(3등급)로 넣으면 그것부터 쓴다.\n' +
          '★ 승급판은 이제 **필수 목록**(아래 "물건 승급판")에 있다 — 등급 테를\n' +
          '둘러 표시하던 것은 지웠다(판타지 RPG 같다는 유저 결정). 그림이 곧 등급이다.\n' +
          '40종 × 3등급 = 120장을 다 그릴 이유는 없다.',
    rows: SHOPS.flatMap((s) => s.items.map((i) =>
      ({ id: i.id, why: `${s.name} · ${i.name} (지금 ${i.icon})` }))) },
  { dir: 'items', size: '128×224', title: '물건 승급판 (2·3등급)',
    note: '**등급 테두리(은·금 고리)를 지웠다** — 승급은 물건 그림 자체가 바뀌는 것으로 보여준다.\n' +
          '같은 물건이 격이 오른 모습으로: 무쇠도끼 → 참쇠도끼(날이 서고) → 강철도끼(광이 난다).\n' +
          '파일명은 `<물건id>-1.png`(2등급) · `<물건id>-2.png`(3등급).',
    rows: SHOPS.flatMap((sh) => sh.items.flatMap((i) => [1, 2].map((k) =>
      ({ id: `${i.id}-${k}`, why: `${sh.ranks[k]}${i.name} (${sh.name})` })))) },
  /* ★ 직원 개념 폐지(2026-08-26, 유저) — 승급하면 같은 가게 너구리가 한
   * 마리 더 온다(전원 완성형 점장 그림). 두건 직원 그림은 은퇴 — 이미 온
   * 20장은 폴백으로만 남고, **추가 제작 금지.** */
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
          '승급 그림(`smith-1.png`)도 넣을 수 있다. 없으면 기본 것을 쓴다.\n' +
          '★ **↙ 한 장만 그리면 된다** — ↘쪽은 코드가 거울로 뒤집는다. 다만 거울은\n' +
          '빛 방향(왼쪽 위 광원)까지 뒤집으므로, 비대칭이 심해 어색한 가게만\n' +
          '`<가게id>-r.png`(↘판)를 따로 주면 그걸 쓴다. 되도록 좌우 대칭에 가깝게\n' +
          '구성하면 ↘판 없이도 자연스럽다.',
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
  /* ★ 겹그림(조립) 계약은 2026-08-26에 접었다 — **완성형으로 회귀**(유저 결정).
   * 이유: 장수가 비슷하고(155 vs 135), 스티커 핀 맞추기가 AI 그림의 제일
   * 약한 고리이며, "대장간 점장 = 망치 든 너구리"라는 가게 정체성이 무늬
   * 다양성보다 값지다. hero-body/·hero-tail/·gear/ 폴더는 **쓰지 않는다 —
   * 추가 제작 금지.** (들어온 A무늬는 새 점장이 올 때까지 임시로 돈다) */
  /* ★ 가게별 완성형 점장 계약(어제 것)도 취소(2026-08-26, 유저) — 일꾼은
   * **A~D 랜덤 너구리**로 간다(아래 hero-body). 가게 구분은 매대·가마·물건이
   * 말한다. clerks/의 옛 20장은 그림 없는 동안의 폴백 — 추가 제작 금지. */
  { dir: 'hero-body', size: '144×144', title: '일꾼 너구리 A~D (앞치마 3단 × 옆/뒤)',
    note: '가게 구분 없는 일꾼 너구리 — GPT 시트(2026-08-26) 그대로 확정.\n' +
          '무늬 넷: a=주황 · b=회색 · c=적갈 · d=삼색(노랑). 저장본이 너구리마다\n' +
          '무늬를 무작위 배정한다. **앞치마가 가게 등급 표시다**: 이름에 숫자\n' +
          '없음=1단(밝은 앞치마) · -1=2단(갈색) · -2=3단(진한 가죽).\n' +
          '방향 둘: -side(오른쪽 훼이크 측면, 오른팔 뻗음 — 왼쪽은 코드 뒤집기) ·\n' +
          '-back(뒷모습). 정면·꼬리 낱장·그림자 금지. 발끝은 아래 변, 가로 정중앙.',
    rows: ['a', 'b', 'c', 'd'].flatMap((f) => ['side', 'back'].flatMap((d) => [
      { id: `${f}-${d}`, why: `무늬 ${f.toUpperCase()} ${d} · 1단 앞치마` },
      { id: `${f}-${d}-1`, why: `무늬 ${f.toUpperCase()} ${d} · 2단 갈색 앞치마` },
      { id: `${f}-${d}-2`, why: `무늬 ${f.toUpperCase()} ${d} · 3단 가죽 앞치마` },
    ])) },
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
