extends SceneTree
## 두 시간 전에 껐던 저장본을 만들어 둔다 — "다녀오신 동안" 창을 눈으로 보려고.
func _init() -> void:
	var s := Sim.new()
	var rng := Rng.new(7)
	for i in range(40 * 60 * 4):
		s.tick(0.25, rng)
		RunSim.act(s, rng)
	var f: FileAccess = FileAccess.open("user://save.dat", FileAccess.WRITE)
	f.store_buffer(var_to_bytes({
		"state": s.save(),
		"at": Time.get_unix_time_from_system() - 7200.0,   # 두 시간 전
	}))
	print("두 시간 전 저장본을 심었다 · 돈 ", Num.fmt(s.money))
	quit()
