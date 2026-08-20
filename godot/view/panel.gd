extends PanelContainer
class_name ShopPanel
## 아래에서 올라오는 창. 가게를 누르면 여기서 강화·칸 열기·직원·승급을 한다.
##
## 지도에서 바로 되는 일(매대 눌러 강화)은 여기 없어도 된다. 이 창은
## **지도에서 못 하는 것**만 맡는다 — 자세한 숫자와 승급.

var sim: Sim
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
	shop_id = id
	visible = true
	rebuild()

func close() -> void:
	visible = false
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

func rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
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
