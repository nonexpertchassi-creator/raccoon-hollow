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
  BASKET_SPREAD, MAX_BULK, AUTO_COST, AUTO_PER_TICK, AUTO_SHARE, ASK_EVERY, FAIR, SMALL_SHOPS, RANKS, REGULARS, PESTS,
} from './content.js';

const ALL_ITEMS = SHOPS.flatMap((s) => s.items.map((i) => ({ ...i, shop: s.id })));
export const itemById = (id) => ALL_ITEMS.find((i) => i.id === id);

/** 조사 붙이기. '쥐이(가)'처럼 나오면 글이 삭는다.
 *  한글 마지막 글자에 받침이 있으면 앞쪽, 없으면 뒤쪽을 쓴다. */
export function josa(word, withJong, without) {
  const c = word.charCodeAt(word.length - 1) - 0xac00;
  const jong = c >= 0 && c <= 11171 && c % 28 !== 0;
  return word + (jong ? withJong : without);
}
export const shopById = (id) => SHOPS.find((s) => s.id === id);

export class Sim {
  constructor(save = null) {
    this.money = 0;
    this.revenue = 0;
    this.t = 0;

    this.shops = ['smith'];              // 되살린 가게
    this.rank = {};                      // 가게 등급 (가게id → 0·1·2). 없으면 0급
    this.items = { pick: { lv: 1, stock: 0, prog: 0 } };  // 열린 품목
    this.asked = [];                     // 손님이 물어본 적 있는(=열 수 있는) 품목
    this.guests = ['rabbit'];
    this.bought = {};                    // 손님별 누적 구매 개수 (화면 표시용)
    this.visits = {};                    // 손님별 누적 방문 횟수 → 단골 등급
    this.sold = 0;
    this.auto = false;                    // 자동 강화를 샀는가
    this.smalls = [];                     // 세워 둔 작은 건물의 번호
    this.fair = 0;                        // 장이 서 있는 남은 시간(초)
    this.busy = -1;                       // 지금 북적이는 작은 건물 (없으면 -1)
    this._busyT = 0;
    this._fairAcc = 0;
    this._purse = 0;                     // 자동 강화가 쓸 수 있는 몫
    this.events = [];                    // 화면에 띄울 최근 사건

    this._guestAcc = {};
    this._guestGap = {};
    /* 지금 나와 있는 나쁜 놈. 한 번에 하나만.
     * { kind, itemId?, qty?, amount?, left, life } */
    this.pest = null;
    this._pestAcc = {};
    this._pestGap = {};
    this._askAcc = 0;
    for (const g of GUESTS) this._guestAcc[g.id] = 0;

    if (save) Object.assign(this, save);

    /* 옛 저장본에는 visits가 없다. 단골 등급을 개수로 세던 시절이라
     * 그때 사가던 개수로 방문 횟수를 되짚어 준다. 없으면 전원 1성으로
     * 떨어져 몇 시간치 진행이 사라진다. */
    if (save && !save.visits) {
      this.visits = {};
      for (const g of GUESTS) {
        const n = this.bought[g.id];
        if (n) this.visits[g.id] = Math.round(n / (g.qty * 1.8));
      }
    }
  }

  /* ── 품목 ── */
  isOpen(id) { return !!this.items[id]; }
  lv(id) { return this.items[id]?.lv ?? 0; }

  /** 25레벨마다 2배. **판매가**에만 붙는다 — price()에서만 쓰인다.
   * 화면에는 오래도록 '생산 2배'라고 적혀 있었지만 생산은 한 번도 안 빨라졌다. */
  milestone(id) { return Math.pow(MILESTONE_MULT, Math.floor(this.lv(id) / MILESTONE_EVERY)); }

  /** 이 손님이 다음에 올 때까지의 간격(초).
   *
   *  wild가 0이면 every 그대로 — 시계처럼 온다.
   *  wild가 1이면 '초당 1/every 확률로 온다'와 같은 것(지수분포)이 된다.
   *  둘 사이는 섞는다. **어느 쪽이든 평균 간격은 every 그대로**라서
   *  밸런스 표를 다시 잴 필요가 없다. 흔들리기만 한다.
   */
  _gap(g, rng = Math.random) { return this._wildGap(g.every, g.wild || 0, rng); }

