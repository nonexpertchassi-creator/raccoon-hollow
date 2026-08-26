extends Node2D
class_name Village
## 격자 마을을 그린다. **경제 계산이 한 줄도 없다** — sim을 읽기만 하고
## 절대 고치지 않는다. iso.js와 같은 규칙이다.
##
## 지금은 Godot의 _draw()로 도형을 직접 그린다. 그림(스프라이트)이 나오면
## 이 자리에 하나씩 갈아 끼우면 된다 — 배치와 깊이 순서는 그대로 쓴다.

var sim: Sim

const C := {
	# ★ 2026-08-25 '볕 좋은 장날' 톤. 화면의 8할이 바닥이라 게임의 인상은
	#   바닥색이 정한다 — 잿빛 올리브(8b9e74)였을 때 그림이 좋아도 우중충했다.
	#   기준 그림은 까치 카드다: 카드 속 세상과 마을이 같은 세상으로 보여야 한다.
	#   사계절이 들어오면 이 덩어리가 '봄' 색표가 되고 계절마다 갈아 끼운다.
	"grass": Color("b3cc88"), "grass2": Color("a9c17e"), "road": Color("efe0b4"),
	"paper": Color("ece2cb"), "paper2": Color("dccfb2"), "wood": Color("8a6a45"),
	"wood2": Color("6d5236"), "ink": Color("2b241b"), "ink2": Color("5a4e3d"),
	"gold": Color("a8763e"), "jade": Color("4a7c59"), "red": Color("c7563f"),
	"ruin": Color("5f6b4e"), "dirt": Color("cdb88d"), "yardfloor": Color("decfab"),
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

var _grng: Rng = Rng.new(20260821)
## 구역이 열리는 순간의 안개 걷힘. 구역 id → 남은 안개(1→0으로 줄어든다).
## 툭 사라지면 "열렸다"는 순간이 없다 — 1.4초에 걸쳐 걷힌다.
var _zoneFade: Dictionary = {}

func reveal_zone(id: String) -> void:
	_zoneFade[id] = 1.0
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

## 촌장 너구리 — **마당 밖으로 나오는 유일한 너구리**다.
## 길을 따라 마을을 돌아다니고, 걸린 의뢰가 있으면 머리 위에 ❗를 띄운다.
## 누르면 의뢰 창이 열린다.
##
## ★ 여기 있는 것은 **화면뿐**이다. sim은 한 줄도 안 건드린다.
##   촌장이 경제(돈·젬)를 만지는 순간 대조 시험이 그 자리에서 깨진다 —
##   자바스크립트 답안지에는 촌장이 없기 때문이다. 그 이야기는 FLOW.md에 적었다.
var mayor: Dictionary = {}
const MAYOR_SPEED := 62.0
## 삽살개들 — 개집에 앉아만 있었는데(유저: "안 움직이는 것 같다") 이제
## 마을 길을 돈다. 화면 전용이다 — 무는 판정은 여전히 sim의 주사위가 한다.
var dogs: Array = []
const DOG_SPEED := 88.0
## 길에 떨어지는 쓰레기(낙엽·검불). **화면 전용이다** — 아직 돈·젬은 안 나온다.
## 보상을 붙이는 순간 경제가 되고, 그때는 재는 도구가 마을을 같이 돌려야 한다
## (FLOW.md §7의 갈림길). 지금은 촌장이 마을을 돌보는 게 **보이게만** 한다.
var trash: Array = []
var _trashAcc: float = 0.0

## 가게별 점장 — 평소엔 작업대, 팔릴 땐 계산대 뒤로 간다
var clerks: Array = []
## 직원의 현재 자리("가게:번호" → 좌표). 만드는 매대가 바뀌면 걸어서 옮긴다.
var _staffAt: Dictionary = {}
## 줄 도착 순번표 — 늘어나기만 하는 번호. 도착한 차례가 곧 줄 차례다.
var _lineSeq: int = 0
## 일감표 — 누가 어느 매대를 잡았나(점장: 가게번호→매대번호, 직원: "가게:직원"→매대번호).
## ★ 한 번 잡은 매대는 그 물건이 다 만들어질 때까지 안 놓는다(2026-08-25, 유저 —
##   "5번 자리에서 탭 댄스"). 만드는 목록이 출렁일 때마다 목표를 갈아타면
##   일꾼이 마당 가운데서 발만 동동 구른다.
var _heroJob: Dictionary = {}
var _staffJob: Dictionary = {}
## 마당 칸 번호(1~n²)를 바닥에 깐다 — "6번 매대" 같은 말이 통하게 하는
## **대화용 자**다(유저). G 키로 껐다 켠다. 내보내기 전에 기본값을 끈다.
var show_grid: bool = true
## 낮과 밤 — 도구가 시각을 못 박을 때 쓴다(0~1, 음수면 게임 시계를 따른다).
var clock_override: float = -1.0
## 날씨 — 도구가 못 박을 때 쓴다(""면 sim을 따른다).
var wx_override: String = ""

func wx() -> String:
	return wx_override if wx_override != "" else String(sim.weather)
const CLERK_SPEED := 130.0

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_props = _make_props()

func setup(s: Sim) -> void:
	sim = s
	clerks = []
	line = []
	for i in range(Content.SHOPS.size()):
		clerks.append({"pos": Iso.foot(sim, i).work, "at": "work", "busy": 0.0, "walking": false,
			"carry": 0.0, "carry_oid": 0, "carryQ": []})
		line.append([])
	var start: Vector2i = Iso.GATES[0]
	mayor = {"pos": Iso.w(start.x + 0.5, start.y + 0.5), "at": start,
		"path": [], "step": 1, "rest": 1.0}

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
		"n": int(sale.n), "gain": float(sale.gain), "sold": _order_of(sale, shop_id), "q": 0,
		"oid": int(sale.get("orderId", -1)), "ready": false, "leaveT": 0.9,
		"speed": float(sale.guest.get("speed", 1.0)), "off": (_grng.next() - 0.5) * 30.0,
	})
	line[idx].append(walkers[walkers.size() - 1])

## 주문이 완성됐다 — 만든 너구리가 상자를 들고 계산대로 가고, 손님은
## 받아서 떠난다. 예전엔 완료가 **두 번째 손님을 또 만들어냈다**(on_sale로
## 들어가서) — 주문 생산 전환(2026-08-26)에서 정리됐다.
func on_done(d: Dictionary) -> void:
	var oid: int = int(d.get("orderId", 0))
	for wk in walkers:
		if int(wk.get("oid", -1)) == oid:
			wk.gain = float(d.gain)
			# ★ 손님은 너구리가 상자를 들고 **계산대에 실제로 닿아야** 받는다
			#   (2026-08-26, 유저: "계산을 대각선에서 한다") — 예전엔 타이머라
			#   너구리가 마당 한가운데서 허공에 건네는 그림이 됐다.
			var c9: Dictionary = clerks[wk.shop]
			if int(c9.get("carry_oid", 0)) == 0:
				c9.carry_oid = oid
			else:
				(c9.carryQ as Array).append(oid)
			return

## 이 손님이 무엇을 몇 개 사러 왔나. 머리 위에 띄울 주문표다.
## 셋까지만 담는다 — 넷을 넘기면 말풍선이 손님보다 커져서 길을 덮는다.
##
## ★ **이 가게 물건만** 담는다(2026-08-25, 유저가 잡았다). 바구니에는 여러
##   가게 것이 섞여 있는데(계산은 sim이 한 번에 한다), 화면의 줄은 첫 물건의
##   가게 앞 하나뿐이다 — 필방 앞에서 낫과 국밥이 뜨면 오류로 보이는 게 맞다.
func _order_of(sale: Dictionary, shop_id: String) -> Array:
	var out: Array = []
	for l in sale.lines:
		if String(l.item.shop) != shop_id:
			continue
		out.append({"id": String(l.item.id), "icon": String(l.item.icon), "n": int(l.n)})
	return out

## 줄에서 **몇 번째인가.** 줄 번호는 **줄에 도착한 순서**(wk.q)로 센다.
##
## ★ 두 번 고쳤다. 처음엔 `line.find(wk)`(찜한 순서) — 앞사람이 길 위에
##   있는데 자리가 찜돼서 맨 앞이 비었다. 다음엔 "걸어오는 사람은 빼고
##   배열 순서" — 그런데 배열은 **마을에 나타난 순서**라, 느린 거북이
##   걸어오는 동안 빠른 토끼가 맨 앞에 섰다가 거북이 도착하면 **뒤로
##   밀려나는** 그림이 됐다(유저: "1번이 2번으로 밀린다"). 줄은 도착한
##   순서다 — 한 번 선 사람은 뒷사람 때문에 절대 안 밀린다.
func _line_index(wk: Dictionary) -> int:
	var n: int = 0
	for w in line[wk.shop]:
		if w != wk and w.state == "buy" and int(w.q) < int(wk.q):
			n += 1
	return n

