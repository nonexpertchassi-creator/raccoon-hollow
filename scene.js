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
import { SHOPS, STOCK_CAP, SMALL_SHOPS, GUARD } from './content.js';
import { fmt, itemById } from './sim.js';
import { drawArt } from './art.js';

/* 보이는 창은 480×800이고, 마을은 그보다 세로로 길다. 손가락으로 밀어 훑는다.
 * 가게가 늘 때마다 화면에 욱여넣을 수 없어서 세로로 늘렸다. */
const W = 480, H = 1750;
const ROAD_W = 66;

/** 구불구불한 길. 이 한 줄이 "지도 느낌"의 가장 큰 원인을 없앤다. */
/* 휨을 24 → 18로 줄였다. 길이 가운데를 크게 흔들수록 양옆에 남는 폭이
 * 줄어드는데, 가게가 커지면서 그 폭이 모자랐다. 구불구불한 느낌은 남는다. */
const roadX = (y) => 240 + 18 * Math.sin(y / 175 + 0.6);

/* 가게 자리.
 * 좌우 번갈이를 일부러 깼다 — 지물포와 옹기점은 둘 다 왼쪽에 선다.
 * 폭도 제각각인데, 길이 오른쪽으로 휜 구간에서는 왼쪽에 자리가 더 남기
 * 때문이다. 길에 맞춰 자리를 잡으니 배치가 저절로 불규칙해진다. */
/* 높이를 150 → 192로 키웠다. 좌판을 **두 줄**로 놓기 위해서다.
 *
 * 한 줄에 네 칸을 넣으면 칸이 37px밖에 안 돼 글자가 폰에서 1.9mm가 된다.
 * 가게를 넓히려 했지만 길이 가운데를 지나 **2px밖에 안 남았다.**
 * 두 줄로 놓으면 칸 폭이 37 → 78로 두 배가 된다 — 넓이가 아니라 높이로 푼 것이다.
 *
 * 그 대신 마을이 1560 → 1900으로 길어졌다. 스와이프가 늘어나는 건 감수한다. */
const SLOTS = [
  { x: 300, y: 1528, w: 172, h: 192, side: 1 },   // 대장간
  { x: 12,  y: 1256, w: 160, h: 192, side: -1 },  // 필방
  { x: 12,  y: 984,  w: 168, h: 192, side: -1 },  // 지물포
  { x: 312, y: 712,  w: 160, h: 192, side: 1 },   // 옹기점
  { x: 304, y: 440,  w: 168, h: 192, side: 1 },   // 약재상
];

/* 작은 건물 — 큰 가게 사이를 채우는 점포·주막·포장마차.
 * 마을이 세로로 길어지면서 가게 사이가 휑해졌다. 자리는 길과 큰 가게를
 * 피해 계산으로 잡았다. */
const SMALL_W = 96, SMALL_H = 76;
/** content.js의 SMALL_SHOPS와 같은 순서·같은 개수여야 한다.
 *  점포를 오른쪽 1270에 뒀더니 '장 서다!' 표시가 필방 글자를 가려 옮겼다. */
/* 가게 **맞은편**에 놓는다. 가게와 가게 사이(80px)에 끼워 넣었더니
 * 위 가게 점장이 서는 자리(가게 아래 15px)를 깔고 앉았다. */
const SMALL_POS = [
  { x: 368, y: 1300 },   // 필방 맞은편
  { x: 368, y: 1030 },   // 지물포 맞은편
  { x: 16,  y: 760 },    // 옹기점 맞은편
  { x: 16,  y: 480 },    // 약재상 맞은편
];

/* 삽살개 집 — 대장간 맞은편. 처음 켰을 때 화면에 바로 들어와야
 * "저게 뭐지"가 된다. */
const DOG = { x: 16, y: 1560, w: 84, h: 60 };

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
/* 주인공 너구리.
 *
 * 게임 이름이 '너구리 만물상'인데 화면에 너구리가 없었다. 손님과 물건과
 * 도둑만 있고 주인이 없으니, 이 마을이 누구 것인지가 안 보인다.
 *
 * 한 마리만 둔다. 가게마다 하나씩 세우면 '내 분신'이 아니라 '점원'이 되고,
 * 다섯이 동시에 같은 짓을 하면 오히려 아무도 주인공이 아니게 된다.
 * (가게별 점원은 나중에 고용으로 넣을 자리다.)
 *
 * 두 가지 모습이 있다:
 *   만드는 중  손님이 없을 때. 좌판 옆에서 두드린다
 *   파는 중    그 가게에 손님이 서 있을 때. 손님 쪽으로 돌아서 건넨다
 * 둘 다 sim이 이미 아는 상태라 새로 계산할 게 없다 — 화면 몫이다.
 */
/* 손님이 가게 앞에서 보내는 시간.
 *
 * 예전엔 도착하자마자(0.7초) 재고가 빠지고 엽전이 튀고 떠났다 —
 * "명령 주입된 손님이 호다닥 사간다"는 느낌이었다. 장사가 아니라 자판기다.
 *
 * 세 박자로 나눴다:
 *   0.0초  도착. 무엇을 얼마나 살지 말풍선을 띄운다 (주문)
 *   1.1초  주인 너구리가 건넨다. 이때 재고가 빠지고 엽전이 튄다
 *   2.3초  짐을 지고 떠난다
 *
 * 걸음도 155 → 95로 늦췄다. 손님 수가 아니라 **한 명이 오래 머무는 것**이
 * 마을을 붐비게 만든다. */
