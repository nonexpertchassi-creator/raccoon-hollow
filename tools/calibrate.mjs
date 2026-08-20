/* calibrate.mjs — 돈 단위 개편용 측정기.
 * 지금 content.js로 10시간을 돌리며 모든 '관문'(가게·품목·승급·직원·자동·개·건물)이
 * 언제 열렸고 그 시점 수입 몇 초치였는지, 그리고 분당 revenue/ips 곡선을 기록한다.
 * 실행: node calibrate.mjs <라벨>  → <라벨>.json 저장
 */
import { Sim } from '../sim.js';
import { SHOPS, GUESTS, PESTS } from '../content.js';

const LABEL = process.argv[2] || 'baseline';
const DT = 0.25, HOURS = 10, SEED = 1;
const s = new Sim();
const rng = ((a) => () => {
  a = a + 0x6D2B79F5 | 0;
  let x = Math.imul(a ^ a >>> 15, a | 1);
  x ^= x + Math.imul(x ^ x >>> 7, x | 61);
  return ((x ^ x >>> 14) >>> 0) / 4294967296;
})(SEED);

const gates = [];   // { what, t, cost, ips, secs }
const curve = [];   // { min, revenue, ips }
const mark = (what, cost) => {
  const ips = s.incomePerSec();
  gates.push({ what, t: Math.round(s.t), cost, ips, secs: ips ? +(cost / ips).toFixed(1) : 0 });
};

function act() {
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); mark('shop:' + ns.id, ns.cost); return; }
  for (const id of s.asked) if (s.canOpenItem(id)) {
    const c = s.canOpenItem(id) ? (SHOPS.flatMap(x => x.items).find(i => i.id === id).cost) : 0;
    s.openItem(id); mark('item:' + id, c); return;
  }
  for (const sh of s.shops) if (s.canPromote(sh)) {
    const c = SHOPS.find(x => x.id === sh).promote[s.rankOf(sh)];
    s.promote(sh); mark('promote:' + sh + ':' + s.rankOf(sh), c); return;
  }
  if (s.canBuyAuto()) { const c = 0 + (s.auto ? 0 : 5_000_000); s.buyAuto(); mark('auto', c); return; }
  if (s.canBuyGuard()) { s.buyGuard(); mark('guard', 0); return; }
  for (const sh of s.shops) if (s.canHireStaff(sh)) {
    const c = s.staffCost(sh); s.hireStaff(sh); mark('staff:' + sh + ':' + s.staffOf(sh), c); return;
  }
  const sm = s.nextSmall();
  if (sm >= 0 && s.canBuildSmall(sm)) { s.buildSmall(sm); mark('small:' + sm, 0); return; }
  const open = Object.keys(s.items).filter((id) => !s.atMax(id))
    .sort((a, b) => s.levelCost(a) - s.levelCost(b));
  for (const id of open) if (s.money >= s.levelCost(id)) { s.levelUpMany(id, 10); return; }
}

const guestAt = {}, pestAt = {};
let nextMin = 0;
for (let t = 0; t < HOURS * 3600; t += DT) {
  const r = s.tick(DT, rng);
  if (r.newGuest) guestAt[r.newGuest.id] = Math.round(s.t);
  for (const P of PESTS) if (!(P.id in pestAt) && s.revenue >= P.at) pestAt[P.id] = Math.round(s.t);
  act();
  if (s.t >= nextMin) {
    curve.push({ min: Math.round(nextMin / 60), revenue: Math.round(s.revenue), ips: +s.incomePerSec().toFixed(2) });
    nextMin += 60;
  }
}

const out = { label: LABEL, gates, guestAt, pestAt, curve,
  end: { revenue: Math.round(s.revenue), money: Math.round(s.money), ips: +s.incomePerSec().toFixed(1) } };
const fs = await import('fs');
fs.writeFileSync(LABEL + '.json', JSON.stringify(out, null, 1));
console.log('저장:', LABEL + '.json');
console.log('끝: 누적매출', out.end.revenue.toExponential(2), '· 초당', out.end.ips.toExponential(2));
for (const g of gates) console.log(String(Math.floor(g.t / 60)).padStart(4) + '분', g.what.padEnd(18), '값', g.cost.toExponential(1), '=수입', g.secs + '초치');
