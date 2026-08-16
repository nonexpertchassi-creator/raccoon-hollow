/* juice.js — 반응 레이어.
 *
 * 게임 로직은 하나도 안 바꾼다. 조작에 대한 "반응"만 얹는다.
 *   소리    · 오디오 파일 없이 Web Audio로 그때그때 합성 (에셋 0개 원칙 유지)
 *   흔들림  · 충돌·성공 순간 화면이 떨림
 *   파티클  · 부서지는 조각, 반짝이
 *   정지    · 충돌 순간 0.05~0.1초 전체 정지. "타격감"의 정체가 이거다
 *   튀어오름· 숫자·아이콘이 커졌다 돌아옴
 *
 * 없어도 게임은 돌아간다. 없으면 죽은 것처럼 느껴진다.
 */

/* ───────────────────────── 소리 ───────────────────────── */

let ac = null, master = null;

/** 브라우저는 사용자가 화면을 건드리기 전엔 소리를 막는다. 첫 입력 때 열어준다. */
function audio() {
  if (ac) {
    if (ac.state === 'suspended') ac.resume();
    return ac;
  }
  try {
    ac = new (window.AudioContext || window.webkitAudioContext)();
    master = ac.createGain();
    master.gain.value = 0.5;
    master.connect(ac.destination);
    return ac;
  } catch (_) {
    return null; // 오디오를 못 써도 게임은 그대로 돌아가야 한다
  }
}

function blip(freq, { to = 0, dur = 0.12, type = 'square', vol = 0.18, delay = 0 } = {}) {
  if (Sfx.muted) return;
  const a = audio(); if (!a) return;
  const t = a.currentTime + delay;
  const o = a.createOscillator();
  o.type = type;
  o.frequency.setValueAtTime(freq, t);
  if (to) o.frequency.exponentialRampToValueAtTime(Math.max(20, to), t + dur);
  const g = a.createGain();
  g.gain.setValueAtTime(0.0001, t);
  g.gain.linearRampToValueAtTime(vol, t + 0.006);
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  o.connect(g).connect(master);
  o.start(t); o.stop(t + dur + 0.03);
}

/** 폭발·타격용 잡음. 필터를 아래로 쓸어내려 "쿵" 소리를 만든다. */
function noise({ dur = 0.32, vol = 0.3, from = 900, to = 110 } = {}) {
  if (Sfx.muted) return;
  const a = audio(); if (!a) return;
  const n = Math.floor(a.sampleRate * dur);
  const buf = a.createBuffer(1, n, a.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
  const src = a.createBufferSource(); src.buffer = buf;
  const f = a.createBiquadFilter(); f.type = 'lowpass';
  const t = a.currentTime;
  f.frequency.setValueAtTime(from, t);
  f.frequency.exponentialRampToValueAtTime(to, t + dur);
  const g = a.createGain();
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  src.connect(f).connect(g).connect(master);
  src.start(t);
}

const SCALE = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28]; // 펜타토닉 — 아무렇게나 쳐도 안 어긋난다
const note = (i) => 220 * Math.pow(2, (SCALE[Math.min(i, SCALE.length - 1)] || 0) / 12);

export const Sfx = {
  muted: false,

  /** 첫 사용자 입력에서 호출. 이걸 안 하면 브라우저가 소리를 막는다. */
  unlock() { audio(); },

  toggleMute() {
    Sfx.muted = !Sfx.muted;
    if (master) master.gain.value = Sfx.muted ? 0 : 0.5;
    return Sfx.muted;
  },

  click()   { blip(520, { to: 700, dur: 0.05, type: 'square', vol: 0.10 }); },
  deny()    { blip(150, { to: 90,  dur: 0.16, type: 'sawtooth', vol: 0.14 }); },

  /** 오브 획득 — 연속으로 먹으면 음이 올라가서 콤보처럼 들린다 */
  pickup(step = 0) {
    blip(note(4 + (step % 6)), { to: note(6 + (step % 6)), dur: 0.10, type: 'triangle', vol: 0.16 });
  },

  death() {
    noise({ dur: 0.42, vol: 0.32, from: 1100, to: 80 });
    blip(180, { to: 45, dur: 0.38, type: 'sawtooth', vol: 0.16 });
  },

  /** 머지 — 등급이 오를수록 음이 높아진다. 성장이 귀로 들린다 */
  merge(level = 1) {
    blip(note(level), { to: note(level + 2), dur: 0.13, type: 'square', vol: 0.16 });
    blip(note(level + 4), { dur: 0.10, type: 'triangle', vol: 0.10, delay: 0.06 });
  },

  forge()   { blip(300, { to: 420, dur: 0.09, type: 'square', vol: 0.13 }); },
  coin()    { blip(880, { dur: 0.07, type: 'square', vol: 0.14 });
              blip(1320, { dur: 0.12, type: 'square', vol: 0.12, delay: 0.06 }); },

  /** 칸 뒤집기 — 밝아지면 높은 음, 어두워지면 낮은 음 */
  toggle(on) { blip(on ? 660 : 380, { dur: 0.06, type: 'triangle', vol: 0.13 }); },

  /** 클리어 — 펜타토닉 상행. 3음이면 충분히 "해냈다"로 들린다 */
  win() {
    [0, 2, 4, 7].forEach((s, i) =>
      blip(note(s + 3), { dur: 0.16, type: 'triangle', vol: 0.15, delay: i * 0.075 }));
  },

  reward() {
    [0, 3, 5].forEach((s, i) =>
      blip(note(s + 5), { dur: 0.14, type: 'square', vol: 0.13, delay: i * 0.06 }));
  },
};

