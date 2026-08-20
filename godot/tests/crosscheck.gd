extends SceneTree
## 답안지 맞추기 — cases.txt를 읽어 GDScript 결과를 out_godot.txt로 뱉는다.
## 비교는 tools/crosscheck.sh가 한다.

func _init() -> void:
	var f: FileAccess = FileAccess.open("res://cases.txt", FileAccess.READ)
	if f == null:
		push_error("cases.txt가 없다 — tools/crosscheck.sh로 실행할 것")
		quit(1)
		return
	var out: String = ""
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line == "":
			continue
		out += Num.fmt(line.to_float()) + "\n"
	var w: FileAccess = FileAccess.open("res://out_godot.txt", FileAccess.WRITE)
	w.store_string(out)
	quit()
