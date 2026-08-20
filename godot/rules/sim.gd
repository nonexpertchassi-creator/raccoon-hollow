class_name Sim
extends RefCounted
## 경제 규칙. 그리는 코드가 한 줄도 없다. sim.js를 옮긴 것.
##
## ★ 옮기면서 조심한 것 넷. 전부 "조용히 달라지는" 종류라 적어 둔다.
##
## 1. **정수 나누기.** GDScript는 7 / 2가 3이다(JS는 3.5).
##    그래서 content.gd의 숫자를 전부 실수로 뽑았고, 여기서 만드는 숫자도
##    (재고·레벨까지) 전부 실수로 둔다. 한 군데만 정수여도 거기서 갈린다.
##
## 2. **딕셔너리 순서.** 손님이 물건을 고를 때 items의 순서를 섞어 쓴다.
##    JS의 Object.keys와 Godot의 Dictionary.keys()는 둘 다 넣은 순서를
##    지키므로 같다. 순서가 달라지면 같은 주사위로도 다른 물건을 집는다.
##
## 3. **정렬의 안정성.** Godot의 sort_custom은 같은 값끼리의 순서를 보장하지
##    않는다(JS는 보장한다). 그래서 '제일 싼 것 고르기'를 정렬 대신
##    **처음부터 훑어 제일 작은 것**으로 짰다 — 같으면 먼저 나온 쪽이 이긴다.
##
## 4. **지우기.** Array.erase는 값으로 찾는데 딕셔너리끼리 비교는 믿기 어렵다.
##    주문·의뢰는 전부 고유 번호(id)로 찾아 지운다.

const MASK_NONE := 0

static var _all_items: Array = []
static var _item_by_id: Dictionary = {}
static var _shop_by_id: Dictionary = {}
static var _guest_by_id: Dictionary = {}
static var _gu: Dictionary = {}

static func _tables() -> void:
	if not _all_items.is_empty():
		return
	for s in Content.SHOPS:
		_shop_by_id[s.id] = s
		for i in s.items:
			var it: Dictionary = (i as Dictionary).duplicate()
			it["shop"] = s.id
			_all_items.append(it)
			_item_by_id[it.id] = it
	for g in Content.GUESTS:
		_guest_by_id[g.id] = g
	for u in Content.GEM_UPGRADES:
		_gu[u.id] = u

static func item_by_id(id: String) -> Dictionary: return _item_by_id[id]
static func shop_by_id(id: String) -> Dictionary: return _shop_by_id[id]
static func guest_by_id(id: String) -> Dictionary: return _guest_by_id[id]

# ── 상태 ──
var money: float = 0.0
var revenue: float = 0.0
var t: float = 0.0
var shops: Array = ["smith"]
var rank: Dictionary = {}
var items: Dictionary = {"pick": {"lv": 1.0, "stock": 0.0, "prog": 0.0}}
var asked: Array = []
var guests: Array = ["rabbit"]
var bought: Dictionary = {}
var visits: Dictionary = {}
var sold: float = 0.0
var auto: bool = false
var smalls: Array = []
var guard: bool = false
var staff: Dictionary = {}
var fair: float = 0.0
var busy: int = -1
var _busyT: float = 0.0
var _fairAcc: float = 0.0
var _purse: float = 0.0
var events: Array = []

var quests: Array = []
var gems: float = 0.0
var gemUp: Dictionary = {}
var maxGem: Dictionary = {}
var _qid: int = 0
var _qCool: float = 0.0
var rush: float = 0.0

var wall: float = 0.0
var event: Variant = null
var skins: Array = []
var cleared: Dictionary = {}
var _evAt: float = 0.0
var _evIdx: int = 0
var _evDone: Variant = null
var _questDone: Array = []

var orders: Array = []
var _oid: int = 0
var _hold: Dictionary = {}
var _pestEvents: Array = []
var _guestAcc: Dictionary = {}
var _guestGap: Dictionary = {}
var pest: Variant = null
var _pestAcc: Dictionary = {}
var _pestGap: Dictionary = {}
var _askAcc: float = 0.0

func _init() -> void:
	_tables()
	_qCool = Content.QUEST.first
	for g in Content.GUESTS:
		_guestAcc[g.id] = 0.0

# ── 품목 ──
func is_open(id: String) -> bool: return items.has(id)
func lv(id: String) -> float: return items[id].lv if items.has(id) else 0.0

## 25레벨마다 값이 2배. **판매가**에만 붙는다.
func milestone(id: String) -> float:
	return pow(Content.MILESTONE_MULT, floor(lv(id) / Content.MILESTONE_EVERY))

func _gap(g: Dictionary, rng: Rng) -> float:
	return _wild_gap(g.every, g.get("wild", 0.0), rng)

