extends Node2D
## 마을 화면. 규칙(sim)은 읽기만 하고 절대 고치지 않는다.
##
## 지도를 눌러서 논다(_tap). 강화·창 열기·나쁜 놈 잡기가 전부 여기서 갈린다.

var sim: Sim
var rng: Rng
var village: Village
var cam: Camera2D
var _hud: Label
var _sub: Label
var _log: Label
var _acc: float = 0.0
var panel: ShopPanel
var sfx: Sfx
var _layer: CanvasLayer
var _autobtn: Button
var _guestbtn: Button
var _questbtn: Button
var _newsbtn: Button

## 끌기와 누르기를 가른다. 이걸 안 하면 마을을 둘러보려고 끌 때마다
## 손가락을 뗀 자리가 눌려서 엉뚱한 게 강화된다.
var _press_at: Vector2 = Vector2.ZERO
var _dragged: bool = false

## ── 저장 ──
## 방치형에서 저장은 잔재미가 아니라 뼈대다. 껐다 켜면 처음부터인 게임은
## "잠깐 두고 나중에 본다"가 아예 성립하지 않는다.
const SAVE_PATH := "user://save.dat"
var _save_acc: float = 0.0
var _away: Variant = null       # 다녀온 동안 번 것 (있으면 창을 띄운다)

func _load() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return null
	var blob: PackedByteArray = f.get_buffer(f.get_length())
	var box: Variant = Sim.from_blob(blob)
	if typeof(box) != TYPE_DICTIONARY or not box.has("state"):
		return null
	# 새 판에서 만든 저장본을 옛 게임이 읽으면 모르는 칸을 만난다.
	# 억지로 읽어 망가뜨리느니 **안 읽고 그대로 두는** 쪽이 낫다 —
	# 그 사람이 게임을 최신으로 올리면 저장본이 그대로 살아난다.
	if int(box.get("ver", 0)) > Sim.SAVE_VER:
		push_warning("더 새 판에서 만든 저장본이다 — 건드리지 않는다")
		return null
	sim.load_from(box.state)
	# 껐던 시간만큼 벌어 둔다. 실제 시계로 잰다 — 게임을 켜 둔 시간이 아니라.
	var away: float = Time.get_unix_time_from_system() - float(box.get("at", 0.0))
	if away > 0.0:
		return sim.offline(away)
	return null

func _save() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	# 시각을 함께 담는다. 이게 없으면 얼마나 자리를 비웠는지 알 길이 없다.
	f.store_buffer(var_to_bytes({
		"ver": Sim.SAVE_VER,
		"state": sim.save(),
		"at": Time.get_unix_time_from_system(),
	}))

func _notification(what: int) -> void:
	# 창을 닫거나 화면을 벗어날 때 마지막으로 한 번 더 담는다
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if sim != null:
			_save()

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("6f8159"))
	sim = Sim.new()
	rng = Rng.new(int(Time.get_unix_time_from_system()))
	_away = _load()

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

	_layer = CanvasLayer.new()
	add_child(_layer)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 16; box.offset_top = 12; box.offset_right = -16
	_layer.add_child(box)
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 27)
	box.add_child(_hud)
	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 13)
	box.add_child(_sub)
	_log = Label.new()
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_log)
	# 아래 단추 줄 — 지도에서 못 누르는 것들
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 12; bar.offset_right = -12; bar.offset_top = -56; bar.offset_bottom = -12
	_layer.add_child(bar)
	_guestbtn = Button.new()
	_guestbtn.pressed.connect(func(): panel.open_kind("guests"))
	bar.add_child(_guestbtn)
	_questbtn = Button.new()
	_questbtn.pressed.connect(func(): panel.open_kind("quests"))
	bar.add_child(_questbtn)
	_newsbtn = Button.new()
	_newsbtn.text = "소식"
	_newsbtn.pressed.connect(func(): panel.open_kind("ledger"))
	bar.add_child(_newsbtn)
	_autobtn = Button.new()
	_autobtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_autobtn.pressed.connect(func(): sim.buy_auto())
	bar.add_child(_autobtn)

	sfx = Sfx.new()
	add_child(sfx)

	panel = ShopPanel.new()
	panel.sim = sim
	_layer.add_child(panel)

	if _away != null:
		_show_away(_away)
	_paint()

