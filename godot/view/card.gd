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
var _cardbox: PanelContainer
var _art: TextureRect
var _title: Label
var _sub: Label
var _sign: Label

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
	_cardbox.add_theme_stylebox_override("panel", bg)
	center.add_child(_cardbox)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_cardbox.add_child(box)
	var top := Label.new()
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
	_title.text = "%s %s" % [shop.ranks[rank], shop.name]
	_sub.text = "%s · %d번째 등급" % [shop.desc, rank + 1]
	visible = true

func close() -> void:
	visible = false

## 뜰 때 살짝 커지며 나타난다. 툭 나타나면 "언제 떴지" 하고 지나친다.
func _process(delta: float) -> void:
	if not visible or _cardbox == null:
		return
	_t = min(_t + delta * 4.0, 1.0)
	var e: float = 1.0 - pow(1.0 - _t, 3.0)
	_cardbox.pivot_offset = _cardbox.size * 0.5
	_cardbox.scale = Vector2.ONE * (0.86 + 0.14 * e)
