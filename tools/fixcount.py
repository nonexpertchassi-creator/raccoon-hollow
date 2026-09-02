#!/usr/bin/env python3
# 갈래마다 "픽스 몇 개"라는 숫자가 세 곳에 있었다 —
# 옆 목록 · 갈래 머리 · 그리고 진짜인 픽스 표.
# 손으로 셋을 맞추면 반드시 어긋난다(규칙 3). 그래서 표를 세서 나머지 둘을 고친다.
# 표가 진짜고 나머지는 뽑아 쓴 것이다.
#
#   python3 tools/fixcount.py        재어만 보고 어긋나면 1로 끝난다
#   python3 tools/fixcount.py --fix  어긋난 곳을 고친다

import io, re, sys
from pathlib import Path

LEDGER = Path(__file__).resolve().parent.parent / "ledger" / "rm.html"
FIX = "--fix" in sys.argv

class _All:
    def __init__(self, parts): self._s = "".join(parts)
    def group(self, i): return self._s

html = io.open(LEDGER, encoding="utf-8").read()
orig = html
bad = []

for sid, body in re.findall(r'<section id="(\w+)">(.*?)</section>', html, re.S):
    head = re.search(r'(<div class="zero[^"]*">픽스 <b>)(\d+)(</b>)', body)
    if not head:
        continue
    parts = re.findall(r'<table class="fx">(.*?)</table>', body, re.S)
    table = _All(parts) if parts else None
    real = len(re.findall(r"<tr><td>[\U0001F7E6\U0001F7E8\U0001F7E9]", table.group(1))) if table else 0

    # 갈래 머리
    if head.group(2) != str(real):
        bad.append(f"{sid} 갈래 머리 {head.group(2)} → {real}")
        html = html.replace(body, body.replace(head.group(0), head.group(1) + str(real) + head.group(3), 1), 1)

    # 옆 목록
    nav = re.search(r'(<a href="#%s"><span>[^<]*</span><span class="c[^"]*">)(\d+)(</span></a>)' % sid, html)
    if nav and nav.group(2) != str(real):
        bad.append(f"{sid} 옆 목록 {nav.group(2)} → {real}")
        html = html.replace(nav.group(0), nav.group(1) + str(real) + nav.group(3), 1)

    print(f"{sid:9} 픽스 {real}")

if not bad:
    print("어긋난 곳 없다")
    sys.exit(0)

print("\n어긋난 곳:")
for b in bad:
    print("  " + b)

if not FIX:
    print("\n고치려면 --fix 를 붙인다")
    sys.exit(1)

io.open(LEDGER, "w", encoding="utf-8").write(html)
print("\n고쳤다")