## "다녀오신 동안" — 방치형에서 다시 켤 이유는 이 창 하나에 걸려 있다.
func _show_away(r: Dictionary) -> void:
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -160; box.offset_right = 160
	box.offset_top = -90; box.offset_bottom = 90
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f3e9d2")
	bg.border_color = Color("a8763e")
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(14)
	bg.set_content_margin_all(16)
	box.add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	var h: int = int(r.seconds / 3600.0)
	var m: int = int(fmod(r.seconds, 3600.0) / 60.0)
	for line in [
		["다녀오신 동안", 19, Color("2b241b")],
		["%s%d분 동안 너구리들이 계속 만들었습니다." % ["%d시간 " % h if h > 0 else "", m], 13, Color("5a4e3d")],
		["🪙 " + Num.fmt(r.earned), 30, Color("a8763e")],
	]:
		var l := Label.new()
		l.text = String(line[0])
		l.add_theme_font_size_override("font_size", int(line[1]))
		l.add_theme_color_override("font_color", line[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	if r.capped:
		var c := Label.new()
		c.text = "(최대 %d시간까지만 쌓입니다)" % int(Content.OFFLINE.capHours)
		c.add_theme_font_size_override("font_size", 11)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(c)
	var ok := Button.new()
	ok.text = "받기"
	ok.pressed.connect(func(): box.queue_free())
	v.add_child(ok)
	_layer.add_child(box)

## 게임 한 걸음 — sim을 돌리고, 그 결과를 화면과 소리에 넘긴다.
##
## ★ 이걸 따로 뺀 이유. 빨리 감기 도구(shot·balance)가 이 일을 **베껴 적고**
##   있었는데, 그러면 여기에 뭘 하나 더 붙일 때마다 도구는 그걸 못 본다.
##   실제로 소리를 붙이자마자 30분을 감아도 "소리 없음"이 나왔다 —
##   게임에서는 울리는데 도구에게만 안 울린 것이다. 한 자리에 모아 둔다.
##   (손님 걸음은 여기 없다. village가 제 _process에서 스스로 걷는다.)
func step(delta: float) -> void:
	var r: Dictionary = sim.tick(delta, rng)
	for s in r.sales:
		village.on_sale(s)
	for d in r.done:
		village.on_sale(d)
	if r.ask != null:
		village.on_ask(r.ask)
	# 소리는 **드물게 일어나는 일**에만 준다. 파는 순간은 일부러 뺐다 —
	# 후반에는 초당 수십 번이라 소리가 아니라 소음이 된다.
	if r.newGuest != null:
		sfx.play("guest")
	if not r.quests.is_empty():
		sfx.play("quest")

func _process(delta: float) -> void:
	step(delta)
	village.cam_center = cam.position
	_save_acc += delta
	if _save_acc > 5.0:
		_save_acc = 0.0
		_save()

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
	_guestbtn.text = "손님 %d/%d" % [sim.guests.size(), Content.GUESTS.size()]
	_questbtn.text = "의뢰 %d" % sim.quests.size()
	_autobtn.visible = not sim.auto
	if not sim.auto:
		_autobtn.text = "장부 정리 🪙" + Num.fmt(Content.AUTO_COST)
		_autobtn.disabled = sim.money < Content.AUTO_COST
	var lines: Array[String] = []
	for i in range(min(3, sim.events.size())):
		lines.append("· " + String(sim.events[i].msg))
	_log.text = "\n".join(lines)

## 화면을 끌어서 마을을 둘러보고, 눌러서 논다.
## 마을 밖으로는 못 나간다 — 끝없는 초록 벌판이 나오면 길을 잃는다.
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		if mb.pressed:
			_press_at = mb.position
			_dragged = false
		elif not _dragged:
			_tap(_to_world(mb.position))
	elif e is InputEventMouseMotion and (e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		var mm := e as InputEventMouseMotion
		if mm.position.distance_to(_press_at) > 8.0:
			_dragged = true                    # 8px 넘게 움직였으면 끈 것이다
		cam.position -= mm.relative / cam.zoom.x
		_clamp_cam()

func _to_world(screen: Vector2) -> Vector2:
	return cam.position + (screen - get_viewport_rect().size * 0.5) / cam.zoom.x

## 누른 자리에 무엇이 있나. 급한 것부터 본다.
func _tap(p: Vector2) -> void:
	# 1) 나쁜 놈 — 제일 급하다. 몇 초 안에 사라진다.
	var th: Dictionary = village.pest_at(cam.position)
	if not th.is_empty() and p.distance_to(th.pos + Vector2(0, -6)) < th.r + 8.0:
		if sim.catch_pest(rng) != null:
			sfx.play("catch")
			return

	# 2) 삽살개 자리
	var dp: Vector2 = Iso.w(Iso.DOG_T.x + 1, Iso.DOG_T.y + 1)
	if not sim.guard and absf(p.x - dp.x) < 60.0 and p.y > dp.y - 80.0 and p.y < dp.y + 26.0:
		if sim.buy_guard():
			sfx.play("open")
		return

	# 3) 작은 건물 — 세우거나, 북적일 때 눌러 장을 연다
	for i in range(Iso.SMALL_T.size()):
		var sp: Vector2 = Iso.w(Iso.SMALL_T[i].x + 1, Iso.SMALL_T[i].y + 1)
		if absf(p.x - sp.x) < 62.0 and p.y > sp.y - 92.0 and p.y < sp.y + 24.0:
			if not sim.smalls.has(i):
				if sim.build_small(i):
					sfx.play("open")
			elif sim.tap_small(i):
				sfx.play("fair")
			return

	# 4) 가게 — 매대는 그 자리에서 강화, 나머지는 창
	for i in range(Content.SHOPS.size()):
		var shop: Dictionary = Content.SHOPS[i]
		var o: Vector2i = Iso.org(sim, i)
		var open: bool = sim.shops.has(String(shop.id))
		if open:
			# 이웃 칸은 화면에서 48px밖에 안 떨어진다. '먼저 맞은 것'을 고르면
			# 뒤 매대가 앞 매대의 몫을 삼킨다 — **제일 가까운 매대**를 고른다.
			var best: int = -1
			var best_d: float = INF
			var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], Iso.plot_dim(sim, i))
			var cap: int = min(sim.stall_cap(String(shop.id)), shop.items.size())
			for k in range(cap):
				var sp2: Vector2i = y.stalls[k]
				var q: Vector2 = Iso.w(o.x + sp2.x + 0.5, o.y + sp2.y + 0.5)
				if absf(p.x - q.x) > 52.0 or p.y < q.y - 64.0 or p.y > q.y + 28.0:
					continue
				var d: float = Vector2(p.x - q.x, (p.y - (q.y - 18.0)) * 1.4).length()
				if d < best_d:
					best_d = d
					best = k
			if best >= 0:
				var it: Dictionary = shop.items[best]
				if not sim.is_open(it.id):
					if sim.open_item(it.id):
						sfx.play("open")
				# 매대를 누르면 그 품목을 살 수 있는 만큼 강화한다
				elif sim.level_up_many(it.id, sim.affordable_levels(it.id)) > 0:
					sfx.play("tap")
				return
		# 마당 나머지(현판 포함) — 가게 창을 연다
		var n: int = Iso.plot_dim(sim, i) if open else 3
		var M: Vector2 = Iso.w(o.x + n * 0.5, o.y + n * 0.5)
		var in_plot: bool = absf(p.x - M.x) / (n * 50.0 + 4.0) + absf(p.y - M.y) / (n * 25.0 + 4.0) <= 1.0
		var N: Vector2 = Iso.w(o.x, o.y)
		var on_sign: bool = absf(p.x - N.x) < 90.0 and p.y > N.y - 72.0 and p.y < N.y - 40.0
		if in_plot or on_sign:
			if open:
				panel.open_for(String(shop.id))
			elif sim.open_shop(String(shop.id)):
				sfx.play("open")
			return
	panel.close()

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
