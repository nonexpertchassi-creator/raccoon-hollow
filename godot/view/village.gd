extends Node2D
class_name Village
## 격자 마을을 그린다. **경제 계산이 한 줄도 없다** — sim을 읽기만 하고
## 절대 고치지 않는다. iso.js와 같은 규칙이다.
##
## 지금은 Godot의 _draw()로 도형을 직접 그린다. 그림(스프라이트)이 나오면
## 이 자리에 하나씩 갈아 끼우면 된다 — 배치와 깊이 순서는 그대로 쓴다.

var sim: Sim

const C := {
	"grass": Color("8b9e74"), "grass2": Color("849668"), "road": Color("d9cba9"),
	"paper": Color("ece2cb"), "paper2": Color("dccfb2"), "wood": Color("8a6a45"),
	"wood2": Color("6d5236"), "ink": Color("2b241b"), "ink2": Color("5a4e3d"),
	"gold": Color("a8763e"), "jade": Color("4a7c59"), "red": Color("c7563f"),
	"ruin": Color("5f6b4e"), "dirt": Color("c2ad83"), "yardfloor": Color("d3c5a4"),
}

var _font: Font
var _t: float = 0.0
var _props: Array = []

## 걸어다니는 손님. sim이 "팔았다"고 알려오면 한 마리 생겨서 길로 들어온다.
## 화면은 늘 sim보다 조금 늦다 — 돈은 이미 들어왔지만 손님은 아직 걷고 있다.
var walkers: Array = []
## 한 번 뜨고 사라지는 표 — 팔린 값. 위로 떠오르며 옅어진다.
var floats: Array = []
## 카메라 한가운데(세계 좌표). 까마귀가 화면을 가로지르는 데 쓴다.
var cam_center: Vector2 = Vector2.ZERO
const WALK := 95.0          # 손님 걸음(세계 px/초)
const BUY_TIME := 2.3       # 가게 앞에 서 있는 시간
## 손님이 들어오고 나가는 목은 **매번 고른다**(Iso.GATES).
## 여기 쓰는 주사위는 화면 전용이다 — sim의 주사위를 한 번이라도 굴리면
## 대조 시험이 그 자리에서 어긋난다. 화면은 sim을 읽기만 한다.
## 그림이 아직 없는 자리에 그리는 도형의 크기.
##
## ★ 그림 상자가 72px이라고 60으로 맞췄다가 되돌렸다 — **그림은 상자를 꽉
##   채우지 않는다.** 너구리 둘레에 투명한 여백이 있어서, 상자 크기에 맞추면
##   도형만 두 배로 커져 가게를 덮어 버린다. 실제로 찍어 보고 40으로 잡았다.
##   짐작으로 맞춘 숫자는 이렇게 한 번에 틀린다.
const SHAPE := 40.0
## 등급 테 — 물건이 몇 급인지 매대에서 바로 보이게. 0급(기본)은 안 두른다.
## 값을 색으로 말하는 것이라 물건이 쇠든 종이든 상관없이 통한다.
const RANK_RING := [Color(0, 0, 0, 0), Color("cfd6dd"), Color("e8b93f")]
var _grng: Rng = Rng.new(20260821)
func _gate() -> Vector2i:
	return Iso.GATES[int(_grng.next() * Iso.GATES.size()) % Iso.GATES.size()]
const LINE_MAX := 4          # 한 가게 앞에 세우는 손님 수

## 손님이 물어본 것 — "무쇠도끼?" 한 마디가 그 가게 지붕 위에 뜬다.
## 이게 없으면 아직 안 연 품목을 **왜** 여는지가 화면에 안 보인다.
## 한 번에 하나만 띄운다 — 두 개가 겹치면 둘 다 못 읽는다.
var bubble: Dictionary = {}
const BUBBLE_LIFE := 4.5

## 가게 앞 줄. 손님이 겹쳐 서면 서로를 덮어서 몇 마리인지도 안 보인다.
## 먼저 온 손님이 0번(계산대 앞), 나머지는 길을 따라 뒤로 선다.
var line: Array = []

## 가게별 점장 — 평소엔 작업대, 팔릴 땐 계산대 뒤로 간다
var clerks: Array = []
const CLERK_SPEED := 130.0

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_props = _make_props()

func setup(s: Sim) -> void:
	sim = s
	clerks = []
	line = []
	for i in range(Content.SHOPS.size()):
		clerks.append({"pos": Iso.foot(sim, i).work, "at": "work", "busy": 0.0, "walking": false})
		line.append([])

## sim이 "손님이 물어봤다"고 알려오면 그 가게 위에 말풍선을 띄운다.
func on_ask(ask: Dictionary) -> void:
	var idx: int = -1
	for i in range(Content.SHOPS.size()):
		if Content.SHOPS[i].id == ask.item.shop:
			idx = i
	if idx < 0:
		return
	bubble = {"idx": idx, "text": "%s?" % String(ask.item.name),
		"face": String(ask.guest.face), "t": BUBBLE_LIFE}

## sim이 판 것을 화면에 들여보낸다. **sim을 고치지 않는다** — 읽고 흉내만 낸다.
func on_sale(sale: Dictionary) -> void:
	# 빈손 손님도 들여보낸다 — 못 산 물건의 가게 앞까지는 가 본다.
	# 💢는 거기서 나온다. 문 앞에서 되돌려보내면 왜 화가 났는지가 안 보인다.
	var empty: bool = sale.lines.is_empty()
	var src: Array = sale.get("grumbles", []) if empty else sale.lines
	if src.is_empty():
		return
	var shop_id: String = String(src[0].item.shop)
	var idx: int = -1
	for i in range(Content.SHOPS.size()):
		if Content.SHOPS[i].id == shop_id:
			idx = i
	if idx < 0:
		return
	# 줄이 다 차면 이번 손님은 화면에 안 들여보낸다. 돈은 이미 들어왔고,
	# 화면은 어차피 sim의 그림자일 뿐이다 — 그림자가 넘칠 필요는 없다.
	if line[idx].size() >= LINE_MAX:
		clerks[idx].busy = 1.4
		return
	var door: Vector2i = Iso.door(sim, idx)
	var enter: Vector2i = _gate()
	var path: Array = Iso.route(enter, Iso.nearest_road(door))
	if path.is_empty():
		return
	walkers.append({
		"face": String(sale.guest.face), "id": String(sale.guest.id), "shop": idx, "state": "in",
		"pos": Iso.w(enter.x + 0.5, enter.y + 0.5), "out_gate": _gate(),
		"path": path, "step": 1, "wait": 0.0, "qwait": 0.0, "empty": empty,
		"n": int(sale.n), "gain": float(sale.gain), "sold": _order_of(sale),
	})
	line[idx].append(walkers[walkers.size() - 1])
	clerks[idx].busy = 1.4

