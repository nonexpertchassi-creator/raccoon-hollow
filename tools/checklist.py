#!/usr/bin/env python3
# 장부의 픽스 표를 읽어서 두 자리를 다시 쓴다.
#
#   미결정 모음   살아 있는 🟨 전부 — 유저가 승인 안 한 것
#   파랑 점검표   🟦 전부 — 정해진 것을 한 번에 훑는 자리
#
# 손으로 옮겨 적으면 반드시 한쪽이 어긋난다(규칙 3).
# 진짜는 갈래의 픽스 표고 여기는 뽑아 쓴 것이다.
#
#   python3 tools/checklist.py

import io, re, sys
from pathlib import Path

LEDGER = Path(__file__).resolve().parent.parent / "ledger" / "rm.html"
ROW = re.compile(r'<tr><td>([\U0001F7E6\U0001F7E8\U0001F7E9])</td><td>(.*?)</td>'
                 r'<td class="who">(.*?)</td></tr>', re.S)

class _All:
    def __init__(self, parts): self._s = "".join(parts)
    def group(self, i): return self._s

html = io.open(LEDGER, encoding="utf-8").read()

branches = []
for sid, body in re.findall(r'<section id="(\w+)">(.*?)</section>', html, re.S):
    parts = re.findall(r'<table class="fx">(.*?)</table>', body, re.S)
    if not parts:
        continue
    table = _All(parts)
    title = re.search(r"<h2>(.*?)</h2>", body).group(1)
    rows = ROW.findall(table.group(1))
    total = len(re.findall(r"<tr><td>[\U0001F7E6\U0001F7E8\U0001F7E9]", table.group(1)))
    if len(rows) != total:
        raise SystemExit(f"{sid}: 픽스 줄 {total}개 중 {len(rows)}개만 읽혔다 — 표 형식이 어긋났다")
    branches.append((sid, title, rows))

if not branches:
    raise SystemExit("픽스 표를 못 찾았다")

def head(sid, title, n, what):
    return (f'  <tr><td colspan="2" style="background:var(--sunk); font-weight:700; font-size:11.5px;'
            f' letter-spacing:.06em; color:var(--faint)">'
            f'<a href="#{sid}" style="color:var(--faint)">{title}</a> · {what} {n}</td></tr>')

# ── 미결정 모음 ──
yellow_n = 0
out = []
rows_all = [(s, t, r) for s, t, rs in branches for r in rs if r[0] == "\U0001F7E8"
            for s, t, r in [(s, t, r)]]
groups = [(s, t, [r for r in rs if r[0] == "\U0001F7E8"]) for s, t, rs in branches]
groups = [g for g in groups if g[2]]
yellow_n = sum(len(g[2]) for g in groups)

out.append(f'  <div class="zero{"" if yellow_n else " done"}">아직 승인 안 받은 것 <b>{yellow_n}</b></div>')
if yellow_n:
    out.append('  <p class="sub"><b>전부 내가 판단한 것이다.</b> 유저가 <i>“그거 아니야”</i> 한 마디면 물린다.</p>')
    out.append('  <div class="tw"><table>')
    out.append('    <tr><th>어느 갈래</th><th>내가 정한 것</th></tr>')
    for sid, title, rs in groups:
        out.append(head(sid, title, len(rs), "노랑"))
        for _, what, why in rs:
            out.append(f'  <tr><td class="who" style="white-space:nowrap">🟨</td>'
                       f'<td>{what.strip()}<div class="who" style="margin-top:3px">{why.strip()}</div></td></tr>')
    out.append("  </table></div>")
else:
    out.append('  <div class="note"><b>남은 노랑이 없다.</b> 낸 것을 유저가 다 물렸거나 승인했다.</div>')
out.append('  <div class="note"><b>아무도 안 정한 것</b>(내가 판단조차 안 한 것)은 갈래마다 '
           '<b>「아직 안 정한 것」</b>에 따로 있다 — 그건 성격이 달라서 안 섞는다.</div>')

# ── 파랑 점검표 ──
blue = []
bgroups = [(s, t, [r for r in rs if r[0] == "\U0001F7E6"]) for s, t, rs in branches]
bgroups = [g for g in bgroups if g[2]]
blue_n = sum(len(g[2]) for g in bgroups)
blue.append(f'  <div class="zero done">정해진 것 <b>{blue_n}</b></div>')
blue.append('  <div class="tw"><table>')
blue.append('    <tr><th></th><th>정한 것 · 유저의 말</th></tr>')
for sid, title, rs in bgroups:
    blue.append(head(sid, title, len(rs), "파랑"))
    for i, (_, what, why) in enumerate(rs, 1):
        blue.append(f'  <tr><td class="num mono who">{i}</td>'
                    f'<td>{what.strip()}<div class="who" style="margin-top:3px">{why.strip()}</div></td></tr>')
blue.append("  </table></div>")

def swap(tag, body):
    global html
    a, b = f"<!-- AUTO:{tag} -->", f"<!-- /AUTO:{tag} -->"
    i, j = html.index(a) + len(a), html.index(b)
    html = html[:i] + "\n" + "\n".join(body) + "\n" + html[j:]

swap("open", out)
swap("blue", blue)

# 옆 목록의 미결정 수
html = re.sub(r'(<a href="#open"><span>미결정 모음</span><span class="c[^"]*">)[^<]*(</span></a>)',
              lambda m: m.group(1).replace('class="c"', 'class="c"') + str(yellow_n) + m.group(2), html)
html = re.sub(r'(<a href="#open"><span>미결정 모음</span><span class=")c[^"]*(")',
              lambda m: m.group(1) + ("c" if yellow_n else "c done") + m.group(2), html)

io.open(LEDGER, "w", encoding="utf-8").write(html)
print(f"미결정 {yellow_n} · 파랑 {blue_n}")

# 픽스 표 밖에 떠도는 🟨는 미결정 모음이 못 본다 — 네 번 그렇게 놓쳤다.
# 표에 올리든 파랑으로 바꾸든 하라고 여기서 말해 준다.
loose = len(re.findall(r"🟨 내 제안", html))
if loose:
    print(f"\n⚠ 본문에 떠도는 🟨가 {loose}개 있다 — 픽스 표에 없으면 미결정 모음에 안 잡힌다.")
    for m in re.finditer(r"🟨 내 제안</span>\s*\n?\s*(.{0,90})", html, re.S):
        print("   · " + re.sub(r"<[^>]+>", "", m.group(1)).strip().replace("\n", " "))
