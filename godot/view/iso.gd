class_name Iso
## 격자 마을의 **좌표와 배치**. 그리는 코드는 없다 — iso.js에서 규칙에
## 해당하는 부분만 떼어 온 것이다.
##
## 시점은 비스듬히 내려다본 격자. 바닥 한 칸은 96×48 — 가로:세로 2:1이
## 이 시점의 기본 비율이다.
##
## ★ 화면의 가로 위치는 tx가 아니라 **(tx − ty)**다. 이걸 놓치면 두 가게가
##   같은 세로줄에 포개진다. 아래 배치는 그걸 다 재서 잡은 것이다.

const TW := 96.0
const TH := 48.0
const GW := 15
## 마을이 또 길어졌다(18 → 30 → 48). 3구역(큰장마당)이 들어왔다.
## 가로로 늘리지 않고 **세로로만** 늘린 이유: 이 시점(비스듬히 내려다본 격자)에서
## 가로로 늘리면 화면이 마름모로 넓게 퍼져 폰에서 양옆이 잘린다.
const GH := 48
## 마을 바깥으로 더 까는 풀밭 두께(칸). 여기까지는 밀어서 볼 수 있다.
const EDGE := 2

## 칸 좌표 → 세계 좌표. 정수는 칸의 모서리다.
static func w(tx: float, ty: float) -> Vector2:
	return Vector2((tx - ty) * TW * 0.5, (tx + ty) * TH * 0.5)

## 큰길 둘(세로, 두 칸 폭)과 골목 둘(가로, 한 칸 폭)이 마을을 여섯으로 가른다.
## 손님은 **길로만 다닌다.**
static func is_road(tx: int, ty: int) -> bool:
	return tx == 5 or tx == 6 or tx == 12 or tx == 13 \
		or ty == 5 or ty == 11 or ty == 17 or ty == 23 or ty == 29 or ty == 35 or ty == 41

## 마당의 **길 쪽 모서리**(계산대가 있는 앞 모서리). 마당은 여기를 붙박이로
## 두고 길 반대쪽(뒤)으로 자란다 — 넓어지는 건 뒷마당이다.
## 가게 자리 — **길에 닿는 앞 모서리**다. 마당은 여기를 붙박이로 두고
## 길 반대쪽(뒤)으로 자란다. 그래서 승급해서 넓어져도 앞줄이 안 밀린다.
##
## 골목이 넷(ty 5·11·17·23), 큰길이 둘(tx 5·6 / 12·13)이라 마을이 열 칸으로
## 나뉜다. 가게가 열이니 딱 맞는다.
const SHOP_T := [
	Vector2i(5, 17),   # 대장간
	Vector2i(12, 17),  # 필방
	Vector2i(5, 11),   # 지물포
	Vector2i(12, 5),   # 옹기점
	Vector2i(5, 5),    # 약재상
	Vector2i(12, 11),  # 국밥집
	Vector2i(5, 23),   # 주막
	Vector2i(12, 23),  # 꼬치집
	Vector2i(5, 29),   # 떡집
	Vector2i(12, 29),  # 푸줏간
	Vector2i(5, 35),   # 어물전     ── 여기부터 큰장마당(3구역)
	Vector2i(12, 35),  # 포목전
	Vector2i(5, 41),   # 갓방
	Vector2i(12, 41),  # 유기전
	Vector2i(5, 47),   # 나전방     (12,47)은 비워 뒀다 — 나중 것의 자리
]
## 마당 생김새는 **돌려 가며** 준다. 열 채가 다 같은 모양이면 마을이 아니라
## 창고가 된다. 어느 것을 줘도 규칙은 같다 — 계산대가 길 쪽에 붙기만 하면 된다.
## 가게마다 어느 판을 쓰나 — 세 판을 골고루 돌린다(2026-08-27).
## 열다섯 채가 다 같은 모양이면 마을이 아니라 창고가 된다.
const YARD_KIND := ["갑", "을", "병", "갑", "을", "병", "갑", "을", "병", "갑", "을", "병", "갑", "을", "병"]
## 마을 드나드는 목 — 길이 마을 가장자리에 닿는 칸 전부.
##
## ★ 예전엔 위쪽 한 곳(6,0)뿐이었다. 그래서 손님이 **늘 같은 데서 같은 줄로**
##   내려왔다. 길이 여섯 갈래인데 쓰는 목이 하나면 마을이 좁아 보인다.
const GATES := [
	Vector2i(5, 0), Vector2i(6, 0), Vector2i(12, 0), Vector2i(13, 0),          # 위
	Vector2i(5, GH - 1), Vector2i(6, GH - 1), Vector2i(12, GH - 1), Vector2i(13, GH - 1),  # 아래
	Vector2i(0, 5), Vector2i(0, 11), Vector2i(0, 17), Vector2i(0, 23),         # 왼쪽 골목
	Vector2i(0, 29), Vector2i(0, 35), Vector2i(0, 41),
	Vector2i(GW - 1, 5), Vector2i(GW - 1, 11), Vector2i(GW - 1, 17), Vector2i(GW - 1, 23),  # 오른쪽
	Vector2i(GW - 1, 29), Vector2i(GW - 1, 35), Vector2i(GW - 1, 41),
]
## 작은 건물과 개집 — 가게가 열이 되면서 안쪽 칸을 내줬다.
## 오른쪽 끝 줄(x=14)은 길도 마당도 아니라 늘 비어 있다. 거기로 옮긴다.
const SMALL_T := [Vector2i(14, 2), Vector2i(14, 8), Vector2i(14, 14), Vector2i(14, 20)]
## 개집은 (14,26)이었는데 **저잣거리(잠긴 구역) 안**이라 옮겼다(14,4).
## 삽살개는 2.5만짜리 초반 물건이다 — 잠긴 동네 안에 있으면 초반 내내 못 산다.
## 네 번째 작은 건물(14,20)은 일부러 저잣거리에 남겨 뒀다 — 구역을 열면
## 딸려 오는 덤이 하나 있는 것도 나쁘지 않다.
const DOG_T := Vector2i(14, 4)

