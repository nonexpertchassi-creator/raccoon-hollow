/* interior.js — 가게 안. 그리기만 한다.
 *
 * 왜 만들었나: 마을 한 화면에 가게 다섯을 다 담으니 가게 하나가 화면 폭의
 * 35%밖에 안 됐다. 그래서 좌판 글자가 폰에서 1.9mm가 됐고, 좌판을 두 줄로
 * 바꿔 겨우 11px을 만들었다. **한 화면에 하나만 보여주면 이 문제가 통째로
 * 없어진다** — 같은 물건이 2.5배로 커진다.
 *
 * 그래서 화면이 둘이 됐다.
 *   마을  어디에 무엇이 있는지 · 어느 가게를 살릴지     (scene.js)
 *   가게 안  그 가게에서 무슨 일이 벌어지는지            (여기)
 *
 * 시점은 **비스듬히 내려다본 것**(아이소메트릭)이다. 바닥을 마름모로 깔면
 * 방이 평면이 아니라 공간으로 읽힌다. 사람은 지금 그림 그대로 정면을 본다 —
 * 아이소메트릭 배경에 정면 캐릭터를 얹는 건 흔한 조합이고, 그래야 이미
 * 그린 너구리를 다시 안 그린다.
 */

import { G } from './core/engine.js';
import { Juice, Sfx } from './core/juice.js';
import { SHOPS, STOCK_CAP } from './content.js';
import { fmt, itemById } from './sim.js';
import { drawArt } from './art.js';

const IW = 480;

const IC = {
  floor:  '#d8c9a8', floor2: '#cdbd99', grout: '#bfae8a',
  wall:   '#e6dcc4', wall2:  '#d6c9ab', wallTop: '#f2ead6',
  wood:   '#8a6a45', wood2:  '#6d5236',
  ink:    '#2b241b', ink2:   '#5a4e3d', ink3: '#8a7a63',
  paper:  '#ece2cb', paper2: '#dccfb2',
  gold:   '#a8763e', jade:   '#4a7c59', red: '#c7563f',
};

/* 방 배치.
 *
 * 창 높이가 기기마다 다르므로(폰 634~991) 고정 좌표로 잡으면 어떤 기기에선
 * 방이 화면 아래 절반을 비운 채 뜬다. 실제로 처음에 그랬다.
 * **보이는 높이를 받아 그때그때 계산한다.**
 *
 * 작업대 넷은 **뒤쪽 두 벽에 붙여** 놓는다. 마름모 네 꼭짓점에 놓았더니
 * 앞쪽 작업대가 문·손님·점장과 같은 자리를 다퉜다. 벽에 붙이면 앞 절반이
 * 통째로 비어 사람이 오갈 자리가 된다.
 */
const BAR_H = 54;

/* 방을 **화면보다 크게** 잡아 좌우가 잘리게 한다.
 *
 * 처음엔 마름모를 화면 폭 안에 다 넣었더니 방이 화면 가운데 조그맣게 뜨고
 * 위아래가 텅 비었다. 실제 이런 게임들은 방보다 카메라가 안쪽에 있어서
 * 벽이 화면 밖으로 잘린다 — 그래야 "안에 들어와 있다"가 된다.
 *
 * 바닥 마름모는 2:1(가로:세로)이 아이소메트릭의 기본 비율이다.
 * 세로를 창 높이에 맞춰 정하고 가로는 그 두 배로 두면, 폭 480을 넘겨
 * 좌우가 저절로 잘린다.
 */
