#!/bin/sh
# crosscheck.sh — 옮긴 GDScript가 JS판과 **똑같이** 도는지 대조한다.
# 실행: tools/crosscheck.sh [조각…]   (없으면 전부)
#
# 이 프로젝트에서 엔진 이관이 무서운 이유는 하나다: 옮기다 조용히 달라지는 것.
# 숫자 하나가 반올림 방향만 달라져도 몇 시간 뒤에 경제가 어긋나는데,
# 그때는 어디서 갈라졌는지 못 찾는다.
#
# sim.js는 몇 달간 실제로 돌았고 수백 시간을 재본 코드다. 그러니 **답안지로 쓴다.**
# 같은 입력을 양쪽에 넣고 한 글자라도 다르면 여기서 잡는다.
set -e
cd "$(dirname "$0")/.."
SUBJECTS="${*:-fmt rng content sim}"

# class_name(전역 이름)은 프로젝트를 한 번 훑어야 등록된다.
# 조건부로 건너뛰게 했더니 .gd를 고쳐도 옛 이름이 남을 여지가 있었다. 늘 훑는다.
godot --headless --path godot --import >/dev/null 2>&1 || true

FAIL=0
for S in $SUBJECTS; do
  node tools/answers.mjs "$S"
  godot --headless --path godot --script tests/crosscheck.gd -- "$S" >/dev/null 2>&1
  if diff -q godot/out_js.txt godot/out_godot.txt >/dev/null 2>&1; then
    printf "✅ %-8s %s개 전부 일치\n" "$S" "$(wc -l < godot/out_js.txt | tr -d ' ')"
  else
    FAIL=1
    printf "❌ %-8s 어긋났다:\n" "$S"
    diff godot/out_js.txt godot/out_godot.txt | head -6 | sed 's/^/     /'
  fi
done
exit $FAIL
