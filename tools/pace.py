#!/usr/bin/env python3
# 챕터 하나가 며칠짜리인지 재는 도구 (규칙 1 — 운 번호 여러 개, 가운뎃값)
#
# 게임 코드가 아니라 재는 도구다(규칙 8). 하루 일과를 흉내 낸다:
# 아침·점심·밤 세 번 들어와 오프라인 보상을 받고(아침에 주사위를 다 굴린다),
# 돈이 되는 대로 "별 하나 채우기"로 레벨을 올린다.
#
#   python3 tools/pace.py            무과금 · 유료 각각 11판
#   python3 tools/pace.py --c0 24    비용 밑값을 바꿔서 다시

import random, statistics, sys

# ── 곡선은 tools/numbers.py 한곳에서 온다 (규칙 2·3) ──────────
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from balnum import N          # noqa: E402

_M, _P = N["돈"], N["진행"]
P0, INC, JUMP = _M["물건_밑값"], _M["레벨당_수입증가"], _M["물건바뀔때_배수"]
C0, G         = _M["레벨_밑값"], _M["레벨당_비용증가"]
TS            = _M["손님_간격_초"]
SHOP_K, SHOP_M, ZONE_M = _M["매장값_배수"], _M["매장1_값배수"], _M["구역값_배수"]
OFF_W         = N["오프라인"]["기본_몫"]