## 이 손님이 무엇을 몇 개 사러 왔나. 머리 위에 띄울 주문표다.
## 셋까지만 담는다 — 넷을 넘기면 말풍선이 손님보다 커져서 길을 덮는다.
func _order_of(sale: Dictionary) -> Array:
	var out: Array = []
	for l in sale.lines:
		out.append({"id": String(l.item.id), "icon": String(l.item.icon), "n": int(l.n)})
	return out

func _walk(wk: Dictionary, delta: float) -> bool:
	var target: Vector2
	if wk.state == "buy":
		target = Iso.line_spot(sim, wk.shop, maxi(0, line[wk.shop].find(wk)))
	elif wk.step < wk.path.size():
		var t: Vector2i = wk.path[wk.step]
		target = Iso.w(t.x + 0.5, t.y + 0.5)
	else:
		return true
	var d: Vector2 = target - wk.pos
	var step: float = WALK * delta
	if d.length() <= step:
		wk.pos = target
		if wk.state != "buy":
			wk.step += 1
		return true
	wk.pos += d.normalized() * step
	return false

func _advance(delta: float) -> void:
	# 말풍선 시계도 여기서 돈다. _process에 두면 빨리 감기(shot·taptest)가
	# 이 줄을 건너뛰어서, 도구에게는 말풍선이 **영원히 안 사라지는 것**이 된다.
	if not bubble.is_empty():
		bubble.t -= delta
		if bubble.t <= 0.0:
			bubble = {}
	var live: Array = []
	for f in floats:
		f.t -= delta
		f.pos.y -= delta * 26.0
		if f.t > 0.0:
			live.append(f)
	floats = live
	var keep: Array = []
	for wk in walkers:
		match wk.state:
			"in":
				if _walk(wk, delta) and wk.step >= wk.path.size():
					wk.state = "buy"
			"buy":
				if _walk(wk, delta):
					# 맨 앞에 설 때까지는 시계가 안 돈다 — 줄은 기다리는 곳이다
					if line[wk.shop].find(wk) == 0:
						wk.wait += delta
						wk.qwait = 0.0        # 제 차례가 왔으면 화를 푼다
					else:
						wk.qwait += delta
					if wk.wait >= BUY_TIME:
						wk.state = "out"
						if not wk.empty and wk.gain > 0.0:
							# 엽전은 **팔린 순간**에만 뜬다. 손님 머리 위에 계속
							# 붙여 두면 "얼마 낼 손님"이 되는데, 그건 아직 안 일어난 일이다.
							floats.append({"pos": Iso.foot(sim, wk.shop).serve + Vector2(0, -40),
								"text": "🪙" + Num.fmt(wk.gain), "t": 1.3})
						line[wk.shop].erase(wk)
						wk.path = Iso.route(Iso.nearest_road(Iso.door(sim, wk.shop)), wk.out_gate)
						wk.step = 1
			"out":
				if _walk(wk, delta) and wk.step >= wk.path.size():
					continue                      # 마을을 떠났다
		keep.append(wk)
	walkers = keep
	# 점장 — 팔린 여운이 있으면 계산대 뒤, 아니면 작업대
	for i in range(Content.SHOPS.size()):
		var c: Dictionary = clerks[i]
		c.busy = max(0.0, c.busy - delta)
		var f: Dictionary = Iso.foot(sim, i)
		var goal: Vector2 = f.serve if c.busy > 0.0 else f.work
		var d: Vector2 = goal - c.pos
		var step: float = CLERK_SPEED * delta
		c.walking = d.length() > step        # 걷는 중이면 걷는 그림을 쓴다
		c.pos = goal if d.length() <= step else c.pos + d.normalized() * step

func _process(delta: float) -> void:
	_t += delta
	if sim != null:
		_advance(delta)
	queue_redraw()

## 풀밭에 흩어 놓는 나무·바위·꽃. 길과 가게 자리는 피한다.
func _make_props() -> Array:
	var rng := Rng.new(20260820)
	var out: Array = []
	# 마을 밖 테두리 — **나무만** 빽빽하게. 마을이 벌판 한가운데 뚝 떨어져
	# 있는 것보다, 숲으로 둘러싸인 편이 "여기가 골짜기"라는 말이 된다.
	# (길은 비운다 — 길은 숲 사이로 이어져 나가는 것처럼 보여야 한다.)
	for ty in range(-Iso.EDGE, Iso.GH + Iso.EDGE):
		for tx in range(-Iso.EDGE, Iso.GW + Iso.EDGE):
			if tx >= 0 and ty >= 0 and tx < Iso.GW and ty < Iso.GH:
				continue
			if Iso.is_road(tx, ty) or rng.next() > 0.62:
				continue
			out.append({"t": Vector2i(tx, ty), "k": "tree", "o": 0.7 + rng.next() * 0.9})
	for ty in range(Iso.GH):
		for tx in range(Iso.GW):
			if Iso.is_road(tx, ty):
				continue
			var near_shop: bool = false
			for st in Iso.SHOP_T:
				if absi(st.x - tx) <= 5 and absi(st.y - ty) <= 5:
					near_shop = true
			for st in Iso.SMALL_T:
				if absi(st.x - tx) <= 1 and absi(st.y - ty) <= 1:
					near_shop = true
			if near_shop or (absi(Iso.DOG_T.x - tx) <= 1 and absi(Iso.DOG_T.y - ty) <= 1):
				continue
			if rng.next() > 0.30:
				continue
			var r: float = rng.next()
			out.append({"t": Vector2i(tx, ty), "k": "tree" if r < 0.5 else ("rock" if r < 0.75 else "flower"),
				"o": rng.next()})
	return out

