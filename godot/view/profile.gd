class_name ProfileModal
extends Control
## 프로필 — 바텀시트가 아니라 **가운데 모달**이다(유저). 이름은 늘 위에
## 보이고, 얼굴과 띠는 갈피로 나눈다. 얼굴은 4칸 격자(1:1), 띠는 2칸 격자.

var sim: Sim
var band_colors: Array = []
var tab: String = "face"
var _box: VBoxContainer
var _name: LineEdit

func setup(s: Sim, colors: Array) -> void:
	sim = s
	band_colors = colors
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 뒤 어둠을 누르면 닫힌다 — 모달의 예의다
	bg.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var pn := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.94, 0.87)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16.0)
	pn.add_theme_stylebox_override("panel", sb)
	pn.custom_minimum_size = Vector2(330, 0)
	center.add_child(pn)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	pn.add_child(_box)

func open() -> void:
	visible = true
	rebuild()

func close() -> void:
	visible = false

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(_label("프로필", 17, Color("3d3427")))
	# 이름 — 갈피와 상관없이 늘 보인다(유저)
	_name = LineEdit.new()
	_name.text = String(sim.profile.name)
	_name.max_length = 10
	_name.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.text_submitted.connect(func(t: String): sim.set_profile(t))
	_name.focus_exited.connect(func(): sim.set_profile(_name.text))
	_box.add_child(_name)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)
	for t in [["face", "얼굴"], ["band", "띠"]]:
		var key: String = String(t[0])
		var b := Button.new()
		b.text = String(t[1])
		b.custom_minimum_size = Vector2(90, 0)
		b.disabled = tab == key
		b.pressed.connect(func(): tab = key; rebuild())
		bar.add_child(b)
	_box.add_child(bar)
	if tab == "face":
		_faces()
	else:
		_bands()

## 얼굴 — 1:1 단추 4칸 격자(유저). 뽑기로 만난 손님만 고를 수 있다.
func _faces() -> void:
	_box.add_child(_label("뽑기로 만난 손님만 고를 수 있다", 11, Color("8a7a63")))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_box.add_child(grid)
	var faces: Array = [""]
	for g in Content.GUESTS:
		if sim.guests.has(String(g.id)):
			faces.append(String(g.id))
	for f in faces:
		var fid: String = String(f)
		var b := Button.new()
		b.custom_minimum_size = Vector2(66, 66)
		b.expand_icon = true
		var pic: Texture2D = Art.tex("portraits", "raccoon" if fid == "" else fid)
		if pic == null and fid != "":
			pic = Art.tex("guests", fid + "-front")
			if pic == null:
				pic = Art.tex("guests", fid)
		if pic != null:
			b.icon = pic
		else:
			b.text = "🦝" if fid == "" else String(Sim.guest_by_id(fid).face)
			b.add_theme_font_size_override("font_size", 28)
		b.disabled = String(sim.profile.face) == fid
		b.pressed.connect(func(): sim.set_profile(null, fid); rebuild())
		grid.add_child(b)

## 띠 — 딴 칭호까지, 2칸 격자(유저). 한 줄씩 늘어놓으면 스무 개가 한 화면을 다 먹는다.
func _bands() -> void:
	_box.add_child(_label("단골 칭호를 딴 데까지 고를 수 있다", 11, Color("8a7a63")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	_box.add_child(grid)
	for bi in range(sim.band_max() + 1):
		var b2: int = bi
		var b := Button.new()
		b.text = String(Content.REGULARS[bi].name)
		b.custom_minimum_size = Vector2(140, 34)
		b.add_theme_color_override("font_color", band_colors[mini(bi / 4, band_colors.size() - 1)])
		b.disabled = sim.band_of() == bi
		b.pressed.connect(func(): sim.set_profile(null, null, b2); rebuild())
		grid.add_child(b)