## wild가 0이면 시계처럼, 1이면 완전히 운. 평균 간격은 어느 쪽이든 every 그대로다.
func _wild_gap(every: float, w: float, rng: Rng) -> float:
	if w <= 0.0:
		return every
	var e: float = -log(1.0 - rng.next() * 0.999)
	return max(every * 0.15, every * (1.0 - w + w * e))

# ── 나쁜 놈들 ──
func pest_kind() -> Variant:
	if pest == null:
		return null
	for p in Content.PESTS:
		if p.id == pest.kind:
			return p
	return null

func _pests(dt: float, rng: Rng) -> void:
	if pest != null:
		pest.left -= dt
		if pest.left <= 0.0:
			_pest_escape(rng)
		return
	for P in Content.PESTS:
		if revenue < P.at:
			continue
		_pestAcc[P.id] = _pestAcc.get(P.id, 0.0) + dt
		if not _pestGap.has(P.id):
			_pestGap[P.id] = _wild_gap(P.every, P.wild, rng)
		if _pestAcc[P.id] < _pestGap[P.id]:
			continue
		_pestAcc[P.id] = 0.0
		_pestGap[P.id] = _wild_gap(P.every, P.wild, rng)
		if pest != null:
			continue
		var born: Variant = _pest_born(P, rng)
		if born == null:
			continue
		pest = born
		_ev("%s %s — 눌러서 잡아라" % [Num.josa(P.name, "이", "가"), born.what], "pest")

func _pest_born(P: Dictionary, rng: Rng) -> Variant:
	if P.steal == "goods":
		var pool: Array = []
		for id in items.keys():
			if items[id].stock > 0.0:
				pool.append(id)
		if pool.is_empty():
			return null
		var item_id: String = pool[int(floor(rng.next() * pool.size()))]
		var qty: float = max(1.0, min(P.max, floor(items[item_id].stock * P.take)))
		return {"kind": P.id, "itemId": item_id, "qty": qty, "left": P.life, "life": P.life,
				"what": "%s에 손을 댔다" % item_name(item_id)}
	var amount: float = floor(income_per_sec() * P.take)
	if amount < 1.0:
		return null
	return {"kind": P.id, "amount": amount, "left": P.life, "life": P.life,
			"what": "엽전 %s닢을 노린다" % Num.fmt(amount)}

# ── 삽살개 ──
func can_buy_guard() -> bool: return not guard and money >= Content.GUARD.cost
func buy_guard() -> bool:
	if not can_buy_guard():
		return false
	money -= Content.GUARD.cost
	guard = true
	_ev("%s을 들였다 — 자리를 비워도 지켜준다" % Content.GUARD.name, "shop")
	return true

func _pest_escape(rng: Rng) -> void:
	var tt: Dictionary = pest
	var P: Dictionary = {}
	for p in Content.PESTS:
		if p.id == tt.kind:
			P = p
	var where: Dictionary = {"kind": tt.kind, "itemId": tt.get("itemId", null)}
	pest = null

	if guard and rng.next() < Content.GUARD.rate:
		var worth: float = (price(tt.itemId) * tt.qty) if P.steal == "goods" else float(tt.amount)
		var gain: float = floor(worth * Content.GUARD.fine)
		money += gain
		revenue += gain
		_ev("%s가 %s 물었다 — 벌금 엽전 %s닢" % [Content.GUARD.name, Num.josa(P.name, "을", "를"), Num.fmt(gain)], "guard")
		var e1: Dictionary = where.duplicate(); e1["result"] = "guard"; e1["amount"] = gain
		_pestEvents.append(e1)
		return
	if P.steal == "goods":
		var has_it: bool = items.has(tt.itemId)
		var n: float = min(items[tt.itemId].stock, tt.qty) if has_it else 0.0
		if has_it:
			items[tt.itemId].stock -= n
		_ev("%s %s %s개를 훔쳐 달아났다" % [Num.josa(P.name, "이", "가"), item_name(tt.itemId), str(int(n))], "pest")
		var e2: Dictionary = where.duplicate(); e2["result"] = "stolen"; e2["amount"] = -floor(price(tt.itemId) * n)
		_pestEvents.append(e2)
	else:
		var n2: float = min(money, tt.amount)
		money -= n2
		_ev("%s 엽전 %s닢을 채 갔다" % [Num.josa(P.name, "이", "가"), Num.fmt(n2)], "pest")
		var e3: Dictionary = where.duplicate(); e3["result"] = "stolen"; e3["amount"] = -n2
		_pestEvents.append(e3)

## 잡았다. 훔치려던 것은 그대로 남고 벌금을 받는다.
func catch_pest(rng: Rng) -> Variant:
	if pest == null:
		return null
	var tt: Dictionary = pest
	var P: Dictionary = {}
	for p in Content.PESTS:
		if p.id == tt.kind:
			P = p
	pest = null
	var worth: float = (price(tt.itemId) * tt.qty) if P.steal == "goods" else float(tt.amount)
	var gain: float = floor(worth * P.fine)
	money += gain
	revenue += gain
	var gem: int = 0
	if rng.next() < Content.GEM.catchRate:
		gem = 1
		gems += 1.0
	_ev("%s 잡았다 — 벌금 엽전 %s닢%s" % [Num.josa(P.name, "을", "를"), Num.fmt(gain), (" · 💎1" if gem > 0 else "")], "catch")
	_event_gain("catch", 1.0)
	return {"kind": tt.kind, "gain": gain, "gem": gem}