# ── 그리기 도구 ──
func _quad(a: Vector2, b: Vector2, c2: Vector2, d: Vector2, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c2, d]), col)

func _outline(a: Vector2, b: Vector2, c2: Vector2, d: Vector2, col: Color, wd: float) -> void:
	draw_polyline(PackedVector2Array([a, b, c2, d, a]), col, wd)

func _text(pos: Vector2, s: String, size: int, col: Color) -> void:
	var wd: float = _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, pos - Vector2(wd * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _chip(center: Vector2, wd: float, h: float, col: Color) -> void:
	draw_rect(Rect2(center - Vector2(wd * 0.5, 0), Vector2(wd, h)), col)

static func _shade(col: Color, d: float) -> Color:
	return Color(clampf(col.r + d, 0, 1), clampf(col.g + d, 0, 1), clampf(col.b + d, 0, 1), col.a)

## 건물 상자 — 왼면·오른면·윗면
func _box(tx: float, ty: float, bw: float, bd: float, h: float, top: Color, side: Color, lift: float = 0.0) -> void:
	var off := Vector2(0, -lift)
	var N: Vector2 = Iso.w(tx, ty) + off
	var E: Vector2 = Iso.w(tx + bw, ty) + off
	var S: Vector2 = Iso.w(tx + bw, ty + bd) + off
	var W: Vector2 = Iso.w(tx, ty + bd) + off
	var up := Vector2(0, -h)
	_quad(W + up, S + up, S, W, side)
	_quad(E + up, S + up, S, E, _shade(side, -0.07))
	_quad(N + up, E + up, S + up, W + up, top)

func _tile(tx: int, ty: int, road: bool) -> void:
	var N: Vector2 = Iso.w(tx, ty)
	var E: Vector2 = Iso.w(tx + 1, ty)
	var S: Vector2 = Iso.w(tx + 1, ty + 1)
	var W: Vector2 = Iso.w(tx, ty + 1)
	var col: Color = C.road if road else (C.grass if (tx + ty) % 2 == 1 else C.grass2)
	# 마을 밖은 한 톤 어둡다. 같은 색으로 깔면 어디까지가 마을인지 안 보이고,
	# 밀 수 있는 데까지 밀어 놓고 "여긴 뭐지" 하게 된다.
	if tx < 0 or ty < 0 or tx >= Iso.GW or ty >= Iso.GH:
		col = _shade(col, -0.06)
	_quad(N, E, S, W, col)
	_outline(N, E, S, W, Color(0, 0, 0, 0.05 if road else 0.03), 1.0)

## 다진 흙마당 한 칸 — 작은 건물의 발밑. 이게 있어야 땅에 붙어 보인다.
func _pad(tx: int, ty: int) -> void:
	var N: Vector2 = Iso.w(tx, ty)
	var E: Vector2 = Iso.w(tx + 1, ty)
	var S: Vector2 = Iso.w(tx + 1, ty + 1)
	var W: Vector2 = Iso.w(tx, ty + 1)
	_quad(N, E, S, W, C.dirt)
	_outline(N, E, S, W, Color(0.24, 0.2, 0.12, 0.28), 1.5)

func _prop(p: Dictionary) -> void:
	var at: Vector2 = Iso.w(p.t.x + 0.5, p.t.y + 0.5)
	match p.k:
		"tree":
			draw_rect(Rect2(at + Vector2(-3, -10), Vector2(6, 12)), C.wood2)
			draw_circle(at + Vector2(0, -22), 16.0 + p.o * 5.0, Color("6f8a5c"))
			draw_circle(at + Vector2(-7, -15), 10.0, Color("7fa070"))
		"rock":
			draw_circle(at + Vector2(0, -4), 8.0 + p.o * 4.0, Color("8f8f7a"))
		_:
			for k in range(3):
				draw_circle(at + Vector2((k - 1) * 9, -4 - (k % 2) * 5), 3.0,
					Color("e5b8c4") if k % 2 == 1 else Color("efe3a8"))

# ── 가게 ──
func _ruin(i: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var o: Vector2i = Iso.org(sim, i)
	var N: Vector2 = Iso.w(o.x, o.y)
	var E: Vector2 = Iso.w(o.x + 3, o.y)
	var S: Vector2 = Iso.w(o.x + 3, o.y + 3)
	var W: Vector2 = Iso.w(o.x, o.y + 3)
	_outline(N, E, S, W, Color(0.2, 0.17, 0.12, 0.45), 2.0)
	var M: Vector2 = Iso.w(o.x + 1.5, o.y + 1.5)
	for k in range(3):
		draw_rect(Rect2(M + Vector2(-34 + k * 28, -14 + (k % 2) * 6), Vector2(8, 22 - k * 5)), Color("6a6a55"))
	var next: Variant = sim.next_shop()
	var is_next: bool = next != null and next.id == shop.id
	_text(M + Vector2(0, -34), shop.name if is_next else "무너진 집", 15,
		Color("4a4232") if is_next else C.ruin)
	if is_next:
		var can: bool = sim.money >= shop.cost
		_chip(M + Vector2(0, 4), 104, 25, C.jade if can else Color(0.47, 0.47, 0.37))
		_text(M + Vector2(0, 21), "🪙" + Num.fmt(shop.cost), 13, Color.WHITE)

## 마당 바닥·담·현판 — 항상 맨 뒤에 깔린다
func _plot_base(i: int, n: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var col := Color(shop.color)
	var o: Vector2i = Iso.org(sim, i)
	var N: Vector2 = Iso.w(o.x, o.y)
	var E: Vector2 = Iso.w(o.x + n, o.y)
	var S: Vector2 = Iso.w(o.x + n, o.y + n)
	var W: Vector2 = Iso.w(o.x, o.y + n)
	_quad(N, E, S, W, C.yardfloor)
	_outline(N, E, S, W, _shade(col, 0.16), 2.0)

	# 담은 뒤 두 변에만. 앞에 세우면 마당 안이 가려진다.
	for pair in [[W, N], [N, E]]:
		var A: Vector2 = pair[0]
		var B: Vector2 = pair[1]
		_quad(A, B, B + Vector2(0, -16), A + Vector2(0, -16), _shade(col, -0.03))
		draw_line(A + Vector2(0, -16), B + Vector2(0, -16), _shade(col, 0.10), 3.0)

	# 현판 — 등급은 여기에만 적는다
	var rk: int = sim.rank_of(shop.id)
	var s_txt: String = "%s %s" % [shop.sign, shop.name]
	if rk > 0:
		s_txt += " · " + String(shop.ranks[rk])
	var sw: float = 30.0 + s_txt.length() * 13.0
	draw_rect(Rect2(N + Vector2(-3, -44), Vector2(6, 44)), C.wood2)
	_chip(N + Vector2(0, -66), sw, 26, col)
	_text(N + Vector2(0, -48), s_txt, 15, Color("fff8ec"))

	var cap: int = sim.stall_cap(shop.id)
	if shop.items.size() > cap:
		_text(S + Vector2(0, 20), "승급하면 매대 +2", 12, Color(0.17, 0.14, 0.11, 0.55))

	# 들어가서 좋은 일이 있을 때만 표 — 숙제가 아니라 초대장
	if sim.shop_todo(shop.id) > 0:
		var bob: float = sin(_t * 4.0) * 3.0
		var promo: bool = sim.can_promote(shop.id)
		var txt: String = "승급!" if promo else ("일손!" if sim.can_hire_staff(shop.id) else "새 칸!")
		_chip(N + Vector2(0, -100 + bob), 26.0 + txt.length() * 14.0, 25, C.red if promo else C.jade)
		_text(N + Vector2(0, -82 + bob), txt, 15, Color("fff3dd"))

func _kiln(i: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var col := Color(shop.color)
	var o: Vector2i = Iso.org(sim, i)
	var k: Vector2i = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)).kiln
	var p: Vector2 = Iso.w(o.x + k.x + 0.5, o.y + k.y + 0.5)
	_box(o.x + k.x + 0.22, o.y + k.y + 0.22, 0.56, 0.56, 26, _shade(col, 0.10), _shade(col, -0.07))
	var fl: float = 0.6 + absf(sin(_t * 3.0 + i)) * 0.4
	draw_circle(p + Vector2(0, -30), 5.0 * fl, Color("f0a24b"))
	draw_circle(p + Vector2(0, -36), 3.0 * fl, Color("f6d27a"))

## 매대 한 칸 = 좌대 + 재고·진행 계기 + 이름패
func _stall(i: int, k: int, spot: Vector2i) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var o: Vector2i = Iso.org(sim, i)
	var p: Vector2 = Iso.w(o.x + spot.x + 0.5, o.y + spot.y + 0.5)
	var it: Dictionary = shop.items[k]

	if not sim.is_open(it.id):
		var N: Vector2 = Iso.w(o.x + spot.x, o.y + spot.y)
		var E: Vector2 = Iso.w(o.x + spot.x + 1, o.y + spot.y)
		var S: Vector2 = Iso.w(o.x + spot.x + 1, o.y + spot.y + 1)
		var W: Vector2 = Iso.w(o.x + spot.x, o.y + spot.y + 1)
		_outline(N, E, S, W, Color(0.24, 0.2, 0.14, 0.45), 1.6)
		if sim.asked.has(it.id):
			var can: bool = sim.money >= it.cost
			_text(p + Vector2(0, -26), String(it.name), 13, C.ink2)
			_chip(p + Vector2(0, -16), 76, 21, C.jade if can else Color(0.24, 0.2, 0.14, 0.32))
			_text(p + Vector2(0, -1), "🪙" + Num.fmt(it.cost), 12, Color.WHITE)
		else:
			_text(p + Vector2(0, -8), "? ? ?", 13, Color(0.24, 0.2, 0.14, 0.5))
		return

	var st: Dictionary = sim.items[it.id]
	var cap: float = sim.cap_of(it.id)
	var shown: float = min(cap, st.stock)
	var capped: bool = shown >= cap

	# 매대(좌판) — 가게마다 다르게 생겼다. 대장간은 모루 받침, 필방은 낮은 서안…
	# 그림이 없으면 여태처럼 나무 상자를 그린다.
	var table: Texture2D = Art.ranked("stalls", String(shop.id), sim.rank_of(String(shop.id)))
	if table != null:
		_sprite(table, p + Vector2(0, 14), "stalls")
	else:
		_box(o.x + spot.x + 0.14, o.y + spot.y + 0.14, 0.72, 0.72, 14, C.paper, C.wood)
	# 등급이 오르면 그림도 바뀐다 — 그 등급 그림이 있으면 그것,
	# 없으면 기본 그림에 **등급 테**를 둘러 표시한다(무쇠→참쇠→강철).
	var rk: int = sim.rank_of(String(shop.id))
	if rk > 0:
		draw_arc(p + Vector2(0, -8), 21.0, 0, TAU, 26, RANK_RING[min(rk, RANK_RING.size() - 1)], 3.0)
	var pic: Texture2D = Art.ranked("items", String(it.id), rk)
	if pic != null:
		_sprite(pic, p + Vector2(0, -6), "items")
	else:
		_text(p + Vector2(0, -6), String(it.icon), 22, Color.WHITE)

	# 재고·진행 계기
	var ry: Vector2 = p + Vector2(12, -46)
	var pr: float = 1.0 if capped else clampf(st.prog / sim.craft_time(it.id), 0.0, 1.0)
	draw_circle(ry, 12.0, Color(0.99, 0.96, 0.91, 0.95))
	draw_arc(ry, 15.0, 0, TAU, 24, Color(0.17, 0.14, 0.11, 0.30), 3.5)
	if pr > 0.01:
		draw_arc(ry, 15.0, -PI / 2, -PI / 2 + TAU * pr, 24,
			Color("ff8a63") if capped else Color("e8b93f"), 3.5)
	_text(ry + Vector2(0, 6), str(int(shown)), 16, C.ink)

	var nm: String = String(it.name)
	_chip(p + Vector2(0, 8), 14.0 + nm.length() * 12.0, 18, Color(0.17, 0.14, 0.11, 0.78))
	_text(p + Vector2(0, 21), nm, 12, Color("fff8ec"))

func _counter(i: int) -> void:
	var o: Vector2i = Iso.org(sim, i)
	var ct: Vector2i = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)).counter
	_box(o.x + ct.x + 0.16, o.y + ct.y + 0.3, 0.68, 0.4, 18, C.paper2, C.wood2)
	var p: Vector2 = Iso.w(o.x + ct.x + 0.5, o.y + ct.y + 0.5)
	draw_circle(p + Vector2(8, -24), 4.5, Color("c9a227"))

