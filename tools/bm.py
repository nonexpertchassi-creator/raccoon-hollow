#!/usr/bin/env python3
# 먹고살 수 있나 — 사람 몇 명이 있어야 하는지 거꾸로 푼다.
#
# 재는 도구지 게임 코드가 아니다(규칙 8).
# 밖에서 가져온 값(수수료·광고 단가·과금율)은 전부 가정이고
# 장부에 🟨로 적는다. 숫자를 믿지 말고 폭을 보라.
#
#   python3 tools/bm.py
#   python3 tools/bm.py --fee 0.30 --arppu 20000

import sys

def arg(name, d):
    return float(sys.argv[sys.argv.index(name)+1]) if name in sys.argv else d

# ── 나가는 돈 (연) ──────────────────────────────────
SALARY   = arg("--salary", 80_000_000)     # 내 연봉 (손에 쥐는 것)
INSUR    = 0.09                            # 4대보험 사업자 부담쯤
SERVER_M = arg("--server", 800_000)        # 월 서버·도구 값
ETC_M    = 300_000                         # 월 잡비(스토어 계정·그림 도구·법무)
INCOME_TAX = 0.30                          # 사업소득에 붙는 세금(지방세 포함)쯤
MARGIN   = 0.20                            # 남기고 싶은 마진

# ── 들어오는 돈 (가정) ──────────────────────────────
FEE      = arg("--fee", 0.15)              # 스토어 수수료 (첫 100만$까지 15%)
PAY_RATE = arg("--payrate", 0.02)          # 과금하는 사람 비율
ARPPU    = arg("--arppu", 18_000)          # 과금자 1인 월 결제액(원)
AD_DAU   = arg("--addau", 45)              # 광고로 버는 하루 1인당(원)
DAU_MAU  = arg("--dm", 0.22)               # 하루 접속 / 한 달 접속

def won(x): return f"{x:,.0f}원"

cost_year = SALARY*(1+INSUR) + (SERVER_M+ETC_M)*12
need_pre  = cost_year / (1 - MARGIN)            # 세전에 필요한 이익
need_rev  = need_pre / (1 - INCOME_TAX)         # 세금 내고 남으려면
gross     = need_rev / (1 - FEE)                # 스토어 수수료 떼기 전 매출

print("── 나가는 돈 (한 해) ──")
print(f"  내 인건비(보험 포함) {won(SALARY*(1+INSUR))}")
print(f"  서버·도구·잡비        {won((SERVER_M+ETC_M)*12)}")
print(f"  합                    {won(cost_year)}")
print(f"\n  마진 {MARGIN:.0%} 남기려면 세전 이익 {won(need_pre)}")
print(f"  세금 {INCOME_TAX:.0%} 내고 그게 남으려면 {won(need_rev)}")
print(f"  스토어 수수료 {FEE:.0%} 떼기 전 매출 {won(gross)}")
print(f"  → 한 달 매출 {won(gross/12)}")

m = gross/12
print("\n── 사람이 몇 명 있어야 하나 ──")
for name, ad_share in (("광고 없이 결제만", 0.0), ("반반", 0.5), ("광고가 7할", 0.7)):
    from_ad  = m * ad_share
    from_iap = m - from_ad
    mau_iap  = from_iap / (PAY_RATE * ARPPU)
    dau_ad   = from_ad / (AD_DAU * 30) if from_ad else 0
    mau_ad   = dau_ad / DAU_MAU if dau_ad else 0
    mau = max(mau_iap, mau_ad)
    print(f"  {name:14} 결제 {won(from_iap):>14} 광고 {won(from_ad):>14}"
          f"  → 한 달 쓰는 사람 {max(mau_iap, mau_ad):>9,.0f}명"
          f" (하루 {mau*DAU_MAU:>7,.0f}명)")

print("\n── 광고 제거를 몇 %나 사나 (밖의 수치로 폭만) ──")
# 밖에서 찾은 것: 모바일 게임 전체 과금율 0.8%(Adjust).
# "광고 제거만" 따로 낸 공개 수치는 못 찾았다 — 그래서 폭으로만 본다.
PAY_ALL = 0.008                       # 무엇이든 한 번이라도 결제하는 비율
for share in (0.3, 0.5, 0.7):         # 그중 광고 제거가 차지하는 몫
    r = PAY_ALL * share
    print(f"  첫 결제의 {share*100:.0f}%가 광고 제거라면 → 전체의 {r*100:.2f}%가 산다"
          f"  (1,000명에 {r*1000:.0f}명)")

print("\n── 보석을 얼마에 파나 (묶음 초안) ──")
for gem, price in ((60, 1_500), (300, 6_900), (980, 19_000), (2_000, 39_000), (5_500, 99_000)):
    print(f"  💎{gem:>5} = {won(price):>10}   보석 1개당 {price/gem:6.1f}원")

print("\n── 광고 제거를 얼마에 파나 ──")
# 광고 자리는 17개인데 다 보는 사람은 없다 — 몇 %나 보는지가 진짜 손잡이다.
SLOTS   = 3 + 3 + 5 + 4 + 2   # 주사위3 · 보석3 · 뽑기5 · 팝업4 · 패스와 미션2
ECPM    = 9_000               # 보상형 광고 1,000번에 (원) — 한국 높은 편
per_view= ECPM/1000
print(f"  광고 자리 하루 {SLOTS}개 · 보상형 1회 {per_view:.0f}원")
# 아이들 게임 광고 참여율은 42%라는 밖의 수치가 있다(캐주얼 평균은 25~30%).
# 내가 쓰던 60%는 그보다 훨씬 높았다.
for take in (0.30, 0.42, 0.60):
    seen = SLOTS*take
    print(f"\n  자리의 {take*100:.0f}%를 보면 하루 {seen:.1f}개 · {won(seen*per_view)}")
    for days in (30, 60, 120, 365):
        print(f"    {days:3}일 붙어 있는 사람이 보는 광고값 ≈ {won(seen*days*per_view)}")
