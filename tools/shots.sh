#!/bin/sh
# shots.sh — **게임의 모든 화면을 한 번에 찍는다.**
#
# 왜 만드나: 만드는 사람이 늘 컴퓨터 앞에 있는 게 아니다. 고칠 때마다
# "그래서 화면이 어떻게 됐는데"를 물어야 한다면 그건 만드는 쪽의 게으름이다.
# 한 번 돌리면 열두 장이 shots/ 에 떨어진다 — 그걸 보면 지금 게임이 어떤지
# 다 보인다. 회사에서 하는 '화면 대조(visual QA)'와 같은 것이다.
#
# 실행: tools/shots.sh [분]     (기본 25분어치 감아서 찍는다)
set -e
cd "$(dirname "$0")/.."
M="${1:-25}"
OUT=shots
mkdir -p $OUT
rm -f $OUT/*.png

# ★ 화면 장치가 없는 자리(클라우드 상자·서버)에서도 찍는다.
#   Godot은 그림을 그리려면 화면이 있어야 하는데, 클라우드에는 없다.
#   xvfb는 **화면인 척하는 가짜 화면**이다 — 아무도 안 보지만 Godot은 만족한다.
#   2026-08-28에 붙였다: 유저가 맥에서 떨어져 있어도 게임을 눈으로 볼 수 있어야 한다.
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
  run_shot() { env "$@" godot --path godot tests/shot.tscn; }
elif command -v xvfb-run >/dev/null 2>&1; then
  echo "(화면이 없어서 가짜 화면으로 찍는다 — xvfb)"
  run_shot() {
    xvfb-run -a --server-args="-screen 0 900x1600x24" \
      env "$@" godot --path godot tests/shot.tscn
  }
else
  echo "화면도 xvfb도 없다. 맥에서 돌리거나 'apt install xvfb'." >&2
  exit 1
fi

shot() {   # shot <파일이름> <환경변수들…>
  name=$1; shift
  rm -f godot/shot.png
  run_shot "$@" SHOT_MINUTES=$M >/dev/null 2>&1 || true
  if [ -f godot/shot.png ]; then
    cp godot/shot.png "$OUT/$name.png"
    printf "  %s\n" "$name"
  else
    printf "  %s — 못 찍었다\n" "$name"
  fi
}

echo "화면을 찍는다 ($M분어치 감아서)…"
shot 01-마을-기본     SHOT_ZOOM=1.0
shot 02-마을-멀리     SHOT_ZOOM=0.4
shot 03-마을-가까이   SHOT_ZOOM=1.7
shot 04-가게-제품     SHOT_PANEL=smith SHOT_TAB=items
shot 05-가게-일손     SHOT_PANEL=smith SHOT_TAB=work
shot 06-가게-승급     SHOT_PANEL=smith SHOT_TAB=rank
shot 07-도감-손님     SHOT_PANEL=guests SHOT_TAB=items
shot 08-도감-일꾼카드 SHOT_PANEL=guests SHOT_TAB=work
shot 09-뽑기          SHOT_PANEL=gacha SHOT_TAB=items
shot 10-룰렛          SHOT_PANEL=gacha SHOT_TAB=work
shot 11-의뢰          SHOT_PANEL=quests
shot 12-장날소식      SHOT_PANEL=ledger
shot 13-일꾼카드열림  SHOT_CARD=smith
shot 14-처음켰을때    SHOT_MINUTES=0
echo "shots/ 에 다 넣었다."
