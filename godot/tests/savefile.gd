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

	# ── ★ v2에서 저장본 호환을 끊었다(2026-08-29). 그래서 여기서 볼 것이 뒤집혔다.
	#   예전엔 "10판 저장본의 이름표가 옮겨지나"를 봤다. 이제 볼 것은
	#   **"모르는 판을 만나면 통째로 무시하나"**다 — 반쯤 읽는 것이 제일 나쁘다.
	#   (낼 때가 되면 규칙 5를 다시 켜고 이 시험도 되돌린다.)
	var c := Sim.new()
	var clean: Dictionary = c.save()
	c.load_from(a.save(), Sim.SAVE_VER - 1)
	var ignored: bool = c.save() == clean
	print("모르는 판 저장본을 통째로 무시하나: ", "예" if ignored else "아니오")
	quit(0 if (ok and ignored) else 1)