# ── 단골 20성 ──
func regular_need(gid: String, i: int) -> float:
	if not _guest_by_id.has(gid):
		return Content.REGULARS[i].at
	return max(1.0, round(Content.REGULARS[i].at / _guest_by_id[gid].every))

func regular_lv(gid: String) -> int:
	var n: float = visits.get(gid, 0.0)
	var out: int = 0
	for i in range(1, Content.REGULARS.size()):
		if n >= regular_need(gid, i):
			out = i
	return out

func regular_name(gid: String) -> String: return Content.REGULARS[regular_lv(gid)].name
func regular_star(gid: String) -> int: return regular_lv(gid) + 1
func regular_sum() -> int:
	var s: int = 0
	for g in guests:
		s += regular_lv(g)
	return s

# ── 직원 ──
func staff_of(shop_id: String) -> float: return staff.get(shop_id, 0.0)
func staff_max(shop_id: String) -> float: return Content.STAFF.max if shops.has(shop_id) else 0.0
func staff_cost(shop_id: String) -> float:
	var shop: Dictionary = shop_by_id(shop_id)
	var n: int = int(staff_of(shop_id))
	var base: float = shop.promote[0] if n == 0 else shop.promote[1]
	return floor(base * Content.STAFF.costMul[n])

func can_hire_staff(shop_id: String) -> bool:
	return shops.has(shop_id) and staff_of(shop_id) < staff_max(shop_id) and money >= staff_cost(shop_id)

func hire_staff(shop_id: String) -> bool:
	if not can_hire_staff(shop_id):
		return false
	money -= staff_cost(shop_id)
	staff[shop_id] = staff_of(shop_id) + 1.0
	_ev("%s에 일손을 들였다 (%s명)" % [shop_by_id(shop_id).name, str(int(staff[shop_id]))], "shop")
	return true

## 매대 칸 수 — 마당 크기가 정한다. 무쇠 4 · 참쇠 6 · 강철 8
func stall_cap(shop_id: String) -> int: return 4 + 2 * min(2, rank_of(shop_id))

func _no_stall(item: Dictionary) -> bool:
	var shop: Dictionary = shop_by_id(item.shop)
	var idx: int = -1
	for k in range(shop.items.size()):
		if shop.items[k].id == item.id:
			idx = k
			break
	return idx >= stall_cap(item.shop)

# ── 가게 등급 ──
func rank_of(shop_id: String) -> int: return int(rank.get(shop_id, 0))
func rank_of_item(id: String) -> int: return rank_of(item_by_id(id).shop)

func item_name(id: String) -> String:
	var it: Dictionary = item_by_id(id)
	return String(shop_by_id(it.shop).ranks[rank_of(it.shop)]) + String(it.name)

func max_lv(id: String) -> float: return Content.RANKS[rank_of_item(id)].maxLv
func at_max(id: String) -> bool: return lv(id) >= max_lv(id)

func price(id: String) -> float:
	var it: Dictionary = item_by_id(id)
	return floor(it.price * Content.RANKS[rank_of_item(id)].priceMul
		* (1.0 + Content.LEVEL.priceStep * (lv(id) - 1.0)) * milestone(id) * haggle())

func craft_time(id: String) -> float:
	var it: Dictionary = item_by_id(id)
	var f: float = max(Content.LEVEL.timeFloor, pow(Content.LEVEL.timeReduce, lv(id) - 1.0))
	return it.time * f * forge_mul()

func cap_of(id: String) -> float:
	return Content.STOCK_CAP + Content.STAFF.capAdd * staff_of(item_by_id(id).shop)

func income_per_sec() -> float:
	var s: float = 0.0
	for id in items.keys():
		s += price(id) / craft_time(id)
	return s

func _step_cost(id: String, at_lv: float) -> float:
	var base: float = max(20.0, item_by_id(id).price * Content.RANKS[rank_of_item(id)].priceMul * 4.0)
	return floor(base * pow(Content.LEVEL.costGrowth, at_lv - 1.0))

func level_cost(id: String) -> float: return _step_cost(id, lv(id))

func level_cost_many(id: String, n: int) -> float:
	var sum: float = 0.0
	var at: float = lv(id)
	for k in range(n):
		sum += _step_cost(id, at + k)
	return sum

func affordable_levels(id: String) -> int:
	if not is_open(id):
		return 0
	var left: float = money
	var n: int = 0
	var at: float = lv(id)
	var room: float = max_lv(id) - at
	while n < min(Content.MAX_BULK, room):
		var c: float = _step_cost(id, at + n)
		if c > left:
			break
		left -= c
		n += 1
	return n

