/* balance.mjs — 브라우저 없이 게임을 통째로 돌려보는 장치.
 *
 * 방치형에서 제일 흔한 실패는 "만들고 나서 지루한 걸 알게 되는 것"이다.
 * 아트를 다 그린 뒤에 곡선이 틀린 걸 알면 되돌릴 수가 없다.
 *
 * 그래서 그리기 전에 여기서 확인한다:
 *   - 다음 업그레이드까지 몇 초를 기다리는가 (이게 곧 지루함의 단위)
 *   - 어느 구간에서 벽에 막히는가
 *   - 병목이 계속 바뀌는가 (안 바뀌면 살 게 하나뿐 = 결정이 없음)
 *
 * 실행: node tools/balance.mjs [플레이시간(초)]
 */
import { Sim, fmt } from '../sim.js';
import { ANIMALS, FORESTS } from '../content.js';

const HOURS = Number(process.argv[2] || 6);
const SECONDS = HOURS * 3600;
const DT = 0.25;

/* 플레이어 흉내.
 * 완벽한 최적 플레이가 아니라 "보통 사람이 할 법한" 판단으로 짠다.
 * 눈에 보이는 병목을 먼저 푸는 게 사람이 실제로 하는 행동이다. */
function decide(s) {
  // 숲은 최우선. 등급 분포를 바꾸는 유일한 축이라 항상 이득.
  const nf = s.nextForest();
  if (nf && s.money >= nf.cost) return 'forest';

  const rawFull = s.storedTotal() >= s.rawCap() * 0.9;    // 창고 넘침 → 씻는 게 느림
  const shelfFull = s.cleanTotal() >= s.shelfCap() * 0.9; // 진열대 참 → 안 팔림

  const order = shelfFull ? ['shelf', 'washer', 'gatherer']
              : rawFull   ? ['washer', 'shelf', 'gatherer']
              :             ['gatherer', 'washer', 'shelf'];
  for (const k of order) if (s.money >= s.cost(k)) return k;
  return null;
}

const s = new Sim();
const unlocks = [];
const buys = [];
const waits = [];
const bottleneck = { gatherer: 0, washer: 0, shelf: 0, forest: 0 };
let lastBuy = 0, wastedTotal = 0, missedSales = 0, samples = 0;
const timeline = [];

const moves = [];

for (let t = 0; t < SECONDS; t += DT) {
  const r = s.tick(DT);
  wastedTotal += r.wasted;
  if (r.newAnimal) unlocks.push({ t: s.t, a: r.newAnimal });

  // 이사 판단: 지금 이사하면 소문이 50% 이상 늘어날 때. 방치형 플레이어의 통상 기준.
  if (s.prestigeGain() >= Math.max(1, s.fame * 0.5)) {
    const clock = t;
    const gain = s.prestige();
    moves.push({ t: clock, gain, fame: s.fame });
    lastBuy = clock;
  }

  const want = decide(s);
  if (want) {
    const ok = want === 'forest' ? s.buyForest() : s.buy(want);
    if (ok) {
      waits.push(s.t - lastBuy);
      lastBuy = s.t;
      buys.push({ t: s.t, kind: want });
      bottleneck[want]++;
    }
  }

  // 손님이 왔는데 팔 게 없었던 횟수 = 파이프라인이 막힌 정도
  if (Math.floor(t) % 10 === 0 && Math.abs(t % 1) < DT) {
    samples++;
    if (s.cleanTotal() === 0) missedSales++;
    if (Math.floor(t) % 600 === 0) {
      timeline.push({ min: Math.round(t / 60), money: s.money, rev: s.lifetimeRevenue,
        g: s.gatherer, w: s.washer, sh: s.shelf, f: s.forest, fame: s.fame });
    }
  }
}

const p = (n, d = 1) => n.toFixed(d);
console.log(`\n═══ 너구리 만물상 — 밸런스 리포트 (${HOURS}시간 연속 플레이) ═══\n`);

console.log('■ 동물 — 처음 만난 시점 / 가장 최근 판에서 걸린 시간');
const first = new Map(), last = new Map();
for (const u of unlocks) { if (!first.has(u.a.id)) first.set(u.a.id, u.t); }
first.set('squirrel', 0);  // 다람쥐는 처음부터 마을에 있다
const lastMoveT = moves.length ? moves[moves.length - 1].t : 0;
for (const u of unlocks) if (u.t >= lastMoveT) last.set(u.a.id, u.t - lastMoveT);
if (!first.size) console.log('   (하나도 못 열었음 — 초반 곡선이 너무 가파름)');
for (const a of ANIMALS) {
  if (!first.has(a.id)) { console.log(`   ${'—'.padStart(9)}   ${a.emoji} ${a.name}  (미도달)`); continue; }
  const l = last.has(a.id) ? mmss(last.get(a.id)) : '이미 보유';
  console.log(`   ${mmss(first.get(a.id)).padStart(9)}   ${a.emoji} ${a.name.padEnd(4)}  최근 판: ${l}`);
}

