/* balance.mjs — 그리기 전에 곡선부터 확인한다.
 * 실행: node tools/balance.mjs [시간] [씨앗]
 *
 * 이 도구의 임무는 하나다: **게임이 망가졌으면 망가졌다고 말하는 것.**
 * 예전 판은 재고 정지를 `every`로 판정해서(= 품목이 전부 꽉 차야 셈)
 * 절반이 죽어 있는데도 "문제 없음"을 보고했다. 그래서 품목별로 따로 센다.
 */
import { Sim, fmt, itemById } from '../sim.js';
import { SHOPS, GUESTS, STOCK_CAP } from '../content.js';

const HOURS = Number(process.argv[2] || 4);
const SEED = Number(process.argv[3] || 1);
const DT = 0.25;
const s = new Sim();

/* 씨앗 고정 난수.
 * 손님이 무작위로 물건을 집으면서 매 실행마다 결과가 달라졌다. 그러면
 * 수치를 바꿨을 때 그게 개선인지 그냥 운인지 구분할 수 없다.
 * 씨앗을 고정하면 같은 코드는 항상 같은 숫자를 낸다.
 * 운에 안 흔들리는지 보려면 씨앗을 바꿔 돌린다: node tools/balance.mjs 6 2 */
const rng = ((a) => () => {
  a = a + 0x6D2B79F5 | 0;
  let x = Math.imul(a ^ a >>> 15, a | 1);
  x ^= x + Math.imul(x ^ x >>> 7, x | 61);
  return ((x ^ x >>> 14) >>> 0) / 4294967296;
})(SEED);

/* 보통 사람이 할 법한 판단:
 * 새 가게 > 손님이 물어본 새 품목 > 제일 싼 레벨업 */
function act(s) {
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); return 'shop'; }
  for (const id of s.asked) if (s.canOpenItem(id)) { s.openItem(id); return 'item'; }
  for (const sh of s.shops) if (s.canPromote(sh)) { s.promote(sh); return 'shop'; }
  if (s.canBuyAuto()) { s.buyAuto(); return 'auto'; }
  const sm = s.nextSmall();
  if (sm >= 0 && s.canBuildSmall(sm)) { s.buildSmall(sm); return 'item'; }
  /* 자동 강화를 산 뒤로는 손으로 안 누른다 — 그게 산 이유다.
   * 그래서 여기 세어지는 'level'은 자동 강화를 사기 전까지의 클릭 수다. */
  if (s.auto) return null;
  /* 만렙은 반드시 걸러야 한다. 안 그러면 제일 싼 품목이 상한에 닿는 순간
   * 매 틱마다 아무 일도 안 하고 '눌렀다'로 세어진다 — 클릭 수가 16,547회로
   * 튀고 행동 간격이 0.3초로 찍혔다. 도구가 또 거짓말을 하는 것이다.
   * 레벨 상한이 없던 시절엔 값이 지수로 올라 저절로 막혀 안 보이던 함정이다. */
  const open = Object.keys(s.items).filter((id) => !s.atMax(id))
    .sort((a, b) => s.levelCost(a) - s.levelCost(b));
  for (const id of open) if (s.money >= s.levelCost(id)) {
    s.levelUpMany(id, 10); return 'level';
  }
  return null;
}

const firstShop = new Map(), firstGuest = new Map(), firstItem = new Map();
const firstRank = new Map();
const waits = []; const counts = { shop: 0, item: 0, level: 0, auto: 0 };
let last = 0, samples = 0, timeline = [];

/* 품목별 성적표. 죽은 품목을 찾아내는 게 이 도구의 존재 이유다. */
const perItem = {};                 // id → { rev, sold, stall, live }
const seen = (id) => (perItem[id] ??= { rev: 0, sold: 0, stall: 0, live: 0 });
let lastUnlock = 0, lastUnlockWhat = '시작';

