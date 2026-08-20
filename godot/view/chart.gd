class_name Chart
extends Control
## 막대와 원형 그래프. 게임 안에서 쓰는 것이라 규칙을 하나만 세게 지킨다.
##
## ★ **누군지는 색이 아니라 이모지와 이름이 말한다.**
##
## 보통 그래프는 "파란 건 토끼, 빨간 건 까치"처럼 색이 이름표다. 그러면
## 색을 잘 구분 못 하는 사람은 못 읽는다(남자 스무 명 중 한 명쯤이다).
## 여기서는 조각마다 🐰·🐦를 직접 붙이므로 색은 이름표가 아니다.
## 덕분에 색은 **진하기만** 달리하면 된다 — 그건 누구에게나 구분된다.

enum Kind { BAR, PIE }

var kind: Kind = Kind.BAR
var rows: Array = []          # [[이모지, 이름, 값], …] 큰 것부터
var accent := Color("a8763e")
var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font

func setup(k: Kind, r: Array, h: float) -> void:
	kind = k
	rows = r
	custom_minimum_size = Vector2(0, h)
	queue_redraw()

func _text(pos: Vector2, s: String, size: int, col: Color, center: bool = false) -> void:
	var w: float = _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, pos - Vector2(w * 0.5 if center else 0.0, 0), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _draw() -> void:
	if rows.is_empty():
		_text(Vector2(0, 20), "아직 판 것이 없다", 13, Color("8a7a63"))
		return
	if kind == Kind.BAR:
		_draw_bars()
	else:
		_draw_pie()

## 가로 막대 — 크기를 견주는 데는 이게 제일 정확하다.
## 색은 하나만 쓴다. 막대마다 색을 달리하면 색이 뜻을 갖는 줄 알고 읽게 된다.
func _draw_bars() -> void:
	var top: float = maxf(1.0, rows[0][2])
	var row_h: float = 26.0
	var label_w: float = 108.0
	for i in range(rows.size()):
		var y: float = i * row_h
		var r: Array = rows[i]
		_text(Vector2(0, y + 15), "%s %s" % [r[0], r[1]], 12, Color("2b241b"))
		var track := Rect2(label_w, y + 5, maxf(10.0, size.x - label_w - 46.0), 13)
		draw_rect(track, Color(0.17, 0.14, 0.11, 0.10))
		var w: float = track.size.x * (float(r[2]) / top)
		if w > 1.0:
			draw_rect(Rect2(track.position, Vector2(w, track.size.y)), accent)
		_text(Vector2(size.x - 40, y + 15), str(int(r[2])), 12, Color("5a4e3d"))

## 원형 — '몫'을 한눈에 보는 자리에만 쓴다. 조각은 다섯을 안 넘긴다.
## 여섯 조각이 넘어가면 사람 눈이 각도를 못 견준다.
func _draw_pie() -> void:
	var total: float = 0.0
	for r in rows:
		total += float(r[2])
	if total <= 0.0:
		return
	var c := Vector2(78, 78)
	var rad: float = 66.0
	var a0: float = -PI / 2
	for i in range(rows.size()):
		var frac: float = float(rows[i][2]) / total
		var a1: float = a0 + TAU * frac
		# 진하기만 달리한다 — 색을 못 가려도 순서가 보인다
		var col: Color = accent.lightened(float(i) / maxf(1.0, rows.size()) * 0.62)
		var pts := PackedVector2Array([c])
		var steps: int = maxi(3, int((a1 - a0) / 0.09) + 2)
		for k in range(steps + 1):
			pts.append(c + Vector2(cos(lerpf(a0, a1, float(k) / steps)),
				sin(lerpf(a0, a1, float(k) / steps))) * rad)
		draw_colored_polygon(pts, col)
		# 조각 위에 이모지 — 이게 이름표다
		var mid: float = (a0 + a1) * 0.5
		if frac > 0.06:
			_text(c + Vector2(cos(mid), sin(mid)) * rad * 0.62 + Vector2(0, 7),
				String(rows[i][0]), 19, Color.WHITE, true)
		a0 = a1
	# 오른쪽에 이름과 몫
	for i in range(rows.size()):
		var y: float = 16 + i * 22
		var col2: Color = accent.lightened(float(i) / maxf(1.0, rows.size()) * 0.62)
		draw_rect(Rect2(Vector2(162, y - 9), Vector2(12, 12)), col2)
		_text(Vector2(180, y), "%s %s  %d%%" % [rows[i][0], rows[i][1],
			int(round(float(rows[i][2]) / total * 100.0))], 12, Color("2b241b"))
