extends Node2D
## 마을 화면. 규칙(sim)은 읽기만 하고 절대 고치지 않는다.
##
## 아직 손으로 누를 수 있는 것이 없다 — 지금은 가상 플레이어가 대신 누른다.
## 누르는 조작은 다음 차례다.

var sim: Sim
var rng: Rng
var village: Village
var cam: Camera2D
var _hud: Label
var _sub: Label
var _log: Label
var _acc: float = 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("6f8159"))
	sim = Sim.new()
	rng = Rng.new(int(Time.get_unix_time_from_system()))

	village = Village.new()
	village.setup(sim)
	add_child(village)

	cam = Camera2D.new()
	cam.zoom = Vector2(0.62, 0.62)
	# 대장간 앞에서 시작한다 — 처음 켜면 여기 하나만 서 있다.
	# 화면의 가로 위치는 tx가 아니라 (tx − ty)라, 칸 좌표를 그대로 쓰면 엉뚱한 데를 본다.
	cam.position = Iso.w(Iso.SHOP_T[0].x - 1.5, Iso.SHOP_T[0].y - 1.5) + Vector2(0, -60)
	add_child(cam)
	cam.make_current()
	_clamp_cam()

	var layer := CanvasLayer.new()
	add_child(layer)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 16; box.offset_top = 12; box.offset_right = -16
	layer.add_child(box)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 27)
	box.add_child(_hud)
	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 13)
	box.add_child(_sub)
	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_log)
	_paint()

func _process(delta: float) -> void:
	var r: Dictionary = sim.tick(delta, rng)
	for s in r.sales:
		village.on_sale(s)
	for d in r.done:
		village.on_sale(d)
	RunSim.act(sim, rng)          # 눌러줄 손이 아직 없어서 가상 플레이어가 대신 누른다
	_acc += delta
	if _acc < 0.12:
		return
	_acc = 0.0
	_paint()

func _paint() -> void:
	# 폰 폭에 맞춘다. 한 줄에 다 넣으면 오른쪽이 잘려서 젬이 안 보인다.
	_hud.text = "🪙 " + Num.fmt(sim.money)
	_sub.text = "초당 🪙%s · 가게 %d/%d · 품목 %d · 손님 %d · 💎%d" % [
		Num.fmt(sim.income_per_sec()), sim.shops.size(), Content.SHOPS.size(),
		sim.items.size(), sim.guests.size(), int(sim.gems)]
	var lines: Array[String] = []
	for i in range(min(3, sim.events.size())):
		lines.append("· " + String(sim.events[i].msg))
	_log.text = "\n".join(lines)

## 화면을 끌어서 마을을 둘러본다. 마을 밖으로는 못 나간다 —
## 끝없는 초록 벌판이 나오면 길을 잃는다.
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and (e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		cam.position -= (e as InputEventMouseMotion).relative / cam.zoom.x
		_clamp_cam()

func _clamp_cam() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for t in [Vector2i(0, 0), Vector2i(Iso.GW, 0), Vector2i(0, Iso.GH), Vector2i(Iso.GW, Iso.GH)]:
		var p: Vector2 = Iso.w(t.x, t.y)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var half: Vector2 = get_viewport_rect().size * 0.5 / cam.zoom.x
	# 마을이 화면보다 작으면 가운데에 붙여 둔다
	var c: Vector2 = (lo + hi) * 0.5
	cam.position.x = c.x if hi.x - lo.x < half.x * 2 else clampf(cam.position.x, lo.x + half.x, hi.x - half.x)
	cam.position.y = c.y if hi.y - lo.y < half.y * 2 else clampf(cam.position.y, lo.y + half.y - 80, hi.y - half.y + 80)