func level_up_many(id: String, want: int) -> int:
	var n: int = int(min(float(want), min(float(affordable_levels(id)), max_lv(id) - lv(id))))
	if n <= 0:
		return 0
	money -= level_cost_many(id, n)
	var before: float = floor(lv(id) / Content.MILESTONE_EVERY)
	items[id].lv += n
	var after: float = floor(lv(id) / Content.MILESTONE_EVERY)
	if after > before:
		_ev("%s %s레벨 — 값이 2배!" % [item_by_id(id).name, str(int(lv(id)))], "milestone")
	_check_max(id)
	return n

func can_open_item(id: String) -> bool:
	return not is_open(id) and asked.has(id) and shops.has(item_by_id(id).shop) \
		and money >= item_by_id(id).cost and not _no_stall(item_by_id(id))

func open_item(id: String) -> bool:
	if not can_open_item(id):
		return false
	money -= item_by_id(id).cost
	items[id] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	_ev("%s 칸을 열었다" % item_by_id(id).name, "open")
	return true

# ── 자동 강화 ──
func can_buy_auto() -> bool: return not auto and money >= Content.AUTO_COST
func buy_auto() -> bool:
	if not can_buy_auto():
		return false
	money -= Content.AUTO_COST
	auto = true
	_ev("장부를 정리했다 — 이제 알아서 강화된다", "shop")
	return true

func _auto_level() -> int:
	if not auto:
		return 0
	var budget: float = min(_purse, money)
	if budget <= 0.0:
		return 0
	var done: int = 0
	while done < Content.AUTO_PER_TICK:
		var best: String = ""
		var best_cost: float = INF
		# 정렬이 아니라 훑어서 고른다 — 같은 값이면 먼저 나온 쪽(넣은 순서)이 이긴다
		for id in items.keys():
			if at_max(id):
				continue
			var c: float = level_cost(id)
			if c < best_cost:
				best_cost = c
				best = id
		if best == "" or best_cost > budget:
			break
		budget -= best_cost
		_purse -= best_cost
		money -= best_cost
		var before: float = floor(lv(best) / Content.MILESTONE_EVERY)
		items[best].lv += 1.0
		if floor(lv(best) / Content.MILESTONE_EVERY) > before:
			_ev("%s %s레벨 — 값이 2배!" % [item_by_id(best).name, str(int(lv(best)))], "milestone")
		_check_max(best)
		done += 1
	return done

# ── 가게 승급 ──
func promote_reqs(shop_id: String) -> Variant:
	var shop: Dictionary = shop_by_id(shop_id)
	var r: int = rank_of(shop_id)
	if r + 1 >= Content.RANKS.size():
		return null
	var next: Dictionary = Content.RANKS[r + 1]
	var have: Array = (shop.items as Array).slice(0, stall_cap(shop_id))
	var all_open: bool = true
	for it in have:
		if not is_open(it.id):
			all_open = false
	var all_max: bool = all_open
	if all_open:
		for it in have:
			if not at_max(it.id):
				all_max = false
	var i: int = -1
	for k in range(Content.SHOPS.size()):
		if Content.SHOPS[k].id == shop_id:
			i = k
	var after: Variant = Content.SHOPS[i + 1] if i + 1 < Content.SHOPS.size() else null
	var ips: float = income_per_sec()
	var cost: float = shop.promote[r]
	var list: Array = []
	list.append({"ok": all_max, "text": "지금 있는 매대 %s칸을 전부 %s레벨까지" % [str(have.size()), str(int(Content.RANKS[r].maxLv))]})
	if after != null:
		list.append({"ok": shops.has(after.id), "text": "%s 열기" % after.name})
	list.append({"ok": regular_sum() >= next.guests, "text": "손님 단골 등급 합계 %s (지금 %s)" % [str(int(next.guests)), str(regular_sum())]})
	list.append({"ok": ips >= next.ips, "text": "초당 🪙%s (지금 🪙%s)" % [Num.fmt(next.ips), Num.fmt(ips)]})
	list.append({"ok": money >= cost, "text": "승급값 🪙%s" % Num.fmt(cost)})
	return {"rank": r + 1, "cost": cost, "list": list}

func can_promote(shop_id: String) -> bool:
	var r: Variant = promote_reqs(shop_id)
	if r == null:
		return false
	for x in r.list:
		if not x.ok:
			return false
	return true

func promote(shop_id: String) -> bool:
	if not can_promote(shop_id):
		return false
	var shop: Dictionary = shop_by_id(shop_id)
	money -= shop.promote[rank_of(shop_id)]
	rank[shop_id] = rank_of(shop_id) + 1
	for it in shop.items:
		if items.has(it.id):
			items[it.id].lv = 1.0
	_ev("%s %s 등급으로 올라섰다" % [Num.josa(shop.name, "이", "가"), shop.ranks[rank_of(shop_id)]], "milestone")
	return true