console.log('\n■ 구매 간격 — 다음 걸 사려고 기다리는 시간 (지루함의 단위)');
const w = waits.filter((x) => x > 0).sort((a, b) => a - b);
if (w.length) {
  console.log(`   총 구매 ${buys.length}회 · 중앙값 ${p(w[Math.floor(w.length / 2)])}초 · ` +
              `상위10% ${p(w[Math.floor(w.length * 0.9)])}초 · 최장 ${p(w[w.length - 1])}초`);
  const long = w.filter((x) => x > 180).length;
  console.log(`   3분 이상 기다린 횟수: ${long}회 ${long > buys.length * 0.1 ? '← 너무 많음' : '(적정)'}`);
}

console.log('\n■ 무엇을 샀나 — 살 게 한 종류뿐이면 결정이 없는 게임이다');
const tot = buys.length || 1;
for (const [k, v] of Object.entries(bottleneck)) {
  const pct = (v / tot) * 100;
  console.log(`   ${k.padEnd(9)} ${String(v).padStart(4)}회  ${'█'.repeat(Math.round(pct / 2))} ${p(pct)}%`);
}

console.log('\n■ 파이프라인 손실');
console.log(`   창고 넘쳐서 버린 잡동사니: ${fmt(wastedTotal)}개`);
console.log(`   진열대가 비어 손님을 놓친 비율: ${p((missedSales / samples) * 100)}%`);

console.log('\n■ 이사(환생)');
if (!moves.length) console.log('   한 번도 이사 안 함 — 환생 문턱이 너무 높거나 성장이 느림');
else {
  console.log(`   총 ${moves.length}회 · 최종 소문 ${s.fame} (수입 ×${(1 + s.fame * 0.04).toFixed(1)})`);
  moves.slice(0, 12).forEach((m) => console.log(`   ${mmss(m.t).padStart(9)}  +${m.gain} → 소문 ${m.fame}`));
  if (moves.length > 12) console.log(`   ... 외 ${moves.length - 12}회`);
}

console.log('\n■ 성장 곡선 (10분 간격, 누적매출은 이사해도 안 지워지는 값)');
console.log('    시간   생애매출     너구리 빨래통 진열대  소문   숲');
for (const r of timeline) {
  console.log(`   ${String(r.min).padStart(4)}분  ${fmt(r.rev).padStart(9)}  ` +
    `${String(r.g).padStart(7)} ${String(r.w).padStart(6)} ${String(r.sh).padStart(6)} ` +
    `${String(r.fame).padStart(6)}   ${FORESTS[r.f].name}`);
}

console.log(`\n■ 최종: 생애매출 ${fmt(s.lifetimeRevenue)} · 너구리 ${s.gatherer} · ` +
  `빨래통 ${s.washer} · 진열대 ${s.shelf} · 숲 "${FORESTS[s.forest].name}"`);

/* 자동 판정 — 사람이 표를 읽고 판단하는 대신 규칙으로 잡는다 */
console.log('\n■ 진단');
const issues = [];
if (unlocks.length < 3) issues.push(`${HOURS}시간에 동물 ${unlocks.length}마리만 해금 — 진행이 너무 느림`);
if (unlocks.length >= 7) issues.push(`${HOURS}시간에 거의 다 해금 — 콘텐츠가 금방 바닥남`);
if (w.length && w[Math.floor(w.length / 2)] > 90) issues.push('구매 중앙 간격 90초 초과 — 기다리는 시간이 김');
if (w.length && w[Math.floor(w.length / 2)] < 4) issues.push('구매 간격 4초 미만 — 아무 긴장이 없음');
const maxShare = Math.max(...Object.values(bottleneck)) / tot;
if (maxShare > 0.75) issues.push(`한 종류가 구매의 ${p(maxShare * 100)}% — 사실상 살 게 하나뿐`);
if (missedSales / samples > 0.3) issues.push('손님을 놓치는 비율 30% 초과 — 생산이 판매를 못 따라감');
if (wastedTotal > 5000) issues.push(`버린 잡동사니 ${fmt(wastedTotal)}개 — 창고/빨래통 균형이 안 맞음`);

if (!issues.length) console.log('   문제 없음 — 곡선이 돈다');
else issues.forEach((i) => console.log('   ⚠ ' + i));
console.log();

function mmss(sec) {
  const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), x = Math.floor(sec % 60);
  return h ? `${h}시간${m}분` : `${m}분${String(x).padStart(2, '0')}초`;
}
