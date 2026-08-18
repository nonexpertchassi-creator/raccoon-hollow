/* scene.js — 마을을 위에서 내려다본 한 폭. 그리기만 한다.
 *
 * 여기엔 경제 계산이 한 줄도 없다. sim.js를 읽기만 하고 절대 고치지 않는다.
 *
 * 처음 판은 "지도"처럼 보였다. 원인이 네 가지였다:
 *   길이 자로 잰 듯 화면 정중앙을 세로로 관통
 *   가게가 좌·우·좌·우 정확히 번갈아, 간격도 일정
 *   가게가 평평한 네모라 건물이 아니라 UI 패널로 읽힘
 *   앞뒤로 겹치는 게 없어 깊이가 없음
 *
 * 그래서 길을 구불리고, 가게를 기와지붕 얹은 건물로 그리고, 나무·장독·초롱을
 * 깔고, 모든 것을 발끝 높이(y) 순으로 그려 앞뒤가 겹치게 했다.
 */

import { G } from './core/engine.js';
import { Juice, Sfx } from './core/juice.js';
import { SHOPS, STOCK_CAP } from './content.js';
import { fmt } from './sim.js';

const W = 480, H = 800;
const ROAD_W = 74;

/** 구불구불한 길. 이 한 줄이 "지도 느낌"의 가장 큰 원인을 없앤다. */
const roadX = (y) => 240 + 24 * Math.sin(y / 175 + 0.6);

/* 가게 자리.
 * 좌우 번갈이를 일부러 깼다 — 지물포와 옹기점은 둘 다 왼쪽에 선다.
 * 폭도 제각각인데, 길이 오른쪽으로 휜 구간에서는 왼쪽에 자리가 더 남기
 * 때문이다. 길에 맞춰 자리를 잡으니 배치가 저절로 불규칙해진다. */
const SLOTS = [
  { x: 14,  y: 650, w: 162, h: 132, side: -1 },  // 대장간
  { x: 280, y: 488, w: 186, h: 126, side: 1 },   // 필방
  { x: 14,  y: 342, w: 178, h: 126, side: -1 },  // 지물포
  { x: 16,  y: 158, w: 196, h: 126, side: -1 },  // 옹기점
  { x: 304, y: 14,  w: 164, h: 126, side: 1 },   // 약재상
];

const C = {
  grass:  '#8b9e74',
  grass2: '#7e9268',
  road:   '#d9cba9',
  edge:   '#bfae8a',
  paper:  '#ece2cb',
  paper2: '#dccfb2',
  wood:   '#8a6a45',
  wood2:  '#6d5236',
  tile:   '#4a4139',
  tile2:  '#5d5249',
  ink:    '#2b241b',
  ink2:   '#5a4e3d',
  ink3:   '#8a7a63',
  gold:   '#a8763e',
  jade:   '#4a7c59',
  ruin:   '#6f7d5e',
};

function slotOf(i) {
  const s = SLOTS[i];
  return {
    ...s,
    cx: s.x + s.w / 2,
    cy: s.y + s.h / 2,
    /* 손님이 서는 자리 = 가게 앞.
     * 길 가장자리에 세웠더니 어느 가게에 왔는지 티가 안 났다("필방엔 손님이
     * 안 온다" — 실제로는 30%가 가고 있었다). 이제 발치까지 들어온다. */
    standX: s.x + s.w * (s.side < 0 ? 0.74 : 0.26),
    standY: s.y + s.h + 10,
  };
}

