extends Node
## 누르기가 실제로 먹는지 확인한다.
##
## 눈으로 보면 "눌리는 것 같다"까지밖에 못 간다. 좌표를 계산해 두드려 보고
## sim이 실제로 변했는지를 본다 — 매대를 눌렀는데 옆 매대가 오르거나,
## 끌었는데 눌린 걸로 처리되는 종류의 고장은 그림으로는 안 보인다.
var _done := false

func _process(_d: float) -> void:
	if _done:
		return
	_done = true
	var main: Node = $Main
	var s: Sim = main.sim
	var rng: Rng = main.rng
	var fails: Array[String] = []

	# 돈을 넉넉히 주고 시작한다 — 여기서 보는 건 경제가 아니라 좌표다
	s.money = 1.0e12
	# ★ 운 번호를 못 박는다. main은 시계로 운 번호를 잡으므로(사람이 놀 때는 그게 맞다)
	#   그냥 두면 이 시험은 **돌릴 때마다 다른 판**이 된다.
	main.rng = Rng.new(7)
	rng = main.rng
	# 대장간을 연다. 이제 게임은 **아무 가게도 없이** 시작하는데(첫 동작이
	# '가게 열기'다), 이 시험이 보려는 것은 튜토리얼이 아니라 좌표다.
	s.open_shop("smith")
	for i in range(60 * 4):
		s.tick(0.25, rng)
	# ★ 나쁜 놈을 치운다. 누르기는 나쁜 놈이 제일 먼저다(몇 초 안에 사라지니까).
	#   그래서 쥐가 마침 매대 앞에 서 있으면 매대 누르기가 그리로 먹힌다.
	#   실제로 이 시험이 그것 때문에 **어떤 날은 통과하고 어떤 날은 실패했다** —
	#   고장이 아니라 시험이 운에 걸려 있었던 것이다. 나쁜 놈은 5번에서 따로 본다.
	s.pest = null

	# 1) 매대를 누르면 **그 가게 창이 열린다** (2026-08-25부터 — 지도는 보는 곳,
	#    창이 만지는 곳이다. 예전엔 그 자리에서 바로 강화했다.)
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[0], Iso.plot_dim(s, 0))
	var o: Vector2i = Iso.org(s, 0)
	for k in range(min(s.stall_cap("smith"), Content.SHOPS[0].items.size())):
		var it: Dictionary = Content.SHOPS[0].items[k]
		if not s.is_open(it.id):
			continue
		var before: float = s.lv(it.id)
		var sp: Vector2i = y.stalls[k]
		main._tap(Iso.w(o.x + sp.x + 0.5, o.y + sp.y + 0.5) + Vector2(0, -18))
		if not main.panel.visible or main.panel.shop_id != "smith":
			fails.append("매대 %d(%s)를 눌렀는데 가게 창이 안 열렸다" % [k, it.name])
		if s.lv(it.id) != before:
			fails.append("매대 %d를 눌렀는데 바로 강화됐다(창만 열려야 한다)" % k)
		main.panel.close()

	# 2) 현판을 누르면 창이 열린다.
	#
	#    ★ 예전 주석: "마당 한가운데는 매대 판정에 먹히니 현판으로만 연다."
	#      그건 매대 판정이 제 칸의 두 배였기 때문이고, 유저가 **그걸 그대로
	#      느꼈다**("계산대를 눌러야만 열리는 것 같다"). 판정을 제 칸으로
	#      좁혔으니 이제 마당 아무 데나 눌러도 열려야 한다 — 아래 2-3이 그 시험이다.
	var N: Vector2 = Iso.w(o.x, o.y)
	main._tap(N + Vector2(0, -56))
	if not main.panel.visible or main.panel.shop_id != "smith":
		fails.append("현판을 눌렀는데 가게 창이 안 열렸다")
	main.panel.close()

	# 2-2) 마당 앞 꼭짓점(계산대 쪽)도 통로다
	var n: int = Iso.plot_dim(s, 0)
	main._tap(Iso.w(o.x + n - 0.5, o.y + n - 0.5))
	if not main.panel.visible:
		fails.append("마당 앞쪽을 눌렀는데 가게 창이 안 열렸다")
	main.panel.close()

	# 2-3) 마당 안쪽 — 매대가 안 놓인 칸을 누르면 창이 열린다.
	#      매대·가마·계산대가 쓰는 칸을 빼고 남은 칸으로 시험한다.
	var yd: Dictionary = Iso.yard(Iso.YARD_KIND[0], n)
	var taken: Array = [yd.kiln, yd.counter]
	for k in range(min(s.stall_cap("smith"), Content.SHOPS[0].items.size())):
		taken.append(yd.stalls[k])
	var free: Variant = null
	for ty in range(n):
		for tx in range(n):
			if not taken.has(Vector2i(tx, ty)):
				free = Vector2i(tx, ty)
	if free != null:
		main._tap(Iso.w(o.x + (free as Vector2i).x + 0.5, o.y + (free as Vector2i).y + 0.5))
		if not main.panel.visible:
			fails.append("마당 빈 칸을 눌렀는데 가게 창이 안 열렸다")
		main.panel.close()

	# 3) 장이 설 참일 때 의뢰 게시판을 누르면 장이 열린다 (촌장이 하던 일)
	s.busy = 0
	main._tap(Iso.w(Iso.BOARD_T.x + 0.5, Iso.BOARD_T.y + 0.5) + Vector2(0, -20))
	if s.fair <= 0.0:
		fails.append("장이 설 참에 게시판을 눌렀는데 장이 안 열렸다")
	if s.busy != -1:
		fails.append("장을 열었는데 북적임 깃발이 안 내려갔다")
	main.panel.close()

	# 3-2) 장이 안 설 때 게시판을 누르면 의뢰 창이 열린다
	main._tap(Iso.w(Iso.BOARD_T.x + 0.5, Iso.BOARD_T.y + 0.5) + Vector2(0, -20))
	if not main.panel.visible:
		fails.append("게시판을 눌렀는데 의뢰 창이 안 열렸다")
	main.panel.close()

	# 3-3) 길에 떨어진 것을 누르면 줍는다 — 청소부가 없어도 손으로는 된다
	s.trash = 1.0
	main.village.trash = []
	main.village._advance(0.016)
	if main.village.trash.is_empty():
		fails.append("sim에 쓰레기가 하나 있는데 화면에 안 놓였다")
	else:
		# 나오는 것은 **엽전이 아니라 나뭇잎**이다 — 매출 곡선을 안 건드리려고 그렇게 했다
		var before: float = s.gems
		main._tap((main.village.trash[0].pos as Vector2) + Vector2(0, -8))
		if s.gems <= before:
			fails.append("길에 떨어진 것을 눌렀는데 나뭇잎이 안 나왔다")
		if s.trash > 0.0:
			fails.append("주웠는데 쓰레기가 안 없어졌다")

	# 4) 삽살개 자리
	main._tap(Iso.w(Iso.DOG_T.x + 1, Iso.DOG_T.y + 1) + Vector2(0, -20))
	if s.guards <= 0.0:
		fails.append("삽살개 자리를 눌렀는데 안 들어왔다")

	# 5) 나쁜 놈 — 억지로 하나 세워 놓고 눌러 본다
	s.pest = {"kind": "rat", "itemId": "pick", "qty": 3.0, "left": 5.0, "life": 5.0, "what": "시험"}
	var th: Dictionary = main.village.pest_at(main.cam.position)
	if th.is_empty():
		fails.append("나쁜 놈이 나와 있는데 자리를 못 찾는다")
	else:
		main._tap(th.pos + Vector2(0, -6))
		if s.pest != null:
			fails.append("나쁜 놈을 눌렀는데 안 잡혔다")

	# 6) 아무것도 없는 풀밭 — 아무 일도 없어야 한다
	var money_before: float = s.money
	main._tap(Iso.w(0.5, 0.5))
	if s.money != money_before:
		fails.append("빈 풀밭을 눌렀는데 돈이 움직였다")

	# 7) 레벨업 단추를 **꾹 누르는 동안 창이 살아 있어야 한다.**
	#
	#    ★ 이 시험이 없어서 같은 고장을 두 번 냈다. 창은 0.3초마다 통째로
	#      다시 그리는데, 누르고 있는 사이에 그러면 단추가 사라진다.
	#      그러면 손을 뗀 자리가 빈 곳이 되어 그 누름이 지도로 흘러가고,
	#      **창이 닫힌다.** 유저가 "레벨업 한 번 눌렀는데 바텀시트가 닫힌다"고
	#      한 그것이다. 눈으로는 "가끔 그러네"까지밖에 못 간다.
	#    돈을 확 줄여 둔다 — 만렙까지 갈 돈이 있으면 단추가 '최대'로 바뀌어서
	#    꾹 누르기 자체가 안 나온다. 시험하려는 그 상태를 만들어 놓고 본다.
	var first: String = ""
	for it in Content.SHOPS[0].items:
		if s.is_open(it.id):
			first = String(it.id)
			break
	if first != "":
		s.items[first].lv = 1.0             # 위에서 만렙까지 올려 놨다 — 도로 내린다
		# 스무 단계쯤 살 돈. **적게 주면 시험이 아무것도 안 본다** —
		# 꾹 누르기가 돈이 떨어져 곧바로 끝나면, 보려던 그 순간이 안 온다.
		# (여섯 단계로 뒀다가 실제로 속았다. 고장 난 판을 넣어도 통과했다.)
		# 만렙까지 갈 돈은 아니어야 한다 — 그러면 단추가 '최대'로 바뀐다.
		s.money = s.level_cost_many(first, 20)
	main.panel.open_for("smith")            # 안에서 이미 다시 그린다 — 또 부르면 안 된다
	var lvbtn: Button = _find_btn(main.panel, "레벨업")
	if lvbtn == null:
		fails.append("가게 창에 레벨업 단추가 없다")
	else:
		lvbtn.emit_signal("button_down")
		main.panel._pressing = true          # 손가락이 아직 닿아 있다
		main.panel._acc = 5.0                # 다시 그릴 때가 한참 지났다
		main.panel._process(0.5)
		# ★ 단추 자신이 아니라 **그 줄**을 본다. rebuild()는 _box의 자식(줄)에게만
		#   queue_free()를 걸고, 그 안에 든 단추는 줄이 지워질 때 같이 사라진다 —
		#   단추한테 물어보면 "나는 멀쩡하다"고 답한다. 그것 때문에 이 시험이
		#   고장 난 판을 넣어도 통과했다. **시험이 못 보는 것은 없는 것이다.**
		var row: Node = lvbtn
		while row.get_parent() != null and row.get_parent() != main.panel._box:
			row = row.get_parent()
		if row.is_queued_for_deletion():
			fails.append("꾹 누르는 동안 그 줄이 지워졌다 — 떼면 창이 닫힌다")
		if not main.panel.visible:
			fails.append("레벨업을 누르는 중에 창이 닫혔다")
		main.panel._pressing = false
	main.panel.close()

	# 8) 뽑기와 룰렛을 **단추로 눌러 본다.**
	#
	#    ★ 규칙 시험(tests/gacha.gd)은 확률이 표대로인지만 본다. 그건
	#      "단추를 눌렀을 때 그 규칙이 불리는가"는 안 본다 — 창을 새로
	#      만들었으니 그 사이가 끊겼을 수 있다. 실제로 창 종류를 안 적어
	#      두었더니 도구가 '뽑기'를 가게 이름으로 알아들은 적이 있다.
	s.gems = 100.0
	main.panel.open_kind("gacha")
	var pull1: Button = _find_btn(main.panel, "1회")
	if pull1 == null:
		fails.append("뽑기 창에 1회 단추가 없다")
	else:
		var before_pulls: float = s.pulls
		pull1.emit_signal("pressed")
		if s.pulls <= before_pulls:
			fails.append("1회 뽑기를 눌렀는데 안 뽑혔다")
		if not main.card.visible:
			fails.append("뽑았는데 카드가 안 떴다")
		# 연출 — 뒷면으로 시작해서, 시간이 흐르면 앞면으로 뒤집혀 끝난다
		if main.card._phase != "back":
			fails.append("뽑았는데 뒷면 연출이 시작 안 됐다")
		for i in range(40):
			main.card._process(0.05)
		if main.card._phase != "":
			fails.append("연출이 2초가 지나도 안 끝났다")
		if main.card._title.text == "…":
			fails.append("카드가 앞면으로 안 뒤집혔다")
		main.card.close()
	# 열 장 뽑기 — 드묾 보장이 걸리는 자리
	var pull10: Button = _find_btn(main.panel, "10회")
	if pull10 != null:
		var g0: float = s.gems
		pull10.emit_signal("pressed")
		if s.gems >= g0:
			fails.append("10회 뽑기를 눌렀는데 나뭇잎이 안 줄었다")
		# 열 장은 **판으로 깔린다** — 뒷면 열 장이 놓이고 차례로 뒤집힌다
		if main.card._mode != "grid":
			fails.append("열 장을 뽑았는데 판이 안 깔렸다")
		if main.card._tiles.size() != 10:
			fails.append("판에 카드가 %d장이다(10장이어야 한다)" % main.card._tiles.size())
		# 건너뛰기 — 연출 중에 아무 데나 누르면 전부 즉시 앞면이다.
		# 백 번째 뽑기에서 이게 안 되면 연출이 손맛이 아니라 형벌이 된다.
		var tapev := InputEventMouseButton.new()
		tapev.button_index = MOUSE_BUTTON_LEFT
		tapev.pressed = true
		main.card._on_input(tapev)
		var undone: int = 0
		for t in main.card._tiles:
			if not t.done:
				undone += 1
		if undone > 0:
			fails.append("건너뛰었는데 %d장이 아직 뒷면이다" % undone)
		main.card.close()

	# 프로필 — 모달이 열리고, 별명·얼굴·띠가 규칙대로만 바뀐다
	main.profile_modal.open()
	if not main.profile_modal.visible:
		fails.append("프로필 모달이 안 열렸다")
	main.profile_modal.close()
	main.sim.set_profile("검은너구리")
	if String(main.sim.profile.name) != "검은너구리":
		fails.append("별명을 바꿨는데 안 바뀌었다")
	main.sim.set_profile("")                 # 빈 이름은 거절해야 한다
	if String(main.sim.profile.name) != "검은너구리":
		fails.append("빈 별명이 받아들여졌다")
	main.sim.set_profile(null, "tiger")      # 안 뽑은 손님 얼굴은 거절
	if String(main.sim.profile.face) == "tiger" and not main.sim.guests.has("tiger"):
		fails.append("안 뽑은 손님 얼굴이 받아들여졌다")
	main.sim.set_profile(null, null, 99)     # 못 딴 띠도 거절
	if int(main.sim.profile.band) == 99:
		fails.append("못 딴 띠가 받아들여졌다")

	# 일꾼 무늬 — 열 때 한 번 배정되고, 저장을 오가도·옛 판을 받아도 지켜진다
	if not s.furs.has("smith"):
		fails.append("가게를 열었는데 일꾼 무늬가 배정 안 됐다")
	var fur0: String = s.fur_of("smith")
	var s2 := Sim.new()
	s2.load_from(Sim.from_blob(s.to_blob()))
	if s2.fur_of("smith") != fur0:
		fails.append("저장을 오가니 일꾼 무늬가 바뀌었다")
	var oldsave: Dictionary = Sim.from_blob(s.to_blob())
	oldsave.erase("furs")                    # 6판 전 저장본 흉내
	var s3 := Sim.new()
	s3.load_from(oldsave, 5)
	if not s3.furs.has("smith"):
		fails.append("옛 저장본(5판)에 무늬가 배정 안 됐다")

	# 채용 — 등급이 자리를 연다(무쇠 1자리), 채용하면 자리별 무늬가 배정된다
	if int(s.staff_max("smith")) != s.rank_of("smith") + 1:
		fails.append("채용 자리가 등급+1이 아니다")
	if s.staff_of("smith") < s.staff_max("smith"):
		s.money += s.staff_cost("smith")
		if not s.hire_staff("smith"):
			fails.append("돈이 있는데 채용이 안 된다")
		elif not s.furs.has("smith:%d" % int(s.staff_of("smith"))):
			fails.append("채용한 너구리에 무늬가 배정 안 됐다")
	if s.staff_of("smith") >= s.staff_max("smith"):
		s.money += 1e12
		if s.hire_staff("smith"):
			fails.append("자리가 다 찼는데 채용이 됐다")

	# 룰렛 — 무료 한 번
	main.panel.tab = "work"
	main.panel.rebuild()
	var spin: Button = _find_btn(main.panel, "무료로")
	if spin == null:
		fails.append("룰렛 창에 무료 돌리기 단추가 없다")
	else:
		s.roul_refill()
		var free0: float = s.roulFree
		spin.emit_signal("pressed")
		if s.roulFree >= free0:
			fails.append("룰렛을 돌렸는데 횟수가 안 줄었다")
		# ★ 결과는 **바퀴가 멈춘 뒤에** 떠야 한다. 먼저 뜨면 바퀴를 볼 이유가 없다.
		if main.card.visible:
			fails.append("바퀴가 아직 도는데 결과가 먼저 떴다")
		if main.panel.wheel == null:
			fails.append("룰렛 창에 바퀴가 없다")
		else:
			for i in range(240):                 # 12초어치 — 도는 시간은 2.36초다
				main.panel.wheel._process(0.05)
			if not main.card.visible:
				fails.append("바퀴가 멈췄는데 결과가 안 떴다")
		main.card.close()
	main.panel.close()

	# 9) 도감에서 **카드로 성을 올린다**
	s.cards["rabbit"] = 999.0
	var lv0: int = s.regular_lv("rabbit")
	main.panel.open_kind("guests")
	if not main.panel.codex_tiles.has("rabbit"):
		fails.append("도감 판에 토끼 칸이 없다")
	else:
		(main.panel.codex_tiles["rabbit"] as Button).emit_signal("pressed")
		if not main.card.visible:
			fails.append("도감 칸을 눌렀는데 큰 카드가 안 떴다")
		elif not main.card._action.visible:
			fails.append("카드가 넉넉한데 성 올리기 단추가 없다")
		else:
			main.card._action.emit_signal("pressed")
			if s.regular_lv("rabbit") != lv0 + 1:
				fails.append("성 올리기를 눌렀는데 안 올랐다")
		main.card.close()
	main.panel.close()

	# 10) 잠긴 구역 — 안 열리고, 조건이 차면 눌러서 열리고, 그다음에야 가게가 열린다
	if s.district_open("gaekju"):
		fails.append("저잣거리가 처음부터 열려 있다")
	s.money = 1.0e15
	if s.open_shop("gaekju"):
		fails.append("잠긴 구역의 가게가 열렸다")
	# 조건이 안 찼을 때 눌러 본다 — 아무 일도 없어야 하고, 왜 안 되는지가 떠야 한다
	s.stars = {"rabbit": 3.0}
	var band: Vector2 = Iso.w(8.5, 20.5)          # 저잣거리 한가운데 빈 풀밭
	var floats0: int = main.village.floats.size()
	main._tap(band)
	if s.zones.has("jeoja"):
		fails.append("조건이 안 찼는데 구역이 열렸다")
	if main.village.floats.size() <= floats0:
		fails.append("안 열리는 이유가 화면에 안 떴다")
	# 조건을 채우고 누르면 열린다
	s.stars = {"rabbit": 15.0}
	var money_b4: float = s.money
	main._tap(band)
	if not s.zones.has("jeoja"):
		fails.append("조건이 찼는데 구역이 안 열렸다")
	# ★ 값을 치렀는지도 본다. 처음엔 이 줄이 없었고, 일부러 돈을 안 받게
	#   고장 낸 판을 넣어도 시험이 통과했다 — 시험이 못 보는 것은 없는 것이다.
	elif s.money != money_b4 - Content.DISTRICTS[1].cost:
		fails.append("구역을 열었는데 값을 안 치렀다")
	if not main.card.visible:
		fails.append("구역이 열렸는데 축하 카드가 안 떴다")
	main.card.close()
	if not s.open_shop("gaekju"):
		fails.append("구역을 열었는데 객주가 안 열린다")

	# 소리도 여기서 본다. 소리는 안 나는 게 고장인지 원래 그런 건지 귀로 못 가르고,
	# 지금은 더미라 **아예 안 들린다** — 셈으로 볼 수밖에 없다.
	# 위(7번)에서 창의 레벨업 단추를 눌렀으니 강화 소리가 한 번은 울렸어야 한다.
	if int(main.sfx.counts.get("tap", 0)) == 0:
		fails.append("매대를 눌렀는데 강화 소리를 안 울렸다")

	# 9) 승급 공사(2026-08-27) — 누르면 바로 오르는 게 아니라 시계가 돈다.
	#    ★ 4시간짜리라 밸런스 도구는 이 뒤를 못 본다(4시간 재기에서 한 번도
	#      안 끝났다). 그러면 "도구가 안 써 보는 기능"이 되므로 여기서 본다.
	var s9: Sim = Sim.new()
	var r9: Rng = Rng.new(11)
	s9.money = 1.0e18
	# 승급 조건 다섯을 채운다: 매대 만렙 · 다음 가게 · 성 합계 · 초당 수입 · 값.
	# 초당 수입은 **가게 전체**를 합쳐 세므로 한 채만으로는 못 넘는다.
	for sh9 in Content.SHOPS:
		if not s9.shops.has(String(sh9.id)):
			s9.shops.append(String(sh9.id))
		for k9 in range(4):
			var iid9: String = String(sh9.items[k9].id)
			if not s9.items.has(iid9):
				s9.items[iid9] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
			for _r9 in range(40):             # MAX_BULK가 있어 한 번엔 다 안 오른다
				if s9.level_up_many(iid9, 999) <= 0:
					break
	for g9 in Content.GUESTS:                 # 조건(성 합계)은 **가진 손님**만 센다
		if not s9.guests.has(String(g9.id)):
			s9.guests.append(String(g9.id))
		s9.stars[String(g9.id)] = 5.0
	if not s9.can_promote("smith"):
		var why9: Array = []
		var rq9: Variant = s9.promote_reqs("smith")
		if rq9 != null:
			for x9 in rq9.list:
				if not x9.ok:
					why9.append(String(x9.text))
		fails.append("승급 조건을 다 채웠는데 공사를 시작할 수 없다 — 못 찬 것: %s" % str(why9))
	else:
		var rank_before: int = s9.rank_of("smith")
		s9.promote("smith")
		if not s9.is_building("smith"):
			fails.append("공사를 시작했는데 공사 중이 아니다")
		if s9.rank_of("smith") != rank_before:
			fails.append("공사가 끝나기도 전에 등급이 올랐다")
		# 한 시간 돌려도 아직이어야 한다(4시간짜리다)
		for i9 in range(3600):
			s9.tick(1.0, r9)
		if not s9.is_building("smith"):
			fails.append("네 시간짜리 공사가 한 시간 만에 끝났다")
		# 자리를 비운 동안에도 공사는 돈다(2026-08-27에 잡은 구멍)
		var sB: Sim = Sim.new()
		sB.building["smith"] = 4.0 * 3600.0
		sB.rank["smith"] = 0
		sB.offline(5.0 * 3600.0)
		if sB.is_building("smith"):
			fails.append("다섯 시간 자리를 비웠는데 네 시간짜리 공사가 안 끝났다")
		if sB.rank_of("smith") != 1:
			fails.append("자리 비운 동안 공사가 끝났는데 등급이 안 올랐다")
		# 나뭇잎으로 당기면 그 자리에서 끝난다
		var cost9: int = s9.rush_build_cost("smith")
		if cost9 <= 0:
			fails.append("공사를 당기는 값이 0이다")
		s9.gems = float(cost9)
		if not s9.rush_build("smith"):
			fails.append("나뭇잎이 값만큼 있는데 공사를 못 당긴다")
		if s9.rank_of("smith") != rank_before + 1:
			fails.append("공사를 끝냈는데 등급이 안 올랐다")
		if s9.gems > 0.001:
			fails.append("공사를 당겼는데 나뭇잎이 안 빠졌다")
		if s9.is_building("smith"):
			fails.append("공사가 끝났는데 아직 공사 중이다")

	# 10) 패시브 스킬(2026-08-27) — 사면 실제로 세지는가.
	#     값만 빠지고 효과가 안 붙는 종류의 고장은 화면으로는 안 보인다.
	var sA: Sim = Sim.new()
	sA.gems = 1.0e9
	var walk0: float = sA.guest_walk()
	var cap0: float = sA.offline_cap()
	var slot0: int = sA.quest_slots()
	var pay0: float = sA.quest_pay_mul()
	for _i in range(20):
		sA.buy_gem_up("walk")
		sA.buy_gem_up("offtime")
		sA.buy_gem_up("questpay")
	for _i in range(4):
		sA.buy_gem_up("questslot")
	if not is_equal_approx(sA.guest_walk(), 1.0):
		fails.append("손님 걸음을 만렙까지 올렸는데 %.2f (1.00이어야 한다)" % sA.guest_walk())
	if sA.guest_walk() <= walk0:
		fails.append("손님 걸음 스킬을 샀는데 걸음이 안 빨라졌다")
	if sA.offline_cap() <= cap0:
		fails.append("오프라인 시간 스킬을 샀는데 쳐주는 시간이 그대로다")
	if not is_equal_approx(sA.offline_cap(), 8.0 * 3600.0):
		fails.append("오프라인 시간 만렙이 여덟 시간이 아니라 %.0f초" % sA.offline_cap())
	if sA.quest_slots() != slot0 + 4:
		fails.append("의뢰 자리 스킬 만렙인데 자리가 %d (%d이어야)" % [sA.quest_slots(), slot0 + 4])
	if sA.quest_pay_mul() <= pay0:
		fails.append("의뢰 보상 스킬을 샀는데 보상 배수가 그대로다")
	if int(sA.up_lv("walk")) != 20:
		fails.append("스무 번 샀는데 손님 걸음이 %d단계" % int(sA.up_lv("walk")))
	# 만렙을 넘겨 더 못 산다
	if sA.buy_gem_up("walk"):
		fails.append("만렙인데 한 번 더 팔았다")

	if fails.is_empty():
		print("TAPTEST OK")
	else:
		for f in fails:
			print("TAPTEST FAIL: " + f)
	get_tree().quit(0 if fails.is_empty() else 1)

var _snap: Dictionary = {}

## 창 안에서 글자로 단추를 찾는다(가지가 여러 겹이라 훑는다).
##
## ★ **지워지기로 예약된 것은 건너뛴다.** 창을 다시 그리면 옛 줄들이 아직
##   가지에 붙어 있는 채로 '지울 것' 표시만 달린다. 그걸 집으면 이미 죽은
##   단추를 붙잡고 시험하게 되고, 그러면 멀쩡한 판도 실패로 나온다.
func _find_btn(n: Node, starts: String) -> Button:
	for c in n.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is Button and String((c as Button).text).begins_with(starts):
			return c as Button
		var deep: Button = _find_btn(c, starts)
		if deep != null:
			return deep
	return null
