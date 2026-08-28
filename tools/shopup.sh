#!/bin/sh
# 가게 강화가 정말 이득인지 잰다 — **운 번호 여러 개로.**
#
# ★ 왜 이 도구가 따로 있나.
#   운 번호 하나로 재면 판마다의 운(±46%)이 재려는 효과(±30%)보다 커서
#   손해인 강화가 이득으로 보인다. 실제로 한 번 속았다(PLAN.md 2026-08-21).
#   그래서 이 도구는 **운 번호를 여러 개 돌려 가운뎃값**을 내놓는다.
#
# 쓰기:
#   tools/shopup.sh              # 운 번호 1~5, 8시간
#   SEEDS="1 2 3" HOURS=4 tools/shopup.sh
set -e
cd "$(dirname "$0")/.."
SEEDS="${SEEDS:-1 2 3 4 5}"
HOURS="${HOURS:-8}"
JOBS="${JOBS:-3}"
OUT="$(mktemp)"

# 한 판 = 운 번호 하나 × 설정 하나. 여럿을 동시에 돌린다(느려서).
RUN='
  s=$0; a=$1
  if [ "$a" = off ]; then e="BAL_SHOPUP=0"; else e="BAL_ONLY=$a"; fi
  line=$(env $e BAL_TERSE=1 BAL_HOURS=$HOURS BAL_SEED=$s \
    godot --headless --path godot --script tests/balance.gd 2>/dev/null \
    | grep -E "^(끔|smith|brush|paper|pot|herb) " | head -1)
  echo "$s|$a|$line"
'
export HOURS

for s in $SEEDS; do
  for a in off smith brush paper pot herb; do echo "$s $a"; done
done | xargs -P "$JOBS" -n 2 sh -c "$RUN" > "$OUT"

python3 - "$OUT" "$HOURS" <<'PY'
import re, sys, statistics
F, H = sys.argv[1], int(sys.argv[2])
U = {'K':1e3,'M':1e6,'B':1e9,'T':1e12,'Q':1e15}
def num(x):
    m = re.match(r'^([\d.]+)([KMBTQ]?)$', x)
    return float(m.group(1)) * U.get(m.group(2), 1)

def fmt(v):
    for u in ('Q','T','B','M','K'):
        if v >= U[u]: return "%.2f%s" % (v/U[u], u)
    return "%.0f" % v

data = {}
for ln in open(F, encoding='utf-8'):
    if '|' not in ln: continue
    s, a, rest = ln.strip().split('|', 2)
    v = [num(x) for x in rest.split()[1:]]
    if v: data[(int(s), a)] = v
seeds = sorted({k[0] for k in data})
names = {'smith':'풀무','brush':'먹 갈기','paper':'의뢰방',
         'pot':'질그릇 한 벌','herb':'약재 말리기'}

print("운 번호별 %d시간 누적매출" % H)
print("            " + "".join("운%-8d" % s for s in seeds))
for a in ['off'] + list(names):
    row = "%-12s" % names.get(a, '끔')
    for s in seeds:
        v = data.get((s, a))
        row += "%-10s" % (fmt(v[-1]) if v else "-")
    print(row)

print()
print("안 산 판 대비 배수 — 시간별 가운뎃값 (1.00보다 커야 살 만한 것)")
print("            " + " ".join("%2d시" % (i+1) for i in range(H)) + "   이김")
bad = []
for a in names:
    rs, wins = [], 0
    for s in seeds:
        o, v = data.get((s,'off')), data.get((s,a))
        if not o or not v: continue
        rs.append([v[i]/o[i] for i in range(len(v))])
        if v[-1] > o[-1]: wins += 1
    if not rs: continue
    med = [statistics.median(r[i] for r in rs) for i in range(len(rs[0]))]
    mark = "" if med[-1] >= 1.0 and wins > len(rs)/2 else "   ← 손보라"
    if mark: bad.append(names[a])
    print("%-12s" % names[a] + " ".join("%.2f" % x for x in med)
          + "   %d/%d%s" % (wins, len(rs), mark))
print()
print("손봐야 하는 것: " + (", ".join(bad) if bad else "없다 — 다섯 다 살 만하다"))
PY
rm -f "$OUT"
