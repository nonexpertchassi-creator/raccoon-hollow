extends Node
## 시간을 감아 놓고 화면을 찍는다. 사람이 볼 화면이 진짜 나오는지 보는 용도.
## main.tscn에는 안 넣는다 — 넣으면 게임을 켤 때마다 몇 초 뒤에 꺼진다.
var _done: bool = false

func _ready() -> void:
	var main: Node = $Main
	var s: Sim = main.sim
	var rng: Rng = main.rng
	# 미리 돌려 놓는다. 갓 켠 화면은 볼 것이 없다.
	var mins: int = int(OS.get_environment("SHOT_MINUTES")) if OS.has_environment("SHOT_MINUTES") else 30
	# ★ main._process가 하는 일을 그대로 한다. 예전엔 sim.tick만 돌렸는데
	#   그러면 판매가 화면으로 안 넘어가서 **손님이 한 마리도 안 나왔다.**
	#   빨리 감기는 게임을 그대로 감아야지, 반만 감으면 딴것이 된다.
	for i in range(mins * 60 * 4):
		var r: Dictionary = s.tick(0.25, rng)
		for sale in r.sales:
			main.village.on_sale(sale)
		for d in r.done:
			main.village.on_sale(d)
		RunSim.act(s, rng)
		main.village._advance(0.25)
	main._paint()
	if OS.has_environment("SHOT_PANEL"):
		var k: String = OS.get_environment("SHOT_PANEL")
		if k == "quests" or k == "guests" or k == "ledger":
			main.panel.open_kind(k)
		else:
			main.panel.open_for(k)

func _process(_delta: float) -> void:
	if _done:
		return
	_done = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	get_tree().quit()