  _wildGap(every, w, rng = Math.random) {
    if (w <= 0) return every;
    const e = -Math.log(1 - rng() * 0.999);          // 평균 1인 지수분포
    return Math.max(every * 0.15, every * (1 - w + w * e));
  }

  /* ── 나쁜 놈들 ── */
  pestKind() { return this.pest ? PESTS.find((p) => p.id === this.pest.kind) : null; }

  _pests(dt, rng) {
    if (this.pest) {
      this.pest.left -= dt;
      if (this.pest.left <= 0) this._pestEscape();
      return;
    }
    for (const P of PESTS) {
      if (this.revenue < P.at) continue;
      this._pestAcc[P.id] = (this._pestAcc[P.id] || 0) + dt;
      if (this._pestGap[P.id] == null) this._pestGap[P.id] = this._wildGap(P.every, P.wild, rng);
      if (this._pestAcc[P.id] < this._pestGap[P.id]) continue;
      this._pestAcc[P.id] = 0;
      this._pestGap[P.id] = this._wildGap(P.every, P.wild, rng);
      if (this.pest) continue;              // 이미 하나 나와 있으면 이번엔 거른다
      const born = this._pestBorn(P, rng);
      if (!born) continue;
      this.pest = born;
      this._ev(`${josa(P.name, '이', '가')} ${born.what} — 눌러서 잡아라`, 'pest');
    }
  }

  _pestBorn(P, rng) {
    if (P.steal === 'goods') {
      const pool = Object.keys(this.items).filter((id) => this.items[id].stock > 0);
      if (!pool.length) return null;        // 훔칠 것이 없으면 오지 않는다
      const itemId = pool[Math.floor(rng() * pool.length)];
      const qty = Math.max(1, Math.min(P.max, Math.floor(this.items[itemId].stock * P.take)));
      return { kind: P.id, itemId, qty, left: P.life, life: P.life,
               what: `${this.itemName(itemId)}에 손을 댔다` };
    }
    /* 엽전은 **초당 수입 몇 초치**로 잡는다. 가진 돈의 비율로 하면
     * 아껴 모은 사람만 크게 털린다 — 모으는 게 벌이 되면 안 된다. */
    const amount = Math.floor(this.incomePerSec() * P.take);
    if (amount < 1) return null;
    return { kind: P.id, amount, left: P.life, life: P.life,
             what: `엽전 ${fmt(amount)}냥을 노린다` };
  }

  _pestEscape() {
    const t = this.pest;
    const P = PESTS.find((p) => p.id === t.kind);
    this.pest = null;
    if (P.steal === 'goods') {
      const it = this.items[t.itemId];
      const n = it ? Math.min(it.stock, t.qty) : 0;
      if (it) it.stock -= n;
      this._ev(`${josa(P.name, '이', '가')} ${this.itemName(t.itemId)} ${n}개를 훔쳐 달아났다`, 'pest');
    } else {
      const n = Math.min(this.money, t.amount);
      this.money -= n;
      this._ev(`${josa(P.name, '이', '가')} ${fmt(n)}냥을 채 갔다`, 'pest');
    }
  }

  /** 잡았다. 훔치려던 것은 그대로 남고 벌금을 받는다.
   *  손해를 막는 게 아니라 이득을 줍는 구조여야 한다 — 안 보고 있어도
   *  잃는 건 작고, 보고 있으면 버는 게 크다. */
  catchPest() {
    const t = this.pest;
    if (!t) return null;
    const P = PESTS.find((p) => p.id === t.kind);
    this.pest = null;
    const worth = P.steal === 'goods' ? this.price(t.itemId) * t.qty : t.amount;
    const gain = Math.floor(worth * P.fine);
    this.money += gain;
    this.revenue += gain;
    this._ev(`${josa(P.name, '을', '를')} 잡았다 — 벌금 ${fmt(gain)}냥`, 'catch');
    return { kind: t.kind, gain };
  }

