extends PanelContainer
class_name ShopPanel
## 아래에서 올라오는 창. 가게를 누르면 여기서 강화·칸 열기·직원·승급을 한다.
##
## 지도에서 바로 되는 일(매대 눌러 강화)은 여기 없어도 된다. 이 창은
## **지도에서 못 하는 것**만 맡는다 — 자세한 숫자와 승급.

var sim: Sim
## 창 한 틀에 세 가지를 담는다 — 가게 · 의뢰 · 손님 도감.
## 창을 세 개 만들면 여닫는 규칙도 세 벌이 되고, 그중 하나는 반드시 어긋난다.
var kind: String = ""
var shop_id: String = ""
## 가게 창 안의 갈피. 한 화면에 다 쏟으면 스크롤이 길어져서 아무것도 안 읽힌다.
var tab: String = "items"
const TABS := [["items", "제품"], ["work", "일손"], ["rank", "승급"]]
var _box: VBoxContainer
var _acc: float = 0.0
## 지도를 이 가게로 옮겨 달라고 부탁하는 줄. main이 꽂아 준다 —
## 창이 카메라를 직접 만지면 화면 규칙이 두 군데로 흩어진다.
var on_focus: Callable = Callable()
## 꾹 누르고 있는 품목. 누르는 동안 계속 오른다.
##
## ★ 단추의 button_up을 안 쓰는 이유: 이 창은 0.3초마다 통째로 다시 그린다.
##   그때 단추가 사라지므로 button_up이 영영 안 온다 — 손을 뗐는데 계속
##   올라가는 고장이 된다. 그래서 **뗀 것은 창이 직접 듣는다**(_input).
var _held: String = ""
var _held_t: float = 0.0
var _rep_t: float = 0.0

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 0
	offset_right = 0
	offset_top = -540
	# 배경을 안 깔면 지도가 글자 사이로 비쳐서 아무것도 못 읽는다
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f3e9d2")
	bg.border_color = Color("a8763e")
	bg.border_width_top = 3
	bg.corner_radius_top_left = 16
	bg.corner_radius_top_right = 16
	bg.content_margin_left = 14
	bg.content_margin_right = 14
	bg.content_margin_top = 12
	bg.content_margin_bottom = 12
	add_theme_stylebox_override("panel", bg)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_box)

func open_for(id: String) -> void:
	if shop_id != id:
		tab = "items"           # 다른 가게를 열면 제품부터. 남의 갈피가 남아 있으면 헷갈린다
	kind = "shop"
	shop_id = id
	visible = true
	_focus()
	rebuild()

## 이 가게가 화면 가운데 오게, 그리고 **창에 안 가리게**. 창을 열어 놓고
## 지도를 손으로 찾아 옮기는 것은 수고다 — 열 때 이미 거기를 보고 있어야 한다.
func _focus() -> void:
	if on_focus.is_valid() and shop_id != "":
		on_focus.call(shop_id)

## 열린 가게만 차례로. 안 연 가게로 넘어가면 빈 창이 나온다.
func _open_shops() -> Array:
	var out: Array = []
	for sh in Content.SHOPS:
		if sim.shops.has(String(sh.id)):
			out.append(String(sh.id))
	return out

func step_shop(dir: int) -> void:
	var list: Array = _open_shops()
	if list.size() < 2:
		return
	var i: int = list.find(shop_id)
	open_for(String(list[(i + dir + list.size()) % list.size()]))

func open_kind(k: String) -> void:
	# 같은 것을 다시 누르면 닫힌다 — 닫기 단추를 찾아 누르는 수고를 던다
	if visible and kind == k:
		close()
		return
	kind = k
	shop_id = ""
	visible = true
	rebuild()

func close() -> void:
	visible = false
	kind = ""
	shop_id = ""

func _input(e: InputEvent) -> void:
	# 어디서 뗐든 꾹 누르기는 끝난다. 단추가 다시 그려지며 사라져도 안전하다.
	if _held == "" :
		return
	if (e is InputEventMouseButton and not (e as InputEventMouseButton).pressed) \
			or (e is InputEventScreenTouch and not (e as InputEventScreenTouch).pressed):
		_held = ""

