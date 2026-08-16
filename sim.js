/* sim.js — 경제 시뮬레이션. 그리기 코드가 한 줄도 없다.
 *
 * 왜 분리했나:
 * 방치형은 성장 곡선이 곧 게임이다. 곡선이 잘못되면 아트가 아무리 좋아도 재미없다.
 * 로직이 렌더링과 붙어 있으면 브라우저를 띄워야만 확인이 되고, 그러면 하루에
 * 몇 번 못 돌려본다. 여기 분리해두면 터미널에서 게임 100일치를 1초에 돌린다.
 *
 * 파이프라인:  줍기 → (창고) → 씻기 → (진열대) → 판매
 * 각 단계가 병목이 될 수 있고, 어디가 막히는지가 곧 "다음에 뭘 살까"의 답이다.
 */

import {
  TIERS, PRICE, WASH_COST, FORESTS, ANIMALS, UPGRADES, RAW_CAP_PER_GATHERER,
  PRESTIGE, MILESTONE_EVERY, MILESTONE_MULT,
} from './content.js';

const T = TIERS.length;

export class Sim {
  constructor(save = null) {
    this.money = 0;
    this.totalRevenue = 0;
    this.t = 0;                    // 누적 플레이 시간(초)
    this.gatherer = 1;
    this.washer = 1;
    this.shelf = 1;
    this.forest = 0;
    this.raw = new Array(T).fill(0);    // 미가공 잡동사니
    this.clean = new Array(T).fill(0);  // 씻은 상품
    this.sold = new Array(T).fill(0);
    this.seenAnimals = ['squirrel'];
    this.fame = 0;                 // 이사해도 남는 영구 자산
    this.moves = 0;                // 이사 횟수
    this.lifetimeRevenue = 0;      // 이사해도 안 지워지는 누적
    this.log = [];                      // 최근 사건 (UI용)

    this._gatherAcc = 0;
    this._washAcc = 0;
    this._animalAcc = {};
    for (const a of ANIMALS) this._animalAcc[a.id] = 0;

    if (save) Object.assign(this, save);
  }

  /* ── 파생 수치 ── */
  cost(kind) {
    const u = UPGRADES[kind];
    return Math.floor(u.base * Math.pow(u.growth, this[kind] - 1));
  }
  /** 25마리째마다 효율 2배. 24→25로 넘어가는 순간이 이 게임에서 제일 신나야 한다. */
  milestone(n) { return Math.pow(MILESTONE_MULT, Math.floor(n / MILESTONE_EVERY)); }
  /** 다음 이정표까지 몇 개 남았는지 (UI가 이걸 보여줘야 목표가 생긴다) */
  toMilestone(kind) { return MILESTONE_EVERY - (this[kind] % MILESTONE_EVERY); }

  /** 소문(이사해도 남는 영구 배수) */
  fameMult() { return 1 + this.fame * PRESTIGE.perPoint; }

  gatherRate() { return this.gatherer * UPGRADES.gatherer.rate * this.milestone(this.gatherer); }
  washRate()   { return this.washer * UPGRADES.washer.rate * this.milestone(this.washer); }
  rawCap()     { return this.gatherer * RAW_CAP_PER_GATHERER; }
  shelfCap()   { return this.shelf * UPGRADES.shelf.rate; }
  rawTotal()   { return this.raw.reduce((a, b) => a + b, 0); }

  /**
   * 창고 상한은 "지금 팔 수 있는 등급"에만 적용한다.
   *
   * 두 번째 교착이 여기였다. 아직 살 동물이 없는 보물이 창고를 영구히 막아서
   * 줍기가 통째로 멈췄다. 보물은 별도로 무한히 쌓이게 두는 게 맞다 —
   * 곰이 오는 순간 그동안 쌓인 게 전부 돈이 되는 장면이 이 게임의 클라이맥스니까.
   */
  storedTotal() {
    const s = this.sellableTiers();
    return this.raw.reduce((sum, n, t) => sum + (s.has(t) ? n : 0), 0);
  }

