extends Control
class_name Wheel
## 원형 룰렛. 열두 칸이 나뉜 바퀴가 돌다가 **정해진 칸에 멈춘다.**
##
## ★ 여기가 이 파일에서 제일 중요한 규칙이다.
##   **상은 돌리기 전에 이미 정해져 있다**(`sim.spin`이 정한다).
##   바퀴는 그 칸이 바늘 밑에 오도록 각도를 맞춰 돌 뿐이다.
##   순서를 뒤집으면 — 바퀴가 멈춘 자리를 보고 상을 정하면 —
##   화면의 오차가 확률이 되어 **고지한 표가 거짓말이 된다.**
##
## 그림이 오면 원판(`ui/wheel.png`)과 바늘(`ui/needle.png`)을 이 자리에 끼운다.
## 지금은 도형으로 그린다 — 어디서 멈춰도 게임은 돈다.

signal landed(wedge: int)

const R := 132.0                  ## 바퀴 반지름
const SPINS := 4.0                ## 멈추기 전에 도는 바퀴 수
const DUR := 2.2                  ## 도는 시간(초)
const BOUNCE := 0.16              ## 마지막에 살짝 되튀는 시간

var sim: Sim
var _font: Font
var _t: float = -1.0              ## 0보다 작으면 멈춰 있다
var _from: float = 0.0
var _to: float = 0.0
var _angle: float = 0.0
var _target: int = -1

func _ready() -> void:
	_font = ThemeDB.fallback_font
	custom_minimum_size = Vector2(0, R * 2.0 + 34.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## 이 칸에 멈추도록 돌린다. **칸은 이미 정해져 온 것이다.**
func spin_to(wedge: int) -> void:
	_target = wedge
	var n: int = Content.ROULETTE.wedges.size()
	var step: float = TAU / float(n)
	# 바늘은 위(−90°)를 가리킨다. 그 칸의 가운데가 바늘에 오도록 각을 맞춘다.
	var want: float = -PI * 0.5 - (float(wedge) + 0.5) * step
	_from = _angle
	# 지금 각도에서 want까지, 네 바퀴를 더 돌아서 간다
	_to = want - TAU * SPINS
	while _to > _from:
		_to -= TAU
	_t = 0.0

func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	var total: float = DUR + BOUNCE
	if _t >= total:
		_angle = _to
		_t = -1.0
		queue_redraw()
		landed.emit(_target)
		return
	if _t <= DUR:
		# 끝에서 느려진다(다섯 제곱). 처음부터 느리면 도는 맛이 없고,
		# 끝까지 빠르면 어디 멈췄는지 눈이 못 따라간다.
		var p: float = _t / DUR
		var e: float = 1.0 - pow(1.0 - p, 5.0)
		_angle = _from + (_to - _from) * e
	else:
		# **마지막 되튐.** 딱 멈추면 기계 같고, 조금 되튀면 바퀴 같다.
		var q: float = (_t - DUR) / BOUNCE
		_angle = _to + sin(q * PI) * 0.035
	queue_redraw()

func _draw() -> void:
	var c: Vector2 = Vector2(size.x * 0.5, R + 12.0)
	var n: int = Content.ROULETTE.wedges.size()
	var step: float = TAU / float(n)
	# 바깥 테
	draw_circle(c, R + 7.0, Color("6d5236"))
	draw_circle(c, R + 4.0, Color("a8763e"))
	for i in range(n):
		var w: Dictionary = Content.ROULETTE.wedges[i]
		var a0: float = _angle + float(i) * step
		# 칸 색은 **상의 종류**로 정한다. 무게(확률)로 정하면 큰 상이
		# 어디 있는지 안 보이고, 그러면 돌 때 볼 것이 없다.
		var col: Color = Color("d9cba9")
		match String(w.kind):
			"gem": col = Color("6f93a8")
			"card": col = Color("8a6a9e")
			_: col = Color("cbab6e") if float(w.amount) >= 180.0 else Color("e0d3b0")
		_wedge(c, a0, a0 + step, R, col)
		# 칸 이름 — 짧게 줄여 안쪽에 눕힌다
		var mid: float = a0 + step * 0.5
		var at: Vector2 = c + Vector2(cos(mid), sin(mid)) * (R * 0.62)
		_text(at, _short(w), 12, Color("2b241b"))
	draw_arc(c, R, 0, TAU, 64, Color("6d5236"), 3.0)
	draw_circle(c, 20.0, Color("f3e9d2"))
	draw_arc(c, 20.0, 0, TAU, 32, Color("a8763e"), 3.0)
	# 바늘 — 위에서 아래를 가리킨다. 늘 제자리에 있고 바퀴만 돈다.
	var tip: Vector2 = c + Vector2(0, -R - 2.0)
	draw_colored_polygon(PackedVector2Array([
		tip, tip + Vector2(-11, -17), tip + Vector2(11, -17)]), Color("c7563f"))

## 칸 하나를 부채꼴로. Godot에 부채꼴을 그리는 것이 없어 삼각형을 이어 붙인다.
func _wedge(c: Vector2, a0: float, a1: float, r: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([c])
	var steps: int = 10
	for k in range(steps + 1):
		var a: float = a0 + (a1 - a0) * float(k) / float(steps)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)

func _short(w: Dictionary) -> String:
	match String(w.kind):
		"gem": return "💎%d" % int(w.amount)
		"card": return "카드%d" % int(w.amount)
		_:
			var a: float = float(w.amount)
			if a >= 1800.0: return "엽전 궤"
			if a >= 600.0: return "엽전 자루"
			if a >= 180.0: return "엽전 꾸러미"
			return "엽전 줌"

func _text(at: Vector2, s: String, sz: int, col: Color) -> void:
	var wd: float = _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(_font, at - Vector2(wd * 0.5, -4.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