func _walk(wk: Dictionary, delta: float) -> bool:
	var target: Vector2
	if wk.state == "buy":
		target = Iso.line_spot(sim, wk.shop, _line_index(wk))
	elif wk.step < wk.path.size():
		var t: Vector2i = wk.path[wk.step]
		# 길을 걸을 때만 좌우로 조금 흩뜨린다. 다들 한 줄로 겹쳐 걸으면
		# 열 마리가 한 마리처럼 보인다. 줄에 설 때는 안 흩뜨린다(줄이 흐트러진다).
		# 흩뜨림은 **가로로만**. 위아래로도 흩뜨렸더니 발끝(앞뒤 판정)이
		# 길가 매대와 어긋나서, 웃돈(+7)으로 때우는 악순환이 됐다.
		target = Iso.w(t.x + 0.5, t.y + 0.5) + Vector2(wk.off, 0)
	else:
		return true
	var d: Vector2 = target - wk.pos
	# 걷는 방향으로 몸을 돌린다. 왼쪽이면 뒤집고, **화면 위로 올라가면 뒷모습**을
	# 쓴다(-back 그림이 있으면). 옆모습만으로 때우려던 것을 유저가 되돌렸다 —
	# 등을 보이고 올라가는 짐승이 옆을 보면 어색한 게 맞다.
	if absf(d.x) > 0.5:
		wk.flip = d.x < 0.0
	if absf(d.y) > 0.2:
		wk.up = d.y < 0.0
	# 손님마다 걸음이 다르다 — 토끼는 빠르고 거북은 느리다.
	# 이 숫자는 content.js에 처음부터 있었는데 화면이 안 쓰고 있었다.
	var step: float = WALK * float(Content.GUEST_WALK) * float(wk.speed) * delta
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
	for zid in _zoneFade.keys():
		_zoneFade[zid] = float(_zoneFade[zid]) - delta / 1.4
		if float(_zoneFade[zid]) <= 0.0:
			_zoneFade.erase(zid)
	# 쓰레기 — 이따금 길에 하나씩, 셋까지
	_trashAcc += delta
	if _trashAcc >= 24.0 and trash.size() < 3:
		_trashAcc = 0.0
		var tsp: Vector2i = _road_spot()
		trash.append({"t": tsp, "pos": Iso.w(tsp.x + 0.5, tsp.y + 0.5)})
	# 일감 배정 — 잡은 매대가 아직 만드는 중이면 **그대로 유지**한다.
	# 목록 순서가 출렁여도 목표는 안 바뀐다 — 탭 댄스 방지의 핵심이다.
	for i in range(Content.SHOPS.size()):
		var sid5: String = String(Content.SHOPS[i].id)
		if not sim.shops.has(sid5):
			continue
		var ci5: Array = _craft_idx(i)
		var claimed: Dictionary = {}
		if clerks[i].busy > 0.0 or ci5.is_empty():
			_heroJob[i] = -1                 # 계산대 차례 — 일감을 놓는다
		else:
			var hj: int = int(_heroJob.get(i, -1))
			if not ci5.has(hj):
				hj = int(ci5[0])
			_heroJob[i] = hj
			claimed[hj] = true
		for k5 in range(int(sim.staff_of(sid5))):
			var kk: String = "%d:%d" % [i, k5]
			var sj: int = int(_staffJob.get(kk, -1))
			if not ci5.has(sj) or claimed.has(sj):
				sj = -1
				for cx in ci5:
					if not claimed.has(int(cx)):
						sj = int(cx)
						break
			_staffJob[kk] = sj
			if sj >= 0:
				claimed[sj] = true

	# 직원 — 만드는 매대 곁으로 걸어간다. 순간이동하면 "일하러 갔다"가 안 보인다.
	for i in range(Content.SHOPS.size()):
		if not sim.shops.has(String(Content.SHOPS[i].id)):
			continue
		for k in range(int(sim.staff_of(String(Content.SHOPS[i].id)))):
			var skey: String = "%d:%d" % [i, k]
			var goal: Vector2 = _staff_goal(i, k)
			var cur: Vector2 = _staffAt.get(skey, _staff_pos(i, k))
			_staffAt[skey] = cur.move_toward(goal, 52.0 * delta)
	_walk_mayor(delta)
	# 산 만큼 개를 풀어놓는다
	while dogs.size() < int(sim.guards):
		dogs.append({"pos": Iso.w(Iso.DOG_T.x + 0.5, Iso.DOG_T.y + 0.5),
			"at": Iso.nearest_road(Iso.DOG_T), "path": [], "step": 1,
			"rest": 0.5 + _grng.next() * 2.0, "flip": false})
	# 밤엔 절반만 순찰한다(유저) — 나머지는 그 자리에서 쉰다.
	# (쥐는 밤에 더 설친다 — sim의 밤 규칙. 개까지 다 재우면 벌만 받는 밤이 된다)
	var awake: int = dogs.size() if not _night() else int(ceil(dogs.size() / 2.0))
	for di in range(dogs.size()):
		if di < awake:
			_walk_dog(dogs[di], delta)
	var keep: Array = []
	for wk in walkers:
		match wk.state:
			"in":
				if _walk(wk, delta) and wk.step >= wk.path.size():
					wk.state = "buy"
					_lineSeq += 1
					wk.q = _lineSeq       # 줄 번호는 **도착한 순서**다(아래 _line_index 참고)
			"buy":
				if _walk(wk, delta):
					# 줄은 기다리는 곳이다 — 주문이 **완성돼야** 받아서 떠난다
					# (2026-08-26, 대기시간 폐지). 앞줄이 아니면 답답한 표정만.
					if _line_index(wk) >= sim.counters_of(String(Content.SHOPS[wk.shop].id)):
						wk.qwait += delta
					else:
						wk.qwait = 0.0
					if bool(wk.get("delivered", false)):
						wk.leaveT = float(wk.get("leaveT", 0.35)) - delta
						if wk.leaveT <= 0.0:
							wk.state = "out"
							if wk.gain > 0.0:
								# 엽전은 **팔린 순간**에만 뜬다
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
	# 점장 — **손님이 계산대에 닿아 있는 동안** 계산대 뒤에 선다.
	#
	# ★ 예전엔 sim이 "팔렸다"고 알리는 순간(=손님이 마을 입구에 생기는 순간)
	#   점장을 보냈다. 손님은 몇 초를 걸어와야 하는데 점장은 이미 가 있으니,
	#   **아무도 없는 계산대에서 물건을 옮기는** 그림이 됐다.
	#   폰에서 유저가 바로 알아챈 것이 이것이다.
	# 주문 생산(2026-08-26)에선 손님이 기다려도 너구리는 **만들러 간다** —
	# 계산 자세(busy)는 완성 상자를 나르는 순간(on_done)에만 걸린다.
	# 예전의 "줄에 손님이 있으면 계산대 붙박이"를 여기서 걷어냈다.
	for i in range(Content.SHOPS.size()):
		var c: Dictionary = clerks[i]
		c.busy = max(0.0, c.busy - delta)
		c.carry = max(0.0, float(c.get("carry", 0.0)) - delta)
		var f: Dictionary = Iso.foot(sim, i)
		# 점장도 직원처럼 **만드는 매대 앞**으로 간다. 작업대에 서 있는데
		# 저쪽 매대가 만들어지면 오류로 보인다(유저). 만들 게 없으면 작업대.
		# 줄에 손님이 남아 있으면 계산대를 안 떠난다 — 손님 사이마다 매대로
		# 갔다 오며 몸이 좌우로 홱홱 뒤집혔다(유저: "자세를 한가지로").
		var goal: Vector2 = f.serve
		var hjob: int = int(_heroJob.get(i, -1))
		if int(c.get("carry_oid", 0)) != 0:
			goal = f.serve                        # 상자를 들었다 — 계산대로
		elif c.busy <= 0.0:
			# 할 일이 없으면 **그 자리에서** 쉰다(유저: "마지막 지점에서
			# 머무는 게 자연스럽다"). 작업대로 돌아가 서 있으면 그것도
			# 손님을 기다리는 예지력처럼 보인다.
			goal = _stall_front(i, hjob) if hjob >= 0 else (c.pos if _idle(i) else f.work)
		# 계산 자리가 마당 안 칸(계산대의 안쪽 이웃)이 되면서 팔꿈치 경유는
		# 필요 없어졌다 — 빈 칸 사이 직선은 가구를 안 밟는다.
		var tgt: Vector2 = goal
		var d: Vector2 = tgt - c.pos
		var step: float = CLERK_SPEED * delta
		c.walking = d.length() > step        # 걷는 중이면 걷는 그림을 쓴다
		if c.walking and absf(d.y) > 0.2:
			c.up = d.y < 0.0                 # 위로 걸으면 뒷모습을 쓴다(3방향 계약)
		# 계산대 근처(30px)에서는 방향을 **절대 안 바꾼다** — 팔꿈치를 오가는
		# 짧은 걸음마다 좌우가 뒤집혀 파닥거렸다(유저가 두 번 잡았다).
		var near_ct: bool = c.pos.distance_to(f.serve) < 30.0
		if c.walking and absf(d.x) > 0.5 and not near_ct:
			c.flip = d.x < 0.0
		# ★ 길 쪽 보기 잠금은 **계산하러 왔을 때만**. 계산 자리(8번)는 매대
		#   7번의 작업 자리이기도 한데, 잠금이 만들 때도 길을 보게 해서
		#   "만드는 방향이 반대"가 됐다(유저).
		if near_ct and goal == f.serve:
			c.flip = String(f.yard.gate) == "y"    # 계산대에선 길 쪽을 본다
		elif not c.walking and hjob >= 0:
			c.flip = _stall_at(i, hjob).x < c.pos.x   # 매대 앞에선 매대를 본다
		c.pos = tgt if d.length() <= step else c.pos + d.normalized() * step
		# 상자가 계산대에 닿았다 — 이제야 손님이 받는다
		if int(c.get("carry_oid", 0)) != 0 and c.pos.distance_to(f.serve) < 10.0:
			for wk9 in line[i]:
				if int(wk9.get("oid", -1)) == int(c.carry_oid):
					wk9.delivered = true
					break
			c.carry_oid = 0 if (c.carryQ as Array).is_empty() else int((c.carryQ as Array).pop_front())
			c.carry = 0.5                          # 상자 잔상 + 계산 자세 한 박자
			c.busy = 0.8

## 촌장 걸음 — 길 위의 아무 데나 한 곳을 골라 걸어가고, 닿으면 잠깐 쉬었다 또 간다.
## 목적지를 마을 문(GATES)에서 고르면 늘 가장자리만 돌게 되므로 길 전체에서 고른다.
func _walk_mayor(delta: float) -> void:
	if mayor.is_empty():
		return
	# 닿은 자리에 쓰레기가 있으면 줍는다 — 비질 표가 잠깐 남는다
	for k in range(trash.size() - 1, -1, -1):
		if (trash[k].pos as Vector2).distance_to(mayor.pos) < 20.0:
			floats.append({"pos": trash[k].pos + Vector2(0, -24), "text": "🧹", "t": 1.0})
			trash.remove_at(k)
	if mayor.path.is_empty() or mayor.step >= mayor.path.size():
		mayor.rest -= delta
		if mayor.rest > 0.0:
			return
		# 쓰레기가 보이면 그리로 간다 — 마을 어른이 마을을 돌본다
		var to: Vector2i = (trash[0].t as Vector2i) if not trash.is_empty() else _road_spot()
		mayor.path = Iso.route(mayor.at, to)
		mayor.step = 1
		mayor.at = to
		mayor.rest = 1.4 + _grng.next() * 2.6
		if mayor.path.is_empty():
			mayor.at = _road_spot()
		return
	var t: Vector2i = mayor.path[mayor.step]
	var target: Vector2 = Iso.w(t.x + 0.5, t.y + 0.5)
	var d: Vector2 = target - mayor.pos
	if absf(d.x) > 0.5:
		mayor.flip = d.x < 0.0
	var step: float = MAYOR_SPEED * delta
	if d.length() <= step:
		mayor.pos = target
		mayor.step += 1
	else:
		mayor.pos += d.normalized() * step

func _walk_dog(dg: Dictionary, delta: float) -> void:
	if dg.path.is_empty() or dg.step >= dg.path.size():
		dg.rest -= delta
		if dg.rest > 0.0:
			return
		var to: Vector2i = _road_spot()
		dg.path = Iso.route(dg.at, to)
		dg.step = 1
		dg.at = to
		dg.rest = 0.8 + _grng.next() * 1.8
		return
	var t: Vector2i = dg.path[dg.step]
	var target: Vector2 = Iso.w(t.x + 0.5, t.y + 0.5)
	var d: Vector2 = target - dg.pos
	if absf(d.x) > 0.5:
		dg.flip = d.x < 0.0
	var step: float = DOG_SPEED * delta
	if d.length() <= step:
		dg.pos = target
		dg.step += 1
	else:
		dg.pos += d.normalized() * step

