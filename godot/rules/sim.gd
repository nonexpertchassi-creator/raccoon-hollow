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
## 되살린 가게. **처음엔 비어 있다.**
## 예전엔 대장간이 켜진 채로 시작했는데, 그러면 '가게를 연다'는 이 게임의
## 첫 동작을 아무도 해 보지 않는다 — 제일 좋은 첫 순간을 코드가 미리
## 써 버리는 셈이다. 대장간은 값이 0이라 켜자마자 누르면 열린다.
var shops: Array = []
## 열린 구역. 마을은 골목으로 나뉜 덩어리(구역)로 열린다 — 닫힌 동네가
## 안개 너머로 보이고, 조건(성 합계·엽전)을 채우면 통째로 열린다.
## 첫 구역(안골)은 처음부터 열려 있다.
var zones: Array = ["angol"]
var rank: Dictionary = {}
## 열린 품목. **처음엔 비어 있다** — 가게가 하나도 없으니 팔 것도 없다.
## 예전엔 곡괭이가 열린 채로 시작했는데, 대장간을 잠그고 나니
## '가게는 없는데 곡괭이는 팔린다'가 됐다. 가게를 열면 그때 들어온다.
var items: Dictionary = {}
## 가게마다의 **작업대 단수**(1~8). 가게id → 몇 단까지 세웠나.
##
## ★ 2026-08-29에 '매대 칸'을 여기로 갈아 끼웠다(유저). 왜:
##   - 이름이 틀렸었다. 물건은 매대에서 팔린 적이 없다 — **파는 곳은 계산대**고,
##     매대에서 하는 일은 만드는 것뿐이었다. 그러니 작업대가 맞는 이름이다.
##   - 열리는 방식이 어긋나 있었다. 예전엔 **손님이 물어봐야** 그 물건 칸을
##     살 수 있었다. 손님이 오는 것은 이야기가 할 일이지 물건 잠금이 할 일이
##     아니다(STORY.md의 축). 이제 작업대는 **돈만 내면** 한 단 오른다.
##   - 두 축이 갈린다: **작업대 단 = 무엇을 만들 줄 아나**,
##     **일꾼 수 = 한 번에 몇 개를 만드나.** 서로 다른 것을 사게 된다.
##   물건 값·차례·등급 상한(4·6·8)은 하나도 안 건드렸다 — 이름과 여는 방법만 바뀐다.
var bench: Dictionary = {}
## 마을에 온 손님. **이제 뽑기로만 늘어난다** — 카드를 처음 뽑으면 그때 온다.
## 토끼 하나로 시작한다(첫 카드를 뽑기 전에도 장사는 돼야 하니까).
var guests: Array = ["rabbit"]
## 손님별 **가진 카드 장수**. 성을 올릴 때 쓰고 줄어든다.
var cards: Dictionary = {"rabbit": 0.0}
## 손님별 **성(星)**. 0이 1성, 19가 20성이다.
## 예전에는 방문 횟수로 저절로 올랐는데, 이제 **카드를 모아 눌러서** 올린다.
var stars: Dictionary = {}
## 여태 뽑은 총 횟수. 뽑기 레벨이 여기서 나온다.
var pulls: float = 0.0

## ── 세는 것 ──
##
## ★ 규칙에 **한 번도 안 쓰인다.** 오직 더하기만 하고 아무것도 읽어서
##   판단하지 않는다. 그래야 계측을 넣거나 빼도 같은 게임이다.
##   무엇을 왜 세는지는 METRICS.md에 있다.
##
## 처음이 빈 사전인 이유: 세는 칸이 늘어도 옛 저장본은 그 칸이 없다.
## 없으면 0으로 시작해야 하고, 빈 사전이면 그게 저절로 된다.
var stats: Dictionary = {}
## 프로필 — 별명·얼굴(뽑은 손님 얼굴만)·띠(단골 칭호). 머리띠(HUD)가 읽는다.
## face가 ""이면 기본 너구리, band가 -1이면 지금 딴 제일 높은 칭호를 쓴다.
var profile: Dictionary = {"name": "너구리", "face": "", "band": -1}
## 일꾼 무늬 — 가게마다 벌거벗은 본체 무늬(a~d)를 **저장본마다 한 번** 배정한다.
## 재실행·승급에 다시 추첨하지 않는다(유저 규칙). 화면과 카드가 같이 읽는다.
const FURS := ["a", "b", "c", "d"]
var furs: Dictionary = {}

func bump(key: String, by: float = 1.0) -> void:
	stats[key] = float(stats.get(key, 0.0)) + by
var bought: Dictionary = {}
var visits: Dictionary = {}
var sold: float = 0.0
var auto: bool = false
var smalls: Array = []
## 삽살개 **마리 수**. 예전에는 있다/없다(참·거짓)였다.
## 가게가 늘면 도둑도 느니 여러 마리를 둘 수 있어야 한다.
var guards: float = 0.0
## 옛 저장본 호환용. 참이면 한 마리로 친다(load_from에서 옮긴다).
var guard: bool = false
var staff: Dictionary = {}
## 이야기에서 **이미 지나간 마디**들. 한 마디는 한 번만 나온다.
##
## ★ 왜 화면이 아니라 여기 있나. 저장본에 남아야 하기 때문이다 — 껐다 켤 때마다
##   "왔구나"가 다시 뜨면 그건 이야기가 아니라 잔소리다. sim은 이 게임에서
##   유일하게 **기억하는 곳**이라 여기 둔다. 돈은 한 푼도 안 건드린다.
var story: Dictionary = {}

## 그 마디가 **처음인가.** 처음이면 참을 돌려주고 그 자리에서 지나간 것으로 적는다.
## 화면은 이 값만 보고 쪽지를 붙일지 정한다.
func story_fire(id: String) -> bool:
	if story.has(id):
		return false
	story[id] = true
	bump("story." + id)
	return true

## 길에 떨어져 있는 쓰레기 **개수**. 자리는 화면이 정하고, 개수는 여기가 정한다 —
## 그래야 게임을 껐다 켜도 쌓인 만큼 그대로 있다.
var trash: float = 0.0
var _trashAcc: float = 0.0
## 장터 청소부 **사람 수**. 있으면 자리를 비워도 대신 줍는다.
var sweepers: float = 0.0
var _sweepAcc: float = 0.0
var fair: float = 0.0
var busy: int = -1
var _busyT: float = 0.0
var _fairAcc: float = 0.0
var _purse: float = 0.0
var events: Array = []

var quests: Array = []
## 시작 나뭇잎 3개 — 1회 뽑기가 🍃1이라, 켜자마자 **뽑기 → 새 손님이 걸어
## 들어오는 순간**을 3분 안에 겪게 한다. 0으로 시작했더니 처음 3분 동안
## 나뭇잎을 얻을 길이 없어서 이 게임의 심장(뽑기)을 못 만났다(실측).
var gems: float = 3.0
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
## 이번 틱에 실제로 만들어지고 있는 물건들 — 화면이 로딩 파이를 그리는 데 쓴다.
## 저장 안 한다(매 틱 다시 채워진다).
var _crafting: Dictionary = {}
## 손이 작업대로 걸어가는 중인 물건(id → 남은 초). CRAFT.walk 참고.
var _switch: Dictionary = {}
## 마지막으로 손을 댄 지 얼마나 됐나(id → 초). regrip 유예 판정용.
var _recent: Dictionary = {}
## 이번 틱에 "도착했더니 자리가 차서" 지나간 주문 번호들 — 화면에 알린다.
var _passed: Array = []
## 승급 공사 중인 가게(가게id → 남은 초). 2026-08-27, 유저.
## 승급이 누르는 순간 끝나면 무게가 없다 — 기다림이 값을 만든다.
## **공사 중에도 장사는 그대로 돈다**(멈추면 승급이 벌이 된다 — 4번 규칙).
var building: Dictionary = {}
## 이번 틱에 공사가 끝난 가게들 — 화면이 카드를 띄우려고 본다.
var _built: Array = []
## 날씨 — content.js의 WEATHER.kinds 중 하나. 손님 발길·손놀림·쥐가 탄다.
var weather: String = "clear"
var _wxT: float = 0.0
var _pestEvents: Array = []
var _guestAcc: Dictionary = {}
var _guestGap: Dictionary = {}
var pest: Variant = null
var _pestAcc: Dictionary = {}
var _pestGap: Dictionary = {}
## 이번 틱의 주사위. _settle은 rng를 안 받는데 '약재 말리기'가 필요해서
## 여기 담아 둔다. _settle은 언제나 틱 안에서만 불리므로 늘 이번 것이 맞다.
var _rng: Rng = null

## ── 장날 소식 ──
## 하루치씩 담는다: [{ "day": 3, "sales": { "rabbit>hoe": 12.0, … } }]
## 누적 총계로 세면 처음 연 품목이 영원히 1등이라 순위가 굳는다.
## 기간으로 세야 매번 새 소식이 된다(content.gd의 LEDGER 참고).
var ledger: Array = []

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
	# 성이 오르면 발걸음도 잦아진다 — content.js의 REGULAR_COME 참고
	# 밤엔 발길이 뜸하다(DAY.nightCome) — 짐승도 잘 시간이다. 날씨도 탄다.
	return _wild_gap(g.every / (1.0 + Content.REGULAR_COME * regular_lv(String(g.id)))
		* (Content.DAY.nightCome if is_night() else 1.0) / weather_come() / _wx_of(g),
		g.get("wild", 0.0), rng)

## 짐승마다 좋아하는 날씨 — 개구리는 비 오는 날 1.8배로 자주 온다(2026-08-27).
## ★ 도감에 "비 오는 날이면 더 자주 온다"고 적어 놓고 규칙에는 없었다.
##   글이 약속한 것을 규칙이 안 지키면 그 도감은 거짓말이 된다.
func _wx_of(g: Dictionary) -> float:
	if String(g.get("wx", "")) == "" or String(g.wx) != String(weather_def().id):
		return 1.0
	return float(g.get("wxMul", 1.0))

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
		# 밤엔 쥐가 설친다(DAY.nightPest), 비 오면 뜸하다(WEATHER.pest)
		_pestAcc[P.id] = _pestAcc.get(P.id, 0.0) \
			+ dt / (Content.DAY.nightPest if is_night() else 1.0) / float(weather_def().pest)
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
			"what": "엽전 %s냥을 노린다" % Num.fmt(amount)}

# ── 삽살개 ──
## 삽살개 값 — 마리마다 오른다. 두 번째부터는 첫 마리의 2.2배씩.
func guard_cost() -> float:
	return floor(Content.GUARD.cost * pow(Content.GUARD.costMul, guards))

func guard_max() -> int:
	# 가게 넷마다 한 마리. 가게가 하나뿐인데 개가 셋이면 우스꽝스럽다.
	return max(1, int(ceil(float(shops.size()) / Content.GUARD.perShops)))

