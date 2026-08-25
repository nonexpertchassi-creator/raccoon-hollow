extends Node
## 시간을 감아 놓고 화면을 찍는다. 사람이 볼 화면이 진짜 나오는지 보는 용도.
## main.tscn에는 안 넣는다 — 넣으면 게임을 켤 때마다 몇 초 뒤에 꺼진다.
##
##   SHOT_MINUTES=30           얼마나 감을지
##   SHOT_UNTIL=bubble|grumpy|coin  그 장면이 나올 때까지 더 감는다
##   SHOT_ZOOM=1.0             그 크기로 찍는다(기본은 게임이 정한 값)
##   SHOT_PANEL=quests|guests|ledger|gacha|<가게id>   창을 열어 놓고 찍는다
##   SHOT_TAB=items|work|rank  가게 창의 갈피를 골라서 찍는다
##   SHOT_CARD=<가게id>        점장 카드가 열린 순간을 띄워서 찍는다
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
	# 줌을 바꿔 가며 찍는다 — "이 크기가 놀 만한가"는 재는 게 아니라 보는 것이다
	if OS.has_environment("SHOT_ZOOM"):
		var z: float = float(OS.get_environment("SHOT_ZOOM"))
		main.cam.zoom = Vector2(z, z)
		main._clamp_cam()
	# SHOT_CLOCK=0~1 — 하루 중 시각을 못 박는다(0.75면 한밤). 낮과 밤은
	# 게임 시계를 따라 돌아서, 못 박는 손잡이가 없으면 도구가 밤을 영영 못 본다.
	if OS.has_environment("SHOT_CLOCK"):
		main.village.clock_override = float(OS.get_environment("SHOT_CLOCK"))
	# SHOT_SHOP=<가게id> — 그 가게를 가운데 놓고 찍는다. 계산대 자리 같은
	# 마당 문제는 마을 전경으론 안 보인다 — 도구가 못 비추면 못 잡는다.
	if OS.has_environment("SHOT_SHOP"):
		var fid: String = OS.get_environment("SHOT_SHOP")
		for si in range(Content.SHOPS.size()):
			if String(Content.SHOPS[si].id) == fid:
				main.cam.position = Iso.foot(main.sim, si).stand
				main._clamp_cam()
	# 카드는 **누르는 순간**에만 뜬다 — 도구가 스스로 누를 수는 없으니 띄워 보게 한다.
	if OS.has_environment("SHOT_CARD"):
		var sid: String = OS.get_environment("SHOT_CARD")
		main.card.show_card(sid, main.sim.rank_of(sid))
		main.card._process(1.0)
	main._paint()
	if OS.has_environment("SHOT_PANEL"):
		var k: String = OS.get_environment("SHOT_PANEL")
		# ★ 창 종류를 여기 안 적으면 도구가 그 창을 **가게 이름으로 알아듣는다**.
		#   실제로 뽑기 창을 찍으려다 "gacha라는 가게가 없다"로 죽었다.
		if k in ["quests", "guests", "ledger", "gacha"]:
			main.panel.open_kind(k)
		else:
			main.panel.open_for(k)
		# 갈피는 어느 창이든 고를 수 있어야 한다 — 가게 창에만 걸어 뒀더니
		# 도감의 '점장 카드' 갈피를 도구가 영영 못 봤다.
		if OS.has_environment("SHOT_TAB"):
			main.panel.tab = OS.get_environment("SHOT_TAB")
			main.panel.rebuild()
	# 찍은 화면에 무엇이 들어 있는지 말해 준다 — 그림만 보면 "말풍선이 원래
	# 안 뜨는 건지, 이번에만 없는 건지"를 못 가른다.
	var staff: int = 0
	for sh in main.sim.shops:
		staff += int(main.sim.staff_of(sh))
	print("SHOT 손님 %d · 직원 %d · 빈손💢 %d · 말풍선 %s · 소리 %s" % [main.village.walkers.size(), staff,
		_grumpy(main), ("없음" if main.village.bubble.is_empty() else String(main.village.bubble.text)),
		main.sfx.summary()])

## ★ 게임 한 걸음을 **베껴 적지 않는다** — main.step을 그대로 부른다.
##   예전에 여기서 sim.tick만 돌렸을 때는 판매가 화면으로 안 넘어가
##   손님이 한 마리도 안 나왔고, 소리를 붙였을 때는 게임에서만 울리고
##   여기서는 안 울렸다. 두 번 다 원인이 같다 — 베낀 것은 반드시 뒤처진다.
##   손님 걸음(_advance)만 따로 부른다. 빨리 감기는 _process가 안 돌기 때문이다.
func _step(main: Node, s: Sim, rng: Rng) -> void:
	main.step(0.25)
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
	if want == "coin":
		return not main.village.floats.is_empty()      # 팔린 순간 뜨는 엽전 표
	return true

func _process(_delta: float) -> void:
	if _done:
		return
	_done = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	get_tree().quit()