## 이 줄(ty)이 열린 동네인가 — 잠긴 구역(안개)은 촌장도 개도 안 들어간다.
func _open_row(ty: int) -> bool:
	for dz in Content.DISTRICTS:
		if not sim.zones.has(String(dz.id)) and ty >= int(dz.rows[0]) and ty <= int(dz.rows[1]):
			return false
	return true

func _road_spot() -> Vector2i:
	for _try in range(20):
		var tx: int = int(_grng.next() * Iso.GW) % Iso.GW
		var ty: int = int(_grng.next() * Iso.GH) % Iso.GH
		# 안개 속을 태연히 걸으면 잠김이 거짓말이 된다(유저) — 열린 동네만
		if Iso.is_road(tx, ty) and _open_row(ty):
			return Vector2i(tx, ty)
	return Iso.GATES[0]

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

## 바닥에 **누운** 십자 — 빈 자리 표시.
## 글자 "+"는 화면에 똑바로 서 있어서 바닥에 누운 느낌이 없었다(X로도 보였다).
## 마름모의 두 축을 따라 막대 두 개를 그리면 바닥에 붙어 보인다.
func _flat_plus(cx: float, cy: float, col: Color) -> void:
	for axis in [Vector2(0.30, 0.10), Vector2(0.10, 0.30)]:
		_quad(Iso.w(cx - axis.x, cy - axis.y), Iso.w(cx + axis.x, cy - axis.y),
			Iso.w(cx + axis.x, cy + axis.y), Iso.w(cx - axis.x, cy + axis.y), col)

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
			# 나무 세 종 — 같은 씨앗값(o)으로 종이 갈려서 심을 때 정해진다.
			# 사계절이 들어오면 색만 계절표로 갈아 끼운다(모양은 그대로).
			draw_rect(Rect2(at + Vector2(-3, -10), Vector2(6, 12)), C.wood2)
			if p.o < 0.5:
				# 둥근 활엽수
				draw_circle(at + Vector2(0, -22), 16.0 + p.o * 5.0, Color("7da35f"))
				draw_circle(at + Vector2(-7, -15), 10.0, Color("93b877"))
			elif p.o < 0.8:
				# 소나무 — 세모 셋을 쌓는다
				for tt in range(3):
					var wdt: float = 16.0 - tt * 4.0
					var base_y: float = -12.0 - tt * 9.0
					draw_colored_polygon(PackedVector2Array([
						at + Vector2(-wdt, base_y), at + Vector2(wdt, base_y),
						at + Vector2(0, base_y - 13.0)]), Color("5e8a52") if tt % 2 == 0 else Color("6f9c60"))
			else:
				# 떡갈나무 — 옆으로 퍼진 큰 나무
				draw_circle(at + Vector2(-9, -20), 11.0, Color("739757"))
				draw_circle(at + Vector2(9, -21), 12.0, Color("86ac68"))
				draw_circle(at + Vector2(0, -28), 13.0, Color("93b877"))
		"rock":
			draw_circle(at + Vector2(0, -4), 8.0 + p.o * 4.0, Color("8f8f7a"))
		_:
			for k in range(3):
				draw_circle(at + Vector2((k - 1) * 9, -4 - (k % 2) * 5), 3.0,
					Color("e5b8c4") if k % 2 == 1 else Color("efe3a8"))

# ── 가게 ──
func _ruin(i: int) -> void:
	# ★ '무너진 집'과 가게 이름은 지웠다(2026-08-25, 유저) — **무슨 가게가
	#   열릴지 미리 알리지 않는다.** 궁금함이 여는 이유가 된다.
	#   자리는 매대 빈 칸과 같은 말(9칸 빈 터 + 누운 십자)로 그린다.
	var shop: Dictionary = Content.SHOPS[i]
	var o: Vector2i = Iso.org(sim, i)
	var next: Variant = sim.next_shop()
	var is_next: bool = next != null and next.id == shop.id
	var can: bool = is_next and sim.money >= shop.cost
	for b in range(3):
		for a in range(3):
			var cN: Vector2 = Iso.w(o.x + a, o.y + b)
			var cE: Vector2 = Iso.w(o.x + a + 1, o.y + b)
			var cS: Vector2 = Iso.w(o.x + a + 1, o.y + b + 1)
			var cW: Vector2 = Iso.w(o.x + a, o.y + b + 1)
			_quad(cN, cE, cS, cW, Color(0.62, 0.78, 0.55, 0.25) if can else Color(0.45, 0.42, 0.36, 0.12))
			_outline(cN, cE, cS, cW, Color(0.4, 0.37, 0.3, 0.3), 1.2)
	_flat_plus(o.x + 1.5, o.y + 1.5, C.jade if can else Color(0.4, 0.37, 0.3, 0.5))
	var M: Vector2 = Iso.w(o.x + 1.5, o.y + 1.5)
	if is_next:
		_chip(M + Vector2(0, 16), 104, 25, C.jade if can else Color(0.47, 0.47, 0.37))
		_text(M + Vector2(0, 33), "🪙" + Num.fmt(shop.cost), 13, Color.WHITE)
	# 아직 아무 가게도 없다 = **막 시작한 사람**이다.
	# 이 한 칸이 튜토리얼의 전부다 — 어디를 눌러야 하는지만 알려주면
	# 나머지는 누르면서 알게 된다. 열리는 순간 이 표는 사라진다.
	if is_next and sim.shops.is_empty():
		var bob: float = absf(sin(_t * 3.2)) * 7.0
		_chip(M + Vector2(0, -96 - bob), 168, 27, C.red)
		_text(M + Vector2(0, -77 - bob), "여기부터 되살리세!", 14, Color("fff3dd"))
		# 아래를 가리키는 삼각형 — 글자만 있으면 어디를 누르라는 건지 애매하다
		draw_colored_polygon(PackedVector2Array([
			M + Vector2(-9, -69 - bob), M + Vector2(9, -69 - bob), M + Vector2(0, -56 - bob)]), C.red)

## 마당 바닥·담·현판 — 항상 맨 뒤에 깔린다
func _plot_base(i: int, n: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var col := Color(shop.color)
	var o: Vector2i = Iso.org(sim, i)
	var N: Vector2 = Iso.w(o.x, o.y)
	var E: Vector2 = Iso.w(o.x + n, o.y)
	var S: Vector2 = Iso.w(o.x + n, o.y + n)
	var W: Vector2 = Iso.w(o.x, o.y + n)
	# ★ 바닥도 등급 따라 자란다(2026-08-26, 유저): 모래 → 나무 마루 → 돌판.
	#   담(초가→돌담→기와)과 같은 원칙 — 승급이 창 안 숫자가 아니라
	#   마을 풍경에서 보여야 한다. 전부 코드 그림이라 그림 장수는 안 는다.
	var frank: int = sim.rank_of(shop.id)
	var o5: Vector2i = Iso.org(sim, i)
	match frank:
		0:
			# 모래 — 누런 흙바닥에 잔돌 몇 개
			_quad(N, E, S, W, C.yardfloor)
			for g5 in range(n * 2):
				var gx: float = fmod(float(g5) * 0.37 + 0.2, 1.0) * float(n)
				var gy: float = fmod(float(g5) * 0.61 + 0.1, 1.0) * float(n)
				draw_circle(Iso.w(o5.x + gx, o5.y + gy), 2.0, Color(0.72, 0.64, 0.48, 0.5))
		1:
			# 나무 마루 — 널빤지 결이 한 방향으로
			_quad(N, E, S, W, Color("cfa878"))
			for k5 in range(1, n * 2):
				var f5: float = float(k5) * 0.5
				draw_line(Iso.w(o5.x + f5, float(o5.y)), Iso.w(o5.x + f5, float(o5.y + n)),
					Color(0.68, 0.52, 0.36, 0.5), 1.5)
		_:
			# 돌판 — 잿빛 판석을 격자로 깐다
			_quad(N, E, S, W, Color("bcb6a8"))
			for k5 in range(1, n):
				draw_line(Iso.w(o5.x + float(k5), float(o5.y)), Iso.w(o5.x + float(k5), float(o5.y + n)),
					Color(0.6, 0.58, 0.52, 0.6), 1.5)
				draw_line(Iso.w(float(o5.x), o5.y + float(k5)), Iso.w(float(o5.x + n), o5.y + float(k5)),
					Color(0.6, 0.58, 0.52, 0.6), 1.5)
	_outline(N, E, S, W, _shade(col, 0.16), 2.0)

	# 담은 뒤 두 변에만. 앞에 세우면 마당 안이 가려진다.
	#
	# ★ 담이 등급 따라 자란다(2026-08-25, 유저): 초가(짚) → 돌담 → 기와.
	#   승급이 창 안의 숫자로만 남지 않고 **마을 풍경에서 보이게** 된다.
	#   전부 코드 그림이라 그림 장수는 안 는다.
	var wrank: int = sim.rank_of(shop.id)
	for pair in [[W, N], [N, E]]:
		var A: Vector2 = pair[0]
		var B: Vector2 = pair[1]
		match wrank:
			0:
				# 초가 — 누런 짚단 담. 위가 삐죽삐죽하다
				_quad(A, B, B + Vector2(0, -14), A + Vector2(0, -14), Color("d8c078"))
				for t2 in range(6):
					var q2: Vector2 = A.lerp(B, (t2 + 0.5) / 6.0)
					draw_line(q2 + Vector2(0, -14), q2 + Vector2(0, -19 - (t2 % 2) * 2), Color("c4aa5e"), 3.0)
			1:
				# 돌담 — 잿빛 벽에 돌덩이 몇 개
				_quad(A, B, B + Vector2(0, -17), A + Vector2(0, -17), Color("a9a396"))
				for t2 in range(5):
					var q2: Vector2 = A.lerp(B, (t2 + 0.5) / 5.0)
					draw_circle(q2 + Vector2(0, -8 - (t2 % 3) * 3), 3.5, Color("8f8a7c"))
				draw_line(A + Vector2(0, -17), B + Vector2(0, -17), Color("c2bdb0"), 2.5)
			_:
				# 기와 — 가게 색 벽 위에 검은 기와 갓
				_quad(A, B, B + Vector2(0, -18), A + Vector2(0, -18), _shade(col, -0.03))
				_quad(A + Vector2(0, -18), B + Vector2(0, -18), B + Vector2(0, -24), A + Vector2(0, -24), C.ink)
				for t2 in range(7):
					var q2: Vector2 = A.lerp(B, (t2 + 0.5) / 7.0)
					draw_line(q2 + Vector2(0, -18), q2 + Vector2(0, -24), Color("4a4139"), 1.5)

	# ★ 현판(가게 이름)과 "승급하면 매대 +2" 문구는 지웠다(2026-08-25, 유저).
	#   '가득!'·'새 칸!' 같은 알림 표는 여기(바닥 층)가 아니라 **맨 위 층**에서
	#   그린다(_yard_signs) — 알림이 가구에 반쯤 가려지면 알림이 아니다.

## 마당 알림 표 — 깊이 정렬 **밖**, 맨 위에 그린다.
## 규칙: 바닥 표시(+ 마름모)는 바닥에 깔리고, 알림 표는 무엇에도 안 가린다.
## 섞어 두면 어떤 것은 가구에 반쯤 먹히고 어떤 것은 바닥을 덮는다(유저가 잡았다).
func _yard_signs(i: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var N: Vector2 = Iso.w(Iso.org(sim, i).x, Iso.org(sim, i).y)
	# '가득!' 표지는 주문 생산 전환(2026-08-26)으로 은퇴했다 — 재고가 없으니
	# 가득도 없다. QA 눈검사에서 유령으로 남아 있던 것을 걷어냈다.
	if sim.shop_todo(shop.id) > 0:
		var bob: float = sin(_t * 4.0) * 3.0
		var promo: bool = sim.can_promote(shop.id)
		var txt: String = "승급!" if promo \
			else ("채용!" if sim.can_hire_staff(shop.id) else "새 칸!")
		_chip(N + Vector2(0, -100 + bob), 26.0 + txt.length() * 14.0, 25, C.red if promo else C.jade)
		_text(N + Vector2(0, -82 + bob), txt, 15, Color("fff3dd"))

func _kiln(i: int) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var col := Color(shop.color)
	var o: Vector2i = Iso.org(sim, i)
	var k: Vector2i = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)).kiln
	var p: Vector2 = Iso.w(o.x + k.x + 0.5, o.y + k.y + 0.5)
	var rk2: int = sim.rank_of(String(shop.id))
	# 가마(풀무)도 등급 그림을 받는다: kilns/<가게id>.png, 등급은 -1·-2.
	# 그림이 오기 전엔 등급 따라 **커지고 불이 세진다** — 승급이 눈에 보이게.
	var pic2: Texture2D = Art.ranked("kilns", String(shop.id), rk2)
	if pic2 != null:
		_sprite(pic2, p + Vector2(0, 18), "kilns")
	else:
		var grow: float = 1.0 + 0.18 * rk2
		_box(o.x + k.x + 0.22, o.y + k.y + 0.22, 0.56 * grow, 0.56 * grow, 26 + 6 * rk2,
			_shade(col, 0.10), _shade(col, -0.07))
	var fl: float = 0.6 + absf(sin(_t * 3.0 + i)) * 0.4
	var fs: float = 1.0 + 0.35 * rk2
	draw_circle(p + Vector2(0, -30 - 6 * rk2), 5.0 * fl * fs, Color("f0a24b"))
	draw_circle(p + Vector2(0, -36 - 6 * rk2), 3.0 * fl * fs, Color("f6d27a"))

