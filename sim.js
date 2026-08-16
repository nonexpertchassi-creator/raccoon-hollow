/* sim.js — 경제 로직. 그리기 코드가 한 줄도 없다.
 *
 * 파이프라인이 아주 단순하다:
 *   열린 품목마다 각자 타이머가 돌아 재고가 쌓인다 → 손님이 와서 사간다 → 돈
 *
 * 이전 버전(줍기→씻기→팔기)은 버렸다. 손님이 요청하면 칸을 여는 구조가
 * 훨씬 단순하고, 무엇보다 "다음에 뭘 할지"를 게임이 알려준다.
 */

import {
  SHOPS, GUESTS, LEVEL, MILESTONE_EVERY, MILESTONE_MULT, STOCK_CAP, OFFLINE, ASK_LINES,
} from './content.js';

const ALL_ITEMS = SHOPS.flatMap((s) => s.items.map((i) => ({ ...i, shop: s.id })));
export const itemById = (id) => ALL_ITEMS.find((i) => i.id === id);
export const shopById = (id) => SHOPS.find((s) => s.id === id);

export class Sim {
  constructor(save = null) {
    this.money = 0;
    this.revenue = 0;
    this.t = 0;

    this.shops = ['smith'];              // 되살린 가게
    this.items = { pick: { lv: 1, stock: 0, prog: 0 } };  // 열린 품목
    this.asked = [];                     // 손님이 물어본 적 있는(=열 수 있는) 품목
    this.guests = ['rabbit'];
    this.sold = 0;
    this.events = [];                    // 화면에 띄울 최근 사건

    this._guestAcc = {};
    this._askAcc = 0;
    for (const g of GUESTS) this._guestAcc[g.id] = 0;

    if (save) Object.assign(this, save);
  }

  /* ── 품목 ── */
  isOpen(id) { return !!this.items[id]; }
  lv(id) { return this.items[id]?.lv ?? 0; }

  /** 25레벨마다 2배 */
  milestone(id) { return Math.pow(MILESTONE_MULT, Math.floor(this.lv(id) / MILESTONE_EVERY)); }

  price(id) {
    const it = itemById(id);
    // 선형 증가 × 이정표. 지수로 올리면 비용 곡선을 추월해서 게임이 폭주한다.
    return Math.floor(it.price * (1 + LEVEL.priceStep * (this.lv(id) - 1)) * this.milestone(id));
  }

  craftTime(id) {
    const it = itemById(id);
    const f = Math.max(LEVEL.timeFloor, Math.pow(LEVEL.timeReduce, this.lv(id) - 1));
    return it.time * f;
  }

  /** 초당 수입 — 재고가 안 넘친다는 가정 하의 이론값 */
  incomePerSec() {
    let s = 0;
    for (const id of Object.keys(this.items)) s += this.price(id) / this.craftTime(id);
    return s;
  }

  levelCost(id) {
    const it = itemById(id);
    const base = Math.max(20, it.price * 4);
    return Math.floor(base * Math.pow(LEVEL.costGrowth, this.lv(id) - 1));
  }

  levelUp(id) {
    const c = this.levelCost(id);
    if (!this.isOpen(id) || this.money < c) return false;
    this.money -= c;
    const before = Math.floor(this.lv(id) / MILESTONE_EVERY);
    this.items[id].lv++;
    const after = Math.floor(this.lv(id) / MILESTONE_EVERY);
    if (after > before) this._ev(`${itemById(id).name} ${this.lv(id)}레벨 — 생산 2배!`, 'milestone');
    return true;
  }

  /** 손님이 물어본 적 있는 품목만 열 수 있다 */
  canOpenItem(id) {
    return !this.isOpen(id) && this.asked.includes(id) &&
           this.shops.includes(itemById(id).shop) && this.money >= itemById(id).cost;
  }

  openItem(id) {
    if (!this.canOpenItem(id)) return false;
    this.money -= itemById(id).cost;
    this.items[id] = { lv: 1, stock: 0, prog: 0 };
    this._ev(`${itemById(id).name} 칸을 열었다`, 'open');
    return true;
  }

  /* ── 가게 ── */
  nextShop() { return SHOPS.find((s) => !this.shops.includes(s.id)) || null; }

  openShop(id) {
    const s = shopById(id);
    if (!s || this.shops.includes(id) || this.money < s.cost) return false;
    this.money -= s.cost;
    this.shops.push(id);
    const first = s.items[0];
    this.items[first.id] = { lv: 1, stock: 0, prog: 0 };
    if (!this.asked.includes(first.id)) this.asked.push(first.id);
    this._ev(`${s.name}이(가) 다시 문을 열었다`, 'shop');
    return true;
  }