func _process(delta: float) -> void:
	if not visible:
		return
	# 꾹 누르고 있으면 계속 오른다. 처음 한 박자는 쉬어 준다 —
	# 안 그러면 한 번 톡 누른 것도 두세 단계가 올라간다.
	if _held != "":
		_held_t += delta
		# 처음 한 박자(0.35초)는 쉬어 준다 — 톡 누른 것까지 서너 단계가
		# 올라가면 "한 단계만 올리고 싶다"를 할 수가 없다.
		# 그다음은 초당 열두 번. 더 빠르면 멈추고 싶은 데서 못 멈춘다.
		if _held_t > 0.35:
			_rep_t += delta
			while _rep_t >= 0.08:
				_rep_t -= 0.08
				if sim.at_max(_held) or sim.level_up_many(_held, 1) == 0:
					_held = ""
					break
			_acc = 1.0                      # 오른 숫자를 바로 보여준다
	# 돈이 오르면 눌릴 수 있게 된 단추가 생긴다 — 자주 다시 그린다
	_acc += delta
	if _acc < 0.3:
		return
	_acc = 0.0
	rebuild()

func _btn(text: String, enabled: bool, cb: Callable, expand: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	if expand:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if enabled:
		b.pressed.connect(cb)
	return b

## ★ autowrap은 기본으로 끈다.
## 켜 놓고 가로줄(HBox)에 넣었더니 제목이 "대/장/간"으로 세로로 쪼개졌다 —
## 옆 것이 자리를 다 먹으면 글자 폭까지 줄어드는데, 줄바꿈이 켜져 있으면
## 그걸 "한 줄에 한 글자"로 받아들인다.
func _label(text: String, size: int, col: Color = Color("2b241b"), wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## 제목 줄 — 어느 창이든 같은 자리에 같은 모양으로
## 제목 줄 — 어느 창이든 같은 자리에 같은 모양으로.
##
## ★ 닫기 단추는 없앴다. 창 밖 아무 데나 누르면 닫히고, 아래 단추를 다시
##   누르면 닫힌다. 닫는 길이 셋이나 되면 그중 둘은 자리만 먹는다.
func _head(title_text: String) -> void:
	var title := _label(title_text, 21)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)

## 눈금 — 얼마나 찼는지가 숫자보다 먼저 읽혀야 한다
func _bar(ratio: float, col: Color) -> void:
	var p := ProgressBar.new()
	p.min_value = 0.0
	p.max_value = 1.0
	p.value = clampf(ratio, 0.0, 1.0)
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 10)
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.corner_radius_top_left = 5; fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_left = 5; fill.corner_radius_bottom_right = 5
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.17, 0.14, 0.11, 0.13)
	bg.corner_radius_top_left = 5; bg.corner_radius_top_right = 5
	bg.corner_radius_bottom_left = 5; bg.corner_radius_bottom_right = 5
	p.add_theme_stylebox_override("fill", fill)
	p.add_theme_stylebox_override("background", bg)
	_box.add_child(p)

func rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	match kind:
		"shop": _shop_body()
		"quests": _quests_body()
		"guests": _guests_body()
		"ledger": _ledger_body()