  /* ── 단골 20성 ── */
  /** i성에 오르는 데 필요한 **방문 횟수**.
   *
   *  개수로 세면 안 된다. 등급이 오르면 한 번에 사가는 개수가 늘고, 그러면
   *  다음 등급이 더 빨리 온다 — 눈덩이가 굴러서 두 시간 만에 12성이 됐다.
   *  실제로 그렇게 만들어 재보니 진열대가 다시 텅 비었다(못채움 28%).
   *  방문 횟수는 등급이 올라도 안 늘어나므로 눈덩이가 안 생긴다.
   *
   *  REGULARS[i].at은 초 단위라 손님의 오는 간격으로 나눈다. 그래서
   *  **누구든 마을에 온 뒤 같은 시간이 흐르면 같은 성**이 된다 —
   *  400초마다 오는 호랑이가 영원히 뜨내기로 남지 않는다. */
  regularNeed(gid, i) {
    const g = GUESTS.find((x) => x.id === gid);
    if (!g) return REGULARS[i].at;
    return Math.max(1, Math.round(REGULARS[i].at / g.every));
  }
  regularLv(gid) {
    const n = this.visits[gid] || 0;
    let lv = 0;
    for (let i = 1; i < REGULARS.length; i++) if (n >= this.regularNeed(gid, i)) lv = i;
    return lv;
  }
  regularName(gid) { return REGULARS[this.regularLv(gid)].name; }
  /** 몇 성인가 (1성부터 센다 — 화면에 그대로 보여준다) */
  regularStar(gid) { return this.regularLv(gid) + 1; }
  /** 다음 등급까지 남은 방문 횟수 (최고 등급이면 null) */
  regularLeft(gid) {
    const lv = this.regularLv(gid);
    return lv >= REGULARS.length - 1 ? null : this.regularNeed(gid, lv + 1) - (this.visits[gid] || 0);
  }
  /** 모든 손님의 단골 등급 합계. 가게 승급 조건에 쓴다. */
  regularSum() { return this.guests.reduce((a, g) => a + this.regularLv(g), 0); }

  /* ── 가게 등급 ── */
  rankOf(shopId) { return this.rank[shopId] || 0; }
  rankOfItem(id) { return this.rankOf(itemById(id).shop); }

  /** 화면에 보이는 이름. 돌도끼 → 쇠도끼 → 강철도끼 */
  itemName(id) {
    const it = itemById(id);
    return shopById(it.shop).ranks[this.rankOf(it.shop)] + it.name;
  }

  /** 이 품목이 지금 등급에서 올릴 수 있는 최대 레벨 */
  maxLv(id) { return RANKS[this.rankOfItem(id)].maxLv; }
  atMax(id) { return this.lv(id) >= this.maxLv(id); }

