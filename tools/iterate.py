#!/usr/bin/env python3
"""iterate.py — 관문 값을 기준판 페이스에 수렴시킨다.
사용: python3 iterate.py <최신 실행.json>
  1) 기준판과 최신 실행을 비교해 각 관문의 어긋남을 보고
  2) 새 값 = sqrt(지금 값 × 제안값) (진동 방지 감쇠)로 content.js를 고쳐 쓴다
"""
import json, re, sys, math

BASE = json.load(open('baseline.json'))
CUR = json.load(open(sys.argv[1]))
P = __import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'content.js')
src = open(P).read()

def at(curve, minute, key):
    last = curve[0]
    for p in curve:
        if p['min'] > minute: break
        last = p
    return last[key]

def pretty(x):
    if x < 100: return max(1, round(x))
    d = 10 ** (math.floor(math.log10(x)) - 1)
    return int(round(x / d) * d)

# 기준판에 값이 안 찍힌 것들(작은 건물·개)은 직접 안다
EXTRA = {'small:0': (7*60, 4_000), 'small:1': (17*60, 400_000),
         'small:2': (28*60, 50_000_000), 'small:3': (53*60, 8_000_000_000),
         'guard': (21*60, 2_000_000)}
base_gates = {}
for g in BASE['gates']:
    t, c = g['t'], g['cost']
    if g['what'] in EXTRA: t, c = EXTRA[g['what']]
    if c <= 0: continue
    secs = c / at(BASE['curve'], t // 60, 'ips')
    base_gates[g['what']] = (t, secs)
for w, (t, c) in EXTRA.items():
    if w not in base_gates:
        base_gates[w] = (t, c / at(BASE['curve'], t // 60, 'ips'))
base_gates['auto'] = (23*60, 5_000_000 / at(BASE['curve'], 23, 'ips'))

cur_gates = {g['what']: g['t'] for g in CUR['gates']}

def replace_num(pattern, new, label):
    global src
    m = re.search(pattern, src)
    assert m, '못 찾음: ' + label
    old = m.group(1)
    src = src[:m.start(1)] + f'{new:_}' + src[m.end(1):]
    return int(old.replace('_', ''))

def damp(cur_cost, target):
    return pretty(math.sqrt(cur_cost * target))

drift = []
def gate_cost_pattern(what):
    kind, _, rest = what.partition(':')
    if kind == 'item':
        return rf"id: '{rest.split(':')[0]}',\s+name: '[^']+',\s+price: [\d_]+,\s+time: [\d.]+, cost: ([\d_]+)"
    if kind == 'shop':
        return rf"id: '{rest}', name: '[^']+', sign: '.', cost: ([\d_]+)"
    if kind == 'promote':
        sh, n = rest.split(':')
        block = re.search(rf"id: '{sh}',.*?promote: \[([\d_]+), ([\d_]+)\]", src, re.S)
        return (sh, int(n))
    if kind == 'small':
        names = ['store1', 'inn', 'cart', 'store2']
        return rf"id: '{names[int(rest)]}',\s+name: '[^']+',\s+k: '\w+',\s+cost: ([\d_]+)"
    if kind == 'auto':
        return r"AUTO_COST = ([\d_]+);"
    if kind == 'guard':
        return r"cost: ([\d_]+),\s*//?[^\n]*\n\s*rate:"
    return None

# guard 패턴은 GUARD 블록 구조 확인 필요 — cost 라인 뒤에 rate가 온다고 가정
if not re.search(gate_cost_pattern('guard'), src):
    # 대안: GUARD 블록 안의 cost
    m = re.search(r"export const GUARD = \{[^}]*?cost: ([\d_]+)", src, re.S)
    assert m, 'GUARD cost 못 찾음'

print('── 어긋남과 새 값 ──')
for what, (t_base, secs) in sorted(base_gates.items(), key=lambda x: x[1][0]):
    if what.startswith('staff'): continue
    t_cur = cur_gates.get(what)
    target = secs * at(CUR['curve'], t_base // 60, 'ips')
    pat = gate_cost_pattern(what)
    if isinstance(pat, tuple):  # promote
        sh, n = pat
        m = re.search(rf"(id: '{sh}',.*?promote: \[)([\d_]+)(, )([\d_]+)(\])", src, re.S)
        cur_cost = int(m.group(2 if n == 1 else 4).replace('_', ''))
        new = damp(cur_cost, target)
        g = 2 if n == 1 else 4
        src = src[:m.start(g)] + f'{new:_}' + src[m.end(g):]
    else:
        m = re.search(pat, src) or (re.search(r"export const GUARD = \{[^}]*?cost: ([\d_]+)", src, re.S) if what == 'guard' else None)
        assert m, what
        cur_cost = int(m.group(1).replace('_', ''))
        new = damp(cur_cost, target)
        src = src[:m.start(1)] + f'{new:_}' + src[m.end(1):]
    d = (t_cur - t_base) / max(60, t_base) if t_cur else None
    drift.append(abs(d) if d is not None else 1.0)
    print(f"{what:20s} 기준 {t_base//60:4d}분  지금 {'-' if t_cur is None else t_cur//60:>4}분  "
          f"값 {cur_cost:,} → {new:,}")

# 손님·나쁜놈 문턱: 기준 도착 시각의 새 누적매출로 (감쇠 동일)
ids = re.findall(r"id: '(\w+)',\s+name: '[^']+',\s+face:", src)
for gid, t in BASE['guestAt'].items():
    target = at(CUR['curve'], t // 60, 'revenue')
    m = re.search(rf"id: '{gid}',[^\n]*\n\s*at: ([\d_]+),", src)
    if not m: continue
    cur_at = int(m.group(1).replace('_', ''))
    new = damp(cur_at, max(1, target))
    src = src[:m.start(1)] + f'{new:_}' + src[m.end(1):]
    t_cur = CUR['guestAt'].get(gid)
    drift.append(abs((t_cur - t) / max(60, t)) if t_cur else 1.0)
    print(f"guest:{gid:14s} 기준 {t//60:4d}분  지금 {'-' if t_cur is None else t_cur//60:>4}분  문턱 {cur_at:,} → {new:,}")
for pid, t in BASE['pestAt'].items():
    target = at(CUR['curve'], t // 60, 'revenue')
    m = re.search(rf"id: '{pid}',[^{{}}]*?at: ([\d_]+),", src, re.S)
    if not m: continue
    cur_at = int(m.group(1).replace('_', ''))
    new = damp(cur_at, max(1, target))
    src = src[:m.start(1)] + f'{new:_}' + src[m.end(1):]
    print(f"pest:{pid:15s} 기준 {t//60:4d}분  문턱 {cur_at:,} → {new:,}")

# 등급 ips 문턱: 기준 승급 시각 새 ips의 3할 (느슨한 관문 유지)
for what, minute in [('promote:smith:1', None), ('promote:smith:2', None)]:
    pass
r1t = base_gates.get('promote:smith:1', (83*60, 0))[0]
r2t = base_gates.get('promote:smith:2', (429*60, 0))[0]
for idx, tt in [(1, r1t), (2, r2t)]:
    target = at(CUR['curve'], tt // 60, 'ips') * 0.3
    ms = list(re.finditer(r"guests: \d+,\s+ips: ([\d_]+) \}", src))
    m = ms[idx]
    cur_v = int(m.group(1).replace('_', ''))
    new = damp(cur_v, max(1, target))
    src = src[:m.start(1)] + f'{new:_}' + src[m.end(1):]
    print(f"rank{idx} ips 문턱      {cur_v:,} → {new:,}")

open(P, 'w').write(src)
print(f"\n어긋남: 평균 {sum(drift)/len(drift)*100:.0f}% · 최대 {max(drift)*100:.0f}%  (관문 {len(drift)}개)")
