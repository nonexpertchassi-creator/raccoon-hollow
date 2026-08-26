extends Node
## 주문 생산 전면 QA — 게임을 통째로 돌리며(화면 포함) 규칙 위반을 센다.
##   QA_MINUTES=30  얼마나 감을지
## 보는 것: 유령 손님(2분 넘게 줄에 서 있음) · 주문 초과(자리보다 많음) ·
## 재고 부활(주문 생산인데 stock>0) · 줄 폭주 · 걷는 손님 수 폭주.
var _done: bool = false

func _ready() -> void:
	var main: Node = $Main
	var s: Sim = main.sim
	var rng: Rng = main.rng
	var mins: int = int(OS.get_environment("QA_MINUTES")) if OS.has_environment("QA_MINUTES") else 30
	var fails: Array[String] = []
	var max_walkers: int = 0
	var max_line: int = 0
	var over_orders: int = 0
	var stock_alive: int = 0
	var ghosts: int = 0
	for step in range(mins * 60 * 4):
		main.step(0.25)
		RunSim.act(s, rng)
		main.village._advance(0.25)
		max_walkers = max(max_walkers, main.village.walkers.size())
		for i in range(Content.SHOPS.size()):
			max_line = max(max_line, main.village.line[i].size())
		if step % 40 == 0:
			for sh in s.shops:
				# 자리 규칙(2026-08-27): 도착한 줄과 걸어오는 무리를 따로 센다 —
				# 각각 자리 수까지. 합계로 재던 옛 검사는 새 규칙에서 거짓 경보였다.
				var _arr: int = s.arrived_orders_of(String(sh))
				var _wlk: int = s.orders_of(String(sh)) - _arr
				if _arr > s.order_slots(String(sh)) or _wlk > s.order_slots(String(sh)):
					over_orders += 1
			for id in s.items:
				if s.items[id].stock > 0.0:
					stock_alive += 1
			for wk in main.village.walkers:
				if wk.state == "buy":
					wk["_qa_t"] = float(wk.get("_qa_t", 0.0)) + 10.0
					if float(wk["_qa_t"]) > 120.0:
						ghosts += 1
						wk["_qa_t"] = -1e9      # 같은 유령을 두 번 안 센다
	# 주문이 실제로 돌았나 — 0이면 QA 자체가 헛돈 것이다
	if s.sold <= 0.0:
		fails.append("30분 동안 한 개도 안 팔렸다 — 주문 생산이 죽어 있다")
	if over_orders > 0:
		fails.append("주문이 계산대 자리를 %d번 넘었다" % over_orders)
	if stock_alive > 0:
		fails.append("재고가 %d번 살아났다 — 주문 생산인데 stock>0" % stock_alive)
	if ghosts > 0:
		fails.append("유령 손님 %d명 — 2분 넘게 줄에 서 있었다" % ghosts)
	if max_line > 8:
		fails.append("줄이 %d명까지 폭주했다" % max_line)
	if max_walkers > 40:
		fails.append("걷는 손님이 %d명까지 폭주했다" % max_walkers)
	print("QA %d분 — 판매 %d · 최다 손님 %d · 최다 줄 %d · 돈 %s" % [
		mins, int(s.sold), max_walkers, max_line, Num.fmt(s.money)])
	if fails.is_empty():
		print("QA 초록불 — 위반 없음 ✅")
	else:
		for f in fails:
			print("QA FAIL: " + f)
	get_tree().quit(0 if fails.is_empty() else 1)