## 매대 한 칸 = 좌대 + 재고·진행 계기 + 이름패
func _stall(i: int, k: int, spot: Vector2i) -> void:
	var shop: Dictionary = Content.SHOPS[i]
	var o: Vector2i = Iso.org(sim, i)
	var p: Vector2 = Iso.w(o.x + spot.x + 0.5, o.y + spot.y + 0.5)
	var it: Dictionary = shop.items[k]

	if not sim.is_open(it.id):
		# 안 연 칸은 **바닥과 같은 1×1 마름모**에 + 하나다(유저 결정).
		# 처음엔 화면에 똑바로 선 네모로 그렸는데, 세상 속 빈 자리가 아니라
		# 공중에 뜬 딱지처럼 보였다 — 빈 매대 자리는 땅바닥이지 창(UI)이 아니다.
		# 살 수 있으면 초록으로 바뀐다. 값은 눌러서 창에서 본다.
		var can: bool = sim.can_open_item(it.id)
		var tN: Vector2 = Iso.w(o.x + spot.x, o.y + spot.y)
		var tE: Vector2 = Iso.w(o.x + spot.x + 1, o.y + spot.y)
		var tS: Vector2 = Iso.w(o.x + spot.x + 1, o.y + spot.y + 1)
		var tW: Vector2 = Iso.w(o.x + spot.x, o.y + spot.y + 1)
		_quad(tN, tE, tS, tW, Color(0.62, 0.78, 0.55, 0.4) if can else Color(0.45, 0.42, 0.36, 0.18))
		_outline(tN, tE, tS, tW, C.jade if can else Color(0.4, 0.37, 0.3, 0.45), 2.0)
		_flat_plus(o.x + spot.x + 0.5, o.y + spot.y + 0.5, C.jade if can else Color(0.4, 0.37, 0.3, 0.5))
		return



	# 매대(좌판) — 가게마다 다르게 생겼다. 대장간은 모루 받침, 필방은 낮은 서안…
	# 그림이 없으면 여태처럼 나무 상자를 그린다.
	var table: Texture2D = Art.ranked("stalls", String(shop.id), sim.rank_of(String(shop.id)))
	if table != null:
		# 매대 그림은 ↙를 보는 한 장이다. 세로 변(왼담 x=0, 길가 x=n-1)에 선
		# 매대는 보여줄 쪽이 ↘라서 뒤집는다 — 필방·옹기점·약재상의 길가 매대가
		# 등을 보이고 있었다(유저가 두 번 잡았다).
		var n4: int = Iso.plot_dim(sim, i)
		# 윗줄(y=0)은 모서리라도 ↙다 — 3번 칸(윗줄의 오른끝)이 세로줄로
		# 잘못 분류돼 ↘로 뒤집혔고, 마당 밖으로 빠져나간 것처럼 보였다(유저).
		var flip4: bool = (spot.x == n4 - 1 or spot.x == 0) and spot.y > 0
		# ↘판 그림(<가게>-r)이 있으면 뒤집는 대신 그걸 쓴다 — 거울은 빛 방향
		# (왼쪽 위 광원)까지 뒤집어서, 비대칭 매대는 어색할 수 있다(유저 물음).
		# 기본은 뒤집기, 어색한 가게만 ↘판을 따로 받는 중간 길이다.
		if flip4:
			var tr4: Texture2D = Art.ranked("stalls", String(shop.id) + "-r", sim.rank_of(String(shop.id)))
			if tr4 != null:
				table = tr4
				flip4 = false
		_sprite(table, p + Vector2(0, 19), "stalls", flip4)
	else:
		_box(o.x + spot.x + 0.14, o.y + spot.y + 0.14, 0.72, 0.72, 14, C.paper, C.wood)
	# 등급이 오르면 그림도 바뀐다 — 그 등급 그림이 있으면 그것,
	# 없으면 기본 그림에 **등급 테**를 둘러 표시한다(무쇠→참쇠→강철).
	# ★ 등급 테두리(은·금 고리)는 지웠다(2026-08-25, 유저 — "판타지 RPG도
	#   아니고"). 승급은 **물건 그림 자체가 바뀌는 것**으로 보여준다.
	#   items/<id>-1.png(2등급)·-2.png(3등급)가 주문서 필수 목록에 들어갔다.
	var rk: int = sim.rank_of(String(shop.id))
	# ★ 상품 배지(2026-08-26, 유저 설계): 물건을 **흰 동그라미**로 감싸고,
	#   만드는 동안 그 동그라미가 **초록으로 차오른다.** 물건도 보이고 생산도
	#   보인다 — 따로 띄우던 로딩 파이는 이 채움에 흡수됐다.
	var bc: Vector2 = p + Vector2(0, -52)     # 좌판이 보이게 위로(유저)
	var st2: Dictionary = sim.items[it.id]
	# 채움은 **sim의 진실 그대로** — 손이 굴러가면 찬다. 일꾼이 계산하러 간
	# 사이에도 손은 일하니까(그게 경제 규칙이다), 채움을 숨기면 "그냥
	# 생산되네"와 "초기화됐네"가 번갈아 나온다(유저가 둘 다 겪었다).
	# 일꾼 있음/없음은 먼지·불티(기척)만 가른다.
	var making: bool = sim._crafting.has(String(it.id)) \
		and float(sim._switch.get(String(it.id), 0.0)) <= 0.0   # 걸어가는 중엔 안 찬다
	var here: bool = making and _worker_of(i, k).distance_to(_stall_front(i, k)) < 8.0
	draw_circle(bc, 17.0, Color(1.0, 0.99, 0.96, 0.95))
	# 하다 만 진행도도 **흐리게 남긴다** — 일꾼이 자리를 비우면 채움이 뚝
	# 사라져서 "초기화됐나"로 보였다(유저). sim은 기억하고 있었다 — 화면만
	# 말을 안 했던 것. 일꾼이 돌아오면 그 자리부터 다시 초록으로 찬다.
	var pr2: float = clampf(st2.prog / sim.craft_time(String(it.id)), 0.0, 1.0)
	if pr2 > 0.01:
		var fan := PackedVector2Array([bc])
		var steps2: int = 22
		for k2 in range(steps2 + 1):
			var a2: float = -PI * 0.5 + TAU * pr2 * float(k2) / float(steps2)
			fan.append(bc + Vector2(cos(a2), sin(a2)) * 16.0)
		draw_colored_polygon(fan, Color(0.44, 0.78, 0.5, 0.55) if making
			else Color(0.5, 0.6, 0.52, 0.3))
	draw_arc(bc, 17.0, 0, TAU, 32, Color(0.55, 0.44, 0.32, 0.8), 2.0)
	var pic: Texture2D = Art.ranked("items", String(it.id), rk)
	if pic != null:
		draw_texture_rect(pic, Rect2(bc - Vector2(9, 15), Vector2(18, 30)), false)
	else:
		_text(bc + Vector2(0, 7), String(it.icon), 18, Color.WHITE)
	if here:
		# 만드는 기척 — 대장간은 불티, 나머지는 먼지구름(매대 위 효과 원칙)
		if String(shop.id) == "smith":
			for s2 in range(3):
				var ph: float = fmod(_t * 1.6 + s2 * 0.37 + spot.x * 0.21, 1.0)
				var px: Vector2 = p + Vector2(sin((s2 * 2.1 + spot.y) * 2.4) * 10.0 * ph,
					-22.0 - ph * 16.0)
				draw_circle(px, 1.8 * (1.0 - ph) + 0.6,
					Color(1.0, 0.55 + 0.25 * (1.0 - ph), 0.15, 1.0 - ph))
		else:
			for s2 in range(2):
				var ph: float = fmod(_t * 0.7 + s2 * 0.5 + spot.x * 0.17 + spot.y * 0.29, 1.0)
				var px: Vector2 = p + Vector2(float(s2 * 2 - 1) * (6.0 + ph * 5.0),
					-26.0 - ph * 10.0)
				draw_circle(px, 3.0 + ph * 2.0, Color(0.87, 0.83, 0.73, 0.35 * (1.0 - ph)))

	# ★ 재고 숫자·진행 고리는 지웠다(2026-08-25, 유저 지적). 그림이 오기 전엔
	#   그 숫자가 화면의 전부였는데, 이제는 물건 그림을 동그라미로 가리는
	#   소음이었다. '가득' 신호는 매대가 아니라 **현판에 하나만** 띄운다 —
	#   처음엔 매대마다 붙였더니 넷이 한꺼번에 깜빡여서 소음을 소음으로 바꾼
	#   꼴이 됐다. 자세한 숫자는 가게 창에 있다.


	# 이름표는 지웠다(유저 결정) — 물건 그림이 이름이다. 대신 **화살표**로
	# 지금 할 수 있는 일을 알린다: 초록 ▲ = 레벨업 가능, 빨강 ▲ = 만렙까지 가능.
	if not sim.at_max(it.id):
		var need: int = int(sim.max_lv(it.id) - sim.lv(it.id))
		var can_max: bool = sim.affordable_levels(it.id) >= need
		var can_up: bool = sim.money >= sim.level_cost(it.id)
		if can_max or can_up:
			var bob3: float = sin(_t * 4.0) * 2.0
			_text(p + Vector2(24, -52 + bob3), "▲", 15, Color("c7563f") if can_max else C.jade)