export class Village {
  constructor(sim, onShopTap) {
    this.sim = sim;
    this.onShopTap = onShopTap;
    this.walkers = [];
    /* 튀어오르는 엽전. 예전엔 "+6,927" 같은 글자를 띄웠는데 손님이 몰리면
     * 글자끼리 겹쳐 읽을 수가 없었다. 금액은 가게 위 카운터가 맡고,
     * 여기서는 "팔렸다"만 알린다. 조선 동전은 가운데가 네모로 뚫려 있다. */
    this.coins = [];
    /* 가게별 매상 카운터. 가게마다 자리를 하나 정해두면 손님이 여럿 와도
     * 금액이 그 자리에서 합쳐질 뿐 겹치지 않는다. */
    this.takings = {};
    /* 아직 손님이 도착하지 않은 판매량.
     * sim은 사는 순간 재고를 깎지만 화면에선 손님이 걸어오는 시간이 있다.
     * 그대로 두면 아무도 없는 가게에서 물건이 먼저 사라진다. 그릴 때만
     * 도로 더해 두었다가 손님이 닿는 순간 뺀다. 계산은 안 건드린다. */
    this.pending = {};
    this.flash = {};
    this.bubble = null;
    this.t = 0;
    this.tufts = this._scatter();
    this.props = this._props();
  }