function layout(viewH) {
  const h = Math.max(560, viewH);
  /* 가로는 화면 폭에 맞추고(240), 세로는 남는 높이를 채우게 잡는다.
   *
   * 아이소메트릭 교과서 비율은 2:1이지만 그대로 하면 세로가 짧아 방이
   * 화면 위아래를 텅 비운 채 뜬다. 반대로 2:1을 지키려고 가로를 늘리면
   * 벽에 붙인 작업대 넷 중 둘이 화면 밖으로 나간다 — 실제로 그랬다.
   * 폭에 맞추고 깊이만 늘린 '눌린 아이소메트릭'으로 간다. */
  const hw = 260;                          // 폭 480을 살짝 넘겨 좌우가 조금 잘린다
  const wall = 150;
  const hh = Math.min(230, (h - BAR_H - wall) / 2);
  const cy = BAR_H + wall + hh + (h - BAR_H - wall - hh * 2) / 2;
  const top = cy - hh;
  /* 작업대는 뒤쪽 두 벽을 따라 놓는다. 앞 절반은 통째로 비워 사람이 오간다.
   * 0.30과 0.70인 이유가 둘이다.
   *   더 붙이면 — 뒤쪽 두 작업대가 x축으로 겨우 104px 떨어져 이름표가 겹친다
   *   더 벌리면 — 앞쪽 두 작업대가 화면 밖으로 나간다(가로가 세로의 1.13배) */
  const on = (dir, t) => ({ x: 240 + dir * hw * t, y: top + hh * t });
  return {
    room: { cx: 240, cy, hw, hh, wall },
    desks: [on(-1, 0.30), on(-1, 0.70), on(1, 0.30), on(1, 0.70)],
    door: { x: 240, y: cy + hh * 0.88 },
    counter: { x: 240, y: cy + hh * 0.34 },
  };
}

export class Interior {
  constructor(sim, onClose, onPromote) {
    this.sim = sim;
    this.onClose = onClose;
    this.onPromote = onPromote;
    this.idx = 0;
    this.t = 0;
    this.L = layout(800);
    this.mgr = { x: 240, y: this.L.counter.y, at: 0, wait: 0, face: 1, state: 'work' };
    this.guests = [];
    this.coins = [];
    this.flash = {};
    this.busy = 0;          // 손님 응대 남은 시간
    this.drag = null;
  }

  open(idx) {
    this.idx = idx;
    this.guests.length = 0;
    this.coins.length = 0;
    this.busy = 0;
  }

  get shop() { return SHOPS[this.idx]; }
  /** 이 가게에서 열린 품목 (최대 4) */
  get items() { return this.shop.items.filter((it) => this.sim.isOpen(it.id)); }

  /* ── 바깥에서 알려주는 사건 ── */
  onSale(sale) {
    // 이 가게 것만 받는다. 다른 가게 거래는 마을 화면에서만 보인다.
    const lines = sale.lines.filter((ln) => ln.item.shop === this.shop.id);
    if (!lines.length || this.guests.length > 3) return;
    this.guests.push({
      face: sale.guest.face, id: sale.guest.id,
      lines, gain: lines.reduce((a, l) => a + l.gain, 0),
      n: lines.reduce((a, l) => a + l.n, 0),
      x: this.L.door.x + (Math.random() - 0.5) * 40, y: this.L.door.y + 46,
      state: 'in', wait: 0, paid: false, bob: Math.random() * 6,
    });
  }