# ── 가게 ──
func next_shop() -> Variant:
	for s in Content.SHOPS:
		if not shops.has(s.id):
			return s
	return null

func open_shop(id: String) -> bool:
	if not _shop_by_id.has(id):
		return false
	var s: Dictionary = shop_by_id(id)
	if shops.has(id) or money < s.cost:
		return false
	money -= s.cost
	shops.append(id)
	var first: Dictionary = s.items[0]
	items[first.id] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	if not asked.has(first.id):
		asked.append(first.id)
	_ev("%s 다시 문을 열었다" % Num.josa(s.name, "이", "가"), "shop")
	return true

# ── 작은 건물 ──
func can_build_small(i: int) -> bool:
	return i >= 0 and i < Content.SMALL_SHOPS.size() and not smalls.has(i) and money >= Content.SMALL_SHOPS[i].cost

func build_small(i: int) -> bool:
	if not can_build_small(i):
		return false
	money -= Content.SMALL_SHOPS[i].cost
	smalls.append(i)
	_ev("%s 세웠다" % Num.josa(Content.SMALL_SHOPS[i].name, "을", "를"), "shop")
	return true

func next_small() -> int:
	for i in range(Content.SMALL_SHOPS.size()):
		if not smalls.has(i):
			return i
	return -1

func tap_small(idx: int) -> bool:
	if idx != busy:
		return false
	busy = -1
	fair = Content.FAIR.boost
	_ev("장이 섰다 — 손님이 몰린다!", "shop")
	_event_gain("fair", 1.0)
	return true

# ── 젬 강화 ──
func up_lv(id: String) -> float: return gemUp.get(id, 0.0)
func gem_cost(id: String) -> Variant:
	if not _gu.has(id):
		return null
	var u: Dictionary = _gu[id]
	var l: int = int(up_lv(id))
	return null if l >= int(u.max) else u.cost[l]

func can_buy_gem_up(id: String) -> bool:
	var c: Variant = gem_cost(id)
	return c != null and gems >= float(c)

func buy_gem_up(id: String) -> bool:
	if not can_buy_gem_up(id):
		return false
	gems -= float(gem_cost(id))
	gemUp[id] = up_lv(id) + 1.0
	_ev("%s %s단계" % [_gu[id].name, str(int(up_lv(id)))], "gem")
	return true

func haggle() -> float: return 1.0 + _gu.haggle.step * up_lv("haggle")
func forge_mul() -> float: return 1.0 - _gu.forge.step * up_lv("forge")
func serve_pause() -> float: return max(0.2, Content.SERVICE.servePause - _gu.hands.step * up_lv("hands"))

func can_rush() -> bool: return rush <= 0.0 and gems >= Content.GEM.rush.cost
func call_rush() -> bool:
	if not can_rush():
		return false
	gems -= Content.GEM.rush.cost
	rush = Content.GEM.rush.secs
	_ev("삯꾼을 불렀다 — %s초 동안 생산 %s배" % [str(int(Content.GEM.rush.secs)), str(int(Content.GEM.rush.mult))], "gem")
	return true

# ── 기간제 이벤트 ──
func event_def() -> Variant:
	if event == null:
		return null
	for e in Content.EVENTS:
		if e.id == event.id:
			return e
	return null

func event_left() -> float: return max(0.0, event.ends - wall) if event != null else 0.0
func event_wait() -> float: return 0.0 if event != null else max(0.0, _evAt - wall)

func _events(_dt: float) -> void:
	if event != null:
		if wall >= event.ends:
			var e: Dictionary = event_def()
			_ev("%s이(가) 끝났다 — 다음 장을 기다리자" % e.name, "event")
			event = null
			_evAt = wall + Content.EVENT.gapHours * 3600.0
		return
	if shops.size() < int(Content.EVENT.afterShops):
		return
	# 남은 시간을 깎지 않고 **시각**으로 잰다 — 껐던 동안에도 흘러야 한다
	if wall < _evAt:
		return
	var e2: Dictionary = Content.EVENTS[_evIdx % Content.EVENTS.size()]
	_evIdx += 1
	event = {"id": e2.id, "ends": wall + e2.hours * 3600.0, "got": 0.0}
	_ev("%s %s — %s (%s시간)" % [e2.face, e2.name, e2.desc, str(int(e2.hours))], "event")

func _event_gain(kind: String, n: float = 1.0) -> void:
	if event == null:
		return
	var e: Variant = event_def()
	if e == null or e.goal != kind:
		return
	event.got += n
	if event.got < e.need:
		return
	gems += e.gems
	if not skins.has(e.skin):
		skins.append(e.skin)
	cleared[e.id] = cleared.get(e.id, 0.0) + 1.0
	_ev("%s %s을(를) 깼다 — 💎%s · %s" % [e.face, e.name, str(int(e.gems)), e.skinName], "event")
	_evDone = (e as Dictionary).duplicate()
	event = null
	_evAt = wall + Content.EVENT.gapHours * 3600.0