## 손님이 서는 쪽(길)과 그 반대쪽(점장이 서는 마당 안). 한 칸 어치다.
const GATE_OFF := {"x": Vector2(44, 22), "y": Vector2(-44, 22)}
## 줄이 뻗는 방향 — **가게 앞면을 따라** 선다(2026-08-25, 유저가 잡았다).
## 예전엔 길을 따라 가게 반대쪽으로 뻗어서, 둘째 사람부터 가게를 등지고
## 골목 너머까지 밀려났다. 계산대가 어디 있든 줄은 매대 진열이 보이는
## 쪽으로 서는 게 장터의 상식이다 — 세로 길(gate x)은 위로, 가로 골목
## (gate y)은 왼쪽으로, 마당 변을 끼고 뻗는다.
const LINE_OFF := {"x": Vector2(42, -21), "y": Vector2(-42, -21)}
## 을 판만 줄이 **아래로** 뻗는다 — 계산대가 뒤 꼭짓점에서 아래로 늘어서기 때문.
const LINE_DOWN := Vector2(-42, 21)

static func plot_dim(sim: Sim, i: int) -> int:
	return 3 + min(2, sim.rank_of(Content.SHOPS[i].id))

static func org(sim: Sim, i: int) -> Vector2i:
	var n: int = plot_dim(sim, i)
	return Vector2i(SHOP_T[i].x - n, SHOP_T[i].y - n)

