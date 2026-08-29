extends Node
## 시간을 감아 놓고 화면을 찍는다. 사람이 볼 화면이 진짜 나오는지 보는 용도.
## main.tscn에는 안 넣는다 — 넣으면 게임을 켤 때마다 몇 초 뒤에 꺼진다.
##
##   SHOT_MINUTES=30           얼마나 감을지
##   SHOT_UNTIL=grumpy|coin|order   그 장면이 나올 때까지 더 감는다
##   SHOT_ZOOM=1.0             그 크기로 찍는다(기본은 게임이 정한 값)
##   SHOT_PANEL=quests|guests|ledger|gacha|<가게id>   창을 열어 놓고 찍는다
##   SHOT_TAB=items|work|rank  가게 창의 갈피를 골라서 찍는다
##   SHOT_CARD=<가게id>        일꾼 카드가 열린 순간을 띄워서 찍는다
##   SHOT_STORY=intro|<마디id>  첫 만화나 게시판 쪽지를 띄워서 찍는다
var _done: bool = false

func _ready() -> void:
	var main: Node = $Main
	var s: Sim = main.sim
	var rng: Rng = main.rng
	# 미리 돌려 놓는다. 갓 켠 화면은 볼 것이 없다.
	var mins: int = int(OS.get_environment("SHOT_MINUTES")) if OS.has_environment("SHOT_MINUTES") else 30
	for i in range(mins * 60 * 4):
		_step(main, s, rng)
	# 드물게 나오는 장면은 그냥 찍으면 거의 안 걸린다 — 빈손으로 돌아가는
	# 손님은 아무 때나 찍으면 열 번에 아홉 번은 빈 화면이다.
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
	# SHOT_WX=rain|cloud|breeze|clear — 날씨를 못 박고 찍는다.
	if OS.has_environment("SHOT_WX"):
		main.village.wx_override = OS.get_environment("SHOT_WX")
		main.sim.weather = OS.get_environment("SHOT_WX")
	# SHOT_OPEN=1 — 가게를 전부 열고 찍는다(2026-08-27). 안 연 가게를 비추면
	# 빈 풀밭만 찍힌다 — 마당 넷을 눈으로 대보려면 열려 있어야 한다.
	if OS.has_environment("SHOT_OPEN"):
		main.sim.money = 1e30
		for sh1 in Content.SHOPS:
			if not main.sim.shops.has(String(sh1.id)):
				main.sim.shops.append(String(sh1.id))
				main.sim._deal_fur(String(sh1.id))
				main.sim.items[String(sh1.items[0].id)] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
				main.sim.bench[String(sh1.id)] = 1.0
	# SHOT_RANK=0~2 — 모든 가게를 그 등급으로 못 박고 찍는다(2026-08-27).
	# 2단·3단 마당은 실제로 승급할 때까지 몇 시간이 걸려서, 도구가 영영
	# 못 보던 화면이었다 — 계산대가 둘·셋 선 마당이 딱 그것이다.
	if OS.has_environment("SHOT_RANK"):
		var rk0: int = int(OS.get_environment("SHOT_RANK"))
		for sh0 in main.sim.shops:
			main.sim.rank[String(sh0)] = rk0
			# 그 등급에서 열리는 작업대 칸은 전부 열어 둔다 — 빈 칸만 보이면
			# 마당이 커진 게 화면에서 안 보인다.
			var cap0: int = main.sim.bench_cap(String(sh0))
			main.sim.bench[String(sh0)] = float(cap0)   # 작업대도 그 등급 상한까지 세운다
			var seen0: int = 0
			for it0 in Sim.shop_by_id(String(sh0)).items:
				seen0 += 1
				if seen0 > cap0:
					break
				if not main.sim.is_open(String(it0.id)):
					main.sim.items[String(it0.id)] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	# SHOT_GRID=1 — 바닥 칸 번호를 켜고 찍는다(마당 배치 확인용).
	if OS.has_environment("SHOT_GRID"):
		main.village.show_grid = OS.get_environment("SHOT_GRID") != "0"
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
	# ★ 이야기 쪽지는 **감는 동안 저절로 뜬다**. 첫 손님·첫 물건 같은 마디가
	#   지나가면 창이 뜨고, 사람이 누를 때까지 안 닫힌다. 그래서 찍은 열다섯
	#   장이 전부 한가운데를 가린 채 나왔다(2026-08-29, 유저: "안 보임").
	#   이야기를 일부러 찍는 판(SHOT_STORY)이 아니면 사람이 눌러 넘긴 셈 친다.
	if not OS.has_environment("SHOT_STORY"):
		# 한 번만 닫으면 소용이 없다 — 닫는 순간 **다음 쪽지가 그 자리를 메운다**.
		# 쪽지는 한 장씩 뜨게 돼 있어서, 감는 동안 밀린 것이 줄을 서 있다.
		# 그래서 마디 수만큼 넘긴 뒤, 찍는 동안 새로 뜨지 못하게 게임을 멈춘다.
		for i in range(Content.BEATS.size() + 2):
			main.story._close()
			main.step(0.0)
		main.story._close()
		main.set_process(false)

	main._paint()
	if OS.has_environment("SHOT_PANEL"):
		var k: String = OS.get_environment("SHOT_PANEL")
		# ★ 창 종류를 여기 안 적으면 도구가 그 창을 **가게 이름으로 알아듣는다**.
		#   실제로 뽑기 창을 찍으려다 "gacha라는 가게가 없다"로 죽었다.
		if k == "profile":
			main.profile_modal.open()
		elif k in ["quests", "guests", "ledger", "gacha"]:
			main.panel.open_kind(k)
		else:
			main.panel.open_for(k)
		# 갈피는 어느 창이든 고를 수 있어야 한다 — 가게 창에만 걸어 뒀더니
		# 도감의 '일꾼 카드' 갈피를 도구가 영영 못 봤다.
		if OS.has_environment("SHOT_TAB"):
			main.panel.tab = OS.get_environment("SHOT_TAB")
			main.panel.rebuild()
	# 이야기 — 도구가 안 보면 도구에게 없는 기능이다. 4장 만화도 쪽지도 찍는다.
	if OS.has_environment("SHOT_STORY"):
		var w: String = OS.get_environment("SHOT_STORY")
		if w == "intro":
			main.story.show_intro()
		else:
			for b in Content.BEATS:
				if String(b.id) == w:
					main.story.show_note(String(b.text))
			if not main.story.visible:
				push_error("모르는 이야기 마디: " + w)

	# 찍은 화면에 무엇이 들어 있는지 말해 준다 — 그림만 보면 "말풍선이 원래
	# 안 뜨는 건지, 이번에만 없는 건지"를 못 가른다.
	var staff: int = 0
	for sh in main.sim.shops:
		staff += int(main.sim.staff_of(sh))
	print("SHOT 손님 %d · 일꾼 %d · 빈손💢 %d · 말풍선 %s · 소리 %s" % [main.village.walkers.size(), staff,
		_grumpy(main), _order_bubble(main), main.sfx.summary()])

