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
## 카드 한 장이 열렸다고 알리는 줄. 승급은 이 창에서 일어난다.
var on_card: Callable = Callable()
## 뽑은 결과를 화면에 넘긴다(카드가 넘어가는 연출은 main이 맡는다)
var on_pull: Callable = Callable()
## 룰렛을 돌려 달라고 부탁한다. 광고 기다리기가 있어서 main이 맡는다.
var on_spin: Callable = Callable()
## 바퀴가 멈췄다고 알리는 줄 — 그때 결과 창을 띄운다
var on_landed: Callable = Callable()
## 뽑기용 주사위. sim의 주사위는 tick이 쓰고 있으니 여기서 따로 굴린다.
var _rng: Rng = Rng.new(20260822)
## 꾹 누르고 있는 품목. 누르는 동안 계속 오른다.
##
## ★ 단추의 button_up을 안 쓰는 이유: 이 창은 0.3초마다 통째로 다시 그린다.
##   그때 단추가 사라지므로 button_up이 영영 안 온다 — 손을 뗐는데 계속
##   올라가는 고장이 된다. 그래서 **뗀 것은 창이 직접 듣는다**(_input).
var _held: String = ""
var _held_t: float = 0.0
var _rep_t: float = 0.0
## 손가락이 창에 닿아 있는 동안은 **다시 그리지 않는다.**
##
## ★ 이걸 안 하면 화살표와 갈피가 열 번에 서너 번 안 먹는다.
##   창은 0.3초마다 통째로 다시 그리는데, 누르는 순간과 떼는 순간 사이에
##   그 일이 벌어지면 단추가 사라져 버린다. Godot은 **누른 단추와 뗀 단추가
##   같을 때만** '눌렸다'로 치므로, 사라진 단추는 아무 일도 안 한다.
##   게다가 뗀 자리가 빈 곳이 되면 그 누름이 지도까지 흘러가 창이 닫힌다 —
##   유저가 본 "이전 가게를 눌렀는데 창이 닫힌다"가 이것이다.
var _pressing: bool = false
## 꾹 누르는 동안 글자만 고쳐 쓸 두 곳
var _held_btn: Button = null
var _held_line: Label = null

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# ★ 창 위를 누른 것은 **절대 지도로 새어 나가면 안 된다.**
	#   이걸 안 박아 두면, 단추가 아닌 빈 자리를 눌렀을 때 그 누름이 지도까지
	#   내려가 "빈 곳을 눌렀다"로 처리되어 창이 닫힌다.
	mouse_filter = Control.MOUSE_FILTER_STOP
	offset_left = 0
	offset_right = 0
	# 폰에서 보니 창이 쓸데없이 컸다 — 화면의 6할을 덮으면 마을이 안 보이고,
	# 그러면 "지금 뭘 하고 있었지"를 잃는다. 목록은 어차피 밀어서 본다.
	offset_top = -430
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
	scroll.custom_minimum_size = Vector2(0, 392)
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
	if kind != k:
		tab = "items"           # 갈피는 늘 첫 장부터. 남의 갈피가 남아 있으면 헷갈린다
	kind = k
	shop_id = ""
	visible = true
	rebuild()

func close() -> void:
	visible = false
	kind = ""
	shop_id = ""

func _input(e: InputEvent) -> void:
	var down: Variant = null
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		down = (e as InputEventMouseButton).pressed
	elif e is InputEventScreenTouch:
		down = (e as InputEventScreenTouch).pressed
	if down == null:
		return
	_pressing = bool(down)
	# 어디서 뗐든 꾹 누르기는 끝난다. 단추가 다시 그려지며 사라져도 안전하다.
	if not _pressing:
		_held = ""
		_held_btn = null
		_held_line = null

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
			_refresh_held()
	# 돈이 오르면 눌릴 수 있게 된 단추가 생긴다 — 자주 다시 그린다.
	# 다만 손가락이 닿아 있는 동안은 참는다(위 _pressing 설명).
	_acc += delta
	if _acc < 0.3 or _pressing:
		return
	_acc = 0.0
	rebuild()