## 나쁜 놈을 무는 확률. 마리가 늘수록 오르되 **덜 오른다** —
## 그냥 곱하면 세 마리에 180%가 되어 나쁜 놈이 아예 없는 게임이 된다.
## 남는 몫(1 − rate)을 마리마다 갉아먹는 식이라 100%를 절대 안 넘는다.
func guard_rate() -> float:
	if guards <= 0.0:
		return 0.0
	return min(float(Content.GUARD.rateCap), 1.0 - pow(1.0 - Content.GUARD.rate, guards))

func can_buy_guard() -> bool:
	return guards < float(guard_max()) and money >= guard_cost()
func buy_guard() -> bool:
	if not can_buy_guard():
		return false
	money -= guard_cost()
	bump("open.guard")
	guards += 1.0
	guard = true
	_ev("%s을 들였다 — 자리를 비워도 지켜준다" % Content.GUARD.name, "shop")
	return true

# ── 쓰레기와 장터 청소부 ──
## ★ 여기에는 **주사위가 한 번도 안 나온다.** 그래서 청소부를 안 산 판은
##   난수 순서가 한 칸도 안 밀린다 — 옛 저장본이 그대로 돈다.
##
## ★ 나오는 것은 **엽전이 아니라 나뭇잎**이다(2026-08-28, 유저).
##   엽전이면 매출 곡선에 곱셈으로 얹혀서 밸런스가 통째로 흔들린다.
##   나뭇잎은 뽑기 쪽으로만 흘러서 **잰 것을 다시 안 재도 된다.**
##   이게 새 것을 붙일 때 제일 싼 자리다.

## 손으로 줍는다. 청소부가 줍는 것보다 더 준다 — 직접 하는 보람.
func tap_trash() -> bool:
	if trash < 1.0:
		return false
	trash -= 1.0
	bump("tap.trash")
	var leaf: float = float(Content.TRASH.handLeaf)
	gems += leaf
	_ev("길에 떨어진 것을 주웠다 — 🍃%d" % int(leaf), "shop")
	return true

func sweeper_cost() -> float:
	return floor(Content.SWEEPER.cost)

func sweeper_max() -> int:
	return int(Content.SWEEPER.max)

func can_buy_sweeper() -> bool:
	return sweepers < float(sweeper_max()) and money >= sweeper_cost()

func buy_sweeper() -> bool:
	if not can_buy_sweeper():
		return false
	money -= sweeper_cost()
	bump("open.sweeper")
	sweepers += 1.0
	_ev("%s를 들였다 — 자리를 비워도 길을 쓴다" % Content.SWEEPER.name, "shop")
	return true

## 한 틱치 쓰레기 — 떨어지고, 청소부가 줍는다.
func _trash_tick(dt: float) -> void:
	_trashAcc += dt
	while _trashAcc >= float(Content.TRASH.every):
		_trashAcc -= float(Content.TRASH.every)
		trash = min(float(Content.TRASH.max), trash + 1.0)
	if sweepers <= 0.0:
		return
	_sweepAcc += dt * sweepers
	while _sweepAcc >= float(Content.SWEEPER.picks):
		_sweepAcc -= float(Content.SWEEPER.picks)
		if trash < 1.0:
			_sweepAcc = 0.0
			break
		trash -= 1.0
		gems += float(Content.TRASH.sweepLeaf)

func _pest_escape(rng: Rng) -> void:
	var tt: Dictionary = pest
	var P: Dictionary = {}
	for p in Content.PESTS:
		if p.id == tt.kind:
			P = p
	var where: Dictionary = {"kind": tt.kind, "itemId": tt.get("itemId", null)}
	pest = null

	if guards > 0.0 and rng.next() < guard_rate():
		var worth: float = (price(tt.itemId) * tt.qty) if P.steal == "goods" else float(tt.amount)
		var gain: float = floor(worth * Content.GUARD.fine)
		money += gain
		revenue += gain
		_ev("%s가 %s 물었다 — 벌금 엽전 %s냥" % [Content.GUARD.name, Num.josa(P.name, "을", "를"), Num.fmt(gain)], "guard")
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
		_ev("%s 엽전 %s냥을 채 갔다" % [Num.josa(P.name, "이", "가"), Num.fmt(n2)], "pest")
		var e3: Dictionary = where.duplicate(); e3["result"] = "stolen"; e3["amount"] = -n2
		_pestEvents.append(e3)

## 잡았다. 훔치려던 것은 그대로 남고 벌금을 받는다.
func catch_pest(rng: Rng) -> Variant:
	if pest == null:
		return null
	bump("tap.pest")
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
	_ev("%s 잡았다 — 벌금 엽전 %s냥%s" % [Num.josa(P.name, "을", "를"), Num.fmt(gain), (" · 🍃1" if gem > 0 else "")], "catch")
	_event_gain("catch", 1.0)
	return {"kind": tt.kind, "gain": gain, "gem": gem}

# ── 단골 20성 ──
## 다음 성까지 필요한 **카드 장수**. (예전에는 방문 횟수였다)
func star_need(gid: String) -> Variant:
	var lv: int = regular_lv(gid)
	if lv >= Content.STAR_CARDS.size():
		return null                      # 20성 — 더 오를 곳이 없다
	return Content.STAR_CARDS[lv]

func can_star_up(gid: String) -> bool:
	var need: Variant = star_need(gid)
	return need != null and cards.get(gid, 0.0) >= float(need)

## 카드를 써서 한 성 올린다. **눌러서 올린다** — 저절로 오르면
## "왜 올랐지"가 되고, 모으는 재미도 사라진다.
func star_up(gid: String) -> bool:
	if not can_star_up(gid):
		return false
	bump("star.up")
	cards[gid] = cards.get(gid, 0.0) - float(star_need(gid))
	stars[gid] = float(regular_lv(gid) + 1)
	_ev("%s %d성이 되었다" % [_guest_by_id[gid].name, regular_star(gid)], "guest")
	return true

func regular_need_old(gid: String, i: int) -> float:
	if not _guest_by_id.has(gid):
		return Content.REGULARS[i].at
	return max(1.0, round(Content.REGULARS[i].at / _guest_by_id[gid].every))

## 지금 몇 성인가(0 = 1성). 카드로 올린 값만 본다.
func regular_lv(gid: String) -> int:
	return int(stars.get(gid, 0.0))

func regular_lv_old(gid: String) -> int:
	var n: float = visits.get(gid, 0.0)
	var out: int = 0
	for i in range(1, Content.REGULARS.size()):
		if n >= regular_need_old(gid, i):
			out = i
	return out

## 딸 수 있는 제일 높은 띠(칭호) — 손님들 중 제일 높은 성이 곧 자격이다.
func band_max() -> int:
	var m: int = 0
	for g in guests:
		m = max(m, regular_lv(String(g)))
	return m

## 지금 두른 띠. 고른 적 없으면(-1) 제일 높은 것을 쓴다.
func band_of() -> int:
	var b: int = int(profile.get("band", -1))
	if b >= 0 and b <= band_max():
		return b
	return band_max()

## 프로필 고치기 — null인 칸은 안 건드린다. 얼굴은 **뽑은 손님만** 된다.
func set_profile(nm: Variant = null, face: Variant = null, band: Variant = null) -> void:
	if nm != null:
		var t: String = String(nm).strip_edges().left(10)
		if t != "":
			profile.name = t
	if face != null and (String(face) == "" or guests.has(String(face))):
		profile.face = String(face)
	if band != null and int(band) >= -1 and int(band) <= band_max():
		profile.band = int(band)
	bump("profile.set")

func regular_name(gid: String) -> String: return Content.REGULARS[regular_lv(gid)].name
func regular_star(gid: String) -> int: return regular_lv(gid) + 1
func regular_sum() -> int:
	var s: int = 0
	for g in guests:
		s += regular_lv(g)
	return s

## 이 가게에 **지금 들어가서 할 일**이 몇 개인가.
## 들어갈 이유가 없으면 안 들어가게 하는 것 — 표가 그 역할이다.
## 강화는 안 센다. 늘 할 수 있어서 표가 항상 켜져 있게 되고,
## 항상 켜진 표는 없는 것과 같다.
func shop_todo(shop_id: String) -> int:
	if not _shop_by_id.has(shop_id) or not shops.has(shop_id):
		return 0
	var n: int = 0
	if can_bench_up(shop_id):
		n += 1
	if can_promote(shop_id):
		n += 1
	if can_hire_staff(shop_id):
		n += 1
	return n

# ── 일꾼 너구리 ──
## 채용 부활(2026-08-26, 유저): **승급이 채용 자리를 연다.** 오픈 1마리 +
## 등급마다 자리 하나(무쇠 1·참쇠 2·강철 3) = 최대 4마리. 돈 내고 채용한다.
func staff_of(shop_id: String) -> float: return staff.get(shop_id, 0.0)
func staff_max(shop_id: String) -> float:
	return float(rank_of(shop_id) + 1) if shops.has(shop_id) else 0.0

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
	bump("open.staff")
	staff[shop_id] = staff_of(shop_id) + 1.0
	_deal_fur("%s:%d" % [shop_id, int(staff[shop_id])])
	_ev("%s에 너구리가 왔다 (%s마리)" % [shop_by_id(shop_id).name, str(int(staff[shop_id]) + 1)], "shop")
	return true

## 작업대를 몇 단까지 세울 수 있나 — 마당 크기가 정한다. 무쇠 4 · 참쇠 6 · 강철 8
## (예전 '매대 칸 수'와 같은 식이다. 승급이 상한을 올려 준다.)
func bench_cap(shop_id: String) -> int:
	return min(4 + 2 * min(2, rank_of(shop_id)), shop_by_id(shop_id).items.size())

## 지금 몇 단인가. 가게를 열면 1단(첫 물건)부터다.
func bench_lv(shop_id: String) -> int:
	return int(bench.get(shop_id, 1.0)) if shops.has(shop_id) else 0

## 다음 단에서 만들 줄 알게 되는 물건. 더 못 올리면 null.
func bench_next(shop_id: String) -> Variant:
	var n: int = bench_lv(shop_id)
	if n <= 0 or n >= bench_cap(shop_id):
		return null
	return shop_by_id(shop_id).items[n]

## 다음 단 값 — **예전 '칸 여는 값' 그대로**다. 값 곡선을 안 건드렸다.
func bench_cost(shop_id: String) -> float:
	var nx: Variant = bench_next(shop_id)
	return float(nx.cost) if nx != null else 0.0

func can_bench_up(shop_id: String) -> bool:
	var nx: Variant = bench_next(shop_id)
	return nx != null and money >= float(nx.cost)

func bench_up(shop_id: String) -> bool:
	if not can_bench_up(shop_id):
		return false
	var nx: Dictionary = bench_next(shop_id)
	money -= float(nx.cost)
	bench[shop_id] = float(bench_lv(shop_id) + 1)
	items[nx.id] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	bump("open.item")
	_ev("%s 작업대 %d단 — %s를 만들 줄 알게 됐다"
		% [shop_by_id(shop_id).name, bench_lv(shop_id), nx.name], "open")
	return true

