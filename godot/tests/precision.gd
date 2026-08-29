extends SceneTree
## 저장했다 불러온 소수가 **비트 하나까지** 같은지 본다.
## 글자로 비교하면 표기 차이에 속는다 — 값 자체를 견준다.
func _init() -> void:
	var a := Sim.new()
	var rng := Rng.new(7)
	for i in range(1800 * 4):
		a.tick(0.25, rng)
		RunSim.act(a, rng)
	var b := Sim.new()
	b.load_from(Sim.from_blob(a.to_blob()))
	var bad: int = 0
	var checked: int = 0
	for id in a.items.keys():
		for f in ["lv", "stock", "prog"]:
			checked += 1
			var x: float = a.items[id][f]
			var y: float = b.items[id][f]
			if x != y:
				bad += 1
				print("값이 다르다 %s.%s : %.20f vs %.20f" % [id, f, x, y])
	for f in ["money", "revenue", "t", "wall", "_purse", "_fairAcc", "fair", "rush", "gems", "sold"]:
		checked += 1
		if float(a.get(f)) != float(b.get(f)):
			bad += 1
			print("값이 다르다 %s : %.20f vs %.20f" % [f, a.get(f), b.get(f)])
	for k in a._guestAcc.keys():
		checked += 1
		if a._guestAcc[k] != b._guestAcc[k]:
			bad += 1
			print("값이 다르다 _guestAcc[%s]" % k)
	print("소수 %d개 견줌 · 다른 것 %d개" % [checked, bad])
	quit()
