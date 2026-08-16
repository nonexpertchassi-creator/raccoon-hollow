/* balance.mjs — 그리기 전에 곡선부터 확인한다.
 * 실행: node tools/balance.mjs [시간]
 */
import { Sim, fmt, itemById } from '../sim.js';
import { SHOPS, GUESTS } from '../content.js';

const HOURS = Number(process.argv[2] || 4);
const DT = 0.25;
const s = new Sim();

/* 보통 사람이 할 법한 판단:
 * 새 가게 > 손님이 물어본 새 품목 > 제일 싼 레벨업 */
function act(s) {
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); return 'shop'; }
  for (const id of s.asked) if (s.canOpenItem(id)) { s.openItem(id); return 'item'; }
  const open = Object.keys(s.items).sort((a, b) => s.levelCost(a) - s.levelCost(b));
  for (const id of open) if (s.money >= s.levelCost(id)) { s.levelUp(id); return 'level'; }
  return null;
}

const firstShop = new Map(), firstGuest = new Map(), firstItem = new Map();
const waits = []; const counts = { shop: 0, item: 0, level: 0 };
let last = 0, idle = 0, samples = 0, timeline = [];

for (let t = 0; t < HOURS * 3600; t += DT) {
  s.tick(DT);
  for (const sh of s.shops) if (!firstShop.has(sh)) firstShop.set(sh, s.t);
  for (const g of s.guests) if (!firstGuest.has(g)) firstGuest.set(g, s.t);
  for (const id of Object.keys(s.items)) if (!firstItem.has(id)) firstItem.set(id, s.t);

  const a = act(s);
  if (a) { waits.push(s.t - last); last = s.t; counts[a]++; }

  if (Math.abs(t % 1) < DT) {
    samples++;
    // 진열대가 꽉 차 생산이 멈춘 품목 = 손님이 부족하다는 신호
    if (Object.values(s.items).every((x) => x.stock >= 40)) idle++;
    if (Math.floor(t) % 600 === 0) {
      timeline.push({ min: Math.round(t / 60), rev: s.revenue, ips: s.incomePerSec(),
        shops: s.shops.length, items: Object.keys(s.items).length });
    }
  }
}

const mm = (x) => { const m = Math.floor(x / 60); const ss = Math.floor(x % 60);
  return m >= 60 ? `${Math.floor(m / 60)}시간${m % 60}분` : `${m}분${String(ss).padStart(2, '0')}초`; };

console.log(`\n═══ 너구리 만물상 — ${HOURS}시간 플레이 ═══\n`);

console.log('■ 가게가 살아난 시점  (= 마을이 구제되는 속도)');
for (const sh of SHOPS) {
  console.log(`   ${(firstShop.has(sh.id) ? mm(firstShop.get(sh.id)) : '—').padStart(10)}   ${sh.sign} ${sh.name}`);
}

console.log('\n■ 품목 칸이 열린 시점');
for (const [id, t] of firstItem) console.log(`   ${mm(t).padStart(10)}   ${itemById(id).name}`);

console.log('\n■ 손님이 온 시점');
for (const g of GUESTS) {
  console.log(`   ${(firstGuest.has(g.id) ? mm(firstGuest.get(g.id)) : '—').padStart(10)}   ${g.face} ${g.name}`);
}

const w = waits.filter((x) => x > 0).sort((a, b) => a - b);
console.log('\n■ 뭔가 할 수 있게 되기까지 기다린 시간');
if (w.length) {
  console.log(`   총 ${waits.length}회 · 중앙값 ${w[Math.floor(w.length / 2)].toFixed(1)}초 · ` +
    `상위10% ${w[Math.floor(w.length * 0.9)].toFixed(1)}초 · 최장 ${w[w.length - 1].toFixed(1)}초`);
  console.log(`   가게 ${counts.shop} · 새 품목 ${counts.item} · 레벨업 ${counts.level}`);
}
console.log(`\n■ 재고가 꽉 차 생산이 멈춘 시간 비율: ${((idle / samples) * 100).toFixed(1)}%`);

console.log('\n■ 성장');
console.log('    시간      누적매출     초당수입  가게  품목');
for (const r of timeline) {
  console.log(`   ${String(r.min).padStart(4)}분  ${fmt(r.rev).padStart(11)}  ${fmt(r.ips).padStart(11)}` +
    `  ${String(r.shops).padStart(4)}  ${String(r.items).padStart(4)}`);
}

console.log('\n■ 진단');
const bad = [];
if (firstShop.size < 2) bad.push(`${HOURS}시간에 가게를 하나도 못 늘림 — 마을이 안 살아남`);
if (w.length && w[Math.floor(w.length / 2)] > 60) bad.push('할 게 생기기까지 중앙 60초 초과 — 지루함');
if (w.length && w[Math.floor(w.length / 2)] < 2) bad.push('간격 2초 미만 — 긴장이 없음');
if (idle / samples > 0.25) bad.push(`생산 정지 ${((idle / samples) * 100).toFixed(0)}% — 손님이 재고를 못 따라감`);
if (Object.keys(s.items).length < 3) bad.push('열린 품목이 3개 미만 — 요청 흐름이 막힘');
console.log(bad.length ? bad.map((x) => '   ⚠ ' + x).join('\n') : '   문제 없음 — 곡선이 돈다');
console.log();
