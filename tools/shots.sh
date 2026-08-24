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

shot() {   # shot <파일이름> <환경변수들…>
  name=$1; shift
  rm -f godot/shot.png
  env "$@" SHOT_MINUTES=$M godot --path godot tests/shot.tscn >/dev/null 2>&1 || true
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
shot 08-도감-점장카드 SHOT_PANEL=guests SHOT_TAB=work
shot 09-뽑기          SHOT_PANEL=gacha SHOT_TAB=items
shot 10-룰렛          SHOT_PANEL=gacha SHOT_TAB=work
shot 11-의뢰          SHOT_PANEL=quests
shot 12-장날소식      SHOT_PANEL=ledger
shot 13-점장카드열림  SHOT_CARD=smith
shot 14-처음켰을때    SHOT_MINUTES=0
echo "shots/ 에 다 넣었다."
