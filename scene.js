/* scene.js — 마을을 위에서 내려다본 한 폭. 그리기만 한다.
 *
 * 여기엔 경제 계산이 한 줄도 없다. sim.js를 읽기만 하고 절대 고치지 않는다.
 * 목록·버튼으로 보여주던 걸 장면으로 바꾸는 게 전부다:
 *
 *   "토끼가 곡괭이 3개를 사갔다"  →  토끼가 길을 걸어 올라와 대장간 앞에 서고,
 *                                  동전이 튀고, 다시 걸어 내려간다
 *
 * core/engine.js를 처음으로 쓴다. 그 파일은 이걸 하라고 만들어져 있었는데
 * 게임이 목록 방식이라 한 번도 안 쓰였다.
 */

import { G } from './core/engine.js';
import { Juice, Sfx } from './core/juice.js';
import { SHOPS, STOCK_CAP } from './content.js';
import { fmt } from './sim.js';

/* ── 마을 배치 ──
 * 길이 가운데를 세로로 지나고, 가게가 좌우로 번갈아 선다.
 * 손님은 화면 아래에서 길을 따라 올라온다. */
const W = 480, H = 800;
const ROAD_X = 240, ROAD_W = 74;
const BOX_W = 190, BOX_H = 138;

/** 가게 자리. SHOPS 순서대로 아래에서 위로 올라간다 — 아래가 오래된 가게다. */
const SLOTS = [
  { x: 12,  y: 596, side: -1 },
  { x: 278, y: 450, side: 1 },
  { x: 12,  y: 304, side: -1 },
  { x: 278, y: 158, side: 1 },
  { x: 12,  y: 12,  side: -1 },
];

const C = {
  grass:  '#8b9e74',
  grass2: '#7e9268',
  road:   '#d9cba9',
  edge:   '#bfae8a',
  paper:  '#e8ddc8',
  paper2: '#ddd0b6',
  ink:    '#2b241b',
  ink2:   '#5a4e3d',
  ink3:   '#8a7a63',
  gold:   '#a8763e',
  jade:   '#4a7c59',
  ruin:   '#6f7d5e',
};

/** 자리 정보 + 손님이 설 위치 */
function slotOf(i) {
  const s = SLOTS[i];
  return {
    ...s,
    cx: s.x + BOX_W / 2,
    cy: s.y + BOX_H / 2,
    /* 손님이 서는 자리 = 가게 앞.
     *
     * 처음엔 길 가장자리(219 / 261)에 세웠는데, 길이 203~277이라 어느 가게에
     * 가든 길 위 몇 픽셀 차이였다. 그래서 "필방은 손님이 한 번도 안 온다"처럼
     * 보였다 — 실제로는 30%가 필방으로 가고 있었는데 자리가 티가 안 났다.
     * 이제 길에서 벗어나 가게 발치까지 들어온다. */
    standX: s.x + BOX_W * (s.side < 0 ? 0.72 : 0.28),
    standY: s.y + BOX_H + 8,   // 진열대 숫자를 안 가리도록 가게 발치 바로 아래
  };
}

export class Village {
  /**
   * @param sim         읽기 전용으로 들여다볼 게임 상태
   * @param onShopTap   가게를 눌렀을 때 부를 함수 (강화 창을 여는 쪽에서 처리)
   */
  constructor(sim, onShopTap) {
    this.sim = sim;
    this.onShopTap = onShopTap;
    this.walkers = [];
    /* 튀어오르는 엽전. 예전엔 "+6,927" 같은 글자를 띄웠는데 손님이 몰리면
     * 글자끼리 겹쳐 읽을 수가 없었다. 게다가 헤더는 "3002만냥", 글자는
     * "+6,927"이라 표기까지 달랐다.
     *
     * 금액은 헤더가 이미 은행 잔고처럼 보여준다. 여기서는 "팔렸다"만
     * 알려주면 된다. 조선 동전은 가운데가 네모로 뚫린 상평통보다. */
    this.coins = [];
    /* 가게별 매상 카운터. 가게idx → {amount, t}
     *
     * 금액을 손님 자리에 띄웠더니 손님이 몰릴 때 글자끼리 겹쳤다.
     * 가게마다 한 자리를 정해두면 같은 가게에 손님이 여럿 와도 금액이
     * 그 자리에서 합쳐질 뿐 겹치지 않는다. */
    this.takings = {};
    /* 아직 손님이 도착하지 않은 판매량. 품목id → 개수.
     *
     * sim은 손님이 사는 순간 재고를 바로 깎는다. 그런데 화면에서는 그 손님이
     * 길을 걸어오는 데 몇 초가 걸린다. 그대로 두면 **아무도 없는 가게에서
     * 물건이 먼저 사라진다** — 결과가 원인보다 먼저 나온다.
     *
     * 그래서 진열대에 보여줄 때만 이 수치를 도로 더한다. 손님이 도착하는
     * 순간 빼면 숫자가 그때 떨어진다. 계산은 건드리지 않으므로 밸런스는
     * 그대로다. 화면이 계산을 따라잡는 것뿐이다. */
    this.pending = {};
    this.flash = {};         // 방금 깎인 칸을 잠깐 빛나게 한다
    this.bubble = null;      // 손님 요청 말풍선 {shopIdx, text, t}
    this.t = 0;
    this.tufts = this._tufts();
  }