  /* ── 배경 무늬·소품은 한 번만 정한다. 매 프레임 난수를 쓰면 떨린다. ── */
  _rng(seed) {
    let s = seed;
    return () => (s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
  }

  _scatter() {
    const rnd = this._rng(7), out = [];
    for (let i = 0; i < 130; i++) {
      const x = rnd() * W, y = rnd() * H;
      if (Math.abs(x - roadX(y)) < ROAD_W / 2 + 6) continue;
      out.push({ x, y, r: 2 + rnd() * 3.2 });
    }
    return out;
  }

  /** 빈 풀밭이 지도 여백처럼 보였다. 나무·장독·초롱·바위를 깔아 마을로 만든다. */
  _props() {
    const rnd = this._rng(20250818), out = [];
    const kinds = ['tree', 'tree', 'tree', 'jars', 'lantern', 'rock', 'flower', 'flower'];
    let guard = 0;
    while (out.length < 26 && guard++ < 900) {
      const x = 14 + rnd() * (W - 28), y = 30 + rnd() * (H - 40);
      if (Math.abs(x - roadX(y)) < ROAD_W / 2 + 20) continue;      // 길 위엔 안 놓는다
      if (SLOTS.some((s) => x > s.x - 22 && x < s.x + s.w + 22 &&
                            y > s.y - 46 && y < s.y + s.h + 26)) continue;  // 가게 자리도 비운다
      if (out.some((p) => Math.hypot(p.x - x, p.y - y) < 46)) continue;     // 서로 안 겹치게
      out.push({ x, y, k: kinds[(rnd() * kinds.length) | 0], r: 13 + rnd() * 9, f: rnd() });
    }
    return out;
  }

  /* ── 바깥에서 알려주는 사건 ── */

  onSale(sale) {
    if (this.walkers.length > 9) return;   // 못 띄우면 재고도 붙잡지 않는다
    const idx = SHOPS.findIndex((s) => s.id === sale.lines[0].item.shop);
    if (idx < 0) return;
    for (const ln of sale.lines) {
      this.pending[ln.item.id] = (this.pending[ln.item.id] || 0) + ln.n;
    }
    const fromTop = SLOTS[idx].y < H / 2;
    const y = fromTop ? -30 : H + 30;
    this.walkers.push({
      face: sale.guest.face, idx, gain: sale.gain,
      sold: sale.lines.map((ln) => ({ id: ln.item.id, n: ln.n })),
      lane: (Math.random() - 0.5) * (ROAD_W - 34),
      x: roadX(y), y,
      exit: fromTop ? -1 : 1,
      state: 'in', wait: 0, bob: Math.random() * 6,
    });
  }

  onAsk(ask) {
    const idx = SHOPS.findIndex((s) => s.id === ask.item.shop);
    if (idx < 0) return;
    this.bubble = { idx, text: `${ask.item.name}?`, t: 4.5, face: ask.guest.face };
  }

  /* ── 매 프레임 ── */
  update(dt, pointer) {
    this.t += dt;
    if (this.bubble) { this.bubble.t -= dt; if (this.bubble.t <= 0) this.bubble = null; }

    for (const w of this.walkers) {
      const sl = slotOf(w.idx);
      if (w.state === 'in') {
        const dy = sl.standY - w.y;
        w.y += Math.sign(dy) * Math.min(Math.abs(dy), 155 * dt);
        // 멀리 있을 땐 구부러진 길을 따라가고, 가까워지면 가게 앞으로 꺾는다
        const tx = Math.abs(dy) < 130 ? sl.standX : roadX(w.y) + w.lane;
        const dx = tx - w.x;
        w.x += Math.sign(dx) * Math.min(Math.abs(dx), 175 * dt);
        if (Math.abs(dy) < 3 && Math.abs(sl.standX - w.x) < 3) {
          w.state = 'buy'; w.wait = 0.75;
          for (const s of w.sold) {                 // 도착한 지금이 재고가 빠지는 순간
            this.pending[s.id] = Math.max(0, (this.pending[s.id] || 0) - s.n);
            this.flash[s.id] = 0.45;
          }
          for (let k = 0; k < Math.min(5, w.sold.length); k++) {
            this.coins.push({
              x: w.x + (Math.random() - 0.5) * 14, y: w.y - 18,
              vx: (Math.random() - 0.5) * 46, vy: -92 - Math.random() * 46,
              t: 1.05, r: 8.5 + Math.random() * 2.5,
            });
          }
          const tk = (this.takings[w.idx] ||= { amount: 0, t: 0 });
          tk.amount += w.gain; tk.t = 1.7;
          Juice.burst(w.x, w.y - 14, { n: 4, color: ['#f0d98b'], size: 2, speed: 52, life: 0.34 });
          Sfx.coin();
        }
      } else if (w.state === 'buy') {
        w.wait -= dt;
        if (w.wait <= 0) w.state = 'out';
      } else {
        w.y += 150 * dt * w.exit;
        const back = roadX(w.y) + w.lane - w.x;
        w.x += Math.sign(back) * Math.min(Math.abs(back), 120 * dt);
      }
    }
    this.walkers = this.walkers.filter((w) => w.y > -90 && w.y < H + 90);

    for (const id of Object.keys(this.flash)) {
      this.flash[id] -= dt;
      if (this.flash[id] <= 0) delete this.flash[id];
    }
    for (const co of this.coins) {
      co.t -= dt; co.x += co.vx * dt; co.y += co.vy * dt; co.vy += 165 * dt;
    }
    this.coins = this.coins.filter((co) => co.t > 0);
    for (const k of Object.keys(this.takings)) {
      this.takings[k].t -= dt;
      if (this.takings[k].t <= 0) delete this.takings[k];
    }

    if (pointer.justDown) {
      for (let i = 0; i < SHOPS.length; i++) {
        const s = SLOTS[i];
        if (pointer.x > s.x && pointer.x < s.x + s.w &&
            pointer.y > s.y && pointer.y < s.y + s.h) {
          this.onShopTap(SHOPS[i].id, this.sim.shops.includes(SHOPS[i].id));
          return;
        }
      }
    }
  }

  /* ── 그리기 ──
   * 건물·소품·손님을 한 줄로 세워 발끝 높이 순으로 그린다. 앞에 있는 것이
   * 뒤를 가려야 평면이 아니라 공간으로 보인다. */
  draw(c) {
    this._ground(c);

    const layer = [];
    for (let i = 0; i < SHOPS.length; i++) {
      layer.push({ z: SLOTS[i].y + SLOTS[i].h, d: () => this._shop(c, i) });
    }
    for (const p of this.props) layer.push({ z: p.y, d: () => this._prop(c, p) });
    for (const w of this.walkers) layer.push({ z: w.y, d: () => this._walker(c, w) });
    layer.sort((a, b) => a.z - b.z);
    for (const l of layer) l.d();

    for (const k of Object.keys(this.takings)) this._takings(c, Number(k));
    if (this.bubble) this._bubble(c);
    for (const co of this.coins) this._coin(c, co);
  }

  _ground(c) {
    G.rect(c, 0, 0, W, H, C.grass);
    for (const t of this.tufts) G.circle(c, t.x, t.y, t.r, C.grass2);

    // 구부러진 길 — 가로줄을 촘촘히 쌓아 곡선을 만든다
    for (let y = 0; y < H; y += 2) {
      const rx = roadX(y);
      G.rect(c, rx - ROAD_W / 2, y, ROAD_W, 2.4, C.road);
      G.rect(c, rx - ROAD_W / 2, y, 3, 2.4, C.edge);
      G.rect(c, rx + ROAD_W / 2 - 3, y, 3, 2.4, C.edge);
    }
    // 디딤돌. 좌우로 어긋나게 놓아야 사다리처럼 안 보인다.
    for (let i = 0, y = 46; y < H; y += 98, i++) {
      G.round(c, roadX(y) + (i % 2 ? 13 : -13) - 13, y, 26, 13, 6, C.edge);
    }
  }

  /* ── 소품 ── */
  _prop(c, p) {
    const { x, y, r } = p;
    if (p.k === 'tree') {
      G.circle(c, x, y + 2, r * 0.52, 'rgba(0,0,0,.14)');
      G.rect(c, x - 3, y - r * 0.85, 6, r * 0.85, C.wood2);
      G.circle(c, x, y - r * 1.3, r, '#65825a');
      G.circle(c, x - r * 0.32, y - r * 1.58, r * 0.66, '#77956a');
      G.circle(c, x + r * 0.36, y - r * 1.42, r * 0.5, '#7fa070');
    } else if (p.k === 'jars') {
      // 장독대 — 항아리 셋
      for (let k = 0; k < 3; k++) {
        const jx = x + (k - 1) * 15, jr = k === 1 ? 11 : 8.5;
        G.circle(c, jx, y + 2, jr * 0.75, 'rgba(0,0,0,.14)');
        G.circle(c, jx, y - jr * 0.7, jr, '#5f4433');
        G.round(c, jx - jr * 0.62, y - jr * 1.5, jr * 1.24, 5, 2, '#4b3527');
      }
    } else if (p.k === 'lantern') {
      // 초롱 — 기둥에 걸린 등
      G.circle(c, x, y + 2, 6, 'rgba(0,0,0,.14)');
      G.rect(c, x - 2.5, y - 34, 5, 34, C.wood2);
      G.round(c, x - 9, y - 48, 18, 17, 6, '#d9534a');
      G.round(c, x - 9, y - 50, 18, 4, 2, C.wood2);
      G.glow(c, x, y - 40, 17, 'rgba(255,214,138,.28)');
    } else if (p.k === 'rock') {
      G.circle(c, x, y + 1, r * 0.42, 'rgba(0,0,0,.12)');
      G.round(c, x - r * 0.44, y - r * 0.5, r * 0.88, r * 0.55, 6, '#8d8b7e');
    } else {
      // 들꽃
      for (let k = 0; k < 5; k++) {
        const a = p.f * 6.28 + k * 1.26;
        G.circle(c, x + Math.cos(a) * 11, y + Math.sin(a) * 7, 3, k % 2 ? '#e8d6a0' : '#d98fa0');
      }
    }
  }

  /* ── 가게 ── */

  /** 기와지붕. 양 끝이 치켜올라가고 가운데가 처지는 게 한옥 지붕의 앞모습이다. */
  _roof(c, x, y, w) {
    const l = x - 10, r = x + w + 10;
    c.fillStyle = C.tile;
    c.beginPath();
    c.moveTo(l, y + 6);
    c.quadraticCurveTo(x + w / 2, y + 21, r, y + 6);
    c.lineTo(r, y + 34);
    c.quadraticCurveTo(x + w / 2, y + 49, l, y + 34);
    c.closePath(); c.fill();
    // 용마루
    c.strokeStyle = C.tile2; c.lineWidth = 4;
    c.beginPath();
    c.moveTo(l, y + 7); c.quadraticCurveTo(x + w / 2, y + 22, r, y + 7);
    c.stroke();
    // 기왓골
    c.strokeStyle = 'rgba(255,255,255,.09)'; c.lineWidth = 1.4;
    for (let k = 1; k < 8; k++) {
      const px = x - 6 + ((w + 12) * k) / 8;
      const t = (px - l) / (r - l);
      const top = y + 6 + 30 * t * (1 - t) * 2;
      c.beginPath(); c.moveTo(px, top + 3); c.lineTo(px, top + 26); c.stroke();
    }
  }

  _shop(c, i) {
    const shop = SHOPS[i], sl = slotOf(i), open = this.sim.shops.includes(shop.id);
    const { x, y, w, h } = sl;

    if (!open) {
      // 무너진 집 — 주춧돌만 남고 서까래가 부러져 있다
      G.circle(c, sl.cx, y + h - 4, 6, 'rgba(0,0,0,.10)');
      c.save();
      c.setLineDash([8, 7]); c.lineWidth = 2; c.strokeStyle = C.ruin;
      c.beginPath(); c.roundRect(x + 6, y + 18, w - 12, h - 30, 10); c.stroke();
      c.restore();
      for (let k = 0; k < 3; k++) {                   // 부러진 기둥
        G.round(c, x + 22 + k * (w - 60) / 2, y + h - 42, 8, 26 - k * 7, 3, '#6a6a55');
      }
      const next = this.sim.nextShop();
      const isNext = next && next.id === shop.id;
      G.text(c, isNext ? shop.name : '무너진 집', sl.cx, y + 46,
        { size: 13, fill: isNext ? '#f0ead6' : C.ruin, weight: 800 });
      if (isNext) {
        G.round(c, sl.cx - 48, y + 60, 96, 24, 9,
          this.sim.money >= shop.cost ? C.jade : '#77775f');
        G.text(c, `${fmt(shop.cost)}냥`, sl.cx, y + 72, { size: 12, fill: '#fff', weight: 800 });
      }
      return;
    }

    // 땅에 드리운 그림자
    c.fillStyle = 'rgba(0,0,0,.15)';
    c.beginPath(); c.ellipse(sl.cx, y + h + 2, w * 0.46, 11, 0, 0, 7); c.fill();

    // 몸채 — 흙벽에 나무 기둥
    G.round(c, x + 6, y + 30, w - 12, h - 30, 5, C.paper);
    G.rect(c, x + 6, y + h - 12, w - 12, 12, C.wood2);          // 툇마루
    G.rect(c, x + 6, y + 34, 9, h - 46, C.wood);                // 기둥
    G.rect(c, x + w - 15, y + 34, 9, h - 46, C.wood);

    this._roof(c, x, y, w);

    // 간판 — 처마에 걸린 현판
    const sw = Math.min(w - 34, 118);
    G.round(c, sl.cx - sw / 2, y + 30, sw, 25, 6, shop.color);
    G.round(c, sl.cx - sw / 2, y + 30, sw, 4, 2, 'rgba(0,0,0,.18)');
    G.text(c, `${shop.sign} ${shop.name}`, sl.cx, y + 43, { size: 13.5, fill: '#fff8ec', weight: 800 });

    // 좌판 — 열린 품목마다 한 칸. 재고가 차오르는 게 눈에 보여야 한다.
    const items = shop.items.filter((it) => this.sim.isOpen(it.id));
    const per = Math.min(4, items.length);
    // 대장간은 폭이 제일 좁은데 물건은 4개라 칸이 빠듯하다. 여백을 줄여 벌어준다.
    const inner = w - 26;
    for (let k = 0; k < per; k++) {
      const it = items[k];
      const bw = inner / per - 4;
      const bx = x + 13 + k * (bw + 4);
      const by = y + 62;
      const fl = this.flash[it.id] || 0;
      G.round(c, bx, by, bw, h - 80, 6, fl > 0 ? '#f2e5b6' : C.paper2);
      const st = this.sim.items[it.id];
      // 걸어오는 중인 몫을 도로 더한다 — 손님이 닿아야 숫자가 떨어진다
      const shown = Math.min(STOCK_CAP, st.stock + (this.pending[it.id] || 0));
      const bh = Math.round((h - 84) * Math.min(1, shown / STOCK_CAP));
      if (bh > 0) G.round(c, bx + 2, by + (h - 82) - bh, bw - 4, bh, 4, shop.color);
      G.text(c, it.name, bx + bw / 2, by + 11, { size: 9.5, fill: C.ink2, weight: 800 });
      G.text(c, String(shown), bx + bw / 2, by + 30,
        { size: fl > 0 ? 15 : 13, fill: C.ink, weight: 800 });
    }

    // 잠긴 칸 — 다음에 뭘 열지가 여기서 보인다
    const locked = shop.items.filter((it) => !this.sim.isOpen(it.id));
    if (locked.length) {
      const askedNext = locked.find((it) => this.sim.asked.includes(it.id));
      G.text(c, askedNext ? `${askedNext.name} 칸 열 수 있음` : `${locked.length}칸 더 있다`,
        sl.cx, y + h - 5, { size: 10.5, fill: askedNext ? '#ffe9a8' : '#d8ccb0', weight: 800 });
    }
  }

  _walker(c, w) {
    const bob = Math.sin(this.t * 9 + w.bob) * (w.state === 'buy' ? 0.8 : 2.4);
    c.fillStyle = 'rgba(0,0,0,.17)';
    c.beginPath(); c.ellipse(w.x, w.y + 8, 11, 4.5, 0, 0, 7); c.fill();
    G.text(c, w.face, w.x, w.y - 8 + bob, { size: 27, fill: '#000' });
  }

  /* ── 가게 위에 뜨는 것들 ── */

  /** 띄울 자리. 맨 위 가게는 위쪽이 화면 밖이라 아래에 단다. */
  _perch(sl, h) {
    return sl.y - h - 10 >= 4 ? sl.y - h - 10 : sl.y + sl.h - 2;
  }

  _takings(c, idx) {
    const tk = this.takings[idx], sl = slotOf(idx);
    const label = `+${fmt(tk.amount)}냥`;
    const bw = 26 + label.length * 8.4;
    const y = this._perch(sl, 26) - (1.7 - tk.t) * 11;
    c.globalAlpha = Math.min(1, tk.t / 0.45);
    G.round(c, sl.cx - bw / 2, y, bw, 25, 9, '#3d3327');
    G.text(c, label, sl.cx, y + 13, { size: 13.5, fill: '#f2d88c', weight: 800 });
    c.globalAlpha = 1;
  }

  _bubble(c) {
    const b = this.bubble, sl = slotOf(b.idx);
    // 아래에 달릴 때는 꼬리도 위를 향해야 어느 가게를 가리키는지 맞는다
    const below = sl.y - 28 - 10 < 4;
    const lift = this.takings[b.idx] ? 32 : 0;
    const bw = 112, x = sl.cx - bw / 2;
    const y = below ? this._perch(sl, 28) + lift : this._perch(sl, 28) - lift;
    c.globalAlpha = Math.min(1, b.t);
    G.round(c, x, y, bw, 28, 9, '#fff6d8');
    c.fillStyle = '#fff6d8';
    c.beginPath();
    if (below) { c.moveTo(sl.cx - 6, y + 1); c.lineTo(sl.cx + 6, y + 1); c.lineTo(sl.cx, y - 8); }
    else { c.moveTo(sl.cx - 6, y + 27); c.lineTo(sl.cx + 6, y + 27); c.lineTo(sl.cx, y + 36); }
    c.fill();
    G.text(c, `${b.face} ${b.text}`, sl.cx, y + 14, { size: 13, fill: C.ink, weight: 800 });
    c.globalAlpha = 1;
  }

  /** 엽전 — 둥근 몸통에 네모 구멍. 조선 상평통보 모양이다. */
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
