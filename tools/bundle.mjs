/* tools/bundle.mjs — 한 파일짜리 묶음을 만든다.
 *
 * 왜 필요한가: 게임은 여러 파일로 나뉘어 있는데(그게 맞다), 남한테 보여주려면
 * 한 파일이어야 한다. 여기서 import/export를 걷어내고 이어 붙인다.
 *
 * 그림도 같이 심는다. 묶음 파일은 바깥 파일을 못 불러오므로,
 * art/ 아래 PNG를 전부 글자(data URI)로 바꿔 window.ART_DATA에 넣는다.
 * 그림이 없으면 없는 대로 나온다 — art.js가 알아서 이모지로 넘어간다.
 *
 *   node tools/bundle.mjs [나갈파일]
 */
import fs from 'fs';
import path from 'path';

const ROOT = path.resolve(import.meta.dirname, '..');
const OUT = process.argv[2] || path.join(ROOT, 'nogur.html');
const ORDER = ['content.js', 'core/store.js', 'core/juice.js', 'core/engine.js',
               'art.js', 'sim.js', 'iso.js', 'interior.js'];

const strip = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8')
  .replace(/^import\s+[^;]*?;\s*$/gms, '')
  .replace(/^export\s+/gm, '');

/* 그림 → data URI. 파일명이 곧 id다(art/guests/rabbit.png → guests/rabbit). */
const art = {};
for (const kind of ['guests', 'items', 'pests', 'hero', 'clerks']) {
  const dir = path.join(ROOT, 'art', kind);
  if (!fs.existsSync(dir)) continue;
  for (const f of fs.readdirSync(dir)) {
    if (!f.endsWith('.png')) continue;
    const b = fs.readFileSync(path.join(dir, f));
    art[`${kind}/${f.slice(0, -4)}`] = `data:image/png;base64,${b.toString('base64')}`;
  }
}

const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
const i = html.indexOf('<script type="module">');
const j = html.indexOf('</script>', i);
const body = html.slice(i + '<script type="module">'.length, j)
  .replace(/^import\s+[^;]*?;\s*$/gms, '');

/* 같은 이름을 두 파일이 쓰면 묶는 순간 터진다.
 * 파일로 나눠 쓸 때는 각자 자기 안에서만 사는 이름이지만, 이어 붙이면
 * 한 덩어리가 되기 때문이다. scene.js와 interior.js가 둘 다 W와 C를
 * 쓰다가 실제로 터졌다 — 브라우저를 켜야만 보이는 종류의 고장이라
 * 여기서 미리 잡는다. */
const seen = new Map();
for (const p of ORDER) {
  const src = strip(p);
  for (const m of src.matchAll(/^(?:const|let|var|function|class)\s+([A-Za-z_$][\w$]*)/gm)) {
    const name = m[1];
    if (seen.has(name)) {
      console.error(`✗ 이름이 겹친다: ${name} — ${seen.get(name)} 와 ${p}`);
      process.exit(1);
    }
    seen.set(name, p);
  }
}

const mods = ORDER.map((p) => `/* ===== ${p} ===== */\n${strip(p)}`).join('\n');
fs.writeFileSync(OUT,
  html.slice(0, i) +
  `<script>window.ART_DATA=${JSON.stringify(art)};</script>\n` +
  '<script type="module">\n' + mods + '\n/* ===== index ===== */\n' + body +
  html.slice(j));

const kb = (fs.statSync(OUT).size / 1024).toFixed(0);
console.log(`${OUT} · ${kb}KB · 그림 ${Object.keys(art).length}장 심음`);
if (Object.keys(art).length) console.log('  ' + Object.keys(art).join(', '));
