/* content.js — 너구리 만물상: 내용물 전부.
 *
 * 구조:
 *   마을에 가게 자리가 여러 개 있고, 처음엔 대장간 하나만 살아있다.
 *   가게마다 품목 칸이 있고, 칸을 열면 그 물건이 자동으로 계속 만들어진다.
 *   손님이 와서 사간다. 돈이 모이면 옆집을 되살린다.
 *
 * "마을이 구제된다" = 빈 가게가 하나씩 채워지는 것.
 * 시대는 조선. 곡괭이·낫·붓·한지 전부 그 시대 물건이다.
 */

/* ───────────── 가게 ─────────────
 * 순서대로 해금된다. 가게 하나가 열리면 그 안의 첫 품목도 같이 열린다.
 */
export const SHOPS = [
  {
    id: 'smith', name: '대장간', sign: '⚒', cost: 0,
    desc: '무쇠를 두드려 연장을 만든다',
    color: '#b8622f',
    items: [
      { id: 'pick',   name: '곡괭이', price: 12,     time: 3.0, cost: 0 },
      { id: 'sickle', name: '낫',     price: 34,     time: 3.8, cost: 260 },
      { id: 'hoe',    name: '호미',   price: 95,     time: 4.6, cost: 2_200 },
      { id: 'axe',    name: '도끼',   price: 260,    time: 5.6, cost: 18_000 },
    ],
  },
  {
    id: 'brush', name: '필방', sign: '筆', cost: 9_000,
    desc: '붓과 먹을 다룬다',
    color: '#3f6f4a',
    items: [
      { id: 'brush',    name: '붓',   price: 700,    time: 4.2, cost: 0 },
      { id: 'ink',      name: '먹',   price: 1_900,  time: 5.0, cost: 60_000 },
      { id: 'inkstone', name: '벼루', price: 5_200,  time: 6.2, cost: 420_000 },
    ],
  },
  {
    id: 'paper', name: '지물포', sign: '紙', cost: 900_000,
    desc: '닥나무를 떠서 종이를 만든다',
    color: '#8a7440',
    items: [
      { id: 'hanji',  name: '한지',   price: 14_000,  time: 5.0, cost: 0 },
      { id: 'fan',    name: '부채',   price: 38_000,  time: 6.0, cost: 5_000_000 },
      { id: 'window', name: '창호지', price: 105_000, time: 7.2, cost: 34_000_000 },
    ],
  },
  {
    id: 'pot', name: '옹기점', sign: '甕', cost: 120_000_000,
    desc: '흙을 빚어 항아리를 굽는다',
    color: '#6b4a3a',
    items: [
      { id: 'jar',   name: '옹기',   price: 280_000,   time: 5.4, cost: 0 },
      { id: 'bowl',  name: '사발',   price: 760_000,   time: 6.4, cost: 700_000_000 },
      { id: 'celad', name: '청자',   price: 2_100_000, time: 8.0, cost: 5_000_000_000 },
    ],
  },
  {
    id: 'herb', name: '약재상', sign: '藥', cost: 20_000_000_000,
    desc: '산에서 캔 것을 말리고 썬다',
    color: '#4a5f7a',
    items: [
      { id: 'root',    name: '도라지', price: 5_600_000,  time: 5.6, cost: 0 },
      { id: 'ginseng', name: '산삼',   price: 15_000_000, time: 7.0, cost: 120_000_000_000 },
    ],
  },
];

/* ───────────── 손님 ─────────────
 * 손님은 두 가지 일을 한다:
 *   1) 재고를 사간다 (수입)
 *   2) 아직 없는 물건을 물어본다 (다음 목표를 알려줌)
 *
 * 2번이 이 게임의 핵심이다. 방치형에서 제일 흔한 문제가 "뭘 사야 할지 모르겠다"인데,
 * 손님이 물어보는 순간 그게 답이 된다. 토끼가 곡괭이를 묻는 게 게임의 첫 장면이다.
 */