  /* ── 한 틱 ── */
  tick(dt, rng = Math.random) {
    this.t += dt;

    // 1) 생산 — 열린 품목이 각자 자기 타이머로 돈다. 손 댈 필요 없음.
    for (const id of Object.keys(this.items)) {
      const st = this.items[id];
      if (st.stock >= STOCK_CAP) continue;      // 진열대가 꽉 차면 잠시 멈춘다
      st.prog += dt;
      const need = this.craftTime(id);
      while (st.prog >= need && st.stock < STOCK_CAP) {
        st.prog -= need;
        st.stock++;
      }
    }

    // 2) 손님 — 재고에서 비싼 것부터 사간다
    const sales = [];
    for (const g of GUESTS) {
      if (!this.guests.includes(g.id)) continue;
      this._guestAcc[g.id] += dt;
      while (this._guestAcc[g.id] >= g.every) {
        this._guestAcc[g.id] -= g.every;
        const s = this._buy(g);
        if (s) sales.push(s);
      }
    }

    // 3) 손님이 없는 물건을 물어본다 → 그게 다음 목표가 된다
    let ask = null;
    this._askAcc += dt;
    if (this._askAcc >= 14) {
      this._askAcc = 0;
      ask = this._ask(rng);
    }

    // 4) 새 손님이 마을에 온다
    let newGuest = null;
    const ng = GUESTS.find((g) => !this.guests.includes(g.id) && this.revenue >= g.at);
    if (ng) {
      this.guests.push(ng.id);
      newGuest = ng;
      this._ev(`${ng.name}이(가) 마을에 왔다`, 'guest');
    }

    return { sales, ask, newGuest };
  }

  _buy(g) {
    const open = Object.keys(this.items).filter((id) => this.items[id].stock > 0);
    if (!open.length) return null;
    // 비싼 것부터 사간다
    open.sort((a, b) => this.price(b) - this.price(a));
    const id = open[0];
    const n = Math.min(g.qty, this.items[id].stock);
    const gain = Math.floor(this.price(id) * g.pay * n);
    this.items[id].stock -= n;
    this.money += gain;
    this.revenue += gain;
    this.sold += n;
    return { guest: g, item: itemById(id), n, gain };
  }

  /**
   * 아직 안 열린 품목 하나를 물어본다. 이게 다음 목표를 지정한다.
   *
   * 중요: 이미 물어봤는데 아직 안 열어준 게 있으면 새로 안 물어본다.
   * 안 그러면 요청이 3개씩 쌓여서 "다음에 뭘 할지"가 다시 흐려진다 —
   * 요청 구조를 쓰는 이유가 목표를 하나로 좁히는 거였는데 그게 무너진다.
   */
  _ask(rng) {
    const pending = this.asked.some((id) => !this.isOpen(id));
    if (pending) return null;
    const cands = ALL_ITEMS.filter((i) =>
      !this.isOpen(i.id) && !this.asked.includes(i.id) && this.shops.includes(i.shop));
    if (!cands.length) return null;
    const item = cands[0];                       // 가게 안에서는 순서대로
    const gs = this.guests;
    const guest = GUESTS.find((g) => g.id === gs[gs.length - 1]) || GUESTS[0];
    this.asked.push(item.id);
    const line = ASK_LINES[Math.floor(rng() * ASK_LINES.length)].replace('{item}', item.name);
    this._ev(`${guest.name}: "${line}"`, 'ask');
    return { guest, item, line };
  }

  /** 오프라인 수익. 껐다 켰을 때 쌓여 있어야 다시 켠다. */
  offline(seconds) {
    const real = Math.min(seconds, OFFLINE.capHours * 3600);
    if (real < 60) return null;
    const earned = Math.floor(this.incomePerSec() * real * OFFLINE.efficiency);
    this.money += earned;
    this.revenue += earned;
    return { earned, seconds: real, capped: seconds > OFFLINE.capHours * 3600 };
  }

  _ev(msg, kind) {
    this.events.unshift({ t: this.t, msg, kind });
    this.events.length = Math.min(this.events.length, 40);
  }

  save() {
    const { events, ...rest } = this;
    return JSON.parse(JSON.stringify(rest));
  }
}

/** 큰 숫자. 방치형은 이게 없으면 화면이 터진다. */
export function fmt(n) {
  n = Math.floor(n);
  if (n < 10000) return n.toLocaleString('ko-KR');
  const U = ['', '만', '억', '조', '경'];
  let i = 0, v = n;
  while (v >= 10000 && i < U.length - 1) { v /= 10000; i++; }
  return (v < 10 ? v.toFixed(2) : v < 100 ? v.toFixed(1) : Math.floor(v)) + U[i];
}
