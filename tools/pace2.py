#!/usr/bin/env python3
# 제조시간을 넣은 판. 여기가 지금의 진짜 모형이다.
#   실제 수입 = min(손님이 오는 속도, 만들어 내는 속도)
#
#   python3 tools/pace2.py                 지금 값으로
#   python3 tools/pace2.py --solve 7       과녁을 주면 비용 증가율을 찾는다
#   python3 tools/pace2.py --feel          며칠째에 무슨 일이

import random, statistics, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from balnum import N

def a(k, d): return float(sys.argv[sys.argv.index(k)+1]) if k in sys.argv else d
M = N["돈"]
# 숫자는 balnum.py 한곳에서 온다 (규칙 2·3)
_C = N["제조"]
P0    = a("--p0",   M["물건_밑값"])
INC   = a("--inc",  M["레벨당_수입증가"])
STAR  = a("--star", M["별마다_배수"])
JUMP  = a("--jump", M["물건바뀔때_배수"])
C0    = a("--c0",   M["레벨_밑값"])
G     = a("--g",    M["레벨당_비용증가"])
TS    = a("--ts",   M["손님_간격_초"])
SHOP_K, SHOP_M, ZONE_M = M["매장값_배수"], a("--shopm", M["매장1_값배수"]), M["구역값_배수"]
OFF_W = N["오프라인"]["기본_몫"]
FLOOR, PER = _C["바닥"], _C["레벨마다"]

BAND = [tuple(x) for x in _C["계단"]]
def band(i):
    for lo, hi, t in BAND:
        if lo <= i <= hi: return t
def proc(i):
    for lo, hi, p in _C["공정_수"]:
        if lo <= i <= hi: return p