func _small(i: int) -> void:
	var t: Vector2i = Iso.SMALL_T[i]
	var def: Dictionary = Content.SMALL_SHOPS[i]
	var p: Vector2 = Iso.w(t.x + 1, t.y + 1)
	if not sim.smalls.has(i):
		var N: Vector2 = Iso.w(t.x, t.y)
		var E: Vector2 = Iso.w(t.x + 1, t.y)
		var W: Vector2 = Iso.w(t.x, t.y + 1)
		_outline(N, E, p, W, Color(0.24, 0.2, 0.14, 0.4), 2.0)
		_text(p + Vector2(0, -Iso.TH - 16), String(def.name) + " 자리", 12, C.ruin)
		var can: bool = sim.money >= def.cost
		_chip(p + Vector2(0, -Iso.TH - 8), 84, 21, C.jade if can else Color(0.24, 0.2, 0.14, 0.3))
		_text(p + Vector2(0, -Iso.TH + 7), "🪙" + Num.fmt(def.cost), 12,
			Color.WHITE if can else Color("e6e0cf"))
		return
	# 흙마당(발 밑) → 벽 → 벽보다 넓게 나온 처마. 이 순서가 '땅에 서 있다'를 만든다.
	_pad(t.x, t.y)
	_box(t.x + 0.16, t.y + 0.16, 0.68, 0.68, 19, C.paper2, C.wood)
	_box(t.x + 0.02, t.y + 0.02, 0.96, 0.96, 9, Color("8a6647"), Color("6b4c33"), 19)
	_chip(p + Vector2(0, -46), 64, 17, Color(0.17, 0.14, 0.11, 0.85))
	_text(p + Vector2(0, -33), String(def.name), 11, Color("fff8ec"))
	if sim.busy == i:
		var bob: float = sin(_t * 5.0) * 4.0
		_chip(p + Vector2(0, -96 + bob), 68, 24, C.red)
		_text(p + Vector2(0, -79 + bob), "장 서다!", 13, Color("fff3dd"))

