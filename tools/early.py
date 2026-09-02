#!/usr/bin/env python3
# 초반 30분만 분 단위로 본다. "30분에 두 매장"이 되는지가 과녁이다.
#   python3 tools/early.py                지금 값으로
#   python3 tools/early.py --shop 300 --c0 5 --p0 1 --ts 6

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from balnum import N

def a(k, d): return float(sys.argv[sys.argv.index(k)+1]) if k in sys.argv else d
M = N["돈"]
P0   = a("--p0",   M["물건_밑값"])
INC  = a("--inc",  M["레벨당_수입증가"])
JUMP = a("--jump", M["물건바뀔때_배수"])
C0   = a("--c0",   M["레벨_밑값"])
G    = a("--g",    M["레벨당_비용증가"])
TS   = a("--ts",   M["손님_간격_초"])
SHOP = a("--shop", M["레벨_밑값"] * M["매장1_값배수"] * M["매장값_배수"])

def inc(L):  return 0.0 if L <= 0 else P0 * INC**(L-1) * JUMP**((L-1)//50) / TS
def cost(L): return C0 * G**(L-1)

def play(minutes=30, verbose=True):
    """1분마다 벌고, 별 하나 채우기를 살 수 있으면 사고, 둘째 매장이 살 만하면 산다."""
    L, shops, money = 1, 1, 0.0
    marks = []
    for t in range(1, minutes+1):
        money += inc(L)*60 * shops          # 매장이 둘이면 대충 두 배로 본다
        # 둘째 매장을 먼저 노린다 (유저: 마스터 안 해도 열려야 한다)
        if shops == 1 and money >= SHOP:
            money -= SHOP; shops = 2
            marks.append((t, f"둘째 매장을 열었다 (값 {SHOP:,.0f}원)"))
        # 별 하나 채우기
        while True:
            to = min(1000, (L//10)*10 + 10)
            need = sum(cost(x) for x in range(L+1, to+1))
            if need <= money and to > L:
                money -= need
                before = L; L = to
                if to % 50 == 0:
                    marks.append((t, f"물건이 바뀌었다 ({to}레벨)"))
                elif to in (10, 20, 50):
                    marks.append((t, f"별 {to//10}개 ({to}레벨)"))
            else:
                break
    return L, shops, money, marks

L, shops, money, marks = play()
print(f"── 30분 놀면 ── 매장 {shops}채 · 레벨 {L} · 남은 돈 {money:,.0f}원")
for t, w in marks[:12]:
    print(f"   {t:2}분  {w}")
if shops == 1:
    print(f"   ✗ 둘째 매장({SHOP:,.0f}원)을 30분 안에 못 연다")