## ── 마을 의뢰와 젬 ──
func _quests_body() -> void:
	_head("마을 의뢰")

	# 기간제 이벤트 — 마감은 실제 시간이라 게임을 꺼도 줄어든다
	var e: Variant = sim.event_def()
	if e == null:
		var w: float = sim.event_wait()
		_box.add_child(_label("가게를 둘 열면 장이 선다" if sim.shops.size() < 2
			else "다음 장까지 %s" % _hhmm(w), 13, Color("8a7a63")))
	else:
		var got: float = min(sim.event.got, e.need)
		_box.add_child(_label("%s %s — %s 남음" % [e.face, e.name, _hhmm(sim.event_left())], 17, Color("a8763e")))
		_box.add_child(_label("%s — %d / %d" % [e.desc, int(got), int(e.need)], 13))
		_bar(got / e.need, Color("a8763e"))
		_box.add_child(_label("깨면 💎%d · %s · 못 깨도 잃는 것은 없다" % [int(e.gems), e.skinName], 11, Color("8a7a63")))
	if not sim.skins.is_empty():
		var names: Array[String] = []
		for k in sim.skins:
			for ev in Content.EVENTS:
				if ev.skin == k:
					names.append(String(ev.skinName))
		_box.add_child(_label("받은 것: %s  (그림은 나중에 붙는다)" % ", ".join(names), 11, Color("4a7c59")))

	_box.add_child(_label("가진 젬 💎%d · 의뢰를 마치거나, 품목을 만렙까지 올리거나, 나쁜 놈을 잡으면 모인다"
		% int(sim.gems), 13, Color("5a4e3d"), true))

	for q in sim.quests:
		var g: Dictionary = Sim.guest_by_id(q.gid)
		_box.add_child(_label("%s %s마을 — %s %d개  💎%d" % [
			g.face, g.name, sim.item_name(q.itemId), int(q.need), int(q.gems)], 14))
		_bar(q.got / q.need, Color("4a7c59"))
		_box.add_child(_label("%d / %d · %d성 %s · 마치면 🪙%s" % [
			int(q.got), int(q.need), sim.regular_star(q.gid), sim.regular_name(q.gid),
			Num.fmt(floor(sim.price(q.itemId) * q.need * Content.QUEST.payMul))], 11, Color("8a7a63")))
	if sim.quests.size() < sim.quest_slots():
		_box.add_child(_label("다음 의뢰가 오는 중… (%d초)" % int(ceil(max(0.0, sim._qCool))), 12, Color("8a7a63")))

	_box.add_child(_label("젬 쓰는 곳", 15, Color("5a4e3d")))
	_box.add_child(_label("👷 삯꾼 부르기 — %s" % ("삯꾼이 일하는 중… %d초" % int(ceil(sim.rush))
		if sim.rush > 0.0 else "%d초 동안 만드는 속도가 %d배"
		% [int(Content.GEM.rush.secs), int(Content.GEM.rush.mult)]), 13))
	_box.add_child(_btn("💎%d" % int(Content.GEM.rush.cost), sim.can_rush(),
		func(): sim.call_rush(); rebuild()))
	for u in Content.GEM_UPGRADES:
		var lv: int = int(sim.up_lv(u.id))
		var cost: Variant = sim.gem_cost(u.id)
		_box.add_child(_label("%s %s %d/%d — %s" % [u.face, u.name, lv, int(u.max), u.desc], 13))
		if cost == null:
			_box.add_child(_label("끝까지 올렸다", 11, Color("4a7c59")))
		else:
			_box.add_child(_btn("💎%d" % int(cost), sim.can_buy_gem_up(u.id),
				func(): sim.buy_gem_up(u.id); rebuild()))
	_box.add_child(_label("뽑기 · 룰렛 · 스킨 상점은 다음 판에 붙는다", 11, Color("8a7a63")))

func _hhmm(sec: float) -> String:
	var h: int = int(sec / 3600.0)
	var m: int = int(fmod(sec, 3600.0) / 60.0)
	return "%d시간 %d분" % [h, m] if h > 0 else "%d분" % m

## ── 손님 도감 ──
## 아직 안 온 손님도 자리를 비워 보여준다 — 몇이 더 남았는지, 무엇을 하면
## 오는지가 보여야 모으는 재미가 생긴다.
func _guests_body() -> void:
	_head("손님 도감")
	_box.add_child(_label("마을에 온 손님 %d / %d · 단골 등급 합계 %d" % [
		sim.guests.size(), Content.GUESTS.size(), sim.regular_sum()], 13, Color("5a4e3d")))
	for g in Content.GUESTS:
		if not sim.guests.has(String(g.id)):
			_box.add_child(_label("?  ? ? ?   누적 매출 🪙%s에 온다" % Num.fmt(g.at), 13, Color("8a7a63")))
			continue
		var lv: int = sim.regular_lv(String(g.id))
		var left: Variant = null
		if lv < Content.REGULARS.size() - 1:
			left = sim.regular_need(String(g.id), lv + 1) - sim.visits.get(g.id, 0.0)
		_box.add_child(_label("%s %s   %d성 %s   %s" % [
			g.face, g.name, lv + 1, Content.REGULARS[lv].name,
			"최고 등급" if left == null else "다음까지 %s번" % Num.fmt(float(left))], 14))
		_box.add_child(_label("%s · %d초마다 %d개 · 값 ×%s · 누적 %s개 / %s번" % [
			g.desc, int(g.every), int(g.qty), str(g.pay),
			Num.fmt(sim.bought.get(g.id, 0.0)), Num.fmt(sim.visits.get(g.id, 0.0))], 11, Color("8a7a63"), true))