for (let t = 0; t < HOURS * 3600; t += DT) {
  const r = s.tick(DT, rng);

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
    lastUnlockWhat = s.itemName(id);
  }
  /* 승급도 '새로 열린 것'이다. 이걸 안 세면 도구가 또 눈이 먼다 —
   * 예전에 죽은 품목을 every로 판정해 못 잡던 것과 같은 종류의 실수다. */
  for (const sh of s.shops) {
    const key = `${sh}:${s.rankOf(sh)}`;
    if (s.rankOf(sh) > 0 && !firstRank.has(key)) {
      firstRank.set(key, s.t); lastUnlock = s.t;
      const S = SHOPS.find((x) => x.id === sh);
      lastUnlockWhat = `${S.name} ${S.ranks[s.rankOf(sh)]}급`;
    }
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

console.log(`\n═══ 너구리 만물상 — ${HOURS}시간 플레이 (씨앗 ${SEED}) ═══\n`);

console.log('■ 가게가 살아난 시점  (= 마을이 구제되는 속도)');
for (const sh of SHOPS) {
  console.log(`   ${(firstShop.has(sh.id) ? mm(firstShop.get(sh.id)) : '—').padStart(10)}   ${sh.sign} ${sh.name}`);
}

console.log('\n■ 손님이 온 시점');
for (const g of GUESTS) {
  console.log(`   ${(firstGuest.has(g.id) ? mm(firstGuest.get(g.id)) : '—').padStart(10)}   ${g.face} ${g.name}`);
}

/* ── 품목별 성적표 ──
 * 판정 기준이 **매출 비중이 아니라 판매 개수**인 이유:
 * 곡괭이는 제일 싸므로 아무리 많이 팔아도 매출 비중은 1%를 못 넘는다.
 * 비중으로 재면 잘 팔리는 품목을 '죽음'으로 오진한다 — 실제로 그랬다.
 *
 * 진짜 죽음은 하나뿐이다: **안 팔려서 재고 상한에 박히고 생산까지 멈춘 것.**
 * 싼 물건의 낮은 매출 비중은 정상이다. */
console.log('\n■ 품목별 성적   (죽음 = 안 팔려서 생산이 멈춘 것)');
console.log('      품목    레벨    열린시점      판매    매출기여   생산정지   상태');
const dead = [], stuck = [];
for (const id of Object.keys(s.items)) {
  const p = seen(id), name = itemById(id).name;
  const rev = pct(p.rev, s.revenue), stall = pct(p.stall, p.live);
  let mark = '✓';
  if (!p.sold) { dead.push(name); mark = '✗ 죽음'; }
  else if (stall > 50) { stuck.push(name); mark = '△ 정체'; }
  console.log(`   ${name.padEnd(5)} ${String(s.lv(id)).padStart(6)}  ${
    mm(firstItem.get(id)).padStart(9)}  ${String(p.sold).padStart(8)}  ${
    (rev.toFixed(1) + '%').padStart(8)}  ${
    (stall.toFixed(0) + '%').padStart(9)}   ${mark}`);
}

if (firstRank.size) {
  console.log('\n■ 가게 승급');
  for (const [k, t] of firstRank) {
    const [sid, r] = k.split(':');
    const S = SHOPS.find((x) => x.id === sid);
    console.log(`   ${mm(t).padStart(10)}   ${S.name} → ${S.ranks[+r]}급`);
  }
}

const w = waits.filter((x) => x > 0).sort((a, b) => a - b);
console.log('\n■ 뭔가 할 수 있게 되기까지 기다린 시간');
if (w.length) {
  console.log(`   총 ${waits.length}회 · 중앙값 ${w[Math.floor(w.length / 2)].toFixed(1)}초 · ` +
    `상위10% ${w[Math.floor(w.length * 0.9)].toFixed(1)}초 · 최장 ${w[w.length - 1].toFixed(1)}초`);
  console.log(`   가게 ${counts.shop} · 새 품목 ${counts.item} · 강화 클릭 ${counts.level}` +
    (s.auto ? ' (자동 강화 구입 후로는 0)' : ''));
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
  bad.push(`품목 ${dead.length}/${Object.keys(s.items).length}개가 한 개도 안 팔림 — ${dead.join('·')}`);
}
if (stuck.length) {
  bad.push(`품목 ${stuck.length}개가 재고 상한에 박혀 절반 이상 생산 정지 — ${stuck.join('·')}`);
}
if (leftover > 1800) bad.push(`${mm(lastUnlock)}에 콘텐츠 소진 — 남은 ${mm(leftover)}은 레벨업뿐`);
if (Object.keys(s.items).length < 3) bad.push('열린 품목이 3개 미만 — 요청 흐름이 막힘');
console.log(bad.length ? bad.map((x) => '   ⚠ ' + x).join('\n') : '   문제 없음 — 곡선이 돈다');
console.log();
