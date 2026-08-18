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
import { SHOPS, STOCK_CAP, SMALL_SHOPS } from './content.js';
import { fmt } from './sim.js';

/* 보이는 창은 480×800이고, 마을은 그보다 세로로 길다. 손가락으로 밀어 훑는다.
 * 가게가 늘 때마다 화면에 욱여넣을 수 없어서 세로로 늘렸다. */
const W = 480, H = 1560;
const ROAD_W = 74;

/** 구불구불한 길. 이 한 줄이 "지도 느낌"의 가장 큰 원인을 없앤다. */
const roadX = (y) => 240 + 24 * Math.sin(y / 175 + 0.6);

/* 가게 자리.
 * 좌우 번갈이를 일부러 깼다 — 지물포와 옹기점은 둘 다 왼쪽에 선다.
 * 폭도 제각각인데, 길이 오른쪽으로 휜 구간에서는 왼쪽에 자리가 더 남기
 * 때문이다. 길에 맞춰 자리를 잡으니 배치가 저절로 불규칙해진다. */
const SLOTS = [
  { x: 12,  y: 1358, w: 188, h: 150, side: -1 },  // 대장간
  { x: 308, y: 1112, w: 160, h: 150, side: 1 },   // 필방
  { x: 12,  y: 872,  w: 168, h: 150, side: -1 },  // 지물포
  { x: 12,  y: 612,  w: 160, h: 150, side: -1 },  // 옹기점
  { x: 300, y: 322,  w: 168, h: 150, side: 1 },   // 약재상
];

/* 작은 건물 — 큰 가게 사이를 채우는 점포·주막·포장마차.
 * 마을이 세로로 길어지면서 가게 사이가 휑해졌다. 자리는 길과 큰 가게를
 * 피해 계산으로 잡았다. */
const SMALL_W = 96, SMALL_H = 76;
/** content.js의 SMALL_SHOPS와 같은 순서·같은 개수여야 한다.
 *  점포를 오른쪽 1270에 뒀더니 '장 서다!' 표시가 필방 글자를 가려 옮겼다. */