func _dog() -> void:
	var t: Vector2i = Iso.DOG_T
	var p: Vector2 = Iso.w(t.x + 1, t.y + 1)
	if not sim.guard:
		var N: Vector2 = Iso.w(t.x, t.y)
		var E: Vector2 = Iso.w(t.x + 1, t.y)
		var W: Vector2 = Iso.w(t.x, t.y + 1)
		_outline(N, E, p, W, Color(0.24, 0.2, 0.14, 0.4), 2.0)
		_text(p + Vector2(0, -Iso.TH - 16), "삽살개 자리", 12, C.ruin)
		var can: bool = sim.money >= Content.GUARD.cost
		_chip(p + Vector2(0, -Iso.TH - 8), 80, 21, C.jade if can else Color(0.24, 0.2, 0.14, 0.3))
		_text(p + Vector2(0, -Iso.TH + 7), "🪙" + Num.fmt(Content.GUARD.cost), 12,
			Color.WHITE if can else Color("e6e0cf"))
		return
	_pad(t.x, t.y)
	_box(t.x + 0.18, t.y + 0.18, 0.64, 0.64, 19, C.paper2, Color("d8c9a3"))
	_box(t.x + 0.06, t.y + 0.06, 0.88, 0.88, 8, Color("8a6647"), Color("6b4c33"), 19)
	draw_circle(p + Vector2(0, -13), 6.5, C.ink)
	var bob: float = absf(sin(_t * 12.0)) * 3.0 if sim.pest != null else sin(_t * 2.0) * 1.2
	var pic: Texture2D = Art.tex("pests", "dog")
	if pic != null:
		_sprite(pic, p + Vector2(-18, 6 - bob), "pests")
	else:
		_text(p + Vector2(-26, 4 - bob), "🐕", 24, Color.WHITE)

## 그림 한 장을 **발끝 기준**으로 놓는다. 그림 주문서에도 "발끝이 아래 변에
## 닿게"라고 적어 둔 이유가 이것이다 — 발끝이 곧 그 물건이 서 있는 자리이고,
## 앞뒤 가리기(깊이)도 발끝 높이로 정한다.
func _sprite(t: Texture2D, foot: Vector2, kind: String, flip: bool = false) -> void:
	var sz: Vector2 = Art.SIZE[kind]
	var r := Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz)
	if flip:
		# 그림은 오른쪽 보는 것 한 장만 받는다. 왼쪽은 여기서 뒤집는다 —
		# 두 장씩 그리게 하면 장수가 두 배가 되고, 둘이 미묘하게 달라진다.
		draw_texture_rect_region(t, Rect2(r.position + Vector2(sz.x, 0), Vector2(-sz.x, sz.y)),
			Rect2(Vector2.ZERO, t.get_size()))
	else:
		draw_texture_rect(t, r, false)

