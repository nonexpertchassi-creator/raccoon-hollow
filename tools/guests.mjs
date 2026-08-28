/* guests.mjs — 손님 등장 문턱(GUESTS[].at)을 목표 시각에 수렴시킨다.
 * 실행: node tools/guests.mjs [반복횟수]
 *
 * 왜 도구가 필요한가: at은 '누적매출 얼마'인데, 그 누적매출 곡선 자체가
 * at에 따라 달라진다(손님이 일찍 오면 매출이 빨리 오른다). 손으로 찍으면
 * 한 번 고칠 때마다 나머지 열한 개가 어긋난다. 그래서 재고 → 고치고 →
 * 다시 재기를 반복해 수렴시킨다. 진동을 막으려고 감쇠를 건다
 * (새 값 = √(지금 값 × 제안값)) — 관문 값을 맞출 때 쓴 것과 같은 방법이다.
 */
import { Sim } from '../sim.js';
import { SHOPS, GUESTS, GEM_UPGRADES } from '../content.js';
import fs from 'fs';

/* 목표 시각(분). 원래 값은 콘텐츠가 8시간25분에 바닥나던 시절에 맞춘 것이라
 * 매대를 40칸으로 늘린 지금은 전부 앞당겨져 버렸다. 새 수명(14시간대)에
 * 맞춰 뒤쪽을 길게 펼친다 — 앞쪽 셋은 초반 재미라 거의 그대로 둔다. */
const TARGET = [0, 6, 15, 35, 65, 140, 190, 250, 310, 340, 420, 480];
const ROUNDS = Number(process.argv[2] || 6);
const HOURS = 10, DT = 0.25, SEEDS = [1, 2, 3];
const P = new URL('../content.js', import.meta.url).pathname;

function mkRng(seed) {
  let a = seed;
  return () => {
    a = a + 0x6D2B79F5 | 0;
    let x = Math.imul(a ^ a >>> 15, a | 1);
    x ^= x + Math.imul(x ^ x >>> 7, x | 61);
    return ((x ^ x >>> 14) >>> 0) / 4294967296;
  };
}

/* balance.mjs의 가상 플레이어와 같은 판단을 쓴다 — 다른 사람을 흉내 내면
 * 다른 곡선이 나오고, 그러면 여기서 맞춘 값이 저기서 안 맞는다. */
function act(s) {
  if (s.busy >= 0 && s.tapSmall(s.busy)) return;
  const ns = s.nextShop();
  if (ns && s.money >= ns.cost) { s.openShop(ns.id); return; }
  for (const id of s.asked) if (s.canOpenItem(id)) { s.openItem(id); return; }
  for (const sh of s.shops) if (s.canPromote(sh)) { s.promote(sh); return; }
  if (s.canBuyAuto()) { s.buyAuto(); return; }
  if (s.canBuyGuard()) { s.buyGuard(); return; }
  for (const sh of s.shops) if (s.canHireStaff(sh)) { s.hireStaff(sh); return; }
  const up = GEM_UPGRADES.map((u) => u.id).filter((id) => s.canBuyGemUp(id))
    .sort((a, b) => s.gemCost(a) - s.gemCost(b))[0];
  if (up) { s.buyGemUp(up); return; }
  if (!GEM_UPGRADES.some((u) => s.gemCost(u.id) !== null) && s.canRush()) { s.callRush(); return; }
  const sm = s.nextSmall();
  if (sm >= 0 && s.canBuildSmall(sm)) { s.buildSmall(sm); return; }
  if (s.auto) return;
  const open = Object.keys(s.items).filter((id) => !s.atMax(id))
    .sort((a, b) => s.levelCost(a) - s.levelCost(b));
  for (const id of open) if (s.money >= s.levelCost(id)) { s.levelUpMany(id, 10); return; }
}

/** 한 판 돌려 분당 누적매출 곡선과 손님별 등장 시각을 돌려준다 */
function run(seed) {
  const s = new Sim(), rng = mkRng(seed);
  const curve = [0], seen = {};
  let nextMin = 1;
  for (let t = 0; t < HOURS * 3600; t += DT) {
    s.tick(DT, rng);
    for (const g of s.guests) if (seen[g] == null) seen[g] = s.t;
    act(s);
    while (s.t >= nextMin * 60) { curve[nextMin] = s.revenue; nextMin++; }
  }
  return { curve, seen };
}

/** 여러 운 번호의 중앙값 — 한 판만 보면 운을 실력으로 착각한다 */
const med = (a) => { const b = [...a].sort((x, y) => x - y); return b[b.length >> 1]; };
const revAt = (curve, min) => curve[Math.min(min, curve.length - 1)] ?? curve[curve.length - 1];
const mm = (sec) => sec == null ? '—' : `${Math.floor(sec / 60)}분`;
const pretty = (x) => {
  if (x < 1000) return Math.max(0, Math.round(x));
  const d = 10 ** (Math.floor(Math.log10(x)) - 1);
  return Math.round(x / d) * d;
};

for (let round = 1; round <= ROUNDS; round++) {
  const runs = SEEDS.map(run);
  const cur = SHOPS && GUESTS.map((g) => g.at);
  const next = [], report = [];
  for (let i = 0; i < GUESTS.length; i++) {
    const g = GUESTS[i];
    const got = med(runs.map((r) => r.seen[g.id] ?? HOURS * 3600));
    const want = med(runs.map((r) => revAt(r.curve, TARGET[i])));
    // 감쇠: 곡선이 at에 따라 움직이므로 한 번에 다 옮기면 진동한다
    const v = i === 0 ? 0 : pretty(Math.sqrt(Math.max(1, cur[i]) * Math.max(1, want)));
    next.push(v);
    report.push(`${g.face}${g.name.padEnd(4)} 목표 ${String(TARGET[i]).padStart(3)}분 · 지금 ${mm(got).padStart(6)}`);
  }
  console.log(`── ${round}회차 ──`);
  console.log(report.join('\n'));

  /* ★ 고쳐 쓰는 범위를 GUESTS 배열 안으로 **못 박는다.**
   * 처음엔 파일 전체에서 /at: 숫자,/를 찾아 바꿨는데, PESTS에도 at이 있어서
   * 14군데가 걸렸다. 게다가 ++k로 세는 바람에 값이 한 칸씩 밀려
   * 마지막 둘이 NaN·undefined가 됐다. 그 판의 측정값은 전부 쓰레기였다.
   * 자동으로 소스를 고치는 도구는 범위를 좁히는 것이 첫 번째 안전장치다. */
  const src = fs.readFileSync(P, 'utf8');
  const head = src.indexOf('export const GUESTS = [');
  const tail = src.indexOf('\n];', head);
  let k = 0;
  const body = src.slice(head, tail).replace(/(\n\s*)at: [\d_]+,/g, (m, sp) =>
    `${sp}at: ${String(next[k++]).replace(/\B(?=(\d{3})+(?!\d))/g, '_')},`);
  if (k !== GUESTS.length) throw new Error(`at를 ${k}개 고쳤다 — ${GUESTS.length}개여야 한다`);
  fs.writeFileSync(P, src.slice(0, head) + body + src.slice(tail));
}
console.log('\ncontent.js에 새 문턱을 써 넣었다.');
