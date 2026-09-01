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

# ── 곡선 (초안 — 장부 밸런스 갈래와 같이 움직인다) ──────────────
P0   = 4.0     # 1번 물건 한 개 값
INC  = 1.025   # 레벨마다 수입 +2.5%
JUMP = 2.0     # 물건이 바뀌면(50레벨마다) 수입 ×2 — 규칙 5의 "눈에 띄게"
C0   = 20.0    # 1레벨 올리는 값
G    = 1.04    # 레벨마다 비용 +4% (50레벨에 ×7.1 ≈ 수입 ×6.9와 짝)
TS   = 10.0    # 손님 한 명 오는 간격(초, 매장마다)
SHOP_K = 4.0   # 다음 매장 값은 몇 배씩
SHOP_M = 25.0  # 매장 1 값 = C0 × 25
ZONE_M = 3.0   # 구역 값 = 그 구역 첫 매장 값 × 3
OFF_W  = 0.5   # 오프라인 기본 몫 (옛 공식 그대로)

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

if __name__ == "__main__":
    if "--c0" in sys.argv: C0 = float(sys.argv[sys.argv.index("--c0")+1])
    for paid in (False, True):
        runs = [run(1000+s, paid) for s in range(11)]
        outs = [r.get("done", 99) for r in runs]
        med = statistics.median(outs)
        z = runs[len(runs)//2].get("zday", [])
        print(f"{'유료 ' if paid else '무과금'}: 가운뎃값 {med:.1f}일  "
              f"(판마다: {', '.join(f'{o:.1f}' for o in sorted(outs))})")
        print(f"        구역 2~5가 열리는 날: {z}")
