extends SceneTree
## 저장했다 불러온 직후에 **무엇이 다른지** 칸 이름으로 찍는다.
func _init() -> void:
	var a := Sim.new()
	var rng := Rng.new(7)
	for i in range(1800 * 4):
		a.tick(0.25, rng)
		RunSim.act(a, rng)
	var b := Sim.new()
	b.load_from(Sim.from_blob(a.to_blob()))
	var da: Dictionary = a.save()
	var db: Dictionary = b.save()
	var bad: int = 0
	for k in Sim.SAVE_KEYS:
		var x: String = JSON.stringify(da.get(k), "", false, true)
		var y: String = JSON.stringify(db.get(k), "", false, true)
		if x != y:
			bad += 1
			var i: int = 0
			while i < x.length() and i < y.length() and x[i] == y[i]:
				i += 1
			print("다름 [%s] — %d번째 글자부터\n   안 껐을 때: …%s\n   불러온 뒤: …%s" % [
				k, i, x.substr(max(0, i - 30), 70), y.substr(max(0, i - 30), 70)])
	if bad == 0:
		print("불러온 직후에는 칸이 전부 같다 — 어긋남은 그 뒤에 생긴다")
	quit()
