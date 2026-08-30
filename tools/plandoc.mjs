/* plandoc.mjs — **기획 여섯 갈래별 관문**을 만든다.
 *
 * 왜 필요한가 (2026-08-29, 유저):
 *   *"기획에서 시스템/밸런스/콘텐츠/시나리오/UX/사업 … 코드로는 남겨 있고
 *     장부에는 없잖아. 그걸 볼 문서가 필요한 거."*
 *
 *   장부에 **내용**은 다 있다(가게 15/15 · 물건 120/120 · 강화 13/13).
 *   그런데 **게임 기능 순서**로 늘어놓여 있어서, "밸런스 기획이 지금 어디까지
 *   됐지?"를 물으면 여섯 칸을 돌아다녀야 답이 나온다. 기획자는 갈래로 묻는다.
 *
 * 왜 손으로 안 적나:
 *   손으로 적은 산문은 이 프로젝트에서 계속 어긋났다(일꾼 상한이 네 곳에서
 *   4·1·3·넷이었다). **숫자는 코드에서 뽑고, 사람이 적는 건 판단뿐**으로 가른다.
 *   아래 PARTS의 글은 판단이고, 세는 것은 전부 content.js가 답한다.
 *
 * 실행: node tools/plandoc.mjs            → PLANNING.md 를 다시 쓴다
 *       node tools/plandoc.mjs --html     → 장부에 끼울 HTML 한 덩이를 뱉는다
 */
import * as C from '../content.js';
import fs from 'node:fs';

const items = C.SHOPS.flatMap((s) => s.items);
const n = {
  shops: C.SHOPS.length, shopGoal: 20,
  items: items.length,
  guests: C.GUESTS.length,
  zones: C.DISTRICTS.length,
  ranks: C.RANKS.length,
  stars: C.REGULARS.length,
  grades: C.CARD_GRADES.length,
  gemUp: C.GEM_UPGRADES.length,
  pests: C.PESTS.length,
  service: Object.keys(C.SERVICE).length,
  intro: C.INTRO.length,
  beats: C.BEATS.length,
  events: C.EVENTS.length,
  smalls: C.SMALL_SHOPS.length,
  weather: C.WEATHER.kinds.length,
};

/* ── 사람이 적는 것은 여기뿐이다. 판단과 빈칸. ──
 *
 * done  : 정해졌고 코드에 들어 있다
 * open  : 아직 안 정했다 — **이 목록이 이 문서의 값어치다**
 * where : 어디를 보면 되나 (장부 칸 · 파일)
 */