  /* ── 매 프레임 ── */
  update(dt, pointer, viewH) {
    if (viewH) this.L = layout(viewH);
    this.t += dt;
    this.busy = Math.max(0, this.busy - dt);
    for (const k of Object.keys(this.flash)) {
      this.flash[k] -= dt;
      if (this.flash[k] <= 0) delete this.flash[k];
    }

    // 손님 — 문에서 계산대까지 걸어와 사고 나간다
    const counter = this.L.counter;
    for (const g of this.guests) {
      if (g.state === 'in') {
        const dy = counter.y - g.y, dx = counter.x - g.x;
        const d = Math.hypot(dx, dy);
        if (d > 3) {
          const s = Math.min(d, 96 * dt);
          g.x += dx / d * s; g.y += dy / d * s;
        } else { g.state = 'buy'; g.wait = 2.3; this.busy = 3.4; }
      } else if (g.state === 'buy') {
        g.wait -= dt;
        if (!g.paid && g.wait <= 1.2) {
          g.paid = true;
          for (const ln of g.lines) this.flash[ln.item.id] = 0.5;
          for (let k = 0; k < 5; k++) {
            this.coins.push({
              x: g.x + (Math.random() - 0.5) * 20, y: g.y - 16,
              vx: (Math.random() - 0.5) * 90, vy: -110 - Math.random() * 50,
              t: 1.1, r: 11 + Math.random() * 3,
            });
          }
          Sfx.coin();
        }
        if (g.wait <= 0) g.state = 'out';
      } else {
        g.y += 110 * dt;
      }
    }
    this.guests = this.guests.filter((g) => g.y < this.L.door.y + 110);

    // 점장 — 손님이 있으면 계산대로, 없으면 작업대를 차례로 돈다
    const m = this.mgr;
    let tx, ty;
    if (this.busy > 0) { tx = counter.x - 52; ty = counter.y + 14; }
    else {
      m.wait += dt;
      const ds = this.items.length || 1;
      if (m.wait > 5) { m.wait = 0; m.at = (m.at + 1) % ds; }
      const d = this.L.desks[Math.min(m.at, 3)];
      tx = d.x + (d.x < 240 ? 54 : -54); ty = d.y + 30;
    }
    const dx = tx - m.x, dy = ty - m.y, d = Math.hypot(dx, dy);
    if (d > 2) {
      const s = Math.min(d, 150 * dt);
      m.x += dx / d * s; m.y += dy / d * s;
      m.state = 'walk'; m.face = Math.abs(dx) > 1 ? Math.sign(dx) : (m.face || 1);
    } else {
      m.state = this.busy > 0 ? 'sell' : 'work';
      if (m.state === 'sell') m.face = 1;
    }

    for (const co of this.coins) {
      co.t -= dt; co.vy += 420 * dt;
      co.x += co.vx * dt; co.y += co.vy * dt;
    }
    this.coins = this.coins.filter((c) => c.t > 0);

    this._input(pointer);
  }

  _input(p) {
    if (p.justDown) this.drag = { x: p.x, y: p.y, moved: 0 };
    else if (this.drag && p.down) {
      this.drag.moved += Math.hypot(p.x - this.drag.x, p.y - this.drag.y);
      this.drag.x = p.x; this.drag.y = p.y;
    } else if (this.drag) {
      if (this.drag.moved < 8) this._tap(p.x, p.y);
      this.drag = null;
    }
  }

  _tap(x, y) {
    // 닫기 — 오른쪽 위
    if (x > IW - 64 && y < 54) { this.onClose(); return; }
    // 승급 단추
    if (this.sim.canPromote(this.shop.id) && y > 60 && y < 98 && x > IW / 2 - 76 && x < IW / 2 + 76) {
      this.onPromote(this.shop.id); return;
    }
    // 작업대 — 눌러서 강화, 잠긴 자리는 눌러서 연다
    const slots = this.shop.items.slice(0, 4);
    for (let i = 0; i < slots.length; i++) {
      const d = this.L.desks[i];
      if (Math.abs(x - d.x) > 62 || y < d.y - 58 || y > d.y + 40) continue;
      const it = slots[i];
      if (!this.sim.isOpen(it.id)) {
        if (this.sim.canOpenItem(it.id) && this.sim.openItem(it.id)) { Sfx.win(); Juice.shake(6); }
        else Sfx.deny();
        return;
      }
      const n = this.sim.affordableLevels(it.id);
      if (n > 0 && this.sim.levelUpMany(it.id, n)) { Sfx.click(); this.flash[it.id] = 0.35; }
      else Sfx.deny();
      return;
    }
  }

  /* ── 그리기 ── */
  draw(c, viewH) {
    const shop = this.shop;
    // 벽 뒤 배경
    if (viewH) this.L = layout(viewH);
    G.rect(c, 0, 0, IW, Math.max(viewH, 900), '#8f8875');
    this._room(c);

    const slots = shop.items.slice(0, 4);
    const layer = [];
    for (let i = 0; i < slots.length; i++) {
      const d = this.L.desks[i];
      layer.push({ z: d.y, d: () => this._desk(c, i, slots[i]) });
    }
    for (const g of this.guests) layer.push({ z: g.y, d: () => this._guest(c, g) });
    layer.push({ z: this.mgr.y, d: () => this._mgr(c) });
    layer.sort((a, b) => a.z - b.z);
    for (const l of layer) l.d();

    for (const co of this.coins) this._coin(c, co);
    this._bar(c);
  }

