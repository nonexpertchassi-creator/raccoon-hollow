extends SceneTree
## 장부가 실제로 쌓이고, 순위가 말이 되는지 본다.
func _init() -> void:
	var s := Sim.new()
	var rng := Rng.new(7)
	for i in range(90 * 60 * 4):        # 90분 = 게임내 11일 = 두 장 남짓
		s.tick(0.25, rng)
		RunSim.act(s, rng)
	print("게임내 %d일째 · %d번째 장 %d일차 · 담아둔 날 %d개" % [
		s.day(), s.fair_no() + 1, s.fair_day(), s.ledger.size()])
	var FAIR_DAYS: int = int(Content.LEDGER.daysPerFair)
	print("\n[이번 장 핫템]")
	for r in s.hot_items(FAIR_DAYS, 6):
		print("   %-10s %d개" % [s.item_name(r[0]), int(r[1])])
	var top: Array = s.hot_items(FAIR_DAYS, 1)
	if not top.is_empty():
		print("\n[%s를 사간 동물]" % s.item_name(top[0][0]))
		for r in s.buyers_of(top[0][0], FAIR_DAYS, 4):
			print("   %-8s %d개" % [Sim.guest_by_id(r[0]).name, int(r[1])])
		print("   → 제일 많이 사간 건: ", Sim.guest_by_id(s.best_buyer(top[0][0], FAIR_DAYS)).name)
	print("\n[마을별 핫템]")
	for g in s.guests:
		var h: String = s.hot_for(g, FAIR_DAYS)
		if h != "":
			print("   %s마을 → %s" % [Sim.guest_by_id(g).name, s.item_name(h)])
	# 순위가 장마다 바뀌는지 — 안 바뀌면 이 기능을 넣은 이유가 없다
	var a: Array = s.hot_items(FAIR_DAYS, 3)
	var b: Array = s.hot_items(0, 3)
	print("\n이번 장 1등: %s · 전체 누적 1등: %s%s" % [
		s.item_name(a[0][0]), s.item_name(b[0][0]),
		"   ← 다르다(좋다)" if a[0][0] != b[0][0] else "   ← 같다"])
	quit()
