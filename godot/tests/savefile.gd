extends SceneTree
## 진짜 파일에 담았다 꺼내는 길이 통째로 도는지 본다.
## 규칙만 시험하면 "저장은 되는데 파일이 안 써진다"를 놓친다.
const P := "user://save_test.dat"
func _init() -> void:
	var a := Sim.new()
	var rng := Rng.new(7)
	for i in range(600 * 4):
		a.tick(0.25, rng)
		RunSim.act(a, rng)
	var f: FileAccess = FileAccess.open(P, FileAccess.WRITE)
	f.store_buffer(var_to_bytes({"state": a.save(), "at": 1000.0}))
	f = null
	var g: FileAccess = FileAccess.open(P, FileAccess.READ)
	var box: Variant = bytes_to_var(g.get_buffer(g.get_length()))
	var b := Sim.new()
	b.load_from(box.state, int(box.get("ver", Sim.SAVE_VER)))
	var ok: bool = RunSim.snapshot(a) == RunSim.snapshot(b)
	print("파일에 담았다 꺼낸 판이 같은가: ", "예" if ok else "아니오")
	print("파일 크기: %d바이트" % FileAccess.get_file_as_bytes(P).size())
	# 오프라인 수익도 실제로 붙는지
	# ★ 2026-08-27부터 offline()은 **계산만** 한다 — 받는 것은 claim_offline이다
	#   (그냥 받기 ×1 / 주사위 수령 ×1~×6). 그래서 여기서도 받아 봐야 한다.
	var before: float = b.money
	var r: Variant = b.offline(3600.0)
	if r != null:
		b.claim_offline(r, 1.0)
	print("한 시간 자리 비운 값: ", "🪙" + Num.fmt(r.earned) if r != null else "없음",
		" · 받으면 돈이 늘었나: ", "예" if b.money > before else "아니오")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(P))

	# ── 옛 저장본 받아주기: 11판에서 갈린 이름표가 실제로 옮겨지는가.
	#   이건 눈으로 못 보는 고장이다 — 옛 판을 켠 사람만 겪고, 그 사람은
	#   "가게가 사라졌다"고만 말할 수 있다. 그래서 여기서 흉내 내 본다.
	var old_save: Dictionary = a.save()
	# 새 이름을 옛 이름으로 되돌려 **10판 저장본을 만든다**
	var back: Dictionary = {}
	for k in Sim.RENAMED_V11:
		back[Sim.RENAMED_V11[k]] = k
	var arr2: Array = (old_save["shops"] as Array).duplicate()
	for i2 in range(arr2.size()):
		if back.has(arr2[i2]):
			arr2[i2] = back[arr2[i2]]
	old_save["shops"] = arr2
	var rk2: Dictionary = {}
	for k2 in (old_save["rank"] as Dictionary):
		rk2[back.get(k2, k2)] = old_save["rank"][k2]
	old_save["rank"] = rk2
	var c := Sim.new()
	c.load_from(old_save, 10)
	var kept: bool = c.shops == (a.save()["shops"] as Array) and c.rank.keys().size() == a.rank.keys().size()
	var stale: bool = false
	for k4 in c.rank:
		if back.has(k4) or Sim.RENAMED_V11.has(k4):
			stale = true
	print("10판 저장본을 열면 이름표가 갈아 끼워지나: ", "예" if (kept and not stale) else "아니오")
	quit(0 if (ok and kept and not stale) else 1)