  _room(c) {
    const { cx, cy, hw, hh } = this.L.room;
    /* 뒤쪽 두 벽. 마름모 바닥의 위 두 변에서 위로 세운다.
     * 앞 두 벽은 안 그린다 — 그려 버리면 안이 안 보인다(인형의 집 단면). */
    const wallH = this.L.room.wall;
    const top = { x: cx, y: cy - hh }, left = { x: cx - hw, y: cy }, right = { x: cx + hw, y: cy };
    for (const [a, b, tone] of [[left, top, IC.wall], [top, right, IC.wall2]]) {
      c.fillStyle = tone;
      c.beginPath();
      c.moveTo(a.x, a.y); c.lineTo(b.x, b.y);
      c.lineTo(b.x, b.y - wallH); c.lineTo(a.x, a.y - wallH);
      c.closePath(); c.fill();
    }
    // 벽 윗선 — 두께가 있어 보이게
    c.fillStyle = IC.wallTop;
    c.beginPath();
    c.moveTo(left.x, left.y - wallH); c.lineTo(top.x, top.y - wallH); c.lineTo(right.x, right.y - wallH);
    c.lineTo(right.x, right.y - wallH - 9); c.lineTo(top.x, top.y - wallH - 9);
    c.lineTo(left.x, left.y - wallH - 9);
    c.closePath(); c.fill();

    // 바닥 마름모
    c.fillStyle = IC.floor;
    c.beginPath();
    c.moveTo(cx, cy - hh); c.lineTo(cx + hw, cy); c.lineTo(cx, cy + hh); c.lineTo(cx - hw, cy);
    c.closePath(); c.fill();
    // 바닥 무늬 — 마름모를 6×6으로 나눈 선
    c.save();
    c.clip();
    c.strokeStyle = IC.grout; c.lineWidth = 1.2;
    for (let i = 1; i < 6; i++) {
      const t = i / 6;
      c.beginPath();
      c.moveTo(cx - hw + hw * t, cy - hh * t); c.lineTo(cx + hw * t, cy + hh * t);
      c.stroke();
      c.beginPath();
      c.moveTo(cx + hw - hw * t, cy - hh * t); c.lineTo(cx - hw * t, cy + hh * t);
      c.stroke();
    }
    c.restore();

    // 문 — 앞쪽 아래. 손님이 여기로 들어온다
    G.round(c, this.L.door.x - 40, this.L.door.y - 5, 80, 13, 5, IC.wood2);
    G.text(c, '들머리', this.L.door.x, this.L.door.y - 16, { size: 12.5, fill: IC.ink3, weight: 800 });
  }