## 꾹 누르는 동안 오르는 숫자를 보여준다 — **다시 그리지 않고 글자만 고쳐 쓴다.**
##
## ★ 통째로 다시 그렸더니 누르고 있던 단추가 사라졌고, 손을 뗀 자리가 빈 곳이
##   되면서 그 누름이 지도로 흘러가 **창이 닫혔다.** 유저가 "레벨업 한 번
##   눌렀는데 바텀시트가 닫힌다"고 한 게 이것이다.
##   손가락이 닿아 있는 동안은 무엇도 지우지 않는다. 글자만 바꾼다.
func _refresh_held() -> void:
	if _held == "" or _held_line == null or _held_btn == null:
		return
	_held_line.text = "%s   Lv.%d/%d   🪙%s" % [sim.item_name(_held), int(sim.lv(_held)),
		int(sim.max_lv(_held)), Num.fmt(sim.price(_held))]
	if sim.at_max(_held):
		_held_btn.text = "끝까지 올렸다"
		_held_btn.disabled = true
		return
	var c: float = sim.level_cost(_held)
	_held_btn.text = "레벨업 🪙" + Num.fmt(c)
	_held_btn.disabled = sim.money < c

## 손가락으로 누르는 단추 — 글자는 작아도 **누르는 자리는 커야 한다.**
func _wide_btn(text: String, enabled: bool, cb: Callable) -> Button:
	var b: Button = _btn(text, enabled, cb, false)
	b.custom_minimum_size = Vector2(52, 48)
	b.add_theme_font_size_override("font_size", 24)
	return b

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
		c.visible = false       # queue_free는 프레임 끝에 지워진다 — 그동안 겹쳐 보이면 깜박인다
		c.queue_free()
	match kind:
		"shop": _shop_body()
		"quests": _quests_body()
		"guests": _guests_body()
		"ledger": _ledger_body()
		"gacha": _fair_body()

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
## 도감 — **한 창에 갈피 둘**(손님 · 점장 카드).
## 창을 따로 만들면 아래 단추가 넷이 되고, 폰에서 넷은 누르다 틀린다.
## 가게 창에서 쓴 수법을 그대로 쓴다.
func _guests_body() -> void:
	_head("도감")
	var bar := HBoxContainer.new()
	for t in [["items", "손님"], ["work", "점장 카드"]]:
		var key: String = String(t[0])
		var b := _btn(String(t[1]), true, func(): tab = key; rebuild())
		b.disabled = tab == key
		bar.add_child(b)
	_box.add_child(bar)
	if tab == "work":
		_cards_body()
		return
	_guest_list()

## 점장 카드 — **가진 것에서 계산한다.** 따로 담아 두지 않는다.
## 가게가 열렸으면 그 가게 0등급 카드가 있는 것이고, 승급했으면 그만큼 더 있다.
func _cards_body() -> void:
	var have: int = 0
	var all: int = 0
	for sh in Content.SHOPS:
		all += (sh.ranks as Array).size()
		if sim.shops.has(String(sh.id)):
			have += sim.rank_of(String(sh.id)) + 1
	_box.add_child(_label("모은 카드 %d / %d" % [have, all], 13, Color("5a4e3d")))
	_box.add_child(_label("가게를 되살리거나 승급하면 한 장씩 열린다", 11, Color("8a7a63")))
	for sh in Content.SHOPS:
		var open: bool = sim.shops.has(String(sh.id))
		var got: int = (sim.rank_of(String(sh.id)) + 1) if open else 0
		_box.add_child(_label("%s %s   %d / %d" % [sh.sign, sh.name, got, (sh.ranks as Array).size()], 15))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		for k in range((sh.ranks as Array).size()):
			var mine: bool = k < got
			var slot := _label(("%s %s" % [sh.ranks[k], sh.name]) if mine else "? ? ?", 12,
				Color("4a7c59") if mine else Color("b3a992"))
			slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.custom_minimum_size = Vector2(0, 46)
			slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(slot)
		_box.add_child(row)

