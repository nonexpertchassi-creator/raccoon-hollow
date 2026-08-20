/* balance.mjs — 그리기 전에 곡선부터 확인한다.
 * 실행: node tools/balance.mjs [시간] [씨앗]
 *
 * 이 도구의 임무는 하나다: **게임이 망가졌으면 망가졌다고 말하는 것.**
 * 예전 판은 재고 정지를 `every`로 판정해서(= 품목이 전부 꽉 차야 셈)
 * 절반이 죽어 있는데도 "문제 없음"을 보고했다. 그래서 품목별로 따로 센다.
 */
import { Sim, fmt, itemById } from '../sim.js';
import { SHOPS, GUESTS, STOCK_CAP, PESTS, GUARD, GEM_UPGRADES } from '../content.js';

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
  /* 북적이면 바로 누른다 — 12초짜리 창이라 제일 먼저 봐야 한다.
   *
   * 이게 없던 동안 이 도구는 **장을 한 번도 안 열었다.** 그래서 장에 붙은
   * 수치(FAIR, 젬 강화 두 가지)를 아무리 키우고 줄여도 결과가 안 변했고,
   * 나는 그걸 '이 손잡이는 효과가 없다'로 읽을 뻔했다. 안 쓰는 기능은
   * 효과가 없는 게 당연하다 — 도구가 또 거짓말을 한 것이다. */
  if (s.busy >= 0 && s.tapSmall(s.busy)) return 'fair';
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); return 'shop'; }
  for (const id of s.asked) if (s.canOpenItem(id)) { s.openItem(id); return 'item'; }
  for (const sh of s.shops) if (s.canPromote(sh)) { s.promote(sh); return 'shop'; }
  if (s.canBuyAuto()) { s.buyAuto(); return 'auto'; }
  if (s.canBuyGuard()) { s.buyGuard(); return 'item'; }
  for (const sh of s.shops) if (s.canHireStaff(sh)) { s.hireStaff(sh); return 'item'; }
  /* 젬은 모아두면 아무 일도 안 일어난다. 제일 싼 것부터 바로 쓴다고 본다 —
   * 이래야 젬 강화가 경제에 주는 영향이 최대치로 잡히고, 그 최대치가
   * 견딜 만해야 수치를 내보낼 수 있다. */
  const up = GEM_UPGRADES.map((u) => u.id).filter((id) => s.canBuyGemUp(id))
    .sort((a, b) => s.gemCost(a) - s.gemCost(b))[0];
  if (up) { s.buyGemUp(up); return 'item'; }
  /* 영구 강화를 **다 산 뒤에만** 남는 젬을 삯꾼으로 쓴다.
   *
   * 처음엔 아무 때나 쓰게 했더니 8시간 내내 삯꾼만 부르고 영구 강화는
   * 벼린 연장 2단계에서 멈췄다 — 삯꾼이 3알로 제일 싸서, 다음 강화값
   * (5·7·11알)을 모으기 전에 젬이 계속 빠져나간 것이다. 그러면 도구가
   * 영구 강화를 한 번도 제대로 못 재본다. */
  const anyLeft = GEM_UPGRADES.some((u) => s.gemCost(u.id) !== null);
  if (!anyLeft && s.canRush()) { s.callRush(); return 'fair'; }
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
const waits = []; const counts = { shop: 0, item: 0, level: 0, auto: 0, fair: 0 };
let last = 0, samples = 0, timeline = [];

/* 품목별 성적표. 죽은 품목을 찾아내는 게 이 도구의 존재 이유다. */
const perItem = {};                 // id → { rev, sold, stall, live }
const seen = (id) => (perItem[id] ??= { rev: 0, sold: 0, stall: 0, live: 0 });
let lastUnlock = 0, lastUnlockWhat = '시작';
/* 나쁜 놈은 '안 잡았을 때'를 잰다 — 폰을 꺼놓고 자는 쪽이 최악이고,
 * 그쪽이 안전해야 이 장치를 넣어도 된다. */
const pestLog = {};
for (const P of PESTS) pestLog[P.id] = { seen: 0, loss: 0, worth: 0 };
let pestHad = null;
/* 계산대 규칙(SERVICE)이 실제로 어떻게 굴러가는지 — 기다림과 💢를 센다 */
let visitsAll = 0, visitsWaited = 0, waitSum = 0, huffs = 0;
/* 마을 의뢰 — 몇 건이 끝났고 젬이 얼마나 들어왔나. 시간당으로 봐야 한다:
 * 총합만 보면 후반에 몰린 건지 고르게 들어온 건지 구분이 안 된다. */
let qDone = 0, qCoin = 0, qGem = 0, gemMax = 0, gemCatch = 0;
const qByHour = [];
const qByVillage = {};