## 마당 생김새 **셋**. 마당 안 좌표는 (0,0)이 뒤 꼭짓점(화면 위),
## (n-1,n-1)이 앞 꼭짓점(화면 아래)이다.
##   갑 앞마당 · 을 뒷마당 · 병 옆문
##
## ★ 2026-08-27, 넷에서 셋으로 줄였다(유저). 계산대는 반드시 **꼭짓점에서
##   시작해 한 변을 따라** 늘어선다 — 그래야 줄이 길 위로 곧게 뻗는다.
##   변 가운데에서 시작하던 판(옛 B·C)은 줄이 뻗을 자리가 모자랐다.
##   길 쪽 변은 오른쪽(↘)과 아래(↙) 둘뿐이라(마당이 길 반대쪽으로 자란다)
##   "오른쪽 변 위로 · 오른쪽 변 아래로 · 아래 변 왼쪽으로" 셋이 전부다.
##
## 줄 길이도 등급을 탄다 — 동시 주문 자리 = 계산대 + 1 = 2 · 3 · 4명.
static func yard(kind: String, n: int) -> Dictionary:
	var nct: int = n - 2                    # 계산대 수 = 등급 + 1
	var cts: Array = []
	var stalls: Array = []
	var kiln: Vector2i
	var gate: String
	if kind == "을":
		# 뒷마당 — 계산대가 **뒤 꼭짓점**에서 길가 변을 따라 아래로.
		kiln = Vector2i(0, n - 1)
		gate = "x"
		for k in range(nct):
			cts.append(Vector2i(n - 1, k))
		for x in range(1, n):
			stalls.append(Vector2i(x, n - 1))
		for y in range(0, n - 1):
			stalls.append(Vector2i(0, y))
	elif kind == "병":
		# 옆문 — 계산대가 **앞 꼭짓점**에서 아래 골목 변을 따라 왼쪽으로.
		kiln = Vector2i(0, 0)
		gate = "y"
		for k in range(nct):
			cts.append(Vector2i(n - 1 - k, n - 1))
		for x in range(1, n):
			stalls.append(Vector2i(x, 0))
		for y in range(1, n):
			stalls.append(Vector2i(0, y))
	else:
		# 갑 앞마당 — 계산대가 **앞 꼭짓점**에서 길가 변을 따라 위로.
		kiln = Vector2i(0, 0)
		gate = "x"
		for k in range(nct):
			cts.append(Vector2i(n - 1, n - 1 - k))
		for x in range(1, n):
			stalls.append(Vector2i(x, 0))
		for y in range(1, n):
			stalls.append(Vector2i(0, y))
	stalls = stalls.slice(0, 2 * (n - 1))
	var svs: Array = []
	for c in cts:
		svs.append(Vector2i(c.x - 1, c.y) if gate == "x" else Vector2i(c.x, c.y - 1))
	# 줄이 뻗는 쪽 — 계산대가 늘어선 방향의 **연장선**이다. 그래야 줄이 꺾이지 않는다.
	#   갑 위로(↗) · 을 아래로(↙) · 병 왼쪽으로(↖)
	var loff: Vector2 = LINE_OFF.x
	if kind == "을":
		loff = LINE_DOWN
	elif kind == "병":
		loff = LINE_OFF.y
	return {"kind": kind, "gate": gate, "kiln": kiln, "lineOff": loff,
		"counter": cts[0], "counters": cts, "serve": svs[0], "serves": svs,
		"stalls": stalls}

## 작업대 — 가마 바로 안쪽 칸. 점장이 여기서 만든다.
static func work_spot(y: Dictionary, n: int) -> Vector2i:
	return Vector2i(clampi(y.kiln.x, 1, n - 2), clampi(y.kiln.y, 1, n - 2))

## 직원 자리 — 안쪽 빈칸을 먼저, 모자라면 담벼락 빈칸까지.
## 3×3 마당은 안쪽 칸이 딱 하나뿐이고 그걸 작업대가 쓴다. 담벼락까지 안 내주면
## 무쇠급 가게는 직원을 뽑아도 한 마리도 안 보인다.
static func staff_spots(y: Dictionary, n: int) -> Array:
	var wk: Vector2i = work_spot(y, n)
	# 가구가 놓인 칸은 사람이 못 선다. 계산 자리도 뺀다 — 거기 서 있으면
	# 상자를 건네러 온 일꾼과 겹친다(계산대가 여럿이 되면서 더 자주 겹친다).
	var taken: Dictionary = {}
	for t in y.stalls:
		taken[t] = true
	for c in y.counters:
		taken[c] = true
	for s in y.serves:
		taken[s] = true
	taken[y.kiln] = true
	taken[wk] = true
	var out: Array = []
	for b in range(1, n - 1):
		for a in range(1, n - 1):
			if not taken.has(Vector2i(a, b)):
				out.append(Vector2i(a, b))
	for b in range(n):
		for a in range(n):
			if a > 0 and a < n - 1 and b > 0 and b < n - 1:
				continue
			if not taken.has(Vector2i(a, b)):
				out.append(Vector2i(a, b))
	return out