/* ─────────────────── 흔들림 · 정지 · 파티클 ─────────────────── */

const parts = [];
const MAX_PARTS = 220; // 무한히 쌓이면 프레임이 떨어진다

export const Juice = {
  shakeAmt: 0,
  freezeT: 0,

  /** 화면 흔들림. 8~14가 충돌, 3~5가 작은 반응 */
  shake(a) { Juice.shakeAmt = Math.max(Juice.shakeAmt, a); },

  /** 전체 정지. 충돌 순간 0.05~0.1초. 이게 "타격감"이다 */
  freeze(t) { Juice.freezeT = Math.max(Juice.freezeT, t); },

  /**
   * 파티클 터뜨리기.
   * @param {object} o color(단색 또는 배열) · count · speed · life · size · gravity · spread
   */
  burst(x, y, o = {}) {
    const {
      color = '#fff', count = 12, speed = 160, life = 0.6,
      size = 4, gravity = 340, spread = Math.PI * 2, dir = 0, fade = true,
    } = o;
    for (let i = 0; i < count; i++) {
      if (parts.length >= MAX_PARTS) parts.shift();
      const ang = dir + (Math.random() - 0.5) * spread;
      const sp = speed * (0.45 + Math.random() * 0.75);
      parts.push({
        x, y,
        vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp,
        life: life * (0.6 + Math.random() * 0.7), max: life,
        size: size * (0.6 + Math.random() * 0.8),
        gravity, fade,
        color: Array.isArray(color) ? color[(Math.random() * color.length) | 0] : color,
      });
    }
  },

  update(dt) {
    Juice.shakeAmt *= 0.84;
    if (Juice.shakeAmt < 0.25) Juice.shakeAmt = 0;

    for (let i = parts.length - 1; i >= 0; i--) {
      const p = parts[i];
      p.life -= dt;
      if (p.life <= 0) { parts.splice(i, 1); continue; }
      p.vy += p.gravity * dt;
      p.vx *= 0.985;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
  },

  draw(c) {
    for (const p of parts) {
      const k = Math.max(0, p.life / p.max);
      c.globalAlpha = p.fade ? Math.min(1, k * 1.6) : 1;
      c.fillStyle = p.color;
      const s = p.size * (0.35 + k * 0.65);
      c.fillRect(p.x - s / 2, p.y - s / 2, s, s);
    }
    c.globalAlpha = 1;
  },

  clear() { parts.length = 0; Juice.shakeAmt = 0; Juice.freezeT = 0; },
  count() { return parts.length; },
};

/* ───────────────────────── 튀어오름 ─────────────────────────
 * 값이 바뀐 순간 커졌다가 원래대로 돌아오는 배율을 계산한다.
 * G.text 의 size 에 곱해서 쓰면 숫자가 살아난다.
 */
export class Pop {
  constructor() { this.t = 0; }
  hit(strength = 1) { this.t = strength; }
  /** @returns {number} 1.0 = 평상시, 1.0 초과 = 커진 상태 */
  scale(dt, amount = 0.35) {
    if (this.t > 0) this.t = Math.max(0, this.t - dt * 4.5);
    return 1 + this.t * amount;
  }
}
