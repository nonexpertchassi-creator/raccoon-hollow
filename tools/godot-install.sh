#!/bin/sh
# godot-install.sh — 이 작업방에 Godot을 깐다.
#
# 왜 스크립트로 두는가: 이 상자는 일회용이라 세션이 끝나면 지워진다.
# 다음에 또 깔아야 하는데, 그때 "어디서 받더라"를 다시 찾고 싶지 않다.
#
# godotengine.org와 tuxfamily 미러는 이 방에서 막혀 있다.
# GitHub 릴리스 파일(objects.githubusercontent.com)은 열려 있어서 그쪽으로 받는다.
#
# 내 컴퓨터에 깔 때는 이 스크립트가 필요 없다 — https://godotengine.org/download
# 에서 받아 압축만 풀면 된다. Godot은 설치 과정이 없는 단일 실행 파일이다.
set -e
V="${1:-4.7.2}"
DIR=/opt/godot
URL="https://github.com/godotengine/godot/releases/download/${V}-stable/Godot_v${V}-stable_linux.x86_64.zip"
mkdir -p "$DIR"
curl -sSL -m 600 -o "$DIR/godot.zip" "$URL"
unzip -o -q "$DIR/godot.zip" -d "$DIR"
rm "$DIR/godot.zip"
ln -sf "$DIR/Godot_v${V}-stable_linux.x86_64" /usr/local/bin/godot
godot --headless --version