  /** 아직 팔 사람이 없어 쌓아둔 보물 */
  hoardTotal() {
    const s = this.sellableTiers();
    return this.raw.reduce((sum, n, t) => sum + (s.has(t) ? 0 : n), 0);
  }
  cleanTotal() { return this.clean.reduce((a, b) => a + b, 0); }
  nextForest() { return FORESTS[this.forest + 1] || null; }
  animals()    { return ANIMALS.filter((a) => this.seenAnimals.includes(a.id)); }

  /**
   * 지금 마을에 온 동물들이 사가는 등급.
   *
   * 이게 없으면 게임이 죽는다. 초기 버전은 "비싼 것부터 씻기"였는데,
   * 아직 아무도 안 사는 고급품이 진열대를 꽉 채워서 씻기가 멈추고,
   * 팔 물건이 영영 안 만들어졌다. 밸런스 시뮬레이터가 잡은 교착이다.
   *
   * 대신 안 팔리는 건 창고에 그대로 쌓인다 — 그리고 곰이 마을에 오는 순간
   * 그 창고가 통째로 돈이 된다. 버그를 고치다 나온 이 장면이 오히려 좋다.
   */
  sellableTiers() {
    const set = new Set();
    for (const a of this.animals()) for (const t of a.wants) set.add(t);
    return set;
  }

  /** 다음에 마을로 올 동물과 남은 매출 */
  nextAnimal() {
    const a = ANIMALS.find((x) => !this.seenAnimals.includes(x.id));
    return a ? { animal: a, remain: Math.max(0, a.at - this.totalRevenue) } : null;
  }

  /* ── 구매 ── */
  buy(kind) {
    const c = this.cost(kind);
    if (this.money < c) return false;
    this.money -= c;
    this[kind]++;
    return true;
  }

  buyForest() {
    const nx = this.nextForest();
    if (!nx || this.money < nx.cost) return false;
    this.money -= nx.cost;
    this.forest++;
    this._push(`숲 이동 — ${nx.name}`);
    return true;
  }

  /* ── 한 틱 ── */
  tick(dt, rng = Math.random) {
    this.t += dt;

    // 1) 줍기 — 창고가 꽉 차면 버려진다(= 빨래통을 늘릴 이유)
    this._gatherAcc += this.gatherRate() * dt;
    const drop = FORESTS[this.forest].drop;
    let wasted = 0;
    const sellableNow = this.sellableTiers();
    while (this._gatherAcc >= 1) {
      this._gatherAcc -= 1;
      const tier = pickTier(drop, rng);
      // 팔 수 있는 등급만 창고 상한을 먹는다. 보물은 따로 무한히 쌓인다.
      if (sellableNow.has(tier) && this.storedTotal() >= this.rawCap()) { wasted++; continue; }
      this.raw[tier]++;
    }

    // 2) 씻기 — 지금 팔 수 있는 등급 중 비싼 것부터.
    //    팔 사람이 없는 등급은 안 씻고 창고에 둔다(= 나중에 그 동물이 오면 금광이 된다).
    this._washAcc += this.washRate() * dt;
    const sellable = this.sellableTiers();
    let stalled = false;
    for (let tier = T - 1; tier >= 0 && !stalled; tier--) {
      if (!sellable.has(tier)) continue;
      while (this.raw[tier] > 0 && this._washAcc >= WASH_COST[tier]) {
        if (this.cleanTotal() >= this.shelfCap()) { stalled = true; break; }
        this._washAcc -= WASH_COST[tier];
        this.raw[tier]--;
        this.clean[tier]++;
      }
    }
    // 씻을 게 없으면 손이 논다. 무한히 쌓아뒀다 한꺼번에 처리하는 걸 막는다.
    if (this._washAcc > this.washRate() * 2) this._washAcc = this.washRate() * 2;

    // 3) 판매 — 해금된 동물이 각자 주기대로 방문
    const sales = [];
    for (const a of this.animals()) {
      this._animalAcc[a.id] += dt;
      while (this._animalAcc[a.id] >= a.every) {
        this._animalAcc[a.id] -= a.every;
        const s = this._serve(a);
        if (s) sales.push(s);
      }
    }

    // 4) 새 동물 해금
    const nx = this.nextAnimal();
    if (nx && this.totalRevenue >= nx.animal.at) {
      this.seenAnimals.push(nx.animal.id);
      this._push(`${nx.animal.name}이(가) 마을에 왔다`);
      return { sales, wasted, newAnimal: nx.animal };
    }
    return { sales, wasted, newAnimal: null };
  }

