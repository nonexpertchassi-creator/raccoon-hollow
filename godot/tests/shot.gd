extends Node
## 시간을 감아 놓고 화면을 찍는다. 사람이 볼 화면이 진짜 나오는지 보는 용도.
## main.tscn에는 안 넣는다 — 넣으면 게임을 켤 때마다 몇 초 뒤에 꺼진다.
##
##   SHOT_MINUTES=30           얼마나 감을지
##   SHOT_UNTIL=bubble|grumpy  그 장면이 나올 때까지 더 감는다
##   SHOT_PANEL=quests|guests|<가게id>   창을 열어 놓고 찍는다
var _done: bool = false

func _ready() -> void:
	var main: Node = $Main
	var s: Sim = main.sim
	var rng: Rng = main.rng
	# 미리 돌려 놓는다. 갓 켠 화면은 볼 것이 없다.
	var mins: int = int(OS.get_environment("SHOT_MINUTES")) if OS.has_environment("SHOT_MINUTES") else 30
	for i in range(mins * 60 * 4):
		_step(main, s, rng)
	# 드물게 나오는 장면은 그냥 찍으면 거의 안 걸린다 — 물어보는 말풍선은
	# 여덟 시간에 네 번쯤이라, 아무 때나 찍으면 열 번에 아홉 번은 빈 화면이다.
	# "나올 때까지 감아라"가 없으면 도구는 그 기능을 영영 안 보는 셈이 된다.
	if OS.has_environment("SHOT_UNTIL"):
		var want: String = OS.get_environment("SHOT_UNTIL")
		for i in range(60 * 60 * 4):          # 최대 한 시간까지만 더 감는다
			if _scene_has(main, want):
				break
			_step(main, s, rng)
	main._paint()
	if OS.has_environment("SHOT_PANEL"):
		var k: String = OS.get_environment("SHOT_PANEL")
		if k == "quests" or k == "guests" or k == "ledger":
			main.panel.open_kind(k)
		else:
			main.panel.open_for(k)
	# 찍은 화면에 무엇이 들어 있는지 말해 준다 — 그림만 보면 "말풍선이 원래
	# 안 뜨는 건지, 이번에만 없는 건지"를 못 가른다.
	print("SHOT 손님 %d · 빈손💢 %d · 말풍선 %s" % [main.village.walkers.size(),
		_grumpy(main), ("없음" if main.village.bubble.is_empty() else String(main.village.bubble.text))])

## ★ main._process가 하는 일을 그대로 한다. 예전엔 sim.tick만 돌렸는데
##   그러면 판매가 화면으로 안 넘어가서 **손님이 한 마리도 안 나왔다.**
##   빨리 감기는 게임을 그대로 감아야지, 반만 감으면 딴것이 된다.
func _step(main: Node, s: Sim, rng: Rng) -> void:
	var r: Dictionary = s.tick(0.25, rng)
	for sale in r.sales:
		main.village.on_sale(sale)
	for d in r.done:
		main.village.on_sale(d)
	if r.ask != null:
		main.village.on_ask(r.ask)
	RunSim.act(s, rng)
	main.village._advance(0.25)

func _grumpy(main: Node) -> int:
	var n: int = 0
	for wk in main.village.walkers:
		if wk.empty and wk.state == "buy" and wk.wait > 0.0:
			n += 1
	return n

func _scene_has(main: Node, want: String) -> bool:
	if want == "bubble":
		return not main.village.bubble.is_empty()
	if want == "grumpy":
		return _grumpy(main) > 0
	return true

func _process(_delta: float) -> void:
	if _done:
		return
	_done = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	get_tree().quit()
