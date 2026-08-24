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
var card: CardPopup
var sfx: Sfx
var _layer: CanvasLayer
var _guestbtn: Button
var _questbtn: Button
var _fairbtn: Button
## 더미 광고가 도는 동안 잠깐 막아 둔다
var _adWait: float = 0.0
var _newsbtn: Button

## 끌기와 누르기를 가른다. 이걸 안 하면 마을을 둘러보려고 끌 때마다
## 손가락을 뗀 자리가 눌려서 엉뚱한 게 강화된다.
var _press_at: Vector2 = Vector2.ZERO
var _dragged: bool = false

## ── 줌 ──
## 왜 칸을 정해 두나. 마음대로 줄이면 마을이 개미만 해지고, 마음대로 키우면
## 손님이 화면을 다 덮는다. 둘 다 놀 수 없는 화면이다.
##   1.00 — 처음 보는 크기. 가게 하나(3×3 마당 288px)가 폭 430 안에 꽉 찬다
##   0.45 — 마을 전체를 훑는다
##   1.80 — 매대 하나를 정확히 누를 만큼
const ZOOM_DEF := 1.0
const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.8
## 두 손가락 사이 거리 — 지난 프레임과 견줘서 벌어졌는지 좁혀졌는지를 본다
var _touches: Dictionary = {}
var _pinch_d: float = 0.0

## ── 저장 ──
## 방치형에서 저장은 잔재미가 아니라 뼈대다. 껐다 켜면 처음부터인 게임은
## "잠깐 두고 나중에 본다"가 아예 성립하지 않는다.
const SAVE_PATH := "user://save.dat"
var _save_acc: float = 0.0
## 내가 이 판의 주인공인가. 시험 장면(shot·taptest) 안에 얹혀 있을 때는 거짓이다.
##
## ★ 이걸 안 가르면 **시험이 남의 저장본을 물려받는다.** 실제로 그랬다 —
##   30분짜리 스크린샷을 몇 번 찍었더니 저장본이 쌓였고, 그다음부터 누르기
##   시험이 "매대를 눌렀는데 안 오른다"로 실패했다. 고장이 아니라 이미
##   만렙이었던 것이다. 시험은 늘 **빈손으로 시작**해야 한다.
var _standalone: bool = false
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
	sim.load_from(box.state, int(box.get("ver", 1)))
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
		if sim != null and _standalone:
			_save()

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("6f8159"))
	sim = Sim.new()
	rng = Rng.new(int(Time.get_unix_time_from_system()))
	_standalone = get_parent() == get_tree().root
	_away = _load() if _standalone else null
	# 켠 횟수 — 며칠 만에 다시 오나를 여기서 센다
	sim.bump("run.start")

	village = Village.new()
	village.setup(sim)
	add_child(village)

	cam = Camera2D.new()
	cam.zoom = Vector2(ZOOM_DEF, ZOOM_DEF)
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
	_fairbtn = Button.new()
	_fairbtn.pressed.connect(func(): panel.open_kind("gacha"))
	bar.add_child(_fairbtn)
	_newsbtn = Button.new()
	_newsbtn.text = "소식"
	_newsbtn.pressed.connect(func(): panel.open_kind("ledger"))
	bar.add_child(_newsbtn)

	sfx = Sfx.new()
	add_child(sfx)

	panel = ShopPanel.new()
	panel.sim = sim
	panel.on_focus = _focus_shop
	panel.on_card = _show_card
	panel.on_pull = _show_pull
	panel.on_spin = _spin
	panel.on_landed = func():
		if _spinResult != null:
			_reveal_spin(_spinResult)
			_spinResult = null
	_layer.add_child(panel)
	card = CardPopup.new()
	card.sim = sim
	_layer.add_child(card)

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
## 켜 두었던 시간을 초로 쌓는다. 한 번에 얼마나 하나가 여기서 나온다.
var _secAcc: float = 0.0

func step(delta: float) -> void:
	_secAcc += delta
	if _secAcc >= 1.0:
		sim.bump("run.seconds", floor(_secAcc))
		_secAcc -= floor(_secAcc)
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
	if _adWait > 0.0:
		_adWait -= delta
		if _adWait <= 0.0:
			_adWait = 0.0
			_finish_spin(true)
	step(delta)
	village.cam_center = cam.position
	_save_acc += delta
	if _standalone and _save_acc > 5.0:
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
	sim.roul_refill()
	# 남은 횟수를 단추에 적는다 — 안 적으면 매일 열어 보고 확인해야 한다
	var left: int = int(sim.roulFree) + int(sim.roulAd)
	_fairbtn.text = "뽑기" if left == 0 else "뽑기 ●%d" % left
	var lines: Array[String] = []
	for i in range(min(3, sim.events.size())):
		lines.append("· " + String(sim.events[i].msg))
	_log.text = "\n".join(lines)

