/* engine.js — 초경량 캔버스 엔진.
 * Unity/Godot을 안 쓴 이유: 이번 목표는 "게임 만들기"가 아니라 "출시 파이프라인 통과"다.
 * 엔진이 무거우면 빌드·용량·스토어 요구사항에서 시간을 다 잡아먹는다.
 * 이 파일 전체가 8KB 미만이고, 3개 게임이 이걸 공유한다. = 양산 가능한 구조.
 */

import { Juice, Sfx } from './juice.js';

export class Engine {
  /**
   * @param fit  'contain' 통째로 우겨넣는다 — 남는 쪽에 빈 띠가 생긴다
   *             'width'   가로만 맞추고 세로는 기기가 주는 대로 받는다
   *
   * 세로 게임은 'width'가 맞다. 'contain'으로 두면 iPhone SE에서 좌우 50px,
   * iPad에서 상하 98px씩 빈 띠가 생긴다. 가로만 맞추면 여백이 아예 없고,
   * 세로로 넘치거나 모자란 양은 화면을 밀어 훑는 것으로 흡수된다.
   */
  constructor(canvas, { w = 480, h = 800, bg = '#0b0d17', fit = 'contain' } = {}) {
    this.cv = canvas;
    this.ctx = canvas.getContext('2d');
    this.W = w; this.H = h; this.bg = bg; this.fit = fit;
    // 실제로 보이는 범위(가상 단위). 기기마다 다르므로 장면이 이걸 보고 그린다.
    this.viewW = w; this.viewH = h;
    this.scenes = {}; this.scene = null;
    this.keys = new Set(); this.pointer = { x: 0, y: 0, down: false, justDown: false };
    this.running = false; this.t = 0; this.paused = false;
    this._fit();
    addEventListener('resize', () => this._fit());
    this._bindInput();
  }

  /* 화면 비율 유지 + DPR 대응. 모바일에서 흐릿하게 나오면 리뷰가 나빠진다. */
  _fit() {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const box = this.cv.parentElement.getBoundingClientRect();
    const s = this.fit === 'width'
      ? box.width / this.W
      : Math.min(box.width / this.W, box.height / this.H);
    this.scale = s;
    const cw = this.fit === 'width' ? box.width : this.W * s;
    const ch = this.fit === 'width' ? box.height : this.H * s;
    this.viewW = cw / s;
    this.viewH = ch / s;
    this.cv.style.width = cw + 'px';
    this.cv.style.height = ch + 'px';
    this.cv.width = Math.round(cw * dpr);
    this.cv.height = Math.round(ch * dpr);
    this.ctx.setTransform(s * dpr, 0, 0, s * dpr, 0, 0);
  }

  _bindInput() {
    addEventListener('keydown', (e) => {
      if ([' ', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)) e.preventDefault();
      if (!this.keys.has(e.key)) this._justKey = e.key;
      this.keys.add(e.key);
    });
    addEventListener('keyup', (e) => this.keys.delete(e.key));

    const pos = (e) => {
      const r = this.cv.getBoundingClientRect();
      const p = e.touches?.[0] || e;
      return { x: (p.clientX - r.left) / this.scale, y: (p.clientY - r.top) / this.scale };
    };
    const down = (e) => {
      Sfx.unlock(); // 브라우저는 첫 사용자 입력 전엔 소리를 막는다
      Object.assign(this.pointer, pos(e), { down: true, justDown: true });
      e.preventDefault();
    };
    const move = (e) => { Object.assign(this.pointer, pos(e)); };
    const up = () => { this.pointer.down = false; };

    this.cv.addEventListener('mousedown', down);
    this.cv.addEventListener('mousemove', move);
    addEventListener('mouseup', up);
    this.cv.addEventListener('touchstart', down, { passive: false });
    this.cv.addEventListener('touchmove', move, { passive: false });
    addEventListener('touchend', up);
  }

  keyPressed(k) { const j = this._justKey === k; return j; }
  add(name, scene) { this.scenes[name] = scene; scene.engine = this; return this; }

  go(name, data) {
    this.scene?.exit?.();
    this.scene = this.scenes[name];
    this.scene.enter?.(data);
    return this.scene;
  }

  start(name) {
    this.go(name);
    this.running = true;
    let last = performance.now();
    const frame = (now) => {
      if (!this.running) return;
      const dt = Math.min((now - last) / 1000, 0.05); // 탭 전환 후 점프 방지
      last = now; this.t += dt;

      // 히트스톱: 충돌 순간 전체를 멈춘다. 이게 "타격감"의 정체다.
      if (Juice.freezeT > 0) Juice.freezeT -= dt;
      else if (!this.paused) this.scene?.update?.(dt);
      Juice.update(dt);

      const c = this.ctx;
      c.save();
      if (Juice.shakeAmt > 0) {
        const s = Juice.shakeAmt;
        c.translate((Math.random() - 0.5) * s * 2, (Math.random() - 0.5) * s * 2);
      }
      // 흔들려도 가장자리가 비지 않도록 배경을 넉넉히 칠한다
      c.fillStyle = this.bg;
      c.fillRect(-60, -60, this.viewW + 120, this.viewH + 120);
      this.scene?.draw?.(c);
      Juice.draw(c);
      c.restore();

      this.pointer.justDown = false; this._justKey = null;
      requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  }
}

/* ── 그리기 헬퍼. 이미지 에셋 0개로 게임을 만들기 위한 최소 도구 ── */
export const G = {
  rect(c, x, y, w, h, fill) { c.fillStyle = fill; c.fillRect(x, y, w, h); },

  round(c, x, y, w, h, r, fill) {
    c.fillStyle = fill; c.beginPath(); c.roundRect(x, y, w, h, r); c.fill();
  },

  circle(c, x, y, r, fill) {
    c.fillStyle = fill; c.beginPath(); c.arc(x, y, r, 0, 7); c.fill();
  },

  text(c, s, x, y, { size = 20, fill = '#fff', align = 'center', weight = 600, font = 'system-ui' } = {}) {
    c.fillStyle = fill; c.textAlign = align; c.textBaseline = 'middle';
    c.font = `${weight} ${size}px ${font}`;
    c.fillText(s, x, y);
  },

  glow(c, x, y, r, color) {
    const g = c.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, color); g.addColorStop(1, 'transparent');
    c.fillStyle = g; c.beginPath(); c.arc(x, y, r, 0, 7); c.fill();
  },

  /** 버튼 그리고 눌렸는지 반환. 즉시모드 UI — 상태관리 없이 UI를 쓰는 가장 싼 방법 */
  button(c, p, { x, y, w, h, label, fill = '#3b82f6', text = '#fff', size = 20 }) {
    const over = p.x > x && p.x < x + w && p.y > y && p.y < y + h;
    const pressed = over && p.down;
    // 눌린 동안 살짝 작아지고 내려앉는다. 이 2px가 "눌렸다"는 느낌을 만든다.
    const d = pressed ? 2 : 0;
    G.round(c, x + d, y + d, w - d * 2, h - d * 2, 12, over ? lighten(fill) : fill);
    G.text(c, label, x + w / 2, y + h / 2 + d, { size, fill: text });
    const clicked = over && p.justDown;
    if (clicked) Sfx.click();
    return clicked;
  },
};

function lighten(hex) {
  const n = parseInt(hex.slice(1), 16);
  const f = (v) => Math.min(255, Math.round(v * 1.25));
  return `rgb(${f(n >> 16)},${f((n >> 8) & 255)},${f(n & 255)})`;
}

export const rnd = (a, b) => a + Math.random() * (b - a);
export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
export const hit = (a, b) =>
  a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
