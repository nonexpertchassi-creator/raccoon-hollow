/* balance.mjs — 그리기 전에 곡선부터 확인한다.
 * 실행: node tools/balance.mjs [시간]
 *
 * 이 도구의 임무는 하나다: **게임이 망가졌으면 망가졌다고 말하는 것.**
 * 예전 판은 재고 정지를 `every`로 판정해서(= 품목이 전부 꽉 차야 셈)
 * 절반이 죽어 있는데도 "문제 없음"을 보고했다. 그래서 품목별로 따로 센다.
 */
import { Sim, fmt, itemById } from '../sim.js';
import { SHOPS, GUESTS, STOCK_CAP } from '../content.js';

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
let last = 0, samples = 0, timeline = [];

/* 품목별 성적표. 죽은 품목을 찾아내는 게 이 도구의 존재 이유다. */
const perItem = {};                 // id → { rev, sold, stall, live }
const seen = (id) => (perItem[id] ??= { rev: 0, sold: 0, stall: 0, live: 0 });
let lastUnlock = 0, lastUnlockWhat = '시작';

for (let t = 0; t < HOURS * 3600; t += DT) {
  const r = s.tick(DT);

  /* 매출을 품목별로 쪼개 적는다.
   * 손님 한 명이 여러 품목을 사갈 수 있으므로 lines[]를 먼저 본다. */
  for (const sale of r.sales) {
    for (const ln of (sale.lines || [sale])) {
      const p = seen(ln.item.id);
      p.rev += ln.gain; p.sold += ln.n;
    }
  }

  for (const sh of s.shops) if (!firstShop.has(sh)) {
    firstShop.set(sh, s.t); lastUnlock = s.t;
    lastUnlockWhat = SHOPS.find((x) => x.id === sh).name;
  }
  for (const g of s.guests) if (!firstGuest.has(g)) {
    firstGuest.set(g, s.t); lastUnlock = s.t;
    lastUnlockWhat = GUESTS.find((x) => x.id === g).name;
  }
  for (const id of Object.keys(s.items)) if (!firstItem.has(id)) {
    firstItem.set(id, s.t); lastUnlock = s.t;
    lastUnlockWhat = itemById(id).name;
  }

  const a = act(s);
  if (a) { waits.push(s.t - last); last = s.t; counts[a]++; }

  if (Math.abs(t % 1) < DT) {
    samples++;
    /* 품목별 정지 시간. 재고가 상한이면 그 품목은 지금 아무것도 안 만들고 있다.
     * 전역 플래그로 뭉뚱그리면 상위 품목이 계속 팔리는 동안 하위 품목이
     * 죽어가는 걸 놓친다 — 예전 판이 정확히 그랬다. */
    for (const id of Object.keys(s.items)) {
      const p = seen(id);
      p.live++;
      if (s.items[id].stock >= STOCK_CAP) p.stall++;
    }
    if (Math.floor(t) % 600 === 0) {
      timeline.push({ min: Math.round(t / 60), rev: s.revenue, ips: s.incomePerSec(),
        shops: s.shops.length, items: Object.keys(s.items).length });
    }
  }
}

const mm = (x) => { const m = Math.floor(x / 60); const ss = Math.floor(x % 60);
  return m >= 60 ? `${Math.floor(m / 60)}시간${m % 60}분` : `${m}분${String(ss).padStart(2, '0')}초`; };
const pct = (a, b) => (b ? (a / b) * 100 : 0);

console.log(`\n═══ 너구리 만물상 — ${HOURS}시간 플레이 ═══\n`);

console.log('■ 가게가 살아난 시점  (= 마을이 구제되는 속도)');
for (const sh of SHOPS) {
  console.log(`   ${(firstShop.has(sh.id) ? mm(firstShop.get(sh.id)) : '—').padStart(10)}   ${sh.sign} ${sh.name}`);
}

console.log('\n■ 손님이 온 시점');
for (const g of GUESTS) {
  console.log(`   ${(firstGuest.has(g.id) ? mm(firstGuest.get(g.id)) : '—').padStart(10)}   ${g.face} ${g.name}`);
}

/* ── 품목별 성적표 ──
 * 매출기여 0.0% = 그 품목은 게임에 없는 것과 같다. 플레이어가 레벨업에
 * 쏟은 돈이 전부 허공으로 간다. 이 표의 0.0%가 밸런스 수정의 합격 기준이다. */
console.log('\n■ 품목별 성적   (매출기여 0.0% = 죽은 품목)');
console.log('      품목    레벨    열린시점    매출기여    생산정지   상태');
const dead = [];
for (const id of Object.keys(s.items)) {
  const p = seen(id), name = itemById(id).name;
  const rev = pct(p.rev, s.revenue), stall = pct(p.stall, p.live);
  const bad = rev < 0.05;
  if (bad) dead.push(name);
  console.log(`   ${name.padEnd(5)} ${String(s.lv(id)).padStart(6)}  ${
    mm(firstItem.get(id)).padStart(9)}  ${(rev.toFixed(1) + '%').padStart(9)}  ${
    (stall.toFixed(0) + '%').padStart(9)}   ${bad ? '✗ 죽음' : '✓'}`);
}

const w = waits.filter((x) => x > 0).sort((a, b) => a - b);
console.log('\n■ 뭔가 할 수 있게 되기까지 기다린 시간');
if (w.length) {
  console.log(`   총 ${waits.length}회 · 중앙값 ${w[Math.floor(w.length / 2)].toFixed(1)}초 · ` +
    `상위10% ${w[Math.floor(w.length * 0.9)].toFixed(1)}초 · 최장 ${w[w.length - 1].toFixed(1)}초`);
  console.log(`   가게 ${counts.shop} · 새 품목 ${counts.item} · 레벨업 ${counts.level}`);
}

/* ── 콘텐츠 소진 ──
 * 마지막 해금 이후로는 새로 열리는 게 없다 = 레벨업 버튼만 남는다. */
const leftover = HOURS * 3600 - lastUnlock;
console.log('\n■ 콘텐츠 소진');
console.log(`   마지막 해금: ${mm(lastUnlock)} (${lastUnlockWhat})`);
console.log(`   이후 ${mm(leftover)} 동안 새로 열린 것이 없다`);

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
if (dead.length) {
  bad.push(`품목 ${dead.length}/${Object.keys(s.items).length}개가 매출 0 — ${dead.join('·')}`);
}
const stalled = Object.keys(s.items).filter((id) => pct(seen(id).stall, seen(id).live) > 50);
if (stalled.length) {
  bad.push(`품목 ${stalled.length}개가 재고 상한에 박혀 절반 이상 생산 정지`);
}
if (leftover > 1800) bad.push(`${mm(lastUnlock)}에 콘텐츠 소진 — 남은 ${mm(leftover)}은 레벨업뿐`);
if (Object.keys(s.items).length < 3) bad.push('열린 품목이 3개 미만 — 요청 흐름이 막힘');
console.log(bad.length ? bad.map((x) => '   ⚠ ' + x).join('\n') : '   문제 없음 — 곡선이 돈다');
console.log();