## ── 장날 소식 ──
##
## ★ 그래프가 주인공이 아니라 **한 줄 소식**이 주인공이다.
##   "이번 장 핫템 — 호미!"가 먼저 읽히고, 그래프는 그 말의 근거일 뿐이다.
##   그래프를 먼저 놓으면 숫자를 읽어야 뜻을 알게 되는데, 그건 재미가 아니다.
func _ledger_body() -> void:
	_head("장날 소식")
	var days: int = int(Content.LEDGER.daysPerFair)
	_box.add_child(_label("%d번째 장 · %d일차 (게임내 %d일째)" % [
		sim.fair_no() + 1, sim.fair_day(), sim.day()], 12, Color("8a7a63")))

	var hot: Array = sim.hot_items(days, int(Content.LEDGER.topItems))
	if hot.is_empty():
		_box.add_child(_label("아직 이번 장에 판 것이 없다", 14, Color("8a7a63")))
		return

	# 한 줄 소식 둘 — 이게 사람들이 보러 오는 것이다
	var best_item: String = hot[0][0]
	_box.add_child(_label("이번 장 핫템 — %s!" % sim.item_name(best_item), 19, Color("a8763e")))
	var bb: String = sim.best_buyer(best_item, days)
	if bb != "":
		var g: Dictionary = Sim.guest_by_id(bb)
		_box.add_child(_label("제일 많이 사간 건 %s %s!" % [g.face, g.name], 15, Color("4a7c59")))

	# 막대 — 무엇이 잘 나갔나
	_box.add_child(_label("이번 장에 잘 나간 것", 13, Color("5a4e3d")))
	var bars: Array = []
	for r in hot:
		bars.append([Sim.item_by_id(r[0]).icon, Sim.item_by_id(r[0]).name, r[1]])
	var c1 := Chart.new()
	_box.add_child(c1)
	c1.setup(Chart.Kind.BAR, bars, hot.size() * 26.0 + 6.0)

	# 원형 — 그 물건의 몫을 누가 가져갔나
	_box.add_child(_label("%s를 사간 동물" % Sim.item_by_id(best_item).name, 13, Color("5a4e3d")))
	var who: Array = sim.buyers_of(best_item, days, int(Content.LEDGER.topBuyers))
	var slices: Array = []
	var shown: float = 0.0
	var all: Array = sim.buyers_of(best_item, days, 99)
	for r in who:
		slices.append([Sim.guest_by_id(r[0]).face, Sim.guest_by_id(r[0]).name, r[1]])
		shown += float(r[1])
	var rest: float = 0.0
	for r in all:
		rest += float(r[1])
	rest -= shown
	if rest > 0.0:
		slices.append(["🐾", "그 밖에", rest])
	var c2 := Chart.new()
	_box.add_child(c2)
	c2.setup(Chart.Kind.PIE, slices, 160.0)

	# 마을별 핫템 — "토끼들의 핫템은 호미!"
	_box.add_child(_label("마을마다 잘 나가는 것", 13, Color("5a4e3d")))
	for gid in sim.guests:
		var h: String = sim.hot_for(gid, days)
		if h == "":
			continue
		var gg: Dictionary = Sim.guest_by_id(gid)
		_box.add_child(_label("%s %s마을 — %s" % [gg.face, gg.name, sim.item_name(h)], 13))

