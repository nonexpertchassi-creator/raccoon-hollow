/* iso.js — 격자 마을. 그리기만 한다. scene.js(세로 두루마리)의 후임.
 *
 * 왜 갈아탔나:
 *   세로 두루마리는 가게가 늘 때마다 마을이 아래로만 길어졌다(1560 → 1750,
 *   가게 열이면 3000). 격자는 가로로도 퍼진다. 그리고 빈 칸이 눈에 보여서
 *   "폐허를 하나씩 채운다"가 지도 자체로 읽힌다.
 *
 * 시점은 비스듬히 내려다본 격자(아이소메트릭)다. 바닥 한 칸은 96×48 —
 * 가로:세로 2:1이 이 시점의 기본 비율이다. 건물은 코드로 그린 상자라서
 * 이 전환에 새 그림이 한 장도 안 들었다. 캐릭터는 그대로 정면을 본다.
 *
 * 여기엔 경제 계산이 한 줄도 없다. sim.js를 읽기만 하고 절대 고치지 않는다.
 */

import { G } from './core/engine.js';
import { Juice, Sfx } from './core/juice.js';
import { SHOPS, STOCK_CAP, SMALL_SHOPS, GUARD } from './content.js';
import { fmt, itemById } from './sim.js';
import { drawArt } from './art.js';

const VW = 480;                       // 화면 가상 폭 (엔진이 가로를 여기에 맞춘다)
const TW = 96, TH = 48;               // 바닥 한 칸
const GW = 13, GH = 18;                // 마을 크기(칸)

/** 칸 좌표 → 세계 좌표. 정수는 칸의 모서리다. */
const iso = (tx, ty) => ({ x: (tx - ty) * TW / 2, y: (tx + ty) * TH / 2 });

/* 길 — 세로 큰길(3~4열) 하나와 가로 골목(4·10행) 둘.
 * 손님은 큰길 양끝에서 들어온다. */
/* 길이 마을을 네 마당으로 가른다. 가게 마당이 5×5까지 자라도
 * 길을 밟지 않도록 4분면 하나에 가게 하나씩이다. */
const isRoad = (tx, ty) => (tx === 5 || tx === 6) || ty === 5 || ty === 12;

/* 가게는 3×3칸짜리 **마당**이다. 지붕 덮인 상자였던 것을 열어젖혔다 —
 * 안이 다 보이니 들어갈 필요가 없고, '가게 안' 화면 자체가 사라진다.
 *
 * 마당 아홉 칸의 쓰임 (마당 안 좌표):
 *   (0,0) 가마 — 가게마다 다른 분위기 소품
 *   (0,1) 작업대 — 점장이 여기서 만든다
 *   (1,0)(2,0)(1,1)(2,1) 매대 — 품목마다 한 칸. 책상+학생이 한 칸인 것과 같다
 *   (1,2) 계산대 — 점장이 나와서 계산하고, 손님은 그 앞에 선다
 *   나머지는 빈 바닥 — 사람이 오가는 자리
 *
 * ★ 화면의 가로 위치는 tx가 아니라 (tx−ty)다. 이걸 놓치면 두 가게가
 * 같은 세로줄에 포개진다. 세 세로줄에 번갈아 놓고 같은 줄에선 세로로
 * 260px 이상 벌린다. */
const SHOP_T = [
  [7, 13],   // 대장간 — 시작 화면(아래 오른 분면)
  [7, 7],    // 필방 — 가운데 오른 분면
  [8, 0],    // 지물포 — 위 오른 분면
  [0, 7],    // 옹기점 — 가운데 왼 분면
  [0, 0],    // 약재상 — 위 왼 분면
];

/** 마당 안 배치 — 등급이 오르면 마당이 커지고 매대가 늘어난다.
 *
 *   무쇠급 3×3 → 매대 4칸    참쇠급 4×4 → 6칸    강철급 5×5 → 8칸
 *
 * "품목을 늘리려면 대장간2를 지어야 하나"의 답: 둘째 대장간이 아니라
 * **같은 마당이 넓어진다.** 매대는 뒤 두 담벼락을 따라 ㄱ자로 는다.
 * (가운데에 뭉치면 화면에서 마름모로 포개져 앞 계기가 뒤 매대를 덮는다.)
 */
function plotDim(sim, i) { return 3 + Math.min(2, sim.rankOf(SHOPS[i].id)); }
function stallSpots(n) {
  const out = [];
  for (let x = 1; x < n; x++) out.push([x, 0]);      // 위 담벼락
  for (let y = 1; y < n; y++) out.push([0, y]);      // 왼 담벼락
  return out;
}
const anvilAt = (n) => Math.floor((n - 1) / 2);

const SMALL_T = [[12, 14], [12, 8], [2, 6], [0, 13]];
const DOG_T = [3, 14];

const BUY_TIME = 2.3;                 // 손님이 가게 앞에 서 있는 시간
const HAND_OVER = 1.1;                // 이 시점에 물건이 건네진다
const WALK = 95;                      // 손님 걸음(세계 px/초)
const GUEST_PX = 34, CLERK_PX = 33;
const CLERK_SPEED = 130;

const C = {
  grass: '#8b9e74', grass2: '#849668', road: '#d9cba9', roadLine: 'rgba(0,0,0,.05)',
  paper: '#ece2cb', paper2: '#dccfb2', wood: '#8a6a45', wood2: '#6d5236',
  tile: '#4a4139', ink: '#2b241b', ink2: '#5a4e3d', ink3: '#8a7a63',
  gold: '#a8763e', jade: '#4a7c59', red: '#c7563f', ruin: '#5f6b4e',
};

const shade = (hex, d) => {
  const n = parseInt(hex.slice(1), 16);
  const f = (v) => Math.max(0, Math.min(255, v + d));
  return '#' + ((f(n >> 16) << 16) | (f((n >> 8) & 255) << 8) | f(n & 255)).toString(16).padStart(6, '0');
};

/* 손님이 지고 온 짐 — qty를 눈에 보이게 하는 표시 */
const carryOf = (qty) => qty <= 5 ? 'hand' : qty <= 9 ? 'bojjim' : qty <= 14 ? 'jige' : 'cart';

export class Village {
  constructor(sim, onShopTap) {
    this.sim = sim;
    this.onShopTap = onShopTap;
    this.onDelivered = null;               // 계산이 눈앞에서 끝났을 때 — 장부(로그)는 이때 쓴다
    this.t = 0;
    this.walkers = [];
    this.coins = [];
    this.takings = {};
    /* 아직 손님이 도착하지 않은 판매량 — sim은 사는 순간 재고를 깎지만
     * 화면에선 손님이 걸어오는 시간이 있다. 그릴 때만 도로 더한다. */
    this.pending = {};
    this.flash = {};
    this.bubble = null;
    this.busyShop = {};                    // 가게별 '방금 팔렸다' 여운(점장이 쫓는다)
    this.fetch = {};                       // 가게별 '집어올 물건' — 주문 받고 내오는 연출
    this.mgr = SHOPS.map((_, i) => ({ ...this._foot(i).work, at: 'work', face: 1 }));

    /* 카메라 — 이제 2차원이다. 가로로도 민다. */
    this.viewW = VW; this.viewH = 800;
    const s0 = this._foot(0).S;
    this.cam = { x: s0.x - VW / 2, y: s0.y - 800 * 0.62 };
    this.vel = { x: 0, y: 0 };
    this.drag = null;

    this.trees = this._trees();
  }

  /** 가게 i의 요지(세계 좌표). 마당 크기는 등급이 정하므로 sim을 읽는다. */
  _foot(i) {
    const [tx, ty] = SHOP_T[i];
    const n = plotDim(this.sim, i);
    const S = iso(tx + n, ty + n);
    const a = anvilAt(n);
    const cc = iso(tx + n - 0.5, ty + n - 0.5);          // 계산대 가운데
    return {
      n, S,
      stand: { x: cc.x + 44, y: cc.y + 22 },             // 손님 — 계산대 앞
      work: iso(tx + a + 0.5, ty + a + 0.5),             // 작업대 칸
      serve: { x: cc.x - 34, y: cc.y + 12 },             // 점장 — 계산대 뒤
    };
  }