# ── 가게마다의 고유 강화 ──
#
# ★ **가게 고유 강화를 뺐다**(2026-08-28, 유저).
#   축("이게 손님이 돌아오는 걸 느끼게 하나?")으로 재니 ✕였다 — 숫자만 올렸다.
#   게다가 다섯 중 셋은 운 번호 다섯으로 재 보니 **사면 손해**였다
#   (의뢰방 0.99배 · 약재 말리기 0.88배 · 질그릇 한 벌 0.82배).
#   "파는 물건이 사는 사람을 손해 보게 만들면 안 된다"는 넷째 규칙에 걸렸는데,
#   고쳐서 살리는 것보다 **없는 게 나았다.** 되살리려면 이 커밋을 되돌린다.

## 계산대 수 — 등급이 정한다(무쇠 1 · 참쇠 2 · 강철 3). 승급 보상 하나 더(2026-08-26).
func counters_of(shop_id: String) -> int:
	return rank_of(shop_id) + 1

## 동시에 받아 둘 수 있는 주문 수 — 계산대 수 + 1(걸어오는 손님 몫).
## 측정의 역사: ×2는 1.9B 과열 → ×1은 도착 시간(eta) 도입 뒤 373M로
## 질식(걸어오는 내내 자리를 물고 있어서) → +1이 숨통이다.
func order_slots(shop_id: String) -> int:
	return counters_of(shop_id) + 1

## 도착해서 줄에 선 주문만 센다 — 자리 규칙(2026-08-27)의 기준.
func arrived_orders_of(shop_id: String) -> int:
	var n: int = 0
	for o in orders:
		if float(o.get("eta", 0.0)) > 0.0:
			continue
		if not (o.lines as Array).is_empty() \
				and String(item_by_id(String(o.lines[0].id)).shop) == shop_id:
			n += 1
	return n

func orders_of(shop_id: String) -> int:
	var n: int = 0
	for o in orders:
		if not (o.lines as Array).is_empty() \
				and String(item_by_id(String(o.lines[0].id)).shop) == shop_id:
			n += 1
	return n

## 지금 날씨의 발길 배수 — **비 올 때만** 스킬이 덜어 준다(이름 그대로).
func weather_come() -> float:
	var c: float = float(weather_def().come)
	return minf(1.0, c + skill("rainy")) if String(weather_def().id) == "rain" else c

## 동시에 걸리는 의뢰 자리 — 기본값 + 나뭇잎 스킬로 늘린 만큼.
func quest_slots() -> int:
	return int(Content.QUEST.slots) + int(up_lv("questslot"))

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
		* (1.0 + Content.LEVEL.priceStep * (lv(id) - 1.0)) * milestone(id) * haggle()
		)

## 하루 어디쯤인가(0~1). 화면의 어둠과 경제의 밤 규칙이 **같은 시계**를 본다.
func day_phase() -> float:
	return fposmod(t, float(Content.DAY.cycle)) / float(Content.DAY.cycle)

func weather_def() -> Dictionary:
	for k in Content.WEATHER.kinds:
		if String(k.id) == weather:
			return k
	return Content.WEATHER.kinds[0]

func is_night() -> bool:
	var ph: float = day_phase()
	return ph >= float(Content.DAY.night[0]) and ph < float(Content.DAY.night[1])

func craft_time(id: String) -> float:
	var it: Dictionary = item_by_id(id)
	var f: float = max(Content.LEVEL.timeFloor, pow(Content.LEVEL.timeReduce, lv(id) - 1.0))
	# handSpeed — 손 하나의 손놀림 배수(생산 개편 보정, content.js의 CRAFT 참고)
	# 밤엔 손이 느리다(DAY.nightCraft) — 밤 규칙은 화면이 아니라 여기(sim)의 것이다
	return it.time * f * forge_mul() / Content.CRAFT.handSpeed 		* (night_craft() if is_night() else 1.0) * float(weather_def().craft)

func cap_of(id: String) -> float:
	return Content.STOCK_CAP + Content.STAFF.capAdd * staff_of(item_by_id(id).shop)

## 초당 수입 어림. 손이 물건보다 적으면 그만큼 깎아 센다 —
## 생산이 손 수에 묶였으니(위 개편) 어림도 같이 묶여야 승급 문턱이 거짓말을 안 한다.
func income_per_sec() -> float:
	var s: float = 0.0
	for sh in shops:
		var hands: int = 1 + int(staff_of(String(sh)))
		var ids: Array = []
		for it in shop_by_id(String(sh)).items:
			if items.has(String(it.id)):
				ids.append(String(it.id))
		if ids.is_empty():
			continue
		var mul: float = minf(1.0, float(hands) / float(ids.size()))
		for id in ids:
			s += price(id) / craft_time(id) * mul
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

## want가 1이면 '한 번 눌렀다', 여럿이면 '최대로 올렸다'로 센다.
func level_up_many(id: String, want: int) -> int:
	var n: int = int(min(float(want), min(float(affordable_levels(id)), max_lv(id) - lv(id))))
	if n <= 0:
		return 0
	money -= level_cost_many(id, n)
	# 한 번 눌러 한 단계인지, '최대'로 한꺼번에인지를 갈라 센다 —
	# 꾹 누르기와 최대 단추가 쓸모 있나를 이 둘의 비로 본다.
	bump("tap.level" if n == 1 else "tap.levelMany")
	var before: float = floor(lv(id) / Content.MILESTONE_EVERY)
	items[id].lv += n
	var after: float = floor(lv(id) / Content.MILESTONE_EVERY)
	if after > before:
		_ev("%s %s레벨 — 값이 2배!" % [item_by_id(id).name, str(int(lv(id)))], "milestone")
	_check_max(id)
	return n

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
	var have: Array = (shop.items as Array).slice(0, bench_cap(shop_id))
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
	list.append({"ok": all_max, "text": "작업대 %s단을 다 세우고 전부 %s레벨까지" % [str(have.size()), str(int(Content.RANKS[r].maxLv))]})
	if after != null:
		list.append({"ok": shops.has(after.id), "text": "%s 열기" % after.name})
	list.append({"ok": regular_sum() >= next.guests, "text": "손님 단골 등급 합계 %s (지금 %s)" % [str(int(next.guests)), str(regular_sum())]})
	list.append({"ok": ips >= next.ips, "text": "초당 🪙%s (지금 🪙%s)" % [Num.fmt(next.ips), Num.fmt(ips)]})
	list.append({"ok": money >= cost, "text": "승급값 🪙%s" % Num.fmt(cost)})
	return {"rank": r + 1, "cost": cost, "list": list}

## 승급하면 이 가게가 어떻게 되나. **화면이 보여주려고 묻는 것**이라
## 상태를 바꾸지 않는다(잠깐 바꿔 재고 그대로 되돌린다).
##
## ★ 값 계산을 여기서 다시 쓰지 않는 이유: 베낀 식은 반드시 뒤처진다.
##   값 규칙을 고치면 이 미리보기만 조용히 옛말을 하게 된다.
##   그래서 진짜 price()·craft_time()에게 물어본다.
func promote_gain(shop_id: String) -> Variant:
	var r: int = rank_of(shop_id)
	if r + 1 >= Content.RANKS.size():
		return null
	var shop: Dictionary = shop_by_id(shop_id)
	var id: String = ""
	for it in shop.items:
		if is_open(it.id):
			id = String(it.id)
			break
	var out: Dictionary = {
		"rank": r + 1,
		"priceMul": Content.RANKS[r + 1].priceMul / Content.RANKS[r].priceMul,
		"maxLv": [Content.RANKS[r].maxLv, Content.RANKS[r + 1].maxLv],
		"bench": [bench_cap(shop_id), min(4 + 2 * min(2, r + 1), shop.items.size())],
		"staff": [staff_of(shop_id), min(staff_of(shop_id) + 1.0, Content.STAFF.max)],
		"dip": 1.0, "even": 1, "top": 1.0,
	}
	if id == "":
		return out
	var keep_lv: float = lv(id)
	var had_rank: bool = rank.has(shop_id)      # 없던 칸을 만들어 놓고 가면 저장본이 달라진다
	var before: float = price(id) / craft_time(id)
	rank[shop_id] = r + 1
	items[id].lv = 1.0
	out.dip = (price(id) / craft_time(id)) / before
	for l in range(1, int(max_lv(id)) + 1):
		items[id].lv = float(l)
		out.even = l
		if price(id) / craft_time(id) >= before:
			break
	items[id].lv = max_lv(id)
	out.top = (price(id) / craft_time(id)) / before
	items[id].lv = keep_lv        # 재 봤으면 도로 갖다 놓는다
	if had_rank:
		rank[shop_id] = r
	else:
		rank.erase(shop_id)
	return out

func can_promote(shop_id: String) -> bool:
	if is_building(shop_id):
		return false                 # 이미 공사 중이다
	var r: Variant = promote_reqs(shop_id)
	if r == null:
		return false
	for x in r.list:
		if not x.ok:
			return false
	return true

## 이 가게가 지금 공사 중인가 / 얼마나 남았나.
func is_building(shop_id: String) -> bool:
	return float(building.get(shop_id, 0.0)) > 0.0

func build_left(shop_id: String) -> float:
	return max(0.0, float(building.get(shop_id, 0.0)))

## 남은 공사를 나뭇잎으로 당기는 값 — 30분에 한 장.
func rush_build_cost(shop_id: String) -> int:
	return int(ceil(build_left(shop_id) / Content.BUILD_RUSH_PER))

func can_rush_build(shop_id: String) -> bool:
	return is_building(shop_id) and gems >= float(rush_build_cost(shop_id))

func rush_build(shop_id: String) -> bool:
	if not can_rush_build(shop_id):
		return false
	gems -= float(rush_build_cost(shop_id))
	bump("build.rush")
	building[shop_id] = 0.0
	_promote_done(shop_id)
	return true

## 승급값을 내고 **공사를 시작한다.** 오르는 것은 공사가 끝나야 한다.
func promote(shop_id: String) -> bool:
	if not can_promote(shop_id):
		return false
	var shop: Dictionary = shop_by_id(shop_id)
	money -= shop.promote[rank_of(shop_id)]
	bump("open.promote")
	var secs: float = float(Content.RANKS[rank_of(shop_id) + 1].build)
	if secs > 0.0:
		building[shop_id] = secs
		_ev("%s 승급 공사를 시작했다 — %s" % [shop.name, Num.dur(secs)], "milestone")
		return true
	_promote_done(shop_id)
	return true