  /** 풀밭 무늬. 매 프레임 난수를 쓰면 잔디가 부들부들 떨린다 — 한 번만 정해둔다. */
  _tufts() {
    let seed = 7;
    const rnd = () => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    const out = [];
    for (let i = 0; i < 90; i++) {
      const x = rnd() * W, y = rnd() * H;
      if (Math.abs(x - ROAD_X) < ROAD_W / 2 + 8) continue;   // 길 위엔 안 난다
      out.push({ x, y, r: 2 + rnd() * 3 });
    }
    return out;
  }

  /** 가게 위에 띄울 자리. 맨 위 가게(약재상)는 위쪽이 화면 밖이라 아래에 단다. */
  _perch(sl, h) {
    return sl.y - h - 8 >= 4 ? sl.y - h - 8 : sl.y + BOX_H - 4;
  }

  /* ── 바깥에서 알려주는 사건 ── */

  /** 손님이 뭔가 사갔다 → 그 가게로 걸어 보낸다 */
  onSale(sale) {
    // 손님을 못 띄우면 재고도 붙잡지 않는다. 안 그러면 영영 안 빠진다.
    if (this.walkers.length > 9) return;
    const shopId = sale.lines[0].item.shop;
    const idx = SHOPS.findIndex((s) => s.id === shopId);
    if (idx < 0) return;
    for (const ln of sale.lines) {
      this.pending[ln.item.id] = (this.pending[ln.item.id] || 0) + ln.n;
    }
    this.walkers.push({
      face: sale.guest.face,
      idx,
      gain: sale.gain,
      sold: sale.lines.map((ln) => ({ id: ln.item.id, n: ln.n })),
      lines: sale.lines.length,
      // 가까운 쪽에서 들어온다. 전부 화면 아래에서 출발시켰더니 맨 위 약재상까지
      // 7초가 걸렸고, 그동안 진열대 숫자가 멈춰 있어 그것대로 어색했다.
      x: ROAD_X + (Math.random() - 0.5) * (ROAD_W - 34),
      y: SLOTS[idx].y < H / 2 ? -30 : H + 30,
      exit: SLOTS[idx].y < H / 2 ? -1 : 1,
      state: 'in',
      wait: 0,
      bob: Math.random() * 6,
    });
  }

