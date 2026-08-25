extends SceneTree
## 짐승 그림의 발끝·가운데 검사 — "받아주되, 알려준다."
## 코드(Art.fit)가 여백을 재서 앉혀 주지만, 그건 안전망이지 면허가 아니다.
## 규칙은 그림 쪽에 있다: 발끝은 아래 변에, 몸은 가로 한가운데에.
## 어긋난 그림을 여기서 자동으로 잡아 준다 — 새로 그릴 때 고치면 된다.
const DIRS := ["hero", "hero-body", "clerks", "staff", "guests", "pests"]
const PAD_MAX := 0.03    # 아래 여백 3% 넘으면 발이 떠 보인다
const CX_MAX := 0.05     # 가로 치우침 5% 넘으면 그림자와 어긋나 보인다

func _init() -> void:
	var bad: int = 0
	for d in DIRS:
		var dir := DirAccess.open("res://art/" + d)
		if dir == null:
			continue
		for f in dir.get_files():
			if not f.ends_with(".png"):
				continue
			var img := Image.new()
			if img.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/%s/%s" % [d, f])) != OK:
				continue
			var w: int = img.get_width()
			var h: int = img.get_height()
			var rows: int = 0
			var x0: int = w
			var x1: int = -1
			for y in range(h):
				for x in range(0, w, 2):
					if img.get_pixel(x, y).a > 0.05:
						x0 = min(x0, x)
						x1 = max(x1, x)
			for y in range(h - 1, -1, -1):
				var any: bool = false
				for x in range(0, w, 2):
					if img.get_pixel(x, y).a > 0.05:
						any = true
						break
				if any:
					break
				rows += 1
			var pad: float = float(rows) / float(h)
			var cx: float = (float(x0 + x1) * 0.5 / float(w)) if x1 >= x0 else 0.5
			if pad > PAD_MAX or absf(cx - 0.5) > CX_MAX:
				bad += 1
				print("  ⚠ %s/%s — 아래 여백 %d%% · 가로 치우침 %+d%%" % [
					d, f, int(pad * 100.0), int((cx - 0.5) * 100.0)])
	if bad == 0:
		print("그림 발끝·가운데 전부 규칙대로다 ✅")
	else:
		print("어긋난 그림 %d장 — 새로 그릴 때 위 목록부터 고친다 (게임은 코드가 받아줘서 멀쩡히 돈다)" % bad)
	quit()