## 공사가 끝났다 — 여기서야 등급이 오른다.
func _promote_done(shop_id: String) -> void:
	building.erase(shop_id)
	_built.append(shop_id)          # 화면에 알린다 — 카드는 공사가 끝날 때 뜬다
	var shop: Dictionary = shop_by_id(shop_id)
	rank[shop_id] = rank_of(shop_id) + 1
	# 승급은 너구리를 주지 않는다 — **채용 자리를 하나 연다**(2026-08-26).
	for it in shop.items:
		if items.has(it.id):
			items[it.id].lv = 1.0
	_ev("%s %s 등급으로 올라섰다" % [Num.josa(shop.name, "이", "가"), shop.ranks[rank_of(shop_id)]], "milestone")

# ── 가게 ──
# ── 구역 ──
func district_of(shop_id: String) -> Variant:
	for d in Content.DISTRICTS:
		if (d.shops as Array).has(shop_id):
			return d
	return null

## 이 가게가 있는 구역이 열렸나. 목록에 없는 가게는 열린 것으로 친다 —
## 나중에 가게를 더 넣고 구역 목록을 깜빡해도 게임이 잠기지는 않게.
func district_open(shop_id: String) -> bool:
	var d: Variant = district_of(shop_id)
	return d == null or zones.has(String(d.id))

## 구역을 여는 조건. 승급 조건과 같은 모양(list of {ok, text})으로 돌려준다 —
## 화면이 체크리스트 하나로 둘 다 그린다.
func district_reqs(id: String) -> Variant:
	for d in Content.DISTRICTS:
		if d.id != id:
			continue
		if zones.has(id):
			return null
		var list: Array = []
		list.append({"ok": regular_sum() >= d.stars,
			"text": "손님 성 합계 %s (지금 %s)" % [str(int(d.stars)), str(regular_sum())]})
		list.append({"ok": money >= d.cost, "text": "🪙%s" % Num.fmt(d.cost)})
		return {"district": d, "list": list}
	return null

func can_unlock_district(id: String) -> bool:
	var r: Variant = district_reqs(id)
	if r == null:
		return false
	for x in r.list:
		if not x.ok:
			return false
	return true

func unlock_district(id: String) -> bool:
	if not can_unlock_district(id):
		return false
	var dd: Dictionary = (district_reqs(id) as Dictionary).district
	money -= dd.cost
	zones.append(id)
	bump("open.district")
	_ev("%s 열렸다 — 무너진 집들이 드러났다" % Num.josa(String(dd.name), "이", "가"), "milestone")
	return true

## 다음에 열 가게. **잠긴 구역의 가게는 없는 셈 친다** — 무너진 집 표시도,
## 가상 플레이어의 판단도 전부 여기를 거친다.
## k번째 일꾼의 무늬(0 = 첫 너구리). 자리마다 따로 배정된다 — "쌍둥이 말고
## 랜덤 너구리"(2026-08-26, 유저).
func fur_of(id: String, k: int = 0) -> String:
	if k <= 0:
		return String(furs.get(id, "a"))
	return String(furs.get("%s:%d" % [id, k], "a"))

## 무늬 주머니 — 덜 쓴 무늬만 담아 뽑는다(초반 중복 방지, 유저 규칙).
## 뽑는 손은 여는 순간의 게임 시계다 — 저장본마다 다르고(여는 시각이 다르니),
## 같은 판을 다시 돌리면 늘 같다(sim은 주사위 없이도 결정적이어야 한다).
func _deal_fur(id: String) -> void:
	if furs.has(id):
		return
	var used: Dictionary = {}
	for f in furs.values():
		used[f] = int(used.get(f, 0)) + 1
	var low: int = 1 << 30
	for f in FURS:
		low = min(low, int(used.get(f, 0)))
	var bag: Array = []
	for f in FURS:
		if int(used.get(f, 0)) == low:
			bag.append(f)
	furs[id] = bag[int(fposmod(t * 977.0, float(bag.size())))]

func next_shop() -> Variant:
	for s in Content.SHOPS:
		if not shops.has(s.id) and district_open(String(s.id)):
			return s
	return null

func open_shop(id: String) -> bool:
	if not _shop_by_id.has(id):
		return false
	var s: Dictionary = shop_by_id(id)
	if shops.has(id) or money < s.cost or not district_open(id):
		return false
	money -= s.cost
	shops.append(id)
	_deal_fur(id)
	bump("open.shop")
	var first: Dictionary = s.items[0]
	items[first.id] = {"lv": 1.0, "stock": 0.0, "prog": 0.0}
	bench[id] = 1.0                     # 작업대 1단 — 첫 물건은 문 여는 값에 딸려 온다
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
	bump("tap.fair")
	fair = Content.FAIR.boost
	_ev("장이 섰다 — 손님이 몰린다!", "shop")
	_event_gain("fair", 1.0)
	return true

# ── 나뭇잎 강화(패시브 스킬로 흡수 예정) ──
func up_lv(id: String) -> float: return gemUp.get(id, 0.0)
func gem_cost(id: String) -> Variant:
	if not _gu.has(id):
		return null
	var u: Dictionary = _gu[id]
	var l: int = int(up_lv(id))
	if l >= int(u.max):
		return null
	# 패시브 스킬(2026-08-27)은 값이 **레벨 × costMul**이다 — 표를 스무 줄씩
	# 손으로 적지 않는다. 옛 강화 셋은 그대로 표(cost)를 쓴다.
	if u.has("costMul"):
		return float(l + 1) * float(u.costMul)
	return u.cost[l]

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

## 스킬 한 가지가 지금 얼마나 세졌나 — step × 레벨.
func skill(id: String) -> float:
	return float(_gu[id].step) * up_lv(id) if _gu.has(id) else 0.0

## 손님 걸음 — 기본 0.45에서 스킬로 1.00까지 올라간다(2026-08-27).
## 일부러 느리게 두고 시작한다. 되찾는 30%가 첫 성장의 손맛이다.
func guest_walk() -> float:
	return minf(1.0, float(Content.GUEST_WALK) + skill("walk"))

## 너구리가 걷고 나르는 속도 배수(화면이 읽는다).
func carry_speed() -> float: return 1.0 + skill("carry")

## 밤에 손이 느려지는 정도 — 1.35에서 스킬로 1.15까지.
func night_craft() -> float:
	return maxf(1.0, float(Content.DAY.nightCraft) - skill("night"))

## 의뢰 보상 배수 / 의뢰가 주는 나뭇잎 배수.
func quest_pay_mul() -> float: return float(Content.QUEST.payMul) + skill("questpay")
func quest_leaf_mul() -> float: return 1.0 + skill("questleaf")

## 오프라인 — 쳐주는 시간(초)과 배율.
func offline_cap() -> float:
	return float(Content.OFFLINE.capHours) * 3600.0 + skill("offtime")
func offline_rate() -> float:
	return minf(1.0, float(Content.OFFLINE.efficiency) + skill("offrate"))
func offline_leaf_mul() -> float: return 1.0 + skill("offleaf")

func haggle() -> float: return 1.0 + _gu.haggle.step * up_lv("haggle")
func forge_mul() -> float: return 1.0 - _gu.forge.step * up_lv("forge")
func serve_pause() -> float: return max(0.2, Content.SERVICE.servePause - _gu.hands.step * up_lv("hands"))

func can_rush() -> bool: return rush <= 0.0 and gems >= Content.GEM.rush.cost
func call_rush() -> bool:
	if not can_rush():
		return false
	gems -= Content.GEM.rush.cost
	rush = Content.GEM.rush.secs
	_ev("부스터를 켰다 — %s초 동안 생산 %s배" % [str(int(Content.GEM.rush.secs)), str(int(Content.GEM.rush.mult))], "gem")
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
	bump("event.clear")
	cleared[e.id] = cleared.get(e.id, 0.0) + 1.0
	_ev("%s %s을(를) 깼다 — 🍃%s · %s" % [e.face, e.name, str(int(e.gems)), e.skinName], "event")
	_evDone = (e as Dictionary).duplicate()
	event = null
	_evAt = wall + Content.EVENT.gapHours * 3600.0

# ── 마을 의뢰 ──
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

## 이 물건으로 채워야 할 의뢰 물량이 얼마나 남았나(2026-08-27).
func _quest_rem(item_id: String) -> float:
	var s2: float = 0.0
	for q in quests:
		if String(q.itemId) == item_id and not bool(q.get("done", false)):
			s2 += max(0.0, float(q.need) - float(q.got))
	return s2

## 만든 물건 한 개를 의뢰에 넣는다. 넣었으면 참.
func _quest_put(item_id: String) -> bool:
	for q in quests:
		if String(q.itemId) != item_id or bool(q.get("done", false)):
			continue
		q.got += 1.0
		bump("quest.made")
		if q.got >= float(q.need):
			q["done"] = true
			_ev("%s마을 의뢰를 다 만들었다 — 눌러서 보상을 받으시오" % _guest_by_id[String(q.gid)].name, "quest")
		return true
	return false

## 이 의뢰를 마치면 얼마를 받나 — **화면이 물어보는 자리.**
## ★ 창이 이 식을 베껴 쓰고 있었다(2026-08-27에 잡았다). 그래서 그날 넣은
##   '의뢰 보상'·'의뢰 나뭇잎' 패시브 스킬을 화면만 못 보고 실제보다 적게
##   적었다. 베낀 식은 반드시 뒤처진다 — 값을 묻는 곳은 하나여야 한다.
func quest_reward(q: Dictionary) -> Dictionary:
	return {
		"coin": floor(price(String(q.itemId)) * float(q.need) * quest_pay_mul()),
		"leaf": floor(float(q.gems) * quest_leaf_mul()),
	}

## 다 찬 의뢰의 보상을 받는다 — 여기서야 돈·나뭇잎이 들어온다.
func claim_quest(qid: float) -> bool:
	var q: Variant = null
	for x in quests:
		if float(x.id) == qid and bool(x.get("done", false)):
			q = x
			break
	if q == null:
		return false
	for k in range(quests.size()):
		if float(quests[k].id) == qid:
			quests.remove_at(k)
			break
	_qCool = Content.QUEST.every
	var coin: float = float(quest_reward(q).coin)
	money += coin
	revenue += coin
	bump("coin.quest", coin)          # 지표 — 의뢰가 번 몫(판매와 갈라 본다)
	if auto:
		_purse += coin * Content.AUTO_SHARE
	gems += float(quest_reward(q).leaf)
	_ev("%s마을 의뢰를 마쳤다 — 🪙%s · 🍃%s" % [_guest_by_id[String(q.gid)].name, Num.fmt(coin), str(int(q.gems))], "quest")
	_event_gain("quest", 1.0)
	var d: Dictionary = (q as Dictionary).duplicate()
	d["coin"] = coin
	bump("quest.done")
	_questDone.append(d)
	return true

## 지금 등급의 만렙에 닿았으면 나뭇잎 한 알. 등급이 오르면 다시 한 번 받는다.
func _check_max(id: String) -> void:
	if not at_max(id):
		return
	var key: String = "%s@%d" % [id, rank_of_item(id)]
	if maxGem.has(key):
		return
	maxGem[key] = 1.0
	gems += Content.GEM.onMax
	_ev("%s 만렙 — 🍃%s" % [Num.josa(item_name(id), "이", "가"), str(int(Content.GEM.onMax))], "gem")

