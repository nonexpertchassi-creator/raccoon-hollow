extends Control
## 아주 못생긴 화면. **일부러 그렇다.**
##
## 이건 게임 화면이 아니라 "규칙이 Godot 안에서 실제로 돈다"를 눈으로 보는
## 자리다. 진짜 화면은 그림이 나온 뒤에 만든다 — 지금 예쁘게 만들면
## 그림에 맞춰 또 뜯어고치게 된다.

var sim: Sim
var rng: Rng
var _money: Label
var _sub: Label
var _log: Label
var _items: Label
var _acc: float = 0.0

func _ready() -> void:
	sim = Sim.new()
	# 화면에서는 진짜 무작위. 씨앗 고정은 대조 시험에서만 쓴다.
	rng = Rng.new(int(Time.get_unix_time_from_system()))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	box.offset_left = 20; box.offset_top = 20
	box.offset_right = -20; box.offset_bottom = -20
	add_child(box)

	var title := Label.new()
	title.text = "너구리 만물상 — 규칙만 Godot으로 옮긴 판"
	box.add_child(title)

	_money = Label.new()
	_money.add_theme_font_size_override("font_size", 44)
	box.add_child(_money)

	_sub = Label.new()
	box.add_child(_sub)

	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_log)

	_items = Label.new()
	_items.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_items)

	_paint()

func _process(delta: float) -> void:
	sim.tick(delta, rng)
	# 사람이 할 법한 판단을 그대로 쓴다 — 지금은 눌러줄 화면이 없으니까
	RunSim.act(sim, rng)
	_acc += delta
	if _acc < 0.12:
		return
	_acc = 0.0
	_paint()

func _paint() -> void:
	_money.text = "🪙 " + Num.fmt(sim.money)
	_sub.text = "초당 🪙%s · 가게 %d/%d · 품목 %d · 손님 %d · 💎%d" % [
		Num.fmt(sim.income_per_sec()), sim.shops.size(), Content.SHOPS.size(),
		sim.items.size(), sim.guests.size(), int(sim.gems)]
	if sim.events.is_empty():
		_log.text = ""
	else:
		var lines: Array[String] = []
		for i in range(min(6, sim.events.size())):
			lines.append("· " + String(sim.events[i].msg))
		_log.text = "\n".join(lines)
	var rows: Array[String] = []
	for id in sim.items.keys():
		rows.append("%s %d/%d" % [sim.item_name(id), int(sim.items[id].stock), int(sim.cap_of(id))])
	_items.text = "   ".join(rows)