export const GUESTS = [
  { id: 'rabbit',   name: '토끼',   face: '🐰', every: 3.0,  qty: 3, pay: 1.0, at: 0 },
  { id: 'squirrel', name: '다람쥐', face: '🐿️', every: 4.0,  qty: 4, pay: 1.2, at: 400 },
  { id: 'badger',   name: '오소리', face: '🦡', every: 5.5,  qty: 5, pay: 1.5, at: 12_000 },
  { id: 'fox',      name: '여우',   face: '🦊', every: 7.0,  qty: 7, pay: 2.0, at: 300_000 },
  { id: 'deer',     name: '사슴',   face: '🦌', every: 8.5,  qty: 9, pay: 2.8, at: 9_000_000 },
  { id: 'bear',     name: '곰',     face: '🐻', every: 10.0, qty: 12, pay: 4.0, at: 400_000_000 },
  { id: 'crane',    name: '두루미', face: '🦢', every: 12.0, qty: 16, pay: 6.0, at: 15_000_000_000 },
];

/** 손님이 "이런 것도 있소?" 하고 물어보는 대사 */
export const ASK_LINES = [
  '{item} 있소?', '혹시 {item} 파시오?', '{item}을 찾고 있는데…',
  '{item} 하나 구할 수 있겠소?', '{item}은 안 파시나?',
];

/* ───────────── 레벨업 ─────────────
 * 품목마다 따로 올린다. 올리면 값이 오르고 만드는 시간이 줄어든다.
 * growth 1.15 근처여야 "조금만 더 모으면 살 수 있다"가 유지된다.
 */
export const LEVEL = {
  /* 규칙 하나만 지키면 된다: **비용이 수입보다 빨리 올라야 한다.**
   *
   * 처음엔 가격도 지수(×1.13/레벨)로 올렸다가 매출이 10의 141제곱까지 폭주했다.
   * 비용은 1.155배씩 오르는데 가격이 1.13 × 이정표 2배(=1.16배)로 올라서,
   * 레벨을 올릴수록 본전이 빨리 빠지는 무한 루프가 됐다.
   *
   * 그래서 가격은 **선형**으로만 올린다. 레벨업은 갈수록 손해가 되고,
   * 그 벽을 넘는 방법은 **새 품목과 새 가게**뿐이다 — 그게 이 게임의 진행이니까. */
  costGrowth: 1.12,    // 레벨업 비용: 지수
  priceStep: 0.5,      // 판매가: 레벨당 기본가의 50%씩 선형 증가
  timeReduce: 0.985,   // 제작 시간 (하한 있음)
  timeFloor: 0.40,
};

/** 25레벨마다 그 품목의 생산이 2배가 된다. 24→25가 제일 신나야 한다. */
export const MILESTONE_EVERY = 25;
export const MILESTONE_MULT = 2;

/** 진열 가능한 재고 상한. 넘치면 생산이 멈춘다 = 손님이 와야 다시 돈다. */
export const STOCK_CAP = 40;

/** 손님 한 명이 몇 종류를 집어가는가.
 *
 * 예전엔 이 개념이 아예 없었다 — 손님이 제일 비싼 것 한 종류만 사갔고,
 * 그래서 싼 품목은 재고 상한에 박혀 생산까지 멈췄다. 12개 중 7개가 그렇게
 * 죽어 있었다. 곡괭이를 193레벨까지 올려도 매출 기여가 0이었다.
 *
 * 이 값을 키우면 손님이 더 얇게 여러 품목을 훑는다. 3이면 한 명이
 * 대략 세 종류를 건드린다. */
export const BASKET_SPREAD = 3;

/** 오프라인 수익 — 방치형의 심장. 껐다 켰을 때 쌓여 있어야 다시 켠다. */
export const OFFLINE = { capHours: 4, efficiency: 0.6 };