# ── 한 틱 ──
func tick(dt: float, rng: Rng) -> Dictionary:
	_rng = rng
	t += dt
	wall += dt
	_events(dt)
	_trash_tick(dt)

	# 0) 장
	if fair > 0.0:
		fair = max(0.0, fair - dt)
	if busy >= 0:
		_busyT -= dt
		if _busyT <= 0.0:
			busy = -1
	elif fair <= 0.0 and shops.size() >= 2:
		# ★ 장은 이제 **촌장이 연다**(2026-08-25). 작은 건물(점포·포장마차)이
		#   장 여는 단추였는데 의미 없어 보인다고 빼면서, 북적임이 서면 촌장
		#   머리 위에 '장 서다!'가 뜨고 촌장을 누르면 열린다. 문턱은 가게 둘 —
		#   의뢰 창의 "가게를 둘 열면 장이 선다"와 같은 말이 됐다.
		#   busy는 이제 자리 번호가 아니라 깃발이다(0 = 서 있다).
		_fairAcc += dt
		if _fairAcc >= Content.FAIR.every:
			_fairAcc = 0.0
			busy = 0
			_busyT = Content.FAIR.window

	# 1) 생산
	for k in _hold.keys():
		_hold[k] -= dt
		if _hold[k] <= 0.0:
			_hold.erase(k)
	if rush > 0.0:
		rush = max(0.0, rush - dt)
	var speed: float = Content.GEM.rush.mult if rush > 0.0 else 1.0
	# ★ 2026-08-25 생산 개편 — **손 하나가 물건 하나를 만든다.**
	#   예전에는 열린 물건 전부가 동시에 만들어졌다(일꾼 수 무관). 이제
	#   가게의 손 수 = 첫 일꾼 1 + 더 온 일꾼 수. 첫 일꾼이 계산 중이면(_hold)
	#   손이 하나 빠진다 — 더 온 일꾼은 만들기만 하고, 첫 일꾼은 만들다 계산도 한다.
	#   ★ 게임 안에서는 **전부 그냥 일꾼**이다(2026-08-28, 유저). '첫'과 '더 온'은
	#     코드가 자리를 구별하려고 쓰는 말일 뿐, 화면에는 안 나온다.
	#   작업대 순서대로 앞에서부터 손을 배정한다. 다 찬 물건은 손을 안 쓴다.
	# 0) 하늘 — 다음 날씨까지의 시계. 바뀌면 소식 한 줄.
	_wxT -= dt
	if _wxT <= 0.0:
		var tot: float = 0.0
		for k in Content.WEATHER.kinds:
			tot += float(k.weight)
		var pick: float = rng.next() * tot
		var nw: String = String(Content.WEATHER.kinds[0].id)
		for k in Content.WEATHER.kinds:
			pick -= float(k.weight)
			if pick <= 0.0:
				nw = String(k.id)
				break
		_wxT = float(Content.WEATHER.every[0]) \
			+ rng.next() * float(Content.WEATHER.every[1] - Content.WEATHER.every[0])
		if nw != weather:
			weather = nw
			match weather:
				"rain":
					_ev("🌧️ 비가 온다 — 발길은 뜸해지고 일손은 집중한다", "weather")
				"breeze":
					_ev("🍃 산들바람 — 장 보기 좋은 날이다", "weather")
				"cloud":
					_ev("☁️ 하늘이 흐려졌다", "weather")
				_:
					_ev("☀️ 볕이 났다", "weather")

	# 손이 작업대를 옮겨 잡으면 **걸어가는 시간**(CRAFT.walk)이 든다 — 일꾼이
	# 도착하기 전에 물건이 자라는 걸 규칙으로 막는다(2026-08-26, 유저).
	# sim은 화면을 모르지만, "이동"이라는 사실은 안다.
	var _prevCraft: Dictionary = _crafting
	_crafting = {}
	for sh in shops:
		var hands: int = 1 + int(staff_of(String(sh)))
		if _hold.get(sh, 0.0) > 0.0:
			hands -= 1
		if hands <= 0:
			continue
		# ★ 미리 만들지 않는다(2026-08-26, 유저) — **주문된 것만** 만든다.
		#   재고라는 개념이 사라졌다: 주문한다 → 만든다 → 들고 간다 → 판다.
		var first: Array = []
		var second: Array = []
		for it in shop_by_id(String(sh)).items:
			var cid: String = String(it.id)
			if not items.has(cid):
				continue
			if _order_rem(cid) > 0.0:
				first.append(cid)
			elif _quest_rem(cid) > 0.0:
				# ★ 의뢰 물량은 **손님 주문 다음**이다(2026-08-27, 유저).
				#   손님은 눈앞에서 기다리고 의뢰는 기한이 길다 — 급한 쪽 먼저.
				#   이 줄 덕에 "노는 너구리"에게 할 일이 생긴다(지표 hand.idle).
				second.append(cid)
		# ★ 손도 끈끈하다 — 잡은 물건을 다 채울 때까지 안 놓는다. 매 틱
		#   우선순위대로 다시 잡게 했더니 손이 작업대 사이를 쉴 새 없이 갈아타며
		#   걷는 값(walk)만 내다 4시간 매출이 반토막 났다(319M — 재서 잡았다).
		var pool: Array = first + second
		var line2: Array = []
		for id0 in _prevCraft:
			if pool.has(id0) and line2.size() < hands and items.has(String(id0)) \
					and String(item_by_id(String(id0)).shop) == String(sh):
				line2.append(String(id0))
		for id0 in pool:
			if line2.size() >= hands:
				break
			if not line2.has(String(id0)):
				line2.append(String(id0))
		var used: int = 0
		for id in line2:
			if used >= hands:
				break
			var st: Dictionary = items[id]
			_crafting[id] = true
			used += 1
			if not _prevCraft.has(id) and float(_recent.get(id, 1e9)) > float(Content.CRAFT.regrip):
				_switch[id] = float(Content.CRAFT.walk)   # 진짜 이동일 때만
			if float(_switch.get(id, 0.0)) > 0.0:
				_switch[id] = float(_switch[id]) - dt
				continue                     # 아직 걸어가는 중 — 손은 찼지만 진행은 없다
			st.prog += dt * speed
			var need: float = craft_time(id)
			while st.prog >= need and (_order_rem(id) > 0.0 or _quest_rem(id) > 0.0):
				st.prog -= need
				if not _give_to_order(id):
					_quest_put(id)
		# 지표(2026-08-27) — **손이 논 시간.** 한 작업대엔 한 손이라, 같은 물건
		# 주문이 겹치면 남는 너구리가 갈 곳이 없다. 얼마나 잦은지는 짐작이
		# 아니라 이 숫자로 판단한다(의뢰를 생산으로 채우면 줄어야 한다).
		bump("hand.work", dt * float(used))
		bump("hand.idle", dt * float(hands - used))

	# 승급 공사 시계 — 다 되면 그때 등급이 오른다.
	if not building.is_empty():
		for bid in building.keys():
			building[bid] = float(building[bid]) - dt
			if float(building[bid]) <= 0.0:
				_promote_done(String(bid))

	# 손을 댄 지 얼마나 됐나 — regrip 유예의 시계
	for rid in _recent.keys():
		_recent[rid] = float(_recent[rid]) + dt
	for cid2 in _crafting:
		_recent[cid2] = 0.0

	# 1.2) 주문 시계
	var done: Array = []
	if not orders.is_empty():
		var finished: Array = []
		for o in orders:
			o.t += dt
			if float(o.get("eta", 0.0)) > 0.0:
				o.eta = float(o.eta) - dt
				if float(o.eta) <= 0.0:
					# 도착 — 줄이 차 있으면 이 손님은 그냥 지나간다.
					var sh0: String = String(item_by_id(String(o.lines[0].id)).shop)
					if arrived_orders_of(sh0) - 1 >= order_slots(sh0):
						o["passed"] = true
						_passed.append(int(o.id))
						# 지표(2026-08-27) — **눈앞에서 돌아선 발길.** 이 수가
						# 크면 계산대가 모자란 것이다. 지표는 거슬러 올라가
						# 모을 수 없으니 사람이 오기 전에 심는다.
						bump("pass.arrive")
						bump("pass.arrive." + sh0)
			var all_done: bool = true
			for l in o.lines:
				if l.rem > 0.0:
					all_done = false
			if all_done:      # 기다림 시간은 없다 — 주문은 반드시 완성된다(2026-08-26)
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

	# 4.5) 마을 의뢰
	for q in quests:
		q.t += dt
	_qCool -= dt
	if _qCool <= 0.0:
		if quests.size() < quest_slots():
			_new_quest(rng)
		_qCool = Content.QUEST.every

	# 5) 새 손님 — **저절로는 안 온다.**
	#
	# ★ 예전에는 누적 매출이 문턱을 넘으면 손님이 저절로 왔다. 그러면
	#   "기다리면 열린다"가 되는데, 그건 내가 한 일이 아니라 시간이 한 일이다.
	#   이제 손님은 **뽑기로만** 온다(pull·spin 안에서 들어온다).
	var new_guest: Variant = null

	var out: Dictionary = {"passed": _passed.duplicate(), "built": _built.duplicate(), "sales": sales, "done": done, "newGuest": new_guest,
		"autoLv": auto_lv, "pests": _pestEvents, "quests": _questDone, "event": _evDone}
	_built = []
	if not _passed.is_empty():
		var keep2: Array = []
		for o2 in orders:
			if not bool(o2.get("passed", false)):
				keep2.append(o2)
		orders = keep2
		_passed = []
	_evDone = null
	return out

func _order_rem(id: String) -> float:
	var s: float = 0.0
	for o in orders:
		if float(o.get("eta", 0.0)) > 0.0:
			continue                      # 아직 걸어오는 중 — 도착해야 만든다
		for l in o.lines:
			if l.id == id and l.rem > 0.0:
				s += l.rem
	return s