## ★ 게임 한 걸음을 **베껴 적지 않는다** — main.step을 그대로 부른다.
##   예전에 여기서 sim.tick만 돌렸을 때는 판매가 화면으로 안 넘어가
##   손님이 한 마리도 안 나왔고, 소리를 붙였을 때는 게임에서만 울리고
##   여기서는 안 울렸다. 두 번 다 원인이 같다 — 베낀 것은 반드시 뒤처진다.
##   손님 걸음(_advance)만 따로 부른다. 빨리 감기는 _process가 안 돌기 때문이다.
func _step(main: Node, s: Sim, rng: Rng) -> void:
	main.step(0.25)
	RunSim.act(s, rng)
	main.village._advance(0.25)

## 주문 풍선을 띄운 손님 하나를 찾아 그 물건 이름을 돌려준다.
## (예전엔 "손님이 물어보는 말풍선"을 봤는데, 물건 잠금이 작업대로 바뀌면서
##  그 말풍선 자체가 없어졌다 — 도구가 없는 것을 찾고 있으면 안 된다.)
func _order_bubble(main: Node) -> String:
	for wk in main.village.walkers:
		if wk.state == "buy" and not (wk.sold as Array).is_empty():
			return String(wk.sold[0].item.name)
	return "없음"

func _grumpy(main: Node) -> int:
	var n: int = 0
	for wk in main.village.walkers:
		if wk.empty and wk.state == "buy" and wk.wait > 0.0:
			n += 1
	return n

func _scene_has(main: Node, want: String) -> bool:
	if want == "grumpy":
		return _grumpy(main) > 0
	if want == "coin":
		return not main.village.floats.is_empty()      # 팔린 순간 뜨는 엽전 표
	if want == "order":
		for wk in main.village.walkers:                 # 줄 서서 주문 풍선을 띄운 손님
			if wk.state == "buy" and not (wk.sold as Array).is_empty():
				return true
		return false
	return true

func _process(_delta: float) -> void:
	if _done:
		return
	_done = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	get_tree().quit()
