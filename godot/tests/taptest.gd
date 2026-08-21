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
	for i in range(60 * 4):
		s.tick(0.25, rng)

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
	if not s.guard:
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