const SMALL_POS = [
  { x: 16,  y: 1150 },
  { x: 368, y: 1004 },
  { x: 368, y: 760 },
  { x: 16,  y: 470 },
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

/* 손님이 지고 온 짐.
 *
 * GUESTS의 qty(한 번에 사가는 개수)는 이미 정해져 있는데 숫자로만 숨어 있었다.
 * 짐으로 보이면 "큰 손님이 온다"가 멀리서부터 읽힌다.
 * 규칙은 아니고 표시일 뿐이다 — qty를 그대로 그림으로 옮긴다. */
const carryOf = (qty) => qty <= 5 ? 'hand' : qty <= 9 ? 'bojjim' : qty <= 12 ? 'jige' : 'cart';

/* 집이 좋아지는 축이 둘이다.
 *   지붕 = 가게 등급   초가(돌급) → 기와(쇠급) → 기와+단청(강철급)
 *   장식 = 칸을 다 열었는가   현판 금테와 화분
 * 축을 둘로 나눈 이유: 등급 하나로만 하면 첫 승급까지 두 시간 반 동안
 * 건물이 전혀 안 변한다. 칸을 여는 것도 눈에 보여야 한다. */
function lookOf(shop, sim) {
  return {
    roof: sim.rankOf(shop.id),
    deco: shop.items.every((it) => sim.isOpen(it.id)),
  };
}

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
    /* 카메라 — 창의 위쪽이 마을의 어느 높이를 보고 있는가.
     * 마을 어귀(아래)에서 시작한다. 첫 가게가 거기 있다. */
    this.cam = H;          // 첫 update에서 마을 어귀로 물린다
    this.viewH = 800;      // 기기마다 다르다. 엔진이 매 프레임 알려준다.
    this.vel = 0;          // 손을 뗀 뒤 미끄러지는 속도
    this.drag = null;      // 끄는 중일 때 {y, moved}
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
    for (let i = 0; i < 260; i++) {
      const x = rnd() * W, y = rnd() * H;
      if (Math.abs(x - roadX(y)) < ROAD_W / 2 + 6) continue;
      out.push({ x, y, r: 2 + rnd() * 3.2 });
    }
    return out;
  }

  /** 빈 풀밭이 지도 여백처럼 보였다. 나무·장독·초롱·바위를 깔아 마을로 만든다. */
  _props() {
    /* 마을 어귀의 장승 한 쌍.
     *
     * 길이 화면 위아래로 그냥 뚫려 있어 어디가 입구인지 알 수 없었다.
     * 아래를 장승으로 막아 '마을 어귀', 위를 숲으로 막아 '산길'로 읽히게 한다.
     * 손님이 위아래 양쪽에서 오는 게 그제야 말이 된다 — 마을을 지나는 길이니까. */
    const gy = 1522, gx = roadX(gy);
    const out = [
      { x: gx - 48, y: gy, k: 'jangseung', r: 16, f: 0 },
      { x: gx + 48, y: gy, k: 'jangseung', r: 16, f: 1 },
    ];
    const rnd = this._rng(20250818);
    const kinds = ['tree', 'tree', 'tree', 'jars', 'lantern', 'rock', 'flower', 'flower'];
    let guard = 0;
    while (out.length < 52 && guard++ < 2600) {
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

  /**
   * 손님이 사간 것을 가게별로 묶어 **순회 경로**로 만든다.
   *
   * 거래의 85%는 두세 가게에 걸쳐 있다(3시간 측정: 1곳 14%, 2곳 59%, 3곳 27%).
   * 예전엔 첫 줄의 가게 한 곳에만 손님을 세워서, 실제로는 대장간과 필방을
   * 같이 들르는 손님을 화면이 한 곳만 보여주는 거짓말을 하고 있었다.
   */
  onSale(sale) {
    if (this.walkers.length > 6) return;   // 못 띄우면 재고도 붙잡지 않는다

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

    // 들어온 쪽에서 가까운 가게부터 차례로 들르고, 그대로 반대편으로 빠져나간다.
    // 왔던 길을 되돌아가는 것보다 마을을 훑고 지나가는 게 자연스럽다.
    const avgY = stops.reduce((a, x) => a + SLOTS[x.idx].y, 0) / stops.length;
    const fromTop = avgY < H / 2;
    stops.sort((a, b) => fromTop ? SLOTS[a.idx].y - SLOTS[b.idx].y
                                 : SLOTS[b.idx].y - SLOTS[a.idx].y);

    const y = fromTop ? -30 : H + 30;
    this.walkers.push({
      face: sale.guest.face,
      reg: this.sim.regularLv(sale.guest.id),   // 단골 등급 — 갓으로 보여준다
      speed: sale.guest.speed || 1,             // 거북은 느리고 까치는 빠르다
      carry: carryOf(sale.guest.qty),
      stops, si: 0,
      lane: (Math.random() - 0.5) * (ROAD_W - 34),
      x: roadX(y), y,
      exit: fromTop ? 1 : -1,
      state: 'in', wait: 0, bob: Math.random() * 6,
    });
  }

  onAsk(ask) {
    const idx = SHOPS.findIndex((s) => s.id === ask.item.shop);
    if (idx < 0) return;
    this.bubble = { idx, text: `${ask.item.name}?`, t: 4.5, face: ask.guest.face };
  }

  /* ── 매 프레임 ── */
  update(dt, pointer, viewH) {
    /* 보이는 높이가 바뀌면(폴더블을 펴고 접거나, 화면을 돌리거나, 창 크기를
     * 바꾸면) 보고 있던 한가운데를 붙잡아 둔다.
     *
     * 안 그러면 카메라 값만 그대로 남아 보던 곳이 화면 밖으로 밀려난다.
     * 폴드를 펴는 순간 마을 어귀와 대장간이 통째로 아래로 사라졌다. */
    if (viewH && viewH !== this.viewH) {
      const center = this.cam + this.viewH / 2;
      this.viewH = viewH;
      this.cam = center - viewH / 2;
      this.vel = 0;
    }
    this.t += dt;
    if (this.bubble) { this.bubble.t -= dt; if (this.bubble.t <= 0) this.bubble = null; }

    for (const w of this.walkers) {
      const stop = w.stops[w.si];
      if (w.state === 'in' && stop) {
        const sl = slotOf(stop.idx);
        const dy = sl.standY - w.y;
        w.y += Math.sign(dy) * Math.min(Math.abs(dy), 155 * w.speed * dt);
        // 멀리 있을 땐 구부러진 길을 따라가고, 가까워지면 가게 앞으로 꺾는다
        const tx = Math.abs(dy) < 130 ? sl.standX : roadX(w.y) + w.lane;
        const dx = tx - w.x;
        w.x += Math.sign(dx) * Math.min(Math.abs(dx), 175 * w.speed * dt);
        if (Math.abs(dy) < 3 && Math.abs(sl.standX - w.x) < 3) {
          w.state = 'buy'; w.wait = 0.7;
          for (const s of stop.sold) {              // 도착한 지금이 재고가 빠지는 순간
            this.pending[s.id] = Math.max(0, (this.pending[s.id] || 0) - s.n);
            this.flash[s.id] = 0.45;
          }
          // 엽전은 길 쪽으로 튄다. 가게 쪽으로 튀면 좌판의 재고 숫자를 가린다.
          const away = -SLOTS[stop.idx].side;
          for (let k = 0; k < Math.min(5, stop.sold.length); k++) {
            this.coins.push({
              x: w.x + away * 16 + (Math.random() - 0.5) * 12, y: w.y - 8,
              vx: away * (26 + Math.random() * 26), vy: -78 - Math.random() * 38,
              t: 1.05, r: 8.5 + Math.random() * 2.5,
            });
          }
          const tk = (this.takings[stop.idx] ||= { amount: 0, t: 0 });
          tk.amount += stop.gain; tk.t = 1.7;
          // Juice는 엔진이 화면 좌표로 그린다 — 카메라만큼 빼서 넘긴다.
          // 화면 밖 거래에는 아예 안 뿌린다.
          const sy = w.y - this.cam;
          if (sy > -20 && sy < this.viewH + 20) {
            Juice.burst(w.x, sy - 14, { n: 4, color: ['#f0d98b'], size: 2, speed: 52, life: 0.34 });
          }
          Sfx.coin();
        }
      } else if (w.state === 'buy') {
        w.wait -= dt;
        if (w.wait <= 0) { w.si++; w.state = w.si < w.stops.length ? 'in' : 'out'; }
      } else {
        w.y += 150 * w.speed * dt * w.exit;
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

    this._camera(dt, pointer);
  }

  /* ── 카메라 ──
   * 손가락으로 밀어 마을을 위아래로 훑는다. 밀었는지 눌렀는지는 움직인
   * 거리로 가른다 — 안 그러면 스크롤할 때마다 가게 창이 열린다. */
  _camera(dt, p) {
    /* justDown으로 시작을 잡는 게 중요하다. '눌린 상태'를 한 프레임이라도
     * 봐야 하는 방식으로 짰더니, 누름과 뗌이 한 프레임 안에 들어오는 빠른
     * 탭을 통째로 놓쳤다. justDown은 엔진이 한 프레임 붙들어 주므로 안 샌다. */
    if (p.justDown) { this.drag = { y: p.y, moved: 0 }; this.vel = 0; }

    if (this.drag && p.down) {
      const dy = p.y - this.drag.y;
      this.cam -= dy;
      this.vel = -dy / Math.max(dt, 1 / 120);
      this.drag.moved += Math.abs(dy);
      this.drag.y = p.y;
    } else if (this.drag) {
      if (this.drag.moved < 7) this._tap(p.x, p.y + this.cam);   // 민 게 아니라 누른 것
      this.drag = null;
    }

    if (!this.drag) {
      this.cam += this.vel * dt;
      this.vel *= Math.pow(0.0016, dt);        // 손을 떼면 미끄러지다 멎는다
      if (Math.abs(this.vel) < 4) this.vel = 0;
    }
    const camMax = this.camMax();
    if (this.cam < 0) { this.cam = 0; this.vel = 0; }
    if (this.cam > camMax) { this.cam = camMax; this.vel = 0; }
  }

  /** 밀 수 있는 최대 거리. 창이 마을보다 크면 0 — 밀 것이 없다. */
  camMax() { return Math.max(0, H - this.viewH); }

  _tap(wx, wy) {
    // 북적이는 작은 건물을 먼저 본다 — 이게 이 순간 제일 하고 싶은 조작이다
    for (let i = 0; i < SMALL_POS.length; i++) {
      const p = SMALL_POS[i];
      if (wx > p.x - 8 && wx < p.x + SMALL_W + 8 && wy > p.y - 26 && wy < p.y + SMALL_H + 8) {
        if (!this.sim.smalls.includes(i)) {
          if (this.sim.buildSmall(i)) { Sfx.reward(); Juice.shake(5); } else Sfx.deny();
        } else if (this.sim.tapSmall(i)) { Sfx.win(); Juice.shake(6); }
        else Sfx.click();
        return;
      }
    }
    for (let i = 0; i < SHOPS.length; i++) {
      const s = SLOTS[i];
      if (wx > s.x && wx < s.x + s.w && wy > s.y && wy < s.y + s.h) {
        this.onShopTap(SHOPS[i].id, this.sim.shops.includes(SHOPS[i].id));
        return;
      }
    }
  }

  /* ── 그리기 ──
   * 건물·소품·손님을 한 줄로 세워 발끝 높이 순으로 그린다. 앞에 있는 것이
   * 뒤를 가려야 평면이 아니라 공간으로 보인다. */
  draw(c) {
    const top = this.cam - 60, bot = this.cam + this.viewH + 60;
    const near = (y, pad = 0) => y > top - pad && y < bot + pad;

    c.save();
    c.translate(0, -this.cam);
    this._ground(c, top, bot);

    /* 화면 밖은 아예 건너뛴다. 마을이 창의 두 배라 그냥 그리면 절반이
     * 헛일이고, 폰에서 그 값을 그대로 치른다. */
    const layer = [];
    for (let i = 0; i < SHOPS.length; i++) {
      const s = SLOTS[i];
      if (near(s.y, s.h + 60)) layer.push({ z: s.y + s.h, d: () => this._shop(c, i) });
    }
    for (let i = 0; i < SMALL_POS.length; i++) {
      const p = SMALL_POS[i];
      if (near(p.y, SMALL_H + 40)) layer.push({ z: p.y + SMALL_H, d: () => this._small(c, i) });
    }
    for (const p of this.props) if (near(p.y, 60)) layer.push({ z: p.y, d: () => this._prop(c, p) });
    for (const w of this.walkers) if (near(w.y, 40)) layer.push({ z: w.y, d: () => this._walker(c, w) });
    layer.sort((a, b) => a.z - b.z);
    for (const l of layer) l.d();

    for (const k of Object.keys(this.takings)) this._takings(c, Number(k));
    if (this.bubble) this._bubble(c);
    for (const co of this.coins) if (near(co.y, 30)) this._coin(c, co);
    c.restore();

    this._scrollHint(c);
    if (this.sim.fair > 0) this._fairBanner(c);
  }

  /** 장이 서 있는 동안 창 위쪽에 남은 시간을 띄운다 (화면 좌표) */
  _fairBanner(c) {
    const left = this.sim.fair;
    G.round(c, W / 2 - 76, 10, 152, 28, 10, '#c7563f');
    G.text(c, `장이 섰다 · ${Math.ceil(left)}초`, W / 2, 24,
      { size: 13.5, fill: '#fff3dd', weight: 800 });
  }

  /** 마을이 창보다 길다는 걸 알려주는 가느다란 표시 */
  _scrollHint(c) {
    const camMax = this.camMax();
    if (camMax <= 0) return;                 // 다 보이면 표시할 것도 없다
    const track = this.viewH - 44;
    const th = Math.max(46, track * this.viewH / H);
    const ty = 22 + (track - th) * (this.cam / camMax);
    G.round(c, W - 10, 22, 4, track, 2, 'rgba(43,36,27,.10)');
    G.round(c, W - 10, ty, 4, th, 2, 'rgba(43,36,27,.34)');
  }

  _ground(c, top, bot) {
    G.rect(c, 0, top, W, bot - top, C.grass);
    for (const t of this.tufts) {
      if (t.y > top && t.y < bot) G.circle(c, t.x, t.y, t.r, C.grass2);
    }

    // 구부러진 길 — 가로줄을 촘촘히 쌓아 곡선을 만든다 (보이는 구간만)
    for (let y = Math.max(0, Math.floor(top / 2) * 2); y < Math.min(H, bot); y += 2) {
      const rx = roadX(y);
      G.rect(c, rx - ROAD_W / 2, y, ROAD_W, 2.4, C.road);
      G.rect(c, rx - ROAD_W / 2, y, 3, 2.4, C.edge);
      G.rect(c, rx + ROAD_W / 2 - 3, y, 3, 2.4, C.edge);
    }
    // 위쪽 = 산길. 숲으로 막아 마을이 어디서 끝나는지 보이게 한다.
    for (let i = 0; i < 15; i++) {
      const px = 6 + i * 33;
      if (Math.abs(px - roadX(14)) < ROAD_W / 2 + 12) continue;
      G.circle(c, px, 4, 21, '#5e7351');
      G.circle(c, px + 15, -4, 17, '#556a49');
    }

    // 디딤돌. 좌우로 어긋나게 놓아야 사다리처럼 안 보인다.
    for (let i = 0, y = 46; y < H; y += 98, i++) {
      if (y > top && y < bot) G.round(c, roadX(y) + (i % 2 ? 13 : -13) - 13, y, 26, 13, 6, C.edge);
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
    } else if (p.k === 'jangseung') {
      // 장승 — 마을 어귀를 지키는 나무 장승. 부릅뜬 눈과 벌린 입이 특징이다.
      const hh = 44;
      c.fillStyle = 'rgba(0,0,0,.15)';
      c.beginPath(); c.ellipse(x, y + 2, 11, 4.5, 0, 0, 7); c.fill();
      G.round(c, x - 7, y - hh, 14, hh, 3, '#6d5236');
      G.round(c, x - 12, y - hh - 20, 24, 22, 5, '#836745');
      G.round(c, x - 16, y - hh - 24, 32, 6, 2, '#57432c');    // 벙거지
      for (const ex of [-5.5, 5.5]) {
        G.circle(c, x + ex, y - hh - 13, 3.2, '#f2e8d2');
        G.circle(c, x + ex, y - hh - 13, 1.5, '#2b241b');
      }
      G.round(c, x - 6, y - hh - 6, 12, 4.5, 2, '#3a2c1e');
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

  /**
   * 지붕. 격에 따라 초가 → 기와 → 단청 얹은 기와로 바뀐다.
   * 한옥 지붕 앞모습은 양 끝이 치켜올라가고 가운데가 처진다.
   */
  _roof(c, x, y, w, roof) {
    const l = x - 10, r = x + w + 10;
    const thatch = roof <= 0;
    const band = (yTop, yBot, fill) => {
      c.fillStyle = fill;
      c.beginPath();
      c.moveTo(l, y + yTop);
      c.quadraticCurveTo(x + w / 2, y + yTop + 15, r, y + yTop);
      c.lineTo(r, y + yBot);
      c.quadraticCurveTo(x + w / 2, y + yBot + 15, l, y + yBot);
      c.closePath(); c.fill();
    };

    if (thatch) {
      // 초가 — 볏짚을 얹은 지붕. 결이 세로로 보인다.
      band(4, 38, '#b39a63');
      c.strokeStyle = 'rgba(90,70,40,.22)'; c.lineWidth = 1.6;
      for (let k = 1; k < 14; k++) {
        const px = x - 6 + ((w + 12) * k) / 14;
        const t = (px - l) / (r - l);
        const top = y + 4 + 30 * t * (1 - t) * 2;
        c.beginPath(); c.moveTo(px, top + 2); c.lineTo(px, top + 30); c.stroke();
      }
      return;
    }

    band(6, 34, C.tile);
    c.strokeStyle = C.tile2; c.lineWidth = 4;            // 용마루
    c.beginPath();
    c.moveTo(l, y + 7); c.quadraticCurveTo(x + w / 2, y + 22, r, y + 7);
    c.stroke();
    c.strokeStyle = 'rgba(255,255,255,.09)'; c.lineWidth = 1.4;   // 기왓골
    for (let k = 1; k < 8; k++) {
      const px = x - 6 + ((w + 12) * k) / 8;
      const t = (px - l) / (r - l);
      const top = y + 6 + 30 * t * (1 - t) * 2;
      c.beginPath(); c.moveTo(px, top + 3); c.lineTo(px, top + 26); c.stroke();
    }

    // 단청 — 처마 아래 채색 띠. 격이 오른 집에만 올린다.
    if (roof >= 2) {
      for (let k = 0; k < 9; k++) {
        const bw = (w + 8) / 9;
        const bx = x - 4 + k * bw;
        const t = (bx + bw / 2 - l) / (r - l);
        const yy = y + 34 + 30 * t * (1 - t) * 2;
        G.round(c, bx + 1, yy, bw - 2, 6, 2, k % 3 === 0 ? '#3f6f4a' : k % 3 === 1 ? '#a34a3a' : '#3a5f86');
      }
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

    const look = lookOf(shop, this.sim);

    // 담장·화분 — 제일 격이 높은 집에만 두른다
    if (look.deco) {
      for (const px of [x - 4, x + w - 10]) {
        G.round(c, px, y + h - 26, 14, 10, 3, '#7d6a4a');
        G.circle(c, px + 7, y + h - 30, 8, '#6f8a5c');
        G.circle(c, px + 3, y + h - 34, 5, '#7fa070');
      }
    }

    // 몸채 — 흙벽에 나무 기둥
    G.round(c, x + 6, y + 30, w - 12, h - 30, 5, C.paper);
    G.rect(c, x + 6, y + h - 12, w - 12, 12, C.wood2);          // 툇마루
    G.rect(c, x + 6, y + 34, 9, h - 46, C.wood);                // 기둥
    G.rect(c, x + w - 15, y + 34, 9, h - 46, C.wood);

    this._roof(c, x, y, w, look.roof);

    // 간판 — 처마에 걸린 현판
    const sw = Math.min(w - 34, look.deco ? 126 : 112);
    const sh2 = look.deco ? 27 : 24;
    G.round(c, sl.cx - sw / 2, y + 30, sw, sh2, 6, shop.color);
    G.round(c, sl.cx - sw / 2, y + 30, sw, 4, 2, 'rgba(0,0,0,.18)');
    if (look.deco) {   // 칸을 다 열면 현판에 금테를 두른다
      c.strokeStyle = '#e0c073'; c.lineWidth = 1.6;
      c.beginPath(); c.roundRect(sl.cx - sw / 2 + 2, y + 32, sw - 4, sh2 - 4, 4); c.stroke();
    }
    G.text(c, `${shop.sign} ${shop.name}`, sl.cx, y + 30 + sh2 / 2,
      { size: look.deco ? 14 : 13.5, fill: '#fff8ec', weight: 800 });

    // 승급할 수 있으면 알려준다 — 이게 마을이 다 찬 뒤의 다음 목표다
    if (this.sim.canPromote(shop.id)) {
      const bob = Math.sin(this.t * 4) * 3;
      G.round(c, sl.cx - 40, y - 26 + bob, 80, 22, 8, '#c7563f');
      G.text(c, '승급 가능', sl.cx, y - 15 + bob, { size: 12, fill: '#fff3dd', weight: 800 });
    }

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
      G.text(c, this.sim.itemName(it.id), bx + bw / 2, by + 11,
        { size: 9, fill: C.ink2, weight: 800 });
      G.text(c, String(shown), bx + bw / 2, by + 30,
        { size: fl > 0 ? 15 : 13, fill: C.ink, weight: 800 });
    }

    // 잠긴 칸 — 다음에 뭘 열지가 여기서 보인다
    const locked = shop.items.filter((it) => !this.sim.isOpen(it.id));
    if (locked.length) {
      const askedNext = locked.find((it) => this.sim.asked.includes(it.id));
      G.text(c, askedNext ? `${this.sim.itemName(askedNext.id)} 칸 열 수 있음` : `${locked.length}칸 더 있다`,
        sl.cx, y + h - 5, { size: 10.5, fill: askedNext ? '#ffe9a8' : '#d8ccb0', weight: 800 });
    }
  }

  /**
   * 작은 건물 — 점포·주막·포장마차.
   * 큰 가게 사이가 휑해서 넣었다. 큰 가게보다 확실히 작고 낮아야
   * "저건 곁다리"라는 게 한눈에 읽힌다.
   */
  _small(c, i) {
    const { x, y } = SMALL_POS[i], w = SMALL_W, h = SMALL_H;
    const def = SMALL_SHOPS[i];
    const cx = x + w / 2;

    // 아직 안 세운 자리 — 빈터
    if (!this.sim.smalls.includes(i)) {
      c.save();
      c.setLineDash([7, 6]); c.lineWidth = 2; c.strokeStyle = 'rgba(60,52,36,.34)';
      c.beginPath(); c.roundRect(x + 4, y + 14, w - 8, h - 20, 8); c.stroke();
      c.restore();
      G.text(c, `${def.name} 자리`, cx, y + 34, { size: 11, fill: '#5f6b4e', weight: 800 });
      const can = this.sim.money >= def.cost;
      G.round(c, cx - 40, y + 44, 80, 21, 7, can ? C.jade : 'rgba(60,52,36,.30)');
      G.text(c, `${fmt(def.cost)}냥`, cx, y + 54.5,
        { size: 11, fill: can ? '#fff' : '#e6e0cf', weight: 800 });
      return;
    }

    const s = { ...SMALL_POS[i], k: def.k };
    c.fillStyle = 'rgba(0,0,0,.14)';
    c.beginPath(); c.ellipse(cx, y + h, w * 0.42, 8, 0, 0, 7); c.fill();

    if (this.sim.busy === i) {
      const bob = Math.sin(this.t * 5) * 4;
      G.glow(c, cx, y + 18, 46, 'rgba(255,214,120,.34)');
      G.round(c, cx - 30, y - 34 + bob, 60, 24, 9, '#c7563f');
      G.text(c, '장 서다!', cx, y - 22 + bob, { size: 12.5, fill: '#fff3dd', weight: 800 });
    }

    if (s.k === 'cart') {
      // 포장마차 — 천막 씌운 수레. 바퀴가 달려 있다.
      G.round(c, x + 10, y + 30, w - 20, h - 40, 4, C.paper);
      c.fillStyle = '#c0705a';                       // 천막
      c.beginPath();
      c.moveTo(x + 2, y + 30);
      c.quadraticCurveTo(cx, y + 2, x + w - 2, y + 30);
      c.lineTo(x + w - 2, y + 38);
      c.quadraticCurveTo(cx, y + 10, x + 2, y + 38);
      c.closePath(); c.fill();
      for (let k = 0; k < 4; k++) {                  // 천막 줄무늬
        G.round(c, x + 10 + k * 20, y + 12 + Math.abs(k - 1.5) * 5, 8, 22, 3, 'rgba(255,255,255,.20)');
      }
      for (const wx of [x + 22, x + w - 22]) {
        G.circle(c, wx, y + h - 6, 8, C.wood2);
        G.circle(c, wx, y + h - 6, 3.5, '#cbab7c');
      }
      G.text(c, '국밥', cx, y + 48, { size: 11, fill: C.ink2, weight: 800 });
      return;
    }

    // 점포·주막 공통 — 낮은 초가집
    G.round(c, x + 8, y + 24, w - 16, h - 30, 4, C.paper);
    G.rect(c, x + 8, y + h - 10, w - 16, 10, C.wood2);
    c.fillStyle = '#b39a63';
    c.beginPath();
    c.moveTo(x - 2, y + 22);
    c.quadraticCurveTo(cx, y + 34, x + w + 2, y + 22);
    c.lineTo(x + w + 2, y + 8);
    c.quadraticCurveTo(cx, y + 20, x - 2, y + 8);
    c.closePath(); c.fill();

    // 북적임 — 지금 누르면 장이 선다
    if (this.sim.busy === i) {
      const bob = Math.sin(this.t * 5) * 4;
      G.glow(c, cx, y + 18, 46, 'rgba(255,214,120,.34)');
      G.round(c, cx - 30, y - 34 + bob, 60, 24, 9, '#c7563f');
      G.text(c, '장 서다!', cx, y - 22 + bob, { size: 12.5, fill: '#fff3dd', weight: 800 });
    }

    if (s.k === 'inn') {
      // 주막 — 술 깃발과 평상에 앉은 손님
      G.rect(c, x + w - 6, y + 4, 3, 34, C.wood2);
      G.round(c, x + w - 4, y + 6, 20, 13, 2, '#c7563f');
      G.text(c, '酒', x + w + 6, y + 12.5, { size: 10, fill: '#fff3dd', weight: 800 });
      G.round(c, x + 12, y + h - 22, 34, 8, 3, C.wood);        // 평상
      G.text(c, '🐿️', x + 20, y + h - 30, { size: 14, fill: '#000' });
      G.text(c, '🦡', x + 38, y + h - 29, { size: 14, fill: '#000' });
      G.text(c, '주막', cx + 12, y + 44, { size: 11.5, fill: C.ink2, weight: 800 });
    } else {
      G.round(c, x + 16, y + 38, w - 32, 18, 4, C.paper2);      // 좌판
      for (let k = 0; k < 3; k++) G.circle(c, x + 26 + k * 17, y + 47, 5, '#b07f4a');
      G.text(c, '점포', cx, y + 30, { size: 11.5, fill: C.ink2, weight: 800 });
    }
  }

  _walker(c, w) {
    const bob = Math.sin(this.t * 9 * w.speed + w.bob) * (w.state === 'buy' ? 0.8 : 2.4);
    c.fillStyle = 'rgba(0,0,0,.17)';
    c.beginPath(); c.ellipse(w.x, w.y + 8, 11, 4.5, 0, 0, 7); c.fill();
    this._carry(c, w, bob);
    G.text(c, w.face, w.x, w.y - 8 + bob, { size: 27, fill: '#000' });

    /* 단골은 갓을 쓴다. 등급이 오를수록 갓이 커지고 색이 진해진다.
     * 손님 머리 위에 글자를 얹으면 여럿 몰릴 때 다시 겹치므로 모양으로 알린다. */
    if (w.reg > 0) {
      const y = w.y - 24 + bob, sw = 9 + w.reg * 2.2;
      const tone = ['', '#8a7a63', '#6d5236', '#3f3327', '#2b241b'][w.reg];
      G.round(c, w.x - sw, y, sw * 2, 3.5, 2, tone);          // 갓양태
      G.round(c, w.x - sw * 0.42, y - 6.5, sw * 0.84, 8, 3, tone);  // 갓모자
      if (w.reg >= 4) G.circle(c, w.x, y - 8.5, 2.4, '#e0c073');    // 터줏대감은 금관자
    }
  }

  /** 짐 — 많이 사가는 손님일수록 큰 걸 끌고 온다. 멀리서도 읽혀야 한다. */
  _carry(c, w, bob) {
    const x = w.x, y = w.y + bob * 0.4;
    if (w.carry === 'hand') return;
    if (w.carry === 'bojjim') {
      // 봇짐 — 보자기로 싸 등에 진 짐
      G.circle(c, x - 14, y - 13, 9.5, '#c07a56');
      G.round(c, x - 18.5, y - 24, 9, 7, 3, '#9c5c3c');
    } else if (w.carry === 'jige') {
      // 지게 — 나무 틀에 짐을 얹었다
      G.rect(c, x - 20, y - 28, 4, 28, C.wood2);
      G.rect(c, x - 12, y - 28, 4, 28, C.wood2);
      G.round(c, x - 24, y - 38, 22, 14, 4, '#bb8d55');
      G.round(c, x - 21, y - 47, 16, 10, 3, '#a1743f');
    } else {
      // 달구지 — 바퀴 달린 수레
      G.round(c, x - 38, y - 20, 28, 15, 3, '#a1743f');
      G.round(c, x - 35, y - 27, 22, 8, 3, '#bb8d55');
      G.rect(c, x - 13, y - 14, 9, 3.5, C.wood2);
      for (const wx of [x - 32, x - 16]) {
        G.circle(c, wx, y - 2, 6.5, C.wood2);
        G.circle(c, wx, y - 2, 3, '#cbab7c');
      }
    }
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