const PARTS = [
  {
    id: 'sys', name: '시스템 기획',
    what: '규칙과 숫자를 만든다. "손님이 얼마나 자주 오나", "승급 조건이 뭔가".',
    done: [
      ['주문 장사 한 바퀴', '손님이 와서 주문 → 일꾼이 작업대에서 만듦 → 계산대에서 건넴 → 엽전'],
      ['작업대 단', `가게마다 1~8단. 상한은 등급이 준다(무쇠 4·참쇠 6·강철 8)`],
      ['가게 승급', `${n.ranks}단계. 값 ×4 · 레벨 상한 · 작업대 상한 · 계산대 · 채용 자리가 한꺼번에 오른다`],
      ['구역', `${n.zones}곳(안골·저잣거리·큰장마당). 성 합계와 엽전으로 동네째 연다`],
      ['단골 성(星)', `${n.stars}단계. 손님이 더 사고 값도 후해진다`],
      ['날씨·밤낮', `날씨 ${n.weather}가지 · 하루 40분`],
      ['나쁜 놈·삽살개', `${n.pests}종(쥐·까마귀). 삽살개가 대신 잡는다`],
      ['길에 떨어진 것', '40초마다 쌓이고 최대 5. 손으로 줍거나 장터 청소부가 줍는다'],
    ],
    open: [
      '**후반에 돈이 살 것이 없다.** 8시간 매출이 3.35배가 되어도 손님·가게 수가 안 움직였다(2026-08-29에 잼)',
      '**나뭇잎 강화 13개를 서너 개로 합치기** — 축("손님이 돌아온다")과 무관한 순수 숫자다',
      '엔딩(장날 부활) 뒤의 자유 영업이 무엇인가',
    ],
    where: ['장부: 공통 규칙 · 주문 · 생산 · 나르기·계산 · 승급', '`SYSTEMS.md` · `godot/rules/sim.gd`'],
  },
  {
    id: 'bal', name: '밸런스 기획',
    what: '그 숫자를 조율하고, **짐작하지 말고 잰다.** 운 번호 여럿의 가운뎃값으로 판단한다.',
    done: [
      ['물건 값·시간', `${n.items}개 전부. 값·만드는 시간·여는 값이 코드에 있다`],
      ['재는 도구', '`tests/balance.gd` — 8시간 봇. `tools/calibrate.mjs` · `tools/guests.mjs`'],
      ['어긋남 잡기', '`tools/crosscheck.sh` 열한 가지. 규칙을 고치면 반드시 돌린다'],
      ['지금 곡선', '8시간 누적매출 가운뎃값 **223B** (운 번호 다섯 · 폭 ±5%)'],
      ['가게 열리는 때', '20시간에 15채가 목표. 8시간에 10채까지 확인'],
    ],
    open: [
      '**가게 11~20채의 값이 아직 없다** — 꼬리 다섯은 세워만 뒀다',
      '**구역 문턱**이 진짜 손잡이다. 뒤쪽은 초당 수입이 여섯 시간에 97배로 튀어서 어떤 비율도 못 따라간다',
      '광고·유료 상품을 넣었을 때의 곡선을 아직 안 쟀다',
    ],
    where: ['장부: 손님 등장율 · 계산 · 나뭇잎', '`content.js` · `godot/tests/balance.gd`'],
  },
  {
    id: 'cnt', name: '콘텐츠 기획',
    what: '가게 · 손님 · 물건 · 의뢰를 실제로 채운다.',
    done: [
      ['가게', `**${n.shops} / ${n.shopGoal}채**`],
      ['물건', `**${n.items}개** (가게마다 8가지)`],
      ['손님', `**${n.guests}종** — 성격·생김새·버릇까지 (\`BESTIARY.md\`)`],
      ['일꾼 카드', `${n.grades}등급 × ${n.guests}종`],
      ['젬 강화', `${n.gemUp}개`],
      ['작은 건물', `${n.smalls}개 (지금은 게임에서 빠져 있다)`],
      ['기간제 이벤트', `${n.events}개 뼈대`],
    ],
    open: [
      `**가게 ${n.shopGoal - n.shops}채가 비어 있다** — 이름·물건 8가지·값을 아직 안 정했다`,
      '**조류를 손님에서 빼기로 정했는데 아직 코드에 반영 안 됨**(2026-08-28 결정, 30종 → 23종)',
      '손님 23종의 **치우침** — 누가 어느 쪽으로 기우나. *1:1 짝짓기는 안 한다*(유저 결정)',
      '의뢰를 고쳐 만들기',
    ],
    where: ['장부: 가게 15 · 동물 블루프린트', '`content.js` · `BESTIARY.md`'],
  },
  {
    id: 'story', name: '시나리오 기획',
    what: '이야기 · 대사 · 세계관. 축은 **"무너진 산골 장터에, 짐승 손님들이 하나씩 돌아온다."**',
    done: [
      ['한 문장과 결', '동화·힐링. 싸움 없고 마법 없다. **잃는 것이 없는 게임**'],
      ['3막 구조', '1장 불씨(안골) · 2장 소문(저잣거리) · 3장 장날(큰장마당)'],
      ['인트로', `**${n.intro}컷** — 글은 코드에 들어 있다`],
      ['게시판 쪽지', `**${n.beats}줄** — 처음 일어나는 일마다 한 줄씩 뜬다`],
      ['말하는 이', '게시판이다. 촌장을 없앴다(걸어 다니는 안내자는 찾아다녀야 했다)'],
    ],
    open: [
      `**인트로 그림 ${n.intro}장이 없다** — 지금은 글만 뜬다. 이게 지금 제일 큰 구멍이다`,
      '**손님 등장을 뽑기가 아니라 이야기로** — 실루엣으로 나타나고 말을 걸면 열린다(정했으나 안 만듦)',
      '엔딩 잔치를 어떻게 보여줄 것인가',
      '대사는 전부 초안이다 — 뼈대가 굳은 뒤에 다듬는다',
    ],
    where: ['장부: 이야기', '`STORY.md` · `content.js`의 INTRO·BEATS'],
  },
  {
    id: 'ux', name: 'UX 기획',
    what: '화면이 어떻게 이어지나, 무엇이 어떻게 움직이나, 손맛.',
    done: [
      ['방향 넷', '↗ ↖ ↘ ↙ 뿐이다. 길이 마름모라 위아래좌우가 없다'],
      ['마당 배치', '3×3~5×5. 작업대는 안쪽을 보고 계산대만 길 쪽을 본다'],
      ['움직임 규칙', '`MOTION.md` — 무엇이 어떻게 움직여야 하는지'],
      ['창', '가게 · 도감 · 의뢰 · 소식 · 뽑기 · 프로필'],
      ['튜토리얼', '첫 가게 위의 "여기부터 되살리세!" 표 하나 + 게시판 쪽지'],
    ],
    open: [
      '**게임 안에 도움말이 없다.** 주문이 어떻게 도는지, 성(星)이 뭔지 알려주는 곳이 한 군데도 없다',
      '**가게 창이 글자투성이다** — 한 줄에 이름·레벨·값·초·경고가 다 있다(REFS.md의 스낵바와 갈리는 지점)',
      '**"지금 어디쯤"이 안 보인다** — 가게 N/20 · 구역 이름을 늘 띄울 자리',
      '설정 화면이 없다(소리 끄기 등)',
    ],
    where: ['장부: 한 판의 흐름 · 마당 배치 · 골목과 방향', '`FLOW.md` · `MOTION.md` · `godot/view/`'],
  },
  {
    id: 'biz', name: '사업(BM) 기획',
    what: '유료화 · 광고 · 상품. **파는 물건이 사는 사람을 손해 보게 만들면 안 된다**(규칙 4).',
    done: [
      ['두 가지 돈', '엽전(기본) · 나뭇잎(귀한 돈)'],
      ['나뭇잎이 나오는 곳', '의뢰 · 만렙 · 나쁜 놈 잡기'],
      ['나뭇잎을 쓰는 곳', `뽑기 · 젬 강화 ${n.gemUp}개 · 삯꾼 부르기 · 승급 공사 당기기`],
      ['삯꾼(서비스)', `${n.service}가지`],
      ['확률 공개', '뽑기 확률표를 게임 안에서 그대로 보여준다. **확률을 숨기는 뽑기는 만들지 않는다**'],
    ],
    open: [
      '**룰렛을 뺐더니 잎 수입에 구멍이 남았다**(2026-08-28). 하루 서너 잎이 거기서 나왔고 광고 계획이 그 위에 서 있었다',
      '**광고 자리를 안 정했다** — 스낵바는 맨 아래 한가운데에 큰 단추를 둔다. 우리 결(동화·힐링)에 맞는지는 따로 정할 일',
      '유료 상품 목록이 초안이다',
      '광고 SDK는 전부 더미다',
    ],
    where: ['장부: 나뭇잎 · 뽑기', '`content.js`의 GEM·GACHA·SERVICE'],
  },
];