func _counter(i: int) -> void:
	# ★ 계산대도 등급 따라 는다(2026-08-26, 유저): 무쇠 1 · 참쇠 2 · 강철 3.
	#   같은 변을 따라 반 칸씩 벌려 놓는다. 주문 자리(sim.order_slots)와 한 몸.
	var n_ct: int = sim.counters_of(String(Content.SHOPS[i].id))
	for c2 in range(n_ct):
		_counter_one(i, (float(c2) - float(n_ct - 1) * 0.5) * 0.58)

func _counter_one(i: int, toff: float) -> void:
	var o: Vector2i = Iso.org(sim, i)
	var yd: Dictionary = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i))
	var ct: Vector2i = yd.counter
	# 변을 따라 미끄러뜨린다 — 세로 길 가게(gate x)는 y축, 골목 가게는 x축
	var bx: float = float(o.x + ct.x) + (toff if String(yd.gate) == "y" else 0.0)
	var by: float = float(o.y + ct.y) + (toff if String(yd.gate) == "x" else 0.0)
	var p: Vector2 = Iso.w(bx + 0.5, by + 0.5)
	# 계산대도 매대와 같은 규칙이다 — **정면치기 한 장 + 코드 뒤집기.**
	var pic3: Texture2D = Art.ranked("counters", String(Content.SHOPS[i].id), sim.rank_of(String(Content.SHOPS[i].id)))
	if pic3 != null:
		_sprite(pic3, p + Vector2(0, 14), "counters", String(yd.gate) == "y")
	else:
		# 임시 상자도 **방향은 있어야 한다**(유저 — "저게 계산대 맞나").
		_box(bx + 0.16, by + 0.3, 0.68, 0.4, 18, C.paper2, C.wood2)
		var face_r: bool = String(yd.gate) == "x"      # 세로 길 가게는 ↘가 앞
		var fN: Vector2 = Iso.w(bx + (0.84 if face_r else 0.16), by + 0.3)
		var fS: Vector2 = Iso.w(bx + (0.84 if face_r else 0.16), by + 0.98)
		if not face_r:
			fN = Iso.w(bx + 0.16, by + 0.98)
			fS = Iso.w(bx + 0.84, by + 0.98)
		draw_colored_polygon(PackedVector2Array([
			fN, fS, fS + Vector2(0, -18), fN + Vector2(0, -18)]), _shade(C.wood2, -0.06))
		# 상판 위 엽전함(짙은 통) + 엽전 — 계산하는 자리라는 표
		draw_rect(Rect2(p + Vector2(-12, -30), Vector2(11, 7)), Color("4a3a2a"))
		var coin: Texture2D = Art.tex("ui", "coin")
		if coin != null:
			draw_texture_rect(coin, Rect2(p + Vector2(2, -30), Vector2(13, 13)), false)
		else:
			draw_circle(p + Vector2(8, -24), 4.5, Color("c9a227"))

## 작은 건물(점포·주막·포장마차)은 화면에서 뺐다(2026-08-25, 유저 — "의미
## 없어 보임"). 장 여는 단추 노릇이었는데, 그 일은 촌장이 물려받았다.
## sim의 smalls 규칙은 저장 호환 때문에 남아 있고 아무도 안 부른다.

func _dog() -> void:
	var t: Vector2i = Iso.DOG_T
	var p: Vector2 = Iso.w(t.x + 1, t.y + 1)
	if sim.guards <= 0.0:
		var N: Vector2 = Iso.w(t.x, t.y)
		var E: Vector2 = Iso.w(t.x + 1, t.y)
		var W: Vector2 = Iso.w(t.x, t.y + 1)
		_outline(N, E, p, W, Color(0.24, 0.2, 0.14, 0.4), 2.0)
		_text(p + Vector2(0, -Iso.TH - 16), "삽살개 자리", 12, C.ruin)
		var can: bool = sim.money >= sim.guard_cost()
		_chip(p + Vector2(0, -Iso.TH - 8), 80, 21, C.jade if can else Color(0.24, 0.2, 0.14, 0.3))
		_text(p + Vector2(0, -Iso.TH + 7), "🪙" + Num.fmt(sim.guard_cost()), 12,
			Color.WHITE if can else Color("e6e0cf"))
		return
	_pad(t.x, t.y)
	_box(t.x + 0.18, t.y + 0.18, 0.64, 0.64, 19, C.paper2, Color("d8c9a3"))
	_box(t.x + 0.06, t.y + 0.06, 0.88, 0.88, 8, Color("8a6647"), Color("6b4c33"), 19)
	draw_circle(p + Vector2(0, -13), 6.5, C.ink)
	# 개들은 이제 마을을 돈다(dogs) — 개집에는 안 그린다.
	# 더 들일 수 있으면 그 자리를 비워 표시한다
	if sim.guards < float(sim.guard_max()):
		var can2: bool = sim.money >= sim.guard_cost()
		_chip(p + Vector2(0, -Iso.TH - 34), 86, 21, C.jade if can2 else Color(0.24, 0.2, 0.14, 0.3))
		_text(p + Vector2(0, -Iso.TH - 19), "🐕+ 🪙" + Num.fmt(sim.guard_cost()), 11,
			Color.WHITE if can2 else Color("e6e0cf"))

## 낮과 밤 — 게임 시계(sim.t)로 20분에 하루가 돈다. 낮이 반, 나머지가
## 해질녘·밤·새벽이다. 진짜 시계(폰 시각)를 안 쓰는 이유: 방치형은 한 번에
## 2~5분 논다 — 점심에만 켜는 사람은 밤을 영영 못 본다. 게임 시계면 한 판
## 안에서 낮과 밤을 다 만난다. 색은 화면 전체에 얇게 한 겹만 얹는다.
## 하루 시계는 sim의 것이다(밤엔 손님·손놀림·쥐 규칙이 실제로 달라진다).
## clock_override는 찍는 도구용 — 화면만 그 시각인 척한다.
## 일꾼 그림 찾기(2026-08-26 확정 계약): ① 그 가게 세트(clerks/<가게>-<무늬>-<방향>,
## 앞치마 등급은 -1·-2) → ② 공용 무늬 세트(hero-body/<무늬>-<방향>) → ③ A 무늬.
## 무늬는 채용 자리마다 랜덤(sim.fur_of), 복장은 가게가, 앞치마는 등급이 정한다.
func _worker_tex(shop_id: String, slot: int, dir3: String) -> Texture2D:
	var fur: String = sim.fur_of(shop_id, slot)
	var rk: int = sim.rank_of(shop_id)
	var t: Texture2D = Art.ranked("clerks", "%s-%s-%s" % [shop_id, fur, dir3], rk)
	if t == null:
		t = Art.ranked("hero-body", "%s-%s" % [fur, dir3], rk)
	if t == null:
		t = Art.ranked("hero-body", "a-%s" % dir3, rk)
	return t

## 완성된 주문 상자 — 물건 모양이 아니라 **그냥 상자**다(2026-08-26, 유저).
## 나르는 동안 너구리 손께에 얹는다. 전부 코드 그림.
func _crate(p2: Vector2, flip: bool) -> void:
	var bx: Vector2 = p2 + Vector2(-16.0 if flip else 16.0, -40.0)
	draw_rect(Rect2(bx - Vector2(8, 6), Vector2(16, 12)), Color("a97e4f"))
	draw_rect(Rect2(bx - Vector2(8, 6), Vector2(16, 4)), Color("c19a6b"))
	draw_rect(Rect2(bx - Vector2(9, 8), Vector2(18, 2)), Color("6d5236"))

func day_phase() -> float:
	return clock_override if clock_override >= 0.0 else sim.day_phase()

func _night() -> bool:
	var ph: float = day_phase()
	return ph >= float(Content.DAY.night[0]) and ph < float(Content.DAY.night[1])

## 하루 어디쯤인가 — 머리띠 오른쪽 끝의 그림 한 개.
## ★ 십이지시(사시·자시) → 몇 시 → **그림만**, 두 번 깎였다(유저).
##   글자는 결국 소음이었다 — 해가 떠 있으면 낮이고 달이 떠 있으면 밤이다.
func day_icon() -> String:
	var ph: float = day_phase()
	return "☀️" if ph < 0.5 else ("🌆" if ph < 0.66 else ("🌙" if ph < 0.9 else "🌄"))

func _sky() -> Color:
	var ph: float = day_phase()
	var day := Color(0, 0, 0, 0)
	var dusk := Color(0.82, 0.42, 0.18, 0.15)      # 해질녘 — 주황이 얇게
	var night := Color(0.06, 0.09, 0.24, 0.34)     # 밤 — 짙은 남색
	if ph < 0.50:
		return day
	if ph < 0.58:
		return day.lerp(dusk, (ph - 0.50) / 0.08)
	if ph < 0.66:
		return dusk.lerp(night, (ph - 0.58) / 0.08)
	if ph < 0.90:
		return night
	return night.lerp(day, (ph - 0.90) / 0.10)

## 발밑 그림자 — 납작한 원 하나. **그림에 굽지 않고 코드가 그린다** —
## 그림에 넣으면 동물×방향마다 딸려가고, 몸이 들썩일 때 그림자까지 떠 버린다.
## 그림자는 늘 땅(발끝 자리)에 붙어 있어야 발이 땅을 딛는 느낌이 난다.
func _shadow(foot: Vector2, r: float) -> void:
	draw_set_transform(foot, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.13))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## 그림 한 장을 **발끝 기준**으로 놓는다. 그림 주문서에도 "발끝이 아래 변에