## 너구리 한 마리 — 몸통·귀·눈가 무늬. 그림이 없을 때 그리는 임시 도형이다.
func _raccoon(p: Vector2, size: float, tint: Color) -> void:
	var bob: float = sin(_t * 6.0 + p.x * 0.05) * 1.5
	var at: Vector2 = p + Vector2(0, bob)
	draw_circle(at + Vector2(0, -2), size * 0.42, Color(0, 0, 0, 0.16))     # 발밑 그림자
	draw_circle(at + Vector2(0, -size * 0.42), size * 0.34, tint)            # 몸통
	draw_circle(at + Vector2(0, -size * 0.86), size * 0.30, _shade(tint, 0.06))  # 머리
	draw_circle(at + Vector2(-size * 0.22, -size * 1.06), size * 0.11, tint)     # 귀
	draw_circle(at + Vector2(size * 0.22, -size * 1.06), size * 0.11, tint)
	draw_circle(at + Vector2(-size * 0.11, -size * 0.90), size * 0.09, Color(0.17, 0.14, 0.11, 0.85))
	draw_circle(at + Vector2(size * 0.11, -size * 0.90), size * 0.09, Color(0.17, 0.14, 0.11, 0.85))

## 이 가게가 **할 일이 없나** — 열린 물건이 전부 진열대까지 찼으면 존다.
## 이게 있어야 "더 만들 데가 없다"가 화면으로 보인다(늘리라는 신호다).
func _idle(i: int) -> bool:
	var any: bool = false
	for it in Content.SHOPS[i].items:
		if not sim.is_open(it.id):
			continue
		any = true
		if sim.items[it.id].stock < sim.cap_of(it.id):
			return false
	return any

## 점장 그림 — **가게 것이 있으면 가게 것**, 없으면 공통 점장.
## 대장간 너구리는 망치를 들고, 필방 너구리는 앞치마를 두르는 식이다.
## 한 장도 없으면 도형으로 그린다. 어디서 멈춰도 게임은 돈다.
## 가게 등급도 본다 — `smith-make-1.png`가 있으면 참쇠 대장간 점장은 그걸 쓴다.
## 없으면 그 가게 점장, 그것도 없으면 공통 점장. **세 겹 다 없으면 도형이다.**
func _hero_tex(shop_id: String, pose: String) -> Texture2D:
	var t: Texture2D = Art.ranked("clerks", "%s-%s" % [shop_id, pose], sim.rank_of(shop_id))
	if t != null:
		return t
	return Art.tex("hero", "raccoon-" + pose)

func _clerk(i: int) -> void:
	var c: Dictionary = clerks[i]
	var pose: String = "make"
	if c.busy > 0.0:
		pose = "sell"
	elif c.walking:
		pose = "walk1" if fmod(_t * 5.0, 2.0) < 1.0 else "walk2"
	elif _idle(i):
		pose = "sleep"
	var id: String = String(Content.SHOPS[i].id)
	var t: Texture2D = _hero_tex(id, pose)
	if t == null:                       # 그 자세가 아직 없으면 만드는 자세로
		t = _hero_tex(id, "make")
	if t != null:
		_sprite(t, c.pos, "clerks" if Art.tex("clerks", "%s-%s" % [id, pose]) != null else "hero")
		return
	_raccoon(c.pos, SHAPE, Color("a8815a"))

## 직원 — 작업대 옆에 서서 계속 만든다.
##
## ★ 자바스크립트판에는 있었는데 옮기면서 빠져 있었다. 직원을 뽑아도
##   화면에는 아무도 안 나타났다 — 돈만 나가고 아무 일도 안 일어나는,
##   제일 나쁜 종류다. (예전에 자리가 0개라 안 보이던 것과 같은 증상이고,
##   그때 자리 규칙은 고쳤는데 **그리는 쪽을 안 옮겼다.**)
## 직원이 실제로 설 자리. **칸 한가운데가 아니라 마당 안쪽으로 당긴다.**
##
## ★ 3×3 마당에서 직원 자리는 담벼락 칸밖에 안 남는데, 그 앞에는 매대가 선다.
##   칸 한가운데에 세웠더니 매대 뒤에 가려서 **머리만 보였다.** 480K를 주고
##   머리 하나를 사는 셈이다. 안쪽으로 26px 당기면 매대 앞으로 나온다.
##   앞뒤 순서도 이 자리로 정해야 한다 — 안 그러면 그림과 순서가 따로 논다.
func _staff_pos(i: int, k: int) -> Vector2:
	var n: int = Iso.plot_dim(sim, i)
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], n)
	var spots: Array = Iso.staff_spots(y, n)
	var o: Vector2i = Iso.org(sim, i)
	var sp: Vector2i = spots[k]
	var p: Vector2 = Iso.w(o.x + sp.x + 0.5, o.y + sp.y + 0.5)
	var center: Vector2 = Iso.w(o.x + n * 0.5, o.y + n * 0.5)
	if p.distance_to(center) > 34.0:
		p += (center - p).normalized() * 26.0
	return p

func _staff(i: int, k: int) -> void:
	var spots: Array = Iso.staff_spots(Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)), Iso.plot_dim(sim, i))
	if k >= spots.size():
		return
	var p: Vector2 = _staff_pos(i, k)
	var idle: bool = _idle(i)
	# 망치질 — 할 일이 있을 때만 들썩인다. 다 찼으면 가만히 있는다.
	var swing: float = maxf(0.0, sin(fmod(_t / 2.4 + i * 0.37 + (k + 1) * 0.29, 1.0) * TAU))
	var bob: float = 0.0 if idle else swing * 3.0
	var rank: String = String(Content.STAFF_RANKS[0].id)     # 아직 등급 규칙이 없다 — 전부 알바
	var t: Texture2D = Art.tex("staff", "%s-%s" % [rank, "sleep" if idle else "work"])
	if t == null:
		t = Art.tex("staff", "%s-work" % rank)
	if t != null:
		_sprite(t, p + Vector2(0, -bob), "staff")
		return
	# 그림이 오기 전 임시 도형. 점장과 **같은 크기**로, 털빛만 조금 다르게.
	_raccoon(p + Vector2(0, -bob), SHAPE, Color("bfa987"))