# ── 마을 의뢰 ──
func quest_item_for(gid: String) -> Variant:
	for q in quests:
		if q.gid == gid:
			return q.itemId if items.has(q.itemId) else null
	return null

func quest_rate(gid: String, item_id: String) -> float:
	if not _guest_by_id.has(gid) or not items.has(item_id):
		return 0.0
	var g: Dictionary = _guest_by_id[gid]
	var qty: float = max(1.0, round(g.qty * Content.REGULARS[regular_lv(gid)].qty))
	var sp: float = g.spread if g.get("spread", 0.0) > 0.0 else Content.BASKET_SPREAD
	return max(1.0, ceil(qty / sp)) / g.every

func _round_need(n: float) -> float:
	if n < 20.0: return n
	if n < 100.0: return round(n / 5.0) * 5.0
	if n < 500.0: return round(n / 10.0) * 10.0
	return round(n / 50.0) * 50.0

func _new_quest(rng: Rng) -> Variant:
	var open_ids: Array = items.keys()
	var taken: Array = []
	for q in quests:
		taken.append(q.gid)
	var free: Array = []
	for id in guests:
		if not taken.has(id):
			free.append(id)
	if open_ids.is_empty() or free.is_empty():
		return null
	var gid: String = free[int(floor(rng.next() * free.size()))]
	var item_id: String = open_ids[int(floor(rng.next() * open_ids.size()))]
	var rate: float = quest_rate(gid, item_id)
	if rate <= 0.0:
		return null
	var need: float = max(Content.QUEST.min, _round_need(round(Content.QUEST.seconds * rate)))
	var gm: float = max(1.0, min(Content.QUEST.gemCap, 1.0 + floor(float(regular_lv(gid)) / Content.QUEST.gemPerStar)))
	_qid += 1
	var q2: Dictionary = {"id": _qid, "gid": gid, "itemId": item_id, "need": need, "got": 0.0, "gems": gm, "t": 0.0}
	quests.append(q2)
	_ev("%s마을에서 %s %s개를 청했다" % [_guest_by_id[gid].name, item_name(item_id), str(int(need))], "quest")
	return q2

func _quest_gain(gid: String, item_id: String, n: float) -> void:
	var q: Variant = null
	for x in quests:
		if x.gid == gid and x.itemId == item_id:
			q = x
			break
	if q == null:
		return
	q.got += n
	if q.got < q.need:
		return
	# 고유 번호로 찾아 지운다 — 딕셔너리끼리의 비교는 믿지 않는다
	for k in range(quests.size()):
		if quests[k].id == q.id:
			quests.remove_at(k)
			break
	_qCool = Content.QUEST.every
	var coin: float = floor(price(item_id) * q.need * Content.QUEST.payMul)
	money += coin
	revenue += coin
	if auto:
		_purse += coin * Content.AUTO_SHARE
	gems += q.gems
	_ev("%s마을 의뢰를 마쳤다 — 🪙%s · 💎%s" % [_guest_by_id[gid].name, Num.fmt(coin), str(int(q.gems))], "quest")
	_event_gain("quest", 1.0)
	var d: Dictionary = (q as Dictionary).duplicate()
	d["coin"] = coin
	_questDone.append(d)

## 지금 등급의 만렙에 닿았으면 젬 한 알. 등급이 오르면 다시 한 번 받는다.
func _check_max(id: String) -> void:
	if not at_max(id):
		return
	var key: String = "%s@%d" % [id, rank_of_item(id)]
	if maxGem.has(key):
		return
	maxGem[key] = 1.0
	gems += Content.GEM.onMax
	_ev("%s 만렙 — 💎%s" % [Num.josa(item_name(id), "이", "가"), str(int(Content.GEM.onMax))], "gem")

