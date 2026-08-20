/* answers.mjs — 대조 시험의 **문제와 정답**을 만든다 (JS 쪽).
 * 실행: node tools/answers.mjs <조각>
 *   godot/cases.txt   ← 문제 (GDScript도 같은 걸 읽는다)
 *   godot/out_js.txt  ← JS판의 답
 *
 * ★ 문제는 매번 같아야 한다.
 * 처음엔 난수만 뿌렸는데 한 번은 통과하고 다음엔 실패했다 — 반올림이 갈리는
 * 값이 우연히 걸려야만 드러났기 때문이다. 어쩌다 잡히는 시험은 시험이 아니다.
 * 그래서 씨앗을 고정하고, 갈릴 만한 자리를 일부러 전부 넣는다.
 */
import fs from 'fs';
import { fmt } from '../sim.js';
import * as CONTENT from '../content.js';
import { Sim } from '../sim.js';

const SUBJECT = process.argv[2] || 'fmt';
const W = (name, arr) => fs.writeFileSync(`godot/${name}`, arr.join('\n') + '\n');
/** gen-content.mjs와 **같은 규칙**으로 숫자를 글자로 만든다.
 *  정수는 12.0처럼 소수점을 붙인다 — content.gd가 그렇게 담고 있으니까. */
const num = (n) => (Number.isInteger(n) ? n.toFixed(1) : String(n));

/** balance.mjs가 쓰는 것과 같은 mulberry32 */
const mulberry32 = (a) => () => {
  a = a + 0x6D2B79F5 | 0;
  let x = Math.imul(a ^ a >>> 15, a | 1);
  x ^= x + Math.imul(x ^ x >>> 7, x | 61);
  return (x ^ x >>> 14) >>> 0;
};

const SUBJECTS = {
  /* 큰 숫자 줄여 쓰기 */
  fmt() {
    const n = [];
    const r = mulberry32(20260820);
    for (let i = 0; i < 4000; i++) n.push(Math.floor(Math.pow(10, (r() / 2 ** 32) * 15) * (1 + r() / 2 ** 32)));
    [0, 1, 999, 1000, 1001, 9999, 10000, 99999, 100000, 999999, 1e6, 1e9, 1e12, 1e15].forEach((x) => n.push(x));
    // 딱 절반에 떨어지는 값 — 반올림 규칙이 갈리는 자리는 여기뿐이다
    for (let u = 1; u <= 1e12; u *= 1000)
      for (let a = 1; a < 100; a++) { n.push(a * u * 1000 + u * 500); n.push(a * u * 1000 + u * 5); }
    const cases = n.filter((x) => x >= 0 && Number.isFinite(x));
    W('cases.txt', cases);
    W('out_js.txt', cases.map((x) => fmt(x)));
  },

  /* 씨앗 고정 난수 — 흐름 전체가 같아야 한다 */
  rng() {
    const seeds = [1, 2, 3, 7, 42, 1000, 20260820, 4294967295];
    W('cases.txt', seeds);
    const out = [];
    for (const s of seeds) { const r = mulberry32(s); for (let i = 0; i < 20; i++) out.push(r()); }
    W('out_js.txt', out);
  },
  /* content.gd에 담긴 숫자 전부. 뽑아내는 도구가 틀렸는지, 누가 손으로
   * 고쳤는지를 잡는다. 열쇠 순서는 양쪽 다 가나다순으로 맞춘다. */
  content() {
    const out = [];
    const flat = (v, path) => {
      if (Array.isArray(v)) v.forEach((x, i) => flat(x, `${path}[${i}]`));
      else if (v && typeof v === 'object') Object.keys(v).sort().forEach((k) => flat(v[k], `${path}.${k}`));
      else out.push(`${path}\t${typeof v === 'number' ? num(v) : String(v)}`);
    };
    const skip = new Set(['itemById', 'shopById', 'ALL_ITEMS']);
    for (const n of Object.keys(CONTENT).filter((k) => !skip.has(k) && typeof CONTENT[k] !== 'function').sort()) {
      flat(CONTENT[n], n);
    }
    W('cases.txt', ['content']);
    W('out_js.txt', out);
  },
  /* ★ 진짜 시험 — 같은 씨앗으로 같은 판을 양쪽에서 돌린다.
   *
   * 조각 하나하나가 맞는 것과 **몇 시간을 돌려도 안 갈라지는 것**은 다른
   * 문제다. 규칙이 서로를 부르고, 결과가 다음 틱의 입력이 되니까 —
   * 어디 한 곳에서 소수점 아래가 어긋나면 시간이 지날수록 벌어진다.
   *
   * 그래서 1분마다 상태를 통째로 적어 대조한다. 갈라지는 순간
   * **몇 분째에 어느 값부터** 달라졌는지가 바로 나온다.
   *
   * 적는 값은 전부 정수다. 소수를 글자로 찍으면 표기가 갈려서, 규칙이
   * 맞는데도 빨간불이 뜬다 — 그러면 시험 자체를 못 믿게 된다. */
  sim() {
    /* 기본은 1시간. 어긋남은 쌓이는 것이라 가끔은 길게 돌려야 한다:
     *   SIM_HOURS=4 tools/crosscheck.sh sim */
    const SEED = Number(process.env.SIM_SEED || 7);
    const SECONDS = Number(process.env.SIM_HOURS || 1) * 3600, DT = 0.25;
    W('cases.txt', [`${SEED} ${SECONDS} ${DT}`]);

    const rng = mulberry32(SEED);
    const R = () => rng() / 2 ** 32;    // Sim은 0~1을 받는다
    const s = new Sim();
    const out = [];
    let next = 60, elapsed = 0;
    while (elapsed < SECONDS) {
      s.tick(DT, R);
      act(s, R);
      elapsed += DT;
      if (elapsed >= next) { next += 60; out.push(snap(s)); }
    }
    W('out_js.txt', out);
  },
};

