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

## 구역이 열린 시각 — 문턱(성·엽전)을 재서 잡으려면 이게 보여야 한다
static var unlocked_at: Dictionary = {}

static func act(s: Sim, rng: Rng, use_shop_up: bool) -> void:
	if s.busy >= 0 and s.tap_small(s.busy):
		return
	if s.pest != null:
		s.catch_pest(rng)
		return
	# 잠긴 구역 — 조건이 차면 바로 연다. 이걸 안 가르치면 배우는
	# 가게 여섯에서 영영 멈춘다(next_shop이 잠긴 구역을 없는 셈 치니까).
	for dz in Content.DISTRICTS:
		if s.can_unlock_district(String(dz.id)):
			s.unlock_district(String(dz.id))
			unlocked_at[String(dz.id)] = s.t
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
	for sh in s.shops:
		if s.can_hire_staff(sh):
			s.hire_staff(sh)
			return
	# 다 찬 의뢰의 삯 받기 — 저절로 안 들어온다(2026-08-25, 수동 수령)
	for q in s.quests:
		if bool(q.get("done", false)):
			s.claim_quest(float(q.id))
			return
	# ★ 장부 정리(자동 강화)는 **안 산다.** 게임에서 뺐기 때문이다.
	#   여기서만 사면 재는 판과 사람이 노는 판이 달라진다 — 그러면 잰 값이
	#   아무 말도 안 해준다. (대조 시험 쪽 RunSim은 답안지와 맞춰야 하니 그대로 산다.)
	if s.can_buy_guard():
		s.buy_guard()
		return
	# 길에 떨어진 것 — 손이 비면 줍는다. 도구가 안 써 보는 기능은 도구에게 없는 것이다.
	if s.trash >= 1.0 and s.tap_trash():
		return
	if s.can_buy_sweeper():
		s.buy_sweeper()
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
	# ── 뽑기·성 올리기 ──
	#
	# ★ 이걸 안 넣었더니 **8시간 매출이 1.47T에서 3.28B로 주저앉았다.**
	#   손님이 이제 뽑기로만 오는데 도구가 뽑기를 안 하니, 토끼 한 마리로
	#   여덟 시간을 장사한 셈이다. 두 시간 만에 새로 열리는 것이 끊겼다.
	#   *도구가 안 써 보는 기능은 도구에게 없는 것이다* — 다섯 번째다.
	if s.can_spin(false):
		s.spin(false, rng)
		return
	if s.can_spin(true):
		s.spin(true, rng)
		return
	# 모은 카드는 바로 성으로 바꾼다. 공짜로 세지는 것을 안 쓸 이유가 없다.
	for gid in s.guests:
		if s.can_star_up(String(gid)):
			s.star_up(String(gid))
			return
	# 열 장씩 뽑는다 — 한 장씩보다 싸고 드묾 보장이 붙는다
	if s.can_pull(10):
		s.pull(10, rng)
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
	# 작은 건물은 게임에서 빠졌다(2026-08-25) — 배우도 안 짓는다.
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
	unlocked_at = {}
	var s := Sim.new()
	var rng := Rng.new(seed_value)
	# ★ 긴 판을 재려면 성글게 돌 수 있어야 한다(2026-08-28). 4주치(봇 33시간)를
	#   0.25초로 돌면 47만 틱이라 십 분을 훌쩍 넘긴다.
	#   **다만 성글게 돌면 값이 달라진다** — 얼마나 달라지는지 재 보고 쓸 것.
	#   BAL_DT=1 은 "가게가 언제 열리나" 같은 **속도 재기 전용**이다.
	#   돈 곡선을 확정하거나 골든을 박을 때는 반드시 기본값(0.25)으로 돈다.
	var dt: float = float(OS.get_environment("BAL_DT")) if OS.has_environment("BAL_DT") else 0.25

	var guest_at: Dictionary = {}
	var last_new: float = 0.0            # 마지막으로 뭔가 새로 열린 시각
	var seen_items: Dictionary = {}
	var seen_ranks: Dictionary = {}
	var shop_at: Dictionary = {}
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
			# ★ 가게가 **언제** 열렸는지 하나하나 찍는다(2026-08-28).
			#   여태 "마지막으로 새것이 열린 시각" 하나만 찍었더니, 뒤쪽 가게가
			#   전부 안 열려도 그 한 줄은 멀쩡해 보였다. 사다리를 재려면
			#   "몇 번째 가게가 몇 시에 열리나"가 있어야 한다.
			if not shop_at.has(sh):
				shop_at[sh] = s.t
			var k: String = "%s:%d" % [sh, s.rank_of(sh)]
			if s.rank_of(sh) > 0 and not seen_ranks.has(k):
				seen_ranks[k] = true
				last_new = s.t
		if s.t >= next_hour:
			next_hour += 3600.0
			# ★ 돈만 찍으면 구역 문턱을 못 잡는다(2026-08-27). 문턱은 **돈과 성 둘 다**라,
			#   "이 시각에 성이 몇이고 손에 돈이 얼마인가"를 같이 봐야 값을 정할 수 있다.
			#   재려는 것을 도구가 안 찍으면 그 값은 결국 짐작이 된다.
			var st: int = 0
			for gid2 in s.guests:
				st += s.regular_lv(String(gid2))
			curve.append([s.t, s.revenue, s.income_per_sec(), float(st), s.money])

	var tag: String = OS.get_environment("BAL_ONLY") if OS.has_environment("BAL_ONLY") else ("전부" if use_up else "끔")
	var line: String = "%-10s" % tag
	for c in curve:
		line += "  %8s" % Num.fmt(c[1])
	if OS.has_environment("BAL_TERSE"):
		print(line)
		quit()
	print("═══ %d시간 · 운 번호 %d · 가게 강화 %s ═══" % [int(hours), seed_value, tag])
	for c in curve:
		print("   %2d시간   누적매출 %-9s 초당 %-8s 성 %-4d 가진 돈 %s" % [
			int(c[0] / 3600.0), Num.fmt(c[1]), Num.fmt(c[2]), int(c[3]), Num.fmt(c[4])])
	print("   손님 열둘이 다 온 시각: %s" % (
		_mm(guest_at.values().max()) if guest_at.size() >= Content.GUESTS.size() else "아직 다 안 옴"))
	print("   마지막으로 새것이 열린 시각: %s  (그 뒤는 레벨업뿐)" % _mm(last_new))
	var sl: String = "   가게 열린 시각:"
	for k5 in range(Content.SHOPS.size()):
		var sid5: String = String(Content.SHOPS[k5].id)
		sl += " %s=%s" % [Content.SHOPS[k5].name, _mm(shop_at[sid5]) if shop_at.has(sid5) else "—"]
	print(sl)
	# ★ 뽑기가 들어온 뒤로 **여기가 병목인지 아닌지**를 매번 봐야 한다.
	#   손님이 안 늘면 경제가 안 자라는데, 손님은 나뭇잎이 있어야 는다.
	var stars_sum: int = 0
	for gid in s.guests:
		stars_sum += s.regular_lv(String(gid))
	# ★ 봇이 남긴 자국을 파일로 떨어뜨린다. 사람이 오기 전에 **판이 진짜
	#   그려지는지** 보려면 이 자국이 필요하다. 계측이 빠진 칸은 여기서 0으로
	#   드러난다 — 출시 뒤에 아는 것보다 지금 아는 게 훨씬 싸다.
	var f: FileAccess = FileAccess.open("res://stats.json", FileAccess.WRITE)
	if f != null:
		var out: Dictionary = s.stats.duplicate()
		out["_meta.hours"] = hours
		out["_meta.seed"] = float(seed_value)
		out["_meta.revenue"] = s.revenue
		out["_meta.money"] = s.money
		out["_meta.gems"] = s.gems
		out["_meta.shops"] = float(s.shops.size())
		out["_meta.guests"] = float(s.guests.size())
		out["_meta.stars"] = float(stars_sum)
		out["_meta.gachaLv"] = float(s.gacha_lv())
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		print("   자국을 godot/stats.json 에 남겼다 — node tools/dash.mjs")
	for zid in unlocked_at:
		print("   구역 %s 열림: %s" % [zid, _mm(unlocked_at[zid])])
	print("   뽑기 %d회(%d단계) · 손님 %d/%d · 성 합계 %d · 남은 나뭇잎 %d · 가게 %d/%d" % [
		int(s.pulls), s.gacha_lv(), s.guests.size(), Content.GUESTS.size(),
		stars_sum, int(s.gems), s.shops.size(), Content.SHOPS.size()])
	if use_up:
		var got: Array[String] = []
		for sh in s.shops:
			# ★ 가게 고유 강화는 **다섯 채에만** 있다(smith·brush·paper·pot·herb).
			#   없는 가게를 그냥 찾다가 24시간 측정이 끝에서 죽었다(2026-08-27,
			#   여섯째 가게가 열리는 순간). 긴 판을 못 재면 뒷구역을 영영 못 본다.
			if Content.SHOP_UP.has(sh):
				got.append("%s %d/%d" % [Content.SHOP_UP[sh].name, s.shop_up_lv(sh), int(Content.SHOP_UP[sh].max)])
		print("   산 강화: " + " · ".join(got))
	# 패시브 스킬(2026-08-27) — 배우가 나뭇잎을 어디에 썼나. 안 적으면 도구가
	# 스킬을 산 것도, 안 산 것도 말해 주지 않는다(도구 규칙 3).
	var sk: Array[String] = []
	for u in Content.GEM_UPGRADES:
		var l: int = int(s.up_lv(u.id))
		if l > 0:
			sk.append("%s %d/%d" % [u.name, l, int(u.max)])
	print("   패시브 스킬: " + (" · ".join(sk) if not sk.is_empty() else "한 칸도 안 올림"))
	print("   승급 공사: 시작한 승급 %d · 잎으로 당김 %d · 아직 공사 중 %d" % [
		int(s.stats.get("open.promote", 0.0)), int(s.stats.get("build.rush", 0.0)), s.building.size()])
	quit()
