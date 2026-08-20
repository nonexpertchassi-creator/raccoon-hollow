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
SUBJECTS="${*:-fmt rng content sim save}"

# class_name(전역 이름)은 프로젝트를 한 번 훑어야 등록된다.
# 조건부로 건너뛰게 했더니 .gd를 고쳐도 옛 이름이 남을 여지가 있었다. 늘 훑는다.
godot --headless --path godot --import >/dev/null 2>&1 || true

# 누르기·저장은 자바스크립트에 짝이 없다(브라우저 저장을 쓰니까).
# 그래서 답안지 대신 **Godot 안에서 스스로 증명하게** 한다.
FAIL=0

pass() { printf "✅ %-8s %s\n" "$1" "$2"; }
fail() { FAIL=1; printf "❌ %-8s %s\n" "$1" "$2"; }

# 좌표는 눈으로 못 믿는다 — 두드려 보고 sim이 실제로 변했는지 본다
OUT=$(godot --headless --path godot tests/taptest.tscn 2>&1 || true)
case "$OUT" in
  *"TAPTEST OK"*) pass tap "누르기 여섯 가지 다 먹는다" ;;
  *) fail tap "" ; echo "$OUT" | grep "TAPTEST FAIL" | sed 's/^/     /' ;;
esac

# 규칙만 시험하면 "저장은 되는데 파일이 안 써진다"를 놓친다
OUT=$(godot --headless --path godot --script tests/savefile.gd 2>&1 || true)
case "$OUT" in
  *"같은가: 예"*) pass file "파일에 담았다 꺼내도 같다" ;;
  *) fail file "" ; echo "$OUT" | grep -iE "아니오|error" | head -3 | sed 's/^/     /' ;;
esac

# 소수가 비트 하나까지 돌아오는지. 글자로 비교하면 표기 차이에 속는다 —
# 실제로 JSON으로 저장했을 때 1비트가 어긋나 있었고, 글자 비교로는 못 잡았다.
OUT=$(godot --headless --path godot --script tests/precision.gd 2>&1 || true)
case "$OUT" in
  *"다른 것 0개"*) pass bits "저장한 소수가 비트까지 그대로다" ;;
  *) fail bits "" ; echo "$OUT" | grep "값이 다르다" | head -3 | sed 's/^/     /' ;;
esac

for S in $SUBJECTS; do
  node tools/answers.mjs "$S"
  godot --headless --path godot --script tests/crosscheck.gd -- "$S" >/dev/null 2>&1
  # 저장 시험은 자기 자신과 대조한다 — 어긋난 줄에만 두 값이 같이 찍힌다
  if [ "$S" = "save" ]; then
    if grep -q "저장했다 켰을 때" godot/out_godot.txt; then
      FAIL=1
      printf "❌ %-8s 저장했다 켜니 달라졌다:\n" "$S"
      grep -A1 -B1 "저장했다 켰을 때" godot/out_godot.txt | head -4 | cut -c1-150 | sed 's/^/     /'
    else
      printf "✅ %-8s %s분 뒤까지 안 껐을 때와 똑같다\n" "$S" "$(wc -l < godot/out_godot.txt | tr -d ' ')"
    fi
    continue
  fi
  if diff -q godot/out_js.txt godot/out_godot.txt >/dev/null 2>&1; then
    printf "✅ %-8s %s개 전부 일치\n" "$S" "$(wc -l < godot/out_js.txt | tr -d ' ')"
  else
    FAIL=1
    printf "❌ %-8s 어긋났다:\n" "$S"
    diff godot/out_js.txt godot/out_godot.txt | head -6 | sed 's/^/     /'
  fi
done
exit $FAIL
