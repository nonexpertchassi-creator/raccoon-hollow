/* dash.mjs — 봇이 남긴 자국(godot/stats.json)으로 **판 한 장**을 만든다.
 *
 * 실행:  node tools/dash.mjs        → dash.html
 *
 * ★ 왜 사람도 없는데 만드나.
 *
 * 지표는 거슬러 올라가 모을 수 없다. 낸 뒤에 "첫날 사람들이 어디서 그만뒀지"가
 * 궁금해져도 그때 심으면 그날부터의 것만 남는다. 그래서 미리 심는데,
 * **심어 놓고 판을 안 만들면 심었는지도 모른다.**
 *
 * 가상 플레이어에게 여덟 시간을 놀게 하고 그 자국으로 판을 켜 본다.
 * 숫자가 안 들어오는 칸이 곧 **계측이 빠진 칸**이다 — 그걸 지금 찾는 게
 * 출시 뒤에 찾는 것보다 훨씬 싸다.
 *
 * 회사에서는 이걸 QA 플레이 자료로 한다. 우리는 봇으로 한다.
 */
import { readFileSync, writeFileSync, existsSync } from 'fs';

const SRC = 'godot/stats.json';
if (!existsSync(SRC)) {
  console.error(`${SRC} 가 없다. 먼저 봇을 돌린다:
  BAL_HOURS=8 BAL_SEED=1 godot --headless --path godot --script tests/balance.gd`);
  process.exit(1);
}
const S = JSON.parse(readFileSync(SRC, 'utf8'));
const g = (k) => Number(S[k] || 0);
const meta = (k) => Number(S['_meta.' + k] || 0);

const fmt = (n) => {
  if (!isFinite(n)) return '—';
  if (n < 1000) return String(Math.round(n * 100) / 100);
  const U = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
  let i = 0, v = n;
  while (v >= 1000 && i < U.length - 1) { v /= 1000; i++; }
  return (v < 10 ? v.toFixed(2) : v < 100 ? v.toFixed(1) : String(Math.floor(v))) + U[i];
};
const hhmm = (sec) => `${Math.floor(sec / 3600)}시간 ${Math.floor((sec % 3600) / 60)}분`;
const pct = (a, b) => (b > 0 ? (100 * a / b).toFixed(1) + '%' : '—');

/* ── 고지한 확률과 실제가 맞나 ── 이 판에서 제일 중요한 칸이다 */
import { GACHA, CARD_GRADES } from '../content.js';
const lv = Math.max(1, Math.min(GACHA.rates.length, meta('gachaLv')));
const said = GACHA.rates[lv - 1];
const drew = [1, 2, 3, 4, 5, 6].map((k) => g('gacha.grade' + k));
const drewAll = drew.reduce((a, b) => a + b, 0);

const rows = (list) => list.map(([label, val, note]) =>
  `<tr><td>${label}</td><td class="n">${val}</td><td class="note">${note || ''}</td></tr>`).join('\n');