const BUY_TIME = 2.3;        // 가게 앞에 서 있는 총 시간
const HAND_OVER = 1.1;       // 이 시점에 물건이 건네진다
const WALK_IN = 95, WALK_SIDE = 105, WALK_OUT = 92;

const CLERK_PX = 33;         // 손님과 같은 크기. 마을 사람들이니까
const CLERK_SPEED = 130;     // 손님이 서 있는 2.3초 안에 반드시 닿아야 한다
const HERO_SPEED = 120;

/* 가게 앞에 둘이 선다.
 *
 *   점장   가게마다 한 마리. 만들고 · 팔고 · 존다
 *   손님   길 쪽(0.74/0.26)에 잠깐 선다
 *
 * 예전엔 '사장 너구리' 한 마리가 마을을 돌며 팔았다. 뺐다 —
 * **사장은 플레이어다.** 화면 밖에서 마을을 보고 있는 사람이 곧 사장인데,
 * 그 사람의 분신이 필드를 종종거리면 내가 둘이 되는 셈이다. 게다가
 * 초당 0.9건씩 팔리니 어느 가게에도 제때 못 닿아, 하는 일 없이 왔다
 * 갔다만 했다.
 *
 * 이제 파는 것도 그 가게 점장이 한다. 점장은 자리를 두 개 오간다:
 *
 *   작업대 자리  가게 안쪽 (0.18/0.82)   평소
 *   손님 자리    (0.52/0.48)             손님이 오면 몇 걸음 나온다
 *
 * 손님(0.74)까지 41px쯤 남는다 — 물건을 건네는 거리로 딱 맞고 안 겹친다. */
function workSpot(i) {
  const s = SLOTS[i];
  return { x: s.x + s.w * (s.side < 0 ? 0.18 : 0.82), y: s.y + s.h + 15 };
}
function serveSpot(i) {
  const s = SLOTS[i];
  return { x: s.x + s.w * (s.side < 0 ? 0.52 : 0.48), y: s.y + s.h + 18 };
}

/* 화면에 보이는 손님 크기. 임시 토끼 한 장을 넣고 폰 크기로 확인해서 정했다 —
 * 27은 장승 머리보다 작아 캐릭터로 안 읽혔다. 그림이 들어오면 여기만 고친다. */