/** 가상 플레이어. godot/tests/runsim.gd의 act()와 **한 줄씩 같아야 한다.** */
function act(s, R) {
  if (s.busy >= 0 && s.tapSmall(s.busy)) return;
  if (s.pest) { s.catchPest(R); return; }
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); return; }
  for (const id of s.asked) if (s.canOpenItem(id)) { s.openItem(id); return; }
  for (const sh of s.shops) if (s.canPromote(sh)) { s.promote(sh); return; }
  if (s.canBuyAuto()) { s.buyAuto(); return; }
  if (s.canBuyGuard()) { s.buyGuard(); return; }
  for (const sh of s.shops) if (s.canHireStaff(sh)) { s.hireStaff(sh); return; }
  let best = '', bestCost = Infinity, anyLeft = false;
  for (const u of CONTENT.GEM_UPGRADES) {
    const c = s.gemCost(u.id);
    if (c == null) continue;
    anyLeft = true;
    if (s.gems >= c && c < bestCost) { bestCost = c; best = u.id; }
  }
  if (best) { s.buyGemUp(best); return; }
  if (!anyLeft && s.canRush()) { s.callRush(); return; }
  const sm = s.nextSmall();
  if (sm >= 0 && s.canBuildSmall(sm)) { s.buildSmall(sm); return; }
  if (s.auto) return;
  let cheap = '', cheapCost = Infinity;
  for (const id of Object.keys(s.items)) {
    if (s.atMax(id)) continue;
    const c = s.levelCost(id);
    if (c < cheapCost) { cheapCost = c; cheap = id; }
  }
  if (cheap && s.money >= cheapCost) s.levelUpMany(cheap, 10);
}

const k = (x) => String(Math.round(x * 1000));

/** godot/tests/runsim.gd의 snapshot()과 **칸 순서까지 같아야 한다.** */
function snap(s) {
  let stock = 0, prog = 0, lvsum = 0;
  for (const id of Object.keys(s.items)) {
    stock += s.items[id].stock; prog += s.items[id].prog; lvsum += s.items[id].lv;
  }
  let ranksum = 0, staffsum = 0;
  for (const sh of s.shops) { ranksum += s.rankOf(sh); staffsum += s.staffOf(sh); }
  let visitsum = 0;
  for (const key of Object.keys(s.visits)) visitsum += s.visits[key];
  let gacc = 0;
  for (const key of Object.keys(s._guestAcc)) gacc += s._guestAcc[key];
  const qsig = s.quests.map((q) => `${q.gid}:${q.itemId}:${Math.trunc(q.need)}:${Math.trunc(q.got)}`);
  const osig = s.orders.map((o) => `${o.id}:${o.gid}:${Math.round(o.t * 1000)}`);
  return [
    Math.round(s.t), Math.trunc(s.money), Math.trunc(s.revenue), Math.trunc(s.gems),
    Math.trunc(s.sold), Object.keys(s.items).length, s.shops.length, s.guests.length,
    s.asked.length, s.quests.length, s.orders.length,
    Math.trunc(stock), k(prog), Math.trunc(lvsum), ranksum, Math.trunc(staffsum),
    s.smalls.length, k(s.fair), k(s.rush), k(s._fairAcc), k(s._askAcc),
    k(gacc), Math.floor(s._purse), Math.trunc(visitsum),
    s._evIdx, s.skins.length, s.event ? Math.trunc(s.event.got) : '-',
    s.auto ? '1' : '0', s.guard ? '1' : '0', s.pest ? '1' : '0',
    qsig.join(','), osig.join(','),
  ].join('\t');
}

if (!SUBJECTS[SUBJECT]) { console.error('모르는 조각: ' + SUBJECT); process.exit(2); }
SUBJECTS[SUBJECT]();