/* ── 마크다운 ── */
function md() {
  const L = [];
  L.push('# 기획서 — 여섯 갈래로 본 것');
  L.push('');
  L.push('> **이 문서는 손으로 고치지 않는다.** `node tools/plandoc.mjs`가 다시 쓴다.');
  L.push('> 숫자는 전부 `content.js`가 답한 것이라 코드와 어긋날 수가 없다.');
  L.push('> 판단과 빈칸은 `tools/plandoc.mjs`의 `PARTS`에 적는다.');
  L.push('>');
  L.push('> **왜 있나** (2026-08-29, 유저): 장부에 내용은 다 있는데 **게임 기능 순서**로');
  L.push('> 늘어놓여 있어서, *"밸런스 기획이 지금 어디까지 됐지?"*를 물으면 여섯 칸을');
  L.push('> 돌아다녀야 했다. **기획자는 갈래로 묻는다.**');
  L.push('');
  const openTotal = PARTS.reduce((a, p) => a + p.open.length, 0);
  L.push(`## 한눈에 — 아직 안 정한 것이 **${openTotal}가지**`);
  L.push('');
  L.push('| 갈래 | 정한 것 | 아직 안 정한 것 |');
  L.push('|---|---|---|');
  for (const p of PARTS) L.push(`| **${p.name}** | ${p.done.length} | **${p.open.length}** |`);
  L.push('');
  for (const p of PARTS) {
    L.push('---');
    L.push('');
    L.push(`## ${p.name}`);
    L.push('');
    L.push(p.what);
    L.push('');
    L.push('### 정해진 것');
    L.push('');
    L.push('| | |');
    L.push('|---|---|');
    for (const [k, v] of p.done) L.push(`| **${k}** | ${v} |`);
    L.push('');
    L.push('### 아직 안 정한 것');
    L.push('');
    for (const o of p.open) L.push(`- ${o}`);
    L.push('');
    L.push(`**어디를 보나** — ${p.where.join(' · ')}`);
    L.push('');
  }
  return L.join('\n');
}