def income(L):                     # 레벨 L 매장의 초당 수입
    if L <= 0: return 0.0
    return P0 * (INC ** (L - 1)) * (JUMP ** ((L - 1) // 50)) / TS

def lvl_cost(L):
    return C0 * (G ** (L - 1))

def chunk(L):                      # 별 하나 채우기: 다음 10의 배수까지
    to = min(1000, (L // 10) * 10 + 10)
    return to, sum(lvl_cost(x) for x in range(L + 1, to + 1))

def shop_price(j):                 # j = 0..19
    return C0 * SHOP_M * (SHOP_K ** j)

def zone_price(z):                 # z = 1..4 (구역 2~5)
    return shop_price(z * 4) * ZONE_M

def run(seed, paid):
    rng = random.Random(seed)
    st = {"L": [0]*20, "zones": 1, "money": shop_price(0)}
    member  = 2.0  if paid else 1.0
    ts_mult = 0.85 if paid else 1.0
    off_mult = 1.3 if paid else 1.0
    def rate():
        return sum(income(x) for x in st["L"]) * member / ts_mult
    def buy_all():
        while True:
            L = st["L"]
            if st["zones"] < 5 and all(x > 0 for x in L[:st["zones"]*4]) \
               and zone_price(st["zones"]) <= st["money"]:
                st["money"] -= zone_price(st["zones"]); st["zones"] += 1
                st.setdefault("zday", []).append(round(st.get("now", 0), 1)); continue
            best = None
            for i in range(20):
                if 0 < L[i] < 1000:
                    to, c = chunk(L[i])
                    if c <= st["money"]:
                        d = (income(to) - income(L[i])) * member / ts_mult
                        if d > 0 and (best is None or c/d < best[0]):
                            best = (c/d, i, to, c)
                elif L[i] == 0 and i < st["zones"]*4:
                    c = shop_price(i)
                    if c <= st["money"]:
                        d = income(1) * member / ts_mult
                        if best is None or c/d < best[0]:
                            best = (c/d, i, 1, c)
                    break
            if best is None: return
            _, i, to, c = best
            st["money"] -= c; st["L"][i] = to
    sessions = [(7.5, 10), (12.5, 5), (22.5, 10)]
    last_end = 0.0
    for day in range(60):
        cap = 12 if paid else (2 if day < 2 else 6 if day < 4 else 12)
        dice = [rng.randint(1, 6) for _ in range(6 if paid else 4)]
        first = True
        for at, minutes in sessions:
            now = day*24 + at
            st["now"] = now / 24
            gain = rate() * min(now - last_end, cap) * 3600 * OFF_W * off_mult
            if first:
                gain *= 1 + sum(dice); first = False
            m = minutes * (0.7 + 0.6*rng.random())
            for _ in range(int(m)):
                gain += rate() * 60
            last_end = now + m/60
            st["money"] += gain
            buy_all()
            if all(x >= 1000 for x in st["L"]):
                st["done"] = day + at/24
                return st
    return st

def feel(seed=1000, paid=False):
    """숫자 말고 느낌으로 — 며칠째에 무슨 일이 일어나나."""
    rng = random.Random(seed)
    st = {"L": [0]*20, "zones": 1, "money": shop_price(0)}
    member  = 2.0  if paid else 1.0
    ts_mult = 0.85 if paid else 1.0
    off_mult = 1.3 if paid else 1.0
    log = []
    seen_shop, seen_zone, seen_item = 0, 1, 0
    def rate(): return sum(income(x) for x in st["L"]) * member / ts_mult
    def buy_all(when):
        nonlocal seen_shop, seen_zone, seen_item
        while True:
            L = st["L"]
            if st["zones"] < 5 and all(x > 0 for x in L[:st["zones"]*4]) \
               and zone_price(st["zones"]) <= st["money"]:
                st["money"] -= zone_price(st["zones"]); st["zones"] += 1
                log.append((when, f"{st['zones']}구역이 열렸다 — 새 매장 4채")); continue
            best = None
            for i in range(20):
                if 0 < L[i] < 1000:
                    to, c = chunk(L[i])
                    if c <= st["money"]:
                        d = (income(to) - income(L[i])) * member / ts_mult
                        if d > 0 and (best is None or c/d < best[0]): best = (c/d, i, to, c)
                elif L[i] == 0 and i < st["zones"]*4:
                    c = shop_price(i)
                    if c <= st["money"]:
                        d = income(1) * member / ts_mult
                        if best is None or c/d < best[0]: best = (c/d, i, 1, c)
                    break
            if best is None: return
            _, i, to, c = best
            before = st["L"][i]
            st["money"] -= c; st["L"][i] = to
            if before == 0:
                seen_shop += 1
                if seen_shop in (2, 5, 10, 20):
                    log.append((when, f"매장 {seen_shop}채째를 샀다"))
            items = sum(x // 50 for x in st["L"])
            if items > seen_item:
                seen_item = items
                if items in (1, 5, 20, 100, 200, 400):
                    log.append((when, f"물건이 {items}번째로 바뀌었다 (도감 {items}칸)"))
            if any(x >= 1000 for x in st["L"]) and not any(t[1].startswith("첫 매장을 다") for t in log):
                log.append((when, "첫 매장을 다 채웠다 — 덮는 창이 뜬다"))
    sessions = [(7.5, 10), (12.5, 5), (22.5, 10)]
    last_end = 0.0
    for day in range(60):
        cap = 12 if paid else (2 if day < 2 else 6 if day < 4 else 12)
        dice = [rng.randint(1, 6) for _ in range(6 if paid else 4)]
        first = True
        for at, minutes in sessions:
            now = day*24 + at
            gain = rate() * min(now - last_end, cap) * 3600 * OFF_W * off_mult
            if first: gain *= 1 + sum(dice); first = False
            m = minutes * (0.7 + 0.6*rng.random())
            for _ in range(int(m)): gain += rate() * 60
            last_end = now + m/60
            st["money"] += gain
            buy_all(day + at/24)
            if all(x >= 1000 for x in st["L"]):
                log.append((day + at/24, "20매장을 다 채웠다 — 챕터 끝, 세계지도가 열린다"))
                return log
    return log

if __name__ == "__main__":
    if "--c0" in sys.argv: C0 = float(sys.argv[sys.argv.index("--c0")+1])
    if "--feel" in sys.argv:
        for paid in (False, True):
            print(f"\n══ {'돈을 쓴 사람' if paid else '무과금'} — 며칠째에 무슨 일이 ══")
            last = None
            for when, what in feel(1000, paid):
                d = int(when); hh = "아침" if when%1 < 0.4 else ("점심" if when%1 < 0.6 else "밤")
                tag = f"{d+1}일째 {hh}"
                print(f"  {tag if tag != last else ' ' * len(tag)}   {what}")
                last = tag
        sys.exit(0)
    for paid in (False, True):
        runs = [run(1000+s, paid) for s in range(11)]
        outs = [r.get("done", 99) for r in runs]
        med = statistics.median(outs)
        z = runs[len(runs)//2].get("zday", [])
        print(f"{'유료 ' if paid else '무과금'}: 가운뎃값 {med:.1f}일  "
              f"(판마다: {', '.join(f'{o:.1f}' for o in sorted(outs))})")
        print(f"        구역 2~5가 열리는 날: {z}")
