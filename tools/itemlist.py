#!/usr/bin/env python3
"""장부(ledger/rm.html)에서 물건 목록을 뽑아 art/물건목록.md 로 적는다.

손으로 옮겨 적지 않는 이유는 규칙 3이다 — 같은 사실을 두 곳에 손으로 적으면
반드시 한쪽이 어긋난다. 장부를 고치고 이걸 돌리면 목록이 따라온다.

    python3 tools/itemlist.py
"""
import re, pathlib

HERE = pathlib.Path(__file__).resolve().parent.parent
LEDGER = HERE / "ledger" / "rm.html"
OUT = HERE / "art" / "물건목록.md"


def cells(row):
    return [re.sub(r"<.*?>", "", c).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", row)]


def main():
    html = LEDGER.read_text(encoding="utf-8")

    # 매장 20개: 번호 · 이름 · 파는 것 · 역할
    shops = []
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S):
        c = cells(row)
        if len(c) == 5 and c[0].isdigit() and c[1].endswith(("집", "간", "방")):
            shops.append(c[:4])
    if len(shops) != 20:
        raise SystemExit(f"매장이 20개가 아니다: {len(shops)}개")

    # 물건 표 5개: 머리글에서 매장 이름을, 줄에서 물건 넷을 읽는다
    items = {}
    for head, body in re.findall(r"<tr><th></th><th>레벨</th>(.*?)</tr>(.*?)</table>", html, re.S):
        names = [re.sub(r"<.*?>", "", h).strip() for h in re.findall(r"<th>(.*?)</th>", head)]
        cols = [[] for _ in names]
        for row in re.findall(r"<tr[^>]*>(.*?)</tr>", body, re.S):
            c = cells(row)
            if len(c) == 6 and c[0].isdigit():
                for i in range(4):
                    cols[i].append(c[2 + i])
        for name, col in zip(names, cols):
            if len(col) == 20:
                items[name] = col
    if len(items) != 20:
        raise SystemExit(f"물건이 채워진 매장이 20개가 아니다: {len(items)}개")

    all_names = [x for col in items.values() for x in col]
    dup = sorted({x for x in all_names if all_names.count(x) > 1})
    if dup:
        raise SystemExit(f"겹치는 물건 이름이 있다: {dup}")

    lines = [
        "# 1챕터 물건 400개",
        "",
        "**이 파일은 자동으로 뽑은 것이다. 손으로 고치지 마라** —",
        "고칠 곳은 장부(`ledger/rm.html`)이고, 고친 뒤 `python3 tools/itemlist.py`를 돌리면 여기가 따라온다.",
        "",
        "매장 하나가 1,000레벨이고 **50레벨마다 물건이 바뀐다.** 그래서 매장당 20개다.",
        "번호가 곧 진열 순서라 **파일 이름도 이 번호를 쓴다** (`art/README.md`).",
        "",
    ]
    for no, name, sells, role in shops:
        street = (int(no) - 1) // 4 + 1
        lines += [
            f"## {int(no):02d}-{name}",
            "",
            f"{street}스트리트 · {role} · {sells}",
            "",
            "```",
        ]
        lines += [f"{i:02d}-{x}" for i, x in enumerate(items[name], 1)]
        lines += ["```", ""]

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"{OUT.relative_to(HERE)} · 매장 {len(shops)} · 물건 {len(all_names)} · 겹침 0")


if __name__ == "__main__":
    main()
