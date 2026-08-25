class_name Art
## 그림(스프라이트)을 찾아 준다. **없으면 없다고 답한다** — 그게 이 파일의 전부다.
##
## 그림은 한 장씩 들어온다. 그래서 "다 모일 때까지 기다리는" 구조면 안 된다.
## 있으면 그림을 그리고, 없으면 여태 그리던 도형·이모지를 그대로 그린다.
## 폴더에 png를 떨어뜨리는 순간 그 자리만 바뀐다.
##
## ★ 그림은 반드시 **godot/art/** 안에 있어야 한다(res://art/…).
##   Godot은 제 프로젝트 폴더 밖을 못 읽는다.

## 화면에 그리는 크기(월드 px). 파일은 이것의 **2배**로 받는다 —
## 폰은 화면이 촘촘해서(2~3배) 같은 크기로 주면 뿌옇게 보인다.
const SIZE := {
	"hero": Vector2(72, 72),
	"clerks": Vector2(72, 72),      # 가게별 점장 — 공통 점장과 같은 크기여야 갈아 끼울 수 있다
	# ★ 직원도 **점장과 같은 크기**다. 처음엔 작게 뒀는데, 크기로 가르면
	#   "덜 자란 너구리"처럼 보인다. 둘은 같은 너구리고 맡은 일만 다르다.
	#   가르는 것은 크기가 아니라 **손에 든 것과 머리에 쓴 것**이다.
	"staff": Vector2(72, 72),
	# 96×88 → 82×74 (2026-08-26, 유저): 한 칸에서 위로 쏠려 보이고 상품과
	# 겹쳤다. 매대는 상품 받침이지 주인공이 아니다.
	"stalls": Vector2(82, 74),
	"kilns": Vector2(84, 96),        # 가마·풀무 — 매대보다 조금 높다
	"counters": Vector2(84, 72),     # 계산대 — 낮고 넓적하다. 문 방향 따라 코드가 뒤집는다
	"guests": Vector2(64, 64),
	# ★ 물건은 64×112로 그렸더니 **도끼가 점장보다 컸다** — 매대(69×35)와
	#   너구리(72)를 삼켜 버린다. 파일은 128×224 그대로 두고 화면만 줄인다.
	#   찍어 보고 잡은 값이다. 38×66도 "가게를 가린다, 많이 줄여도 된다"
	#   (2026-08-25, 유저) — 물건은 매대 위 소품이지 주인공이 아니다.
	"items": Vector2(26, 45),
	"pests": Vector2(64, 64),
}

static var _cache: Dictionary = {}
static var _fit: Dictionary = {}

## 그림 속 몸이 액자 어디에 있나 — **한 번 재서 기억한다.**
## pad: 아래 투명 여백(높이의 몇 할). 있으면 발이 공중에 뜬다.
## cx: 몸의 가로 한가운데(0~1). 0.5가 아니면 몸이 옆으로 치우친 그림이라,
##     발끝 기준으로 놓으면 그림자와 몸이 어긋난다(유저: "밀린 느낌").
## 그림마다 다 달라서 사람이 맞추는 건 끝이 없다 — 재는 게 맞다.
static func fit(t: Texture2D) -> Dictionary:
	var key: String = t.resource_path
	if _fit.has(key):
		return _fit[key]
	var out: Dictionary = {"pad": 0.0, "cx": 0.5}
	var img: Image = t.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
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
		out.pad = float(rows) / float(h)
		if x1 >= x0:
			out.cx = float(x0 + x1) * 0.5 / float(w)
	_fit[key] = out
	return out

## 등급이 있는 그림(물건)은 **등급 것부터 찾는다.** `pick-1.png`가 있으면
## 참쇠곡괭이는 그걸 쓰고, 없으면 기본 `pick.png`를 쓴다.
## 40종 × 3등급 = 120장을 다 그릴 이유는 없다 — 그리고 싶은 것만 그리면 된다.
static func ranked(dir: String, id: String, rank: int) -> Texture2D:
	if rank > 0:
		var t: Texture2D = tex(dir, "%s-%d" % [id, rank])
		if t != null:
			return t
	return tex(dir, id)

## 없으면 null. 한 번 찾아본 것은 **없다는 사실까지** 기억한다 —
## 매 프레임 파일이 있나 물어보면 그리는 것보다 그 일이 더 비싸진다.
static func tex(dir: String, id: String) -> Texture2D:
	var key: String = dir + "/" + id
	if _cache.has(key):
		return _cache[key]
	var path: String = "res://art/%s.png" % key
	var t: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[key] = t
	return t
