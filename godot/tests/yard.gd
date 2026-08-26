extends SceneTree
## 마당 배치판이 **장부와 같은가.** 칸 번호로 못 박아 둔다.
##
## 유저가 2026-08-27에 칸 번호로 직접 정한 판이다(장부 "마당 배치판").
## 눈으로 그림을 보고 정한 것이라, 코드가 조금만 어긋나도 "매대가 담 밖으로
## 나갔다" 같은 소리를 듣는다 — 사람이 다시 세지 않게 여기서 센다.
##
## 칸 번호는 왼쪽 위부터 가로로 1,2,3… (게임에서 G키를 누르면 바닥에 뜨는 그 번호)
##   번호 = y * n + x + 1

## 판 → 등급 → {가마, 매대들, 계산대들, 계산 자리들}
const BOARD := {
	"A": [
		{"kiln": 1, "stalls": [2, 3, 4, 7],                  "ct": [9],          "sv": [8]},
		{"kiln": 1, "stalls": [2, 3, 4, 5, 9, 13],           "ct": [16, 12],     "sv": [15, 11]},
		{"kiln": 1, "stalls": [2, 3, 4, 5, 6, 11, 16, 21],   "ct": [25, 20, 15], "sv": [24, 19, 14]},
	],
	"B": [
		{"kiln": 3, "stalls": [1, 4, 7, 9],                   "ct": [6],          "sv": [5]},
		{"kiln": 4, "stalls": [1, 5, 9, 13, 3, 16],           "ct": [8, 12],      "sv": [7, 11]},
		{"kiln": 5, "stalls": [1, 6, 11, 16, 21, 3, 4, 25],   "ct": [10, 15, 20], "sv": [9, 14, 19]},
	],
	"D": [
		{"kiln": 1, "stalls": [2, 3, 7, 9],                   "ct": [8],          "sv": [5]},
		{"kiln": 1, "stalls": [2, 3, 4, 5, 13, 16],           "ct": [14, 15],     "sv": [10, 11]},
		{"kiln": 1, "stalls": [2, 3, 4, 5, 6, 11, 21, 25],    "ct": [22, 23, 24], "sv": [17, 18, 19]},
	],
	# C 길가진열은 **보류**다. 유저가 "길은 오른쪽 위(↗)"로 정했는데, 마을
	# 격자에서 마당의 길 쪽 변은 오른쪽(↘)과 아래(↙) 둘뿐이라 그대로는 못 짓는다.
	# 다시 정할 때까지 옛 배치를 지키고, 그 옛 배치가 안 흔들리는지만 본다.
	"C": [
		{"kiln": 7, "stalls": [1, 2, 3, 9],                   "ct": [6],          "sv": [5]},
		{"kiln": 13, "stalls": [1, 2, 3, 4, 8, 5],            "ct": [12, 16],     "sv": [11, 15]},
		{"kiln": 21, "stalls": [1, 2, 3, 4, 5, 10, 6, 11],    "ct": [15, 20, 25], "sv": [14, 19, 24]},
	],
}

var fails: Array = []

func _init() -> void:
	for kind in BOARD:
		for rank in range(3):
			_check(String(kind), rank)
	if fails.is_empty():
		print("YARD OK — 네 판 × 세 단, 장부와 같다")
	else:
		for f in fails:
			print("YARD FAIL: %s" % f)
	quit(0 if fails.is_empty() else 1)

func _num(c: Vector2i, n: int) -> int:
	return c.y * n + c.x + 1

func _nums(cells: Array, n: int) -> Array:
	var out: Array = []
	for c in cells:
		out.append(_num(c, n))
	return out

func _check(kind: String, rank: int) -> void:
	var n: int = 3 + rank
	var y: Dictionary = Iso.yard(kind, n)
	var want: Dictionary = BOARD[kind][rank]
	var tag: String = "%s %d단" % [kind, rank + 1]

	if _num(y.kiln, n) != int(want.kiln):
		fails.append("%s 가마가 %d번이어야 하는데 %d번" % [tag, int(want.kiln), _num(y.kiln, n)])
	var got_st: Array = _nums(y.stalls, n)
	var want_st: Array = (want.stalls as Array).duplicate()
	got_st.sort()
	want_st.sort()
	if got_st != want_st:
		fails.append("%s 매대가 %s여야 하는데 %s" % [tag, str(want_st), str(got_st)])
	if _nums(y.counters, n) != want.ct:
		fails.append("%s 계산대가 %s여야 하는데 %s" % [tag, str(want.ct), str(_nums(y.counters, n))])
	if _nums(y.serves, n) != want.sv:
		fails.append("%s 계산 자리가 %s여야 하는데 %s" % [tag, str(want.sv), str(_nums(y.serves, n))])

	# ── 규칙 검사(번호와 별개로 늘 참이어야 하는 것들)
	if y.counters.size() != rank + 1:
		fails.append("%s 계산대 수가 등급+1(%d)이 아니라 %d" % [tag, rank + 1, y.counters.size()])
	if y.stalls.size() != 2 * (n - 1):
		fails.append("%s 매대 칸이 %d이 아니라 %d" % [tag, 2 * (n - 1), y.stalls.size()])
	# 한 칸에 가구가 둘 놓이면 안 된다 — 계산대가 겹쳐 놓이던 옛 버그의 파수꾼
	var used: Dictionary = {}
	var all: Array = [y.kiln] + (y.stalls as Array) + (y.counters as Array) + (y.serves as Array)
	for c in all:
		if used.has(c):
			fails.append("%s %d번 칸에 가구가 둘" % [tag, _num(c, n)])
		used[c] = true
		if c.x < 0 or c.y < 0 or c.x >= n or c.y >= n:
			fails.append("%s 칸이 마당 밖(%d,%d)" % [tag, c.x, c.y])
	# 계산대는 반드시 **길에 닿는 변**에 있어야 한다(길은 ↘ 아니면 ↙뿐)
	for c in y.counters:
		var ok: bool = (c.x == n - 1) if String(y.gate) == "x" else (c.y == n - 1)
		if not ok:
			fails.append("%s 계산대 %d번이 길가 변이 아니다" % [tag, _num(c, n)])
	# 계산 자리는 계산대의 안쪽 이웃이어야 한다
	for k in range(y.counters.size()):
		var d: Vector2i = (y.counters[k] as Vector2i) - (y.serves[k] as Vector2i)
		if absi(d.x) + absi(d.y) != 1:
			fails.append("%s %d번 계산대의 자리가 이웃이 아니다" % [tag, _num(y.counters[k], n)])
	# 일꾼 자리는 가구 없는 칸이어야 하고, **그 등급에서 뽑을 수 있는 수**만큼은
	# 나와야 한다(채용 자리 = 등급+1). 모자라면 뽑아 놓고 안 보이는 일꾼이 생긴다.
	var spots: Array = Iso.staff_spots(y, n)
	if spots.size() < rank + 1:
		fails.append("%s 일꾼 설 자리가 %d뿐(뽑을 수 있는 수 %d)" % [tag, spots.size(), rank + 1])
	for sp in spots:
		if used.has(sp):
			fails.append("%s 일꾼 자리 %d번에 가구가 있다" % [tag, _num(sp, n)])
