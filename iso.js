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
const GW = 10, GH = 14;                // 마을 크기(칸)

/** 칸 좌표 → 세계 좌표. 정수는 칸의 모서리다. */
const iso = (tx, ty) => ({ x: (tx - ty) * TW / 2, y: (tx + ty) * TH / 2 });

/* 길 — 세로 큰길(3~4열) 하나와 가로 골목(4·10행) 둘.
 * 손님은 큰길 양끝에서 들어온다. */
const isRoad = (tx, ty) => (tx === 3 || tx === 4) || ty === 4 || ty === 10;

/* 가게는 2×2칸. content.js의 SHOPS와 같은 순서다.
 *
 * ★ 자리는 (tx−ty)로 정해진다 — 그게 화면의 가로 위치다.
 * 처음에 '왼쪽/오른쪽'을 tx로 갈랐다가 대장간(5,11)과 필방(1,7)이
 * 화면에서 **정확히 같은 세로줄**(둘 다 tx−ty=−6)에 포개졌다.
 * 지금은 세 세로줄(−240 / 0 / +240px)에 번갈아 놓고, 같은 줄 안에서는
 * 세로로 240px 이상 벌린다 — 건물+표 높이가 230px쯤이라 그 밑으론 겹친다. */
const SHOP_T = [
  [6, 11],   // 대장간 — 왼줄, 시작 화면(아래)
  [6, 6],    // 필방 — 가운데줄
  [7, 2],    // 지물포 — 오른줄
  [1, 6],    // 옹기점 — 왼줄
  [1, 1],    // 약재상 — 가운데줄
];
/* 곁가게는 1×1칸. SMALL_SHOPS와 같은 순서(점포·주막·포장마차·점포). */
/* 곁가게 자리 — 가게의 좌판·현판과 안 겹치는 자리에.
 * 점포를 (8,13)에 뒀더니 대장간 좌판 아랫줄을 정통으로 덮었다.
 * 대장간이 세로줄 x=−240을 위아래로 다 쓰므로 그 줄은 통째로 피한다. */
const SMALL_T = [[9, 12], [9, 7], [5, 1], [0, 11]];
const DOG_T = [3, 13];

const WALLH = 52;                     // 건물 벽 높이
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

/** 가게 i의 앞마당(세계 좌표). S는 건물 바닥 마름모의 아래 꼭짓점이다. */
function shopFoot(i) {
  const [tx, ty] = SHOP_T[i];
  const S = iso(tx + 2, ty + 2);
  return {
    S,
    stand: { x: S.x + 30, y: S.y + 24 },    // 손님
    work: { x: S.x - 58, y: S.y + 16 },     // 점장 작업대
    serve: { x: S.x - 14, y: S.y + 26 },    // 점장이 건네러 나오는 자리
  };
}

export class Village {
  constructor(sim, onShopTap) {
    this.sim = sim;
    this.onShopTap = onShopTap;
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
    this.mgr = SHOPS.map((_, i) => ({ ...shopFoot(i).work, at: 'work', face: 1 }));

    /* 카메라 — 이제 2차원이다. 가로로도 민다. */
    this.viewW = VW; this.viewH = 800;
    const s0 = shopFoot(0).S;
    this.cam = { x: s0.x - VW / 2, y: s0.y - 800 * 0.62 };
    this.vel = { x: 0, y: 0 };
    this.drag = null;

    this.trees = this._trees();
  }

