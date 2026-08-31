extends SceneTree
## **마을이 커지면 무거워지나** — 짐작하지 말고 센다(2026-08-29, 유저 물음:
## *"한내 이상으로 골목들이 추가될 때 데이터의 무게는 문제 없을까?"*).
##
## 세는 것 넷:
##   한 번 그릴 때 도는 것 (바닥 · 소품 · 가게 가구)
##   저장본 크기
##   sim 한 틱이 몇 마이크로초
##
## ★ 처음 돌렸을 때 나온 것: **바닥 988칸을 매 프레임 다시 그린다.**
##   폰 화면에 실제로 보이는 건 570칸(줌 1.0), 가까이 보면 200칸뿐인데
##   화면 밖을 하나도 안 자른다 — 지금도 다섯 배쯤 헛일을 하고 있다.
##   마을을 넓히기 전에 이것부터 고쳐야 한다.
##
## 실행: godot --headless --path godot --script tests/weigh.gd
func _init() -> void:
	var s := Sim.new()
	var rng := Rng.new(1)
	# 다 열어 놓고 잰다 — 제일 무거운 판이 궁금한 것이다
	s.money = 1e30
	for sh in Content.SHOPS:
		if not s.shops.has(String(sh.id)):
			s.shops.append(String(sh.id))
			s._deal_fur(String(sh.id))
		s.bench[String(sh.id)] = 8.0
		s.rank[String(sh.id)] = 2
		for it in sh.items:
			s.items[String(it.id)] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	var W: int = Iso.GW + Iso.EDGE * 2
	var H: int = Iso.GH + Iso.EDGE * 2
	print("마을 %d × %d = **바닥 %d칸** (화면 밖까지 전부 그린다)" % [W, H, W * H])

	# 소품 — village._make_props와 같은 셈
	var rp := Rng.new(20260820)
	var props: int = 0
	for ty in range(-Iso.EDGE, Iso.GH + Iso.EDGE):
		for tx in range(-Iso.EDGE, Iso.GW + Iso.EDGE):
			if tx >= 0 and ty >= 0 and tx < Iso.GW and ty < Iso.GH:
				continue
			if Iso.is_road(tx, ty) or rp.next() > 0.62:
				continue
			props += 1
	for ty in range(Iso.GH):
		for tx in range(Iso.GW):
			if Iso.is_road(tx, ty):
				continue
			var near: bool = false
			for st in Iso.SHOP_T:
				if absi(st.x - tx) <= 5 and absi(st.y - ty) <= 5:
					near = true
			for st in Iso.SMALL_T:
				if absi(st.x - tx) <= 1 and absi(st.y - ty) <= 1:
					near = true
			if near or (absi(Iso.DOG_T.x - tx) <= 1 and absi(Iso.DOG_T.y - ty) <= 1):
				continue
			if rp.next() > 0.30:
				continue
			props += 1
			rp.next()
	print("소품 %d개" % props)

	# 가게 가구
	var furn: int = 0
	for i in range(Content.SHOPS.size()):
		var n: int = 3 + 2
		var y: Dictionary = Iso.yard(Iso.YARD_KIND[i], n)
		furn += 1 + 1 + s.bench_cap(String(Content.SHOPS[i].id)) + y.counters.size()
	print("가게 가구 %d개 (마당바닥+가마+작업대+계산대, 가게 %d채)" % [furn, Content.SHOPS.size()])
	print("── 한 번 그릴 때 합계 약 **%d개**" % (W * H + props + furn))

	# 저장본
	print("저장본 %d바이트" % s.to_blob().size())

	# 한 틱이 얼마나 걸리나
	var t0: int = Time.get_ticks_usec()
	for i in range(60 * 60 * 4):        # 한 시간어치
		s.tick(0.25, rng)
	var us: int = Time.get_ticks_usec() - t0
	print("sim 한 시간(14,400틱) %.2f초 · 한 틱 %.1f마이크로초" % [us / 1e6, float(us) / 14400.0])
	quit(0)