const html = `<title>봇이 남긴 자국</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Gowun+Batang:wght@400;700&family=IBM+Plex+Sans+KR:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500;600&display=swap">
<style>
:root{--ground:#ece2cb;--surface:#f4ecda;--sunk:#e2d6bb;--ink:#2b241b;--muted:#7c705c;
  --rule:#d3c4a3;--accent:#a8763e;--good:#4a7c59;--warn:#c7563f}
:root:not([data-theme="light"]){@media(prefers-color-scheme:dark){
  --ground:#231e18;--surface:#2f2922;--sunk:#1b1712;--ink:#ece2cb;--muted:#a2957e;
  --rule:#3f382f;--accent:#d0a05f;--good:#7aa987;--warn:#e0806b}}
:root[data-theme="dark"]{--ground:#231e18;--surface:#2f2922;--sunk:#1b1712;--ink:#ece2cb;
  --muted:#a2957e;--rule:#3f382f;--accent:#d0a05f;--good:#7aa987;--warn:#e0806b}
*{box-sizing:border-box}
body{margin:0;background:var(--ground);color:var(--ink);
  font-family:"IBM Plex Sans KR",system-ui,"Apple SD Gothic Neo",sans-serif;line-height:1.7}
.wrap{max-width:920px;margin:0 auto;padding:52px 22px 90px}
h1,h2{font-family:"Gowun Batang",serif;margin:0;text-wrap:balance}
h1{font-size:clamp(30px,5vw,44px)}
h2{font-size:22px;margin:52px 0 4px}
.eyebrow{font-family:"IBM Plex Mono",monospace;font-size:12px;letter-spacing:.16em;
  text-transform:uppercase;color:var(--accent);margin:0 0 12px}
.lede{color:var(--muted);max-width:62ch;margin:12px 0 0}
.sub{color:var(--muted);font-size:14.5px;margin:0 0 18px;max-width:64ch}
.chips{display:flex;flex-wrap:wrap;gap:10px;margin:28px 0 0;padding:0;list-style:none}
.chip{padding:10px 14px;background:var(--surface);border:1px solid var(--rule);border-radius:3px;
  display:flex;flex-direction:column;min-width:96px}
.chip b{font-family:"IBM Plex Mono",monospace;font-variant-numeric:tabular-nums;font-size:20px}
.chip span{font-size:12px;color:var(--muted)}
.tablewrap{overflow-x:auto;border:1px solid var(--rule);border-radius:3px;background:var(--surface)}
table{border-collapse:collapse;width:100%;min-width:520px;font-size:14.5px}
th,td{text-align:left;padding:10px 15px;border-bottom:1px solid var(--rule)}
thead th{font-family:"IBM Plex Mono",monospace;font-size:11.5px;letter-spacing:.1em;
  text-transform:uppercase;color:var(--muted);font-weight:500;background:var(--sunk)}
tbody tr:last-child td{border-bottom:0}
td.n{font-family:"IBM Plex Mono",monospace;font-variant-numeric:tabular-nums;text-align:right;
  white-space:nowrap;font-weight:600}
td.note{color:var(--muted);font-size:13px}
.bar{height:7px;background:var(--sunk);border-radius:4px;overflow:hidden;min-width:70px}
.bar i{display:block;height:100%;background:var(--accent)}
.ok{color:var(--good)} .bad{color:var(--warn)}
.zero{color:var(--warn);font-family:"IBM Plex Mono",monospace;font-size:12px}
.note-block{border-left:3px solid var(--accent);padding-left:16px;margin:22px 0 0;
  color:var(--muted);max-width:64ch}
.note-block b{color:var(--ink)}
footer{margin:64px 0 0;padding-top:20px;border-top:1px solid var(--rule);color:var(--muted);font-size:13px}
code{font-family:"IBM Plex Mono",monospace;font-size:.9em;background:var(--sunk);padding:1px 5px;border-radius:2px}
</style>
<div class="wrap">
<p class="eyebrow">가상 플레이어 · 운 번호 ${meta('seed')} · ${meta('hours')}시간</p>
<h1>봇이 남긴 자국</h1>
<p class="lede">사람은 아직 없다. 이 판은 <b>가상 플레이어</b>가 ${meta('hours')}시간을 놀고 남긴 것이다 —
계측이 제대로 도는지, 안 들어오는 칸이 어디인지를 보려고 만들었다.</p>

<ul class="chips">
  <li class="chip"><b>${fmt(meta('revenue'))}</b><span>누적 매출</span></li>
  <li class="chip"><b>${meta('shops')}</b><span>가게</span></li>
  <li class="chip"><b>${meta('guests')}</b><span>손님</span></li>
  <li class="chip"><b>${meta('stars')}</b><span>성 합계</span></li>
  <li class="chip"><b>${meta('gachaLv')}</b><span>뽑기 단계</span></li>
  <li class="chip"><b>${hhmm(g('run.seconds'))}</b><span>켜 둔 시간</span></li>
</ul>

<h2>무엇을 하고 놀았나</h2>
<p class="sub">손가락으로 한 일. <b>0인 칸이 곧 계측이 빠진 칸</b>이거나, 봇이 그 일을 안 하는 것이다.</p>
<div class="tablewrap"><table>
<thead><tr><th>한 일</th><th style="text-align:right">횟수</th><th>보는 것</th></tr></thead>
<tbody>
${rows([
  ['매대를 눌러 강화', fmt(g('tap.level')), '한 단계씩'],
  ['‘최대’로 한꺼번에', fmt(g('tap.levelMany')), '꾹 누르기·최대 단추가 쓸모 있나'],
  ['나쁜 놈 잡기', fmt(g('tap.pest')), '잡는 재미가 실제로 쓰이나'],
  ['장 열기', fmt(g('tap.fair')), ''],
  ['매대 칸 열기', fmt(g('open.item')), ''],
  ['가게 되살리기', fmt(g('open.shop')), ''],
  ['가게 승급', fmt(g('open.promote')), '여기까지 오는 사람이 얼마나 되나'],
  ['직원 들이기', fmt(g('open.staff')), ''],
  ['삽살개 들이기', fmt(g('open.guard')), ''],
  ['구역 열기', fmt(g('open.district')), '동네째 여는 큰 목표 — 몇 시간에 여나'],
])}
</tbody></table></div>

<h2>뽑기와 룰렛</h2>
<p class="sub">이 게임의 심장이다. 손님이 뽑기로만 오기 때문에 여기가 막히면 전부 멈춘다.</p>
<div class="tablewrap"><table>
<thead><tr><th>항목</th><th style="text-align:right">값</th><th>보는 것</th></tr></thead>
<tbody>
${rows([
  ['뽑은 총 장수', fmt(g('gacha.pull')), ''],
  ['한 장씩 뽑기', fmt(g('gacha.pull1')), '한 장 vs 열 장 — 어느 쪽을 쓰나'],
  ['열 장씩 뽑기', fmt(g('gacha.pull10')), ''],
  ['서른 장씩 뽑기', fmt(g('gacha.pull30')), ''],
  ['처음 만난 손님', fmt(g('gacha.newGuest')), ''],
  ['성을 올린 횟수', fmt(g('star.up')), '카드를 쓰나, 쌓아만 두나'],
  ['룰렛 — 무료', fmt(g('roul.free')), ''],
  ['룰렛 — <b>광고 보고</b>', fmt(g('roul.ad')), `광고 몫 ${pct(g('roul.ad'), g('roul.ad') + g('roul.free'))}`],
])}
</tbody></table></div>

<h2>고지한 확률과 실제</h2>
<p class="sub">게임 안에 적어 둔 표(${lv}단계)와 실제로 나온 것을 나란히 둔다.
<b>여기가 어긋나면 고지한 확률이 거짓말이 된 것이다.</b>
${drewAll < 500 ? '<span class="bad">아직 표본이 적다 — 500장은 넘어야 견줄 만하다.</span>' : ''}</p>
<div class="tablewrap"><table>
<thead><tr><th>등급</th><th style="text-align:right">적어 둔 것</th><th style="text-align:right">실제</th><th>차이</th></tr></thead>
<tbody>
${drew.map((n, i) => {
  const want = Number(said[i]);
  const got = drewAll > 0 ? 100 * n / drewAll : 0;
  const gap = got - want;
  const cls = Math.abs(gap) <= Math.max(1.5, want * 0.25) ? 'ok' : 'bad';
  return `<tr><td>${CARD_GRADES[i].face} ${CARD_GRADES[i].name}</td>
    <td class="n">${want}%</td><td class="n">${got.toFixed(2)}%</td>
    <td class="${cls}">${drewAll === 0 ? '—' : (gap >= 0 ? '+' : '') + gap.toFixed(2) + '%p'}</td></tr>`;
}).join('\n')}
</tbody></table></div>

<h2>아직 0인 칸</h2>
<p class="sub">계측이 빠졌거나, 봇이 그 일을 안 하거나, <b>기능 자체가 없는</b> 것이다. 셋을 갈라야 한다.</p>
<div class="tablewrap"><table>
<thead><tr><th>항목</th><th style="text-align:right">값</th><th>왜 0인가</th></tr></thead>
<tbody>
${rows([
  ['의뢰 받기', fmt(g('quest.take')), '<span class="zero">기능 없음</span> — 의뢰는 아직 저절로 걸린다'],
  ['의뢰 놓침', fmt(g('quest.drop')), '<span class="zero">기능 없음</span>'],
  ['이벤트에 발 뗌', fmt(g('event.join')), '<span class="zero">계측 없음</span> — 참여율의 밑변이라 꼭 필요하다'],
  ['광고 중간이탈', fmt(g('roul.adSkip')), '<span class="zero">기능 없음</span> — 광고가 더미다'],
  ['튜토리얼 단계별', '—', '<span class="zero">기능 없음</span> — 튜토리얼이 한 칸뿐이다'],
  ['결제', '—', '<span class="zero">기능 없음</span>'],
  ['의견 보내기', '—', '<span class="zero">창구 없음</span> — 지금 내면 불만을 말할 데가 없다'],
])}
</tbody></table></div>

<p class="note-block"><b>봇은 사람이 아니다.</b> 지치지도 심심해하지도 않고 광고를 끝까지 본다.
봇의 자국으로 알 수 있는 것은 <b>“셈이 제대로 도는가”</b>까지다.
<i>사람들이 광고를 볼까</i>는 사람이 와야 안다.</p>

<footer>
${SRC} 를 <code>tools/dash.mjs</code>가 읽어 만들었다 · 무엇을 왜 세는지는 <code>METRICS.md</code>
</footer>
</div>
`;
writeFileSync('dash.html', html);
console.log(`dash.html — 센 칸 ${Object.keys(S).filter((k) => !k.startsWith('_meta')).length}개`);
