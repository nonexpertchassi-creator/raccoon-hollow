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
# GOLDEN=write 로 부르면 sim의 '박아 둔 정답'을 지금 값으로 다시 쓴다

# class_name(전역 이름)은 프로젝트를 한 번 훑어야 등록된다.
# 조건부로 건너뛰게 했더니 .gd를 고쳐도 옛 이름이 남을 여지가 있었다. 늘 훑는다.
godot --headless --path godot --import >/dev/null 2>&1 || true

# ★ 매달리면 죽인다(2026-08-28). GDScript에 문법 오류가 나면 Godot은
#   **실패하는 게 아니라 그대로 매달린다** — _init이 못 돌아서 quit()에 못 닿고,
#   헤드리스 SceneTree는 영원히 돈다. 실제로 오타 하나에 검사가 열 분씩
#   멈췄고, 화면에는 아무 말도 안 나왔다(출력이 파이프에 갇혀서).
#   시간을 걸어 두면 "멈췄다"가 "실패했다"로 바뀐다 — 그건 볼 수 있는 고장이다.
#   맥에는 timeout이 없어서 직접 잰다.
GD_LIMIT="${GD_LIMIT:-180}"
gd() {
	"$@" >/tmp/gd_out.$$ 2>&1 &
	_pid=$!
	_n=0
	while kill -0 "$_pid" 2>/dev/null; do
		_n=$((_n + 1))
		if [ "$_n" -gt "$((GD_LIMIT * 2))" ]; then
			kill -9 "$_pid" 2>/dev/null
			echo "★ ${GD_LIMIT}초가 지나도 안 끝난다 — 문법 오류일 가능성이 크다:"
			tail -6 /tmp/gd_out.$$
			rm -f /tmp/gd_out.$$
			return 1
		fi
		sleep 0.5
	done
	wait "$_pid" 2>/dev/null || true
	cat /tmp/gd_out.$$
	rm -f /tmp/gd_out.$$
}

# 누르기·저장은 자바스크립트에 짝이 없다(브라우저 저장을 쓰니까).
# 그래서 답안지 대신 **Godot 안에서 스스로 증명하게** 한다.
FAIL=0

pass() { printf "✅ %-8s %s\n" "$1" "$2"; }
fail() { FAIL=1; printf "❌ %-8s %s\n" "$1" "$2"; }

# 좌표는 눈으로 못 믿는다 — 두드려 보고 sim이 실제로 변했는지 본다
OUT=$(gd godot --headless --path godot tests/taptest.tscn 2>&1 || true)
case "$OUT" in
  *"TAPTEST OK"*) pass tap "누르기 열 가지 다 먹는다(승급 공사·패시브 스킬 포함)" ;;
  *) fail tap "" ; echo "$OUT" | grep "TAPTEST FAIL" | sed 's/^/     /' ;;
esac

# 규칙만 시험하면 "저장은 되는데 파일이 안 써진다"를 놓친다
OUT=$(gd godot --headless --path godot --script tests/yard.gd 2>&1 || true)
case "$OUT" in
  *"YARD OK"*) pass yard "마당 배치가 장부와 같다" ;;
  *) fail yard "" ; echo "$OUT" | grep "YARD FAIL" | sed 's/^/     /' ;;
esac

OUT=$(gd godot --headless --path godot --script tests/savefile.gd 2>&1 || true)
case "$OUT" in
  *"같은가: 예"*) pass file "파일에 담았다 꺼내도 같다" ;;
  *) fail file "" ; echo "$OUT" | grep -iE "아니오|error" | head -3 | sed 's/^/     /' ;;
esac

# 소수가 비트 하나까지 돌아오는지. 글자로 비교하면 표기 차이에 속는다 —
# 실제로 JSON으로 저장했을 때 1비트가 어긋나 있었고, 글자 비교로는 못 잡았다.
OUT=$(gd godot --headless --path godot --script tests/precision.gd 2>&1 || true)
case "$OUT" in
  *"다른 것 0개"*) pass bits "저장한 소수가 비트까지 그대로다" ;;
  *) fail bits "" ; echo "$OUT" | grep "값이 다르다" | head -3 | sed 's/^/     /' ;;
esac

# 뽑기·룰렛은 자바스크립트에 짝이 없다(Godot에만 있는 규칙이다).
# 확률은 눈으로 못 보므로 십만 번씩 굴려 표와 견준다.
OUT=$(gd godot --headless --path godot --script tests/gacha.gd 2>&1 || true)
case "$OUT" in
  *"GACHA OK"*) pass gacha "뽑기·룰렛·주사위 확률이 표대로다" ;;
  *) fail gacha "" ; echo "$OUT" | grep "GACHA FAIL" | head -4 | sed 's/^/     /' ;;
esac

for S in $SUBJECTS; do
  # ★ sim은 자바스크립트 **답**은 안 쓰지만(2026-08-22에 갈라졌다) 이 줄은
  #   **문제지(cases.txt)도 만든다.** 건너뛰었더니 옛 문제지가 남아 Godot이
  #   영영 안 끝나는 판을 돌았다(2026-08-27에 한 번 당했다). 답안지는 계속 돈다.
  node tools/answers.mjs "$S"
  godot --headless --path godot --script tests/crosscheck.gd -- "$S" >/dev/null 2>&1
  # ── sim은 이제 **어제의 자신**과 대조한다 ──
  #
  # ★ 2026-08-22, 답안지가 갈라졌다. 뽑기가 들어오면서 손님이 오는 규칙이
  #   바뀌었는데(문턱 → 뽑기), 자바스크립트판에는 뽑기가 없다. 두 판은 이제
  #   영영 다른 게임이라 서로 대조할 수가 없다.
  #
  #   그렇다고 시험을 버리면 규칙을 고칠 때마다 무엇이 달라졌는지 알 길이 없다.
  #   그래서 **정답을 파일로 박아 둔다**(golden_sim.txt). 규칙을 일부러 고쳤으면
  #   아래 명령으로 정답을 다시 박고, 그 차이를 커밋에 남긴다:
  #
  #       GOLDEN=write tools/crosscheck.sh sim
  #
  #   저장 시험이 이미 쓰던 방법과 같다 — 답안지가 자기 자신이 되는 것이다.
  if [ "$S" = "sim" ]; then
    G=godot/tests/golden_sim.txt
    if [ "$GOLDEN" = "write" ]; then
      cp godot/out_godot.txt "$G"
      printf "📌 %-8s 정답을 다시 박았다 (%s줄)\n" "$S" "$(wc -l < "$G" | tr -d ' ')"
    elif [ ! -f "$G" ]; then
      FAIL=1
      printf "❌ %-8s 박아 둔 정답이 없다 — GOLDEN=write 로 한 번 만들 것\n" "$S"
    elif diff -q "$G" godot/out_godot.txt >/dev/null 2>&1; then
      printf "✅ %-8s %s줄 전부 어제와 같다\n" "$S" "$(wc -l < "$G" | tr -d ' ')"
    else
      FAIL=1
      printf "❌ %-8s 어제와 달라졌다 (일부러 고쳤으면 GOLDEN=write):\n" "$S"
      diff "$G" godot/out_godot.txt | head -6 | cut -c1-150 | sed 's/^/     /'
    fi
    continue
  fi
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