const GUEST_PX = 33;

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
    /* 점장은 가게마다 한 마리. 자기 가게를 안 떠난다. */
    this.mgr = SHOPS.map((_, i) => ({ ...workSpot(i), at: 'work' }));
    /* 가게별로 '방금 팔렸다'가 몇 초 남았나.
     * 손님이 서 있는 0.7초만 보고 너구리를 보내려 했더니 **한 번도 도착을
     * 못 했다** — 걸어가는 동안 손님이 이미 떠난다. 그래서 손님이 아니라
     * 거래의 여운을 쫓아가게 했다. */
    this.busyShop = {};
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
    const gy = 1726, gx = roadX(gy);
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
    /* 걸음을 늦추고 머무는 시간을 늘렸으니 한 명이 화면에 오래 남는다.
     * 그만큼 자리를 늘려야 거래가 안 잘린다 — 실측 판매가 초당 0.93건이고
     * 한 명이 10~12초 머무르므로 열 자리면 열에 아홉은 보인다.
     * 넘치면 그 거래는 화면에 안 나온다(계산은 이미 끝났다).
     *
     * 실측으로 맞췄다 — 열 자리로는 78%만 나왔다. 열넷이면 거의 다 나오고,
     * 마을 세로 1560 중 절반쯤만 보이므로 한 화면에는 예닐곱만 잡힌다. */
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

    // 들어온 쪽에서 가까운 가게부터 차례로 들르고, 그대로 반대편으로 빠져나간다.
    // 왔던 길을 되돌아가는 것보다 마을을 훑고 지나가는 게 자연스럽다.
    const avgY = stops.reduce((a, x) => a + SLOTS[x.idx].y, 0) / stops.length;
    const fromTop = avgY < H / 2;
    stops.sort((a, b) => fromTop ? SLOTS[a.idx].y - SLOTS[b.idx].y
                                 : SLOTS[b.idx].y - SLOTS[a.idx].y);

    const y = fromTop ? -30 : H + 30;
    this.walkers.push({
      id: sale.guest.id,
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
      /* 끝에 붙어 있었으면 끝에 그대로 붙여 둔다. 가운데를 붙잡는 것만
       * 하면 마을 어귀를 보고 있다가 창이 바뀔 때 어귀에서 밀려난다 —
       * 처음 켤 때가 정확히 그 경우다(버튼 줄이 채워지며 창이 줄어든다). */
      const wasBottom = this.cam >= this.camMax() - 2;
      const wasTop = this.cam <= 2;
      const center = this.cam + this.viewH / 2;
      this.viewH = viewH;
      this.cam = wasBottom ? this.camMax() : wasTop ? 0 : center - viewH / 2;
      this.vel = 0;
    }
    this.t += dt;
    if (this.bubble) { this.bubble.t -= dt; if (this.bubble.t <= 0) this.bubble = null; }

    for (const w of this.walkers) {
      const stop = w.stops[w.si];
      if (w.state === 'in' && stop) {
        const sl = slotOf(stop.idx);
        const dy = sl.standY - w.y;
        w.y += Math.sign(dy) * Math.min(Math.abs(dy), WALK_IN * w.speed * dt);
        // 멀리 있을 땐 구부러진 길을 따라가고, 가까워지면 가게 앞으로 꺾는다
        const tx = Math.abs(dy) < 130 ? sl.standX : roadX(w.y) + w.lane;
        const dx = tx - w.x;
        w.x += Math.sign(dx) * Math.min(Math.abs(dx), WALK_SIDE * w.speed * dt);
        if (Math.abs(dy) < 3 && Math.abs(sl.standX - w.x) < 3) {
          /* 도착 = 주문. 물건은 아직 안 넘어간다. */
          w.state = 'buy'; w.wait = BUY_TIME; w.paid = false;
          this.busyShop[stop.idx] = BUY_TIME + 1.2;   // 주인이 걸어올 시간까지
        }
      } else if (w.state === 'buy') {
        w.wait -= dt;
        if (!w.paid && w.wait <= BUY_TIME - HAND_OVER) {
          /* 건네는 순간 — 여기서야 재고가 빠지고 엽전이 튄다.
           * 도착 즉시 처리하면 "주문했는데 이미 받아 갔다"가 된다. */
          w.paid = true;
          for (const s of stop.sold) {
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
        if (w.wait <= 0) { w.si++; w.state = w.si < w.stops.length ? 'in' : 'out'; }
      } else {
        w.y += WALK_OUT * w.speed * dt * w.exit;
        const back = roadX(w.y) + w.lane - w.x;
        w.x += Math.sign(back) * Math.min(Math.abs(back), 120 * dt);
      }
    }
    this.walkers = this.walkers.filter((w) => w.y > -90 && w.y < H + 90);
    this._mgr(dt);

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
    if (this.cam < 0) { this.cam = 0; this.vel = 0; }
  }

  /** 이 가게가 지금 화면 어디에 있나. 들어갈 때 거기서 방이 부풀어 오른다. */
  shopScreenPos(i) {
    const s = SLOTS[i];
    return { x: s.x + s.w / 2, y: s.y + s.h / 2 - this.cam };
  }

  /** 밀 수 있는 최대 거리. 창이 마을보다 크면 0 — 밀 것이 없다. */
  camMax() { return Math.max(0, H - this.viewH); }

  _tap(wx, wy) {
    /* 나쁜 놈이 제일 급하다. 몇 초 안에 사라지므로 무엇보다 먼저 본다.
     * 손가락은 뭉툭하고 놈들은 뛰거나 날고 있으니 판정을 넉넉히 준다. */
    const th = this._pestAt();
    if (th && Math.hypot(wx - th.x, wy - th.y + 6) < th.r) {
      const got = this.sim.catchPest();
      if (got) {
        Sfx.win(); Juice.shake(7);
        for (let i = 0; i < 6; i++) {
          this.coins.push({
            x: th.x + (Math.random() - 0.5) * 14, y: th.y - 8,
            vx: (Math.random() - 0.5) * 90, vy: -95 - Math.random() * 45,
            t: 1.2, r: 9 + Math.random() * 3,
          });
        }
        return;
      }
    }

    if (!this.sim.guard && wx > DOG.x - 8 && wx < DOG.x + DOG.w + 8
        && wy > DOG.y - 8 && wy < DOG.y + DOG.h + 8) {
      if (this.sim.buyGuard()) { Sfx.reward(); Juice.shake(5); } else Sfx.deny();
      return;
    }

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
    if (near(DOG.y, DOG.h + 40)) layer.push({ z: DOG.y + DOG.h, d: () => this._dog(c) });
    for (const p of this.props) if (near(p.y, 60)) layer.push({ z: p.y, d: () => this._prop(c, p) });
    for (const w of this.walkers) if (near(w.y, 40)) layer.push({ z: w.y, d: () => this._walker(c, w) });
    /* 말풍선은 깊이 정렬 밖에 둔다 — 앞에 선 것에 가려지면 읽을 수가 없다. */
    for (const w of this.walkers) {
      if (w.state === 'buy' && !w.paid && near(w.y, 60)) {
        layer.push({ z: 9e8, d: () => this._order(c, w) });
      }
    }
    for (let i = 0; i < SHOPS.length; i++) {
      const k = this._clerk(i);
      if (k && near(k.y, 40)) layer.push({ z: k.y, d: () => this._clerkDraw(c, k) });
    }

    const th = this._pestAt();
    /* 까마귀는 하늘에 있으니 무엇에도 안 가린다. 쥐는 발끝 높이로 줄을 선다. */
    if (th && th.kind === 'crow') layer.push({ z: 1e9, d: () => this._pest(c, th) });
    else if (th && near(th.y, 40)) layer.push({ z: th.y + 1, d: () => this._pest(c, th) });
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
    /* 등급(돌·쇠·강철)을 현판으로 옮겼다. 예전엔 좌판마다 '쇠곡괭이'처럼
     * 앞에 붙였는데, 대장간 칸 하나가 37px밖에 안 돼 네 글자를 넣으려면
     * 글자가 9px까지 내려간다 — 폰에서 1.9mm다. 등급은 가게마다 하나이니
     * 현판에 한 번만 적으면 된다. */
    const rk = this.sim.rankOf(shop.id);
    const sTxt = rk > 0 ? `${shop.sign} ${shop.name} · ${shop.ranks[rk]}`
                        : `${shop.sign} ${shop.name}`;
    G.text(c, sTxt, sl.cx, y + 30 + sh2 / 2,
      { size: look.deco ? 15 : 14.5, fill: '#fff8ec', weight: 800 });

    /* 들어가서 할 일이 있으면 표를 띄운다.
     *
     * 이게 있어야 "혹시 뭐 생겼나" 하고 가게마다 들락거리지 않는다.
     * 표가 없으면 안 들어가도 되는 것이고, 그게 들락날락하는 수고를
     * 없애는 유일한 방법이다. 강화는 안 센다 — 늘 할 수 있어서 표가
     * 항상 켜져 있게 되고, 항상 켜진 표는 없는 것과 같다. */
    const todo = this.sim.shopTodo(shop.id);
    if (todo > 0) {
      const bob = Math.sin(this.t * 4) * 3;
      const promo = this.sim.canPromote(shop.id);
      /* 문구가 중요하다. 처음엔 "2가지 할 일"이라고 적었는데 그건 숙제다 —
       * 일일 던전이 사람을 떠나게 하는 게 정확히 그 느낌이다. 표는 **덜
       * 들여다보라고** 만든 것이지 시키려고 만든 게 아니다.
       * 그래서 개수가 아니라 **뭐가 좋은지**를 적는다. 초대장에 가깝게.
       *
       * 그리고 이건 **사라지지 않는다.** 일일 던전이 의무가 되는 이유는
       * 놓치면 손해가 나기 때문이다. 여기선 언제 들어가도 그대로 있다. */
      const txt = promo ? '승급!' : '새 칸!';
      const tw = 26 + txt.length * 13;
      G.round(c, sl.cx - tw / 2, y - 28 + bob, tw, 25, 9, promo ? '#c7563f' : C.jade);
      G.text(c, txt, sl.cx, y - 15.5 + bob, { size: 14, fill: '#fff3dd', weight: 800 });
    }

    /* 좌판 — 열린 품목마다 한 칸. **두 줄까지 쓴다.**
     *
     * 한 줄에 네 칸을 넣던 시절 대장간 칸이 37px이었다. 거기에 물건 이름을
     * 넣으면 폰에서 글자가 1.9mm가 된다. 가게를 넓혀 풀려 했지만 길이
     * 가운데를 지나 2px밖에 안 남았다 — **넓이가 아니라 높이로 풀었다.**
     * 두 칸씩 두 줄이면 칸 폭이 37 → 73이다. 마을이 1560 → 1750으로
     * 길어졌지만 스와이프가 조금 느는 건 감수한다. */
    const items = shop.items.filter((it) => this.sim.isOpen(it.id));
    const cols = Math.min(2, items.length);
    const rows = Math.ceil(items.length / cols);
    const gap = 6;
    const inner = w - 24;
    const areaY = y + 60, areaH = h - 78;
    const bw = (inner - (cols - 1) * gap) / cols;
    const bh = (areaH - (rows - 1) * gap) / rows;

    for (let k = 0; k < items.length; k++) {
      const it = items[k];
      const r = Math.floor(k / cols), cIdx = k % cols;
      // 마지막 줄이 덜 찼으면 가운데로 모은다. 왼쪽에 붙이면 빈칸이 눈에 띈다.
      const inRow = Math.min(cols, items.length - r * cols);
      const rowW = inRow * bw + (inRow - 1) * gap;
      const bx = x + 12 + (inner - rowW) / 2 + cIdx * (bw + gap);
      const by = areaY + r * (bh + gap);

      const fl = this.flash[it.id] || 0;
      G.round(c, bx, by, bw, bh, 6, fl > 0 ? '#f2e5b6' : C.paper2);
      const st = this.sim.items[it.id];
      // 걸어오는 중인 몫을 도로 더한다 — 손님이 닿아야 숫자가 떨어진다
      const shown = Math.min(STOCK_CAP, st.stock + (this.pending[it.id] || 0));
      const fillH = Math.round((bh - 4) * Math.min(1, shown / STOCK_CAP));
      if (fillH > 0) G.round(c, bx + 2, by + bh - 2 - fillH, bw - 4, fillH, 4, shop.color);

      /* 물건 그림은 재고 막대 위, 숫자 아래에 깔린다.
       * 등급(돌·쇠·강철)마다 따로 그리면 17장이 51장이 된다 —
       * 그림은 한 장만 두고 등급은 현판이 알린다. */
      drawArt(c, 'items', it.id, bx + bw * 0.5, by + bh - 4, bw * 0.62, bh * 0.72);

      const nm = itemById(it.id).name;
      G.text(c, nm, bx + bw / 2, by + 11,
        { size: Math.min(14, (bw - 6) / Math.max(2, nm.length)),
          fill: C.ink2, weight: 800 });

      /* 다음 한 개가 나오기까지 — 숫자를 두른 고리가 채워진다.
       * 한 칸이 두 가지를 같이 보여준다:
       *   가운데 숫자 = 지금 쌓인 개수    고리 = 다음 개까지 남은 정도
       * 꽉 차면 sim이 생산을 멈추므로 고리도 저절로 멈춘다. */
      /* 고리가 이름 글자를 먹지 않게 아래로 내려 앉힌다. 처음엔 0.62에
       * 두었더니 '붓'이 '부'로, '먹'이 '머'로 보였다. */
      const cxk = bx + bw / 2, cyk = by + bh * 0.66;
      const rr = Math.min(16, bw / 2 - 6, bh * 0.28);
      const capped = shown >= STOCK_CAP;
      /* 막힌 칸은 **빨간 고리를 한 바퀴 다** 그린다 — 하필 거의 빈 채로
       * 멈추면 '멈췄다'가 아니라 '방금 시작했다'로 보인다. */
      const p = capped ? 1
        : Math.max(0, Math.min(1, st.prog / this.sim.craftTime(it.id)));
      c.save();
      c.lineWidth = 3.5;
      c.lineCap = 'round';
      /* 바탕 고리를 진하게 깐다. 옅게 두면 좌판이 찼을 때 주황 위에서
       * 고리가 통째로 사라진다 — 배경이 매번 바뀌는 자리라서 그렇다. */
      c.strokeStyle = 'rgba(43,36,27,.32)';
      c.beginPath(); c.arc(cxk, cyk, rr, 0, Math.PI * 2); c.stroke();
      if (p > 0.01) {
        c.strokeStyle = capped ? '#ff8a63' : '#f2d878';
        c.beginPath();
        c.arc(cxk, cyk, rr, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p);
        c.stroke();
      }
      c.restore();

      G.text(c, String(shown), cxk, cyk,
        { size: fl > 0 ? 21 : 19, fill: C.ink, weight: 800 });
    }

    // 잠긴 칸 — 다음에 뭘 열지가 여기서 보인다
    const locked = shop.items.filter((it) => !this.sim.isOpen(it.id));
    if (locked.length) {
      const askedNext = locked.find((it) => this.sim.asked.includes(it.id));
      G.text(c, askedNext ? `${this.sim.itemName(askedNext.id)} 칸 열 수 있음` : `${locked.length}칸 더 있다`,
        sl.cx, y + h - 5, { size: 12, fill: askedNext ? '#ffe9a8' : '#d8ccb0', weight: 800 });
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

  /** 나쁜 놈이 지금 화면 어디쯤 있나.
   *  sim은 '몇 초 남았다'만 들고 있다. 어디서 어디로 가는지는 화면 몫이다.
   *  둘은 **다르게** 움직인다 — 쥐는 땅을 뛰고 까마귀는 하늘을 가로지른다. */
  /** 삽살개 집. 안 들였으면 빈터로 값을 보여준다 — 작은 건물과 같은 규칙이다. */
  _dog(c) {
    const { x, y, w, h } = DOG, cx = x + w / 2;
    if (!this.sim.guard) {
      c.save();
      c.setLineDash([7, 6]); c.lineWidth = 2; c.strokeStyle = 'rgba(60,52,36,.34)';
      c.beginPath(); c.roundRect(x + 4, y + 12, w - 8, h - 18, 8); c.stroke();
      c.restore();
      G.text(c, '삽살개 자리', cx, y + 30, { size: 11, fill: '#5f6b4e', weight: 800 });
      const can = this.sim.money >= GUARD.cost;
      G.round(c, cx - 38, y + 38, 76, 21, 7, can ? C.jade : 'rgba(60,52,36,.30)');
      G.text(c, `${fmt(GUARD.cost)}냥`, cx, y + 48.5,
        { size: 11, fill: can ? '#fff' : '#e6e0cf', weight: 800 });
      return;
    }
    c.fillStyle = 'rgba(0,0,0,.14)';
    c.beginPath(); c.ellipse(cx, y + h, w * 0.38, 7, 0, 0, 7); c.fill();

    // 개집 — 흙벽에 기와를 얹은 작은 것
    G.round(c, x + 12, y + 24, w - 24, h - 26, 4, '#dccfb2');
    c.fillStyle = C.tile;                                  // 지붕
    c.beginPath();
    c.moveTo(x + 4, y + 26); c.lineTo(cx, y + 8); c.lineTo(x + w - 4, y + 26);
    c.closePath(); c.fill();
    G.circle(c, cx, y + 42, 11, '#2b241b');                // 드나드는 구멍

    /* 개는 집 앞에 앉아 있다. 나쁜 놈이 나오면 일어나 그쪽을 본다 —
     * 지금 지켜주고 있다는 걸 글자 없이 알린다. */
    const alert = !!this.sim.pest;
    const bob = alert ? Math.abs(Math.sin(this.t * 12)) * 3 : Math.sin(this.t * 2) * 1.2;
    if (!drawArt(c, 'pests', 'dog', x + 16, y + h + 8 - bob, 24, 24))
      G.text(c, '🐕', x + 16, y + h - 4 - bob, { size: 24, fill: '#000' });
    if (alert) {
      G.round(c, x + 2, y + h - 34, 22, 15, 6, '#c7563f');
      G.text(c, '멍!', x + 13, y + h - 26, { size: 9.5, fill: '#fff3dd', weight: 800 });
    }
  }

  _pestAt() {
    const t = this.sim.pest;
    if (!t) return null;
    const p = 1 - Math.max(0, t.left) / t.life;      // 0=나타났다 1=사라진다

    if (t.kind === 'crow') {
      /* 까마귀는 길도 건물도 무시한다. **보이는 화면을 가로질러** 날게 해서
       * 마을 어디를 보고 있든 항상 눈에 들어오게 만든다. 쥐처럼 가게에
       * 묶어 두면 다른 데를 보고 있을 때 아예 못 본다. */
      const dir = t.amount % 2 ? 1 : -1;             // 어느 쪽에서 오는지
      /* 일정한 속도로 지나가면 시간의 절반을 화면 밖에서 쓴다 — 4초를 줘도
       * 실제로 누를 수 있는 건 3.4초다. 들어올 땐 빠르게, 가운데선 천천히
       * 맴돌다, 나갈 때 다시 빠르게. 새가 엽전을 노리는 모양이기도 하다. */
      const u = p * 2 - 1;
      const e = 0.5 + 0.5 * (u * 0.3 + u * u * u * 0.7);
      const x = dir > 0 ? -40 + e * 560 : 520 - e * 560;
      return {
        kind: 'crow', face: '🐦‍⬛',
        x, y: this.cam + this.viewH * 0.3 + Math.sin(p * Math.PI * 2.4) * 46,
        p, left: t.left, life: t.life, r: 30, flip: dir < 0,
      };
    }

    const idx = SHOPS.findIndex((sh) => sh.items.some((it) => it.id === t.itemId));
    const sl = slotOf(idx < 0 ? 0 : idx);
    /* 마을 안쪽으로 달아난다. 마을 끝으로 보내면 대장간처럼 가장자리에 붙은
     * 가게에서는 화면 밖으로 반쯤 잘린 채 서 있다 — 누를 수가 없다. */
    const dir = sl.standY > H / 2 ? -1 : 1;
    const ey = sl.standY + dir * 240;
    return {
      kind: 'rat', face: '🐀',
      x: sl.standX + (roadX(sl.standY) - sl.standX) * Math.min(1, p * 2.2),
      y: sl.standY + (ey - sl.standY) * p,
      p, left: t.left, life: t.life, r: 32, flip: false,
    };
  }

  _pest(c, t) {
    const fly = t.kind === 'crow';
    const bob = fly ? Math.sin(this.t * 11) * 5 : Math.abs(Math.sin(this.t * 16)) * 4;
    /* 남은 시간 고리 — 몇 초 안에 눌러야 하는지가 안 보이면 그냥 지나친다 */
    const r = fly ? 27 : 25;
    c.save();
    /* 뒤에 옅은 판을 깔지 않으면 건물이나 나무 앞에서 묻힌다 */
    G.circle(c, t.x, t.y - 6, r - 3, 'rgba(255,246,232,.55)');
    c.lineWidth = 4;
    c.strokeStyle = 'rgba(163,74,58,.28)';
    c.beginPath(); c.arc(t.x, t.y - 6, r, 0, 7); c.stroke();
    c.strokeStyle = '#a34a3a';
    c.beginPath();
    c.arc(t.x, t.y - 6, r, -Math.PI / 2, -Math.PI / 2 + 7 * (t.left / t.life));
    c.stroke();
    c.restore();

    if (fly) {
      // 나는 놈은 그림자가 땅에 안 붙는다. 대신 아래로 옅게 깔아 높이를 알린다
      c.fillStyle = 'rgba(0,0,0,.10)';
      c.beginPath(); c.ellipse(t.x, t.y + 34, 13, 4, 0, 0, 7); c.fill();
    } else {
      c.fillStyle = 'rgba(0,0,0,.17)';
      c.beginPath(); c.ellipse(t.x, t.y + 7, 10, 4, 0, 0, 7); c.fill();
      G.circle(c, t.x + 11, t.y - 10 - bob * 0.4, 7, '#a34a3a');   // 훔친 보따리
    }
    if (!drawArt(c, 'pests', t.kind, t.x, t.y + 8 - bob, 30, 30))
      G.text(c, t.face, t.x, t.y - 7 - bob, { size: 30, fill: '#000' });
    if (fly) {
      // 물고 가는 엽전
      G.circle(c, t.x + 12, t.y + 2 - bob, 5.5, '#c9a227');
      G.rect(c, t.x + 10, t.y - bob, 4, 4, '#8a6a45');
    }
  }

  /** 점장 너구리를 움직인다.
   *
   *  손님이 오면 몇 걸음 나가 건네주고, 가면 작업대로 돌아간다.
   *  손님이 서 있는 시간이 2.3초, 건네는 건 1.1초 시점 — 64px를 130px/s로
   *  가면 0.5초라 **항상 제때 닿는다.** 예전 사장 너구리는 마을 반대편에서
   *  출발하느라 한 번도 제때 못 닿았고, 그래서 '파는 중' 자세가 실제로는
   *  화면에 나온 적이 없었다.
   */
  _mgr(dt) {
    for (let i = 0; i < SHOPS.length; i++) {
      const m = this.mgr[i];
      const serving = (this.busyShop[i] || 0) > 0;
      const t = serving ? serveSpot(i) : workSpot(i);
      const dx = t.x - m.x, dy = t.y - m.y;
      const d = Math.hypot(dx, dy);
      if (d > 1.5) {
        const step = Math.min(d, CLERK_SPEED * dt);
        m.x += dx / d * step; m.y += dy / d * step;
        m.at = 'walk';
      } else {
        m.x = t.x; m.y = t.y;
        m.at = serving ? 'serve' : 'work';
      }
    }
  }

  /** 점장의 지금 모습. **sim이 이미 아는 사실만 읽는다.**
   *
   *  세 가지다:
   *    팖    손님이 와 있다 — 몇 걸음 나가 건넨다
   *    만듦  평소 — 작업대 옆에서 느긋하게
   *    졺    진열대가 꽉 차 생산이 실제로 멈췄다(`stock >= STOCK_CAP`)
   *
   *  조는 건 귀여우라고 재우는 게 아니다. **정말로 노는 중**인데 그 사실이
   *  화면에 안 보여서 유저가 어느 칸이 막혔는지 몰랐다.
   */
  _clerk(i) {
    const shop = SHOPS[i];
    if (!this.sim.shops.includes(shop.id)) return null;
    const open = shop.items.filter((it) => this.sim.isOpen(it.id));
    if (!open.length) return null;
    const m = this.mgr[i];
    const full = open.every((it) => this.sim.items[it.id].stock >= STOCK_CAP);
    const mode = m.at === 'serve' ? 'sell' : m.at === 'walk' ? 'walk' : full ? 'sleep' : 'work';
    return { i, mode, x: m.x, y: m.y };
  }

  _clerkDraw(c, k) {
    const shop = SHOPS[k.i];
    const face = -SLOTS[k.i].side;                  // 길 쪽(손님 쪽)을 본다
    /* 느긋한 한 박자. 예전엔 실제 제작 주기(1.2~3.6초)에 맞춰 두드리게 했는데,
     * 정확하긴 해도 **캐릭터에게 계기판을 시킨 것**이었다. 정확한 진행은
     * 좌판의 고리가 맡는다. 여기서는 "일하고 있다"만 알리면 된다.
     * 가게마다 위상을 어긋나게 둔다 — 다섯이 딱딱 맞으면 기계처럼 보인다. */
    const ph = (this.t / 2.4 + k.i * 0.37) % 1;
    const swing = Math.max(0, Math.sin(ph * Math.PI * 2));
    const bob = k.mode === 'work' ? swing * 3
              : k.mode === 'walk' ? Math.abs(Math.sin(this.t * 10)) * 3
              : k.mode === 'sell' ? Math.sin(this.t * 3) * 1.4
              : 0;

    c.fillStyle = 'rgba(0,0,0,.15)';
    c.beginPath(); c.ellipse(k.x, k.y + 2, 10, 4, 0, 0, 7); c.fill();

    if (k.mode === 'work' || k.mode === 'sleep') {
      // 모루 — 무슨 일을 하는지는 도구가 아니라 작업대가 알린다
      const ax = k.x + face * 13;
      G.round(c, ax - 6, k.y - 8, 12, 4.5, 2, '#6b6257');
      G.round(c, ax - 2.5, k.y - 4, 5, 5, 1, '#57504a');
      G.round(c, ax - 5, k.y + 1, 10, 2.5, 1, '#4a4139');
      if (k.mode === 'work' && swing > 0.96) for (let j = 0; j < 3; j++) {
        G.circle(c, ax + (j - 1) * 4, k.y - 11 - (j === 1 ? 3 : 0), 1.7, '#f0d98b');
      }
    }
    if (k.mode === 'sell') {
      /* 파는 그림은 앞발을 확실히 내밀고 있어서 여기엔 물건이 붙는다.
       * 눈금으로 잰 자리가 (60,38)/72다. 선 자세 그림에는 못 붙인다 —
       * 망치를 쥐여 주려다 세 번 실패하고 배웠다. */
      const px = k.x + face * (CLERK_PX * (60 / 72 - 0.5));
      const py = k.y + 4 - CLERK_PX + CLERK_PX * (38 / 72);
      G.circle(c, px, py - bob, 5.5, '#c9a227');
      G.round(c, px - 2, py - bob - 6.5, 4, 4, 1, '#8a6a45');
    }

    c.save();
    c.translate(k.x, k.y + 4);                       // 발끝을 원점으로
    if (face < 0) c.scale(-1, 1);
    /* 뒤뚱뒤뚱 — **그림 한 장으로 만든다.**
     *
     * 걷는 그림을 여러 장 그리는 대신 몸통을 좌우로 ±6도 기울인다.
     * 꼬리만 흔드는 것보다 훨씬 세게 읽힌다 — 뒤뚱거림의 정체가
     * 사실 '무게중심이 좌우로 넘어가는 것'이라 몸 전체가 기울어야 한다.
     * 위아래 들썩임과 반박자 어긋나게 두면 두 발로 걷는 것처럼 보인다.
     *
     * 걷는 그림(-walk1/-walk2)이 들어오면 아래에서 저절로 두 장을 번갈아
     * 쓰고, 기울기는 그대로 얹힌다. 두 장이면 충분하다. */
    if (k.mode === 'walk') c.rotate(Math.sin(this.t * 9) * 0.11);

    /* 그림 찾는 순서: 가게 전용 → 공용 너구리 → 이모지.
     * 그래서 대장간 것만 먼저 그려 넣어도 나머지는 안 깨진다. */
    const step = Math.sin(this.t * 9) > 0 ? 1 : 2;
    const names = k.mode === 'sell' ? [`${shop.id}-sell`]
      : k.mode === 'sleep' ? [`${shop.id}-sleep`]
      : k.mode === 'walk' ? [`${shop.id}-walk${step}`, `${shop.id}-walk1`,
                             `${shop.id}-idle`, `${shop.id}-work`]
      : [`${shop.id}-work`];
    let drawn = false;
    for (const n of names) {
      if (drawArt(c, 'clerks', n, 0, -bob, CLERK_PX, CLERK_PX)) { drawn = true; break; }
    }
    if (!drawn
     && !drawArt(c, 'hero', k.mode === 'sell' ? 'raccoon-sell' : 'raccoon-make',
                 0, -bob, CLERK_PX, CLERK_PX))
      G.text(c, '🦝', 0, -13 - bob, { size: CLERK_PX, fill: '#000' });
    c.restore();

    if (k.mode === 'sleep') {
      // 조는 표시 — 이건 "진열대가 꽉 찼다"는 알림이기도 하다
      const z = (this.t * 0.6) % 1;
      G.text(c, '💤', k.x + face * 11, k.y - 26 - z * 9, { size: 11 + z * 3, fill: '#000' });
    }
  }

  /** 주문 말풍선 — 도착해서 물건을 받기 전까지 머리 위에 뜬다.
   *
   *  이게 있어야 '주문 → 제작·전달'이라는 순서가 읽힌다. 없으면 손님이
   *  가게 앞에 잠깐 멈췄다 가는 것으로만 보인다.
   *
   *  글자는 개수만 적는다. 품목 이름까지 넣으면 손님이 몰릴 때 서로 겹친다 —
   *  예전에 금액 글자로 똑같은 실수를 했다. */
  _order(c, w) {
    const stop = w.stops[w.si];
    if (!stop) return;
    const n = stop.sold.reduce((a, s) => a + s.n, 0);
    const kinds = stop.sold.length;
    const txt = kinds > 1 ? `${n}개 · ${kinds}종` : `${n}개`;
    const tw = 12 + txt.length * 7.2;
    /* 가게 반대쪽(길 쪽)으로 비껴 띄운다. 머리 바로 위에 두면 좌판 칸을
     * 가려서 재고 숫자가 안 보인다. */
    const away = -SLOTS[stop.idx].side;
    const bx = w.x + away * 20, by = w.y - 38 + Math.sin(this.t * 3.4) * 1.6;
    G.round(c, bx - tw / 2, by - 11, tw, 19, 7, 'rgba(252,246,232,.96)');
    c.fillStyle = 'rgba(252,246,232,.96)';
    c.beginPath();
    const tipX = bx - away * 12;                       // 꼬리는 손님 쪽을 가리킨다
    c.moveTo(tipX - 4, by + 7); c.lineTo(tipX - away * 2, by + 13); c.lineTo(tipX + 4, by + 7);
    c.closePath(); c.fill();
    G.text(c, txt, bx, by - 1, { size: 12.5, fill: C.ink, weight: 800 });
  }

  _walker(c, w) {
    const bob = Math.sin(this.t * 9 * w.speed + w.bob) * (w.state === 'buy' ? 0.8 : 2.4);
    c.fillStyle = 'rgba(0,0,0,.17)';
    c.beginPath(); c.ellipse(w.x, w.y + 8, 11, 4.5, 0, 0, 7); c.fill();
    this._carry(c, w, bob);
    /* 그림이 들어오면 그림, 아직이면 이모지. 한 장씩 넣어가며 볼 수 있다. */
    if (!drawArt(c, 'guests', w.id, w.x, w.y + 6 + bob, GUEST_PX, GUEST_PX))
      G.text(c, w.face, w.x, w.y - 8 + bob, { size: 27, fill: '#000' });

    /* 단골은 갓을 쓴다. 등급이 오를수록 갓이 커지고 색이 진해진다.
     * 손님 머리 위에 글자를 얹으면 여럿 몰릴 때 다시 겹치므로 모양으로 알린다. */
    if (w.reg > 0) {
      /* 20성을 갓 다섯 단계로 접는다. 성마다 갓이 커지면 정승 갓이 화면을 덮는다. */
      const tier = Math.min(4, Math.ceil(w.reg / 4));
      const y = w.y - 24 + bob, sw = 9 + tier * 2.2;
      const tone = ['', '#8a7a63', '#6d5236', '#3f3327', '#2b241b'][tier];
      G.round(c, w.x - sw, y, sw * 2, 3.5, 2, tone);          // 갓양태
      G.round(c, w.x - sw * 0.42, y - 6.5, sw * 0.84, 8, 3, tone);  // 갓모자
      if (tier >= 4) G.circle(c, w.x, y - 8.5, 2.4, '#e0c073');    // 16성 어사또부터 금관자
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
