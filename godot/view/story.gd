extends Control
class_name StoryPopup
## 이야기를 화면에 얹는다 — **첫 만화**와 **게시판에 붙는 쪽지**.
##
## ★ 왜 이걸 이제야 넣나. 톱니는 스물둘인데 **왜 돌리는지가 화면에 한 번도
##   안 나왔다**(2026-08-28에 확인). STORY.md에 시놉시스도 대사도 다 있었는데
##   코드에는 한 글자도 없었다. 유저가 얻는 게 "숫자가 올라간다" 하나뿐이었다.
##
## ★ 규칙 둘 (STORY.md의 '지킬 선'):
##   · 이야기는 **놀이를 막지 않는다** — 어디를 눌러도 즉시 넘어간다
##   · 한 마디는 **한 번만** — 기억은 sim.story가 한다(저장본에 남는다)
##
## 대사와 컷은 여기 없다. content.js의 INTRO·BEATS에 있다 —
## 코드에 흩어 두면 규칙이 바뀔 때 같이 안 바뀐다.

signal finished

var _cut: int = -1                    ## 지금 보여주는 만화 칸(-1 = 만화 아님)
var _art: TextureRect
var _text: Label
var _hint: Label
var _skip: Button
var _paper: PanelContainer
var _mode: String = ""                ## "intro" · "note"

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.05, 0.04, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	# 쪽지 — 누렇게 바랜 종이 한 장. 게시판에 붙은 것처럼 보이게 한다.
	_paper = PanelContainer.new()
	_paper.custom_minimum_size = Vector2(300, 0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f4ead2")
	bg.border_color = Color("c8b48a")
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(6)
	bg.content_margin_left = 20; bg.content_margin_right = 20
	bg.content_margin_top = 18; bg.content_margin_bottom = 16
	bg.shadow_color = Color(0, 0, 0, 0.35)
	bg.shadow_size = 16
	_paper.add_theme_stylebox_override("panel", bg)
	center.add_child(_paper)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_paper.add_child(box)

	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(0, 180)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_art)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_font_size_override("font_size", 16)
	_text.add_theme_color_override("font_color", Color("2b241b"))
	box.add_child(_text)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color("9c8f74"))
	box.add_child(_hint)

	_skip = Button.new()
	_skip.text = "건너뛰기"
	_skip.pressed.connect(_close)
	box.add_child(_skip)

	gui_input.connect(_on_input)

func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		_next()

## 처음 켤 때의 4장.
func show_intro() -> void:
	_mode = "intro"
	_cut = 0
	_skip.visible = true
	_draw_cut()
	visible = true

## 게시판에 붙는 쪽지 한 장.
func show_note(text: String) -> void:
	_mode = "note"
	_cut = -1
	_art.texture = Art.tex("props", "board")
	_art.visible = _art.texture != null
	_text.text = text
	_hint.text = "— 게시판에 붙은 쪽지 ·  아무 데나 눌러 넘긴다"
	_skip.visible = false
	visible = true

func _draw_cut() -> void:
	var c: Dictionary = Content.INTRO[_cut]
	_art.texture = Art.tex("intro", String(c.art))
	_art.visible = _art.texture != null
	_text.text = String(c.text)
	_hint.text = "%d / %d  ·  눌러서 넘긴다" % [_cut + 1, Content.INTRO.size()]

func _next() -> void:
	if _mode != "intro":
		_close()
		return
	_cut += 1
	if _cut >= Content.INTRO.size():
		_close()
		return
	_draw_cut()

func _close() -> void:
	visible = false
	_mode = ""
	finished.emit()