## ── 가게 ──
##
## 갈피(탭) 셋으로 가른다. 예전엔 제품·직원·강화·승급을 한 줄로 다 쏟았는데,
## 매대가 여덟 칸까지 늘면 승급 조건은 스크롤 저 아래라 아무도 안 봤다.
## 자주 만지는 것(제품)과 가끔 보는 것(승급)은 같은 화면에 있을 이유가 없다.
func _shop_body() -> void:
	if shop_id == "":
		return
	var shop: Dictionary = Sim.shop_by_id(shop_id)

	# 제목 줄 — ‹ 가게 이름 ›. 화살표로 옆 가게로 건너간다(지도도 따라 옮긴다).
	var many: bool = _open_shops().size() > 1
	var head := HBoxContainer.new()
	head.add_child(_btn("‹", many, func(): step_shop(-1), false))
	var title := _label("%s %s   %s" % [shop.sign, shop.name, shop.ranks[sim.rank_of(shop_id)]], 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_btn("›", many, func(): step_shop(1), false))
	_box.add_child(head)

	# 갈피 줄
	var bar := HBoxContainer.new()
	for t in TABS:
		var key: String = String(t[0])
		var b := _btn(String(t[1]), tab != key, func(): tab = key; rebuild())
		b.disabled = tab == key          # 지금 보고 있는 갈피는 눌러도 소용없다
		bar.add_child(b)
	_box.add_child(bar)

	match tab:
		"items": _tab_items(shop)
		"work": _tab_work(shop)
		"rank": _tab_rank(shop)

