/* art.mjs — 아직 없는 그림이 뭔지 세어서 주문서(ASSETS.md)를 갱신한다.
 *
 * 실행:  node tools/art.mjs          남은 그림을 화면에 뿌린다
 *        node tools/art.mjs --write  ASSETS.md의 목록 칸을 다시 쓴다
 *        node tools/art.mjs --audit  **주문서에 없는 그림**을 찾는다(지울 후보)
 *
 * 왜 도구로 만드나: 목록을 손으로 관리하면 반드시 어긋난다 — 그림을 넣고
 * 목록에서 지우는 걸 잊거나, 품목을 추가하고 목록에 안 적거나. 목록은
 * **content.js와 art/ 폴더에서 계산**하면 절대 안 어긋난다.
 */
import { readdirSync, existsSync, readFileSync, writeFileSync, statSync } from 'fs';
import { SHOPS, GUESTS, PESTS, STAFF_RANKS, CARD_GRADES } from '../content.js';

const ROOT = new URL('..', import.meta.url).pathname;
/* ★ 그림은 **godot/art/** 안에 산다. 저장소 뿌리(art/)가 아니다.
 *   Godot은 제 프로젝트 폴더(godot/) 밖의 파일을 못 읽는다 — 밖에 두면
 *   목록은 채워지는데 화면에는 영영 안 나오는, 제일 나쁜 종류가 된다. */
const DIR = 'godot/art';
/* webp든 png든 있으면 들어온 것으로 친다 — 형식을 갈아타는 중이다.
 * 코드(art.gd)도 webp를 먼저 찾고 없으면 png를 찾는다. 둘이 어긋나면
 * 주문서는 "없다"는데 화면에는 나오는 유령이 생긴다. */
const has = (dir, id) =>
  existsSync(`${ROOT}${DIR}/${dir}/${id}.webp`) || existsSync(`${ROOT}${DIR}/${dir}/${id}.webp`);

/* ★ **옛 그림은 전부 지웠다**(2026-08-28, 유저: "제발 옛 그림 지우자,
 *   진짜 마지막 명령이야").
 *
 *   그동안 이름 규칙이 세 번 바뀌었고(옆모습 한 장 → 옆+뒤 → 방향 넷),
 *   그때마다 **옛 그림을 지우지 않고 그물로 남겼다.** 그 그물이 문제였다 —
 *   화면에는 옛 그림이 나오니 "다 된 것 같은데 어딘가 어색하다"가 되고,
 *   목록에는 안 뜨니 무엇이 옛것인지도 안 보였다. 이번 주에 잡은 꼬임의
 *   절반이 여기서 나왔다.
 *
 *   그래서 KEEP·KEEP_OLD를 없애고 **주문서에 없는 그림을 전부 지웠다.**
 *   이제 규칙은 하나다: **주문서에 있으면 쓰고, 없으면 없다.**
 *   그림이 없는 자리는 코드가 도형으로 그린다 — 도형은 "아직 안 왔다"가
 *   눈에 바로 보인다. 그게 어중간한 옛 그림보다 낫다. */