# ── 한 틱 ──
func tick(dt: float, rng: Rng) -> Dictionary:
	t += dt
	wall += dt
	_events(dt)

	# 0) 장
	if fair > 0.0:
		fair = max(0.0, fair - dt)
	if busy >= 0:
		_busyT -= dt
		if _busyT <= 0.0:
			busy = -1
	elif fair <= 0.0 and not smalls.is_empty():
		_fairAcc += dt
		if _fairAcc >= Content.FAIR.every:
			_fairAcc = 0.0
			busy = smalls[int(floor(rng.next() * smalls.size()))]
			_busyT = Content.FAIR.window

	# 1) 생산
	for k in _hold.keys():
		_hold[k] -= dt
		if _hold[k] <= 0.0:
			_hold.erase(k)
	if rush > 0.0:
		rush = max(0.0, rush - dt)
	var speed: float = Content.GEM.rush.mult if rush > 0.0 else 1.0
	for id in items.keys():
		var st: Dictionary = items[id]
		var shop: String = item_by_id(id).shop
		if staff_of(shop) == 0.0 and _hold.get(shop, 0.0) > 0.0:
			continue
		if st.stock >= cap_of(id) and _order_rem(id) == 0.0:
			continue
		st.prog += dt * speed
		var need: float = craft_time(id)
		while st.prog >= need and (_order_rem(id) > 0.0 or st.stock < cap_of(id)):
			st.prog -= need
			if not _give_to_order(id):
				st.stock += 1.0

	# 1.2) 주문 시계
	var done: Array = []
	if not orders.is_empty():
		var finished: Array = []
		for o in orders:
			o.t += dt
			var all_done: bool = true
			for l in o.lines:
				if l.rem > 0.0:
					all_done = false
			if all_done or o.t >= Content.SERVICE.patience * 2.0:
				finished.append(o)
		for o in finished:
			for k in range(orders.size()):
				if orders[k].id == o.id:
					orders.remove_at(k)
					break
			var g: Dictionary = _guest_by_id.get(o.gid, Content.GUESTS[0])
			done.append(_settle(g, o.lines, o.want, o.grumbles, o.t, o.id))

	# 1.5) 나쁜 놈들
	_pestEvents = []
	_questDone = []
	_pests(dt, rng)

	# 2) 손님
	var sales: Array = []
	for g in Content.GUESTS:
		if not guests.has(g.id):
			continue
		_guestAcc[g.id] += dt * (Content.FAIR.mult if fair > 0.0 else 1.0)
		if not _guestGap.has(g.id):
			_guestGap[g.id] = _gap(g, rng)
		while _guestAcc[g.id] >= _guestGap[g.id]:
			_guestAcc[g.id] -= _guestGap[g.id]
			_guestGap[g.id] = _gap(g, rng)
			var s: Variant = _buy(g, rng)
			if s != null:
				sales.append(s)

	# 3) 자동 강화
	var auto_lv: int = _auto_level()

	# 4) 손님이 없는 물건을 물어본다
	var ask: Variant = null
	_askAcc += dt
	if _askAcc >= Content.ASK_EVERY:
		_askAcc = 0.0
		ask = _ask(rng)

	# 4.5) 마을 의뢰
	for q in quests:
		q.t += dt
	_qCool -= dt
	if _qCool <= 0.0:
		if quests.size() < int(Content.QUEST.slots):
			_new_quest(rng)
		_qCool = Content.QUEST.every

	# 5) 새 손님
	var new_guest: Variant = null
	for g in Content.GUESTS:
		if not guests.has(g.id) and revenue >= g.at:
			guests.append(g.id)
			new_guest = g
			_ev("%s 마을에 왔다" % Num.josa(g.name, "이", "가"), "guest")
			break

	var out: Dictionary = {"sales": sales, "done": done, "ask": ask, "newGuest": new_guest,
		"autoLv": auto_lv, "pests": _pestEvents, "quests": _questDone, "event": _evDone}
	_evDone = null
	return out

func _order_rem(id: String) -> float:
	var s: float = 0.0
	for o in orders:
		for l in o.lines:
			if l.id == id and l.rem > 0.0:
				s += l.rem
	return s

func _give_to_order(id: String) -> bool:
	for o in orders:
		for l in o.lines:
			if l.id == id and l.rem > 0.0:
				l.rem -= 1.0
				return true
	return false