## 한 줄에 그림 하나 + 글 뭉치. 그림이 없으면 이모지가 그 자리에 선다
## (art/items/<id>.png가 들어오면 여기만 갈아 끼운다).
func _item_row(icon: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ic := _label(icon, 30)
	ic.custom_minimum_size = Vector2(42, 46)
	ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	return row

func _tab_items(shop: Dictionary) -> void:
	var cap: int = sim.stall_cap(shop_id)
	for k in range(min(cap, shop.items.size())):
		var it: Dictionary = shop.items[k]
		var row: HBoxContainer = _item_row(String(it.icon))
		var col: VBoxContainer = row.get_child(1)
		if sim.is_open(it.id):
			col.add_child(_label("%s   Lv.%d/%d   🪙%s" % [
				sim.item_name(it.id), int(sim.lv(it.id)), int(sim.max_lv(it.id)),
				Num.fmt(sim.price(it.id))], 14))
			col.add_child(_label("재고 %d/%d · %.1f초" % [
				int(sim.items[it.id].stock), int(sim.cap_of(it.id)), sim.craft_time(it.id)],
				11, Color("8a7a63")))
			if sim.at_max(it.id):
				col.add_child(_label("더 올릴 수 없다 — 승급해야 한다", 12, Color("8a7a63")))
			else:
				col.add_child(_level_btn(String(it.id)))
		elif sim.asked.has(it.id):
			col.add_child(_label("%s — 손님이 찾던 물건" % it.name, 14))
			col.add_child(_btn("칸 열기 🪙" + Num.fmt(it.cost), sim.can_open_item(it.id),
				func(): sim.open_item(it.id); rebuild()))
		else:
			col.add_child(_label("? ? ?   아직 아무도 찾지 않았다", 13, Color("8a7a63")))
		_box.add_child(row)

	if shop.items.size() > cap:
		_box.add_child(_label("승급하면 매대 %d칸이 더 생긴다" % (shop.items.size() - cap), 12, Color("8a7a63")))

## 강화 단추 하나.
##
## ★ 예전엔 [레벨업][×10][최대] 셋이었다. 셋은 고민거리가 아니라 산수 문제다 —
##   "지금 돈으로 몇 번이 되지?"를 사람이 대신 풀어야 했다.
##   하나로 줄이고, **꾹 누르면 원하는 만큼** 오른다.
##   그리고 지금 돈으로 만렙까지 갈 수 있으면 단추가 스스로 '최대'로 바뀐다 —
##   그때는 한 번 누르는 게 맞고, 그 사실을 사람이 알아채야 할 이유가 없다.
func _level_btn(id: String) -> Button:
	var need: int = int(sim.max_lv(id) - sim.lv(id))
	var afford: int = sim.affordable_levels(id)
	if need > 0 and afford >= need:
		return _btn("최대 Lv.%d 🪙%s" % [int(sim.max_lv(id)), Num.fmt(sim.level_cost_many(id, need))],
			true, func(): sim.level_up_many(id, need); rebuild())
	var c: float = sim.level_cost(id)
	var b: Button = _btn("레벨업 🪙" + Num.fmt(c), sim.money >= c,
		func(): sim.level_up_many(id, 1); rebuild())
	if sim.money >= c:
		# 꾹 누르기는 여기서 시작만 한다 — 끝내는 것은 창이 듣는다(_input)
		b.button_down.connect(func(): _held = id; _held_t = 0.0; _rep_t = 0.0)
	return b

## 일손과 이 가게만의 강화. 둘 다 "한 번 사면 계속 도는 것"이라 같이 둔다.
func _tab_work(_shop: Dictionary) -> void:
	var smax: float = sim.staff_max(shop_id)
	_box.add_child(_label("일손  점장 1 + 직원 %d/%d" % [int(sim.staff_of(shop_id)), int(smax)], 15))
	_box.add_child(_label("직원이 있으면 계산 중에도 생산이 안 멈춘다", 11, Color("8a7a63")))
	if sim.staff_of(shop_id) < smax:
		var sc: float = sim.staff_cost(shop_id)
		_box.add_child(_btn("직원 들이기 🪙" + Num.fmt(sc), sim.can_hire_staff(shop_id),
			func(): sim.hire_staff(shop_id); rebuild()))
	else:
		_box.add_child(_label("이 등급에서 쓸 수 있는 일손은 다 찼다", 12, Color("4a7c59")))

	var ud: Variant = sim.shop_up_def(shop_id)
	if ud == null:
		return
	var ulv: int = sim.shop_up_lv(shop_id)
	_box.add_child(_label("%s %s  %d/%d" % [ud.face, ud.name, ulv, int(ud.max)], 15))
	_box.add_child(_label(String(ud.desc), 11, Color("8a7a63"), true))
	_bar(float(ulv) / float(ud.max), Color("a8763e"))
	var uc: Variant = sim.shop_up_cost(shop_id)
	if uc == null:
		_box.add_child(_label("끝까지 올렸다", 12, Color("4a7c59")))
	else:
		_box.add_child(_btn("올리기 🪙" + Num.fmt(uc), sim.can_buy_shop_up(shop_id),
			func(): sim.buy_shop_up(shop_id); rebuild()))

## 승급 — 못 하는 이유가 보여야 목표가 된다. 체크리스트로 세운다.
func _tab_rank(shop: Dictionary) -> void:
	var r: Variant = sim.promote_reqs(shop_id)
	if r == null:
		_box.add_child(_label("%s 등급 — 더 오를 곳이 없다" % shop.ranks[sim.rank_of(shop_id)], 15, Color("a8763e")))
		return
	_box.add_child(_label("%s → %s 등급" % [shop.ranks[sim.rank_of(shop_id)], shop.ranks[r.rank]], 17, Color("a8763e")))
	var done: int = 0
	for x in r.list:
		if x.ok:
			done += 1
	_bar(float(done) / float(r.list.size()), Color("4a7c59"))
	_box.add_child(_label("조건 %d / %d" % [done, r.list.size()], 11, Color("8a7a63")))
	for x in r.list:
		_box.add_child(_label(("✅ " if x.ok else "⬜ ") + String(x.text), 13,
			Color("4a7c59") if x.ok else Color("5a4e3d"), true))
	var ok: bool = sim.can_promote(shop_id)
	_box.add_child(_btn("승급하기 🪙" + Num.fmt(r.cost) if ok else "조건을 채워야 한다", ok,
		func(): sim.promote(shop_id); rebuild()))
	_box.add_child(_label("승급하면 매대가 늘고, 값이 오르고, 일손을 더 쓸 수 있다", 11, Color("8a7a63"), true))