func _walker(wk: Dictionary) -> void:
	var t: Texture2D = Art.tex("guests", String(wk.get("id", "")))
	if t != null:
		_sprite(t, wk.pos, "guests")
	else:
		_raccoon(wk.pos, SHAPE * 0.9, Color("9c8f7a"))
		_text(wk.pos + Vector2(0, -58), wk.face, 20, Color.WHITE)
	if wk.state != "buy":
		return
	var bob: float = sin(_t * 5.2) * 2.0
	# 💢 = **빈손으로 돌아간다.** 계산대 앞에 서 본 뒤에만 띄운다 —
	# 걸어 들어올 때부터 화가 나 있으면 '묻지도 않았는데 왜 화났지'가 된다.
	if wk.empty:
		if wk.wait > 0.0:
			_text(wk.pos + Vector2(15, -46 + bob), "💢", 19, Color.WHITE)
		return
	# 😠 = **지금 줄에서 기다리는 중**. 제 차례가 오면 바로 푼다 — 물건을
	# 받아 들고도 화난 얼굴이 남아 있으면 그것도 '왜 화났지'가 된다.
	if wk.qwait > Content.SERVICE.linePatience:
		_text(wk.pos + Vector2(15, -44 + bob), "😠", 17, Color.WHITE)
	_order(wk)

## 주문표 — **무엇을 몇 개 사러 왔는지.**
##
## ★ 여기에 값(🪙)을 띄우고 있었다. 그런데 그건 아직 안 일어난 일이다 —
##   줄에 선 손님 머리 위의 돈은 "얼마 낼 사람"이라는 뜻이 되고, 정작
##   "무엇을 원하는지"는 어디에도 안 보였다. 원하는 것을 띄우고,
##   값은 팔린 순간에 계산대 위로 띄운다(floats).
func _order(wk: Dictionary) -> void:
	var sold: Array = wk.sold
	if sold.is_empty():
		return
	# 줄이 길 때 전부 띄우면 주문표끼리 겹쳐 어느 것도 안 읽힌다.
	# **맨 앞사람만** — 줄을 세운 이유의 절반이 이것이다(자바스크립트판에서 얻은 답).
	if line[wk.shop].find(wk) != 0:
		return
	var show: int = min(3, sold.size())
	var more: int = sold.size() - show
	var wd: float = 18.0 + show * 40.0 + (26.0 if more > 0 else 0.0)
	var y: Vector2 = wk.pos + Vector2(0, -78 + sin(_t * 3.4) * 1.6)
	_chip(y, wd, 24, Color(0.99, 0.96, 0.91, 0.95))
	var x: float = y.x - wd * 0.5 + 12.0
	for i in range(show):
		var sg: Dictionary = sold[i]
		var pic: Texture2D = Art.ranked("items", String(sg.id), sim.rank_of(String(Content.SHOPS[wk.shop].id)))
		if pic != null:
			draw_texture_rect(pic, Rect2(Vector2(x - 2, y.y + 2), Vector2(16, 18)), false)
		else:
			_text(Vector2(x + 6, y.y + 18), String(sg.icon), 14, Color.WHITE)
		_text(Vector2(x + 26, y.y + 18), str(int(sg.n)), 13, C.ink)
		x += 40.0
	if more > 0:
		_text(Vector2(x + 10, y.y + 18), "+%d" % more, 12, C.ink2)

## 물어보는 말풍선 — 현판 바로 위. 깊이 정렬 밖에 그린다(지붕에 가리면 못 읽는다).
func _bubble() -> void:
	var o: Vector2i = Iso.org(sim, int(bubble.idx))
	# 현판(N.y−72 ~ −40)보다 위에. 처음에 −86으로 뒀더니 말풍선이 현판을 덮어
	# 가게 이름이 안 보였다 — 꼬리 끝까지 재서 띄운다.
	var n: Vector2 = Iso.w(o.x, o.y) + Vector2(0, -116)
	var txt: String = "%s %s" % [bubble.face, bubble.text]
	var a: float = minf(1.0, float(bubble.t))       # 사라질 땐 옅어진다
	_chip(n, 28.0 + txt.length() * 12.0, 28, Color(1.0, 0.965, 0.847, a))
	draw_colored_polygon(PackedVector2Array([n + Vector2(-6, 27), n + Vector2(6, 27),
		n + Vector2(0, 36)]), Color(1.0, 0.965, 0.847, a))
	_text(n + Vector2(0, 19), txt, 13, Color(C.ink, a))

## 나쁜 놈이 지금 어디 있나. 없으면 빈 딕셔너리.
##
## 까마귀는 **카메라 한가운데를 기준으로** 가로지른다. 마을 어디를 보고 있든
## 눈에 들어와야 누를 수 있기 때문이다 — 화면 밖에서 훔쳐 가면 장치를 넣은
## 이유가 사라진다. 쥐는 반대로 **훔치는 가게 앞**에 나온다. 어느 가게가
## 털리는지가 보여야 한다.
func pest_at(cam_center: Vector2) -> Dictionary:
	if sim == null or sim.pest == null:
		return {}
	var t: Dictionary = sim.pest
	var p: float = 1.0 - max(0.0, t.left) / t.life
	if t.kind == "crow":
		var dir: float = 1.0 if int(t.get("amount", 0)) % 2 == 1 else -1.0
		var u: float = p * 2.0 - 1.0
		var e: float = 0.5 + 0.5 * (u * 0.3 + u * u * u * 0.7)
		return {"kind": "crow", "face": "🐦‍⬛", "r": 30.0,
			"pos": cam_center + Vector2(dir * (e - 0.5) * 760.0, -160.0 + sin(p * PI * 2.4) * 70.0)}
	var idx: int = 0
	for i in range(Content.SHOPS.size()):
		for it in Content.SHOPS[i].items:
			if it.id == t.get("itemId", ""):
				idx = i
	var f: Dictionary = Iso.foot(sim, idx)
	var heart: Vector2 = Iso.w(Iso.GW * 0.5, Iso.GH * 0.5)
	return {"kind": "rat", "face": "🐀", "r": 32.0,
		"pos": f.stand + (heart - f.stand) * p * 0.5}

