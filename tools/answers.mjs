/* answers.mjs — 대조 시험의 **문제와 정답**을 만든다 (JS 쪽).
 * 실행: node tools/answers.mjs <조각>
 *   godot/cases.txt   ← 문제 (GDScript도 같은 걸 읽는다)
 *   godot/out_js.txt  ← JS판의 답
 *
 * ★ 문제는 매번 같아야 한다.
 * 처음엔 난수만 뿌렸는데 한 번은 통과하고 다음엔 실패했다 — 반올림이 갈리는
 * 값이 우연히 걸려야만 드러났기 때문이다. 어쩌다 잡히는 시험은 시험이 아니다.
 * 그래서 씨앗을 고정하고, 갈릴 만한 자리를 일부러 전부 넣는다.
 */
import fs from 'fs';
import { fmt } from '../sim.js';
import * as CONTENT from '../content.js';

const SUBJECT = process.argv[2] || 'fmt';
const W = (name, arr) => fs.writeFileSync(`godot/${name}`, arr.join('\n') + '\n');
/** gen-content.mjs와 **같은 규칙**으로 숫자를 글자로 만든다.
 *  정수는 12.0처럼 소수점을 붙인다 — content.gd가 그렇게 담고 있으니까. */
const num = (n) => (Number.isInteger(n) ? n.toFixed(1) : String(n));

/** balance.mjs가 쓰는 것과 같은 mulberry32 */
const mulberry32 = (a) => () => {
  a = a + 0x6D2B79F5 | 0;
  let x = Math.imul(a ^ a >>> 15, a | 1);
  x ^= x + Math.imul(x ^ x >>> 7, x | 61);
  return (x ^ x >>> 14) >>> 0;
};

const SUBJECTS = {
  /* 큰 숫자 줄여 쓰기 */
  fmt() {
    const n = [];
    const r = mulberry32(20260820);
    for (let i = 0; i < 4000; i++) n.push(Math.floor(Math.pow(10, (r() / 2 ** 32) * 15) * (1 + r() / 2 ** 32)));
    [0, 1, 999, 1000, 1001, 9999, 10000, 99999, 100000, 999999, 1e6, 1e9, 1e12, 1e15].forEach((x) => n.push(x));
    // 딱 절반에 떨어지는 값 — 반올림 규칙이 갈리는 자리는 여기뿐이다
    for (let u = 1; u <= 1e12; u *= 1000)
      for (let a = 1; a < 100; a++) { n.push(a * u * 1000 + u * 500); n.push(a * u * 1000 + u * 5); }
    const cases = n.filter((x) => x >= 0 && Number.isFinite(x));
    W('cases.txt', cases);
    W('out_js.txt', cases.map((x) => fmt(x)));
  },

  /* 씨앗 고정 난수 — 흐름 전체가 같아야 한다 */
  rng() {
    const seeds = [1, 2, 3, 7, 42, 1000, 20260820, 4294967295];
    W('cases.txt', seeds);
    const out = [];
    for (const s of seeds) { const r = mulberry32(s); for (let i = 0; i < 20; i++) out.push(r()); }
    W('out_js.txt', out);
  },
  /* content.gd에 담긴 숫자 전부. 뽑아내는 도구가 틀렸는지, 누가 손으로
   * 고쳤는지를 잡는다. 열쇠 순서는 양쪽 다 가나다순으로 맞춘다. */
  content() {
    const out = [];
    const flat = (v, path) => {
      if (Array.isArray(v)) v.forEach((x, i) => flat(x, `${path}[${i}]`));
      else if (v && typeof v === 'object') Object.keys(v).sort().forEach((k) => flat(v[k], `${path}.${k}`));
      else out.push(`${path}\t${typeof v === 'number' ? num(v) : String(v)}`);
    };
    const skip = new Set(['itemById', 'shopById', 'ALL_ITEMS']);
    for (const n of Object.keys(CONTENT).filter((k) => !skip.has(k) && typeof CONTENT[k] !== 'function').sort()) {
      flat(CONTENT[n], n);
    }
    W('cases.txt', ['content']);
    W('out_js.txt', out);
  },
};

if (!SUBJECTS[SUBJECT]) { console.error('모르는 조각: ' + SUBJECT); process.exit(2); }
SUBJECTS[SUBJECT]();