## 손님이 서는 길칸 — 계산대가 바라보는 쪽 한 칸.
static func door(sim: Sim, i: int) -> Vector2i:
	var o: Vector2i = org(sim, i)
	var y: Dictionary = yard(YARD_KIND[i], plot_dim(sim, i))
	var ct: Vector2i = y.counter
	return Vector2i(o.x + ct.x + 1, o.y + ct.y) if y.gate == "x" else Vector2i(o.x + ct.x, o.y + ct.y + 1)

## 가게 i의 요지(세계 좌표).
static func foot(sim: Sim, i: int) -> Dictionary:
	var o: Vector2i = org(sim, i)
	var n: int = plot_dim(sim, i)
	var y: Dictionary = yard(YARD_KIND[i], n)
	var cc: Vector2 = w(o.x + y.counter.x + 0.5, o.y + y.counter.y + 0.5)
	var wk: Vector2i = work_spot(y, n)
	# 계산대가 여럿이면 **자리도 여럿이다**(2026-08-27). 손님은 계산대마다
	# 하나씩 서고, 상자를 든 일꾼은 그 손님이 선 계산대의 안쪽 칸으로 간다.
	var stands: Array = []
	var serves: Array = []
	for k in range(y.counters.size()):
		var ck: Vector2i = y.counters[k]
		var sk: Vector2i = y.serves[k]
		stands.append(w(o.x + ck.x + 0.5, o.y + ck.y + 0.5) + GATE_OFF[y.gate])
		serves.append(w(o.x + sk.x + 0.5, o.y + sk.y + 0.5))
	return {
		"n": n, "S": w(o.x + n, o.y + n), "yard": y,
		"stand": cc + GATE_OFF[y.gate], "stands": stands,
		"work": w(o.x + wk.x + 0.5, o.y + wk.y + 0.5),
		"serve": serves[0], "serves": serves,
	}

## 줄 k번째가 설 자리. 0번이 계산대 앞, 뒤로 갈수록 길을 따라 물러선다.
## 계산대가 여럿이면 앞의 몇 사람은 **각 계산대 앞에 나란히** 선다(2026-08-27).
## 그보다 뒤는 마지막 계산대 뒤로 길을 따라 물러선다.
static func line_spot(sim: Sim, i: int, k: int) -> Vector2:
	var f: Dictionary = foot(sim, i)
	var nct: int = (f.stands as Array).size()
	if k < nct:
		return f.stands[k]
	return f.stands[nct - 1] + (f.yard.lineOff as Vector2) * (k - nct + 1)

# ── 길찾기 ──
# 길칸은 60칸 남짓이라 너비우선탐색이면 충분하다. 길 모양은 절대 안 변하므로
# 한 번 찾은 길은 넣어 두고 다시 쓴다.
static var _routes: Dictionary = {}

static func walkable(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < GW and t.y < GH and is_road(t.x, t.y)

## 길칸 a에서 b까지의 칸 목록. 못 가면 빈 배열.
static func route(a: Vector2i, b: Vector2i) -> Array:
	var key: String = "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]
	if _routes.has(key):
		return _routes[key]
	var prev: Dictionary = {a: null}
	var q: Array[Vector2i] = [a]
	var head: int = 0
	var found: bool = a == b
	while head < q.size() and not found:
		var c: Vector2i = q[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = c + d
			if not walkable(nx) or prev.has(nx):
				continue
			prev[nx] = c
			if nx == b:
				found = true
				break
			q.append(nx)
	var out: Array = []
	if prev.has(b):
		var cur: Variant = b
		while cur != null:
			out.push_front(cur)
			cur = prev[cur]
	_routes[key] = out
	return out

## 길 위에서 제일 가까운 칸 (가게 문 앞 등 길 밖 좌표를 받았을 때)
static func nearest_road(t: Vector2i) -> Vector2i:
	if walkable(t):
		return t
	var best: Vector2i = Vector2i(5, 5)
	var bd: int = 1 << 30
	for ty in range(GH):
		for tx in range(GW):
			if not is_road(tx, ty):
				continue
			var d: int = absi(tx - t.x) + absi(ty - t.y)
			if d < bd:
				bd = d
				best = Vector2i(tx, ty)
	return best
