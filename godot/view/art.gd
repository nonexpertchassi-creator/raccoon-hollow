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
	"staff": Vector2(60, 60),       # 직원은 점장보다 조금 작다. 누가 주인인지 한눈에 보이게
	"guests": Vector2(64, 64),
	"items": Vector2(64, 112),
	"pests": Vector2(64, 64),
}

static var _cache: Dictionary = {}

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
