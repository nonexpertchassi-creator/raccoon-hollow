#!/usr/bin/env python3
# 스킬 값 표를 장부에 손으로 적었더니 어긋났다 — 총합이 19,243과 19,244로 갈렸다.
# 진짜는 balnum.py 한곳이고 여기는 뽑아 쓴 것이다(규칙 3).
#
#   python3 tools/skilltab.py

import io, sys, os
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from balnum import N

LEDGER = Path(__file__).resolve().parent.parent / "ledger" / "rm.html"
S = N["스킬"]["목록"]

_K = N["스킬"]["값곡선"]
def cost(s, lv):                                   # 그 레벨 하나를 사는 값 — 여덟이 다 같다
    k = _K["꺾는_레벨"]
    return _K["기울기1"] * lv if lv <= k else \
           _K["기울기1"] * k + _K["기울기2"] * (lv - k)
def total(s):     return sum(cost(s, i) for i in range(1, s["최대"] + 1))

def cell(v): return f'<td class="num mono">{v}</td>'

rows = ['    <tr><th>스킬</th><th>레벨마다</th><th>다 올리면</th>'
        '<th class="num mono">1렙</th><th class="num mono">10렙</th>'
        '<th class="num mono">20렙</th><th class="num mono">마스터까지</th></tr>']
for s in S:
    at = lambda lv: f"{round(cost(s, lv)):,}" if lv <= s["최대"] else "—"
    rows.append("    <tr><td>{} {}</td><td>{}</td><td>{}</td>{}{}{}{}</tr>".format(
        s["아이콘"], s["이름"], s["레벨당"], s["끝"],
        cell(at(1)), cell(at(10)), cell(at(20)), cell(f'{round(total(s)):,}')))
KO = {8: "여덟", 9: "아홉", 10: "열"}.get(len(S), str(len(S)))
rows.append(f'    <tr><td colspan="6"><b>{KO} 다 마스터</b></td>'
            f'<td class="num mono"><b>{round(sum(total(s) for s in S)):,}</b></td></tr>')

html = io.open(LEDGER, encoding="utf-8").read()
a, b = "<!-- AUTO:skill -->", "<!-- /AUTO:skill -->"
if a not in html:
    raise SystemExit(f"장부에 {a} 자리가 없다 — 표를 감싸 두어야 한다")
i, j = html.index(a) + len(a), html.index(b)
html = html[:i] + "\n" + "\n".join(rows) + "\n  " + html[j:]
io.open(LEDGER, "w", encoding="utf-8").write(html)
print(f"스킬 {len(S)}개 · 다 마스터 {round(sum(total(s) for s in S)):,}")