## 도감 — **카드가 판으로 깔린다.** 뽑기 결과와 같은 말이다.
## 만난 손님은 카드로, 아직 못 만난 손님은 ?로. 누르면 크게 뜨고 거기서 성을 올린다.
## 글줄로 서른 줄을 쌓으면 도감이 아니라 장부가 된다 — 모은 것은 펼쳐 보여야 한다.
var codex_tiles: Dictionary = {}     ## 손님 id → 단추 (시험이 눌러 보려고 잡아 둔다)
var on_guest: Callable = Callable()  ## 카드를 눌렀다 — 크게 띄우는 것은 main이 맡는다
## 소리. 지도에서 하던 강화가 창으로 들어오면서 소리도 따라왔다.
var sfx: Sfx = null

func _guest_list() -> void:
	_box.add_child(_label("만난 손님 %d / %d · 성 합계 %d" % [
		sim.guests.size(), Content.GUESTS.size(), sim.regular_sum()], 13, Color("5a4e3d")))
	codex_tiles = {}
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_box.add_child(grid)
	for g in Content.GUESTS:
		var gid: String = String(g.id)
		var met: bool = sim.guests.has(gid)
		var gr: Dictionary = Content.CARD_GRADES[int(g.grade) - 1]
		var b := Button.new()
		b.custom_minimum_size = Vector2(70, 96)
		var st := StyleBoxFlat.new()
		st.bg_color = Color("f6efdc") if met else Color("e2d6bb")
		st.border_color = Color(gr.color) if met else Color("c9bda1")
		st.set_border_width_all(2)
		st.set_corner_radius_all(8)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", st)
		b.add_theme_stylebox_override("disabled", st)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		b.add_child(v)
		var face := _label(String(g.face) if met else "?", 24, Color("2b241b") if met else Color("b3a992"))
		face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(face)
		var nm := _label(String(g.name) if met else String(gr.name), 10,
			Color("5a4e3d") if met else Color("b3a992"))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nm)
		if met:
			# ★n성, 그리고 올릴 수 있으면 비취색으로 알린다 — 서른 칸을
			# 하나하나 열어 보게 하면 아무도 안 올린다
			var can: bool = sim.can_star_up(gid)
			var tail := _label("▲ 올릴 수 있다" if can else "★%d" % sim.regular_star(gid), 9.5,
				Color("4a7c59") if can else Color("a8763e"))
			tail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(tail)
			b.pressed.connect(func():
				if on_guest.is_valid():
					on_guest.call(gid))
		else:
			b.disabled = true
		grid.add_child(b)
		codex_tiles[gid] = b

## ── 뽑기 ──
##
## ★ 확률표를 **접어 두지 않고 그대로 보여준다.** 확률을 숨기는 뽑기는
##   만들지 않는다 — 나라마다 법으로 정해 놓은 곳도 있고, 무엇보다
##   숨기면 "속았다"가 남는다.
## 뽑기와 룰렛은 **한 창에 갈피 둘**로 넣는다.
## 아래 단추가 다섯이 되면 폰에서 누르다 틀린다 — FLOW.md에 적어 둔 그 이유다.
## 둘 다 "운으로 얻는 것"이라 한자리에 있는 게 뜻도 맞는다.
func _fair_body() -> void:
	_head("뽑기와 룰렛")
	var bar := HBoxContainer.new()
	for t in [["items", "뽑기"], ["work", "룰렛"]]:
		var key: String = String(t[0])
		var b := _btn(String(t[1]), true, func(): tab = key; rebuild())
		b.disabled = tab == key
		bar.add_child(b)
	_box.add_child(bar)
	if tab == "work":
		_roulette_body()
	else:
		_gacha_body()