## 닿게"라고 적어 둔 이유가 이것이다 — 발끝이 곧 그 물건이 서 있는 자리이고,
## 앞뒤 가리기(깊이)도 발끝 높이로 정한다.
func _sprite(t: Texture2D, foot: Vector2, kind: String, flip: bool = false, squash: float = 0.0) -> void:
	var sz: Vector2 = Art.SIZE[kind]
	# 짐승은 그림을 재서 앉힌다 — 밑 여백만큼 내리고(발이 그림자에 닿게),
	# 몸이 액자에서 옆으로 치우쳐 있으면 그만큼 당긴다(그림자와 몸이 어긋나던
	# "밀린 느낌"의 범인). 가구는 손으로 맞춘 자리가 있으니 안 건드린다.
	var r := Rect2(foot - Vector2(sz.x * 0.5, sz.y), sz)
	if kind in ["hero", "clerks", "staff", "guests", "pests"]:
		var ft: Dictionary = Art.fit(t)
		r.position.y += float(ft.pad) * sz.y
		var dx: float = (0.5 - float(ft.cx)) * sz.x
		r.position.x += -dx if flip else dx
	if squash > 0.0:
		# 발끝은 그대로, 몸만 낮고 넓게 눌린다
		r.position.x -= r.size.x * squash * 0.35
		r.position.y += r.size.y * squash
		r.size.x *= 1.0 + squash * 0.7
		r.size.y *= 1.0 - squash
	if flip:
		# 그림은 오른쪽 보는 것 한 장만 받는다. 왼쪽은 여기서 뒤집는다 —
		# 두 장씩 그리게 하면 장수가 두 배가 되고, 둘이 미묘하게 달라진다.
		# ★ 뒤집기 삽질의 역사(둘 다 유저가 잡았다): 목적지 네모를 음수로 —
		#   한 칸 옆으로 밀려 그려짐(4·7 매대가 5·8로). 원본 네모를 음수로 —
		#   아예 안 그려짐. **좌표계를 거울로 걸고 정상으로 그리는 것**만 확실하다.
		_mirrored(t, r)
	else:
		draw_texture_rect(t, r, false)

## 세로축 거울 — r 자리에 t를 좌우 반전으로 그린다. 자리는 절대 안 밀린다.
func _mirrored(t: Texture2D, r: Rect2) -> void:
	draw_set_transform(Vector2(r.position.x + r.size.x * 0.5, r.position.y), 0.0, Vector2(-1, 1))
	draw_texture_rect(t, Rect2(Vector2(-r.size.x * 0.5, 0), r.size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## 너구리 한 마리 — 몸통·귀·눈가 무늬. 그림이 없을 때 그리는 임시 도형이다.
func _raccoon(p: Vector2, size: float, tint: Color) -> void:
	var bob: float = sin(_t * 6.0 + p.x * 0.05) * 1.5
	var at: Vector2 = p + Vector2(0, bob)
	_shadow(p, size * 0.42)                                                  # 발밑 그림자
	draw_circle(at + Vector2(0, -size * 0.42), size * 0.34, tint)            # 몸통
	draw_circle(at + Vector2(0, -size * 0.86), size * 0.30, _shade(tint, 0.06))  # 머리
	draw_circle(at + Vector2(-size * 0.22, -size * 1.06), size * 0.11, tint)     # 귀
	draw_circle(at + Vector2(size * 0.22, -size * 1.06), size * 0.11, tint)
	draw_circle(at + Vector2(-size * 0.11, -size * 0.90), size * 0.09, Color(0.17, 0.14, 0.11, 0.85))
	draw_circle(at + Vector2(size * 0.11, -size * 0.90), size * 0.09, Color(0.17, 0.14, 0.11, 0.85))

## 이 가게가 **할 일이 없나** — 아직 걸어오는 손님(eta)의 주문은 셈에서
## 뺀다. 장부엔 출발 때 적히지만 너구리가 그걸 알면 예지력이다(유저,
## 2026-08-26) — 손님이 도착해 말풍선을 띄운 뒤에야 부스스 일어난다.
func _idle(i: int) -> bool:
	var sid: String = String(Content.SHOPS[i].id)
	for o in sim.orders:
		if float(o.get("eta", 0.0)) > 0.0:
			continue
		if not (o.lines as Array).is_empty() \
				and String(sim.item_by_id(String(o.lines[0].id)).shop) == sid:
			return false
	return true

## 점장 그림 — **가게 것이 있으면 가게 것**, 없으면 공통 점장.
## 대장간 너구리는 망치를 들고, 필방 너구리는 앞치마를 두르는 식이다.
## 한 장도 없으면 도형으로 그린다. 어디서 멈춰도 게임은 돈다.
## 가게 등급도 본다 — `smith-make-1.png`가 있으면 참쇠 대장간 점장은 그걸 쓴다.
## 없으면 그 가게 점장, 그것도 없으면 공통 점장. **세 겹 다 없으면 도형이다.**
func _hero_tex(shop_id: String, pose: String) -> Texture2D:
	var t: Texture2D = Art.ranked("clerks", "%s-%s" % [shop_id, pose], sim.rank_of(shop_id))
	if t != null:
		return t
	# ★ 전용 그림이 있는 가게는 없는 자세도 **전용 만들기 그림**으로 때운다.
	#   걷기만 공통 너구리로 갈아입으니 "점장이 두 모습"이 됐다(유저).
	#   움직임(걷기 두 장 번갈아)보다 **같은 얼굴**이 먼저다.
	t = Art.ranked("clerks", "%s-make" % shop_id, sim.rank_of(shop_id))
	if t != null:
		return t
	return Art.tex("hero", "raccoon-" + pose)

func _trash_draw(tr: Dictionary) -> void:
	var p2: Vector2 = tr.pos
	_text(p2 + Vector2(0, 6), "🍂", 15, Color.WHITE)
	draw_circle(p2 + Vector2(6, 2), 2.5, Color(0.45, 0.4, 0.3, 0.5))

func _dog_walker(dg: Dictionary) -> void:
	var bob: float = absf(sin(_t * 9.0 + dg.pos.x * 0.03)) * 2.5
	var pic: Texture2D = Art.tex("pests", "dog")
	if pic != null:
		_shadow(dg.pos, 13.0)
		_sprite(pic, dg.pos + Vector2(0, -bob), "pests", bool(dg.flip))
	else:
		_text(dg.pos + Vector2(0, -bob), "🐕", 24, Color.WHITE)

## 촌장 — 흰 수염과 지팡이로 가른다. 크기는 점장·직원과 같다.
## 가르는 것은 크기가 아니라 **어디를 다니느냐**다 — 마당 밖은 이 너구리뿐이다.
func _mayor() -> void:
	if mayor.is_empty():
		return
	var t: Texture2D = Art.tex("hero", "mayor")
	if t != null:
		_shadow(mayor.pos, 14.0)
		_sprite(t, mayor.pos, "hero", bool(mayor.get("flip", false)))
	else:
		_raccoon(mayor.pos, SHAPE, Color("cbb79a"))
		draw_line(mayor.pos + Vector2(15, -6), mayor.pos + Vector2(19, -44), C.wood2, 2.5)
		draw_circle(mayor.pos + Vector2(0, -26), 5.0, Color(1, 1, 1, 0.85))
	# 장이 설 참이면 촌장이 알린다 — 누르면 장이 열린다(작은 건물의 일을 물려받았다)
	if sim.busy >= 0:
		var bob4: float = absf(sin(_t * 5.0)) * 5.0
		_chip(mayor.pos + Vector2(0, -92 - bob4), 74, 24, C.red)
		_text(mayor.pos + Vector2(0, -75 - bob4), "장 서다!", 13, Color("fff3dd"))
		return
	# 걸린 의뢰가 있으면 알린다. 의뢰 창은 아래 단추에도 있지만,
	# **마을 안에서 눈에 띄어야** 보러 간다.
	if not sim.quests.is_empty():
		var bob: float = absf(sin(_t * 4.0)) * 5.0
		_chip(mayor.pos + Vector2(0, -86 - bob), 26, 26, Color("c7563f"))
		_text(mayor.pos + Vector2(0, -67 - bob), "❗", 17, Color.WHITE)

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
	# 방향은 둘뿐이다(2026-08-26 확정): 위로 걸으면 뒷모습, 나머지 전부
	# 옆모습(오른쪽 한 장, 왼쪽은 뒤집기). 정면은 없다 — 서 있을 땐 마지막
	# 방향 그대로 멈추고, 할 일 없으면 존다.
	var dirn: String = "back" if (c.walking and bool(c.get("up", false))) else "side"
	var full: Texture2D = _worker_tex(id, 0, dirn)
	if full != null:
		var br3: float = 0.0 if c.walking else (0.5 + 0.5 * sin(_t * 2.4 + c.pos.x * 0.03)) * 0.03
		var hop: float = absf(sin(_t * 7.0 + c.pos.x * 0.05)) * 3.5 if c.walking else 0.0
		_shadow(c.pos, 14.0)
		_sprite(full, c.pos + Vector2(0, -hop), "clerks", bool(c.get("flip", false)), br3)
		if int(c.get("carry_oid", 0)) != 0 or float(c.get("carry", 0.0)) > 0.0:
			_crate(c.pos, bool(c.get("flip", false)))
		if pose == "sleep":
			_text(c.pos + Vector2(14, -70 + sin(_t * 2.0) * 3.0), "💤", 14, Color.WHITE)
		return
	var t: Texture2D = _hero_tex(id, pose)
	if t == null:                       # 그 자세가 아직 없으면 만드는 자세로
		t = _hero_tex(id, "make")
	if t != null:
		var breath2: float = 0.0 if c.walking else (0.5 + 0.5 * sin(_t * 2.4 + c.pos.x * 0.03)) * 0.03
		_shadow(c.pos, 14.0)
		_sprite(t, c.pos, "clerks" if Art.tex("clerks", "%s-%s" % [id, pose]) != null else "hero",
			bool(c.get("flip", false)), breath2)
		if int(c.get("carry_oid", 0)) != 0 or float(c.get("carry", 0.0)) > 0.0:
			_crate(c.pos, bool(c.get("flip", false)))
		return
	_raccoon(c.pos, SHAPE, Color("a8815a"))

## 겹그림 점장 — 확정 3방향 원화 규칙(2026-08-26, 유저).
## 본체 12장(무늬4×방향3) + 꼬리 8장(무늬4×side·back) + 장비 스티커(가게×단계×방향).
## 방향: front 정면 · side 오른쪽 훼이크 측면 · back 뒷모습. **왼쪽은 side를 뒤집는다.**
## 겹 순서 — front: 몸→장비(꼬리 없음) · side: 꼬리→몸→장비 · back: 몸→장비→꼬리.
## 장비는 투명 스티커다(몸·손·얼굴·무늬·꼬리·그림자 픽셀 금지) — 본체 위에 핀만 맞춘다.
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
## 지금 만드는 중인 매대 번호들(매대 순서). 손 배정을 화면이 따라가는 눈이다.
func _craft_idx(i: int) -> Array:
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i))
	var out: Array = []
	for k2 in range(min(Content.SHOPS[i].items.size(), y.stalls.size())):
		if sim._crafting.has(String(Content.SHOPS[i].items[k2].id)):
			out.append(k2)
	return out

