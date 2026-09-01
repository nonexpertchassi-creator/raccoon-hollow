#!/usr/bin/env python3
# 장부에서 매장과 물건을 뽑아 art/물건목록.md 를 다시 쓴다.
# 그림을 뽑을 때 통째로 복붙하는 종이다.
#
# 이름은 장부에만 있다(규칙 3). 여기서 손으로 고치면 반드시 어긋난다.
# 2026-09-01: 챕터가 다섯이 됐다. 표마다 data-ch 로 챕터를 적어 두었다.

import io, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
LEDGER = HERE / "ledger" / "rm.html"
OUT = HERE / "art" / "물건목록.md"

html = io.open(LEDGER, encoding="utf-8").read()

def strip(s):
    return re.sub(r"<.*?>", "", s).strip()

# 챕터 이름 — <h3>2챕터 · 미국 서부 · 매장 20개</h3>
NAMES = {int(n): t.strip() for n, t in
         re.findall(r"<h3>(\d)챕터 · (.+?) · 매장 20개", html)}

# 물건 표 — <table data-ch="2"> 머리에 매장 이름 넷, 몸에 20줄
chapters = {}
for ch, head, body in re.findall(
        r'<table data-ch="(\d)">\s*<tr><th></th><th>레벨</th>(.*?)</tr>(.*?)</table>',
        html, re.S):
    ch = int(ch)
    shops = [strip(x) for x in re.findall(r"<th>(.*?)</th>", head)]
    rows = [[strip(c) for c in re.findall(r"<td[^>]*>(.*?)</td>", r)]
            for r in re.findall(r"<tr[^>]*>(.*?)</tr>", body, re.S)]
    for i, name in enumerate(shops):
        chapters.setdefault(ch, {})[name] = [r[i + 2] for r in rows if len(r) == len(shops) + 2]

if not chapters:
    raise SystemExit("장부에서 물건 표를 못 찾았다 — data-ch 가 붙어 있나 본다")

lines = ["# 그릴 물건 목록",
         "",
         "**이 파일은 자동으로 뽑은 것이다. 손으로 고치지 마라** —",
         "`ledger/rm.html`을 고치고 `python3 tools/itemlist.py`를 돌린다.",
         ""]

total = 0
for ch in sorted(chapters):
    shops = chapters[ch]
    name = NAMES.get(ch, f"{ch}챕터")
    if len(shops) != 20:
        raise SystemExit(f"{ch}챕터 매장이 20개가 아니다: {len(shops)}")
    bad = {k: len(v) for k, v in shops.items() if len(v) != 20}
    if bad:
        raise SystemExit(f"{ch}챕터에 물건이 20개가 아닌 매장이 있다: {bad}")
    names = [x for v in shops.values() for x in v]
    dup = sorted({x for x in names if names.count(x) > 1})
    if dup:
        raise SystemExit(f"{ch}챕터 안에 겹치는 물건 이름이 있다: {dup}")
    total += len(names)

    lines += [f"## {ch}챕터 · {name}", ""]
    for i, (shop, items) in enumerate(shops.items(), 1):
        lines += [f"### ch{ch}/{i:02d}-{shop}", "", "```"]
        lines += [f"{j:02d}-{x}" for j, x in enumerate(items, 1)]
        lines += ["```", ""]

io.open(OUT, "w", encoding="utf-8").write("\n".join(lines))
print(f"{OUT.relative_to(HERE)} · 챕터 {len(chapters)} · 매장 {len(chapters)*20} · 물건 {total} · 겹침 0")
