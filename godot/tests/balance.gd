extends SceneTree
## 밸런스 측정 — Godot 쪽 판을 직접 돌려 곡선을 본다.
##
## ★ 왜 tools/balance.mjs를 안 쓰고 새로 만드나.
##
## 자바스크립트판은 이제 **답안지**다. 이미 옮긴 것이 맞는지 대조하는 데만 쓰고
## 새 규칙은 Godot에서만 자란다. 가게 고유 강화는 Godot에만 있으므로
## 자바스크립트 도구로는 잴 방법이 아예 없다.
##
## ★ 대조 시험의 가상 플레이어(RunSim.act)와 **일부러 다른 사람**이다.
##   저쪽은 자바스크립트판과 한 줄씩 같아야 해서 새 강화를 못 산다.
##   여기서는 산다 — 그래야 그 강화가 경제에 뭘 하는지 보인다.
##
## 실행:
##   godot --headless --path godot --script tests/balance.gd
##   BAL_HOURS=8 BAL_SEED=2 BAL_SHOPUP=0 godot … (강화를 끄고 재기)

static func act(s: Sim, rng: Rng, use_shop_up: bool) -> void:
	if s.busy >= 0 and s.tap_small(s.busy):
		return
	if s.pest != null:
		s.catch_pest(rng)
		return
	var ns: Variant = s.next_shop()
	if ns != null and s.money >= ns.cost:
		s.open_shop(ns.id)
		return
	for id in s.asked:
		if s.can_open_item(id):
			s.open_item(id)
			return
	for sh in s.shops:
		if s.can_promote(sh):
			s.promote(sh)
			return
	if s.can_buy_auto():
		s.buy_auto()
		return
	if s.can_buy_guard():
		s.buy_guard()
		return
	for sh in s.shops:
		if s.can_hire_staff(sh):
			s.hire_staff(sh)
			return
	# 가게 고유 강화 — 제일 싼 것부터.
	# BAL_ONLY=smith 처럼 주면 그 가게 것만 산다(하나씩 재려고).
	if use_shop_up:
		var only: String = OS.get_environment("BAL_ONLY") if OS.has_environment("BAL_ONLY") else ""
		var best: String = ""
		var best_c: float = INF
		for sh in s.shops:
			if only != "" and sh != only:
				continue
			var c: Variant = s.shop_up_cost(sh)
			if c != null and s.money >= float(c) and float(c) < best_c:
				best_c = float(c)
				best = sh
		if best != "":
			s.buy_shop_up(best)
			return
	var up: String = ""
	var up_c: float = INF
	var any_left: bool = false
	for u in Content.GEM_UPGRADES:
		var c2: Variant = s.gem_cost(u.id)
		if c2 == null:
			continue
		any_left = true
		if s.gems >= float(c2) and float(c2) < up_c:
			up_c = float(c2)
			up = u.id
	if up != "":
		s.buy_gem_up(up)
		return
	if not any_left and s.can_rush():
		s.call_rush()
		return
	var sm: int = s.next_small()
	if sm >= 0 and s.can_build_small(sm):
		s.build_small(sm)
		return
	if s.auto:
		return
	var cheap: String = ""
	var cheap_c: float = INF
	for id in s.items.keys():
		if s.at_max(id):
			continue
		var c3: float = s.level_cost(id)
		if c3 < cheap_c:
			cheap_c = c3
			cheap = id
	if cheap != "" and s.money >= cheap_c:
		s.level_up_many(cheap, 10)

static func _env(k: String, d: float) -> float:
	return float(OS.get_environment(k)) if OS.has_environment(k) else d

func _mm(sec: float) -> String:
	var m: int = int(sec / 60.0)
	return "%d시간%02d분" % [m / 60, m % 60] if m >= 60 else "%d분" % m

func _init() -> void:
	var hours: float = _env("BAL_HOURS", 8.0)
	var seed_value: int = int(_env("BAL_SEED", 1.0))
	var use_up: bool = _env("BAL_SHOPUP", 1.0) > 0.5
	var s := Sim.new()
	var rng := Rng.new(seed_value)
	var dt: float = 0.25

	var guest_at: Dictionary = {}
	var last_new: float = 0.0            # 마지막으로 뭔가 새로 열린 시각
	var seen_items: Dictionary = {}
	var seen_ranks: Dictionary = {}
	var curve: Array = []
	var next_hour: float = 3600.0

	while s.t < hours * 3600.0:
		s.tick(dt, rng)
		act(s, rng, use_up)
		for g in s.guests:
			if not guest_at.has(g):
				guest_at[g] = s.t
				last_new = s.t
		for id in s.items.keys():
			if not seen_items.has(id):
				seen_items[id] = true
				last_new = s.t
		for sh in s.shops:
			var k: String = "%s:%d" % [sh, s.rank_of(sh)]
			if s.rank_of(sh) > 0 and not seen_ranks.has(k):
				seen_ranks[k] = true
				last_new = s.t
		if s.t >= next_hour:
			next_hour += 3600.0
			curve.append([s.t, s.revenue, s.income_per_sec()])

	var tag: String = OS.get_environment("BAL_ONLY") if OS.has_environment("BAL_ONLY") else ("전부" if use_up else "끔")
	var line: String = "%-10s" % tag
	for c in curve:
		line += "  %8s" % Num.fmt(c[1])
	if OS.has_environment("BAL_TERSE"):
		print(line)
		quit()
	print("═══ %d시간 · 씨앗 %d · 가게 강화 %s ═══" % [int(hours), seed_value, tag])
	for c in curve:
		print("   %2d시간   누적매출 %-9s 초당 %s" % [
			int(c[0] / 3600.0), Num.fmt(c[1]), Num.fmt(c[2])])
	print("   손님 열둘이 다 온 시각: %s" % (
		_mm(guest_at.values().max()) if guest_at.size() >= Content.GUESTS.size() else "아직 다 안 옴"))
	print("   마지막으로 새것이 열린 시각: %s  (그 뒤는 레벨업뿐)" % _mm(last_new))
	if use_up:
		var got: Array[String] = []
		for sh in s.shops:
			got.append("%s %d/%d" % [Content.SHOP_UP[sh].name, s.shop_up_lv(sh), int(Content.SHOP_UP[sh].max)])
		print("   산 강화: " + " · ".join(got))
	quit()