func _give_to_order(id: String) -> bool:
	for o in orders:
		if float(o.get("eta", 0.0)) > 0.0:
			continue
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

	# ★ 한 손님은 **한 가게만** 본다(2026-08-25, 유저가 잡은 치명 오류 —
	#   "필방에 손님이 온 적이 없는데 재고가 떨어진다"). 줄 선 가게가 곧
	#   장 본 가게다.
	# ★ 가게는 **균등하게** 고른다(2026-08-26, 유저 — "필방도 지물포도 안
	#   간다"). 처음에 "섞은 바구니의 첫 물건이 정한 가게"로 했더니 방문이
	#   물건 칸 수에 비례해 쏠렸다 — 물건 여섯인 대장간이 물건 하나인 새
	#   가게의 여섯 배로 손님을 독차지했다.
	# ★ **의뢰는 방문과 무관하다**(2026-08-27, 유저). 예전엔 의뢰를 건 마을
	#   손님을 그 가게로 보냈는데, 그건 **판매가 의뢰를 채우던 시절의 규칙**이다.
	#   어제 "의뢰는 만들어서 채운다"로 바뀌면서 저 쏠림은 하는 일이 없어졌고,
	#   "의뢰한 짐승이 줄을 선다"는 오해만 남겼다. 이제 예외 없이 균등하다.
	var pick_shop: String = String(shops[int(floor(rng.next() * shops.size())) % shops.size()])
	var mine: Array = []
	for id2 in have:
		if String(item_by_id(String(id2)).shop) == pick_shop:
			mine.append(id2)
	have = mine
	if have.is_empty():
		return null

	# ★ 주문 생산(2026-08-26, 유저): 재고에서 집지 않는다 — **주문한다 →
	#   만든다 → 들고 간다 → 판다.** 기다림 시간(patience)도 없앴다: 주문은
	#   반드시 완성된다. 대신 동시에 받는 주문 수가 계산대 수(등급+1)×2로
	#   막힌다 — 차 있으면 이번 발길은 그냥 지나간다.
	# ★ 자리 규칙(2026-08-27, 유저): 걸어오는 손님은 줄 자리를 **안** 문다.
	#   자리는 도착한 줄만 세고, 도착 순간 차 있으면 그때 지나간다(아래 tick).
	#   다만 출발을 아예 안 막으면 거리가 주문으로 넘쳐 4시간이 3.3B까지
	#   끓었다(재서 잡았다) — 걸어오는 무리에도 자리 수만큼 상한을 건다.
	if orders_of(pick_shop) - arrived_orders_of(pick_shop) >= order_slots(pick_shop):
		bump("pass.start")            # 지표 — 오다 말고 돌아선 발길
		return null
	# ★ 한 주문 = **한 종류**(2026-08-26, 유저). 여러 종을 담으면 풍선(첫
	#   물건 하나만 보인다)에 없는 물건이 만들어져 "안 보이는데 생산"이 됐다.
	#   수량은 예전 여러 줄의 총량 수준으로 한 물건에 몰아 담는다.
	var one: String = String(have[0])
	# ★ 사는 개수는 **1~한도 사이 랜덤**(2026-08-26, 유저): 토끼(한도 3)는
	#   1~3개, 사슴(한도 9)은 1~9개. 늘 같은 개수보다 장 보는 맛이 난다.
	#   한도 = 짐승의 qty × 단골 배수. 종류 나눔(spread)은 한 주문 한 종류가
	#   되면서 은퇴했다.
	var lim: float = max(1.0, round(qty))
	var roll: float = 1.0 + floor(rng.next() * lim)
	var want_n: float = max(1.0, ceil(roll))
	var lines: Array = [{"id": one, "n": want_n, "rem": want_n, "unit": price(one) * pay}]

	_oid += 1
	# eta — 손님이 가게까지 **걸어오는 시간.** 주문은 출발할 때 접수되지만
	# 제작은 도착해야 시작된다(2026-08-26, 유저: "도착 전에 만든다").
	# 빠른 짐승은 금방, 거북은 한참 — 화면의 걸음과 대충 맞는다.
	orders.append({"id": _oid, "gid": g.id, "lines": lines, "want": qty, "grumbles": [],
		"t": 0.0, "eta": 8.0 / (float(g.get("speed", 1.0)) * guest_walk())})
	var shown: Array = []
	for l in lines:
		shown.append({"item": item_by_id(l.id), "n": l.n, "gain": floor(l.unit * l.n)})
	return {"guest": g, "orderId": _oid, "waiting": true, "gain": 0.0, "n": 0.0,
			"want": qty, "grumbles": [], "lines": shown}

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
	bump("coin.sale", gain)           # 지표 — 손님에게 판 몫
	if auto:
		_purse += gain * Content.AUTO_SHARE

	for ln in out:
		if staff_of(ln.item.shop) == 0.0:
			_hold[ln.item.shop] = serve_pause()

	for ln in out:
		# ★ 의뢰는 이제 **판매로 안 찬다**(2026-08-27, 유저): 만들어야 찬다.
		#   손님 주문이 늘 먼저고, 남는 손이 의뢰 물량을 만든다(craft 참고).
		_ledger_add(g.id, ln.item.id, ln.n)   # 장날 소식에 쓸 기록

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

# ── 뽑기 ──
##
## ★ 확률은 Content.GACHA.rates가 전부다. 게임 안에서도 그 표를 그대로 보여준다.
##   확률을 숨기는 뽑기는 만들지 않는다.

## 지금 뽑기 레벨(1~10). 여태 뽑은 총 횟수로 정해진다.
func gacha_lv() -> int:
	var lv: int = 1
	for i in range(Content.GACHA.levelAt.size()):
		if pulls >= float(Content.GACHA.levelAt[i]):
			lv = i + 1
	return lv

## 다음 레벨까지 몇 번 더 뽑아야 하나. 만렙이면 null.
func gacha_next() -> Variant:
	var lv: int = gacha_lv()
	if lv >= Content.GACHA.levelAt.size():
		return null
	return float(Content.GACHA.levelAt[lv]) - pulls

func gacha_rates() -> Array:
	return Content.GACHA.rates[gacha_lv() - 1]

func gacha_cost(n: int) -> Variant:
	for c in Content.GACHA.cost:
		if int(c.n) == n:
			return float(c.gems)
	return null

func can_pull(n: int) -> bool:
	var c: Variant = gacha_cost(n)
	return c != null and gems >= float(c)

## 등급 하나를 뽑는다. 표의 무게대로 고른다.
func _roll_grade(rng: Rng, floor_grade: int = 1) -> int:
	var r: Array = gacha_rates()
	var total: float = 0.0
	for i in range(r.size()):
		if i + 1 >= floor_grade:
			total += float(r[i])
	if total <= 0.0:
		return floor_grade
	var x: float = rng.next() * total
	for i in range(r.size()):
		if i + 1 < floor_grade:
			continue
		x -= float(r[i])
		if x <= 0.0:
			return i + 1
	return floor_grade

## 그 등급의 손님 중 하나를 고른다. 등급 안에서는 고르게 나온다.
func _roll_guest(grade: int, rng: Rng) -> String:
	var pool: Array = []
	for g in Content.GUESTS:
		if int(g.grade) == grade:
			pool.append(String(g.id))
	if pool.is_empty():
		return ""
	return String(pool[int(rng.next() * pool.size()) % pool.size()])

## n장 뽑는다. 뽑은 것 목록을 돌려준다 — 화면이 그걸로 연출한다.
##
## 열 장 이상 뽑을 때는 **드묾 이상 한 장을 보장**한다(2레벨부터).
## 열 번 뽑아 전부 흔함이면 뽑은 기억이 안 남는다.
func pull(n: int, rng: Rng) -> Array:
	if not can_pull(n):
		return []
	gems -= float(gacha_cost(n))
	bump("gacha.pull", float(n))
	bump("gacha.pull%d" % n)
	var out: Array = []
	var best: int = 0
	for i in range(n):
		var floor_g: int = 1
		# 마지막 한 장을 남기고도 드묾 이상이 없으면 그 장을 올려 준다
		if n >= 10 and i == n - 1 and best < 2 and gacha_lv() >= int(Content.GACHA.tenPity):
			floor_g = 2
		var grade: int = _roll_grade(rng, floor_g)
		best = max(best, grade)
		var gid: String = _roll_guest(grade, rng)
		if gid == "":
			continue
		bump("gacha.grade%d" % grade)
		var isnew: bool = not guests.has(gid)
		if isnew:
			bump("gacha.newGuest")
			guests.append(gid)
			_guestAcc[gid] = 0.0
			_ev("%s 마을에 왔다" % Num.josa(_guest_by_id[gid].name, "이", "가"), "guest")
		cards[gid] = cards.get(gid, 0.0) + 1.0
		out.append({"id": gid, "grade": grade, "isNew": isnew})
	pulls += float(n)
	return out


## 하루가 바뀌었으면 횟수를 채운다. **실제 시간**으로 센다(wall).
func offline(seconds: float) -> Variant:
	# 수익은 상한까지만 쌓이지만 **이벤트 마감은 그대로 흐른다**
	wall += seconds
	# ★ 승급 공사도 자리를 비운 동안 그대로 돈다(2026-08-27에 잡았다).
	#   안 그러면 네 시간짜리 공사를 게임을 **켜 둔 채로** 기다려야 한다 —
	#   방치형에서 그건 벌이다. 벌이 상한(cap)과 달리 시간은 통째로 흐른다.
	for bid in building.keys():
		building[bid] = float(building[bid]) - seconds
		if float(building[bid]) <= 0.0:
			_promote_done(String(bid))
	_built = []                       # 화면은 아직 없다 — 카드는 켠 뒤 뜨지 않는다
	var cap: float = offline_cap()
	var real: float = min(seconds, cap)
	if real < 60.0:
		return null
	var earned: float = floor(income_per_sec() * real * offline_rate())
	# 나뭇잎도 얹는다(2026-08-27, 유저) — 쳐주는 두 시간마다 한 장.
	var leaf: float = floor(floor(real / 7200.0) * offline_leaf_mul())
	bump("run.offline")
	# ★ 여기서 주지 않는다(2026-08-27). 받는 방법이 둘이 됐다 — 그냥 받기와
	#   주사위 수령. 배수가 정해진 뒤에 claim_offline이 준다.
	return {"earned": earned, "leaf": leaf, "seconds": real, "capped": seconds > cap}

## 자리 비운 벌이를 **배수를 정해 받는다.** 배수는 화면이 주사위로 정한다.
func claim_offline(r: Dictionary, mult: float) -> Dictionary:
	var coin: float = floor(float(r.earned) * mult)
	var leaf: float = floor(float(r.get("leaf", 0.0)) * mult)
	money += coin
	revenue += coin
	gems += leaf
	if auto:
		_purse += coin * Content.AUTO_SHARE
	bump("offline.claim")
	bump("offline.mult", mult)
	return {"earned": coin, "leaf": leaf}

## 주사위 한 번 — ×1~×6. 확률은 content.js에 적힌 무게 그대로다.
func roll_offline_dice(rng: Rng) -> int:
	var total: float = 0.0
	for f in Content.OFFLINE_DICE.faces:
		total += float(f.weight)
	var x: float = rng.next() * total
	for f in Content.OFFLINE_DICE.faces:
		x -= float(f.weight)
		if x < 0.0:
			return int(f.mult)
	return int(Content.OFFLINE_DICE.faces[0].mult)

