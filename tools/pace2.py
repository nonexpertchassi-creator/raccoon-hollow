#!/usr/bin/env python3
# 제조시간을 넣은 판. 여기가 지금의 진짜 모형이다.
#   실제 수입 = min(손님이 오는 속도, 만들어 내는 속도)
#
#   python3 tools/pace2.py                 지금 값으로
#   python3 tools/pace2.py --solve 7       과녁을 주면 비용 증가율을 찾는다
#   python3 tools/pace2.py --feel          며칠째에 무슨 일이
#   python3 tools/pace2.py --mins 50       하루 접속 분을 바꿔서 (기본 25분)
#
# "며칠"은 기준이 안 된다 — 하루에 몇 분 하는지에 매달려 있기 때문이다.
# 그래서 흐른 날과 함께 <b>접속 시간</b>도 같이 낸다.

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
WMAX  = int(N["제조"]["일꾼_최대"])   # 전에는 4로 박아 뒀는데 첫 판은 6이었다(규칙 2)
MINS  = a("--mins", 25.0)          # 하루에 손에 잡고 있는 분
SESS  = int(a("--sess", 3))        # 하루에 몇 번 들어오나. 오프라인을 몇 번 걷어 가느냐가 진짜 레버다
CAP   = a("--cap", 0)              # 오프라인 최대 시간을 못 박는다. 0이면 예전처럼 날짜로 늘어난다
# 앞 챕터에서 들고 오는 힘. 첫 챕터는 둘 다 1이다.
# 매일 받기 — 하루에 "그때 수입 N분어치"를 더 준다.
# 밑값은 장부의 다섯 칸을 다 받은 값이다. 이건 이제 게임에 붙박이라
# 0으로 두면 우리가 안 만드는 게임을 재게 된다(그러면 챕터가 8.3일로 나온다).
DAILY = a("--daily", float(sum(N["매일받기"]["칸_분어치"])))
ONMUL = a("--onmul", 1.0)          # 손에 잡고 있을 때만 걸리는 배수 (멤버십)
BOOST = a("--boost", 1.0)          # 물건 값에 곱해지는 것 — 손님 능력 배수
FASTER= a("--faster", 1.0)         # 빨라지는 것 — 손님도 제조도 같이 (상한 2.1배)
CHAP  = int(a("--ch", 1))          # 몇 번째 챕터인가. 챕터마다 레벨 밑값이 오르고,
                                   # 안 주면 그 챕터에서 들고 있을 힘도 자동으로 잡아 준다
if "--ch" in sys.argv and CHAP > 1:
    _f = min(1.0, (CHAP - 1) / 19.0)          # 20챕터쯤 되면 힘이 다 찬다고 본다
    if "--faster" not in sys.argv: FASTER = 1 + 1.1 * _f   # 손님 빨라지는 합 상한 +110%
    if "--boost"  not in sys.argv: BOOST  = 1 + 2.0 * _f   # 손님 능력 ×1 → ×3
    C0 = C0 * M["챕터당_밑값배수"] ** (CHAP - 1)
OFF_W = a("--off", N["오프라인"]["기본_몫"])   # 오프라인 몫. 광고 없애기를 사면 두 배가 된다
OFF_0, OFF_MAX = N["오프라인"]["처음_시간"], N["오프라인"]["최대_시간"]
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

