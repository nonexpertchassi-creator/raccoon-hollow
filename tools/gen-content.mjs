/* gen-content.mjs — content.js의 숫자를 GDScript로 뽑아낸다.
 * 실행: node tools/gen-content.mjs   → godot/rules/content.gd
 *
 * ★ 왜 손으로 안 옮기는가.
 *
 * content.js에는 숫자가 700줄 가까이 있다. 손으로 베끼면 반드시 어딘가
 * 틀린다. 그리고 틀려도 안 보인다 — 대장간 도끼 값이 260이어야 하는데
 * 250으로 적혀 있으면, 게임은 멀쩡히 돌고 몇 시간 뒤에 곡선만 이상해진다.
 *
 * 뽑아내면 틀릴 수가 없다. 게다가 이관하는 동안 숫자를 더 만질 텐데,
 * 그때마다 다시 돌리면 양쪽이 저절로 같아진다.
 *
 * ★ 숫자를 전부 **실수(float)**로 뽑는 이유. 이게 이 파일에서 제일 중요하다.
 *
 * GDScript는 정수끼리 나누면 정수가 나온다. `7 / 2`가 3이다.
 * 자바스크립트는 3.5다. 그래서 `qty / every` 같은 줄을 그대로 옮기면
 * **조용히 다른 값**이 되고, 그런 건 몇 시간 뒤에야 곡선으로 드러난다.
 *
 * 우리 숫자는 제일 큰 것이 2조인데 실수(double)는 9천조까지 정수를 정확히
 * 담는다. 그러니 전부 실수로 둬도 오차가 안 생긴다. 위험은 없애고
 * 정확도는 그대로 가져가는 쪽이다.
 */
import fs from 'fs';
import * as C from '../content.js';

const num = (n) => {
  if (!Number.isFinite(n)) throw new Error('이상한 숫자: ' + n);
  return Number.isInteger(n) ? n.toFixed(1) : String(n);
};
const str = (s) => JSON.stringify(s);

function emit(v, indent) {
  const pad = '\t'.repeat(indent);
  const pad2 = '\t'.repeat(indent + 1);
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'string') return str(v);
  if (typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) {
    if (!v.length) return '[]';
    return '[\n' + v.map((x) => pad2 + emit(x, indent + 1)).join(',\n') + '\n' + pad + ']';
  }
  const keys = Object.keys(v);
  if (!keys.length) return '{}';
  return '{\n' + keys.map((k) => `${pad2}${str(k)}: ${emit(v[k], indent + 1)}`).join(',\n') + '\n' + pad + '}';
}

const SKIP = new Set(['itemById', 'shopById', 'ALL_ITEMS']);   // 함수·파생값은 sim이 만든다
const names = Object.keys(C).filter((k) => !SKIP.has(k)).sort();

let out = `class_name Content
## content.js에서 **뽑아낸** 파일이다. 손으로 고치지 말 것 —
## content.js를 고치고 \`node tools/gen-content.mjs\`를 다시 돌린다.
##
## 숫자가 전부 실수(3.0, 12.0)인 이유: GDScript는 정수끼리 나누면 정수가
## 나온다(7 / 2 = 3). 자바스크립트는 3.5다. 그대로 옮기면 조용히 달라진다.
## 우리 숫자는 최대 2조라 실수로 둬도 정확히 담긴다 — 위험만 없앤 것이다.
##
## 개수를 세거나 자리를 셀 때는 int()로 감싸 쓸 것.

`;
for (const n of names) {
  const v = C[n];
  if (typeof v === 'function') continue;
  out += `const ${n} := ${emit(v, 0)}\n\n`;
}
/* ★ 뽑기 전에 **id가 겹치는지** 본다(2026-08-27).
 *
 * 손님으로 만들던 물건 이름을 갈다가 버섯전골 id를 `beoseot`으로 줬는데,
 * 꼬치집 버섯꼬치가 이미 그 id였다. 겹친 id 하나에 검사가 **10분씩 멈췄고**,
 * 어디가 원인인지 아무 말도 안 해 줬다 — 데이터가 어긋나면 코드는 조용히
 * 헛도는 법이라, 그건 사람이 찾을 일이 아니라 도구가 잡을 일이다.
 *
 * 여기서 막으면 잘못된 content.gd가 아예 안 만들어진다. */
const dupes = [];
const seenShop = new Set(), seenItem = new Map();
for (const sh of C.SHOPS) {
  if (seenShop.has(sh.id)) dupes.push(`가게 id 겹침: ${sh.id}`);
  seenShop.add(sh.id);
  for (const it of sh.items) {
    if (seenItem.has(it.id))
      dupes.push(`물건 id 겹침: '${it.id}' — ${seenItem.get(it.id)} vs ${sh.name}/${it.name}`);
    seenItem.set(it.id, `${sh.name}/${it.name}`);
  }
}
const seenGuest = new Set();
for (const g of C.GUESTS) {
  if (seenGuest.has(g.id)) dupes.push(`손님 id 겹침: ${g.id}`);
  seenGuest.add(g.id);
}
if (dupes.length) {
  console.error('★ 뽑지 않았다 — id가 겹친다:');
  for (const d of dupes) console.error('   ' + d);
  process.exit(1);
}

fs.writeFileSync('godot/rules/content.gd', out);
const n = out.split('\n').length;
console.log(`godot/rules/content.gd — ${names.length}덩이 · ${n}줄`);