  /** 작업대 하나 = 품목 한 칸.
   *  마을에서 71px이던 칸이 여기선 120px이다. 숫자가 15 → 26으로 커진다. */
  _desk(c, i, it) {
    const d = this.L.desks[i];
    const open = this.sim.isOpen(it.id);
    const fl = this.flash[it.id] || 0;

    c.fillStyle = 'rgba(0,0,0,.13)';
    c.beginPath(); c.ellipse(d.x, d.y + 14, 52, 15, 0, 0, 7); c.fill();

    if (!open) {
      c.save();
      c.setLineDash([8, 6]); c.lineWidth = 2; c.strokeStyle = 'rgba(60,52,36,.42)';
      c.beginPath(); c.roundRect(d.x - 52, d.y - 56, 104, 68, 9); c.stroke();
      c.restore();
      const asked = this.sim.asked.includes(it.id);
      G.text(c, asked ? itemById(it.id).name : '? ? ?', d.x, d.y - 36,
        { size: 15, fill: IC.ink2, weight: 800 });
      if (asked) {
        const can = this.sim.money >= itemById(it.id).cost;
        G.round(c, d.x - 48, d.y - 20, 96, 28, 9, can ? IC.jade : 'rgba(60,52,36,.3)');
        G.text(c, `${fmt(itemById(it.id).cost)}냥`, d.x, d.y - 6,
          { size: 13.5, fill: '#fff', weight: 800 });
      } else {
        G.text(c, '손님이 물어봐야 연다', d.x, d.y - 10, { size: 11.5, fill: IC.ink3, weight: 700 });
      }
      return;
    }

    const st = this.sim.items[it.id];
    const shown = Math.min(STOCK_CAP, st.stock);
    const capped = shown >= STOCK_CAP;

    /* 위에서 아래로 딱 세 층만 쓴다 — 고리 · 상판 · 이름표.
     * 처음엔 단추를 따로 한 층 더 얹어 108px이 됐는데, 그러면 앞 작업대가
     * 뒤 작업대의 이름표를 덮었다. 이름과 레벨을 한 줄에 합쳐 93px로 줄였다. */
    const rx = d.x, ry = d.y - 31, rr = 25;
    const p = capped ? 1 : Math.max(0, Math.min(1, st.prog / this.sim.craftTime(it.id)));
    G.circle(c, rx, ry, rr - 3, 'rgba(252,246,232,.95)');
    c.save();
    c.lineWidth = 5.5; c.lineCap = 'round';
    c.strokeStyle = 'rgba(43,36,27,.25)';
    c.beginPath(); c.arc(rx, ry, rr, 0, Math.PI * 2); c.stroke();
    c.strokeStyle = capped ? '#ff8a63' : '#e8b93f';
    c.beginPath(); c.arc(rx, ry, rr, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke();
    c.restore();
    G.text(c, String(shown), rx, ry - 3, { size: fl > 0 ? 25 : 23, fill: IC.ink, weight: 800 });
    G.text(c, `/${STOCK_CAP}`, rx, ry + 13, { size: 10.5, fill: IC.ink3, weight: 700 });

    // 물건 — 고리 왼쪽에 세워 둔다. 그림이 없으면 자리만 잡아 둔다
    if (!drawArt(c, 'items', it.id, d.x - 36, d.y - 6, 32, 48))
      G.round(c, d.x - 50, d.y - 44, 28, 38, 5, 'rgba(43,36,27,.14)');

    // 작업대 상판과 다리
    G.round(c, d.x - 52, d.y - 4, 104, 15, 4, fl > 0 ? '#e8c98a' : this.shop.color);
    G.round(c, d.x - 46, d.y + 9, 8, 11, 2, IC.wood2);
    G.round(c, d.x + 38, d.y + 9, 8, 11, 2, IC.wood2);

    /* 이름과 레벨을 한 줄에. 눌러서 강화하는 자리이기도 하다.
     * 바닥 위에 글자만 얹으면 바닥 무늬와 겹쳐 안 읽힌다 — 판을 깐다.
     * 글자를 길게 쓰면 뒤쪽 두 작업대의 이름표가 서로 겹친다(104px 간격). */
    const lv = this.sim.lv(it.id), max = this.sim.atMax(it.id);
    const n = max ? 0 : this.sim.affordableLevels(it.id);
    const txt = `${itemById(it.id).name} · Lv${lv}`;
    const tw = 20 + txt.length * 8 + (n > 0 ? 30 : 0);
    G.round(c, d.x - tw / 2, d.y + 14, tw, 24, 9,
      max ? '#7b7360' : n > 0 ? IC.jade : 'rgba(43,36,27,.7)');
    G.text(c, txt, d.x - (n > 0 ? 15 : 0), d.y + 26, { size: 12.5, fill: '#fff8ec', weight: 800 });
    if (n > 0) {
      // 몇 레벨을 한 번에 올릴 수 있는지 — 지금 누르면 얼마나 오르는가
      G.round(c, d.x + tw / 2 - 34, d.y + 17, 30, 18, 7, 'rgba(255,248,236,.9)');
      G.text(c, `+${n}`, d.x + tw / 2 - 19, d.y + 26, { size: 11.5, fill: IC.jade, weight: 800 });
    } else if (!max) {
      G.text(c, fmt(this.sim.levelCostMany(it.id, 1)) + '냥', d.x, d.y + 46,
        { size: 11, fill: IC.ink2, weight: 700 });
    }
  }

  _mgr(c) {
    const m = this.mgr;
    const bob = m.state === 'walk' ? Math.abs(Math.sin(this.t * 9)) * 4
              : m.state === 'work' ? Math.abs(Math.sin(this.t * 2.6)) * 3 : Math.sin(this.t * 3) * 1.6;
    c.fillStyle = 'rgba(0,0,0,.16)';
    c.beginPath(); c.ellipse(m.x, m.y + 2, 15, 6, 0, 0, 7); c.fill();
    if (m.state === 'sell') {
      G.circle(c, m.x + 20, m.y - 26 - bob, 8, '#c9a227');
    }
    c.save();
    c.translate(m.x, m.y + 4);
    if ((m.face || 1) < 0) c.scale(-1, 1);
    if (m.state === 'walk') c.rotate(Math.sin(this.t * 9) * 0.1);
    const pose = m.state === 'sell' ? 'sell' : 'work';
    if (!drawArt(c, 'clerks', `${this.shop.id}-${pose}`, 0, -bob, 52, 52)
     && !drawArt(c, 'hero', pose === 'sell' ? 'raccoon-sell' : 'raccoon-make', 0, -bob, 52, 52))
      G.text(c, '🦝', 0, -22 - bob, { size: 52, fill: '#000' });
    c.restore();
  }

  _guest(c, g) {
    const bob = g.state === 'buy' ? Math.sin(this.t * 3) * 1.6 : Math.abs(Math.sin(this.t * 8)) * 4;
    c.fillStyle = 'rgba(0,0,0,.16)';
    c.beginPath(); c.ellipse(g.x, g.y + 2, 14, 6, 0, 0, 7); c.fill();
    c.save();
    c.translate(g.x, g.y + 4);
    if (!drawArt(c, 'guests', g.id, 0, -bob, 46, 46))
      G.text(c, g.face, 0, -20 - bob, { size: 44, fill: '#000' });
    c.restore();
    if (g.state === 'buy' && !g.paid) {
      const txt = `${g.n}개`;
      const tw = 16 + txt.length * 9;
      G.round(c, g.x - tw / 2, g.y - 82, tw, 26, 9, 'rgba(252,246,232,.97)');
      G.text(c, txt, g.x, g.y - 69, { size: 15, fill: IC.ink, weight: 800 });
    }
  }

  _coin(c, co) {
    const a = Math.min(1, co.t * 2);
    c.globalAlpha = a;
    G.circle(c, co.x, co.y, co.r, '#e8b93f');
    G.circle(c, co.x, co.y, co.r * 0.62, '#c9a227');
    G.rect(c, co.x - co.r * 0.2, co.y - co.r * 0.2, co.r * 0.4, co.r * 0.4, '#8a6a45');
    c.globalAlpha = 1;
  }

  /** 위쪽 띠 — 어느 가게인지, 승급할 수 있는지, 나가는 길 */
  _bar(c) {
    const shop = this.shop, rk = this.sim.rankOf(shop.id);
    G.rect(c, 0, 0, IW, 54, 'rgba(43,36,27,.82)');
    G.text(c, rk > 0 ? `${shop.sign} ${shop.name} · ${shop.ranks[rk]}` : `${shop.sign} ${shop.name}`,
      20, 27, { size: 19, fill: '#fff8ec', weight: 800, align: 'left' });
    G.round(c, IW - 58, 12, 44, 30, 9, 'rgba(255,248,236,.2)');
    G.text(c, '나감', IW - 36, 27, { size: 13, fill: '#fff8ec', weight: 800 });

    if (this.sim.canPromote(shop.id)) {
      const bob = Math.sin(this.t * 4) * 2.5;
      G.round(c, IW / 2 - 74, 62 + bob, 148, 32, 11, IC.red);
      G.text(c, '승급할 수 있다!', IW / 2, 78 + bob, { size: 15, fill: '#fff3dd', weight: 800 });
    }
  }
}