  /* 나무 — 빈 풀칸에 심는다. 매 프레임 난수를 쓰면 떨리므로 한 번만. */
  _trees() {
    let s = 20250819;
    const rng = () => (s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    const used = new Set();
    for (const [tx, ty] of SHOP_T) for (let a = 0; a < 2; a++) for (let b = 0; b < 2; b++) used.add(`${tx + a},${ty + b}`);
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
    if (this.walkers.length > 14) return;
    const byShop = new Map();
    for (const ln of sale.lines) {
      const idx = SHOPS.findIndex((s) => s.id === ln.item.shop);
      if (idx < 0) continue;
      if (!byShop.has(idx)) byShop.set(idx, { idx, sold: [], gain: 0 });
      const g = byShop.get(idx);
      g.sold.push({ id: ln.item.id, n: ln.n });
      g.gain += ln.gain;
      this.pending[ln.item.id] = (this.pending[ln.item.id] || 0) + ln.n;
    }
    const stops = [...byShop.values()];
    if (!stops.length) return;

    /* 큰길 양끝 중 첫 가게에 가까운 쪽에서 들어와, 가게들을 훑고
     * 반대쪽으로 나간다. */
    const gate = (top) => iso(4, top ? -1.6 : GH + 1.6);
    const avgY = stops.reduce((a, x) => a + shopFoot(x.idx).S.y, 0) / stops.length;
    const fromTop = Math.abs(gate(true).y - avgY) < Math.abs(gate(false).y - avgY);
    stops.sort((a, b) => fromTop
      ? shopFoot(a.idx).S.y - shopFoot(b.idx).S.y
      : shopFoot(b.idx).S.y - shopFoot(a.idx).S.y);
    const g0 = gate(fromTop);
    this.walkers.push({
      id: sale.guest.id, face: sale.guest.face,
      reg: this.sim.regularLv(sale.guest.id),
      speed: sale.guest.speed || 1,
      carry: carryOf(sale.guest.qty),
      stops, si: 0,
      x: g0.x + (Math.random() - 0.5) * 40, y: g0.y,
      exitGate: gate(!fromTop),
      state: 'in', wait: 0, paid: false, bob: Math.random() * 6,
      lane: (Math.random() - 0.5) * 34,
    });
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
        const f = shopFoot(stop.idx);
        const tgt = { x: f.stand.x + w.lane * 0.4, y: f.stand.y };
        const dx = tgt.x - w.x, dy = tgt.y - w.y;
        const d = Math.hypot(dx, dy);
        if (d > 2) {
          const step = Math.min(d, WALK * 1.3 * w.speed * dt);
          w.x += dx / d * step; w.y += dy / d * step;
        }
        if (d < 4) {
          w.state = 'buy'; w.wait = BUY_TIME; w.paid = false;
          this.busyShop[stop.idx] = BUY_TIME + 1.2;
        }
      } else if (w.state === 'buy') {
        w.wait -= dt;
        if (!w.paid && w.wait <= BUY_TIME - HAND_OVER) {
          w.paid = true;
          for (const s of stop.sold) {
            this.pending[s.id] = Math.max(0, (this.pending[s.id] || 0) - s.n);
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

    // 점장 — 방금 판 가게에선 나가서 건네고, 아니면 작업대로
    for (let i = 0; i < SHOPS.length; i++) {
      const m = this.mgr[i];
      const f = shopFoot(i);
      const serving = (this.busyShop[i] || 0) > 0;
      const t = serving ? f.serve : f.work;
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
      y0: iso(0, 0).y - 60, y1: iso(GW, GH).y + 90,
    };
  }

  camMax() { const b = this._bounds(); return Math.max(0, b.y1 - b.y0 - this.viewH); }

  /** 이 가게가 지금 화면 어디에 있나 — 들어갈 때 확대의 중심 */
  shopScreenPos(i) {
    const S = shopFoot(i).S;
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

    // 가게 — 건물 전체가 단추다
    for (let i = 0; i < SHOPS.length; i++) {
      const S = shopFoot(i).S;
      if (Math.abs(wx - S.x) < TW && wy > S.y - TH * 2 - WALLH - 40 && wy < S.y + 30) {
        this.onShopTap(SHOPS[i].id, this.sim.shops.includes(SHOPS[i].id));
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
      const S = shopFoot(i).S;
      if (vis(S, TW * 2)) layer.push({ z: S.y, d: () => this._shop(c, i) });
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
    for (const w of this.walkers) if (w.state === 'buy' && !w.paid && vis(w, 80)) this._order(c, w);
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

  _shop(c, i) {
    const shop = SHOPS[i];
    const [tx, ty] = SHOP_T[i];
    const open = this.sim.shops.includes(shop.id);
    const S = iso(tx + 2, ty + 2);

    if (!open) {
      // 폐허 — 점선 마름모와 부러진 기둥
      const N = iso(tx, ty), E = iso(tx + 2, ty), W2 = iso(tx, ty + 2);
      c.save();
      c.setLineDash([8, 7]); c.lineWidth = 2; c.strokeStyle = 'rgba(50,44,30,.45)';
      c.beginPath(); c.moveTo(N.x, N.y); c.lineTo(E.x, E.y); c.lineTo(S.x, S.y); c.lineTo(W2.x, W2.y);
      c.closePath(); c.stroke(); c.restore();
      for (let k = 0; k < 3; k++) {
        G.round(c, S.x - 34 + k * 28, S.y - TH - 20 + (k % 2) * 6, 8, 22 - k * 5, 3, '#6a6a55');
      }
      const next = this.sim.nextShop();
      const isNext = next && next.id === shop.id;
      G.text(c, isNext ? shop.name : '무너진 집', S.x, S.y - TH - 34,
        { size: 14, fill: isNext ? '#f0ead6' : C.ruin, weight: 800 });
      if (isNext) {
        const can = this.sim.money >= shop.cost;
        G.round(c, S.x - 50, S.y - TH - 22, 100, 25, 9, can ? C.jade : '#77775f');
        G.text(c, `${fmt(shop.cost)}냥`, S.x, S.y - TH - 9.5, { size: 12.5, fill: '#fff', weight: 800 });
      }
      return;
    }

    // 그림자
    c.fillStyle = 'rgba(0,0,0,.14)';
    c.beginPath(); c.ellipse(S.x, S.y + 6, TW * 0.95, TH * 0.4, 0, 0, 7); c.fill();

    // 몸채 + 지붕
    const box = this._box(c, tx, ty, 2, 2, WALLH, C.paper, shop.color);
    const RN = iso(tx + 1, ty + 1);
    c.beginPath();
    c.moveTo(RN.x, RN.y - TH * 2 - WALLH - 34);
    c.lineTo(box.E.x + 7, box.E.y - WALLH - 3);
    c.lineTo(S.x, S.y - WALLH + 5);
    c.lineTo(box.W.x - 7, box.W.y - WALLH - 3);
    c.closePath(); c.fillStyle = C.tile; c.fill();

    /* 세로 배치 — 아래에서 위로 쌓는다:
     *   좌판(바닥 위) → 현판(좌판 바로 위) → 표(현판 위)
     * 처음엔 현판을 벽 높이에 고정했더니 좌판 두 줄이 그 위를 덮었다.
     * 좌판 높이에 따라 현판이 밀려 올라가야 한다. */
    const items = shop.items.filter((it) => this.sim.isOpen(it.id));
    const cols = Math.min(2, items.length);
    const rows2 = Math.ceil(Math.max(1, items.length) / Math.max(1, cols));
    const chipH = rows2 * 52 + (rows2 - 1) * 5;
    const chipTop = S.y - 8 - chipH;

    const rk = this.sim.rankOf(shop.id);
    const sTxt = rk > 0 ? `${shop.sign} ${shop.name} · ${shop.ranks[rk]}` : `${shop.sign} ${shop.name}`;
    const sw = 30 + sTxt.length * 12.5;
    const signY = chipTop - 34;
    G.round(c, S.x - sw / 2, signY, sw, 26, 8, shop.color);
    G.text(c, sTxt, S.x, signY + 13, { size: 14, fill: '#fff8ec', weight: 800 });

    if (cols > 0) {
      const bw = 68, bh = 52, gap = 5;
      const rows = rows2;
      const y0 = chipTop;
      for (let k = 0; k < items.length; k++) {
        const it = items[k];
        const r = Math.floor(k / cols), ci = k % cols;
        const inRow = Math.min(cols, items.length - r * cols);
        const rowW = inRow * bw + (inRow - 1) * gap;
        const bx = S.x - rowW / 2 + ci * (bw + gap);
        const by = y0 + r * (bh + gap);
        const fl = this.flash[it.id] || 0;
        G.round(c, bx, by, bw, bh, 7, fl > 0 ? '#f7ecc9' : 'rgba(252,246,232,.95)');
        const st = this.sim.items[it.id];
        const shown = Math.min(STOCK_CAP, st.stock + (this.pending[it.id] || 0));
        const nm = itemById(it.id).name;
        drawArt(c, 'items', it.id, bx + 14, by + bh - 4, 22, 36);
        G.text(c, nm, bx + bw / 2, by + 10,
          { size: Math.min(12, (bw - 8) / Math.max(2, nm.length)), fill: C.ink2, weight: 800 });
        // 진행 고리 + 재고
        const cxk = bx + bw / 2, cyk = by + 33, rr = 13.5;
        const capped = shown >= STOCK_CAP;
        const p = capped ? 1 : Math.max(0, Math.min(1, st.prog / this.sim.craftTime(it.id)));
        c.save();
        c.lineWidth = 3; c.lineCap = 'round';
        c.strokeStyle = 'rgba(43,36,27,.30)';
        c.beginPath(); c.arc(cxk, cyk, rr, 0, Math.PI * 2); c.stroke();
        if (p > 0.01) {
          c.strokeStyle = capped ? '#ff8a63' : '#e8b93f';
          c.beginPath(); c.arc(cxk, cyk, rr, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke();
        }
        c.restore();
        G.text(c, String(shown), cxk, cyk, { size: fl > 0 ? 16 : 14.5, fill: C.ink, weight: 800 });
      }
    }

    // 잠긴 칸 안내
    const locked = shop.items.filter((it) => !this.sim.isOpen(it.id));
    if (locked.length) {
      const askedNext = locked.find((it) => this.sim.asked.includes(it.id));
      G.text(c, askedNext ? `${itemById(askedNext.id).name} 칸 열 수 있음` : `${locked.length}칸 더 있다`,
        S.x, S.y + 20, { size: 11.5, fill: askedNext ? '#8a6a2c' : 'rgba(43,36,27,.55)', weight: 800 });
    }

    /* 들어가서 좋은 일이 있을 때만 표를 띄운다 — 숙제가 아니라 초대장.
     * 강화는 안 센다. 늘 할 수 있는 건 표가 항상 켜져 있게 되고,
     * 항상 켜진 표는 없는 것과 같다. 그리고 이건 사라지지 않는다. */
    const todo = this.sim.shopTodo(shop.id);
    if (todo > 0) {
      const bob = Math.sin(this.t * 4) * 3;
      const promo = this.sim.canPromote(shop.id);
      const txt = promo ? '승급!' : '새 칸!';
      const tw = 26 + txt.length * 13;
      G.round(c, S.x - tw / 2, signY - 34 + bob, tw, 25, 9, promo ? C.red : C.jade);
      G.text(c, txt, S.x, signY - 21.5 + bob, { size: 14, fill: '#fff3dd', weight: 800 });
    }
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

    c.fillStyle = 'rgba(0,0,0,.13)';
    c.beginPath(); c.ellipse(p.x, p.y + 3, TW * 0.42, TH * 0.32, 0, 0, 7); c.fill();
    this._box(c, tx + 0.08, ty + 0.08, 0.84, 0.84, 30, '#e6dcc4', C.wood);
    G.round(c, p.x - 34, p.y - 62, 68, 19, 6, 'rgba(43,36,27,.8)');
    G.text(c, def.name, p.x, p.y - 52.5, { size: 11, fill: '#fff8ec', weight: 800 });

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
    // 개집
    this._box(c, DOG_T[0] + 0.15, DOG_T[1] + 0.15, 0.7, 0.7, 24, C.paper2, C.wood2);
    G.circle(c, p.x, p.y - 22, 9, '#2b241b');
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
    const full = open.every((it) => this.sim.items[it.id].stock >= STOCK_CAP);
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
    if (!stop) return;
    const n = stop.sold.reduce((a, s) => a + s.n, 0);
    const kinds = stop.sold.length;
    const txt = kinds > 1 ? `${n}개 · ${kinds}종` : `${n}개`;
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
    const f = shopFoot(Math.max(0, idx));
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
    const S = shopFoot(idx).S;
    const label = `+${fmt(tk.amount)}냥`;
    const bw = 26 + label.length * 8.4;
    const y = S.y - WALLH - TH * 2 - 52 - (1.7 - tk.t) * 11;
    c.globalAlpha = Math.min(1, tk.t / 0.45);
    G.round(c, S.x - bw / 2, y, bw, 25, 9, '#3d3327');
    G.text(c, label, S.x, y + 13, { size: 13.5, fill: '#f2d88c', weight: 800 });
    c.globalAlpha = 1;
  }

  _bubble(c) {
    const b = this.bubble;
    const S = shopFoot(b.idx).S;
    const lift = this.takings[b.idx] ? 30 : 0;
    const bw = 112, y = S.y - WALLH - TH * 2 - 50 - lift;
    c.globalAlpha = Math.min(1, b.t);
    G.round(c, S.x - bw / 2, y, bw, 28, 9, '#fff6d8');
    c.fillStyle = '#fff6d8';
    c.beginPath();
    c.moveTo(S.x - 6, y + 27); c.lineTo(S.x + 6, y + 27); c.lineTo(S.x, y + 36);
    c.fill();
    G.text(c, `${b.face} ${b.text}`, S.x, y + 14, { size: 13, fill: C.ink, weight: 800 });
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
