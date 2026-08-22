extends SceneTree
## 뽑기와 룰렛이 **표대로 나오는지** 잰다.
##
## ★ 확률은 눈으로 못 본다. 열 번 뽑아 다 흔함이 나와도 그게 고장인지
##   운인지 알 수가 없다. 그래서 **십만 번** 뽑아 표와 견준다.
##   확률을 고지하는 기능이라 더더욱 — 적어 놓은 값과 실제가 다르면 거짓말이 된다.
##
## 실행: godot --headless --path godot --script tests/gacha.gd

const N := 100000

func _init() -> void:
	var fails: Array[String] = []
	fails.append_array(_rates())
	fails.append_array(_wheel())
	fails.append_array(_stars())
	fails.append_array(_dogs())
	if fails.is_empty():
		print("GACHA OK")
	else:
		for f in fails:
			print("GACHA FAIL: " + f)
	quit(0 if fails.is_empty() else 1)

## 뽑기 등급 확률 — 레벨마다 십만 번씩
func _rates() -> Array[String]:
	var out: Array[String] = []
	for lv in range(1, Content.GACHA.rates.size() + 1):
		var s := Sim.new()
		var rng := Rng.new(1000 + lv)
		s.pulls = float(Content.GACHA.levelAt[lv - 1])
		if s.gacha_lv() != lv:
			out.append("%d단계여야 하는데 %d단계다" % [lv, s.gacha_lv()])
			continue
		var hit := [0, 0, 0, 0, 0, 0]
		for i in range(N):
			hit[s._roll_grade(rng) - 1] += 1
		var want: Array = Content.GACHA.rates[lv - 1]
		var line: Array[String] = []
		for g in range(6):
			var got: float = 100.0 * float(hit[g]) / float(N)
			line.append("%.2f" % got)
			# 십만 번이면 오차는 0.2%p 안쪽이다. 0.5%p를 넘으면 표와 코드가 다른 것이다.
			if absf(got - float(want[g])) > 0.5:
				out.append("%d단계 %s: 표 %.1f%% 인데 실제 %.2f%%"
					% [lv, Content.CARD_GRADES[g].name, float(want[g]), got])
		print("  뽑기 %2d단계  %s" % [lv, " · ".join(line)])
	return out

## 룰렛 칸 — 십만 번
func _wheel() -> Array[String]:
	var out: Array[String] = []
	var s := Sim.new()
	var rng := Rng.new(77)
	var hit: Array = []
	for i in range(Content.ROULETTE.wedges.size()):
		hit.append(0)
	# 돌릴 수 있게 횟수를 넉넉히 준다(여기서 보는 건 확률이지 횟수 제한이 아니다)
	for i in range(N):
		s.roulFree = 1.0
		var got: Variant = s.spin(false, rng)
		if got == null:
			out.append("룰렛이 안 돌았다")
			break
		hit[int(got.wedge)] += 1
	for i in range(hit.size()):
		var w: Dictionary = Content.ROULETTE.wedges[i]
		var got2: float = 100.0 * float(hit[i]) / float(N)
		if absf(got2 - float(w.weight)) > 0.5:
			out.append("룰렛 '%s': 표 %d%% 인데 실제 %.2f%%" % [String(w.label), int(w.weight), got2])
	print("  룰렛 열두 칸 — 표와 실제가 0.5%p 안쪽")
	return out

## 카드로 성 올리기 — 표에 적힌 장수만큼만 든다
func _stars() -> Array[String]:
	var out: Array[String] = []
	var s := Sim.new()
	var gid := "rabbit"
	var total: float = 0.0
	for step in range(Content.STAR_CARDS.size()):
		var need: float = float(Content.STAR_CARDS[step])
		s.cards[gid] = need - 1.0
		if s.can_star_up(gid):
			out.append("%d성: 한 장 모자란데 올라간다" % (step + 1))
		s.cards[gid] = need
		if not s.star_up(gid):
			out.append("%d성: 장수가 찼는데 안 올라간다" % (step + 1))
		if s.cards[gid] != 0.0:
			out.append("%d성: 카드가 %s장 남았다(0이어야 한다)" % [step + 1, str(s.cards[gid])])
		total += need
	if s.regular_star(gid) != 20:
		out.append("끝까지 올렸는데 %d성이다" % s.regular_star(gid))
	if s.star_need(gid) != null:
		out.append("20성인데 더 올릴 수 있다고 한다")
	print("  20성까지 카드 %d장" % int(total))
	return out

## 삽살개 — 여러 마리, 값, 무는 확률 상한
func _dogs() -> Array[String]:
	var out: Array[String] = []
	var s := Sim.new()
	s.money = 1.0e12
	for i in range(20):
		s.shops.append("x%d" % i)          # 자리 수만 늘린다
	var n: int = 0
	while s.can_buy_guard() and n < 12:
		s.buy_guard()
		n += 1
	if s.guards != float(s.guard_max()):
		out.append("개를 %d마리 샀는데 상한은 %d마리다" % [int(s.guards), s.guard_max()])
	if s.guard_rate() > float(Content.GUARD.rateCap) + 0.0001:
		out.append("무는 확률이 상한(%.0f%%)을 넘었다: %.1f%%"
			% [float(Content.GUARD.rateCap) * 100.0, s.guard_rate() * 100.0])
	print("  삽살개 %d마리 · 무는 확률 %.1f%%" % [int(s.guards), s.guard_rate() * 100.0])
	return out