const GROUPS = [
  /* 마을 길을 도는 너구리 한 마리. 마당 안 일꾼과 **다른 사람**이다. */
  { dir: 'hero', size: '144×144', title: '장터 청소부',
    note: '마당 밖으로 나오는 **유일한 너구리**다. 빗자루를 들고 길을 돌며\n' +
          '떨어진 것을 줍는다. 옆모습 한 장이면 된다 — 왼쪽은 코드가 뒤집는다.\n' +
          '★ 지금 들어 있는 파일은 **옛 촌장 그림**(흰 수염·지팡이)이다.\n' +
          '지팡이를 빗자루로 바꿔 **다시 그려야 한다** — 목록에 "있음"으로 뜨는 건\n' +
          '파일이 있다는 뜻이지 맞는 그림이라는 뜻이 아니다.\n' +
          '일꾼과 헷갈리지 않게: 앞치마 없이, 빗자루 하나로 가른다.',
    rows: [{ id: 'sweeper', why: '장터 청소부 — 빗자루를 들고 길을 돈다 (다시 그릴 것)' }] },
  /* 첫 만화 넉 장 — 게임을 처음 켤 때 한 번만 보여준다(건너뛸 수 있다).
   * ★ 이 넉 장이 **이 게임이 무엇인지 말하는 유일한 자리**다. 여기가 비면
   *   유저는 "숫자가 올라가는 것" 말고는 아무것도 못 받는다(2026-08-28). */
  { dir: 'intro', size: '512×320', title: '첫 만화 넉 장',
    note: '가로로 긴 한 컷씩. 글자는 **넣지 않는다** — 코드가 아래에 얹는다.\n' +
          '톤은 STORY.md의 결(동화·힐링). 1컷만 슬프고 나머지는 볕 좋은 장날 쪽으로.\n' +
          '없으면 글만 나온다 — 게임은 돌지만 첫인상이 통째로 빈다.',
    rows: [
      { id: 'intro1', why: '붐비던 옛 장터 — 등불, 짐승 손님들, 좌판 가득한 물건' },
      { id: 'intro2', why: '큰 장마 — 물이 장터를 쓸어 간다. **이 게임에서 유일하게 슬픈 컷**' },
      { id: 'intro3', why: '떠내려간 자리에 게시판 하나만 남았다 — 텅 빈 진흙 벌' },
      { id: 'intro4', why: '무너진 대장간 화덕에 남은 불씨 하나 — 그 앞에 선 너구리 뒷모습' },
    ] },
  /* 붙박이 소품 — 걸어 다니는 사람이 아니라 **늘 그 자리에 있는 것**들. */
  { dir: 'props', size: '160×176', title: '마을 소품',
    note: '의뢰 게시판은 촌장이 하던 일을 물려받았다(2026-08-28). 걸린 의뢰가 있으면\n' +
          '코드가 그 위에 ❗를, 장이 설 참이면 "장 서다!" 표를 얹는다 — **그림에는 넣지 말 것.**',
    rows: [{ id: 'board', why: '의뢰 게시판 — 기둥 둘에 판때기, 종이 몇 장이 붙어 있다' }] },
  /* ★ 물건은 **등급마다 실제로 다시 그린다**(2026-08-27, 유저 확정).
   *   270장으로 주문서에서 제일 큰 덩어리다. "모양은 같고 재질만 다르니
   *   기본 그림 하나에 색만 입히면 120장으로 줄지 않나"를 유저에게 물었고,
   *   답은 **아니오**였다 — "물건은 바뀌는 게 맞는 거 같음".
   *
   *   맞는 판단이다. 물건이 바뀌는 것이 **승급의 보람**이다. 색만 바꾸면
   *   승급해도 매대가 그대로처럼 보인다. 여기서 아낀 그림값은 게임의
   *   제일 큰 순간을 깎아 먹는다. 이 결정은 다시 뒤집지 않는다.
   *
   *   대신 값은 안다: 가게 하나당 18장, 가게 20채면 물건만 360장. */
  { dir: 'items', size: '128×224', title: '물건 (등장하는 단의 그림만)',
    note: '**두 군데에 쓰인다** — 매대 위(원래 크기)와 가게 창의 목록 썸네일(작게 줄여서).\n' +
          '그래서 작게 줄여도 뭔지 알아볼 수 있어야 한다 — 잔무늬보다 **실루엣**이 중요하다.\n\n' +
          '★ **없는 그림은 목록에 없다**(2026-08-27). 마당의 매대가 4 → 6 → 8칸이라\n' +
          '물건도 그 수만큼만 열린다: 가게의 1~4번째 물건은 1단부터, 5~6번째는 2단부터,\n' +
          '7~8번째는 3단부터 나온다. **2단에 나오는 물건의 1단 그림은 영영 안 쓰인다** —\n' +
          '그런 그림을 그리게 만드는 목록이 제일 비싼 낭비다(유저가 잡았다).\n' +
          '그래서 가게 하나가 24장이 아니라 **18장**이다(4×3 + 2×2 + 2×1). 15가게면 270장.\n\n' +
          '파일명: 1단은 `<물건id>.webp`, 2단은 `<물건id>-1.webp`, 3단은 `<물건id>-2.webp`.\n' +
          '같은 물건이 격이 오른 모습으로 — 무쇠도끼 → 참쇠도끼(날이 서고) → 강철도끼(광이 난다).\n' +
          '등급 테두리(은·금 고리)는 코드가 안 그린다. **그림이 곧 등급이다.**',
    rows: SHOPS.flatMap((sh) => sh.items.flatMap((it, k) => {
      /* 이 물건이 처음 나오는 단: 1~4번째=1단(0) · 5~6번째=2단(1) · 7~8번째=3단(2).
         매대 칸 수(4·6·8)와 같은 규칙이다 — sim.stall_cap과 한 몸으로 움직인다. */
      const from = k < 4 ? 0 : (k < 6 ? 1 : 2);
      const tiers = [];
      for (let r = from; r < 3; r++) tiers.push(r);
      return tiers.map((r) => ({
        id: r === 0 ? it.id : `${it.id}-${r}`,
        why: `${sh.ranks[r]}${it.name} (${sh.name} ${r + 1}단${from === r ? ' — 여기서 처음 나온다' : ''})`,
      }));
    })) },
  /* ★ 일꾼 개념 폐지(2026-08-26, 유저) — 승급하면 같은 가게 너구리가 한
   * 마리 더 온다(전원 완성형 일꾼 그림). 두건 일꾼 그림은 은퇴 — 이미 온
   * 20장은 빈자리를 메우는 데만 남고, **추가 제작 금지.** */
  /* ★ 걷는 모습이 목록에 아예 없었다(2026-08-27에 잡았다) — 손님 그림의
   * **기본**인데 주문서가 한 번도 달라고 하지 않았다. 도감을 갈아 새 짐승이
   * 아홉 들어왔을 때 그들만 조용히 빠져 있었다. 주문서에 없는 그림은
   * 그려지지 않는다. */
  /* ★ **방향 넷을 다 그린다**(2026-08-28, 유저: "↗ ↖ ↘ ↙ 이 방향 다 그리자").
   *   옛날에는 옆모습 한 장 + 정면 + 뒷모습이었고 왼쪽은 코드가 거울로 뒤집었다.
   *   거울은 **빛과 무늬를 같이 뒤집는다** — 왼쪽 위에서 오던 볕이 반대에서
   *   오고, 얼룩이 반대편으로 간다. 한 장 아끼려다 늘 어딘가 어색했다.
   *
   *   이 화면은 비스듬히 내려다본 격자라 **네 대각선으로만** 움직인다.
   *   그래서 넷이면 전부다 — 정면도 뒷모습도 따로 없다. */
  { dir: 'guests', size: '144×144', title: '손님 걷는 모습 — 방향 넷',
    note: '파일명: `<손님id>-<방향>.webp`. 방향은 넷: `ne`(↗) · `nw`(↖) · `se`(↘) · `sw`(↙).\n' +
          '**뒤집지 않는다** — 네 장 다 제 그림이다. 빛은 늘 왼쪽 위에서.\n' +
          'se·sw는 얼굴이 보이는 쪽, ne·nw는 등이 보이는 쪽이다.\n' +
          '2등신(머리 둘 높이), 배경 없이, 발이 그림 맨 아래에 닿게.\n' +
          '★ 한 짐승을 **넷 다 끝내고** 다음 짐승으로 간다 — 서른을 한 방향씩\n' +
          '그리면 서른 마리가 다 반쯤 된 채로 오래 간다.\n' +
          '★ 옛 한 장짜리(`<손님id>.webp`)는 **지웠다.** 그물로 남겨 두면\n' +
          '"다 된 것 같은데 어딘가 어색하다"가 되고, 무엇이 옛것인지도 안 보인다.\n' +
          '그림이 없는 손님은 도형으로 나온다 — 안 왔다는 게 바로 보이는 게 낫다.',
    rows: GUESTS.flatMap((g) => [['ne', '↗ 오른쪽 위로'], ['nw', '↖ 왼쪽 위로'],
      ['se', '↘ 오른쪽 아래로'], ['sw', '↙ 왼쪽 아래로']]
      .map(([d, ko]) => ({ id: `${g.id}-${d}`, why: `${g.face} ${g.name} — ${ko}` }))) },
  { dir: 'counters', size: '168×144', title: '계산대', optional: true,
    note: '일꾼이 서서 파는 곳. **정면치기 한 장이면 된다** — 마당 문 방향에 따라\n' +
          '코드가 좌우로 뒤집는다. 좌우 비대칭 소품(주판·엽전함)을 올려도 뒤집혀\n' +
          '어색하지 않게, 되도록 가운데 배치로. 없으면 나무 상자를 그린다.\n' +
          '★ **방향 약속**: 손님이 받아 가는 넓은 면이 그림의 **오른쪽 아래**를\n' +
          '보게 그린다(길이 그쪽이다). 왼쪽 골목을 보는 가게는 코드가 뒤집는다 —\n' +
          '지금 임시 상자가 어색해 보이는 건 방향이 없어서다(유저가 필방·옹기점·\n' +
          '약재상에서 잡았다). 그림이 오면 이 약속대로 방향이 생긴다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} 계산대` })) },
  { dir: 'kilns', size: '168×192', title: '가마·풀무',
    note: '마당 뒤쪽의 만드는 기계 — 대장간은 풀무·화덕, 옹기점은 가마, 국밥집은 가마솥.\n' +
          '승급 그림(`smith-1.webp`·`smith-2.webp`)을 넣으면 등급 따라 갈아입는다(선택).\n' +
          '없으면 코드가 등급 따라 키우고 불을 세게 피운다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} — ${sh.desc}` })) },
  { dir: 'pests', size: '128×128', title: '나쁜 놈',
    rows: [...PESTS.map((p) => ({ id: p.id, why: `${p.name} — 눌러서 잡는다` })),
           { id: 'dog', why: '삽살개 — 앉아서 지킨다' }] },
  { dir: 'stalls', size: '192×176', title: '매대(좌판)',
    note: '가게마다 **다르게 생겨야 한다.** 지금은 다섯 가게가 똑같은 나무 상자다.\n' +
          '그 가게에서 무엇을 파는지가 좌판에서 먼저 읽혀야 한다 —\n' +
          '대장간은 모루·쇠받침, 필방은 낮은 서안, 지물포는 종이 두루마리 선반,\n' +
          '옹기점은 흙바닥 좌판, 약재상은 약재 서랍장 같은 식으로.\n' +
          '**물건 그림이 이 위에 얹힌다** — 가운데 위쪽을 비워 둘 것.\n' +
          '승급 그림(`smith-1.webp`)도 넣을 수 있다. 없으면 기본 것을 쓴다.\n' +
          '★ **↙ 한 장만 그리면 된다** — ↘쪽은 코드가 거울로 뒤집는다. 다만 거울은\n' +
          '빛 방향(왼쪽 위 광원)까지 뒤집으므로, 비대칭이 심해 어색한 가게만\n' +
          '`<가게id>-r.webp`(↘판)를 따로 주면 그걸 쓴다. 되도록 좌우 대칭에 가깝게\n' +
          '구성하면 ↘판 없이도 자연스럽다.',
    rows: SHOPS.map((sh) => ({ id: sh.id, why: `${sh.name} — ${sh.desc || ''}`.trim() })) },
  { dir: 'ui', size: '아래 참고', title: '뽑기와 룰렛 판',
    note: '움직임은 `MOTION.md`에 적어 뒀다.\n' +
          '· `back.webp` 512×768 — 카드 뒷면. 뒤집기 연출에 쓴다. 등급 빛은 코드가 얹는다\n' +
          '· `wheel.webp` 512×512 — 룰렛 원판. **열두 칸**이 그려진 바퀴. 칸 안 글자는 코드가 얹는다\n' +
          '· `needle.webp` 64×96 — 룰렛 바늘. 위에서 아래를 가리킨다',
    rows: [
      { id: 'back', why: '카드 뒷면 512×768 — 뒤집기 전에 보이는 면' },
      { id: 'coin', why: '엽전 64×64 — 계산대 위·팔린 표에 쓴다 (상평통보처럼 가운데 네모 구멍)' },
      /* ★ 이 둘은 **이미 들어와 있는데 코드가 아직 안 붙였다.** 룰렛은 지금
       *   코드가 직접 원을 그린다. 그림 쪽 할 일은 없다 — 붙이는 것은 코드 몫.
       *   (2026-08-28에 --wired 검사가 잡아냈다. 그 전에는 아무도 몰랐다.) */
      { id: 'wheel', why: '룰렛 원판 512×512 — **들어와 있다.** 코드가 붙이는 일만 남았다' },
      { id: 'needle', why: '룰렛 바늘 64×96 — **들어와 있다.** 코드가 붙이는 일만 남았다' },
    ] },
  /* 선택 — 프로필 초상. 없으면 이모지 얼굴로 돈다. */
  { dir: 'portraits', size: '256×256', title: '프로필 초상', optional: true,
    note: '머리띠(위 표시줄) 왼쪽의 동그란 얼굴. 규격 네 줄이면 된다:\n' +
          '1. **동그란 틀 안에** 그린다 — 원 밖은 투명. 코드가 네모로 자르지 않는다.\n' +
          '2. **어깨까지 상반신**, 살짝 위에서 본 정면(3/4). 얼굴이 원의 7~8할.\n' +
          '3. 배경은 투명. 테두리 띠(칭호 색)와 바탕은 코드가 두른다.\n' +
          '4. 표정은 그 짐승의 성격대로(BESTIARY.md 참고) — 호랑이는 위엄, 토끼는 촐랑.\n' +
          '카드(512×768)와 같은 그림체·팔레트다. 카드가 이미 있는 손님은 그 얼굴을\n' +
          '동그란 틀에 다시 앉히면 된다 — 새로 창작할 필요 없다.',
    rows: [{ id: 'raccoon', why: '기본 얼굴 — 주인공 너구리' }]
      .concat(GUESTS.map((g) => ({ id: g.id, why: `${g.name} — 뽑으면 고를 수 있다` }))) },
  /* ★ 겹그림(조립) 계약은 2026-08-26에 접었다 — **완성형으로 회귀**(유저 결정).
   * 이유: 장수가 비슷하고(155 vs 135), 스티커 핀 맞추기가 AI 그림의 제일
   * 약한 고리이며, "대장간 일꾼 = 망치 든 너구리"라는 가게 정체성이 무늬
   * 다양성보다 값지다. hero-body/·gear/ 폴더는 **쓰지 않는다 —
   * 추가 제작 금지.** (들어온 A무늬는 새 일꾼이 올 때까지 임시로 돈다) */
  /* ★ 최종 확정(2026-08-26, 유저): **가게마다 일꾼 세트가 따로 있다.**
   * 한 세트 = 무늬 4(a주황·b회색·c적갈·d삼색) × 방향 2(side·back) ×
   * 앞치마 3단(없음·-1·-2) = 24장. 대장간 시트가 첫 세트다.
   * 무늬는 채용마다 랜덤, 복장은 가게가, 앞치마는 등급이 정한다. */
  /* ★ 일꾼 너구리는 **가게를 안 가린다**(2026-08-27, 유저).
   *
   *   가게마다 전용으로 그리면 무늬 4 × 방향 2 × 가게 20 = 160장이고,
   *   가게가 늘 때마다 8장씩 늘어 "무한히 계속 뽑아야" 한다.
   *   게다가 그동안 이름 체계가 셋으로 갈려 싸우고 있었다 —
   *   `<가게>-<자세>`(20장 있음) · `<가게>-<무늬>-<방향>`(0장, 주문서만 시킴) ·
   *   `hero-body/<무늬>-<방향>`(5장). 그래서 걷는 일꾼과 일하는 일꾼이
   *   다르게 생겼다. **주문서가 코드에 없는 걸 시키고 있었던 것이다.**
   *
   *   이제 한 갈래다: `hero-body/<무늬>-<자세>`.
   *   가게가 늘어도 **0장**. 무늬(타입)를 하나 그리면 **모든 가게에서 동시에**
   *   쓰인다 — 그래서 무늬는 일감이 아니라 **모으는 재미**다.
   *
   *   아래 목록은 코드가 실제로 찾는 이름 그대로다(village.gd `_clerk_layers`). */
  /* ★ **자세 넷 × 방향 넷**(2026-08-28, 유저: "많이 만들고 쳐낸다").
   *   8/28 아침에 자세를 다섯에서 셋으로 줄였다가, 같은 날 방향을 넷으로
   *   늘렸다. 왔다 갔다 한 것처럼 보이지만 **줄인 축과 늘린 축이 다르다** —
   *   줄인 것은 자세(일감), 늘린 것은 방향(거울 대신 진짜 그림).
   *
   *   sell만 방향이 둘이다. 계산대는 마당 문이 x쪽이냐 y쪽이냐 둘뿐이라
   *   ↘·↙ 말고는 **화면에 절대 안 나온다**(Iso.yard의 gate). 안 나올 그림을
   *   시키지 않는다 — 그게 이번 주에 꼬리로 배운 것이다.
   *
   *   무늬 4 × (walk 4 + make 4 + sell 2 + sleep 4) = **56장**. */
  { dir: 'hero-body', size: '144×144', title: '일꾼 너구리 — 무늬 × 자세 × 방향',
    note: '파일명: `<무늬>-<자세>-<방향>.webp`.\n' +
          '무늬 넷 `a`·`b`·`c`·`d` · 자세 넷 `walk`·`make`·`sell`·`sleep` ·\n' +
          '방향 넷 `ne`(↗) `nw`(↖) `se`(↘) `sw`(↙).\n' +
          '**뒤집지 않는다** — 네 장 다 제 그림이다. 빛은 늘 왼쪽 위에서.\n' +
          '**앞치마·연장은 안 그린다.** 가게 정체성은 마당과 손에 든 물건이 낸다.\n' +
          '발밑 그림자 금지(코드가 그린다). 발끝은 아래 변, 몸은 가로 정중앙.\n' +
          '★ **무늬 A를 열넷 다 끝내고** 다음 무늬로 — 없는 무늬는 A로 때운다.\n' +
          '자세한 것은 `RACCOON.md`.',
    rows: ['a', 'b', 'c', 'd'].flatMap((f) =>
      [['walk', '걷기', ['ne', 'nw', 'se', 'sw']],
       ['make', '만드는 중', ['ne', 'nw', 'se', 'sw']],
       /* 계산대는 길 쪽을 본다 — 문이 x면 ↘, y면 ↙. 그 둘뿐이다. */
       ['sell', '파는 중 (★손바닥은 비워 둘 것)', ['se', 'sw']],
       ['sleep', '조는 중 — 만들 주문이 하나도 없을 때', ['ne', 'nw', 'se', 'sw']],
      ].flatMap(([q, ko, dirs]) => dirs.map((d) => ({
        id: `${f}-${q}-${d}`,
        why: `무늬 ${f.toUpperCase()} · ${ko} · ${{ne: '↗', nw: '↖', se: '↘', sw: '↙'}[d]}`,
      })))) },
  { dir: 'gear', size: '144×144', title: '가게 앞치마·연장 (선택 — 몸 위에 얹는다)', optional: true,
    note: '파일명: `<가게>-<자세>.webp`. **너구리를 그리지 않는다** —\n' +
          '앞치마·머리쓰개·연장만, 나머지는 투명. 몸과 같은 액자·같은 자리.\n' +
          '무늬와 상관없이 한 벌만 그리면 무늬 넷에 다 얹힌다.\n' +
          '**안 그려도 된다** — 가게 정체성은 마당과 손에 든 물건이 이미 낸다.\n' +
          '가게 색을 내고 싶어질 때 한 가게씩 넣으면 그때부터 보인다.',
    rows: SHOPS.flatMap((sh) => [
      { id: `${sh.id}-make`, why: `${sh.name} · 차림 (만드는 중)` },
      { id: `${sh.id}-side`, why: `${sh.name} · 차림 (옆)` },
    ]) },
  { dir: 'clerks', size: '144×144', title: '가게 전용 일꾼 (선택 — 겹치기를 통째로 덮는다)', optional: true,
    note: '파일명: `<가게>-<자세>.webp` — 이미 스무 장이 들어와 있고 그대로 쓰인다.\n' +
          '**새로 안 시킨다.** 공통 너구리로 안 나오는 특별한 가게가 생겼을 때만.\n' +
          '있으면 그 가게는 겹치기를 건너뛰고 이 한 장으로 그려진다.',
    rows: SHOPS.flatMap((sh) => [
      { id: `${sh.id}-make`, why: `${sh.name} · 만드는 중` },
      { id: `${sh.id}-sell`, why: `${sh.name} · 파는 중` },
    ]) },
];

/* --audit — **주문서에 없는 그림**을 일러 준다.
 * 손님이 바뀌거나(박쥐→매) 물건이 갈리면 옛 그림이 폴더에 남는다. 그건
 * 화면에 안 나오면서 저장소만 불린다 — 그런데 눈으로는 절대 안 보인다.
 * 여기서 세면 다음에 또 셀 일이 없다. */
/* --wired — **주문서와 코드를 서로 대 본다.** 2026-08-28에 만들었다.
 *
 * ★ 왜 이게 없어서 꼬였나.
 *   --audit은 "폴더에 있는데 주문서에 없는 그림"만 봤다. 반대쪽은 아무도
 *   안 봤다 — **주문서가 시키는데 코드는 한 번도 안 여는 그림.** 그런 줄은
 *   조용히 남아서 누군가 실제로 그린다. 실제로 그렇게 됐다:
 *     · hero-tail 8장 — 꼬리 흔들기를 접고도 목록에 남아 두 장이 그려졌다
 *     · ui/wheel · ui/needle — 룰렛은 코드가 직접 그리는데 그림을 시켰다
 *   그림값은 이 프로젝트에서 제일 비싼 값이다. 안 쓸 것을 시키면 안 된다.
 *
 * 코드에서 `Art.tex("<폴더>"` · `Art.ranked("<폴더>"`를 훑어 **폴더 단위**로 댄다.
 * 파일 하나까지는 못 본다(이름을 코드가 조립해서 만든다) — 폴더만으로도
 * 위의 둘은 다 잡힌다.
 */
if (process.argv.includes('--wired')) {
  const gd = [];
  const walk = (d) => {
    for (const f of readdirSync(d, { withFileTypes: true })) {
      if (f.name.startsWith('.')) continue;
      const full = `${d}/${f.name}`;
      if (f.isDirectory()) walk(full);
      else if (f.name.endsWith('.gd')) gd.push(readFileSync(full, 'utf8'));
    }
  };
  walk(`${ROOT}godot`);
  const opened = new Set();
  for (const src of gd)
    for (const m of src.matchAll(/Art\.(?:tex|ranked)\(\s*"([a-z-]+)"/g)) opened.add(m[1]);

  const asked = new Set(GROUPS.map((g) => g.dir));
  const onlyAsked = [...asked].filter((d) => !opened.has(d));   // 시키는데 안 연다
  const onlyOpened = [...opened].filter((d) => !asked.has(d));  // 여는데 안 시킨다

  /* 파일 이름까지 보는 곳 — 코드가 `Art.tex("ui", "back")`처럼 **이름을 그대로**
   * 적은 자리만 본다. 이름을 조립하는 곳(가게id·손님id)은 못 보고, 안 봐도 된다.
   * 이게 없어서 ui/wheel·ui/needle이 아무도 안 쓰는 채로 그려졌다. */
  const literal = new Set();   // Art.tex("ui", "back") — 이름을 그대로 적은 것
  const composed = new Set();  // Art.ranked("hero-body", "%s-%s" % [...]) — 만들어 쓰는 것
  for (const src of gd)
    for (const m of src.matchAll(/Art\.(?:tex|ranked)\(\s*"([a-z-]+)"\s*,\s*([^,)]+)/g)) {
      const arg = m[2].trim();
      if (/^"[a-z0-9-]+"$/.test(arg)) literal.add(`${m[1]}/${arg.slice(1, -1)}`);
      else composed.add(m[1]);
    }
  /* ★ 이름을 만들어 쓰는 폴더는 **건너뛴다.** hero-body는
   *   `Art.ranked("hero-body", "%s-%s" % [fur, pose])`처럼 부르므로 코드 안에
   *   'b-make'라는 글자가 없다 — 그걸 "안 쓴다"고 하면 백 줄이 헛으로 뜬다.
   *   (첫 판이 그랬다. 경고가 백 줄이면 아무도 안 읽는다.) */
  const dead = [];
  for (const g of GROUPS) {
    if (!opened.has(g.dir) || composed.has(g.dir)) continue;
    for (const r of g.rows) if (!literal.has(`${g.dir}/${r.id}`)) dead.push(`${g.dir}/${r.id}`);
  }

  let bad = 0;
  if (dead.length) {
    console.log('⚠️  주문서에 있는데 코드가 이름으로 안 여는 그림:');
    for (const k of dead) console.log(`     godot/art/${k}  ← 지금은 코드가 직접 그린다`);
  }
  if (onlyAsked.length) {
    bad += onlyAsked.length;
    console.log('❌ 주문서가 시키는데 **코드가 한 번도 안 여는** 폴더:');
    for (const d of onlyAsked) console.log(`     godot/art/${d}/  ← 그리면 버려진다`);
  }
  if (onlyOpened.length) {
    console.log('⚠️  코드는 여는데 주문서에 없는 폴더:');
    for (const d of onlyOpened) console.log(`     godot/art/${d}/  ← 일부러 비워 둔 것인지 확인할 것`);
  }
  if (!bad) console.log('✅ art      주문서가 시키는 폴더를 코드가 다 연다');
  process.exit(bad ? 1 : 0);
}

/* --json — 주문서를 **기계가 읽을 수 있게** 뱉는다.
 * 장부의 체크 목록을 손으로 옮겨 적으면 반드시 어긋난다(이번 주에 겪었다).
 * 여기서 뽑아 쓴다. */
if (process.argv.includes('--json')) {
  console.log(JSON.stringify(GROUPS.map((g) => ({
    dir: g.dir, title: g.title, size: g.size, optional: !!g.optional,
    rows: g.rows.map((r) => ({ id: r.id, why: r.why, has: has(g.dir, r.id) })),
  }))));
  process.exit(0);
}

if (process.argv.includes('--audit')) {
  const want = new Map();               // dir → 기대하는 id 집합
  for (const g of GROUPS) {
    if (!want.has(g.dir)) want.set(g.dir, new Set());
    for (const r of g.rows) want.get(g.dir).add(r.id);
  }
  /* ★ 주문서에 없어도 **코드가 읽는** 그림이 있다. 이걸 모르면 이 도구는
   *   "안 쓴다"고 거짓말을 하고, 그 말을 믿고 지우면 화면에서 그림이 사라진다.
   *   실제로 한 번 그럴 뻔했다(2026-08-27).
   *   - items/<id>  : 주문서는 등장하는 단의 그림(-2·-3)만 시키지만,
   *                   art.gd의 ranked()가 못 찾으면 **기본 이름으로 내려온다**.
   *   (staff/ 는 2026-08-28에 통째로 없앴다 — 겹치기로 바뀌며 안 닿는 길이 됐다.) */
  for (const g of GROUPS) if (g.dir === 'items') for (const r of g.rows)
    want.get('items').add(r.id.replace(/-[123]$/, ''));

  let n = 0, bytes = 0;
  for (const dir of readdirSync(`${ROOT}${DIR}`, { withFileTypes: true })) {
    if (!dir.isDirectory()) continue;
    const ok = want.get(dir.name);
    if (!ok) { console.log(`## ${dir.name}/ — 주문서에 없는 폴더 통째`); }
    for (const f of readdirSync(`${ROOT}${DIR}/${dir.name}`)) {
      if (!/\.(png|webp)$/.test(f)) continue;
      const id = f.replace(/\.(png|webp)$/, '');
      if (ok && ok.has(id)) continue;
      const { size } = statSync(`${ROOT}${DIR}/${dir.name}/${f}`);
      console.log(`  ${dir.name}/${f}  ${(size / 1024).toFixed(0)}KB`);
      n++; bytes += size;
    }
  }
  console.log(`\n주문서에 없는 그림 ${n}장 · ${(bytes / 1048576).toFixed(1)}MB`);
  process.exit(0);
}

  /* ★ 카드 그림을 뺐다(2026-08-27, 유저: "일꾼카드, 동물 카드 빼자 의미 없다").
   *
   *   손님 카드 30장 + 등급판 90장 + 일꾼 카드 15장 + 승급판 30장 = **165장**이었다.
   *   동물이 60마리가 되면 카드만 240장이고, 화면에는 **107×160**으로 뜨는데
   *   512×768을 싣고 있었다 — 게임 그림 17MB 중 14MB가 카드였다.
   *
   *   빼도 뽑기 연출은 안 죽는다. 틀·이름·설명·그림자·등급 색 물듦·뒤집기는
   *   **전부 코드가 그린다**(card.gd). 초상 자리에는 걷는 모습이 들어간다 —
   *   card.gd가 그림 없을 때 그리는 그림이 이미 그렇게 되어 있어서 코드는 한 줄도 안 고쳤다.
   *
   *   그래서 손님 한 마리에 드는 그림이 **7장 → 3장**(걷기·정면·뒤)이 됐다. */

let done = 0, total = 0;
const lines = [];
for (const g of GROUPS) {
  const left = g.rows.filter((r) => !has(g.dir, r.id));
  if (!g.optional) { done += g.rows.length - left.length; total += g.rows.length; }
  lines.push(`### ${g.title}${g.optional ? ' (선택)' : ''} — \`${DIR}/${g.dir}/\` · ${g.size} · **${left.length}장 남음**`, '');
  if (g.note) lines.push(g.note, '');
  if (!left.length) lines.push('전부 들어왔다. ✅', '');
  else {
    for (const r of left) lines.push(`- [ ] \`${r.id}.webp\` — ${r.why}`);
    lines.push('');
  }
}

const head = `> 이 칸은 \`node tools/art.mjs --write\`가 다시 쓴다.\n` +
  `> **그림을 폴더에 넣으면 목록에서 저절로 빠진다** — 손으로 지울 필요 없다.\n\n` +
  `**${done} / ${total}장** 들어왔다.\n`;
const body = head + '\n' + lines.join('\n').trimEnd() + '\n';

if (process.argv.includes('--write')) {
  const p = `${ROOT}ASSETS.md`;
  const md = readFileSync(p, 'utf8');
  const A = '<!-- 목록시작 -->', B = '<!-- 목록끝 -->';
  const i = md.indexOf(A), j = md.indexOf(B);
  if (i < 0 || j < 0) { console.error('ASSETS.md에 목록 표시가 없다'); process.exit(1); }
  writeFileSync(p, md.slice(0, i + A.length) + '\n' + body + '\n' + md.slice(j));
  console.log(`ASSETS.md 갱신 — ${done}/${total}장`);
} else {
  console.log(body);
}