## k번 매대의 앞자리 — 안쪽 칸에 서서 매대 쪽으로 살짝 붙은 자리.
func _stall_front(i: int, k: int) -> Vector2:
	var n: int = Iso.plot_dim(sim, i)
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], n)
	var o: Vector2i = Iso.org(sim, i)
	var sp: Vector2i = y.stalls[k]
	# 매대의 이웃 칸 중 **가구가 없는 빈 칸**에서 마당 중심에 제일 가까운
	# 곳에 선다(대각선 포함). 처음엔 "수직 안쪽 한 칸"으로 못 박았는데,
	# 모서리 매대는 그 칸이 하필 다른 매대였다 — 필방 7번, 지물포 3·9번은
	# 일하러 갈 자리가 아예 없었다(유저가 잡았다). 자리는 정하는 게 아니라
	# **찾는** 것이다.
	var taken: Dictionary = {}
	for t5 in y.stalls:
		taken[t5] = true
	taken[y.counter] = true
	taken[y.kiln] = true
	# 1순위: **수직 안쪽 이웃**(7번 매대면 8번 자리 — 유저 설계). 그 칸에
	# 가구가 있을 때만 2순위로 넘어간다. 처음부터 "중심에 가까운 빈 칸"으로
	# 골랐더니 8번이 비어 있는데도 5번으로 갔다(유저가 잡았다).
	var perp: Array = []
	if sp.x == 0:
		perp.append(Vector2i(1, sp.y))
	if sp.x == n - 1:
		perp.append(Vector2i(n - 2, sp.y))
	if sp.y == 0:
		perp.append(Vector2i(sp.x, 1))
	if sp.y == n - 1:
		perp.append(Vector2i(sp.x, n - 2))
	for cnd in perp:
		if cnd.x >= 0 and cnd.y >= 0 and cnd.x < n and cnd.y < n and not taken.has(cnd):
			return Iso.w(o.x + cnd.x + 0.5, o.y + cnd.y + 0.5)
	# 2순위: 이웃 여덟 칸의 빈 곳 중 마당 중심에 가까운 곳(모서리 매대용)
	var best: Vector2i = Vector2i(clampi(sp.x, 1, n - 2), clampi(sp.y, 1, n - 2))
	var best_d: float = INF
	var mid: Vector2 = Vector2(float(n) * 0.5, float(n) * 0.5)
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var cnd2 := Vector2i(sp.x + dx, sp.y + dy)
			if cnd2.x < 0 or cnd2.y < 0 or cnd2.x >= n or cnd2.y >= n or taken.has(cnd2):
				continue
			var d5: float = Vector2(float(cnd2.x) + 0.5, float(cnd2.y) + 0.5).distance_to(mid)
			if d5 < best_d:
				best_d = d5
				best = cnd2
	return Iso.w(o.x + best.x + 0.5, o.y + best.y + 0.5)

## 이 매대를 맡은 일꾼이 **지금 어디 있나**. 매대 앞에 닿기 전엔 만드는
## 효과(파이·먼지)를 안 띄우려고 본다 — 가지도 않았는데 만들어지면 오류로
## 보인다(2026-08-25, 유저). 점장이 계산 중이면 첫 매대부터 직원 몫이다.
func _worker_of(i: int, k: int) -> Vector2:
	if int(_heroJob.get(i, -1)) == k:
		return clerks[i].pos
	for s2 in range(int(sim.staff_of(String(Content.SHOPS[i].id)))):
		if int(_staffJob.get("%d:%d" % [i, s2], -1)) == k:
			return _staffAt.get("%d:%d" % [i, s2], Vector2.INF)
	return Vector2.INF

## 직원이 지금 있어야 할 자리 — **만드는 매대 곁**이다(2026-08-25, 유저).
## 제작을 짐승의 동작으로 보여주면 등급×자세만큼 그림이 는다. 대신 직원이
## 그 매대로 걸어가 서고, "만들고 있다"는 매대 위 효과(먼지구름·불티)가 말한다.
## 점장이 계산 중이면 첫 매대부터 직원 몫이고, 아니면 점장이 첫 매대를 맡는다.
func _staff_goal(i: int, k: int) -> Vector2:
	var job: int = int(_staffJob.get("%d:%d" % [i, k], -1))
	if job < 0:
		# 맡을 매대가 없으면 **작업대 곁에 모인다 — 겹쳐도 된다**(유저).
		return (Iso.foot(sim, i).work as Vector2) + Vector2(12.0 * float((k % 3) - 1), 7.0 * float(k / 3))
	return _stall_front(i, job)

## k번 매대 칸의 화면 중심 — 일꾼이 어느 쪽을 바라볼지 정할 때 쓴다.
func _stall_at(i: int, k: int) -> Vector2:
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i))
	var o: Vector2i = Iso.org(sim, i)
	var sp: Vector2i = y.stalls[k]
	return Iso.w(o.x + sp.x + 0.5, o.y + sp.y + 0.5)

## 직원의 현재 자리(걸어가는 중일 수 있다). 그리기와 앞뒤 순서가 같이 쓴다.
func _staff_cur(i: int, k: int) -> Vector2:
	return _staffAt.get("%d:%d" % [i, k], _staff_pos(i, k))

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
	var p: Vector2 = _staff_cur(i, k)
	var idle: bool = _idle(i)
	# 밤엔 수시로 졸았다 깼다 한다(유저) — 직원마다 다른 박자로. sim의 밤
	# 규칙(손놀림이 느려진다)과 결이 맞는 그림이다.
	if _night() and sin(_t * 0.35 + float(i * 3 + k) * 1.9) > 0.1:
		idle = true
	# 망치질 — 할 일이 있을 때만, **자리에 닿았을 때만** 들썩인다.
	# 걷는 중에 망치질하면 걸으며 못질하는 목수가 된다.
	var moving: bool = p.distance_to(_staff_goal(i, k)) > 2.0
	var swing: float = maxf(0.0, sin(fmod(_t / 2.4 + i * 0.37 + (k + 1) * 0.29, 1.0) * TAU))
	var bob: float = (absf(sin(_t * 6.0)) * 2.0) if moving else (0.0 if idle else swing * 3.0)
	# ★ 직원 개념 폐지(2026-08-26, 유저) — 승급하면 "같은 가게 너구리가 한
	#   마리 더 온다". 전원이 그 가게의 완성형 그림을 쓴다(쌍둥이 형제들).
	#   경제(손 셈)는 그대로고 화면과 말만 통일했다. 두건 직원 그림은 은퇴.
	var sid6: String = String(Content.SHOPS[i].id)
	var job5: int = int(_staffJob.get("%d:%d" % [i, k], -1))
	var sflip: bool = job5 >= 0 and _stall_at(i, job5).x < p.x   # 맡은 매대를 본다
	var breath: float = (0.5 + 0.5 * sin(_t * 2.2 + p.x * 0.04)) * 0.03 if idle else 0.0
	var t: Texture2D = _worker_tex(sid6, k + 1, "side")
	if t != null:
		_shadow(p, 14.0)
		_sprite(t, p + Vector2(0, -bob), "clerks", sflip, breath)
		if idle:
			_text(p + Vector2(14, -70 + sin(_t * 2.0 + float(k)) * 3.0), "💤", 12, Color.WHITE)
		return
	var t2: Texture2D = Art.tex("staff", "band-%s" % ("sleep" if idle else "work"))
	if t2 != null:
		_shadow(p, 14.0)
		_sprite(t2, p + Vector2(0, -bob), "staff", sflip, breath)
		return
	_raccoon(p + Vector2(0, -bob), SHAPE, Color("bfa987"))

