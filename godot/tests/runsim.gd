class_name RunSim
## 같은 씨앗·같은 판단으로 시뮬레이션을 돌리고 1분마다 상태를 적는다.
## JS 쪽(tools/answers.mjs)과 **한 글자도 다르면 안 된다.**
##
## 적는 값은 전부 정수로 만든다. 소수를 글자로 찍으면 JS와 Godot의 표기가
## 갈릴 수 있어서, 규칙이 맞는데도 빨간불이 뜬다 — 그러면 시험을 못 믿는다.
## 소수는 1000을 곱해 반올림한다(0.001까지는 본다).

## 가상 플레이어. balance.mjs의 판단과 같은 순서다.
static func act(s: Sim, rng: Rng) -> void:
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
	if s.can_buy_auto():
		s.buy_auto()
		return
	if s.can_buy_guard():
		s.buy_guard()
		return
	# 젬 강화 — 제일 싼 것부터. 정렬이 아니라 훑어서 고른다(같으면 먼저 나온 쪽)
	var best: String = ""
	var best_cost: float = INF
	var any_left: bool = false
	for u in Content.GEM_UPGRADES:
		var c: Variant = s.gem_cost(u.id)
		if c == null:
			continue
		any_left = true
		if s.gems >= float(c) and float(c) < best_cost:
			best_cost = float(c)
			best = u.id
	if best != "":
		s.buy_gem_up(best)
		return
	if not any_left and s.can_rush():
		s.call_rush()
		return
	# 작은 건물은 게임에서 빠졌다(2026-08-25) — 배우도 안 짓는다.
	if s.auto:
		return
	var cheap: String = ""
	var cheap_cost: float = INF
	for id in s.items.keys():
		if s.at_max(id):
			continue
		var c2: float = s.level_cost(id)
		if c2 < cheap_cost:
			cheap_cost = c2
			cheap = id
	if cheap != "" and s.money >= cheap_cost:
		s.level_up_many(cheap, 10)

static func _k(x: float) -> String:
	return str(int(round(x * 1000.0)))

static func snapshot(s: Sim) -> String:
	var stock: float = 0.0
	var prog: float = 0.0
	var lvsum: float = 0.0
	for id in s.items.keys():
		stock += s.items[id].stock
		prog += s.items[id].prog
		lvsum += s.items[id].lv
	var ranksum: int = 0
	for sh in s.shops:
		ranksum += s.rank_of(sh)
	var staffsum: float = 0.0
	for sh in s.shops:
		staffsum += s.staff_of(sh)
	var visitsum: float = 0.0
	for k in s.visits.keys():
		visitsum += s.visits[k]
	var gacc: float = 0.0
	for k in s._guestAcc.keys():
		gacc += s._guestAcc[k]
	var qsig: Array[String] = []
	for q in s.quests:
		qsig.append("%s:%s:%d:%d" % [q.gid, q.itemId, int(q.need), int(q.got)])
	var osig: Array[String] = []
	for o in s.orders:
		osig.append("%d:%s:%d" % [o.id, o.gid, int(round(o.t * 1000.0))])
	var f: Array[String] = [
		str(int(round(s.t))), str(int(s.money)), str(int(s.revenue)), str(int(s.gems)),
		str(int(s.sold)), str(s.items.size()), str(s.shops.size()), str(s.guests.size()),
		str(s.asked.size()), str(s.quests.size()), str(s.orders.size()),
		str(int(stock)), _k(prog), str(int(lvsum)), str(ranksum), str(int(staffsum)),
		str(s.smalls.size()), _k(s.fair), _k(s.rush), _k(s._fairAcc), _k(s._askAcc),
		_k(gacc), str(int(floor(s._purse))), str(int(visitsum)),
		str(s._evIdx), str(s.skins.size()), str(int(s.event.got)) if s.event != null else "-",
		"1" if s.auto else "0", "1" if s.guard else "0", "1" if s.pest != null else "0",
		",".join(qsig), ",".join(osig),
	]
	return "\t".join(f)

## ★ 저장 시험 — 담을 칸을 하나라도 빠뜨렸으면 여기서 잡힌다.
##
## 반쯤 돌린 뒤 저장하고, 그 저장본을 **글자로 만들었다가 도로 읽어**
## 새 Sim에 넣는다(진짜 파일에 쓰는 것과 같은 길을 지나게 하려고).
## 그리고 안 껐던 판과 저장했다 켠 판을 **같은 주사위로 끝까지 나란히 돌린다.**
##
## 칸 하나를 빠뜨리면 그 순간엔 티가 안 난다 — 몇 분 뒤에 곡선이 갈라진다.
## 그래서 저장 직후가 아니라 **한참 더 돌려서** 대조한다.
static func save_test(seed_value: int, seconds: float, dt: float) -> String:
	var a := Sim.new()
	var rng_a := Rng.new(seed_value)
	var half: float = seconds * 0.5
	var el: float = 0.0
	while el < half:
		a.tick(dt, rng_a)
		act(a, rng_a)
		el += dt

	# 저장 → 글자 → 다시 읽기 → 새 Sim
	var blob: PackedByteArray = a.to_blob()
	var b := Sim.new()
	b.load_from(Sim.from_blob(blob))

	# 이제부터 둘을 같은 주사위로 나란히 돌린다
	var ra := Rng.new(seed_value + 991)
	var rb := Rng.new(seed_value + 991)
	var out: Array[String] = []
	var next_mark: float = 60.0
	var el2: float = 0.0
	while el2 < half:
		a.tick(dt, ra)
		act(a, ra)
		b.tick(dt, rb)
		act(b, rb)
		el2 += dt
		if el2 >= next_mark:
			next_mark += 60.0
			var sa: String = snapshot(a)
			var sb: String = snapshot(b)
			out.append(sa if sa == sb else "안 껐을 때: %s\n저장했다 켰을 때: %s" % [sa, sb])
	return "\n".join(out) + "\n"

## seconds초를 돌리고 1분마다 한 줄씩
static func run(seed_value: int, seconds: float, dt: float) -> String:
	var s := Sim.new()
	var rng := Rng.new(seed_value)
	var out: Array[String] = []
	var next_mark: float = 60.0
	var elapsed: float = 0.0
	while elapsed < seconds:
		s.tick(dt, rng)
		act(s, rng)
		elapsed += dt
		if elapsed >= next_mark:
			next_mark += 60.0
			out.append(snapshot(s))
	return "\n".join(out) + "\n"