  /** 손님이 없는 물건을 물어봤다 → 그 가게 위에 말풍선 */
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
        // 길을 따라 올라가다가, 가게 높이에 닿으면 가게 쪽으로 붙는다
        const dy = sl.standY - w.y;
        w.y += Math.sign(dy) * Math.min(Math.abs(dy), 155 * dt);
        const dx = sl.standX - w.x;
        if (Math.abs(dy) < 130) w.x += Math.sign(dx) * Math.min(Math.abs(dx), 175 * dt);
        if (Math.abs(dy) < 3 && Math.abs(dx) < 3) {
          w.state = 'buy'; w.wait = 0.75;
          // 도착한 지금이 재고가 빠지는 순간이다
          for (const s of w.sold) {
            this.pending[s.id] = Math.max(0, (this.pending[s.id] || 0) - s.n);
            this.flash[s.id] = 0.45;
          }
          // 산 품목 수만큼 엽전이 튄다 — 3종을 사가면 3개
          const n = Math.min(5, w.sold.length);
          for (let k = 0; k < n; k++) {
            this.coins.push({
              x: w.x + (Math.random() - 0.5) * 14,
              y: w.y - 16,
              vx: (Math.random() - 0.5) * 46,
              vy: -92 - Math.random() * 46,
              t: 1.05, r: 8.5 + Math.random() * 2.5,
            });
          }
          const tk = (this.takings[w.idx] ||= { amount: 0, t: 0 });
          tk.amount += w.gain;
          tk.t = 1.7;
          Juice.burst(w.x, w.y - 14, { n: 4, color: ['#f0d98b'], size: 2, speed: 52, life: 0.34 });
          Sfx.coin();
        }
      } else if (w.state === 'buy') {
        w.wait -= dt;
        if (w.wait <= 0) w.state = 'out';
      } else {
        w.y += 150 * dt * w.exit;      // 왔던 쪽으로 돌아간다
        const back = ROAD_X - w.x;
        w.x += Math.sign(back) * Math.min(Math.abs(back), 70 * dt);
      }
    }
    this.walkers = this.walkers.filter((w) => w.y > -90 && w.y < H + 90);

    for (const id of Object.keys(this.flash)) {
      this.flash[id] -= dt;
      if (this.flash[id] <= 0) delete this.flash[id];
    }

    for (const co of this.coins) {
      co.t -= dt;
      co.x += co.vx * dt;
      co.y += co.vy * dt;
      co.vy += 165 * dt;          // 살짝 떨어지며 사라진다
    }
    this.coins = this.coins.filter((co) => co.t > 0);

    for (const k of Object.keys(this.takings)) {
      this.takings[k].t -= dt;
      if (this.takings[k].t <= 0) delete this.takings[k];
    }

    // 가게를 눌렀나
    if (pointer.justDown) {
      for (let i = 0; i < SHOPS.length; i++) {
        const s = SLOTS[i];
        if (pointer.x > s.x && pointer.x < s.x + BOX_W &&
            pointer.y > s.y && pointer.y < s.y + BOX_H) {
          this.onShopTap(SHOPS[i].id, this.sim.shops.includes(SHOPS[i].id));
          return;
        }
      }
    }
  }

  /* ── 그리기 ── */
  draw(c) {
    this._ground(c);
    for (let i = 0; i < SHOPS.length; i++) this._shop(c, i);
    for (const w of this.walkers) this._walker(c, w);
    for (const k of Object.keys(this.takings)) this._takings(c, Number(k));
    if (this.bubble) this._bubble(c);
    for (const co of this.coins) this._coin(c, co);
  }

  /** 매상 카운터. 가게 위에 떠서 잠깐 올라가다 사라진다. */
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

  /** 엽전 — 둥근 몸통에 네모 구멍. 조선 상평통보 모양이다. */
  _coin(c, co) {
    const a = Math.min(1, co.t * 2.4);
    const r = co.r;
    c.globalAlpha = a;
    G.circle(c, co.x, co.y, r, '#b8873a');
    G.circle(c, co.x, co.y, r * 0.84, '#ecc264');
    c.fillStyle = '#b8873a';
    const q = r * 0.3;
    c.fillRect(co.x - q, co.y - q, q * 2, q * 2);
    c.globalAlpha = 1;
  }

  _ground(c) {
    G.rect(c, 0, 0, W, H, C.grass);
    for (const t of this.tufts) G.circle(c, t.x, t.y, t.r, C.grass2);
    // 길
    G.rect(c, ROAD_X - ROAD_W / 2, 0, ROAD_W, H, C.road);
    G.rect(c, ROAD_X - ROAD_W / 2, 0, 3, H, C.edge);
    G.rect(c, ROAD_X + ROAD_W / 2 - 3, 0, 3, H, C.edge);
    // 디딤돌. 처음엔 54px마다 한가운데 놓았더니 길이 사다리처럼 보였다.
    // 간격을 벌리고 좌우로 어긋나게 놓으니 밟고 지나가는 길이 됐다.
    for (let i = 0, y = 40; y < H; y += 96, i++) {
      const off = i % 2 ? 13 : -13;
      G.round(c, ROAD_X + off - 13, y, 26, 13, 6, C.edge);
    }
  }

  _shop(c, i) {
    const shop = SHOPS[i], sl = slotOf(i), open = this.sim.shops.includes(shop.id);
    const { x, y } = sl;

    if (!open) {
      // 무너진 집 — 점선 테두리에 잡초
      c.save();
      c.setLineDash([7, 6]); c.lineWidth = 2; c.strokeStyle = C.ruin;
      c.beginPath(); c.roundRect(x + 6, y + 10, BOX_W - 12, BOX_H - 20, 12); c.stroke();
      c.restore();
      G.text(c, '□', sl.cx, sl.cy - 12, { size: 30, fill: C.ruin, weight: 700 });
      const next = this.sim.nextShop();
      const isNext = next && next.id === shop.id;
      G.text(c, isNext ? shop.name : '무너진 집', sl.cx, sl.cy + 18,
        { size: 12.5, fill: isNext ? C.paper : C.ruin, weight: 800 });
      if (isNext) {
        G.round(c, sl.cx - 46, sl.cy + 32, 92, 22, 8,
          this.sim.money >= shop.cost ? C.jade : '#7d7a68');
        G.text(c, `${fmt(shop.cost)}냥`, sl.cx, sl.cy + 43, { size: 11.5, fill: '#fff', weight: 800 });
      }
      return;
    }

    // 바닥 그림자
    G.round(c, x + 6, y + 16, BOX_W - 12, BOX_H - 18, 12, 'rgba(0,0,0,.13)');
    // 몸체
    G.round(c, x + 4, y + 10, BOX_W - 8, BOX_H - 20, 12, C.paper);
    // 차양 — 가게 색
    G.round(c, x + 4, y + 10, BOX_W - 8, 30, 12, shop.color);
    G.rect(c, x + 4, y + 32, BOX_W - 8, 8, shop.color);
    // 간판
    G.text(c, `${shop.sign} ${shop.name}`, sl.cx, y + 26, { size: 14, fill: '#fff8ec', weight: 800 });

    // 진열대 — 열린 품목마다 재고 칸. 재고가 차오르는 게 눈에 보여야 한다.
    const items = shop.items.filter((it) => this.sim.isOpen(it.id));
    const per = Math.min(4, items.length);
    for (let k = 0; k < per; k++) {
      const it = items[k];
      const bw = (BOX_W - 24) / per - 4;
      const bx = x + 12 + k * (bw + 4);
      const by = y + 48;
      const fl = this.flash[it.id] || 0;
      G.round(c, bx, by, bw, 46, 7, fl > 0 ? '#f0e2b4' : C.paper2);
      const st = this.sim.items[it.id];
      // 걸어오는 중인 몫을 도로 더한다 — 손님이 닿아야 숫자가 떨어진다
      const shown = Math.min(STOCK_CAP, st.stock + (this.pending[it.id] || 0));
      const h = Math.round(42 * Math.min(1, shown / STOCK_CAP));
      if (h > 0) G.round(c, bx + 2, by + 44 - h, bw - 4, h, 5, shop.color);
      G.text(c, it.name, bx + bw / 2, by + 12, { size: 9.5, fill: C.ink2, weight: 800 });
      G.text(c, String(shown), bx + bw / 2, by + 32,
        { size: fl > 0 ? 15 : 13, fill: C.ink, weight: 800 });
    }

    // 잠긴 칸이 남아 있으면 알려준다 — 다음에 뭘 열지가 여기서 보인다
    const locked = shop.items.filter((it) => !this.sim.isOpen(it.id));
    if (locked.length) {
      const askedNext = locked.find((it) => this.sim.asked.includes(it.id));
      G.text(c, askedNext ? `${askedNext.name} 칸 열 수 있음` : `${locked.length}칸 더 있다`,
        sl.cx, y + BOX_H - 18, { size: 10.5, fill: askedNext ? C.gold : C.ink3, weight: 800 });
    }
  }

  _walker(c, w) {
    const bob = Math.sin(this.t * 9 + w.bob) * (w.state === 'buy' ? 0.8 : 2.4);
    G.circle(c, w.x, w.y + 8, 9, 'rgba(0,0,0,.16)');
    G.text(c, w.face, w.x, w.y - 8 + bob, { size: 27, fill: '#000' });
  }

  _bubble(c) {
    const b = this.bubble, sl = slotOf(b.idx);
    // 맨 위 가게는 위가 화면 밖이라 말풍선이 아래에 달린다. 그때는 꼬리도
    // 위를 향해야 어느 가게를 가리키는지가 맞는다.
    const below = sl.y - 28 - 8 < 4;
    const lift = this.takings[b.idx] ? 32 : 0;
    const w = 108, x = sl.cx - w / 2;
    const y = below ? this._perch(sl, 28) + lift : this._perch(sl, 28) - lift;
    c.globalAlpha = Math.min(1, b.t);
    G.round(c, x, y, w, 28, 9, '#fff6d8');
    c.fillStyle = '#fff6d8';
    c.beginPath();
    if (below) {
      c.moveTo(sl.cx - 6, y + 1); c.lineTo(sl.cx + 6, y + 1); c.lineTo(sl.cx, y - 8);
    } else {
      c.moveTo(sl.cx - 6, y + 27); c.lineTo(sl.cx + 6, y + 27); c.lineTo(sl.cx, y + 36);
    }
    c.fill();
    G.text(c, `${b.face} ${b.text}`, sl.cx, y + 14, { size: 13, fill: C.ink, weight: 800 });
    c.globalAlpha = 1;
  }

}