  /**
   * 동물 한 마리가 원하는 등급 중 가장 비싼 걸 사간다.
   *
   * 사가는 양이 진열대 크기에 비례한다 — 이게 없으면 매출이 동물 방문 주기에
   * 갇혀서, 너구리를 아무리 고용해도 수입이 안 늘어난다. 실제로 그래서 게임이
   * 두 번 멈췄다. 방치형은 투자가 반드시 수입으로 이어져야 한다.
   */
  _serve(a) {
    const avail = a.wants.filter((t) => this.clean[t] > 0);
    if (!avail.length) return null;          // 재고 없음 = 손님을 놓친 것
    const tier = avail[avail.length - 1];
    const n = Math.min(a.qty * this.shelf, this.clean[tier]);
    const gain = Math.floor(PRICE[tier] * a.mult * n * this.fameMult());
    this.clean[tier] -= n;
    this.sold[tier] += n;
    this.money += gain;
    this.totalRevenue += gain;
    this.lifetimeRevenue += gain;
    return { animal: a, tier, n, gain };
  }

  /* ── 이사 (환생) ── */

  /** 지금 이사하면 받을 소문 */
  prestigeGain() {
    if (this.totalRevenue < PRESTIGE.minRevenue) return 0;
    return Math.floor(PRESTIGE.scale * Math.sqrt(this.totalRevenue / PRESTIGE.minRevenue));
  }

  canPrestige() { return this.prestigeGain() > this.fame * 0.1 && this.prestigeGain() > 0; }

  /** 가게는 처음부터 다시. 소문만 따라온다. */
  prestige() {
    const gain = this.prestigeGain();
    if (gain <= 0) return 0;
    const keep = {
      fame: this.fame + gain,
      moves: this.moves + 1,
      lifetimeRevenue: this.lifetimeRevenue,
      log: this.log,
    };
    Object.assign(this, new Sim(), keep);
    this._push(`이사 — 소문 +${gain} (총 ${keep.fame})`);
    return gain;
  }

  /**
   * 오프라인 수익. 방치형의 심장 — "껐다 켰더니 돈이 쌓여 있다"가 리텐션을 만든다.
   * 상한을 두는 이유: 없으면 한 달 뒤 접속해서 게임이 끝나버린다.
   * 그리고 그 상한이 곧 광고 시청("2배로 받기")을 팔 자리가 된다.
   */
  offline(seconds, { cap = 2 * 3600, efficiency = 0.55 } = {}) {
    const real = Math.min(seconds, cap);
    const before = this.money;
    const step = 1.0;
    for (let s = 0; s < real; s += step) this.tick(step);
    const earned = Math.floor((this.money - before) * efficiency);
    this.money = before + earned;
    return { earned, seconds: real, capped: seconds > cap };
  }

  _push(msg) {
    this.log.unshift({ t: this.t, msg });
    this.log.length = Math.min(this.log.length, 30);
  }

  save() {
    const { log, ...rest } = this;
    return JSON.parse(JSON.stringify(rest));
  }
}

function pickTier(drop, rng) {
  let r = rng();
  for (let i = 0; i < drop.length; i++) {
    r -= drop[i];
    if (r <= 0) return i;
  }
  return 0;
}

/** 큰 숫자 표기. 방치형은 이게 없으면 화면이 터진다. */
export function fmt(n) {
  if (n < 1000) return Math.floor(n).toString();
  const U = ['', 'K', 'M', 'B', 'T', 'aa', 'ab', 'ac'];
  const i = Math.min(Math.floor(Math.log10(n) / 3), U.length - 1);
  const v = n / Math.pow(1000, i);
  return (v < 10 ? v.toFixed(2) : v < 100 ? v.toFixed(1) : Math.floor(v)) + U[i];
}
