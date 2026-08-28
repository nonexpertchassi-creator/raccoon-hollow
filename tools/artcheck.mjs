/* 장부(아티팩트)에 붙일 **그림 체크 목록**을 만든다.
 *
 * ★ 왜 손으로 안 적나.
 *   이번 주에 실제로 주문서가 코드에 없는 이름 120장을 시키고 있었고,
 *   반대로 코드가 읽는 그림이 주문서에 없기도 했다. 사람이 적으면 또 어긋난다.
 *   그래서 이 목록은 tools/art.mjs --json(= 코드가 실제로 여는 파일 이름)에서만 나온다.
 *
 * 쓰기:  node tools/artcheck.mjs > /tmp/art-section.html
 */
import { execSync } from 'node:child_process';

const groups = JSON.parse(execSync('node tools/art.mjs --json', { encoding: 'utf8' }));

/* 보는 순서 — 지금 급한 것부터. 폴더 이름이 같은 갈래가 둘 있어(guests)
   제목까지 봐야 갈린다. */
const ORDER = [
  ['hero', null], ['hero-body', null], ['hero-tail', null], ['gear', null],
  ['clerks', null], ['portraits', null],
  ['guests', '손님 걷는 모습 (기본)'], ['guests', '손님 정면·뒷모습'],
  ['items', null], ['stalls', null], ['counters', null], ['kilns', null],
  ['pests', null], ['ui', null],
];
const pick = (dir, title) => groups.find(g =>
  g.dir === dir && (title === null || g.title === title));
const sorted = ORDER.map(([d, t]) => pick(d, t)).filter(Boolean);
for (const g of groups) if (!sorted.includes(g)) sorted.push(g);

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const done = g => g.rows.filter(r => r.has).length;
const CIRC = ['①','②','③','④','⑤','⑥','⑦','⑧','⑨','⑩','⑪','⑫','⑬','⑭','⑮'];

function bar(has, all) {
  const pct = all ? Math.round(has / all * 100) : 0;
  const col = has === all ? '#16a34a' : (has === 0 ? '#cbd5e1' : 'var(--gam)');
  return `<div style="display:flex;align-items:center;gap:10px;margin:0 0 8px">`
    + `<div style="flex:1;height:8px;background:rgba(128,128,128,.2);border-radius:99px;overflow:hidden">`
    + `<div style="width:${pct}%;height:100%;background:${col}"></div></div>`
    + `<b style="font-size:13px" class="num">${has} / ${all}</b></div>`;
}

const today = new Date().toISOString().slice(0, 10);
const total = sorted.reduce((a, g) => a + g.rows.length, 0);
const got = sorted.reduce((a, g) => a + done(g), 0);
const needTotal = sorted.filter(g => !g.optional).reduce((a, g) => a + g.rows.length, 0);
const needGot = sorted.filter(g => !g.optional).reduce((a, g) => a + done(g), 0);

let h = '';
h += `<section id="art">\n  <div class="mark"><i></i><h2>그림 목록 — 코드가 실제로 찾는 파일 이름</h2></div>\n`;
h += `<p class="sub">${today} 기준 · <b>${got} / ${total}장</b>`
  + ` (꼭 필요한 것만 보면 <b>${needGot} / ${needTotal}장</b>).`
  + ` 사람이 적은 목록이 아니라 <code>node tools/art.mjs --json</code>이 뱉은 것이다 —`
  + ` <b>코드가 실제로 여는 파일 이름</b>이라 주문서와 코드가 어긋날 수가 없다.</p>\n`;

h += `<p style="font-size:13px;margin:0 0 14px;padding:10px 12px;border-left:3px solid var(--jade);`
  + `background:rgba(128,128,128,.06);border-radius:6px">`
  + `<b>읽는 법.</b> "지금" 칸은 <b>파일이 폴더에 있나</b>만 본다 — 가안인지 픽스인지는 안 본다.`
  + ` 경로는 <b>그대로 쓰면 된다</b>. <code>godot/art/</code> 밖에 두면 목록에서는 사라지는데`
  + ` 화면에는 영영 안 나온다 — 제일 나쁜 종류다. 파일은 <b>webp</b>,`
  + ` 넣은 뒤 <code>godot --headless --path godot --import</code> 한 번,`
  + ` <code>.import</code> 짝도 같이 커밋한다.<br>`
  + `<b>선택</b>이라고 적힌 갈래는 없어도 게임이 돈다 — 코드가 기본 그림으로 때운다.</p>\n`;

/* 한눈에 보는 표 — 어디가 본진인지가 먼저 보여야 한다 */
h += `<div class="tw"><table class="mini">\n<tr><th>갈래</th><th>폴더</th><th>크기</th><th>진행</th></tr>\n`;
sorted.forEach((g, i) => {
  const has = done(g), all = g.rows.length;
  const pct = all ? Math.round(has / all * 100) : 0;
  const col = has === all ? '#16a34a' : (has === 0 ? '#cbd5e1' : 'var(--gam)');
  h += `<tr><td><a href="#art-${i}">${CIRC[i] || (i + 1)} ${esc(g.title)}</a>`
    + (g.optional ? ` <span style="color:var(--muted);font-size:12px">선택</span>` : '')
    + `</td><td><code>godot/art/${g.dir}/</code></td>`
    + `<td class="num" style="font-size:12.5px">${esc(g.size)}</td>`
    + `<td class="num"><span style="display:inline-block;width:60px;height:6px;`
    + `background:rgba(128,128,128,.2);border-radius:99px;overflow:hidden;vertical-align:middle">`
    + `<span style="display:block;width:${pct}%;height:100%;background:${col}"></span></span> `
    + `${has} / ${all}</td></tr>\n`;
});
h += `</table></div>\n`;

sorted.forEach((g, i) => {
  const has = done(g), all = g.rows.length;
  h += `<h4 id="art-${i}" style="margin:26px 0 4px">${CIRC[i] || (i + 1)} ${esc(g.title)}`
    + ` — <code>godot/art/${g.dir}/</code> · ${esc(g.size)}`
    + (g.optional ? ' <span style="color:var(--muted);font-size:13px">(선택)</span>' : '')
    + `</h4>\n`;
  h += bar(has, all);
  h += `<div class="tw"><table class="mini">`
    + `<tr><th>파일 (경로 그대로)</th><th>무엇</th><th>지금</th></tr>\n`;
  for (const r of g.rows) {
    h += `<tr><td><code>godot/art/${g.dir}/${esc(r.id)}.webp</code></td>`
      + `<td style="font-size:12.5px">${esc(r.why)}</td>`
      + `<td class="num">` + (r.has
        ? `<span style="color:#16a34a;font-weight:700">있음</span>`
        : `<span style="color:var(--muted)">—</span>`) + `</td></tr>\n`;
  }
  h += `</table></div>\n`;
});

h += `<p style="font-size:12.5px;color:var(--muted);margin:18px 0 0">`
  + `<b>이 목록은 손으로 고치지 않는다.</b> 그림을 넣고 <code>node tools/art.mjs --write</code>를 돌리면`
  + ` ASSETS.md가 갱신되고, 이 칸은 <code>node tools/artcheck.mjs</code>가 같은 자료에서 다시 만든다.`
  + ` 체크 표시를 손으로 찍으면 다음 갱신에 지워진다 — 그리고 그 사이에 거짓말을 한다.</p>\n`;
h += `</section>\n`;

process.stdout.write(h);
