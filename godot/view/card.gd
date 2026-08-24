extends Control
class_name CardPopup
## 점장 카드 한 장이 열리는 순간. 화면을 덮고 한가운데에 뜬다.
##
## ★ 카드를 **따로 저장하지 않는다.** 어떤 카드를 가졌는지는 이미 sim이 안다 —
##   가게가 열렸으면 그 가게 0등급 카드가 있는 것이고, 참쇠로 승급했으면
##   1등급 카드까지 있는 것이다. 담는 칸을 새로 만들면 저장본을 깨뜨리고
##   (다섯 번째 규칙), 게다가 **두 군데가 어긋날 여지**가 생긴다.
##   있는 것에서 계산할 수 있으면 계산한다.
##
## 그림은 나중에 온다. `clerks/<가게>-make-<등급>` → `clerks/<가게>-make`
## → `hero/raccoon-make` 순으로 찾고, 하나도 없으면 현판 글자를 크게 띄운다.

var sim: Sim
var _t: float = 0.0
## 뽑기 연출의 단계. "" = 연출 없음(바로 보여줌) · back → flip → done.
## 백 번 뽑는 게임이라 **어디서든 누르면 즉시 끝으로 간다** — 연출은
## 첫 열 번의 설렘이지 백 번째의 기다림이 아니다.
var _phase: String = ""
var _pt: float = 0.0
var _front: Dictionary = {}          ## 뒤집힌 뒤에 보여줄 앞면
var _bg: StyleBoxFlat                ## 테두리 색을 등급 색으로 물들이려고 잡아 둔다
var _flash: ColorRect                ## 진귀 이상에서 한 번 번쩍이는 막
var _cardbox: PanelContainer
var _art: TextureRect
var _title: Label
var _sub: Label
var _sign: Label
var _head_label: Label

func _ready() -> void:
	visible = false
	# ★ set_anchors_preset이 아니라 **and_offsets** 쪽을 쓴다.
	#   앞엣것은 앵커만 바꾸고 크기는 그대로 두어서, 화면을 안 채운다.
	#   처음에 그걸 몰라 카드가 화면 왼쪽 위 구석에 붙어 나왔다.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 뒤를 어둡게 덮는다. 안 덮으면 카드가 '떠 있는 딱지'로 보이고,
	# 무엇보다 뒤를 눌러 버려서 카드를 못 본 채로 지나간다.
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.06, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_cardbox = PanelContainer.new()
	_cardbox.custom_minimum_size = Vector2(252, 0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f6efdc")
	bg.border_color = Color("a8763e")
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(18)
	bg.content_margin_left = 16; bg.content_margin_right = 16
	bg.content_margin_top = 14; bg.content_margin_bottom = 14
	bg.shadow_color = Color(0, 0, 0, 0.3)
	bg.shadow_size = 14
	_bg = bg
	_cardbox.add_theme_stylebox_override("panel", bg)
	center.add_child(_cardbox)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_cardbox.add_child(box)
	_head_label = Label.new()
	var top: Label = _head_label
	top.text = "새 점장 카드!"
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 15)
	top.add_theme_color_override("font_color", Color("c7563f"))
	box.add_child(top)
	_sign = Label.new()
	_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sign.add_theme_font_size_override("font_size", 72)
	box.add_child(_sign)
	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(0, 160)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_art)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color("2b241b"))   # 기본 흰 글자는 이 바탕에서 안 읽힌다
	box.add_child(_title)
	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 12)
	_sub.add_theme_color_override("font_color", Color("8a7a63"))
	box.add_child(_sub)
	var ok := Button.new()
	ok.text = "받는다"
	ok.pressed.connect(close)
	box.add_child(ok)
	# 번쩍이는 막 — 제일 위에. 진귀 이상이 나올 때 한 번 하얗게 스친다.
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.98, 0.9, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	# 연출 중에 아무 데나 누르면 끝으로 건너뛴다
	gui_input.connect(_on_input)

func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and _phase != "":
		_finish_flip()

func show_card(shop_id: String, rank: int) -> void:
	_t = 0.0
	var shop: Dictionary = Sim.shop_by_id(shop_id)
	var t: Texture2D = Art.ranked("clerks", "%s-make" % shop_id, rank)
	if t == null:
		t = Art.tex("hero", "raccoon-make")
	_art.texture = t
	_art.visible = t != null
	_sign.visible = t == null            # 그림이 없으면 현판 글자로 대신한다
	_sign.text = String(shop.sign)
	_head_label.text = "새 점장 카드!"
	_title.text = "%s %s" % [shop.ranks[rank], shop.name]
	_title.add_theme_color_override("font_color", Color("2b241b"))
	_sub.text = "%s · %d번째 등급" % [shop.desc, rank + 1]
	visible = true

