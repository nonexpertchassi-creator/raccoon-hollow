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
import { SHOPS, GUESTS, PESTS, STAFF_RANKS } from '../content.js';

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
];

const GROUPS = [
  { dir: 'hero', size: '144×144', title: '점장 너구리',
    rows: HERO.map(([id, why]) => ({ id, why })) },
  { dir: 'items', size: '128×224', title: '물건',
    note: '**두 군데에 쓰인다** — 매대 위(원래 크기)와 가게 창의 목록 썸네일(작게 줄여서).\n' +
          '그래서 작게 줄여도 뭔지 알아볼 수 있어야 한다 — 잔무늬보다 **실루엣**이 중요하다.',
    rows: SHOPS.flatMap((s) => s.items.map((i) =>
      ({ id: i.id, why: `${s.name} · ${i.name} (지금 ${i.icon})` }))) },
  { dir: 'staff', size: '144×144', title: '직원 너구리',
    note: '**점장과 같은 몸, 같은 크기다.** 크기로 가르면 덜 자란 너구리처럼 보인다 —\n' +
          '둘은 같은 너구리고 맡은 일만 다르다. 가르는 것은 **머리에 쓴 것**이다.\n' +
          '점장은 손에 연장(망치 같은 것)을 들고, 직원은 그냥 모자만 쓴다.\n' +
          '등급도 모자로만 가른다 — 몸은 네 등급이 똑같아도 된다. 위로 갈수록 격이 오른다.\n' +
          '`work`는 일하는 자세, `sleep`은 조는 자세 — 진열대가 다 차면 존다.',
    rows: STAFF_RANKS.flatMap((r) => [['work', '일하는 중'], ['sleep', '조는 중 — 만들 데가 없다']]
      .map(([pose, why]) => ({ id: `${r.id}-${pose}`, why: `${r.name} · ${r.hat} — ${why}` }))) },
  { dir: 'guests', size: '128×128', title: '손님',
    rows: GUESTS.map((g) => ({ id: g.id, why: `${g.name} — ${g.desc}` })) },
  { dir: 'pests', size: '128×128', title: '나쁜 놈',
    rows: [...PESTS.map((p) => ({ id: p.id, why: `${p.name} — 눌러서 잡는다` })),
           { id: 'dog', why: '삽살개 — 앉아서 지킨다' }] },
  /* 선택 — 없으면 공통 점장(hero/)으로 다 돌아간다. 그래서 합계에서 뺀다. */
  { dir: 'clerks', size: '144×144', title: '가게별 점장', optional: true,
    note: '가게마다 다른 너구리. **여기까지 오면 제일 좋다.**\n' +
          '대장간은 망치가 어울리고 필방은 앞치마가 어울린다 — 그 가게의 일이 보이게.\n' +
          '한 장이라도 있으면 그 가게만 이 그림을 쓰고, 없는 자리는 공통 점장이 선다.\n' +
          '`make`·`sell` 둘만 있어도 충분하다(걷기·조는 것은 공통 것을 쓴다).',
    rows: SHOPS.flatMap((sh) => [['make', '만드는 중'], ['sell', '파는 중']]
      .map(([pose, why]) => ({ id: `${sh.id}-${pose}`, why: `${sh.name} — ${why}` }))) },
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