  /* 나무 — 빈 풀칸에 심는다. 매 프레임 난수를 쓰면 떨리므로 한 번만. */
  _trees() {
    let s = 20250819;
    const rng = () => (s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    const used = new Set();
    // 마당은 최대 5×5까지 자라니 나무는 처음부터 그 밖에만 심는다
    for (const [tx, ty] of SHOP_T) for (let a = 0; a < 5; a++) for (let b = 0; b < 5; b++) used.add(`${tx + a},${ty + b}`);
    for (const [tx, ty] of SMALL_T) used.add(`${tx},${ty}`);
    used.add(`${DOG_T[0]},${DOG_T[1]}`);
    const out = [];
    for (let ty = 0; ty < GH; ty++) for (let tx = 0; tx < GW; tx++) {
      if (isRoad(tx, ty) || used.has(`${tx},${ty}`)) continue;
      const r = rng();
      if (r < 0.30) out.push({ tx, ty, k: r < 0.20 ? 'tree' : r < 0.26 ? 'rock' : 'flower', o: rng() });
    }
    return out;
  }

  /* ── 바깥에서 알려주는 사건 ── */

  onSale(sale) {
    /* 걸음이 느려 한 명이 10초쯤 머문다. 실측으로 열넷이면 거래의 96%가
     * 화면에 나온다. 넘치면 그 거래는 화면에 안 나온다(계산은 끝났다). */
    if (this.walkers.length > 14) {
      // 걸어올 사람이 없으니 장부라도 바로 쓴다 — 돈은 이미 움직였다
      if (!sale.waiting && sale.n > 0 && this.onDelivered) this.onDelivered(sale);
      return;
    }
    const byShop = new Map();
    for (const ln of sale.lines) {
      const idx = SHOPS.findIndex((s) => s.id === ln.item.shop);
      if (idx < 0) continue;
      if (!byShop.has(idx)) byShop.set(idx, { idx, sold: [], gain: 0, pend: !sale.waiting });
      const g = byShop.get(idx);
      g.sold.push({ id: ln.item.id, n: ln.n });
      g.gain += ln.gain;
      /* 즉시 판매만 도로 더한다. 주문은 점장이 손에 들고 만드는 중이라
       * 진열대가 파인 게 오히려 맞는 그림이다. */
      if (!sale.waiting) this.pending[ln.item.id] = (this.pending[ln.item.id] || 0) + ln.n;
    }
    /* 빈손 손님 — 포기한 물건의 가게 앞까지는 가 본다. 💢는 거기서 나온다. */
    if (!byShop.size && sale.grumbles && sale.grumbles.length) {
      const idx = SHOPS.findIndex((s) => s.id === sale.grumbles[0].item.shop);
      if (idx >= 0) byShop.set(idx, { idx, sold: [], gain: 0 });
    }
    const stops = [...byShop.values()];
    if (!stops.length) return;

    /* 큰길 양끝 중 첫 가게에 가까운 쪽에서 들어와, 가게들을 훑고
     * 반대쪽으로 나간다. */
    const gate = (top) => iso(6, top ? -1.6 : GH + 1.6);
    const avgY = stops.reduce((a, x) => a + this._foot(x.idx).S.y, 0) / stops.length;
    const fromTop = Math.abs(gate(true).y - avgY) < Math.abs(gate(false).y - avgY);
    stops.sort((a, b) => fromTop
      ? this._foot(a.idx).S.y - this._foot(b.idx).S.y
      : this._foot(b.idx).S.y - this._foot(a.idx).S.y);
    const g0 = gate(fromTop);
    this.walkers.push({
      id: sale.guest.id, face: sale.guest.face,
      reg: this.sim.regularLv(sale.guest.id),
      speed: sale.guest.speed || 1,
      carry: carryOf(sale.guest.qty),
      stops, si: 0,
      sale, orderId: sale.orderId, settled: !sale.waiting,
      x: g0.x + (Math.random() - 0.5) * 40, y: g0.y,
      exitGate: gate(!fromTop),
      state: 'in', wait: 0, paid: false, served: false, bob: Math.random() * 6,
      lane: (Math.random() - 0.5) * 34,
    });
  }

  /** 기다리던 주문이 다 나왔다 — sim이 방금 돈을 움직였다. 손님을 깨운다. */
  onOrderDone(done) {
    const w = this.walkers.find((x) => x.orderId === done.orderId);
    if (!w) {
      if (done.n > 0 && this.onDelivered) this.onDelivered(done);
      return;
    }
    w.sale = done;
    w.settled = true;
    // 실제로 받아가는 만큼으로 바꿔 단다 (시간 초과면 주문보다 적을 수 있다)
    const byShop = new Map();
    for (const ln of done.lines) {
      const idx = SHOPS.findIndex((s) => s.id === ln.item.shop);
      if (!byShop.has(idx)) byShop.set(idx, { sold: [], gain: 0 });
      const g = byShop.get(idx);
      g.sold.push({ id: ln.item.id, n: ln.n });
      g.gain += ln.gain;
    }
    for (const stop of w.stops) {
      const g = byShop.get(stop.idx);
      stop.sold = g ? g.sold : [];
      stop.gain = g ? g.gain : 0;
    }
  }

  /** 계산은 끝났는데 아직 계산대 연출이 안 끝난 돈.
   *  위쪽 엽전 표시는 이만큼 빼고 보여준다 — 돈이 미리 오르면 버그로 보인다. */
  inTransit() {
    let s = 0;
    for (const w of this.walkers) {
      if (!w.settled) continue;                 // 주문 대기 — 돈이 아직 안 움직였다
      for (let i = w.si; i < w.stops.length; i++) {
        if (i === w.si && w.paid) continue;
        s += w.stops[i].gain;
      }
    }
    return s;
  }

  onAsk(ask) {
    const idx = SHOPS.findIndex((s) => s.id === ask.item.shop);
    if (idx < 0) return;
    this.bubble = { idx, text: `${ask.item.name}?`, t: 4.5, face: ask.guest.face };
  }

  /* ── 매 프레임 ── */
  update(dt, pointer, viewH) {
    if (viewH && viewH !== this.viewH) {
      this.cam.y += (this.viewH - viewH) / 2;    // 보던 가운데를 붙잡는다
      this.viewH = viewH;
    }
    this.t += dt;
    if (this.bubble) { this.bubble.t -= dt; if (this.bubble.t <= 0) this.bubble = null; }
    for (const k of Object.keys(this.flash)) { this.flash[k] -= dt; if (this.flash[k] <= 0) delete this.flash[k]; }
    for (const k of Object.keys(this.busyShop)) { this.busyShop[k] -= dt; if (this.busyShop[k] <= 0) delete this.busyShop[k]; }

    // 손님 — 큰길을 따라 내려오다 가게 앞으로 꺾는다
    for (const w of this.walkers) {
      const stop = w.stops[w.si];
      if (w.state === 'in' && stop) {
        /* 직선으로 걷는다. 세로 두루마리에선 큰길을 따라가다 꺾었지만,
         * 격자에선 그 규칙이 마을 반대편까지 도는 우회를 만들었다.
         * 아이소메트릭에서 직선은 어차피 비스듬한 길로 보인다. */
        const f = this._foot(stop.idx);
        const tgt = { x: f.stand.x + w.lane * 0.4, y: f.stand.y };
        const dx = tgt.x - w.x, dy = tgt.y - w.y;
        const d = Math.hypot(dx, dy);
        if (d > 2) {
          const step = Math.min(d, WALK * 1.3 * w.speed * dt);
          w.x += dx / d * step; w.y += dy / d * step;
        }
        if (d < 4) {
          w.state = 'buy'; w.wait = BUY_TIME; w.paid = false; w.served = false;
        }
      } else if (w.state === 'buy') {
        /* 주문한 물건이 아직 안 나왔다 — 점장은 만드는 중, 손님은 서서 기다린다.
         * 계산 연출은 sim이 onOrderDone으로 깨워줄 때 시작한다. */
        if (!w.settled) continue;
        if (!w.served) {
          w.served = true; w.wait = BUY_TIME;
          this.busyShop[stop.idx] = BUY_TIME + 1.2;
          /* 점장이 이 매대에 들러 물건을 집어 온다 — '주문 받고 내온다'가
           * 눈에 보이는 지점. 경제는 그대로다(재고에서 파는 것). */
          if (stop.sold.length) this.fetch[stop.idx] = stop.sold[0].id;
        }
        w.wait -= dt;
        if (!w.paid && w.wait <= BUY_TIME - HAND_OVER) {
          w.paid = true;
          if (stop.gain > 0) {
            for (const s of stop.sold) {
              if (stop.pend) this.pending[s.id] = Math.max(0, (this.pending[s.id] || 0) - s.n);
              this.flash[s.id] = 0.45;
            }
            for (let k = 0; k < Math.min(5, stop.sold.length + 2); k++) {
              this.coins.push({
                x: w.x + (Math.random() - 0.5) * 16, y: w.y - 10,
                vx: 20 + Math.random() * 30, vy: -80 - Math.random() * 40,
                t: 1.05, r: 8.5 + Math.random() * 2.5,
              });
            }
            const tk = (this.takings[stop.idx] ||= { amount: 0, t: 0 });
            tk.amount += stop.gain; tk.t = 1.7;
            const sy = w.y - this.cam.y, sx = w.x - this.cam.x;
            if (sy > -20 && sy < this.viewH + 20 && sx > -20 && sx < VW + 20) {
              Juice.burst(sx, sy - 14, { n: 4, color: ['#f0d98b'], size: 2, speed: 52, life: 0.34 });
            }
            Sfx.coin();
          }
          /* 장부는 마지막 계산이 끝난 이 순간에 쓴다 — 미리 쓰면 버그로 보인다 */
          if (w.si === w.stops.length - 1 && this.onDelivered) this.onDelivered(w.sale);
        }
        if (w.wait <= 0) { w.si++; w.state = w.si < w.stops.length ? 'in' : 'out'; }
      } else {
        const dx = w.exitGate.x + w.lane - w.x, dy = w.exitGate.y - w.y;
        const d = Math.hypot(dx, dy);
        const step = Math.min(d, WALK * 1.25 * w.speed * dt);
        if (d > 1) { w.x += dx / d * step; w.y += dy / d * step; }
        if (d < 30) w.gone = true;
      }
    }
    this.walkers = this.walkers.filter((w) => !w.gone);

    // 점장 — 주문이 오면 매대에서 집어서 계산대로, 아니면 작업대로
    for (let i = 0; i < SHOPS.length; i++) {
      const m = this.mgr[i];
      const f = this._foot(i);
      const serving = (this.busyShop[i] || 0) > 0;
      if (!serving) delete this.fetch[i];
      let t = serving ? f.serve : f.work;
      /* 집어올 물건이 있으면 그 매대부터 들른다 */
      const fid = serving ? this.fetch[i] : null;
      if (fid && this.sim.isOpen(fid)) {
        const shop = SHOPS[i];
        const k = shop.items.findIndex((x) => x.id === fid);
        const spots = stallSpots(plotDim(this.sim, i));
        if (k >= 0 && k < spots.length) {
          const [lx, ly] = spots[k];
          const sp = iso(SHOP_T[i][0] + lx + 0.5, SHOP_T[i][1] + ly + 0.5);
          const near = Math.hypot(sp.x + 26 - m.x, sp.y + 14 - m.y) < 5;
          if (near) delete this.fetch[i];            // 집었다 — 이제 계산대로
          else t = { x: sp.x + 26, y: sp.y + 14 };
        }
      }
      const dx = t.x - m.x, dy = t.y - m.y, d = Math.hypot(dx, dy);
      if (d > 1.5) {
        const step = Math.min(d, CLERK_SPEED * dt);
        m.x += dx / d * step; m.y += dy / d * step;
        m.at = 'walk'; if (Math.abs(dx) > 1) m.face = Math.sign(dx);
      } else {
        m.x = t.x; m.y = t.y;
        m.at = serving ? 'sell' : 'work';
        if (m.at === 'sell') m.face = 1;                // 손님은 오른쪽에 선다
      }
    }

    for (const co of this.coins) {
      co.t -= dt; co.x += co.vx * dt; co.y += co.vy * dt; co.vy += 165 * dt;
    }
    this.coins = this.coins.filter((co) => co.t > 0);
    for (const k of Object.keys(this.takings)) {
      this.takings[k].t -= dt;
      if (this.takings[k].t <= 0) delete this.takings[k];
    }

    this._camera(dt, pointer);
  }

  /* ── 카메라 — 2차원 끌기 ── */
  _camera(dt, p) {
    if (p.justDown) { this.drag = { x: p.x, y: p.y, moved: 0 }; this.vel.x = this.vel.y = 0; }
    if (this.drag && p.down) {
      const dx = p.x - this.drag.x, dy = p.y - this.drag.y;
      this.cam.x -= dx; this.cam.y -= dy;
      this.vel.x = -dx / Math.max(dt, 1 / 120);
      this.vel.y = -dy / Math.max(dt, 1 / 120);
      this.drag.moved += Math.abs(dx) + Math.abs(dy);
      this.drag.x = p.x; this.drag.y = p.y;
    } else if (this.drag) {
      if (this.drag.moved < 7) this._tap(p.x + this.cam.x, p.y + this.cam.y);
      this.drag = null;
    }
    if (!this.drag) {
      this.cam.x += this.vel.x * dt; this.cam.y += this.vel.y * dt;
      const f = Math.pow(0.0016, dt);
      this.vel.x *= f; this.vel.y *= f;
      if (Math.abs(this.vel.x) < 4) this.vel.x = 0;
      if (Math.abs(this.vel.y) < 4) this.vel.y = 0;
    }
    // 마을 밖으로 못 나가게. 창이 마을보다 크면 가운데 고정.
    const b = this._bounds();
    this.cam.x = clampAxis(this.cam.x, b.x0, b.x1, VW);
    this.cam.y = clampAxis(this.cam.y, b.y0, b.y1, this.viewH);
  }

  _bounds() {
    return {
      x0: iso(0, GH).x - 40, x1: iso(GW, 0).x + 40,
      y0: iso(0, 0).y - 150, y1: iso(GW, GH).y + 90,
    };
  }

  camMax() { const b = this._bounds(); return Math.max(0, b.y1 - b.y0 - this.viewH); }

  /** 이 가게가 지금 화면 어디에 있나 — 들어갈 때 확대의 중심 */
  shopScreenPos(i) {
    const S = this._foot(i).S;
    return { x: S.x - this.cam.x, y: S.y - 60 - this.cam.y };
  }

  /* ── 손가락 ── */
  _tap(wx, wy) {
    // 나쁜 놈이 제일 급하다
    const th = this._pestAt();
    if (th) {
      const hx = th.screen ? wx - this.cam.x : wx;
      const hy = th.screen ? wy - this.cam.y : wy;
      if (Math.hypot(hx - th.x, hy - th.y + 6) < th.r) {
        const got = this.sim.catchPest();
        if (got) {
          Sfx.win(); Juice.shake(7);
          const cx = th.screen ? th.x + this.cam.x : th.x;
          const cy = th.screen ? th.y + this.cam.y : th.y;
          for (let i = 0; i < 6; i++) {
            this.coins.push({
              x: cx + (Math.random() - 0.5) * 14, y: cy - 8,
              vx: (Math.random() - 0.5) * 90, vy: -95 - Math.random() * 45,
              t: 1.2, r: 9 + Math.random() * 3,
            });
          }
          return;
        }
      }
    }

    // 삽살개 자리
    {
      const p = iso(DOG_T[0] + 1, DOG_T[1] + 1);
      if (!this.sim.guard && Math.abs(wx - p.x) < 60 && wy > p.y - 80 && wy < p.y + 26) {
        if (this.sim.buyGuard()) { Sfx.reward(); Juice.shake(5); } else Sfx.deny();
        return;
      }
    }

    // 곁가게
    for (let i = 0; i < SMALL_T.length; i++) {
      const p = iso(SMALL_T[i][0] + 1, SMALL_T[i][1] + 1);
      if (Math.abs(wx - p.x) < 62 && wy > p.y - 92 && wy < p.y + 24) {
        if (!this.sim.smalls.includes(i)) {
          if (this.sim.buildSmall(i)) { Sfx.reward(); Juice.shake(5); } else Sfx.deny();
        } else if (this.sim.tapSmall(i)) { Sfx.win(); Juice.shake(6); }
        else Sfx.click();
        return;
      }
    }

    // 가게 마당 — 매대는 그 자리에서 바로 강화/열기, 나머지는 가게 창
    for (let i = 0; i < SHOPS.length; i++) {
      const [tx, ty] = SHOP_T[i];
      const shop = SHOPS[i];
      const open = this.sim.shops.includes(shop.id);
      if (open) {
        /* 이웃 칸은 화면에서 48px밖에 안 떨어진다. '먼저 맞은 것'을 고르면
         * 뒤 매대가 앞 매대의 몫을 삼킨다 — **제일 가까운 매대**를 고른다. */
        let best = null;
        const n = plotDim(this.sim, i);
        const spots = stallSpots(n);
        const cap = Math.min(this.sim.stallCap(shop.id), shop.items.length);
        for (let k = 0; k < cap; k++) {
          const [lx, ly] = spots[k];
          const p = iso(tx + lx + 0.5, ty + ly + 0.5);
          if (Math.abs(wx - p.x) > 52 || wy < p.y - 64 || wy > p.y + 28) continue;
          const d = Math.hypot(wx - p.x, (wy - (p.y - 18)) * 1.4);
          if (!best || d < best.d) best = { it: shop.items[k], d };
        }
        if (best) {
          const it = best.it;
          if (!this.sim.isOpen(it.id)) {
            if (this.sim.canOpenItem(it.id) && this.sim.openItem(it.id)) { Sfx.win(); Juice.shake(6); }
            else Sfx.deny();
            return;
          }
          /* 매대를 누르면 그 품목을 살 수 있는 만큼 강화한다 —
           * 가게 안 화면이 없어졌으니 강화가 지도에서 바로 돼야 한다 */
          const n = this.sim.affordableLevels(it.id);
          if (n > 0 && this.sim.levelUpMany(it.id, n)) { Sfx.click(); this.flash[it.id] = 0.35; }
          else Sfx.deny();
          return;
        }
      }
      // 마당 나머지(현판 포함) — 가게 창을 연다 (승급·자세한 숫자)
      const n2 = open ? plotDim(this.sim, i) : 3;
      const M = iso(tx + n2 / 2, ty + n2 / 2);
      const inPlot = Math.abs(wx - M.x) / (n2 * 50 + 4) + Math.abs(wy - M.y) / (n2 * 25 + 4) <= 1;
      const N = iso(tx, ty);
      const onSign = Math.abs(wx - N.x) < 90 && wy > N.y - 72 && wy < N.y - 40;
      if (inPlot || onSign) {
        this.onShopTap(shop.id, open);
        return;
      }
    }
  }

  /* ── 그리기 ── */
  draw(c) {
    c.save();
    c.translate(-this.cam.x, -this.cam.y);

    const left = this.cam.x - 60, right = this.cam.x + VW + 60;
    const top = this.cam.y - 120, bot = this.cam.y + this.viewH + 80;
    const vis = (p, pad = 0) =>
      p.x > left - pad && p.x < right + pad && p.y > top - pad && p.y < bot + pad;

    // 바닥
    for (let ty = 0; ty < GH; ty++) for (let tx = 0; tx < GW; tx++) {
      const p = iso(tx + 1, ty + 1);            // 칸의 아래 꼭짓점
      if (!vis(p, TW)) continue;
      this._tile(c, tx, ty, isRoad(tx, ty));
    }

    // 깊이 순서대로 — 아래 꼭짓점 y가 큰 것이 앞이다
    const layer = [];
    for (let i = 0; i < SHOPS.length; i++) {
      const [tx, ty] = SHOP_T[i];
      const n = plotDim(this.sim, i);
      const S = iso(tx + n, ty + n);
      if (!vis(S, TW * 3)) continue;
      if (!this.sim.shops.includes(SHOPS[i].id)) {
        layer.push({ z: S.y, d: () => this._ruin(c, i) });
        continue;
      }
      /* 마당을 한 덩어리로 그리면 마당의 z(아래 꼭짓점)가 마당 **안에 서 있는**
       * 손님·점장보다 커서 가구가 동물을 덮었다. 바닥은 맨 뒤로 보내고,
       * 가구 하나하나를 자기 발끝 z로 따로 세운다 — 그래야 손님이 계산대
       * 뒤에 서면 가려지고 앞에 서면 가리는, 당연한 일이 당연하게 된다. */
      layer.push({ z: iso(tx, ty).y + 2, d: () => this._plotBase(c, i, n) });
      layer.push({ z: iso(tx + 1, ty + 1).y, d: () => this._kiln(c, i) });
      const cap = Math.min(this.sim.stallCap(SHOPS[i].id), SHOPS[i].items.length);
      const spots = stallSpots(n);
      for (let k = 0; k < cap; k++) {
        const [lx, ly] = spots[k];
        const kk = k;
        layer.push({ z: iso(tx + lx + 1, ty + ly + 1).y, d: () => this._stall(c, i, kk, spots[kk]) });
      }
      layer.push({ z: S.y, d: () => this._counter(c, i, n) });
      /* 직원 — 늘 작업대 줄에 붙어 만든다. 점장이 계산대로 불려가도
       * 이쪽은 계속 만든다. '한 마리는 생산, 한 마리는 판매'가 이 그림이다. */
      const nst = this.sim.staffOf(SHOPS[i].id);
      for (let sIdx = 0; sIdx < nst; sIdx++) {
        const sp = iso(tx + 1.5 + sIdx, ty + n - 1.5);
        const si = sIdx;
        layer.push({ z: sp.y + 0.5, d: () => this._staff(c, i, si, sp) });
      }
    }
    for (let i = 0; i < SMALL_T.length; i++) {
      const p = iso(SMALL_T[i][0] + 1, SMALL_T[i][1] + 1);
      if (vis(p, TW)) layer.push({ z: p.y, d: () => this._small(c, i) });
    }
    {
      const p = iso(DOG_T[0] + 1, DOG_T[1] + 1);
      if (vis(p, TW)) layer.push({ z: p.y, d: () => this._dog(c, p) });
    }
    for (const tr of this.trees) {
      const p = iso(tr.tx + 0.5, tr.ty + 0.5);
      if (vis(p, 60)) layer.push({ z: p.y + TH / 2, d: () => this._prop(c, tr, p) });
    }
    for (const w of this.walkers) if (vis(w, 60)) layer.push({ z: w.y, d: () => this._walker(c, w) });
    for (let i = 0; i < SHOPS.length; i++) {
      const k = this._clerk(i);
      if (k && vis(k, 60)) layer.push({ z: k.y + 0.5, d: () => this._clerkDraw(c, k) });
    }
    const th = this._pestAt();
    if (th && !th.screen && vis(th, 60)) layer.push({ z: th.y + 1, d: () => this._pest(c, th) });
    layer.sort((a, b) => a.z - b.z);
    for (const l of layer) l.d();

    // 말풍선·표는 깊이 정렬 밖 — 가려지면 못 읽는다
    for (const w of this.walkers) {
      if (w.state !== 'buy' || !vis(w, 80)) continue;
      if (!w.paid) this._order(c, w);
      /* 빈손이거나 일부를 포기했다 — 💢 */
      const gr = w.sale && w.sale.grumbles && w.sale.grumbles.length;
      if (gr && (w.paid || !w.stops[w.si] || !w.stops[w.si].sold.length)) {
        G.text(c, '💢', w.x + 15, w.y - 46 + Math.sin(this.t * 5.2) * 2, { size: 19, fill: '#000' });
      }
    }
    for (const k of Object.keys(this.takings)) this._takings(c, Number(k));
    if (this.bubble) this._bubble(c);
    for (const co of this.coins) if (vis(co, 30)) this._coin(c, co);

    c.restore();

    // 화면에 붙는 것들
    if (th && th.screen) this._pest(c, th);
    if (this.sim.fair > 0) {
      G.round(c, VW / 2 - 76, 10, 152, 28, 10, C.red);
      G.text(c, `장이 섰다 · ${Math.ceil(this.sim.fair)}초`, VW / 2, 24,
        { size: 13.5, fill: '#fff3dd', weight: 800 });
    }
  }

  _tile(c, tx, ty, road) {
    const n = iso(tx, ty), e = iso(tx + 1, ty), s = iso(tx + 1, ty + 1), w2 = iso(tx, ty + 1);
    c.beginPath();
    c.moveTo(n.x, n.y); c.lineTo(e.x, e.y); c.lineTo(s.x, s.y); c.lineTo(w2.x, w2.y);
    c.closePath();
    c.fillStyle = road ? C.road : ((tx + ty) % 2 ? C.grass : C.grass2);
    c.fill();
    c.strokeStyle = road ? C.roadLine : 'rgba(0,0,0,.03)';
    c.lineWidth = 1; c.stroke();
  }

  _prop(c, tr, p) {
    if (tr.k === 'tree') {
      G.rect(c, p.x - 3, p.y - 10, 6, 12, C.wood2);
      G.circle(c, p.x, p.y - 22, 16 + tr.o * 5, '#6f8a5c');
      G.circle(c, p.x - 7, p.y - 15, 10, '#7fa070');
    } else if (tr.k === 'rock') {
      G.circle(c, p.x, p.y - 4, 8 + tr.o * 4, '#8f8f7a');
    } else {
      for (let k = 0; k < 3; k++) {
        G.circle(c, p.x + (k - 1) * 9, p.y - 4 - (k % 2) * 5, 3, k % 2 ? '#e5b8c4' : '#efe3a8');
      }
    }
  }

  /** 다진 흙마당 한 칸 — 작은 건물의 발밑. 이게 있어야 땅에 붙어 보인다. */
  _pad(c, tx, ty) {
    const N = iso(tx, ty), E = iso(tx + 1, ty), S = iso(tx + 1, ty + 1), W2 = iso(tx, ty + 1);
    c.beginPath();
    c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(S.x, S.y); c.lineTo(W2.x, W2.y);
    c.closePath();
    c.fillStyle = '#c2ad83'; c.fill();
    c.strokeStyle = 'rgba(60,50,30,.28)'; c.lineWidth = 1.5; c.stroke();
  }

  /** 건물 상자 — 윗면·왼면·오른면 */
  _box(c, tx, ty, w, d, h, topCol, sideCol) {
    const N = iso(tx, ty), E = iso(tx + w, ty), S = iso(tx + w, ty + d), W2 = iso(tx, ty + d);
    // 왼면(서쪽) · 오른면(동쪽)
    c.beginPath(); c.moveTo(W2.x, W2.y - h); c.lineTo(S.x, S.y - h); c.lineTo(S.x, S.y); c.lineTo(W2.x, W2.y);
    c.closePath(); c.fillStyle = sideCol; c.fill();
    c.beginPath(); c.moveTo(E.x, E.y - h); c.lineTo(S.x, S.y - h); c.lineTo(S.x, S.y); c.lineTo(E.x, E.y);
    c.closePath(); c.fillStyle = shade(sideCol, -18); c.fill();
    // 윗면
    c.beginPath(); c.moveTo(N.x, N.y - h); c.lineTo(E.x, E.y - h); c.lineTo(S.x, S.y - h); c.lineTo(W2.x, W2.y - h);
    c.closePath(); c.fillStyle = topCol; c.fill();
    return { N, E, S, W: W2 };
  }

  _ruin(c, i) {
    const shop = SHOPS[i];
    const [tx, ty] = SHOP_T[i];
    const S = iso(tx + 3, ty + 3);
    const N = iso(tx, ty), E = iso(tx + 3, ty), W2 = iso(tx, ty + 3);
    c.save();
    c.setLineDash([8, 7]); c.lineWidth = 2; c.strokeStyle = 'rgba(50,44,30,.45)';
    c.beginPath(); c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(S.x, S.y); c.lineTo(W2.x, W2.y);
    c.closePath(); c.stroke(); c.restore();
    const M = iso(tx + 1.5, ty + 1.5);
    for (let k = 0; k < 3; k++) {
      G.round(c, M.x - 34 + k * 28, M.y - 14 + (k % 2) * 6, 8, 22 - k * 5, 3, '#6a6a55');
    }
    const next = this.sim.nextShop();
    const isNext = next && next.id === shop.id;
    G.text(c, isNext ? shop.name : '무너진 집', M.x, M.y - 34,
      { size: 14, fill: isNext ? '#4a4232' : C.ruin, weight: 800 });
    if (isNext) {
      const can = this.sim.money >= shop.cost;
      G.round(c, M.x - 50, M.y + 4, 100, 25, 9, can ? C.jade : '#77775f');
      G.text(c, `${fmt(shop.cost)}냥`, M.x, M.y + 16.5, { size: 12.5, fill: '#fff', weight: 800 });
    }
  }

  /** 마당 바닥·담·현판·표 — 항상 맨 뒤에 깔린다 */
  _plotBase(c, i, n) {
    const shop = SHOPS[i];
    const [tx, ty] = SHOP_T[i];
    const N = iso(tx, ty), E = iso(tx + n, ty), S = iso(tx + n, ty + n), W2 = iso(tx, ty + n);

    c.beginPath();
    c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(S.x, S.y); c.lineTo(W2.x, W2.y);
    c.closePath();
    c.fillStyle = '#d3c5a4'; c.fill();
    c.strokeStyle = shade(shop.color, 40); c.lineWidth = 2; c.stroke();

    for (const [A, B] of [[W2, N], [N, E]]) {
      c.beginPath();
      c.moveTo(A.x, A.y); c.lineTo(B.x, B.y);
      c.lineTo(B.x, B.y - 16); c.lineTo(A.x, A.y - 16);
      c.closePath(); c.fillStyle = shade(shop.color, -8); c.fill();
      c.beginPath(); c.moveTo(A.x, A.y - 16); c.lineTo(B.x, B.y - 16);
      c.strokeStyle = shade(shop.color, 26); c.lineWidth = 3; c.stroke();
    }

    // 현판 — 등급은 여기에만 적는다
    const rk = this.sim.rankOf(shop.id);
    const sTxt = rk > 0 ? `${shop.sign} ${shop.name} · ${shop.ranks[rk]}` : `${shop.sign} ${shop.name}`;
    const sw = 30 + sTxt.length * 12.5;
    G.rect(c, N.x - 3, N.y - 44, 6, 44, C.wood2);
    G.round(c, N.x - sw / 2, N.y - 66, sw, 26, 8, shop.color);
    G.text(c, sTxt, N.x, N.y - 53, { size: 14, fill: '#fff8ec', weight: 800 });

    // 매대가 모자라면 — 다음 승급이 매대를 늘린다는 걸 알린다
    const cap = this.sim.stallCap(shop.id);
    if (shop.items.length > cap) {
      G.text(c, `승급하면 매대 +2`, S.x, S.y + 20,
        { size: 11.5, fill: 'rgba(43,36,27,.55)', weight: 800 });
    }

    /* 들어가서 좋은 일이 있을 때만 표 — 숙제가 아니라 초대장 */
    const todo = this.sim.shopTodo(shop.id);
    if (todo > 0) {
      const bob = Math.sin(this.t * 4) * 3;
      const promo = this.sim.canPromote(shop.id);
      const txt = promo ? '승급!' : this.sim.canHireStaff(shop.id) ? '일손!' : '새 칸!';
      const tw = 26 + txt.length * 13;
      G.round(c, N.x - tw / 2, N.y - 100 + bob, tw, 25, 9, promo ? C.red : C.jade);
      G.text(c, txt, N.x, N.y - 87.5 + bob, { size: 14, fill: '#fff3dd', weight: 800 });
    }
  }

  _kiln(c, i) {
    const shop = SHOPS[i];
    const [tx, ty] = SHOP_T[i];
    const p = iso(tx + 0.5, ty + 0.5);
    this._box(c, tx + 0.22, ty + 0.22, 0.56, 0.56, 26,
      shade(shop.color, 24), shade(shop.color, -16));
    const fl = 0.6 + Math.abs(Math.sin(this.t * 3 + i)) * 0.4;
    G.circle(c, p.x, p.y - 30, 5 * fl, '#f0a24b');
    G.circle(c, p.x, p.y - 36, 3 * fl, '#f6d27a');
  }

  /** 매대 한 칸 = 좌대 + 물건 + 재고·진행 계기 + 이름패 */
  _stall(c, i, k, spot) {
    const shop = SHOPS[i];
    const [tx, ty] = SHOP_T[i];
    const [lx, ly] = spot;
    const p = iso(tx + lx + 0.5, ty + ly + 0.5);
    const it = shop.items[k];

    if (!this.sim.isOpen(it.id)) {
      c.save();
      c.setLineDash([5, 5]); c.strokeStyle = 'rgba(60,52,36,.45)'; c.lineWidth = 1.6;
      const n2 = iso(tx + lx, ty + ly), e2 = iso(tx + lx + 1, ty + ly),
            s2 = iso(tx + lx + 1, ty + ly + 1), w3 = iso(tx + lx, ty + ly + 1);
      c.beginPath(); c.moveTo(n2.x, n2.y); c.lineTo(e2.x, e2.y); c.lineTo(s2.x, s2.y); c.lineTo(w3.x, w3.y);
      c.closePath(); c.stroke(); c.restore();
      const asked = this.sim.asked.includes(it.id);
      if (asked) {
        const can = this.sim.money >= itemById(it.id).cost;
        G.text(c, itemById(it.id).name, p.x, p.y - 26, { size: 12.5, fill: C.ink2, weight: 800 });
        G.round(c, p.x - 36, p.y - 16, 72, 21, 7, can ? C.jade : 'rgba(60,52,36,.32)');
        G.text(c, `${fmt(itemById(it.id).cost)}냥`, p.x, p.y - 5.5, { size: 11, fill: '#fff', weight: 800 });
      } else {
        G.text(c, '? ? ?', p.x, p.y - 8, { size: 12, fill: 'rgba(60,52,36,.5)', weight: 800 });
      }
      return;
    }

    const st = this.sim.items[it.id];
    const fl = this.flash[it.id] || 0;
    const cap = this.sim.capOf(it.id);
    const shown = Math.min(cap, st.stock + (this.pending[it.id] || 0));
    const capped = shown >= cap;

    this._box(c, tx + lx + 0.14, ty + ly + 0.14, 0.72, 0.72, 14,
      fl > 0 ? '#f2e0ae' : C.paper, C.wood);
    drawArt(c, 'items', it.id, p.x - 16, p.y - 14, 26, 42);

    const ry = p.y - 46, rr = 15;
    const pr = capped ? 1 : Math.max(0, Math.min(1, st.prog / this.sim.craftTime(it.id)));
    G.circle(c, p.x + 12, ry, rr - 3, 'rgba(252,246,232,.95)');
    c.save();
    c.lineWidth = 3.5; c.lineCap = 'round';
    c.strokeStyle = 'rgba(43,36,27,.30)';
    c.beginPath(); c.arc(p.x + 12, ry, rr, 0, Math.PI * 2); c.stroke();
    if (pr > 0.01) {
      c.strokeStyle = capped ? '#ff8a63' : '#e8b93f';
      c.beginPath(); c.arc(p.x + 12, ry, rr, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pr); c.stroke();
    }
    c.restore();
    G.text(c, String(shown), p.x + 12, ry, { size: fl > 0 ? 17 : 15.5, fill: C.ink, weight: 800 });

    const nm = itemById(it.id).name;
    const nw = 14 + nm.length * 11;
    G.round(c, p.x - nw / 2, p.y + 8, nw, 18, 5, 'rgba(43,36,27,.78)');
    G.text(c, nm, p.x, p.y + 17, { size: 11, fill: '#fff8ec', weight: 800 });
  }

  _counter(c, i, n) {
    const [tx, ty] = SHOP_T[i];
    this._box(c, tx + n - 1 + 0.16, ty + n - 1 + 0.3, 0.68, 0.4, 18, C.paper2, C.wood2);
    const p = iso(tx + n - 0.5, ty + n - 0.5);
    G.circle(c, p.x + 8, p.y - 24, 4.5, '#c9a227');    // 엽전 접시
  }

  _small(c, i) {
    const [tx, ty] = SMALL_T[i];
    const def = SMALL_SHOPS[i];
    const p = iso(tx + 1, ty + 1);

    if (!this.sim.smalls.includes(i)) {
      const N = iso(tx, ty), E = iso(tx + 1, ty), W2 = iso(tx, ty + 1);
      c.save();
      c.setLineDash([6, 5]); c.lineWidth = 2; c.strokeStyle = 'rgba(60,52,36,.4)';
      c.beginPath(); c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(p.x, p.y); c.lineTo(W2.x, W2.y);
      c.closePath(); c.stroke(); c.restore();
      G.text(c, `${def.name} 자리`, p.x, p.y - TH - 16, { size: 11, fill: C.ruin, weight: 800 });
      const can = this.sim.money >= def.cost;
      G.round(c, p.x - 40, p.y - TH - 8, 80, 21, 7, can ? C.jade : 'rgba(60,52,36,.30)');
      G.text(c, `${fmt(def.cost)}냥`, p.x, p.y - TH + 2.5, { size: 11, fill: can ? '#fff' : '#e6e0cf', weight: 800 });
      return;
    }

    /* 건물이 '땅에 서 있다'는 인상은 이 순서가 만든다:
     * 다진 흙마당(발 밑) → 벽 → 벽보다 넓게 나온 처마 지붕.
     * 예전엔 상자 밑에 그림자 타원을 깔았는데, 그림자가 바닥 밖으로
     * 삐져나오니 오히려 공중에 뜬 것처럼 보였다. 지붕도 길바닥과 같은
     * 미색이라 윗면이 '떠 있는 땅 한 칸'으로 읽혔다. */
    this._pad(c, tx, ty);
    this._box(c, tx + 0.16, ty + 0.16, 0.68, 0.68, 19, C.paper2, C.wood);
    c.save(); c.translate(0, -19);
    this._box(c, tx + 0.02, ty + 0.02, 0.96, 0.96, 9, '#8a6647', '#6b4c33');
    c.restore();
    G.round(c, p.x - 30, p.y - 46, 60, 17, 6, 'rgba(43,36,27,.85)');
    G.text(c, def.name, p.x, p.y - 37.5, { size: 10.5, fill: '#fff8ec', weight: 800 });

    if (this.sim.busy === i) {
      const bob = Math.sin(this.t * 5) * 4;
      G.glow?.(c, p.x, p.y - 46, 44, 'rgba(255,214,120,.34)');
      G.round(c, p.x - 30, p.y - 96 + bob, 60, 24, 9, C.red);
      G.text(c, '장 서다!', p.x, p.y - 84 + bob, { size: 12.5, fill: '#fff3dd', weight: 800 });
    }
  }

  _dog(c, p) {
    if (!this.sim.guard) {
      const [tx, ty] = DOG_T;
      const N = iso(tx, ty), E = iso(tx + 1, ty), W2 = iso(tx, ty + 1);
      c.save();
      c.setLineDash([6, 5]); c.lineWidth = 2; c.strokeStyle = 'rgba(60,52,36,.4)';
      c.beginPath(); c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(p.x, p.y); c.lineTo(W2.x, W2.y);
      c.closePath(); c.stroke(); c.restore();
      G.text(c, '삽살개 자리', p.x, p.y - TH - 16, { size: 11, fill: C.ruin, weight: 800 });
      const can = this.sim.money >= GUARD.cost;
      G.round(c, p.x - 38, p.y - TH - 8, 76, 21, 7, can ? C.jade : 'rgba(60,52,36,.30)');
      G.text(c, `${fmt(GUARD.cost)}냥`, p.x, p.y - TH + 2.5, { size: 11, fill: can ? '#fff' : '#e6e0cf', weight: 800 });
      return;
    }
    // 개집 — 작은 가게와 같은 문법: 흙마당 → 벽 → 처마
    this._pad(c, DOG_T[0], DOG_T[1]);
    this._box(c, DOG_T[0] + 0.18, DOG_T[1] + 0.18, 0.64, 0.64, 19, C.paper2, '#d8c9a3');
    c.save(); c.translate(0, -19);
    this._box(c, DOG_T[0] + 0.06, DOG_T[1] + 0.06, 0.88, 0.88, 8, '#8a6647', '#6b4c33');
    c.restore();
    G.circle(c, p.x, p.y - 13, 6.5, '#2b241b');
    const alert = !!this.sim.pest;
    const bob = alert ? Math.abs(Math.sin(this.t * 12)) * 3 : Math.sin(this.t * 2) * 1.2;
    if (!drawArt(c, 'pests', 'dog', p.x - 26, p.y + 8 - bob, 24, 24))
      G.text(c, '🐕', p.x - 26, p.y - 4 - bob, { size: 24, fill: '#000' });
    if (alert) {
      G.round(c, p.x - 44, p.y - 34, 24, 15, 6, C.red);
      G.text(c, '멍!', p.x - 32, p.y - 26.5, { size: 9.5, fill: '#fff3dd', weight: 800 });
    }
  }

  /* ── 점장 ── */
  _clerk(i) {
    const shop = SHOPS[i];
    if (!this.sim.shops.includes(shop.id)) return null;
    const open = shop.items.filter((it) => this.sim.isOpen(it.id));
    if (!open.length) return null;
    const m = this.mgr[i];
    const full = open.every((it) => this.sim.items[it.id].stock >= this.sim.capOf(it.id));
    const mode = m.at === 'sell' ? 'sell' : m.at === 'walk' ? 'walk' : full ? 'sleep' : 'work';
    return { i, mode, x: m.x, y: m.y, face: m.face };
  }

  _clerkDraw(c, k) {
    const shop = SHOPS[k.i];
    const face = k.face || 1;
    const ph = (this.t / 2.4 + k.i * 0.37) % 1;
    const swing = Math.max(0, Math.sin(ph * Math.PI * 2));
    const bob = k.mode === 'work' ? swing * 3
      : k.mode === 'walk' ? Math.abs(Math.sin(this.t * 10)) * 3
      : k.mode === 'sell' ? Math.sin(this.t * 3) * 1.4 : 0;

    c.fillStyle = 'rgba(0,0,0,.15)';
    c.beginPath(); c.ellipse(k.x, k.y + 2, 10, 4, 0, 0, 7); c.fill();

    if (k.mode === 'work' || k.mode === 'sleep') {
      const ax = k.x - 15;                        // 작업대는 건물 쪽(왼편)
      G.round(c, ax - 6, k.y - 8, 12, 4.5, 2, '#6b6257');
      G.round(c, ax - 2.5, k.y - 4, 5, 5, 1, '#57504a');
      G.round(c, ax - 5, k.y + 1, 10, 2.5, 1, '#4a4139');
      if (k.mode === 'work' && swing > 0.96) for (let j = 0; j < 3; j++) {
        G.circle(c, ax + (j - 1) * 4, k.y - 11 - (j === 1 ? 3 : 0), 1.7, '#f0d98b');
      }
    }
    if (k.mode === 'sell') {
      const px = k.x + face * (CLERK_PX * (60 / 72 - 0.5));
      const py = k.y + 4 - CLERK_PX + CLERK_PX * (38 / 72);
      G.circle(c, px, py - bob, 5.5, '#c9a227');
      G.round(c, px - 2, py - bob - 6.5, 4, 4, 1, C.wood);
    }

    c.save();
    c.translate(k.x, k.y + 4);
    if (face < 0) c.scale(-1, 1);
    if (k.mode === 'walk') c.rotate(Math.sin(this.t * 9) * 0.11);
    const step = Math.sin(this.t * 9) > 0 ? 1 : 2;
    const names = k.mode === 'sell' ? [`${shop.id}-sell`]
      : k.mode === 'sleep' ? [`${shop.id}-sleep`]
      : k.mode === 'walk' ? [`${shop.id}-walk${step}`, `${shop.id}-walk1`, `${shop.id}-idle`, `${shop.id}-work`]
      : [`${shop.id}-work`];
    let drawn = false;
    for (const n of names) if (drawArt(c, 'clerks', n, 0, -bob, CLERK_PX, CLERK_PX)) { drawn = true; break; }
    if (!drawn && !drawArt(c, 'hero', k.mode === 'sell' ? 'raccoon-sell' : 'raccoon-make', 0, -bob, CLERK_PX, CLERK_PX))
      G.text(c, '🦝', 0, -13 - bob, { size: CLERK_PX, fill: '#000' });
    c.restore();

    if (k.mode === 'sleep') {
      const z = (this.t * 0.6) % 1;
      G.text(c, '💤', k.x + 11, k.y - 26 - z * 9, { size: 11 + z * 3, fill: '#000' });
    }
  }

  /** 직원 너구리 — 자리를 안 옮긴다. 자기 작업대만 지킨다. */
  _staff(c, i, k, sp) {
    const shop = SHOPS[i];
    const full = shop.items.filter((it) => this.sim.isOpen(it.id))
      .every((it) => this.sim.items[it.id].stock >= this.sim.capOf(it.id));
    const ph = (this.t / 2.4 + i * 0.37 + (k + 1) * 0.29) % 1;
    const swing = Math.max(0, Math.sin(ph * Math.PI * 2));
    const bob = full ? 0 : swing * 3;

    c.fillStyle = 'rgba(0,0,0,.15)';
    c.beginPath(); c.ellipse(sp.x, sp.y + 2, 9, 4, 0, 0, 7); c.fill();
    const ax = sp.x - 14;
    G.round(c, ax - 6, sp.y - 8, 12, 4.5, 2, '#6b6257');
    G.round(c, ax - 2.5, sp.y - 4, 5, 5, 1, '#57504a');
    if (!full && swing > 0.96) G.circle(c, ax, sp.y - 12, 1.7, '#f0d98b');
    c.save();
    c.translate(sp.x, sp.y + 4);
    const pose = full ? 'sleep' : 'work';
    if (!drawArt(c, 'clerks', `${shop.id}-${pose}`, 0, -bob, 30, 30)
     && !drawArt(c, 'hero', 'raccoon-make', 0, -bob, 30, 30))
      G.text(c, '🦝', 0, -12 - bob, { size: 30, fill: '#000' });
    c.restore();
    if (full) G.text(c, '💤', sp.x + 10, sp.y - 24, { size: 11, fill: '#000' });
  }

  /* ── 손님 ── */
  _walker(c, w) {
    const bob = Math.sin(this.t * 9 * w.speed + w.bob) * (w.state === 'buy' ? 0.8 : 2.4);
    c.fillStyle = 'rgba(0,0,0,.17)';
    c.beginPath(); c.ellipse(w.x, w.y + 8, 11, 4.5, 0, 0, 7); c.fill();
    this._carry(c, w, bob);
    c.save();
    if (w.state !== 'buy') c.translate(0, 0);
    if (!drawArt(c, 'guests', w.id, w.x, w.y + 6 + bob, GUEST_PX, GUEST_PX))
      G.text(c, w.face, w.x, w.y - 8 + bob, { size: GUEST_PX - 4, fill: '#000' });
    c.restore();

    // 단골 갓 — 20성을 네 계단으로 접는다
    if (w.reg > 0) {
      const tier = Math.min(4, Math.ceil(w.reg / 4));
      const y = w.y - 26 + bob, sw = 9 + tier * 2.2;
      const tone = ['', '#8a7a63', '#6d5236', '#3f3327', '#2b241b'][tier];
      G.round(c, w.x - sw, y, sw * 2, 3.5, 2, tone);
      G.round(c, w.x - sw * 0.42, y - 6.5, sw * 0.84, 8, 3, tone);
      if (tier >= 4) G.circle(c, w.x, y - 8.5, 2.4, '#e0c073');
    }
  }

  _carry(c, w, bob) {
    const x = w.x, y = w.y + bob * 0.4;
    if (w.carry === 'hand') return;
    if (w.carry === 'bojjim') {
      G.circle(c, x - 14, y - 13, 9.5, '#c07a56');
      G.round(c, x - 18.5, y - 24, 9, 7, 3, '#9c5c3c');
    } else if (w.carry === 'jige') {
      G.rect(c, x - 20, y - 28, 4, 28, C.wood2);
      G.rect(c, x - 12, y - 28, 4, 28, C.wood2);
      G.round(c, x - 24, y - 38, 22, 14, 4, '#bb8d55');
      G.round(c, x - 21, y - 47, 16, 10, 3, '#a1743f');
    } else {
      G.round(c, x - 34, y - 20, 26, 14, 3, '#a1743f');
      G.circle(c, x - 29, y - 3, 6.5, C.wood2);
      G.circle(c, x - 15, y - 3, 6.5, C.wood2);
      G.round(c, x - 32, y - 30, 22, 11, 3, '#bb8d55');
    }
  }

  _order(c, w) {
    const stop = w.stops[w.si];
    if (!stop || !stop.sold.length) return;
    const n = stop.sold.reduce((a, s) => a + s.n, 0);
    const kinds = stop.sold.length;
    // 아직 만드는 중이면 🔨를 붙인다 — '기다리는 중'이 눈에 보인다
    const txt = (w.settled ? '' : '🔨 ') + (kinds > 1 ? `${n}개 · ${kinds}종` : `${n}개`);
    const tw = 12 + txt.length * 7.2;
    const bx = w.x + 24, by = w.y - 38 + Math.sin(this.t * 3.4) * 1.6;
    G.round(c, bx - tw / 2, by - 11, tw, 19, 7, 'rgba(252,246,232,.96)');
    c.fillStyle = 'rgba(252,246,232,.96)';
    c.beginPath();
    c.moveTo(bx - 16, by + 7); c.lineTo(bx - 22, by + 13); c.lineTo(bx - 10, by + 7);
    c.closePath(); c.fill();
    G.text(c, txt, bx, by - 1, { size: 12.5, fill: C.ink, weight: 800 });
  }

  /* ── 나쁜 놈 ── */
  _pestAt() {
    const t = this.sim.pest;
    if (!t) return null;
    const p = 1 - Math.max(0, t.left) / t.life;

    if (t.kind === 'crow') {
      // 까마귀는 화면 기준으로 가로지른다 — 마을 어디를 보고 있든 눈에 들어온다
      const dir = t.amount % 2 ? 1 : -1;
      const u = p * 2 - 1;
      const e = 0.5 + 0.5 * (u * 0.3 + u * u * u * 0.7);
      const x = dir > 0 ? -40 + e * 560 : 520 - e * 560;
      return {
        kind: 'crow', face: '🐦‍⬛', screen: true,
        x, y: this.viewH * 0.3 + Math.sin(p * Math.PI * 2.4) * 46,
        left: t.left, life: t.life, r: 30, flip: dir < 0,
      };
    }

    const idx = SHOPS.findIndex((sh) => sh.items.some((it) => it.id === t.itemId));
    const f = this._foot(Math.max(0, idx));
    const heart = iso(GW / 2, GH / 2);           // 마을 안쪽으로 달아난다
    return {
      kind: 'rat', face: '🐀', screen: false,
      x: f.stand.x + (heart.x - f.stand.x) * p * 0.5,
      y: f.stand.y + (heart.y - f.stand.y) * p * 0.5,
      left: t.left, life: t.life, r: 32, flip: false,
    };
  }

  _pest(c, t) {
    const fly = t.kind === 'crow';
    const bob = fly ? Math.sin(this.t * 11) * 5 : Math.abs(Math.sin(this.t * 16)) * 4;
    const r = fly ? 27 : 25;
    c.save();
    G.circle(c, t.x, t.y - 6, r - 3, 'rgba(255,246,232,.55)');
    c.lineWidth = 4;
    c.strokeStyle = 'rgba(163,74,58,.28)';
    c.beginPath(); c.arc(t.x, t.y - 6, r, 0, 7); c.stroke();
    c.strokeStyle = '#a34a3a';
    c.beginPath(); c.arc(t.x, t.y - 6, r, -Math.PI / 2, -Math.PI / 2 + 7 * (t.left / t.life)); c.stroke();
    c.restore();
    if (fly) {
      c.fillStyle = 'rgba(0,0,0,.10)';
      c.beginPath(); c.ellipse(t.x, t.y + 34, 13, 4, 0, 0, 7); c.fill();
    } else {
      c.fillStyle = 'rgba(0,0,0,.17)';
      c.beginPath(); c.ellipse(t.x, t.y + 7, 10, 4, 0, 0, 7); c.fill();
      G.circle(c, t.x + 11, t.y - 10 - bob * 0.4, 7, '#a34a3a');
    }
    if (!drawArt(c, 'pests', t.kind, t.x, t.y + 8 - bob, 30, 30))
      G.text(c, t.face, t.x, t.y - 7 - bob, { size: 30, fill: '#000' });
    if (fly) {
      G.circle(c, t.x + 12, t.y + 2 - bob, 5.5, '#c9a227');
      G.rect(c, t.x + 10, t.y - bob, 4, 4, C.wood);
    }
  }

  /* ── 떠 있는 글자들 ── */
  _takings(c, idx) {
    const tk = this.takings[idx];
    const label = `+${fmt(tk.amount)}냥`;
    const bw = 26 + label.length * 8.4;
    /* 마당의 현판이 뒤 꼭짓점 위에 있으니 매상 표도 그 위로 띄운다 */
    const N = iso(SHOP_T[idx][0], SHOP_T[idx][1]);
    const y = N.y - 100 - (1.7 - tk.t) * 11;
    c.globalAlpha = Math.min(1, tk.t / 0.45);
    G.round(c, N.x - bw / 2, y, bw, 25, 9, '#3d3327');
    G.text(c, label, N.x, y + 13, { size: 13.5, fill: '#f2d88c', weight: 800 });
    c.globalAlpha = 1;
  }

  _bubble(c) {
    const b = this.bubble;
    const N = iso(SHOP_T[b.idx][0], SHOP_T[b.idx][1]);
    const lift = this.takings[b.idx] ? 30 : 0;
    const bw = 112, y = N.y - 98 - lift;
    c.globalAlpha = Math.min(1, b.t);
    G.round(c, N.x - bw / 2, y, bw, 28, 9, '#fff6d8');
    c.fillStyle = '#fff6d8';
    c.beginPath();
    c.moveTo(N.x - 6, y + 27); c.lineTo(N.x + 6, y + 27); c.lineTo(N.x, y + 36);
    c.fill();
    G.text(c, `${b.face} ${b.text}`, N.x, y + 14, { size: 13, fill: C.ink, weight: 800 });
    c.globalAlpha = 1;
  }

  _coin(c, co) {
    c.globalAlpha = Math.min(1, co.t * 2.4);
    G.circle(c, co.x, co.y, co.r, '#b8873a');
    G.circle(c, co.x, co.y, co.r * 0.84, '#ecc264');
    c.fillStyle = '#b8873a';
    const q = co.r * 0.3;
    c.fillRect(co.x - q, co.y - q, q * 2, q * 2);
    c.globalAlpha = 1;
  }
}

/** 한 축을 마을 안에 가둔다. 창이 마을보다 크면 가운데 고정. */
function clampAxis(cam, lo, hi, view) {
  if (hi - lo <= view) return (lo + hi) / 2 - view / 2;
  return Math.max(lo, Math.min(hi - view, cam));
}