## 뽑은 카드. 여러 장이면 **제일 좋은 것 한 장**을 크게 띄우고 나머지는 줄로 적는다.
## 열 장을 한 장씩 넘겨 보여주면 그게 더 지루하다.
##
## 순서(MOTION.md): 뒷면 → 테두리가 등급 색으로 물든다 → 뒤집힌다 → 앞면.
## **등급이 뒤집히기 전에 새어 나오는 것**이 이 연출의 전부다 — "뭐가 나올까"가
## 그 0.45초 동안 있어야 뽑는 맛이 난다.
func show_pull(got: Array) -> void:
	if got.is_empty():
		return
	_t = 0.0
	var best: Dictionary = got[0]
	for r in got:
		if int(r.grade) > int(best.grade):
			best = r
	var g: Dictionary = Sim.guest_by_id(String(best.id))
	var gr: Dictionary = Content.CARD_GRADES[int(best.grade) - 1]
	# ★ 내역은 **짐승별로** 적는다. 처음엔 등급 합계만 적었는데(⚪흔함 10),
	#   그러면 "한 짐승이 10장 나왔다"로 읽힌다 — 실제로는 장마다 따로 굴려서
	#   다람쥐 2 · 토끼 3 · 까치 1처럼 섞여 나오는데, 화면이 그걸 숨기고 있었다.
	#   유저가 정확히 그렇게 오해했다. 섞여 나온다는 사실이 보여야 한다.
	var byid: Dictionary = {}
	var grade_of: Dictionary = {}
	for r in got:
		byid[r.id] = int(byid.get(r.id, 0)) + 1
		grade_of[r.id] = int(r.grade)
	var rows: Array = []
	for gid in byid:
		rows.append({"id": gid, "n": int(byid[gid]), "grade": int(grade_of[gid])})
	# 귀한 것부터, 같으면 많이 나온 것부터
	rows.sort_custom(func(a, b): return a.n > b.n if a.grade == b.grade else a.grade > b.grade)
	var parts: Array[String] = []
	for row in rows:
		var gg: Dictionary = Sim.guest_by_id(String(row.id))
		var dot: String = String(Content.CARD_GRADES[int(row.grade) - 1].face)
		parts.append("%s%s%s %d" % [dot, gg.face, gg.name, int(row.n)])
	# 앞면은 아직 안 보여준다 — 뒤집힌 뒤에 입힐 것만 챙겨 둔다
	_front = {
		"tex": _pull_art(String(best.id)),
		"face": String(g.face),
		"title": "%s %s" % [g.name, "— 처음 만났다!" if best.get("isNew", false) else ""],
		"color": Color(gr.color),
		"sub": "%d장 뽑음\n%s" % [got.size(), _wrap(parts, 3)],
		"head": "새 손님!" if best.get("isNew", false) else "카드를 뽑았다",
		"grade": int(best.grade),
	}
	# 뒷면부터
	_art.visible = false
	_sign.visible = true
	_sign.text = "🎴"
	_title.text = "…"
	_title.add_theme_color_override("font_color", Color("8a7a63"))
	_sub.text = " \n "
	_head_label.text = "뽑는 중"
	_bg.border_color = Color("a8763e")
	_phase = "back"
	_pt = 0.0
	visible = true

## 긴 내역을 몇 개씩 줄로 접는다 — 서른 장이면 열 줄이 넘어 카드가 화면을 뚫는다
func _wrap(parts: Array[String], per: int) -> String:
	var lines: Array[String] = []
	for i in range(0, parts.size(), per):
		lines.append(" · ".join(parts.slice(i, i + per)))
	return "\n".join(lines)

## 카드에 띄울 그림 — 초상(cards/<id>-1)이 있으면 그것, 없으면 걷는 그림,
## 둘 다 없으면 이모지. 그림 주문서의 '카드 1단'이 들어오면 여기가 살아난다.
func _pull_art(gid: String) -> Texture2D:
	var t: Texture2D = Art.tex("cards", gid + "-1")
	if t != null:
		return t
	return Art.tex("guests", gid)