func _gacha_body() -> void:
	var lv: int = sim.gacha_lv()
	var nxt: Variant = sim.gacha_next()
	# 단계 옆 물음표 — 누르면 확률표가 작은 글씨로 펴진다(유저). 표를 늘
	# 펴 두면 뽑기 단추가 화면 아래로 밀렸다. 숨기는 게 아니라 접는 것이다 —
	# 한 번 누르면 나오고, 낱낱이 다 적혀 있다.
	var lvrow := HBoxContainer.new()
	var lvlbl: Label = _label("뽑기 %d단계 · 여태 %s번 뽑았다" % [lv, Num.fmt(sim.pulls)], 15, Color("a8763e"))
	lvlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvrow.add_child(lvlbl)
	var qb := _btn("?", true, func(): show_rates = not show_rates; rebuild())
	qb.custom_minimum_size = Vector2(34, 0)
	qb.size_flags_horizontal = Control.SIZE_SHRINK_END   # 안 그러면 줄 반을 먹는다
	lvrow.add_child(qb)
	_box.add_child(lvrow)
	if nxt == null:
		_box.add_child(_label("만렙이다 — 제일 좋은 확률이다", 12, Color("4a7c59")))
	else:
		var span: float = float(Content.GACHA.levelAt[lv]) - float(Content.GACHA.levelAt[lv - 1])
		_bar(1.0 - float(nxt) / span, Color("a8763e"))
		_box.add_child(_label("%s번 더 뽑으면 %d단계 — 좋은 카드가 더 자주 나온다"
			% [Num.fmt(float(nxt)), lv + 1], 12, Color("8a7a63")))
	_box.add_child(_label("가진 젬 💎%d" % int(sim.gems), 14, Color("5a4e3d")))

	var row := HBoxContainer.new()
	for c in Content.GACHA.cost:
		var n: int = int(c.n)
		row.add_child(_btn("%d회\n💎%d" % [n, int(c.gems)], sim.can_pull(n),
			func(): _do_pull(n)))
	_box.add_child(row)
	if int(Content.GACHA.tenPity) <= lv:
		_box.add_child(_label("열 장 이상 뽑으면 드묾 이상 한 장은 반드시 나온다", 11, Color("4a7c59")))

	if show_rates:
		_box.add_child(_label("지금 단계의 확률", 13, Color("5a4e3d")))
		var rates: Array = sim.gacha_rates()
		for i in range(rates.size()):
			var gr: Dictionary = Content.CARD_GRADES[i]
			var pct: float = float(rates[i])
			var line := HBoxContainer.new()
			var nm: Label = _label("%s %s" % [gr.face, gr.name], 11,
				Color(gr.color) if pct > 0.0 else Color("b3a992"))
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(nm)
			line.add_child(_label(("%.1f%%" % pct) if pct > 0.0 else "안 나옴", 11,
				Color("2b241b") if pct > 0.0 else Color("b3a992"), false))
			_box.add_child(line)
		_box.add_child(_label("등급 안에서는 손님마다 똑같은 확률이다. 흔함 8종 · 드묾 7종 · 귀함 6종 · 진귀 5종 · 영물 3종 · 신수 1종.",
			10, Color("8a7a63"), true))

func _do_pull(n: int) -> void:
	var got: Array = sim.pull(n, _rng)
	if got.is_empty():
		return
	if on_pull.is_valid():
		on_pull.call(got)
	rebuild()

## ── 룰렛 ──
## 창을 다시 그려도 바퀴는 **살려 둔다.** 돌고 있는 중에 새로 만들면
## 그 순간 각도가 0으로 돌아가 바퀴가 튄다.
var wheel: Wheel = null
## 뽑기 확률표를 펴 놨나 — 물음표(?)로 접었다 편다
var show_rates: bool = false