## ── 저장 ──
##
## ★ 방치형에서 저장은 잔재미가 아니라 **뼈대**다. 껐다 켜면 처음부터인 게임은
##   "잠깐 두고 나중에 본다"가 아예 성립하지 않는다. 오프라인 수익도 여기 얹힌다.
##
## 담을 칸을 손으로 적는다. 자바스크립트는 "이 셋만 빼고 전부"라고 쓸 수 있지만
## GDScript는 그게 안 된다. 그래서 **빠뜨리기 쉽다** — 칸 하나를 빠뜨리면 껐다
## 켤 때마다 그것만 조용히 0으로 돌아간다. tools/crosscheck.sh의 save 시험이
## 저장했다 불러온 판과 안 껐던 판을 끝까지 대조해 그걸 잡는다.
const SAVE_KEYS: Array[String] = [
	"money", "revenue", "t", "shops", "rank", "items", "bench", "guests", "bought", "visits",
	"sold", "auto", "smalls", "guard", "staff", "fair", "busy", "_busyT", "_fairAcc", "_purse",
	"quests", "gems", "gemUp", "maxGem", "_qid", "_qCool", "rush",
	"wall", "event", "skins", "cleared", "_evAt", "_evIdx",
	"orders", "_oid", "_hold", "_guestAcc", "_guestGap", "pest", "_pestAcc", "_pestGap",
	"ledger",
	"cards", "stars", "pulls", "guards",
	"stats", "zones",
	"profile", "furs", "_crafting", "_switch", "_recent", "weather", "_wxT",
	"building",
	"trash", "_trashAcc", "sweepers", "_sweepAcc",
	"story",
]
## 글자로 저장했다 되돌리면 정수가 소수가 된다(-1 → -1.0). 자리를 세는 데
## 쓰는 것들은 도로 정수로 되돌린다 — 아니면 배열 자리를 못 찾는다.
const INT_KEYS: Array[String] = ["busy", "_qid", "_evIdx", "_oid"]

## ★ 저장본 판 번호.
##
## 이게 왜 필요한가: 게임을 낸 뒤에도 규칙은 계속 고친다. 그런데 **이미 놀고
## 있는 사람의 저장본**은 옛 모양이다. 판 번호가 없으면 옛 저장본을 새 규칙에
## 그냥 밀어 넣게 되고, 그러면 조용히 망가진다 — 몇 시간치 진행이 사라지는데
## 왜 그런지는 아무도 모른다.
##
## 규칙: **저장본 모양을 바꾸면 이 번호를 올리고, 옛 판을 받아주는 코드를 남긴다.**
## 그리고 새 판 저장본을 옛 게임에 넣지 않는다(아래 _load에서 막는다) —
## 모르는 칸을 만나면 게임이 죽는 대신 그냥 안 읽는 게 낫다.
## 3판: 세는 칸(stats)이 들어왔다. 없으면 빈 사전으로 시작하므로
## 2판 저장본은 아무 손질 없이 그대로 읽힌다.
##
## 2판: 뽑기·룰렛·카드가 들어오고 삽살개가 여러 마리가 됐다.
##      (룰렛은 2026-08-28에 다시 뺐다 — 옛 저장본의 그 칸은 그냥 안 읽는다.)
## 1판 저장본은 아래 load_from이 받아준다(개 한 마리, 카드 없음, 성은 방문 수로).
## 4판: 구역(zones)이 들어왔다. 3판 저장본은 zones 칸이 없어 기본값으로
## 시작하는데, 아래 load_from이 **열린 가게에서 구역을 되짚는다** —
## 저잣거리 가게를 이미 연 판이면 그 구역도 열린 것으로 친다.
## 5판: 프로필(profile)이 들어왔다. 4판 저장본은 그 칸이 없고, load_from이
## 없는 칸을 건너뛰므로 기본값(너구리·기본 얼굴·자동 띠)으로 시작한다 —
## 따로 옮길 것이 없다.
## 6판: 일꾼 무늬(furs). 옛 저장본은 **연 순서대로 주머니를 돌려** 배정한다 —
## 약속은 "한 번 정하면 안 바뀐다"이지 "무작위"가 아니라서, 옛 판은
## 규칙적이어도 된다. 이후 새로 여는 가게부터 주머니 뽑기를 탄다.
## 7판: 손의 이동(_crafting·_switch). 옛 저장본은 칸이 없어 빈 값으로
## 시작한다 — 첫 틱에 모든 손이 이동 시간을 한 번 내는 것뿐, 옮길 것 없다.
## 8판: 날씨(weather·_wxT). 옛 저장본은 맑음으로 시작하면 된다.
## 9판: 승급 공사(building). 옛 저장본은 그 칸이 없다 — 공사 중인 가게가
## 없다는 뜻이고, 그게 맞다(옛 판에서는 누르는 즉시 승급했다). 이미 오른
## 등급은 rank에 그대로 남아 있으니 잃는 것이 없다.
## 10판: 박쥐가 매로 바뀌었다(손님 id bat → falcon). 담는 칸은 그대로지만
## **칸 안에 든 이름이 달라졌다** — 그냥 두면 이미 박쥐를 뽑은 사람의
## 레전드가 목록에서 사라지고, 쌓아 둔 성과 카드도 주인을 잃는다.
## 옛 저장본을 읽을 때 bat을 falcon으로 옮겨 준다.
## 11판: 손님으로 만들던 물건의 이름을 갈았다(2026-08-27, 유저).
## 사슴이 줄을 서는데 녹용을 팔고, 닭 손님 옆에서 닭꼬치를 굽고 있었다.
## 가게 하나(푸줏간 → 과일전)와 물건 열아홉의 id가 바뀌었다 — **담는 칸은
## 그대로고 칸에 든 이름표만 달라졌다.** 그냥 두면 열어 둔 가게와 물건,
## 올려 둔 등급이 통째로 사라진다. 이름표를 갈아 끼워 준다.
## 12판: 쓰레기가 화면 장식에서 **경제 규칙**이 됐고, 장터 청소부가 생겼다.
## 옛 저장본에는 trash·sweepers 칸이 아예 없다 — 없으면 0이고, 그게 맞다
## (길이 깨끗한 채로 다시 시작하고, 청소부는 아직 안 뽑은 것이다).
## 13판: 이야기 마디(story). 옛 저장본에는 없다 — 그러면 빈 칸이고, 이미
## 한참 논 사람에게 "왔구나"부터 다시 뜬다. 그건 안 된다. 그래서 옛 판을
## 받을 때 **가진 것을 보고 지나간 마디를 되짚어** 채운다(load_from 아래).
## 14판: 대장간이 농기구 가게가 됐다 — 물건 여덟의 이름표가 갈렸다.
## 담는 칸은 그대로고 칸에 든 이름만 달라졌다. 안 갈아 주면 열어 둔 물건과
## 올려 둔 레벨이 통째로 사라진다.
## 15판: 매대 칸이 **작업대 단수**로 바뀌었다(2026-08-29, 유저).
## 담는 방법이 달라졌다 — 예전엔 "어떤 물건이 열렸나"를 물건마다 따로 적었고
## (items의 열쇠), 여는 자격은 asked에 적혀 있었다. 이제는 가게마다 **숫자
## 하나**(bench)다. 옛 저장본에는 그 숫자가 없다 — 그냥 두면 모든 가게가
## 1단으로 되돌아가고, 사서 올려 둔 물건이 화면에서 사라진다.
## 그래서 옛 판을 읽을 때 **열려 있는 물건을 앞에서부터 세어** 단수를 매긴다.
## asked는 이제 쓰지 않으므로 그냥 안 읽는다(잃을 것이 없다 — 물건은 이미
## items에 열려 있고, 안 열린 것은 어차피 돈으로 사는 것이 됐다).
const SAVE_VER: int = 15

## 11판에서 바뀐 이름표. 옛 id → 새 id.
const RENAMED_V11: Dictionary = {
	"butcher": "fruit",
	"dwaeji": "chamoe", "dak": "salgu", "sogogi": "jadu", "galbi": "boksung",
	"ugeoji": "subak", "gopchang": "hongsi", "ansim": "yuja", "hanwoo": "seokryu",
	"antler": "hasuo", "bezoar": "gamcho",
	"gomtang": "kongguk", "samgye": "deulkkae", "chueo": "jeongol", "yongbong": "yeonip",
	"bossam": "modeum",
	"dakggo": "gamja", "sanjeok": "eunhaeng", "neobiani": "deodeok", "yukhoe": "songi",
}

## 14판 — 대장간이 **농기구 가게**가 됐다(2026-08-28, 유저).
## 자리 순서대로 이름표만 갈아 끼운다. n번째 물건은 그대로 n번째다 —
## 값·시간·여는 값을 하나도 안 바꿨으니 올려 둔 레벨이 그대로 산다.
##
## ★ 여기 **덫이 하나** 있다. hoe와 sickle은 옛 목록에도 새 목록에도 있는데
##   자리가 다르다(hoe 3→1, sickle 2→4). 하나씩 제자리에서 바꾸면
##   먼저 옮긴 것을 나중 것이 덮어쓴다. 그래서 **새 사전을 따로 만들어**
##   통째로 갈아 끼운다(아래 _rename_v14).
const RENAMED_V14: Dictionary = {
	"pick": "hoe", "sickle": "trowel", "hoe": "rake", "axe": "sickle",
	"shears": "spade", "knife": "fork", "lock": "chaff", "cauldr": "plow",
}

## 배열·사전을 통째로 새로 만들어 이름표를 간다. 제자리 수정은 안 한다 —
## 옛 이름과 새 이름이 겹칠 때 덮어쓰기 때문이다.
func _rename_v14() -> void:
	var m: Dictionary = RENAMED_V14
	for name in ["items", "bought", "cleared"]:
		var d: Dictionary = get(name)
		var nd: Dictionary = {}
		for k in d.keys():
			nd[m.get(String(k), k)] = d[k]
		set(name, nd)
	for q in quests:
		if q is Dictionary and m.has(String(q.get("item", ""))):
			q["item"] = m[String(q["item"])]
	for o in orders:
		if not (o is Dictionary):
			continue
		for ln in (o.get("lines", []) as Array):
			if ln is Dictionary and m.has(String(ln.get("id", ""))):
				ln["id"] = m[String(ln["id"])]

func save() -> Dictionary:
	var d: Dictionary = {}
	for k in SAVE_KEYS:
		var v: Variant = get(k)
		d[k] = v.duplicate(true) if v is Array or v is Dictionary else v
	return d

