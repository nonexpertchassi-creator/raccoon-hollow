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
var _box: VBoxContainer
var _acc: float = 0.0

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
	kind = "shop"
	shop_id = id
	visible = true
	rebuild()

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

func _process(delta: float) -> void:
	if not visible:
		return
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
func _head(title_text: String) -> void:
	var head := HBoxContainer.new()
	var title := _label(title_text, 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_btn("닫기", true, close, false))
	_box.add_child(head)

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
	if sim.quests.size() < int(Content.QUEST.slots):
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

## ── 가게 ──
func _shop_body() -> void:
	if shop_id == "":
		return
	var shop: Dictionary = Sim.shop_by_id(shop_id)
	var head := HBoxContainer.new()
	var title := _label("%s %s" % [shop.sign, shop.name], 21)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_btn("닫기", true, close, false))
	_box.add_child(head)
	_box.add_child(_label(String(shop.desc), 12, Color("5a4e3d")))

	var cap: int = sim.stall_cap(shop_id)
	for k in range(min(cap, shop.items.size())):
		var it: Dictionary = shop.items[k]
		var row := VBoxContainer.new()
		if sim.is_open(it.id):
			var at_max: bool = sim.at_max(it.id)
			row.add_child(_label("%s   Lv.%d/%d   🪙%s   재고 %d/%d   %.1f초" % [
				sim.item_name(it.id), int(sim.lv(it.id)), int(sim.max_lv(it.id)),
				Num.fmt(sim.price(it.id)), int(sim.items[it.id].stock),
				int(sim.cap_of(it.id)), sim.craft_time(it.id)], 14))
			if at_max:
				row.add_child(_label("더 올릴 수 없다 — 가게를 승급해야 한다", 12, Color("8a7a63")))
			else:
				var line := HBoxContainer.new()
				var c1: float = sim.level_cost(it.id)
				line.add_child(_btn("레벨업 🪙" + Num.fmt(c1), sim.money >= c1,
					func(): sim.level_up_many(it.id, 1); rebuild()))
				line.add_child(_btn("×10", sim.money >= sim.level_cost_many(it.id, 10),
					func(): sim.level_up_many(it.id, 10); rebuild()))
				line.add_child(_btn("최대", sim.affordable_levels(it.id) > 0,
					func(): sim.level_up_many(it.id, sim.affordable_levels(it.id)); rebuild()))
				row.add_child(line)
		elif sim.asked.has(it.id):
			row.add_child(_label("%s — 손님이 찾던 물건" % it.name, 14))
			row.add_child(_btn("칸 열기 🪙" + Num.fmt(it.cost), sim.can_open_item(it.id),
				func(): sim.open_item(it.id); rebuild()))
		else:
			row.add_child(_label("? ? ?   아직 아무도 찾지 않았다", 13, Color("8a7a63")))
		_box.add_child(row)

	if shop.items.size() > cap:
		_box.add_child(_label("승급하면 매대 %d칸이 더 생긴다" % (shop.items.size() - cap), 12, Color("8a7a63")))

	# 직원
	var smax: float = sim.staff_max(shop_id)
	if sim.staff_of(shop_id) < smax:
		var sc: float = sim.staff_cost(shop_id)
		_box.add_child(_label("일손  점장 1 + 직원 %d/%d · 계산 중에도 생산이 안 멈춘다" % [
			int(sim.staff_of(shop_id)), int(smax)], 13))
		_box.add_child(_btn("직원 들이기 🪙" + Num.fmt(sc), sim.can_hire_staff(shop_id),
			func(): sim.hire_staff(shop_id); rebuild()))

	# 승급 — 못 하는 이유가 보여야 목표가 된다
	var r: Variant = sim.promote_reqs(shop_id)
	if r == null:
		_box.add_child(_label("%s 등급 — 더 오를 곳이 없다" % shop.ranks[sim.rank_of(shop_id)], 13, Color("a8763e")))
	else:
		var ok: bool = sim.can_promote(shop_id)
		_box.add_child(_label("%s → %s 등급으로 승급" % [
			shop.ranks[sim.rank_of(shop_id)], shop.ranks[r.rank]], 15, Color("a8763e")))
		for x in r.list:
			_box.add_child(_label(("✓ " if x.ok else "· ") + String(x.text), 12,
				Color("4a7c59") if x.ok else Color("8a7a63")))
		_box.add_child(_btn("승급하기 🪙" + Num.fmt(r.cost) if ok else "조건을 채워야 한다", ok,
			func(): sim.promote(shop_id); rebuild()))
