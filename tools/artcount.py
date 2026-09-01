#!/usr/bin/env python3
# 그려야 할 그림이 몇 장인지 세서 art/그림목록.md 를 다시 쓴다.
# 손으로 세면 반드시 어긋난다(규칙 3). 물건 수는 장부에서 뽑아 온다.

import io, re
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
LEDGER = HERE / "ledger" / "rm.html"
OUT = HERE / "art" / "그림목록.md"

html = io.open(LEDGER, encoding="utf-8").read()
items = 0
shops = set()
for ch, head, body in re.findall(
        r'<table data-ch="(\d)">\s*<tr><th></th><th>레벨</th>(.*?)</tr>(.*?)</table>', html, re.S):
    names = [re.sub(r"<.*?>", "", x).strip() for x in re.findall(r"<th>(.*?)</th>", head)]
    rows = [r for r in re.findall(r"<tr[^>]*>(.*?)</tr>", body, re.S)]
    for n in names:
        shops.add((ch, n))
    items += len(names) * len([r for r in rows if r.count("<td") == len(names) + 2])

CH = 5           # 지금 잡힌 챕터
SHOPS = len(shops)

G = [
 ("물건", items, "챕터 5 × 매장 20 × 물건 20", "제일 큰 덩이. 정면·배경 투명"),
 ("매장 건물", SHOPS, "챕터마다 20채", "2.5D. 앞벽 없음"),
 ("오브제", SHOPS, "매장마다 하나", "2.5D. 절구·가마·낚싯대"),
 ("간판", SHOPS * 3, "매장마다 3단계", "나무 · 정교한 나무 · 철제"),
 ("가로등", CH * 3, "챕터마다 3단계", "나라 분위기를 탄다"),
 ("너구리 동작", 8, "공정 여덟", "몸이 겹치지 않게"),
 ("너구리 기본", 4, "걷기 · 서기 · 졸기 · 건네기", ""),
 ("손님 기본", 10, "10종", "이모지 말풍선은 그림 아님"),
 ("손님 · 챕터 개", 10, "챕터마다 하나 (10챕터까지)", "진돗개 · 시바견 …"),
 ("바닥 · 길", CH * 3, "챕터마다 3벌", "흙 · 돌 · 물"),
 ("배경", CH * 2, "챕터마다 낮·밤", "가운데 광장 포함"),
 ("만화 컷", CH * 6, "챕터 깰 때 6컷", "대사 없음"),
 ("UI 아이콘", 40, "메뉴 · 스킬 8 · 능력 7 · 단추", "돈 · 보석 포함"),
]
E = [
 ("이벤트 테마 하나에", "", "", ""),
 ("  이벤트 손님", 12, "테마마다 12종", "실루엣은 코드로 만든다"),
 ("  이벤트 배경", 1, "", ""),
 ("  이벤트 오브제", 4, "광장 꾸미기", ""),
]

L = ["# 그려야 할 그림 — 몇 장인가", "",
     "**이 파일은 자동으로 뽑은 것이다. 손으로 고치지 마라** —",
     "`ledger/rm.html`을 고치고 `python3 tools/artcount.py`를 돌린다.", "",
     "## 챕터 5개를 다 만들 때", "",
     "| 무엇 | 장수 | 왜 그 수 | 메모 |", "|---|---:|---|---|"]
tot = 0
for n, c, why, memo in G:
    tot += c
    L.append(f"| {n} | {c:,} | {why} | {memo} |")
L += [f"| **합** | **{tot:,}** | | |", "",
      "## 이벤트는 따로 — 계속 는다", "",
      "| 무엇 | 장수 | 왜 그 수 | 메모 |", "|---|---:|---|---|"]
ev = 0
for n, c, why, memo in E:
    if c == "":
        L.append(f"| **{n}** | | | |"); continue
    ev += c
    L.append(f"| {n} | {c} | {why} | {memo} |")
L += [f"| **테마 하나 합** | **{ev}** | | |", "",
      f"낼 때 테마 4개면 **{ev*4}장**, 그다음 **한 달에 {ev}장씩**.", "",
      "## 이 목록에 없는 것", "",
      "- **실루엣** — 있는 그림을 어둡게 칠한다(장부 · UX)",
      "- **말풍선 이모지** — 글꼴이지 그림이 아니다",
      "- **매장 별 · 진행 바** — 화면 쪽에서 그린다"]
io.open(OUT, "w", encoding="utf-8").write("\n".join(L))
print(f"{OUT.relative_to(HERE)} · 챕터 5 그림 {tot:,}장 · 이벤트 테마 하나 {ev}장")