## 화면을 끌어서 마을을 둘러보고, 눌러서 논다.
## 마을 밖으로는 못 나간다 — 끝없는 초록 벌판이 나오면 길을 잃는다.
func _unhandled_input(e: InputEvent) -> void:
	# 두 손가락 — 폰에서 크게·작게. 손가락 하나는 밀기라 여기서 안 본다.
	if e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		_pinch_d = 0.0
		if _touches.size() >= 2:
			_dragged = true           # 두 손가락을 뗐을 때 그 자리가 눌리면 안 된다
		return
	if e is InputEventScreenDrag:
		var sd := e as InputEventScreenDrag
		_touches[sd.index] = sd.position
		if _touches.size() >= 2:
			var pts: Array = _touches.values()
			var d: float = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
			var mid: Vector2 = ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5
			if _pinch_d > 0.0 and d > 0.0:
				_zoom_by(d / _pinch_d, mid)
			_pinch_d = d
		return
	# 트랙패드 오므리기(맥) · 휠(책상에서 시험할 때)
	if e is InputEventMagnifyGesture:
		_zoom_by((e as InputEventMagnifyGesture).factor, (e as InputEventMagnifyGesture).position)
		return
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		var wb := e as InputEventMouseButton
		if wb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(1.1, wb.position)
			return
		if wb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / 1.1, wb.position)
			return
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := e as InputEventMouseButton
		if mb.pressed:
			_press_at = mb.position
			_dragged = false
		elif not _dragged:
			_tap(_to_world(mb.position))
	elif e is InputEventMouseMotion and (e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		var mm := e as InputEventMouseMotion
		if _touches.size() >= 2:
			return                             # 두 손가락은 크기 조절이지 밀기가 아니다
		if mm.position.distance_to(_press_at) > 8.0:
			_dragged = true                    # 8px 넘게 움직였으면 끈 것이다
		cam.position -= mm.relative / cam.zoom.x
		_clamp_cam()

## 뽑은 카드를 보여준다. 여러 장이면 제일 좋은 것 한 장을 크게 띄운다 —
## 열 장을 한 장씩 보여주면 그게 더 지루하다.
func _show_pull(got: Array) -> void:
	sfx.play("quest")
	card.show_pull(got)

## 룰렛을 돌린다. 광고면 **잠깐 기다린다** — 더미지만 기다리는 시간까지가
## 그 기능이다. 없으면 나중에 진짜 광고를 붙일 때 감이 안 맞는다.
func _spin(by_ad: bool) -> void:
	if _adWait > 0.0:
		return
	if by_ad:
		_adWait = float(Content.ROULETTE.adSeconds)
		return
	_finish_spin(false)

func _finish_spin(by_ad: bool) -> void:
	var got: Variant = sim.spin(by_ad, rng)
	if got == null:
		return
	# ★ 상은 여기서 이미 정해졌다. 바퀴는 **그 칸에 맞춰** 돌 뿐이다.
	#   순서를 뒤집으면 화면의 오차가 확률이 되어 고지한 표가 거짓말이 된다.
	if panel.wheel != null and panel.wheel.is_inside_tree():
		_spinResult = got
		panel.wheel.spin_to(int(got.wedge))
		return
	_reveal_spin(got)

var _spinResult: Variant = null

## 바퀴가 멈춘 뒤에 결과 창을 띄운다. 먼저 띄우면 바퀴를 볼 이유가 없어진다.
func _reveal_spin(got: Dictionary) -> void:
	sfx.play("quest")
	card.show_spin(got)
	panel.rebuild()

## 카드 한 장이 열린다 — 가게를 되살렸거나, 승급했거나.
func _show_card(shop_id: String, rank: int) -> void:
	card.show_card(shop_id, rank)
	sfx.play("open")

## 가게 창을 열면 지도도 그 가게로 간다.
##
## ★ 화면 한가운데가 아니라 **창 위에 남는 자리**의 한가운데에 놓는다.
##   창이 아래 540px을 덮으니, 가운데에 맞추면 방금 연 그 가게가 창 뒤로 숨는다.
##   창을 열어 놓고 지도를 손으로 끌어 찾는 것은 순전한 수고다.
const ZOOM_SHOP := 1.25
func _focus_shop(id: String) -> void:
	var i: int = -1
	for k in range(Content.SHOPS.size()):
		if Content.SHOPS[k].id == id:
			i = k
	if i < 0:
		return
	var o: Vector2i = Iso.org(sim, i)
	var n: int = Iso.plot_dim(sim, i)
	var c: Vector2 = Iso.w(o.x + n * 0.5, o.y + n * 0.5)
	var z: float = clampf(ZOOM_SHOP, ZOOM_MIN, ZOOM_MAX)
	cam.zoom = Vector2(z, z)
	var vh: float = get_viewport_rect().size.y
	var band: float = maxf(140.0, vh - absf(panel.offset_top))
	cam.position = c + Vector2(0, (vh * 0.5 - band * 0.5) / z)
	_clamp_cam()

## 누른 자리를 붙잡고 크게·작게. 화면 한가운데를 기준으로 하면 보고 있던
## 가게가 손 밑에서 도망간다 — 손가락 밑의 땅은 그대로 있어야 한다.
func _zoom_by(f: float, at: Vector2) -> void:
	var before: Vector2 = _to_world(at)
	var z: float = clampf(cam.zoom.x * f, ZOOM_MIN, ZOOM_MAX)
	cam.zoom = Vector2(z, z)
	cam.position += before - _to_world(at)
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

	# 2) 촌장 — 마을을 돌아다닌다. 누르면 의뢰 창.
	#    가게보다 먼저 본다. 가게 마당 위를 지나갈 때 그 밑에 깔리면 못 누른다.
	if not village.mayor.is_empty():
		var mp: Vector2 = village.mayor.pos
		if absf(p.x - mp.x) < 34.0 and p.y > mp.y - 92.0 and p.y < mp.y + 14.0:
			panel.open_kind("quests")
			return

	# 3) 삽살개 자리
	var dp: Vector2 = Iso.w(Iso.DOG_T.x + 1, Iso.DOG_T.y + 1)
	if sim.guards < float(sim.guard_max()) and absf(p.x - dp.x) < 60.0 and p.y > dp.y - 92.0 and p.y < dp.y + 26.0:
		if sim.buy_guard():
			sfx.play("open")
		return

	# 4) 작은 건물 — 세우거나, 북적일 때 눌러 장을 연다
	for i in range(Iso.SMALL_T.size()):
		var sp: Vector2 = Iso.w(Iso.SMALL_T[i].x + 1, Iso.SMALL_T[i].y + 1)
		if absf(p.x - sp.x) < 62.0 and p.y > sp.y - 92.0 and p.y < sp.y + 24.0:
			if not sim.smalls.has(i):
				if sim.build_small(i):
					sfx.play("open")
			elif sim.tap_small(i):
				sfx.play("fair")
			return

	# 5) 가게 — 매대는 그 자리에서 강화, 나머지는 창
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
				# ★ 매대 판정은 **제 칸 위**로만. 예전엔 104×92짜리 네모라
				#   칸(96×48) 두 개 몫을 먹었고, 그래서 마당 어디를 눌러도
				#   매대가 먼저 잡혔다 — 가게 창은 현판으로만 열리는 셈이었다.
				#   칸 모양 그대로(마름모) 재고, 매대 몸통 높이만큼만 위로 올린다.
				var dy: float = p.y - (q.y - 14.0)
				if absf(p.x - q.x) / (Iso.TW * 0.5) + absf(dy) / (Iso.TH * 0.5) > 1.0:
					continue
				var d: float = Vector2(p.x - q.x, dy * 2.0).length()
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
				_show_card(String(shop.id), sim.rank_of(String(shop.id)))
			return
	panel.close()

## 마을 밖으로는 못 나간다 — 끝없는 초록 벌판이 나오면 길을 잃는다.
## 다만 **가장자리 두 칸(Iso.EDGE)까지는 넘어갈 수 있다.** 딱 마을 끝에서
## 막으면 구석 가게는 영영 화면 구석에 붙어 있는다. 창이 열려 있으면
## 그 높이만큼 더 내려갈 수 있다 — 안 그러면 창 뒤에 깔린 가게를 못 끌어올린다.
func _clamp_cam() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for t in [Vector2i(-Iso.EDGE, -Iso.EDGE), Vector2i(Iso.GW + Iso.EDGE, -Iso.EDGE),
			Vector2i(-Iso.EDGE, Iso.GH + Iso.EDGE), Vector2i(Iso.GW + Iso.EDGE, Iso.GH + Iso.EDGE)]:
		var p: Vector2 = Iso.w(t.x, t.y)
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var half: Vector2 = get_viewport_rect().size * 0.5 / cam.zoom.x
	# 마을이 화면보다 작으면 가운데에 붙여 둔다
	var c: Vector2 = (lo + hi) * 0.5
	cam.position.x = c.x if hi.x - lo.x < half.x * 2 else clampf(cam.position.x, lo.x + half.x, hi.x - half.x)
	var sheet: float = (absf(panel.offset_top) * 0.5 / cam.zoom.x) if (panel != null and panel.visible) else 0.0
	cam.position.y = c.y + sheet if hi.y - lo.y < half.y * 2 \
		else clampf(cam.position.y, lo.y + half.y - 80, hi.y - half.y + 80 + sheet)