def item_of(L): return min(20, (L-1)//50 + 1)

def craft(L):                      # 한 개 만드는 데 걸리는 시간
    return band(item_of(L)) * max(FLOOR, PER ** ((L-1) % 50))

def price(L):                      # 물건 한 개 값
    return P0 * INC**(L-1) * STAR**((L-1)//10) * JUMP**((L-1)//50)

def rate_one(L, workers, ts):
    """매장 하나의 초당 수입 = min(손님, 제조) × 값"""
    if L <= 0: return 0.0
    make = min(workers, proc(item_of(L))) / craft(L)   # 초당 만들 수 있는 개수
    come = 1.0 / ts                                     # 초당 오는 손님
    return min(make, come) * price(L)

def shop_price(j): return C0 * SHOP_M * (SHOP_K ** j)
def zone_price(z): return shop_price(z*4) * ZONE_M
def lvl_cost(L):   return C0 * (G ** (L-1))
def chunk(L):
    to = min(1000, (L//10)*10 + 10)
    return to, sum(lvl_cost(x) for x in range(L+1, to+1))

def run(seed, paid, log=None):
    rng = random.Random(seed)
    L = [0]*20; W = [1]*20; zones = 1; money = shop_price(0)
    member  = 2.0 if paid else 1.0
    ts = TS / (1 + (0.30 if paid else 0.0))      # 등장률 스킬(더하기)
    def rate(): return sum(rate_one(L[i], W[i], ts) for i in range(20)) * member
    def buy():
        nonlocal money, zones
        while True:
            if zones < 5 and all(x > 0 for x in L[:zones*4]) and zone_price(zones) <= money:
                money -= zone_price(zones); zones += 1
                if log is not None: log.append(f"{zones}구역이 열렸다")
                continue
            best = None; seen_empty = False
            for i in range(20):
                if L[i] == 0 and seen_empty: continue
                if 0 < L[i] < 1000:
                    to, c = chunk(L[i])
                    if c <= money:
                        d = rate_one(to, W[i], ts) - rate_one(L[i], W[i], ts)
                        if d <= 0:
                            # 물건이 바뀌는 계단 바로 앞에서는 한 별이 잠깐 손해일 수 있다.
                            # 두 별 뒤까지 보고 그래도 이득이면 산다(사람도 그렇게 한다).
                            far = min(1000, to + 10)
                            d = (rate_one(far, W[i], ts) - rate_one(L[i], W[i], ts)) * 0.5
                        if d > 0 and (best is None or c/d < best[0]): best = (c/d, "lv", i, to, c)
                    # 일꾼 한 마리 더
                    if W[i] < 4:
                        c2 = shop_price(i) * (2 ** W[i]) * 0.5
                        if c2 <= money:
                            d = rate_one(L[i], W[i]+1, ts) - rate_one(L[i], W[i], ts)
                            if d <= 0:
                                # 지금은 안 늘어도 다음 물건에서 뚫어 줄 수 있다.
                                # 별을 올렸을 때의 값으로 다시 본다.
                                nxt = min(1000, (L[i]//10)*10 + 10)
                                d = rate_one(nxt, W[i]+1, ts) - rate_one(nxt, W[i], ts)
                            if d > 0 and (best is None or c2/d < best[0]): best = (c2/d, "w", i, 0, c2)
                elif L[i] == 0 and i < zones*4:
                    # 아직 안 산 매장 중 제일 앞의 것만 후보로 본다.
                    # (예전에는 여기서 break 해서 뒤 매장의 레벨·일꾼 후보를 통째로 놓쳤다)
                    c = shop_price(i)
                    if c <= money:
                        d = rate_one(1, 1, ts)
                        if best is None or c/d < best[0]: best = (c/d, "lv", i, 1, c)
                    seen_empty = True
            if best is None: return
            _, kind, i, to, c = best
            money -= c
            if kind == "w": W[i] += 1
            else: L[i] = to
    last, sess = 0.0, [(7.5,10),(12.5,5),(22.5,10)]
    for day in range(120):
        cap = 12 if paid else (2 if day < 2 else 6 if day < 4 else 12)
        dice = [rng.randint(1,6) for _ in range(6 if paid else 4)]
        first = True
        for at, mins in sess:
            now = day*24 + at
            g = rate() * min(now-last, cap) * 3600 * OFF_W
            if first: g *= 1 + sum(dice); first = False
            m = mins * (0.7 + 0.6*rng.random())
            for _ in range(int(m)): g += rate()*60
            last = now + m/60
            money += g; buy()
            if all(x >= 1000 for x in L): return day + at/24
    return None

def feel(seed=1000, paid=False):
    """며칠째에 무슨 일이 — 숫자 말고 느낌으로."""
    out=[]; run(seed, paid, out); return out

if __name__ == "__main__":
    if "--feel" in sys.argv:
        for paid in (False, True):
            print(f"\n══ {'돈 쓴 사람' if paid else '무과금'} ══")
            for w in feel(1000, paid)[:14]: print("   " + w)
        sys.exit(0)
    if "--solve" in sys.argv:
        tgt = float(sys.argv[sys.argv.index("--solve")+1]); lo, hi = 1.020, 1.060
        for _ in range(38):
            G = (lo+hi)/2
            med = statistics.median([run(1000+s, False) or 999 for s in range(5)])
            if med < tgt: lo = G
            else: hi = G
        G = (lo+hi)/2
        f = statistics.median([run(1000+s, False) or 999 for s in range(11)])
        p = statistics.median([run(1000+s, True) or 999 for s in range(11)])
        print(f"과녁 {tgt}일 → 비용 증가율 G = {G:.4f}   무과금 {f:.1f}일 · 유료 {p:.1f}일")
        sys.exit(0)
    for paid in (False, True):
        outs = [run(1000+s, paid) or 999 for s in range(11)]
        print(f"{'유료 ' if paid else '무과금'}: 가운뎃값 {statistics.median(outs):.1f}일  "
              f"({', '.join(f'{o:.1f}' for o in sorted(outs))})")