func _pest(t: Dictionary) -> void:
	var fly: bool = t.kind == "crow"
	var bob: float = sin(_t * 11.0) * 5.0 if fly else absf(sin(_t * 16.0)) * 4.0
	var at: Vector2 = t.pos + Vector2(0, -6 - bob)
	draw_circle(at, t.r - 3.0, Color(1, 0.96, 0.91, 0.55))
	# 남은 시간이 줄어드는 테두리 — 언제까지 누를 수 있는지가 보여야 한다
	draw_arc(at, t.r, 0, TAU, 28, Color(0.64, 0.29, 0.23, 0.28), 4.0)
	var left: float = clampf(sim.pest.left / sim.pest.life, 0.0, 1.0)
	draw_arc(at, t.r, -PI / 2, -PI / 2 + TAU * left, 28, C.red, 4.0)
	var pic: Texture2D = Art.tex("pests", String(sim.pest.kind))
	if pic != null:
		_sprite(pic, at + Vector2(0, 22), "pests")
	else:
		_text(at + Vector2(0, 9), t.face, 26, Color.WHITE)

# ── 한 판 ──
func _draw() -> void:
	if sim == null:
		return
	# 바닥. 마을 밖으로 두 칸 더 깐다 — **바깥이 있어야 가장자리 가게를
	# 화면 가운데로 끌어올 수 있다.** 딱 맞게 깔면 끝 칸에서 더는 못 밀고,
	# 그 가게는 늘 화면 구석에 붙어 있게 된다(줌을 키우면 더 답답하다).
	for ty in range(-Iso.EDGE, Iso.GH + Iso.EDGE):
		for tx in range(-Iso.EDGE, Iso.GW + Iso.EDGE):
			_tile(tx, ty, Iso.is_road(tx, ty))

	# 깊이 순서대로 — 아래 꼭짓점 y가 큰 것이 앞이다
	var layer: Array = []
	var seq: int = 0
	for p in _props:
		layer.append({"z": Iso.w(p.t.x + 1, p.t.y + 1).y, "i": seq, "f": _prop.bind(p)})
		seq += 1
	for i in range(Content.SHOPS.size()):
		var o: Vector2i = Iso.org(sim, i)
		var n: int = Iso.plot_dim(sim, i)
		if not sim.shops.has(String(Content.SHOPS[i].id)):
			layer.append({"z": Iso.w(o.x + 3, o.y + 3).y, "i": seq, "f": _ruin.bind(i)})
			seq += 1
			continue
		# 마당 바닥은 맨 뒤로, 가구는 하나하나 자기 발끝 z로 따로 세운다 —
		# 한 덩어리로 그리면 가구가 마당 안에 선 손님·점장을 덮는다.
		layer.append({"z": Iso.w(o.x, o.y).y + 2.0, "i": seq, "f": _plot_base.bind(i, n)})
		seq += 1
		var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], n)
		layer.append({"z": Iso.w(o.x + y.kiln.x + 1, o.y + y.kiln.y + 1).y, "i": seq, "f": _kiln.bind(i)})
		seq += 1
		var cap: int = min(sim.stall_cap(String(Content.SHOPS[i].id)), Content.SHOPS[i].items.size())
		for k in range(cap):
			var sp: Vector2i = y.stalls[k]
			layer.append({"z": Iso.w(o.x + sp.x + 1, o.y + sp.y + 1).y, "i": seq, "f": _stall.bind(i, k, sp)})
			seq += 1
		layer.append({"z": Iso.w(o.x + y.counter.x + 0.84, o.y + y.counter.y + 0.7).y, "i": seq,
			"f": _counter.bind(i)})
		seq += 1
	for i in range(Content.SMALL_SHOPS.size()):
		layer.append({"z": Iso.w(Iso.SMALL_T[i].x + 1, Iso.SMALL_T[i].y + 1).y, "i": seq, "f": _small.bind(i)})
		seq += 1
	layer.append({"z": Iso.w(Iso.DOG_T.x + 1, Iso.DOG_T.y + 1).y, "i": seq, "f": _dog})
	seq += 1
	# 너구리들 — 발끝 y로 선다. 그래야 계산대 뒤에 서면 가려지고 앞에 서면 가린다.
	for i in range(Content.SHOPS.size()):
		if not sim.shops.has(String(Content.SHOPS[i].id)):
			continue
		layer.append({"z": clerks[i].pos.y + 0.5, "i": seq, "f": _clerk.bind(i)})
		seq += 1
		var spots: Array = Iso.staff_spots(Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)), Iso.plot_dim(sim, i))
		for k in range(min(int(sim.staff_of(String(Content.SHOPS[i].id))), spots.size())):
			layer.append({"z": _staff_pos(i, k).y, "i": seq, "f": _staff.bind(i, k)})
			seq += 1
	for wk in walkers:
		layer.append({"z": wk.pos.y, "i": seq, "f": _walker.bind(wk)})
		seq += 1

	# 같은 z일 때 순서가 흔들리면 화면이 깜빡인다 — 넣은 차례로 못 박는다
	layer.sort_custom(func(a, b): return a.z < b.z if a.z != b.z else a.i < b.i)
	for e in layer:
		e.f.call()
	for f in floats:
		var a: float = clampf(f.t, 0.0, 1.0)
		_chip(f.pos, 22.0 + String(f.text).length() * 11.0, 21, Color(0.17, 0.14, 0.11, 0.82 * a))
		_text(f.pos + Vector2(0, 15), String(f.text), 12, Color(0.99, 0.91, 0.66, a))
	if not bubble.is_empty():
		_bubble()
	# 나쁜 놈은 **늘 맨 앞**에 그린다. 지붕 뒤에 숨으면 누를 수가 없다.
	var th: Dictionary = pest_at(cam_center)
	if not th.is_empty():
		_pest(th)
