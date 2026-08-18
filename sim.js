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
  BASKET_SPREAD, MAX_BULK, AUTO_COST, AUTO_PER_TICK, AUTO_SHARE,
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
    this.auto = false;                    // 자동 강화를 샀는가
    this._purse = 0;                     // 자동 강화가 쓸 수 있는 몫
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

  /** lv레벨에서 다음 한 레벨을 올리는 값 */
  _stepCost(id, lv) {
    const base = Math.max(20, itemById(id).price * 4);
    return Math.floor(base * Math.pow(LEVEL.costGrowth, lv - 1));
  }

  levelCost(id) { return this._stepCost(id, this.lv(id)); }

  /** n레벨을 한 번에 올리는 총액. 한 레벨씩 n번 올릴 때와 **정확히 같다** —
   * 묶음 버튼은 손가락을 아끼는 편의일 뿐, 할인도 손해도 아니어야 한다. */
  levelCostMany(id, n) {
    let sum = 0;
    const lv = this.lv(id);
    for (let k = 0; k < n; k++) sum += this._stepCost(id, lv + k);
    return sum;
  }

  /** 지금 가진 돈으로 몇 레벨까지 올릴 수 있나 */
  affordableLevels(id) {
    if (!this.isOpen(id)) return 0;
    let left = this.money, n = 0;
    const lv = this.lv(id);
    while (n < MAX_BULK) {
      const c = this._stepCost(id, lv + n);
      if (c > left) break;
      left -= c; n++;
    }
    return n;
  }

  /**
   * n레벨을 한 번에 올린다. 돈이 모자라면 살 수 있는 만큼만 올리고,
   * 실제로 오른 레벨 수를 돌려준다.
   *
   * 이게 필요한 이유: 6시간 플레이에 레벨업 클릭이 1945번 나왔다.
   * 의미 있는 선택(새 가게·새 품목)은 14번뿐이었다. 나머지는 전부 손가락 노동이다.
   */
  levelUpMany(id, want) {
    const n = Math.min(want, this.affordableLevels(id));
    if (n <= 0) return 0;
    this.money -= this.levelCostMany(id, n);
    const before = Math.floor(this.lv(id) / MILESTONE_EVERY);
    this.items[id].lv += n;
    const after = Math.floor(this.lv(id) / MILESTONE_EVERY);
    if (after > before) this._ev(`${itemById(id).name} ${this.lv(id)}레벨 — 생산 2배!`, 'milestone');
    return n;
  }

  levelUp(id) { return this.levelUpMany(id, 1) === 1; }

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

  /* ── 자동 강화 ── */
  canBuyAuto() { return !this.auto && this.money >= AUTO_COST; }

  buyAuto() {
    if (!this.canBuyAuto()) return false;
    this.money -= AUTO_COST;
    this.auto = true;
    this._ev('장부를 정리했다 — 이제 알아서 강화된다', 'shop');
    return true;
  }

  /**
   * 버는 돈의 일부를 따로 모아, 그 몫으로 제일 싼 품목부터 알아서 강화한다.
   *
   * 기준이 '남은 돈'이 아니라 **버는 속도**인 게 핵심이다. 남은 돈을 기준으로
   * 하면 다음 목표가 비쌀수록 강화가 멈춰버린다 — 실제로 그렇게 만들었다가
   * 약재상(200억)을 모으는 동안 수입이 몇 시간째 제자리였다.
   * 지금은 6할이 강화로 나가고 4할은 늘 쌓이므로 저축과 성장이 같이 간다.
   */
  _autoLevel() {
    if (!this.auto) return 0;

    let budget = Math.min(this._purse, this.money);
    if (budget <= 0) return 0;

    let done = 0;
    while (done < AUTO_PER_TICK) {
      let best = null, bestCost = Infinity;
      for (const id of Object.keys(this.items)) {
        const c = this.levelCost(id);
        if (c < bestCost) { bestCost = c; best = id; }
      }
      if (!best || bestCost > budget) break;
      budget -= bestCost;
      this._purse -= bestCost;
      this.money -= bestCost;
      const before = Math.floor(this.lv(best) / MILESTONE_EVERY);
      this.items[best].lv++;
      if (Math.floor(this.lv(best) / MILESTONE_EVERY) > before) {
        this._ev(`${itemById(best).name} ${this.lv(best)}레벨 — 생산 2배!`, 'milestone');
      }
      done++;
    }
    return done;
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

    // 2) 손님 — 재고에서 여러 종류를 무작위로 담아간다
    const sales = [];
    for (const g of GUESTS) {
      if (!this.guests.includes(g.id)) continue;
      this._guestAcc[g.id] += dt;
      while (this._guestAcc[g.id] >= g.every) {
        this._guestAcc[g.id] -= g.every;
        const s = this._buy(g, rng);
        if (s) sales.push(s);
      }
    }

    // 3) 자동 강화 — 다음 목표 값은 남기고 나머지로 알아서 올린다
    const autoLv = this._autoLevel();

    // 4) 손님이 없는 물건을 물어본다 → 그게 다음 목표가 된다
    let ask = null;
    this._askAcc += dt;
    if (this._askAcc >= 14) {
      this._askAcc = 0;
      ask = this._ask(rng);
    }

    // 5) 새 손님이 마을에 온다
    let newGuest = null;
    const ng = GUESTS.find((g) => !this.guests.includes(g.id) && this.revenue >= g.at);
    if (ng) {
      this.guests.push(ng.id);
      newGuest = ng;
      this._ev(`${ng.name}이(가) 마을에 왔다`, 'guest');
    }

    return { sales, ask, newGuest, autoLv };
  }

  /**
   * 손님이 장바구니에 여러 품목을 **무작위로** 담아간다.
   *
   * 예전엔 제일 비싼 것 한 종류만 사갔다. 그러면 싼 품목은 아무도 안 사서
   * 재고가 상한에 박히고, tick()의 `stock >= STOCK_CAP` 때문에 생산까지 멈췄다.
   * 한 번 멈추면 팔릴 일이 없으니 영영 죽는다 — 15개 중 7개가 그 상태였다.
   *
   * 고친 건 순서가 아니라 **종류 수**였다. 시뮬로 무작위·재고순·재고가중을
   * 나란히 돌려보니 셋 다 정지 0%가 나왔다. 여러 종류를 사기만 하면 안 막힌다.
   * 그래서 제일 재미있는 쪽인 무작위를 고른다 — 손님이 매번 다른 조합을
   * 집어가야 가게가 살아있는 느낌이 난다.
   */
  _buy(g, rng = Math.random) {
    const have = Object.keys(this.items).filter((id) => this.items[id].stock > 0);
    if (!have.length) return null;

    // 무작위로 섞는다 (Fisher-Yates)
    for (let i = have.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [have[i], have[j]] = [have[j], have[i]];
    }

    // 안전장치: 진열대가 꽉 찬 품목만 맨 앞으로 당긴다. 꽉 찬 품목은 생산이
    // 멈춰 있으므로 먼저 비워야 다시 돈다. 지금 수치로는 없어도 안 막히지만,
    // 앞으로 생산·손님 수치를 만지면 다시 막힐 수 있어 보험으로 남긴다.
    // sort는 안정 정렬이라 같은 그룹 안에서는 위에서 섞은 순서가 유지된다.
    have.sort((a, b) =>
      (this.items[b].stock >= STOCK_CAP) - (this.items[a].stock >= STOCK_CAP));

    const per = Math.max(1, Math.ceil(g.qty / BASKET_SPREAD));
    const lines = [];
    let left = g.qty, gain = 0;

    for (const id of have) {
      if (left <= 0) break;
      const n = Math.min(left, per, this.items[id].stock);
      if (n <= 0) continue;
      const got = Math.floor(this.price(id) * g.pay * n);
      this.items[id].stock -= n;
      left -= n; gain += got; this.sold += n;
      lines.push({ item: itemById(id), n, gain: got });
    }
    if (!lines.length) return null;

    this.money += gain;
    this.revenue += gain;
    if (this.auto) this._purse += gain * AUTO_SHARE;
    return { guest: g, lines, gain, n: g.qty - left };
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
    if (this.auto) this._purse += earned * AUTO_SHARE;
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