func _roulette_body() -> void:
	sim.roul_refill()
	if wheel == null:
		wheel = Wheel.new()
		wheel.sim = sim
		if on_landed.is_valid():
			wheel.landed.connect(func(_w: int): on_landed.call())
	if wheel.get_parent() != null:
		wheel.get_parent().remove_child(wheel)
	_box.add_child(wheel)
	_box.add_child(_label("오늘 남은 횟수 — 무료 %d · 광고 %d" % [
		int(sim.roulFree), int(sim.roulAd)], 15, Color("a8763e")))
	_box.add_child(_label("매일 자정에 다시 찬다", 11, Color("8a7a63")))
	var row := HBoxContainer.new()
	row.add_child(_btn("무료로 돌리기", sim.can_spin(false), func(): _do_spin(false)))
	row.add_child(_btn("광고 보고 돌리기", sim.can_spin(true), func(): _do_spin(true)))
	_box.add_child(row)
	_box.add_child(_label("※ 광고는 아직 **더미**다 — 누르면 잠깐 기다렸다 보상이 나온다.",
		11, Color("8a7a63"), true))

	_box.add_child(_label("칸과 확률", 15, Color("5a4e3d")))
	_box.add_child(_label("바퀴가 멈추는 칸은 **돌리기 전에 이미 정해진다.** 바퀴는 그 칸에 맞춰 도는 것이다.",
		11, Color("8a7a63"), true))
	for w in Content.ROULETTE.wedges:
		var line := HBoxContainer.new()
		var nm: Label = _label(String(w.label), 13)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(nm)
		line.add_child(_label("%d%%" % int(w.weight), 13, Color("5a4e3d"), false))
		_box.add_child(line)
	_box.add_child(_label("엽전은 **지금 초당 수입의 몇 초치**다 — 언제 돌려도 값이 비슷하도록.",
		11, Color("8a7a63"), true))

