/* bestiary.mjs — 동물 도감(BESTIARY.md)을 content.js에서 뽑는다.
 *
 * 실행: node tools/bestiary.mjs
 *
 * 왜 도구로 만드나: 손으로 쓴 명부는 반드시 낡는다 — 손님을 더 넣거나
 * 숫자를 고치면 명부만 옛말이 된다(이 프로젝트에서 문서가 코드보다 오래
 * 산 사고가 세 번 있었다). 생김새(look)까지 content.js에 있으니
 * 이 파일 전체를 계산으로 만들 수 있다. 통째로 다시 쓴다 — 손대지 말 것.
 */
import { writeFileSync } from 'fs';
import { GUESTS, CARD_GRADES, STAR_CARDS } from '../content.js';

const gapWord = (g) =>
  g.every < 10 ? `쉴 새 없이(${g.every}초마다)` :
  g.every < 60 ? `자주(${g.every}초마다)` :
  g.every < 200 ? `이따금(${Math.round(g.every / 60)}분마다쯤)` :
  `어쩌다 한 번(${Math.round(g.every / 60)}분마다쯤)`;
const payWord = (g) =>
  g.pay < 1 ? `값을 깎는다(×${g.pay})` :
  g.pay <= 1.2 ? `제값을 낸다(×${g.pay})` :
  g.pay < 4 ? `후하게 쳐준다(×${g.pay})` : `돈을 아끼지 않는다(×${g.pay})`;
const walkWord = (g) =>
  g.speed >= 1.4 ? '잰걸음' : g.speed >= 1.0 ? '보통 걸음' : g.speed >= 0.7 ? '느린 걸음' : '아주 느린 걸음';

const total = STAR_CARDS.reduce((a, b) => a + b, 0);
const out = [];
out.push(`# 동물 도감 — 손님 서른

> 이 파일은 \`node tools/bestiary.mjs\`가 content.js에서 **통째로 다시 쓴다.**
> 손으로 고치지 말 것 — 생김새를 고치려면 content.js의 \`look\`을 고친다.

마을에 물건을 사러 오는 서른 짐승. **뽑기로 만나고**, 같은 카드를 모아
성(별)을 올린다(20성까지, 한 마리에 ${total.toLocaleString()}장).
등급이 귀할수록 실제로 좋은 손님이다 — 귀한데 쓸모없으면 뽑기가 죽는다.

그림은 두 벌이다: 걷는 모습(\`godot/art/guests/<id>.png\`, 128×128)과
카드 초상(\`godot/art/cards/<id>-1.png\`, 512×768). 규격은 ASSETS.md.
`);
for (const gr of CARD_GRADES) {
  const list = GUESTS.filter((g) => g.grade === gr.id);
  out.push(`\n## ${gr.face} ${gr.name} — ${list.length}종\n`);
  for (const g of list) {
    out.push(`### ${g.face} ${g.name} \`${g.id}\`
- **성격** ${g.desc}
- **생김새** ${g.look}
- **버릇** ${gapWord(g)} 와서 한 번에 ${g.qty}개, ${g.spread}종류를 훑고, ${payWord(g)}. ${walkWord(g)}.
`);
  }
}
out.push(`---

등급별로 **공들인 정도가 달라야 한다.** 흔함은 수수하게, 신수는 한눈에
다르게 — 같은 붓으로 그리되, 뽑았을 때 "좋은 게 나왔다"가 그림에서 와야 한다.
`);
writeFileSync('BESTIARY.md', out.join('\n'));
console.log(`BESTIARY.md — ${GUESTS.length}마리`);