for (let t = 0; t < HOURS * 3600; t += DT) {
  const r = s.tick(DT, rng);
  if (s.pest && !pestHad) {
    pestHad = s.pest;
    const L = pestLog[s.pest.kind];
    const w = s.pest.amount ?? s.price(s.pest.itemId) * s.pest.qty;
    L.seen++; L.worth += w; L.loss += w;
  }
  if (!s.pest && pestHad) pestHad = null;

  /* 매출을 품목별로 쪼개 적는다.
   * 손님 한 명이 여러 품목을 사갈 수 있으므로 lines[]를 먼저 본다.
   * 주문(waiting)은 만들어진 뒤 done으로 다시 오므로 여기선 안 센다 —
   * 두 번 세면 매출이 부풀어 도구가 또 거짓말을 한다. */
  for (const sale of [...r.sales.filter((x) => !x.waiting), ...(r.done || [])]) {
    if (sale.n === 0) { huffs++; continue; }        // 빈손 💢
    visitsAll++;
    if (sale.waited > 0.01) { visitsWaited++; waitSum += sale.waited; }
    for (const ln of sale.lines) {
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

  for (const q of r.quests || []) {
    qDone++; qCoin += q.coin; qGem += q.gems;
    const h = Math.floor(s.t / 3600);
    (qByHour[h] ??= { n: 0, gem: 0, coin: 0 });
    qByHour[h].n++; qByHour[h].gem += q.gems; qByHour[h].coin += q.coin;
    const v = (qByVillage[q.gid] ??= { n: 0, gem: 0, secs: 0 });
    v.n++; v.gem += q.gems; v.secs += q.t;
  }
  for (const e of s.events) {
    if (e.t <= s.t - DT || e.kind !== 'gem') break;
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
      if (s.items[id].stock >= s.capOf(id)) p.stall++;   // 상한은 직원 수에 따라 다르다
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
  console.log(`   가게 ${counts.shop} · 새 품목 ${counts.item} · 장 열기 ${counts.fair} · 강화 클릭 ${counts.level}` +
    (s.auto ? ' (자동 강화 구입 후로는 0)' : ''));
}

console.log('\n■ 마을 의뢰와 젬');
console.log(`   끝낸 의뢰 ${qDone}건 · 받은 젬 💎${qGem} · 보상 엽전 ${fmt(qCoin)} (누적매출의 ${
  pct(qCoin, s.revenue).toFixed(1)}%)`);
console.log(`   지금 가진 젬 💎${s.gems} · 산 강화 ${
  GEM_UPGRADES.map((u) => `${u.name} ${s.upLv(u.id)}/${u.max}`).join(' · ')}`);
console.log('   시간대별   끝낸 의뢰 / 젬 / 보상');
for (let h = 0; h < Math.ceil(HOURS); h++) {
  const q = qByHour[h] || { n: 0, gem: 0, coin: 0 };
  console.log(`   ${String(h + 1).padStart(6)}시간째  ${String(q.n).padStart(6)}건 ${
    String('💎' + q.gem).padStart(7)} ${fmt(q.coin).padStart(9)}`);
}
if (qDone) {
  console.log('   마을별   끝낸 의뢰 / 평균 걸린 시간   (시간이 마을마다 비슷해야 한다)');
  for (const g of GUESTS) {
    const v = qByVillage[g.id];
    if (!v) continue;
    console.log(`   ${(g.face + ' ' + g.name + '마을').padEnd(12)} ${
      String(v.n).padStart(4)}건   ${mm(v.secs / v.n).padStart(9)}`);
  }
}

if (PESTS.some((P) => pestLog[P.id].seen)) {
  console.log('\n■ 나쁜 놈들');
  console.log('   놈    나타남     안 잡았을 때 잃는 것   매번 잡았을 때 버는 것');
  let ls = 0, gs = 0;
  for (const P of PESTS) {
    const L = pestLog[P.id];
    if (!L.seen) continue;
    const gain = L.worth * P.fine;
    ls += L.loss; gs += gain;
    console.log(`   ${P.name.padEnd(5)}${String(L.seen).padStart(5)}마리` +
      `${(fmt(Math.floor(L.loss)) + '냥').padStart(14)} (${(L.loss / s.revenue * 100).toFixed(2)}%)` +
      `${(fmt(Math.floor(gain)) + '냥').padStart(14)} (${(gain / s.revenue * 100).toFixed(1)}%)`);
  }
  console.log(`   ─ 합계: 잃는 것 누적매출의 ${(ls / s.revenue * 100).toFixed(2)}% ·` +
    ` 버는 것 ${(gs / s.revenue * 100).toFixed(1)}% (${(gs / ls).toFixed(0)}배)`);
  /* 삽살개는 '자리를 비웠을 때'만 일한다. 직접 잡는 것보다 확실히 나빠야 한다 —
   * 개가 더 나으면 화면을 볼 이유가 사라지고, 나쁜 놈을 넣은 이유도 같이 사라진다. */
  const worth = ls;                                    // 놓쳤을 때 오가는 값의 총합
  const dog = worth * (GUARD.rate * GUARD.fine - (1 - GUARD.rate));
  console.log(`   삽살개만 믿고 자리를 비우면: ${dog >= 0 ? '+' : ''}${(dog / s.revenue * 100).toFixed(1)}%` +
    ` (직접 매번 잡기의 ${(gs / dog).toFixed(0)}분의 1)`);
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

console.log('\n■ 계산대  (기다림·빈손은 손님 방문 기준)');
console.log(`   방문 ${visitsAll}회 · 기다렸다 받아감 ${visitsWaited}회` +
  ` (${pct(visitsWaited, visitsAll).toFixed(1)}%` +
  `${visitsWaited ? ` · 평균 ${(waitSum / visitsWaited).toFixed(1)}초` : ''})` +
  ` · 빈손 💢 ${huffs}회 (${pct(huffs, visitsAll + huffs).toFixed(1)}%)`);

console.log('\n■ 진단');
const bad = [];
/* 💢가 잦으면 "가게가 장사를 못 한다"로 보인다 — 참을성이나 생산 수치를 만질 것 */
if (pct(huffs, visitsAll + huffs) > 8) bad.push(`빈손으로 돌아간 손님 ${pct(huffs, visitsAll + huffs).toFixed(1)}% — 8% 초과`);
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