## 연출을 끝까지 감는다 — 눌러서 건너뛰든, 시간이 다 됐든 여기로 온다.
func _finish_flip() -> void:
	if _front.is_empty():
		_phase = ""
		return
	_art.texture = _front.tex
	_art.visible = _art.texture != null
	_sign.visible = _art.texture == null
	_sign.text = String(_front.face)
	_title.text = String(_front.title)
	_title.add_theme_color_override("font_color", _front.color)
	_sub.text = String(_front.sub)
	_head_label.text = String(_front.head)
	_bg.border_color = _front.color
	_cardbox.scale = Vector2.ONE
	# 진귀 이상은 한 번 번쩍인다. 흔함은 조용히 — 전부 요란하면 아무것도 요란하지 않다.
	_flash.color.a = 0.75 if int(_front.grade) >= 4 else 0.0
	_phase = ""
	_front = {}

## 룰렛 결과.
func show_spin(got: Dictionary) -> void:
	_t = 0.0
	var w: Dictionary = Content.ROULETTE.wedges[int(got.wedge)]
	_art.visible = false
	_sign.visible = true
	_sign.text = "🎡"
	_head_label.text = "룰렛"
	_title.text = String(w.label)
	_title.add_theme_color_override("font_color", Color("2b241b"))
	match String(got.kind):
		"coin": _sub.text = "🪙 %s" % Num.fmt(float(got.amount))
		"gem": _sub.text = "💎 %d" % int(got.amount)
		_:
			var names: Array[String] = []
			for c in got.cards:
				names.append(String(Sim.guest_by_id(String(c.id)).name))
			_sub.text = "손님 카드 %d장 — %s" % [int(got.amount), ", ".join(names)]
	visible = true

## 구역이 열렸다 — 동네째 하나가 드러나는 순간이라 카드로 축하한다.
func show_zone(dz: Dictionary) -> void:
	_t = 0.0
	_art.visible = false
	_sign.visible = true
	_sign.text = "🏘️"
	_head_label.text = "새 구역!"
	_title.text = String(dz.name)
	_title.add_theme_color_override("font_color", Color("2b241b"))
	_sub.text = "%s\n무너진 집 %d채가 드러났다 — 하나씩 되살리자" % [String(dz.desc), (dz.shops as Array).size()]
	visible = true

func close() -> void:
	visible = false
	_phase = ""
	_front = {}
	_bg.border_color = Color("a8763e")
	_cardbox.scale = Vector2.ONE

## 뜰 때 살짝 커지며 나타난다. 툭 나타나면 "언제 떴지" 하고 지나친다.
func _process(delta: float) -> void:
	if not visible or _cardbox == null:
		return
	_cardbox.pivot_offset = _cardbox.size * 0.5
	if _flash.color.a > 0.0:
		_flash.color.a = max(0.0, _flash.color.a - delta * 2.6)
	match _phase:
		"back":
			# 테두리가 등급 색으로 차오른다 — 등급이 먼저 새어 나온다
			_pt += delta
			var gr: Dictionary = Content.CARD_GRADES[int(_front.grade) - 1]
			var p: float = clampf(_pt / 0.45, 0.0, 1.0)
			_bg.border_color = Color("a8763e").lerp(Color(gr.color), p)
			_cardbox.scale = Vector2.ONE * (0.86 + 0.14 * p)
			if _pt >= 0.45:
				_phase = "flip"
				_pt = 0.0
		"flip":
			# 옆으로 납작해졌다가 다시 펴진다 — 반 넘어가는 순간 앞면으로 갈아입는다
			_pt += delta
			var q: float = clampf(_pt / 0.25, 0.0, 1.0)
			_cardbox.scale = Vector2(absf(cos(q * PI)), 1.0)
			if q >= 0.5 and _sign.text == "🎴":
				_finish_flip_face()
			if q >= 1.0:
				_finish_flip()
		_:
			_t = min(_t + delta * 4.0, 1.0)
			var e: float = 1.0 - pow(1.0 - _t, 3.0)
			_cardbox.scale = Vector2.ONE * (0.86 + 0.14 * e)

## 뒤집히는 중간에 앞면만 갈아입는다(연출은 계속 돈다)
func _finish_flip_face() -> void:
	if _front.is_empty():
		return
	_art.texture = _front.tex
	_art.visible = _art.texture != null
	_sign.visible = _art.texture == null
	_sign.text = String(_front.face)
	_title.text = String(_front.title)
	_title.add_theme_color_override("font_color", _front.color)
	_sub.text = String(_front.sub)
	_head_label.text = String(_front.head)
