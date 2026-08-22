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
	# ★ 씨앗을 못 박는다. main은 시계로 씨앗을 잡으므로(사람이 놀 때는 그게 맞다)
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

	# 1) 매대를 누르면 **그 품목**이 오른다
	var y: Dictionary = Iso.yard(Iso.YARD_KIND[0], Iso.plot_dim(s, 0))
	var o: Vector2i = Iso.org(s, 0)
	for k in range(min(s.stall_cap("smith"), Content.SHOPS[0].items.size())):
		var it: Dictionary = Content.SHOPS[0].items[k]
		if not s.is_open(it.id):
			continue
		var before: float = s.lv(it.id)
		var sp: Vector2i = y.stalls[k]
		main._tap(Iso.w(o.x + sp.x + 0.5, o.y + sp.y + 0.5) + Vector2(0, -18))
		if s.lv(it.id) <= before:
			fails.append("매대 %d(%s)를 눌렀는데 레벨이 안 올랐다" % [k, it.name])
		# 옆 매대가 같이 오르면 안 된다
		for k2 in range(min(s.stall_cap("smith"), Content.SHOPS[0].items.size())):
			if k2 == k:
				continue
			var it2: Dictionary = Content.SHOPS[0].items[k2]
			if s.is_open(it2.id) and s.lv(it2.id) != _snap.get(it2.id, s.lv(it2.id)):
				fails.append("매대 %d를 눌렀는데 %s도 같이 올랐다" % [k, it2.name])
		_snap[it.id] = s.lv(it.id)

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

	# 3) 작은 건물 자리를 누르면 세워진다
	var before_small: int = s.smalls.size()
	main._tap(Iso.w(Iso.SMALL_T[0].x + 1, Iso.SMALL_T[0].y + 1) + Vector2(0, -20))
	if s.smalls.size() != before_small + 1:
		fails.append("작은 건물 자리를 눌렀는데 안 세워졌다")

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
		main.card.close()
	# 열 장 뽑기 — 드묾 보장이 걸리는 자리
	var pull10: Button = _find_btn(main.panel, "10회")
	if pull10 != null:
		var g0: float = s.gems
		pull10.emit_signal("pressed")
		if s.gems >= g0:
			fails.append("10회 뽑기를 눌렀는데 젬이 안 줄었다")
		main.card.close()
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
		if not main.card.visible:
			fails.append("룰렛을 돌렸는데 결과가 안 떴다")
		main.card.close()
	main.panel.close()

	# 9) 도감에서 **카드로 성을 올린다**
	s.cards["rabbit"] = 999.0
	var lv0: int = s.regular_lv("rabbit")
	main.panel.open_kind("guests")
	var starbtn: Button = _find_btn(main.panel, "%d성으로" % (lv0 + 2))
	if starbtn == null:
		fails.append("도감에 성 올리는 단추가 없다")
	else:
		starbtn.emit_signal("pressed")
		if s.regular_lv("rabbit") != lv0 + 1:
			fails.append("성 올리기를 눌렀는데 안 올랐다")
	main.panel.close()

	# 소리도 여기서 본다. 소리는 안 나는 게 고장인지 원래 그런 건지 귀로 못 가르고,
	# 지금은 더미라 **아예 안 들린다** — 셈으로 볼 수밖에 없다.
	# 위에서 매대를 눌렀으니 강화 소리가 한 번은 울렸어야 한다.
	if int(main.sfx.counts.get("tap", 0)) == 0:
		fails.append("매대를 눌렀는데 강화 소리를 안 울렸다")

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