# 매장 번호 j가 뒤로 갈수록 밑값이 오른다. 이게 없으면 20번째 매장을
# 열자마자 620레벨로 뛴다 — 1,000레벨 중 62%를 안 하고 건너뛴다.
SHOPBASE = M["매장당_밑값배수"]
def price(L, j=0):                 # 물건 한 개 값
    return P0 * (SHOPBASE**j) * INC**(L-1) * STAR**((L-1)//10) * JUMP**((L-1)//50)

def rate_one(L, workers, ts, j=0):
    """매장 하나의 초당 수입 = min(손님, 제조) × 값"""
    if L <= 0: return 0.0
    make = min(workers, proc(item_of(L))) / (craft(L) / FASTER)  # 초당 만들 수 있는 개수
    come = FASTER / ts                                           # 초당 오는 손님
    return min(make, come) * price(L, j) * BOOST

def shop_price(j): return C0 * SHOP_M * (SHOP_K ** j)
def zone_price(z): return shop_price(z*4) * ZONE_M
def lvl_cost(L, j=0): return C0 * (SHOPBASE**j) * (G ** (L-1))
def chunk(L, j=0):
    # 한 번에 오르는 끝은 "물건이 바뀌는 자리"다(별 5개 = 50레벨).
    # 넘게 두면 물건이 여러 번 바뀌어 못 보고 지나가는 것이 생긴다.
    to = min(1000, (L//50)*50 + 50)
    return to, sum(lvl_cost(x, j) for x in range(L+1, to+1))

def run(seed, paid, log=None):
    rng = random.Random(seed)
    L = [0]*20; W = [1]*20; zones = 1; money = shop_price(0)
    member  = 2.0 if paid else 1.0
    ts = TS / (1 + (0.30 if paid else 0.0))      # 등장률 스킬(더하기)
    def rate(): return sum(rate_one(L[i], W[i], ts, i) for i in range(20)) * member
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
                    to, c = chunk(L[i], i)
                    if c <= money:
                        d = rate_one(to, W[i], ts, i) - rate_one(L[i], W[i], ts, i)
                        if d <= 0:
                            # 물건이 바뀌는 계단 바로 앞에서는 한 별이 잠깐 손해일 수 있다.
                            # 두 별 뒤까지 보고 그래도 이득이면 산다(사람도 그렇게 한다).
                            far = min(1000, to + 10)
                            d = (rate_one(far, W[i], ts, i) - rate_one(L[i], W[i], ts, i)) * 0.5
                        if d > 0 and (best is None or c/d < best[0]): best = (c/d, "lv", i, to, c)
                    # 일꾼 한 마리 더
                    if W[i] < WMAX:
                        # 장부: "매장 값의 반에서 시작, 마리마다 두 배".
                        # W가 1부터라 첫 채용은 2**0 이어야 한다. 전에는 한 번 더 곱해
                        # 첫 일꾼을 두 배로 받고 있었다.
                        c2 = shop_price(i) * 0.5 * (2 ** (W[i] - 1))
                        if c2 <= money:
                            d = rate_one(L[i], W[i]+1, ts, i) - rate_one(L[i], W[i], ts, i)
                            if d <= 0:
                                # 지금은 안 늘어도 다음 물건에서 뚫어 줄 수 있다.
                                # 별을 올렸을 때의 값으로 다시 본다.
                                nxt = min(1000, (L[i]//10)*10 + 10)
                                d = rate_one(nxt, W[i]+1, ts, i) - rate_one(nxt, W[i], ts, i)
                            if d > 0 and (best is None or c2/d < best[0]): best = (c2/d, "w", i, 0, c2)
                elif L[i] == 0 and i < zones*4:
                    # 아직 안 산 매장 중 제일 앞의 것만 후보로 본다.
                    # (예전에는 여기서 break 해서 뒤 매장의 레벨·일꾼 후보를 통째로 놓쳤다)
                    c = shop_price(i)
                    if c <= money:
                        d = rate_one(1, 1, ts, i)
                        if best is None or c/d < best[0]: best = (c/d, "lv", i, 1, c)
                    seen_empty = True
            if best is None: return
            _, kind, i, to, c = best
            money -= c
            if kind == "w": W[i] += 1
            else: L[i] = to
    if SESS == 3:                         # 기본은 아침·점심·밤
        k = MINS / 25.0
        sess = [(7.5, 10*k), (12.5, 5*k), (22.5, 10*k)]
    else:                                 # 그 밖에는 고르게 벌린다
        sess = [(7.5 + 24.0*i/SESS, MINS/SESS) for i in range(SESS)]
    last = 0.0
    online = 0.0                          # 실제로 손에 잡고 있던 분
    for day in range(120):
        # 오프라인 상한은 스킬로만 열린다(유저가 정했다) — 날짜로 저절로 안 열린다.
        # 무과금은 안 산 채로 시작하고, 돈 쓴 사람은 일찍 산 것으로 친다.
        cap = CAP if CAP else (OFF_MAX if paid else OFF_0)
        dice = [rng.randint(1,6) for _ in range(6 if paid else 4)]
        first = True
        for at, mins in sess:
            now = day*24 + at
            g = rate() * min(now-last, cap) * 3600 * OFF_W
            if first and DAILY: g += rate() * DAILY * 60   # 매일 받기는 그날 첫 접속에
            if first: g *= 1 + sum(dice); first = False
            m = mins * (0.7 + 0.6*rng.random())
            for _ in range(int(m)): g += rate()*60*ONMUL
            online += m
            last = now + m/60
            money += g; buy()
            if all(x >= 1000 for x in L): return day + at/24, online
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
            med = statistics.median([(run(1000+s, False) or (999, 0))[0] for s in range(5)])
            if med < tgt: lo = G
            else: hi = G
        G = (lo+hi)/2
        f = statistics.median([(run(1000+s, False) or (999, 0))[0] for s in range(11)])
        p = statistics.median([(run(1000+s, True) or (999, 0))[0] for s in range(11)])
        print(f"과녁 {tgt}일 → 비용 증가율 G = {G:.4f}   무과금 {f:.1f}일 · 유료 {p:.1f}일")
        sys.exit(0)
    print(f"하루 {SESS}번 들어와 모두 {MINS:.0f}분 기준 (--mins · --sess 로 바꾼다)")
    for paid in (False, True):
        got = [run(1000+s, paid) or (999, 0) for s in range(11)]
        d = statistics.median([g[0] for g in got])
        h = statistics.median([g[1] for g in got]) / 60
        print(f"{'유료 ' if paid else '무과금'}: 흐른 날 가운뎃값 {d:.1f}일 · "
              f"손에 잡고 있던 시간 {h:.1f}시간  "
              f"({', '.join(f'{g[0]:.1f}' for g in sorted(got))})")