  price(id) {
    const it = itemById(id);
    // 선형 증가 × 이정표 × 등급. 지수로 올리면 비용 곡선을 추월해 폭주한다.
    return Math.floor(it.price * RANKS[this.rankOfItem(id)].priceMul
      * (1 + LEVEL.priceStep * (this.lv(id) - 1)) * this.milestone(id));
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
    // 등급이 오르면 값도 같이 올라야 한다. 안 그러면 3급 레벨업이 공짜가 된다.
    const base = Math.max(20, itemById(id).price * RANKS[this.rankOfItem(id)].priceMul * 4);
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
    const room = this.maxLv(id) - lv;
    while (n < Math.min(MAX_BULK, room)) {
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
    const n = Math.min(want, this.affordableLevels(id), this.maxLv(id) - this.lv(id));
    if (n <= 0) return 0;
    this.money -= this.levelCostMany(id, n);
    const before = Math.floor(this.lv(id) / MILESTONE_EVERY);
    this.items[id].lv += n;
    const after = Math.floor(this.lv(id) / MILESTONE_EVERY);
    if (after > before) this._ev(`${itemById(id).name} ${this.lv(id)}레벨 — 값이 2배!`, 'milestone');
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
        if (this.atMax(id)) continue;              // 만렙은 건드리지 않는다
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
        this._ev(`${itemById(best).name} ${this.lv(best)}레벨 — 값이 2배!`, 'milestone');
      }
      done++;
    }
    return done;
  }

  /* ── 가게 승급 ── */

  /**
   * 승급 조건을 하나씩 따져 목록으로 돌려준다.
   * 화면에서 "무엇이 모자란가"를 그대로 보여주기 위해 boolean이 아니라
   * 항목별 결과를 넘긴다 — 못 하는 이유가 안 보이면 목표가 되지 못한다.
   */
  promoteReqs(shopId) {
    const shop = shopById(shopId);
    const r = this.rankOf(shopId);
    const next = RANKS[r + 1];
    if (!next) return null;                       // 이미 최고 등급

    const allOpen = shop.items.every((it) => this.isOpen(it.id));
    const allMax = allOpen && shop.items.every((it) => this.atMax(it.id));
    const i = SHOPS.findIndex((x) => x.id === shopId);
    const after = SHOPS[i + 1];
    const ips = this.incomePerSec();
    const cost = shop.promote[r];
    return {
      rank: r + 1,
      cost,
      list: [
        { ok: allMax, text: `${shop.name}의 모든 칸을 ${next === RANKS[1] ? RANKS[0].maxLv : RANKS[r].maxLv}레벨까지` },
        { ok: !after || this.shops.includes(after.id), text: after ? `${after.name} 열기` : '—' },
        { ok: this.regularSum() >= next.guests,
          text: `손님 단골 등급 합계 ${next.guests} (지금 ${this.regularSum()})` },
        { ok: ips >= next.ips, text: `초당 ${fmt(next.ips)}냥 (지금 ${fmt(ips)})` },
        { ok: this.money >= cost, text: `승급값 ${fmt(cost)}냥` },
      ].filter((x) => x.text !== '—'),
    };
  }

  canPromote(shopId) {
    const r = this.promoteReqs(shopId);
    return !!r && r.list.every((x) => x.ok);
  }

  /**
   * 승급. 레벨은 1로 돌아가지만 밑천이 통째로 좋아진다 — 이 가게만의 작은 환생이다.
   * 재고는 남긴다. 승급했다고 진열대가 비면 손해 본 느낌만 남는다.
   */
  promote(shopId) {
    if (!this.canPromote(shopId)) return false;
    const shop = shopById(shopId);
    this.money -= shop.promote[this.rankOf(shopId)];
    this.rank[shopId] = this.rankOf(shopId) + 1;
    for (const it of shop.items) {
      if (this.items[it.id]) this.items[it.id].lv = 1;
    }
    this._ev(`${josa(shop.name, '이', '가')} ${shop.ranks[this.rankOf(shopId)]} 등급으로 올라섰다`, 'milestone');
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
    this._ev(`${josa(s.name, '이', '가')} 다시 문을 열었다`, 'shop');
    return true;
  }

  /* ── 작은 건물 ── */
  canBuildSmall(i) {
    return SMALL_SHOPS[i] && !this.smalls.includes(i) && this.money >= SMALL_SHOPS[i].cost;
  }

  buildSmall(i) {
    if (!this.canBuildSmall(i)) return false;
    this.money -= SMALL_SHOPS[i].cost;
    this.smalls.push(i);
    this._ev(`${josa(SMALL_SHOPS[i].name, '을', '를')} 세웠다`, 'shop');
    return true;
  }

  /** 아직 안 세운 것 중 제일 싼 것 */
  nextSmall() {
    for (let i = 0; i < SMALL_SHOPS.length; i++) if (!this.smalls.includes(i)) return i;
    return -1;
  }

  /**
   * 북적이는 작은 건물을 눌렀다 → 장이 선다.
   * 북적이지 않는 곳을 누르면 아무 일도 없다.
   */
  tapSmall(idx) {
    if (idx !== this.busy) return false;
    this.busy = -1;
    this.fair = FAIR.boost;
    this._ev('장이 섰다 — 손님이 몰린다!', 'shop');
    return true;
  }

  /* ── 한 틱 ── */
  tick(dt, rng = Math.random) {
    this.t += dt;

    // 0) 장 — 북적임이 떴다 사라지고, 장이 서 있으면 시간이 줄어든다
    if (this.fair > 0) this.fair = Math.max(0, this.fair - dt);
    if (this.busy >= 0) {
      this._busyT -= dt;
      if (this._busyT <= 0) this.busy = -1;
    } else if (this.fair <= 0 && this.smalls.length) {
      // 세워 둔 곳 중에서만 북적인다
      this._fairAcc += dt;
      if (this._fairAcc >= FAIR.every) {
        this._fairAcc = 0;
        this.busy = this.smalls[Math.floor(rng() * this.smalls.length)];
        this._busyT = FAIR.window;
      }
    }

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

    // 1.5) 나쁜 놈들 — 물건이나 엽전을 집어 들고 도망친다
    this._pests(dt, rng);

    // 2) 손님 — 재고에서 여러 종류를 무작위로 담아간다
    const sales = [];
    for (const g of GUESTS) {
      if (!this.guests.includes(g.id)) continue;
      // 장이 서면 손님이 그만큼 자주 온다
      this._guestAcc[g.id] += dt * (this.fair > 0 ? FAIR.mult : 1);
      if (this._guestGap[g.id] == null) this._guestGap[g.id] = this._gap(g, rng);
      while (this._guestAcc[g.id] >= this._guestGap[g.id]) {
        this._guestAcc[g.id] -= this._guestGap[g.id];
        this._guestGap[g.id] = this._gap(g, rng);
        const s = this._buy(g, rng);
        if (s) sales.push(s);
      }
    }

    // 3) 자동 강화 — 다음 목표 값은 남기고 나머지로 알아서 올린다
    const autoLv = this._autoLevel();

    // 4) 손님이 없는 물건을 물어본다 → 그게 다음 목표가 된다
    let ask = null;
    this._askAcc += dt;
    if (this._askAcc >= ASK_EVERY) {
      this._askAcc = 0;
      ask = this._ask(rng);
    }

    // 5) 새 손님이 마을에 온다
    let newGuest = null;
    const ng = GUESTS.find((g) => !this.guests.includes(g.id) && this.revenue >= g.at);
    if (ng) {
      this.guests.push(ng.id);
      newGuest = ng;
      this._ev(`${josa(ng.name, '이', '가')} 마을에 왔다`, 'guest');
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

    // 단골일수록 많이 사가고 값도 후하게 쳐준다
    const reg = REGULARS[this.regularLv(g.id)];
    const qty = Math.max(1, Math.round(g.qty * reg.qty));
    const pay = g.pay * reg.pay;

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

    // 손님마다 훑는 종류 수가 다르다. 곰·멧돼지는 1이라 한 종류를 쓸어간다.
    const per = Math.max(1, Math.ceil(qty / (g.spread || BASKET_SPREAD)));
    const lines = [];
    let left = qty, gain = 0;

    for (const id of have) {
      if (left <= 0) break;
      const n = Math.min(left, per, this.items[id].stock);
      if (n <= 0) continue;
      const got = Math.floor(this.price(id) * pay * n);
      this.items[id].stock -= n;
      left -= n; gain += got; this.sold += n;
      lines.push({ item: itemById(id), n, gain: got });
    }
    if (!lines.length) return null;

    this.money += gain;
    this.revenue += gain;
    if (this.auto) this._purse += gain * AUTO_SHARE;

    // 단골 등급이 올랐으면 알린다 — 손님이 굳어 있지 않다는 신호다
    const before = this.regularLv(g.id);
    this.bought[g.id] = (this.bought[g.id] || 0) + (qty - left);
    this.visits[g.id] = (this.visits[g.id] || 0) + 1;
    const after = this.regularLv(g.id);
    if (after > before) {
      this._ev(`${josa(g.name, '이', '가')} ${after + 1}성 ${josa(REGULARS[after].name, '이', '가')} 되었다`, 'guest');
    }
    return { guest: g, lines, gain, n: qty - left, want: qty };
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