## 손님이 장바구니에 여러 품목을 무작위로 담아간다.
func _buy(g: Dictionary, rng: Rng) -> Variant:
	var have: Array = items.keys()
	if have.is_empty():
		return null

	var reg: Dictionary = Content.REGULARS[regular_lv(g.id)]
	var qty: float = max(1.0, round(g.qty * reg.qty))
	var pay: float = g.pay * reg.pay

	# 무작위로 섞는다 (Fisher-Yates) — JS와 같은 방향, 같은 순서로 돌아야 한다
	var i: int = have.size() - 1
	while i > 0:
		var j: int = int(floor(rng.next() * (i + 1)))
		var tmp: Variant = have[i]
		have[i] = have[j]
		have[j] = tmp
		i -= 1

	# 의뢰를 건 마을은 청한 물건을 맨 먼저 집는다
	var want_q: Variant = quest_item_for(g.id)
	if want_q != null:
		var at: int = have.find(want_q)
		if at > 0:
			have.remove_at(at)
			have.push_front(want_q)

	var sp: float = g.spread if g.get("spread", 0.0) > 0.0 else Content.BASKET_SPREAD
	var per: float = max(1.0, ceil(qty / sp))
	var lines: Array = []
	var grumbles: Array = []
	var left: float = qty

	for id in have:
		if left <= 0.0:
			break
		var st: Dictionary = items[id]
		var want_n: float = min(left, per)
		if want_n <= 0.0:
			continue
		var take: float = min(want_n, st.stock)
		var rem: float = want_n - take

		if rem > 0.0:
			var wait_t: float = (_order_rem(id) + rem) * craft_time(id)
			if wait_t > Content.SERVICE.patience:
				if take > 0.0:
					st.stock -= take
					left -= take
					lines.append({"id": id, "n": take, "rem": 0.0, "unit": price(id) * pay})
				else:
					grumbles.append({"item": item_by_id(id), "n": want_n})
				continue
			st.stock -= take
			left -= want_n
			lines.append({"id": id, "n": want_n, "rem": rem, "unit": price(id) * pay})
			continue
		if take <= 0.0:
			continue
		st.stock -= take
		left -= take
		lines.append({"id": id, "n": take, "rem": 0.0, "unit": price(id) * pay})

	if lines.is_empty():
		if grumbles.is_empty():
			return null
		return {"guest": g, "lines": [], "gain": 0.0, "n": 0.0, "want": qty, "grumbles": grumbles}

	var waiting: bool = false
	for l in lines:
		if l.rem > 0.0:
			waiting = true
	if waiting:
		_oid += 1
		orders.append({"id": _oid, "gid": g.id, "lines": lines, "want": qty, "grumbles": grumbles, "t": 0.0})
		var shown: Array = []
		for l in lines:
			shown.append({"item": item_by_id(l.id), "n": l.n, "gain": floor(l.unit * l.n)})
		return {"guest": g, "orderId": _oid, "waiting": true, "gain": 0.0, "n": 0.0,
				"want": qty, "grumbles": grumbles, "lines": shown}
	return _settle(g, lines, qty, grumbles, 0.0, 0)

## 계산대에서 실제로 돈이 오가는 순간. 즉시 판매든 기다린 주문이든 여기를 지난다.
func _settle(g: Dictionary, lines: Array, want: float, grumbles: Array, waited: float, order_id: int) -> Dictionary:
	var gain: float = 0.0
	var n: float = 0.0
	var out: Array = []
	for l in lines:
		var got: float = l.n - l.get("rem", 0.0)
		if got <= 0.0:
			continue
		var m: float = floor(l.unit * got)
		gain += m
		n += got
		sold += got
		out.append({"item": item_by_id(l.id), "n": got, "gain": m})
	money += gain
	revenue += gain
	if auto:
		_purse += gain * Content.AUTO_SHARE

	for ln in out:
		if staff_of(ln.item.shop) == 0.0:
			_hold[ln.item.shop] = serve_pause()

	for ln in out:
		_quest_gain(g.id, ln.item.id, ln.n)

	if n > 0.0:
		var before: int = regular_lv(g.id)
		bought[g.id] = bought.get(g.id, 0.0) + n
		visits[g.id] = visits.get(g.id, 0.0) + 1.0
		var after: int = regular_lv(g.id)
		if after > before:
			_ev("%s %s성 %s 되었다" % [Num.josa(g.name, "이", "가"), str(after + 1),
				Num.josa(Content.REGULARS[after].name, "이", "가")], "guest")
	return {"guest": g, "lines": out, "gain": gain, "n": n, "want": want,
			"grumbles": grumbles, "waited": waited, "orderId": order_id}

## 아직 안 열린 품목 하나를 물어본다. 이게 다음 목표를 지정한다.
func _ask(rng: Rng) -> Variant:
	for id in asked:
		if not is_open(id):
			return null
	var item: Variant = null
	for i in _all_items:
		if not is_open(i.id) and not asked.has(i.id) and shops.has(i.shop) and not _no_stall(i):
			item = i
			break
	if item == null:
		return null
	var guest: Dictionary = _guest_by_id.get(guests[guests.size() - 1], Content.GUESTS[0])
	asked.append(item.id)
	var line: String = String(Content.ASK_LINES[int(floor(rng.next() * Content.ASK_LINES.size()))]).replace("{item}", item.name)
	_ev("%s: \"%s\"" % [guest.name, line], "ask")
	return {"guest": guest, "item": item, "line": line}

## 오프라인 수익. 껐다 켰을 때 쌓여 있어야 다시 켠다.
func offline(seconds: float) -> Variant:
	# 수익은 4시간까지만 쌓이지만 **이벤트 마감은 그대로 흐른다**
	wall += seconds
	var real: float = min(seconds, Content.OFFLINE.capHours * 3600.0)
	if real < 60.0:
		return null
	var earned: float = floor(income_per_sec() * real * Content.OFFLINE.efficiency)
	money += earned
	revenue += earned
	if auto:
		_purse += earned * Content.AUTO_SHARE
	return {"earned": earned, "seconds": real, "capped": seconds > Content.OFFLINE.capHours * 3600.0}

func _ev(msg: String, kind: String) -> void:
	events.push_front({"t": t, "msg": msg, "kind": kind})
	if events.size() > 40:
		events.resize(40)