/* ── 장부에 끼울 HTML ── */
function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;'); }
function rich(s) {
  return esc(s).replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
               .replace(/\*(.+?)\*/g, '<i>$1</i>')
               .replace(/`(.+?)`/g, '<code>$1</code>');
}
function html() {
  const openTotal = PARTS.reduce((a, p) => a + p.open.length, 0);
  const H = [];
  H.push('<section id="plan">');
  H.push('  <div class="mark"><i></i><h2>기획서 — 여섯 갈래로 본 것</h2></div>');
  H.push('  <p class="sub">이 칸은 <b>손으로 안 적는다</b> — <code>node tools/plandoc.mjs</code>가 <code>content.js</code>에서 다시 뽑는다. 그래서 세는 숫자가 코드와 어긋날 수가 없다.<br>' +
         '아래 다른 칸들은 <b>게임 기능 순서</b>(주문 · 생산 · 승급 …)로 늘어서 있다. 그러면 <i>"밸런스 기획이 지금 어디까지 됐지?"</i>를 물을 때 여섯 칸을 돌아다녀야 한다. <b>기획자는 갈래로 묻는다</b> — 그래서 이 칸이 있다.</p>');
  H.push(`  <h4 style="margin:22px 0 8px">한눈에 — 아직 안 정한 것이 <b>${openTotal}가지</b></h4>`);
  H.push('  <div class="tw"><table class="mini"><tr><th>갈래</th><th class="num">정한 것</th><th class="num">아직 안 정한 것</th></tr>');
  for (const p of PARTS) {
    H.push(`<tr><td><a href="#plan-${p.id}"><b>${p.name}</b></a></td><td class="num">${p.done.length}</td><td class="num"><b>${p.open.length}</b></td></tr>`);
  }
  H.push('</table></div>');
  for (const p of PARTS) {
    H.push(`  <h4 id="plan-${p.id}" style="margin:30px 0 6px">${p.name}</h4>`);
    H.push(`  <p style="font-size:13.5px;color:var(--muted);margin:0 0 12px">${rich(p.what)}</p>`);
    H.push('  <div class="tw"><table class="mini"><tr><th>정해진 것</th><th></th></tr>');
    for (const [k, v] of p.done) H.push(`<tr><td style="white-space:nowrap"><b>${rich(k)}</b></td><td>${rich(v)}</td></tr>`);
    H.push('</table></div>');
    H.push('  <p style="font-size:13.5px;line-height:1.8;margin:12px 0 0;padding:11px 13px;border-left:3px solid var(--gam);background:rgba(224,138,0,.07);border-radius:6px"><b>아직 안 정한 것</b><br>');
    H.push(p.open.map((o) => '· ' + rich(o)).join('<br>'));
    H.push('</p>');
    H.push(`  <p style="font-size:12.5px;color:var(--muted);margin:8px 0 0">어디를 보나 — ${p.where.map(rich).join(' · ')}</p>`);
  }
  H.push('</section>');
  H.push('');
  return H.join('\n');
}

if (process.argv.includes('--html')) {
  process.stdout.write(html());
} else {
  fs.writeFileSync('PLANNING.md', md() + '\n');
  const openTotal = PARTS.reduce((a, p) => a + p.open.length, 0);
  console.log(`PLANNING.md — 여섯 갈래 · 정한 것 ${PARTS.reduce((a, p) => a + p.done.length, 0)} · 아직 안 정한 것 ${openTotal}`);
}