## ★ 글자(JSON)로 저장하지 않는다. **소수가 정확히 안 돌아온다.**
##
## 처음엔 JSON으로 만들었다가 두 번 데었다:
##
## 1. `sort_keys`가 기본으로 **켜져** 있다. 그러면 items의 순서가 넣은 차례가
##    아니라 가나다순으로 바뀐다. 손님은 items의 순서를 섞어서 물건을
##    고르므로(_buy), 순서가 달라지면 **같은 주사위로도 다른 물건을 집는다.**
##    저장했다 켰을 뿐인데 30분 만에 매출이 갈라졌다.
##
## 2. 그걸 끄고 `full_precision`을 켜도 **비트 하나가 어긋났다.**
##    (1.43984302427218668896 → 1.43984302427218691101)
##    지금 당장은 티가 안 나지만, 만드는 진행도가 문턱을 넘느냐 마느냐가
##    한 틱 갈리면 거기서부터 판이 달라진다.
##
## 그래서 **이진 저장**을 쓴다. Godot이 소수를 8바이트 그대로 담고 그대로
## 꺼내므로 어긋날 자리가 없다. 정수와 소수도 구분해서 보존한다.
## 사람이 열어볼 수 없게 되지만, 게임 저장본은 원래 그래도 된다.
func to_blob() -> PackedByteArray:
	return var_to_bytes(save())

static func from_blob(b: PackedByteArray) -> Variant:
	return bytes_to_var(b)

## ver는 저장본의 판 번호. **옛 판을 옮기는 코드가 새 판에도 돌면 안 된다** —
## 실제로 그랬다. 성(星)을 방문 횟수에서 옮기는 줄이 2판 저장본에도 돌아서,
## 껐다 켜면 성이 제멋대로 올라갔다. 저장 시험이 그걸 잡았다.
func load_from(d: Dictionary, ver: int = SAVE_VER) -> void:
	for k in SAVE_KEYS:
		if not d.has(k):
			continue
		var v: Variant = d[k]
		set(k, v.duplicate(true) if v is Array or v is Dictionary else v)
	for k in INT_KEYS:
		set(k, int(get(k)))
	var fixed: Array = []
	for i in smalls:
		fixed.append(int(i))
	smalls = fixed
	# ★ 12판 이전 저장본에는 이야기 마디가 없다. 그냥 두면 이미 가게 열 채를
	#   가진 사람에게 "저 무너진 대장간부터일세"가 뜬다. 그래서 **가진 것을 보고
	#   지나간 마디를 되짚어** 준다 — 이야기는 못 돌려줘도 잔소리는 막는다.
	if ver < 14:
		_rename_v14()
	# ★ 15판 — 매대 칸이 작업대 단수가 됐다. 옛 저장본에는 bench 칸이 없다.
	#   열려 있는 물건을 **가게 목록 차례대로 앞에서부터** 세면 그게 곧 단수다
	#   (옛 판도 앞에서부터 순서대로만 열 수 있었으므로 빈틈이 생기지 않는다).
	if ver < 15:
		bench = {}
		for sh9 in shops:
			var n9: int = 0
			for it9 in shop_by_id(String(sh9)).items:
				if not is_open(String(it9.id)):
					break
				n9 += 1
			bench[String(sh9)] = float(max(1, n9))
	if ver < 13:
		for k in ["start", "firstShop", "firstMake", "firstGuest"]:
			story[k] = true
		if not shops.is_empty():
			story["firstShop"] = true
		for sh in shops:
			if staff_of(String(sh)) > 0.0:
				story["firstStaff"] = true
			if rank_of(String(sh)) > 0:
				story["firstRank"] = true
		if zones.has("jeoja"):
			story["zone2"] = true
		if zones.has("keunjang"):
			story["zone3"] = true
	# 저장한 뒤에 손님이 늘어났으면 그 칸이 없다. 없는 칸에 dt를 더하면
	# 값이 망가져서 **그 손님은 영영 안 온다** — 찾기 아주 나쁜 종류의 고장이다.
	for g in Content.GUESTS:
		if not _guestAcc.has(g.id):
			_guestAcc[g.id] = 0.0
	# 6판 전 저장본 — 무늬 칸이 없다. 연 순서대로 배정한다(위 SAVE_VER 참고).
	if ver < 6 and furs.is_empty():
		for k in range(shops.size()):
			furs[String(shops[k])] = FURS[k % FURS.size()]
	# ── 옛 저장본(1판) 받아주기 ──
	# 개: 있다/없다 → 마리 수
	if ver < 2 and guards <= 0.0 and guard:
		guards = 1.0
	# 성: 방문 횟수로 매기던 것을 그대로 옮겨 온다. 안 옮기면 몇 시간 쌓은
	# 단골이 전부 1성으로 되돌아간다 — 그건 저장본을 깨뜨린 것과 같다.
	if ver < 2 and stars.is_empty() and not visits.is_empty():
		for gid in visits.keys():
			stars[gid] = float(regular_lv_old(String(gid)))
	# 11판 전 저장본 — 가게 하나와 물건 열아홉의 이름표가 바뀌었다.
	# 배열 칸(값이 id)과 사전 칸(열쇠가 id)을 나눠서 갈아 끼운다.
	# 열쇠가 "가게:번호" 꼴인 것(furs)은 앞부분만 바꾼다.
	if ver < 11:
		for arr in [shops, zones, guests, skins]:
			for i2 in range(arr.size()):
				if RENAMED_V11.has(arr[i2]):
					arr[i2] = RENAMED_V11[arr[i2]]
		for d3 in [rank, items, bought, cleared, furs]:
			for k3 in d3.keys():
				# 열쇠가 "가게:번호" 꼴인 것이 있다(furs) — **앞부분만** 간다.
				# 통째로 바꾸려다 replace()에 인자를 셋 줬는데, Godot의 replace는
				# 둘까지다. 조각으로 나눠 첫 조각만 바꾸는 편이 뜻도 분명하다.
				var parts: PackedStringArray = String(k3).split(":")
				var head: String = parts[0]
				if not RENAMED_V11.has(head):
					continue
				parts[0] = String(RENAMED_V11[head])
				var nk: String = ":".join(parts)
				d3[nk] = d3[k3]
				d3.erase(k3)
		# 진행 중인 의뢰도 물건 이름을 들고 있다 — 안 갈면 못 채우는 의뢰가 된다.
		for q in quests:
			if q is Dictionary and RENAMED_V11.has(q.get("item", "")):
				q["item"] = RENAMED_V11[q["item"]]
	# 10판 전 저장본 — 박쥐(bat)가 매(falcon)로 바뀌었다. 이름만 갈아 끼운다.
	# 성·카드·등장 간격까지 통째로 옮겨야 뽑아 둔 레전드를 안 잃는다.
	if ver < 10 and guests.has("bat"):
		guests[guests.find("bat")] = "falcon"
		for d2 in [stars, cards, visits, _guestAcc, _guestGap]:
			if d2.has("bat"):
				d2["falcon"] = d2["bat"]
				d2.erase("bat")
	for gid in guests:
		if not cards.has(gid):
			cards[gid] = 0.0
	# 구역보다 가게가 먼저 저장된 판 — 열린 가게가 있는 구역은 열린 것으로 친다.
	# 몇 번을 돌려도 같은 결과라 판 번호를 안 가린다(가리면 조건이 하나 더 늘 뿐이다).
	for dz in Content.DISTRICTS:
		if zones.has(String(dz.id)):
			continue
		for sid in dz.shops:
			if shops.has(String(sid)):
				zones.append(String(dz.id))
				break

# ── 장날 소식 ──

## 지금이 게임내 며칠째인가. **켜 둔 시간(t)**으로 센다 —
## 자리를 비운 동안에는 물건이 팔린 기록이 없으니 날짜만 넘어가면 빈 장이 된다.
func day() -> int:
	return int(t / (Content.LEDGER.dayMinutes * 60.0))

## 몇 번째 장인가 (닷새가 한 장)
func fair_no() -> int:
	return int(day() / Content.LEDGER.daysPerFair)

## 오늘 장이 선 지 며칠째인가 (1~5일)
func fair_day() -> int:
	return day() % int(Content.LEDGER.daysPerFair) + 1

func _ledger_add(gid: String, item_id: String, n: float) -> void:
	var d: int = day()
	if ledger.is_empty() or ledger[ledger.size() - 1].day != d:
		ledger.append({"day": d, "sales": {}})
		# 오래된 것은 버린다. 안 버리면 저장본이 끝없이 커진다.
		while ledger.size() > int(Content.LEDGER.keepDays):
			ledger.remove_at(0)
	var box: Dictionary = ledger[ledger.size() - 1].sales
	var key: String = gid + ">" + item_id
	box[key] = box.get(key, 0.0) + n

## 최근 며칠치를 하나로 합친다. days가 0이면 갖고 있는 전부.
func _merge(days: int) -> Dictionary:
	var out: Dictionary = {}
	var from_day: int = day() - days + 1 if days > 0 else -1
	for e in ledger:
		if days > 0 and e.day < from_day:
			continue
		for k in e.sales.keys():
			out[k] = out.get(k, 0.0) + e.sales[k]
	return out

## 큰 것부터 [[이름, 개수], …]. 정렬이 아니라 훑어서 뽑는다 —
## Godot의 sort_custom은 같은 값끼리의 순서를 보장하지 않아서,
## 개수가 같은 두 품목의 등수가 화면을 볼 때마다 뒤바뀐다.
static func _rank(counts: Dictionary, top: int) -> Array:
	var rows: Array = []
	var left: Dictionary = counts.duplicate()
	while rows.size() < top and not left.is_empty():
		var best: String = ""
		var best_n: float = -1.0
		for k in left.keys():
			if left[k] > best_n:
				best_n = left[k]
				best = k
		rows.append([best, best_n])
		left.erase(best)
	return rows

## 이번 장에 잘 나간 품목 [[itemId, 개수], …]
func hot_items(days: int, top: int) -> Array:
	var by_item: Dictionary = {}
	for k in _merge(days).keys():
		var it: String = k.split(">")[1]
		by_item[it] = by_item.get(it, 0.0) + _merge(days)[k]
	return _rank(by_item, top)

## 이 품목을 누가 사갔나 [[guestId, 개수], …]
func buyers_of(item_id: String, days: int, top: int) -> Array:
	var by_guest: Dictionary = {}
	var m: Dictionary = _merge(days)
	for k in m.keys():
		var parts: PackedStringArray = k.split(">")
		if parts[1] == item_id:
			by_guest[parts[0]] = by_guest.get(parts[0], 0.0) + m[k]
	return _rank(by_guest, top)

## 이 마을의 핫템 (없으면 빈 글자)
func hot_for(gid: String, days: int) -> String:
	var by_item: Dictionary = {}
	var m: Dictionary = _merge(days)
	for k in m.keys():
		var parts: PackedStringArray = k.split(">")
		if parts[0] == gid:
			by_item[parts[1]] = by_item.get(parts[1], 0.0) + m[k]
	var r: Array = _rank(by_item, 1)
	return r[0][0] if not r.is_empty() else ""

## 이 품목의 최고 단골 (없으면 빈 글자)
func best_buyer(item_id: String, days: int) -> String:
	var r: Array = buyers_of(item_id, days, 1)
	return r[0][0] if not r.is_empty() else ""

func _ev(msg: String, kind: String) -> void:
	events.push_front({"t": t, "msg": msg, "kind": kind})
	if events.size() > 40:
		events.resize(40)