func _do_spin(by_ad: bool) -> void:
	if on_spin.is_valid():
		on_spin.call(by_ad)

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
	# ★ 화살표는 **손가락 크기**로. 글자 크기대로 두었더니 폰에서 너무 작았다.
	#   애플이 권하는 최소 크기가 44pt인데, 글자 하나짜리 단추는 그 절반도 안 된다.
	head.add_child(_wide_btn("‹", many, func(): step_shop(-1)))
	var title := _label("%s %s   %s" % [shop.sign, shop.name, shop.ranks[sim.rank_of(shop_id)]], 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_wide_btn("›", many, func(): step_shop(1)))
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
func _item_row(icon: String, id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var t: Texture2D = Art.ranked("items", id, sim.rank_of(shop_id))
	if t != null:
		var tr := TextureRect.new()
		tr.texture = t
		tr.custom_minimum_size = Vector2(42, 52)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(tr)
	else:
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
		var row: HBoxContainer = _item_row(String(it.icon), String(it.id))
		var col: VBoxContainer = row.get_child(1)
		if sim.is_open(it.id):
			var line: Label = _label("%s   Lv.%d/%d   🪙%s" % [
				sim.item_name(it.id), int(sim.lv(it.id)), int(sim.max_lv(it.id)),
				Num.fmt(sim.price(it.id))], 14)
			col.add_child(line)
			col.add_child(_label("재고 %d/%d · %.1f초" % [
				int(sim.items[it.id].stock), int(sim.cap_of(it.id)), sim.craft_time(it.id)],
				11, Color("8a7a63")))
			if sim.at_max(it.id):
				col.add_child(_label("더 올릴 수 없다 — 승급해야 한다", 12, Color("8a7a63")))
			else:
				col.add_child(_level_btn(String(it.id), line))
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
func _level_btn(id: String, line: Label) -> Button:
	var need: int = int(sim.max_lv(id) - sim.lv(id))
	var afford: int = sim.affordable_levels(id)
	if need > 0 and afford >= need:
		return _btn("최대 Lv.%d 🪙%s" % [int(sim.max_lv(id)), Num.fmt(sim.level_cost_many(id, need))],
			true, func(): sim.level_up_many(id, need); rebuild())
	var c: float = sim.level_cost(id)
	var b := Button.new()
	b.text = "레벨업 🪙" + Num.fmt(c)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = sim.money < c
	if not b.disabled:
		# ★ '눌렸다(pressed)'가 아니라 **'누르기 시작했다(button_down)'**에 건다.
		#   pressed는 누른 단추와 뗀 단추가 같아야 오는데, 꾹 누르는 동안
		#   창이 다시 그려지면 그 단추는 이미 없다 — 톡 누른 것이 통째로
		#   사라진다. 시작에 걸면 다시 그려지든 말든 한 단계는 확실히 오른다.
		b.button_down.connect(func():
			sim.level_up_many(id, 1)
			if sfx != null:
				sfx.play("tap")
			_held = id
			_held_t = 0.0
			_rep_t = 0.0
			_held_btn = b
			_held_line = line
			_refresh_held())
	return b

## 일손과 이 가게만의 강화. 둘 다 "한 번 사면 계속 도는 것"이라 같이 둔다.
func _tab_work(_shop: Dictionary) -> void:
	_box.add_child(_label("일손  점장 1 + 직원 %d" % int(sim.staff_of(shop_id)), 15))
	# 2026-08-25 생산 개편 — 손 하나가 물건 하나를 만든다. 직원마다 만드는
	# 손이 하나씩 는다. 점장은 만들다가 계산도 한다(계산 중엔 손이 빠진다).
	_box.add_child(_label("손 하나가 물건 하나를 만든다 — 직원마다 만드는 손이 하나 는다", 11, Color("8a7a63"), true))
	# 직원을 돈으로 사는 단추는 지웠다(유저 — 한 번에 넷을 사는 게 이상했다).
	_box.add_child(_label("직원은 **가게가 승급할 때** 한 마리씩 온다", 12, Color("4a7c59"), true))

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
	# 승급하면 뭐가 좋아지는가. 조건만 늘어놓고 좋은 점을 안 적으면
	# "이걸 왜 해야 하지"가 된다 — 목표는 조건이 아니라 그 뒤에 오는 것이다.
	var g: Variant = sim.promote_gain(shop_id)
	if g != null:
		_box.add_child(_label("승급하면", 15, Color("a8763e")))
		_box.add_child(_label("· 값이 ×%d — 물건 이름도 '%s'로 바뀐다" % [
			int(g.priceMul), shop.ranks[g.rank]], 13))
		_box.add_child(_label("· 레벨 상한 %d → %d" % [int(g.maxLv[0]), int(g.maxLv[1])], 13))
		_box.add_child(_label("· 매대 %d칸 → %d칸" % [int(g.stalls[0]), int(g.stalls[1])], 13))
		# ★ 나쁜 소식도 같은 크기로 적는다. 승급은 레벨을 1로 되돌리기 때문에
		#   누르고 나면 벌이가 잠깐 떨어진다. 이걸 안 적으면 누른 사람이
		#   "고장 났나" 하고, 그게 이 게임을 끄는 이유가 된다.
		_box.add_child(_label("· 레벨은 1로 되돌아간다 — 벌이가 잠깐 %d%%로 떨어졌다가, %d레벨이면 본전이고 상한까지 올리면 %.0f배다"
			% [int(round(g.dip * 100.0)), int(g.even), g.top], 13, Color("5a4e3d"), true))
	var ok: bool = sim.can_promote(shop_id)
	_box.add_child(_btn("승급하기 🪙" + Num.fmt(r.cost) if ok else "조건을 채워야 한다", ok,
		func():
			if sim.promote(shop_id) and on_card.is_valid():
				on_card.call(shop_id, sim.rank_of(shop_id))
			rebuild()))
