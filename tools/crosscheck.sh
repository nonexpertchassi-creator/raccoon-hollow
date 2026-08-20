#!/bin/sh
# crosscheck.sh — 옮긴 GDScript가 JS판과 **똑같이** 도는지 대조한다.
#
# 이 프로젝트에서 엔진 이관이 무서운 이유는 하나다: 옮기다 조용히 달라지는 것.
# 숫자 하나가 반올림 방향만 달라져도 몇 시간 뒤에 경제가 어긋나는데,
# 그때는 어디서 갈라졌는지 못 찾는다.
#
# JS판은 몇 달간 실제로 돌아간 코드다. 그러니 **답안지로 쓴다.**
# 같은 입력을 양쪽에 넣고 한 글자라도 다르면 여기서 잡는다.
set -e
cd "$(dirname "$0")/.."
# ★ 시험 문제는 **매번 같아야 한다.**
# 처음엔 난수만 4천 개 뿌렸는데 한 번은 통과하고 다음엔 실패했다 —
# 반올림이 갈리는 건 값이 딱 절반(5.625 같은)에 떨어질 때뿐이라, 그런 값이
# 우연히 걸려야만 드러났다. 어쩌다 잡히는 시험은 시험이 아니다.
# 그래서 씨앗을 고정하고, 절반에 딱 떨어지는 값을 일부러 전부 넣는다.
node -e "
const n = [];
const rng = (a => () => { a = a + 0x6D2B79F5 | 0;
  let x = Math.imul(a ^ a >>> 15, a | 1); x ^= x + Math.imul(x ^ x >>> 7, x | 61);
  return ((x ^ x >>> 14) >>> 0) / 4294967296; })(20260820);
for (let i = 0; i < 4000; i++) n.push(Math.floor(Math.pow(10, rng() * 15) * (1 + rng())));
// 자리 경계
[0,1,999,1000,1001,9999,10000,99999,100000,999999,1000000,1e9,1e12,1e15].forEach(x => n.push(x));
// 딱 절반에 떨어지는 값 — 반올림 규칙이 갈리는 자리는 여기뿐이다
for (let u = 1; u <= 1e12; u *= 1000)
  for (let a = 1; a < 100; a++) { n.push(a * u * 1000 + 5 * u / 10 * 10); n.push(a * u * 1000 + 500 * u); }
require('fs').writeFileSync('godot/cases.txt', n.filter(x => x >= 0 && Number.isFinite(x)).join('\n'));
"
# class_name(전역 이름)은 프로젝트를 한 번 훑어야 등록된다.
# 이 줄이 없으면 "Identifier \"Num\" not declared"로 죽는다.
[ -d godot/.godot ] || godot --headless --path godot --import >/dev/null 2>&1
godot --headless --path godot --script tests/crosscheck.gd >/dev/null 2>&1
node -e "
import('./sim.js').then(m=>{
  const fs=require('fs');
  const c=fs.readFileSync('godot/cases.txt','utf8').trim().split('\n');
  fs.writeFileSync('godot/out_js.txt', c.map(x=>m.fmt(Number(x))).join('\n')+'\n');
});"
sleep 1
if diff -q godot/out_js.txt godot/out_godot.txt >/dev/null; then
  echo "✅ fmt() — $(wc -l < godot/out_js.txt)개 전부 일치"
else
  echo "❌ 어긋났다:"
  paste -d'|' godot/cases.txt godot/out_js.txt godot/out_godot.txt \
    | awk -F'|' '$2!=$3 {print "  입력 " $1 " · JS " $2 " · Godot " $3}' | head -10
  exit 1
fi