func _walker(wk: Dictionary) -> void:
	# 방향에 맞는 그림을 고른다: 줄에 서면 정면(-front), 위로 걸으면
	# 뒷모습(-back), 나머지는 옆모습. 없는 방향은 옆모습으로 때운다 —
	# 그림이 한 장씩 들어올 때마다 그 방향만 살아난다.
	var gid2: String = String(wk.get("id", ""))
	var t: Texture2D = null
	if wk.state == "buy":
		t = Art.tex("guests", gid2 + "-front")
	elif bool(wk.get("up", false)):
		t = Art.tex("guests", gid2 + "-back")
	if t == null:
		t = Art.tex("guests", gid2)
	if t != null:
		# 걷는 동안 들썩인다 — 이게 없으면 미끄러지듯 떠다니는 유령이 된다
		# (유저: "공중에 날라다니는 느낌"). 그림자는 땅에 남는다.
		var ph6: float = absf(sin(_t * 7.0 + wk.pos.x * 0.06))
		var stepbob: float = 0.0 if wk.state == "buy" else ph6 * 2.6
		_shadow(wk.pos, 13.0)
		# 걸을 땐 착지 눌림, 줄에 서면 숨 쉬는 말캉임 — 다 같은 스쿼시다(유저)
		var sq6: float = (0.5 + 0.5 * sin(_t * 2.5 + wk.pos.x * 0.05)) * 0.025 \
			if wk.state == "buy" else (1.0 - ph6) * 0.05
		_sprite(t, wk.pos + Vector2(0, -stepbob), "guests", bool(wk.get("flip", false)), sq6)
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
	# ★ 세 번째 판(2026-08-25, 유저가 찾아온 레퍼런스): **동그란 흰 풍선에
	#   물건 하나 크게, 오른쪽 아래 개수 동그라미.** 그리고 맨 앞사람만이
	#   아니라 **줄 선 전원**에게 하나씩 — 여럿이 각자 다른 걸 기다리는 게
	#   한눈에 보인다. 여러 종류를 담았어도 첫 것만 띄운다(풍선 하나에 하나).
	var first: Dictionary = sold[0]
	var bob2: float = sin(_t * 2.6 + wk.pos.x * 0.13) * 1.8
	var c0: Vector2 = wk.pos + Vector2(2, -86 + bob2)
	draw_circle(c0, 21.0, Color(1.0, 0.99, 0.96, 0.97))
	draw_colored_polygon(PackedVector2Array([
		c0 + Vector2(-7, 18), c0 + Vector2(6, 18), c0 + Vector2(-1, 29)]),
		Color(1.0, 0.99, 0.96, 0.97))
	var pic4: Texture2D = Art.ranked("items", String(first.id), sim.rank_of(String(Content.SHOPS[wk.shop].id)))
	if pic4 != null:
		draw_texture_rect(pic4, Rect2(c0 - Vector2(11, 16), Vector2(22, 28)), false)
	else:
		_text(c0 + Vector2(0, 7), String(first.icon), 20, Color.WHITE)
	# 개수 동그라미 — 레퍼런스의 초록 배지 그대로
	draw_circle(c0 + Vector2(14, 12), 9.0, C.jade)
	draw_circle(c0 + Vector2(14, 12), 9.0, Color(1, 1, 1, 0.9), false, 1.5)
	_text(c0 + Vector2(14, 17), "%d" % int(first.n), 11, Color.WHITE)

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
		# 까마귀도 **걸어 다닌다**(2026-08-26, 유저 — 두 발 세계관). 하늘을
		# 가로지르던 시절엔 화면(카메라) 기준으로 날아서 빠르고 못 잡았다.
		# 이제 안골 큰길을 위에서 아래로 좌우 종종걸음 치며 내려온다.
		var u: float = sin(p * PI * 3.0)
		return {"kind": "crow", "face": "🐦‍⬛", "r": 32.0, "flip": u < 0.0,
			"pos": Iso.w(5.5, 6.5 + p * 8.0) + Vector2(u * 90.0, 0.0)}
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
		_sprite(pic, at + Vector2(0, 22), "pests", bool(t.get("flip", false)))
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
			# ★ 안 연 칸(+ 마름모)은 **바닥 표시**라 마당 바닥 바로 위에 깔린다.
			#   발끝 z로 세웠더니 앞 칸의 마름모가 뒤 칸의 매대 그림을 덮었다.
			var zz: float = Iso.w(o.x + sp.x + 1, o.y + sp.y + 1).y
			if not sim.is_open(String(Content.SHOPS[i].items[k].id)):
				zz = Iso.w(o.x, o.y).y + 2.5
			layer.append({"z": zz, "i": seq, "f": _stall.bind(i, k, sp)})
			seq += 1
		layer.append({"z": Iso.w(o.x + y.counter.x + 0.84, o.y + y.counter.y + 0.7).y, "i": seq,
			"f": _counter.bind(i)})
		seq += 1
	layer.append({"z": Iso.w(Iso.DOG_T.x + 1, Iso.DOG_T.y + 1).y, "i": seq, "f": _dog})
	seq += 1
	if not mayor.is_empty():
		layer.append({"z": mayor.pos.y, "i": seq, "f": _mayor})
		seq += 1
	for dg in dogs:
		layer.append({"z": dg.pos.y, "i": seq, "f": _dog_walker.bind(dg)})
		seq += 1
	for tr in trash:
		layer.append({"z": (tr.pos as Vector2).y - 20.0, "i": seq, "f": _trash_draw.bind(tr)})
		seq += 1
	# 너구리들 — 발끝 y로 선다. 그래야 계산대 뒤에 서면 가려지고 앞에 서면 가린다.
	for i in range(Content.SHOPS.size()):
		if not sim.shops.has(String(Content.SHOPS[i].id)):
			continue
		layer.append({"z": clerks[i].pos.y + 0.5, "i": seq, "f": _clerk.bind(i)})
		seq += 1
		var spots: Array = Iso.staff_spots(Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i)), Iso.plot_dim(sim, i))
		for k in range(min(int(sim.staff_of(String(Content.SHOPS[i].id))), spots.size())):
			layer.append({"z": _staff_cur(i, k).y, "i": seq, "f": _staff.bind(i, k)})
			seq += 1
	for wk in walkers:
		# 웃돈 없음 — 흩뜨림을 가로로만 하니(위 _walk) 발끝 그대로가 정답이다.
		# 같은 줄이면 나중에 넣은 손님이 매대 위에 그려진다(넣는 차례 규칙).
		layer.append({"z": wk.pos.y, "i": seq, "f": _walker.bind(wk)})
		seq += 1

	# 같은 z일 때 순서가 흔들리면 화면이 깜빡인다 — 넣은 차례로 못 박는다
	layer.sort_custom(func(a, b): return a.z < b.z if a.z != b.z else a.i < b.i)
	for e in layer:
		e.f.call()
	# ── 잠긴 구역 — 안개로 덮는다 ──
	# 지붕 실루엣은 안개 **아래로** 비친다(무너진 집들은 이미 그려져 있고
	# 안개는 반투명이다). "저 너머에 뭐가 있다"가 보여야 열고 싶어진다.
	for dz in Content.DISTRICTS:
		var locked: bool = not sim.zones.has(String(dz.id))
		var fade: float = float(_zoneFade.get(String(dz.id), 0.0))
		if not locked and fade <= 0.0:
			continue
		var a2: float = (1.0 if locked else fade)
		var r0: int = int(dz.rows[0])
		var r1: int = int(dz.rows[1])
		# 마을 밖 풀밭(EDGE)까지 덮는다 — 띠가 마을에서 뚝 끊기면 무대장치처럼 보인다
		var q := PackedVector2Array([
			Iso.w(-Iso.EDGE, r0), Iso.w(Iso.GW + Iso.EDGE, r0),
			Iso.w(Iso.GW + Iso.EDGE, r1 + 1), Iso.w(-Iso.EDGE, r1 + 1)])
		# 안개는 '그늘'이 아니라 **뿌연 새벽**이다. 어두운 초록으로 덮었더니
		# 화면 절반이 밤이 됐다 — 잠긴 동네는 불길한 곳이 아니라 아직
		# 깨어나지 않은 곳이다. 우윳빛이면 지붕이 안개 너머로 곱게 비친다.
		draw_colored_polygon(q, Color(0.93, 0.91, 0.84, 0.62 * a2))
		# 구역 경계 울타리 — 어디까지가 닫힌 데인지 금을 긋는다
		draw_line(Iso.w(-Iso.EDGE, r0), Iso.w(Iso.GW + Iso.EDGE, r0),
			Color(0.55, 0.48, 0.36, 0.8 * a2), 3.0)
		if not locked:
			continue
		# 장승 — 구역 이름과 여는 조건. 마을 어디서 보든 눈에 띄는 크기로.
		var mid: Vector2 = Iso.w((Iso.GW as float) * 0.5, float(r0) + 2.0)
		_chip(mid + Vector2(0, -30), 150, 30, Color(0.17, 0.14, 0.11, 0.88))
		_text(mid + Vector2(0, -8), "🔒 %s" % String(dz.name), 17, Color("f3e9d2"))
		var cond: String = "성 합계 %d · 🪙%s" % [int(dz.stars), Num.fmt(dz.cost)]
		var can: bool = sim.can_unlock_district(String(dz.id))
		_chip(mid + Vector2(0, 4), 30.0 + cond.length() * 8.0, 22, C.jade if can else Color(0.24, 0.2, 0.14, 0.6))
		_text(mid + Vector2(0, 20), cond, 12, Color.WHITE if can else Color("d8cfbc"))
		if can:
			var bob: float = absf(sin(_t * 3.2)) * 5.0
			_text(mid + Vector2(0, 44 + bob), "누르면 열린다!", 13, Color("ffe9a8"))

	# ── 하늘(날씨) ── 전부 코드 그림. 그림 주문 0장.
	var wnow: String = wx()
	if wnow == "cloud" or wnow == "rain":
		# 잿빛 한 겹 — 비는 조금 더 짙다
		draw_set_transform_matrix(get_canvas_transform().affine_inverse())
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size),
			Color(0.35, 0.4, 0.5, 0.10 if wnow == "cloud" else 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if wnow == "rain":
		# 빗줄기 — 화면 좌표에 사선 줄. 자리는 시각의 함수라 매 프레임 흘러내린다.
		draw_set_transform_matrix(get_canvas_transform().affine_inverse())
		var vp: Vector2 = get_viewport_rect().size
		for rr in range(46):
			var rx: float = fmod(float(rr) * 97.3 + _t * 260.0, vp.x + 60.0) - 30.0
			var ry: float = fmod(float(rr) * 61.7 + _t * 620.0, vp.y + 40.0) - 20.0
			draw_line(Vector2(rx, ry), Vector2(rx - 5.0, ry + 15.0),
				Color(0.62, 0.72, 0.85, 0.5), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif wnow == "breeze":
		# 날리는 잎 — 초록 낱장이 물결치며 지나간다
		draw_set_transform_matrix(get_canvas_transform().affine_inverse())
		var vp2: Vector2 = get_viewport_rect().size
		for lf in range(7):
			var lx: float = fmod(float(lf) * 151.0 + _t * 110.0, vp2.x + 40.0) - 20.0
			var ly: float = fmod(float(lf) * 233.0, vp2.y) + sin(_t * 3.0 + float(lf)) * 24.0
			draw_circle(Vector2(lx, ly), 2.6, Color(0.45, 0.62, 0.3, 0.75))
			draw_circle(Vector2(lx - 6.0, ly + 3.0), 1.8, Color(0.5, 0.68, 0.33, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ── 낮과 밤 ── 알림 표·말풍선보다는 아래, 마을 전부보다는 위.
	var sky: Color = _sky()
	if sky.a > 0.003:
		draw_set_transform_matrix(get_canvas_transform().affine_inverse())
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), sky)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 등불 — 열린 가게 계산대마다 따뜻한 불. 밤이 깊을수록 또렷해진다.
		# 장사는 밤에도 돈다(방치형이다) — 캄캄하기만 하면 죽은 마을로 보인다.
		var glow: float = sky.a / 0.34
		for gi in range(Content.SHOPS.size()):
			if not sim.shops.has(String(Content.SHOPS[gi].id)):
				continue
			var o3: Vector2i = Iso.org(sim, gi)
			var y3: Dictionary = Iso.yard(Iso.YARD_KIND[gi], Iso.plot_dim(sim, gi))
			var cp: Vector2 = Iso.w(o3.x + y3.counter.x + 0.5, o3.y + y3.counter.y + 0.5) + Vector2(0, -18)
			# 호롱불(유저) — 빛무리만 있으면 "어디서 나는 빛이지"가 된다.
			# 계산대 곁에 장대 하나, 그 끝에 호롱. 불꽃은 살짝 일렁인다.
			var lp: Vector2 = cp + Vector2(24, 16)
			draw_line(lp, lp + Vector2(0, -42), Color(0.32, 0.24, 0.16), 3.0)
			draw_line(lp + Vector2(0, -42), lp + Vector2(-9, -48), Color(0.32, 0.24, 0.16), 2.5)
			var flick: float = 0.85 + 0.15 * sin(_t * 9.0 + o3.x * 1.3)
			draw_circle(lp + Vector2(-9, -53), 4.5, Color(1.0, 0.82, 0.45, 0.95 * glow))
			draw_circle(lp + Vector2(-9, -53), 7.5, Color(1.0, 0.7, 0.3, 0.3 * glow * flick))
			for gr in [[54.0, 0.05], [36.0, 0.08], [20.0, 0.13]]:
				draw_circle(cp, gr[0], Color(1.0, 0.78, 0.4, gr[1] * glow))

	for i2 in range(Content.SHOPS.size()):
		if sim.shops.has(String(Content.SHOPS[i2].id)):
			_yard_signs(i2)
	# 칸 번호 자 — 맨 위에 그린다. 가구에 가리면 자 노릇을 못 한다.
	if show_grid:
		for gi2 in range(Content.SHOPS.size()):
			if not sim.shops.has(String(Content.SHOPS[gi2].id)):
				continue
			var go: Vector2i = Iso.org(sim, gi2)
			var gn: int = Iso.plot_dim(sim, gi2)
			for gy in range(gn):
				for gx in range(gn):
					var gp: Vector2 = Iso.w(go.x + gx + 0.5, go.y + gy + 0.5)
					_text(gp + Vector2(0, 5), str(gy * gn + gx + 1), 11, Color(0.15, 0.1, 0.05, 0.55))
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
