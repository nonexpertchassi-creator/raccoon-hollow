extends SceneTree
## 답안지 맞추기 — 어느 조각을 볼지는 명령줄에서 받는다.
##   godot --headless --path godot --script tests/crosscheck.gd -- <조각>
## 결과는 res://out_godot.txt로 나가고, 비교는 tools/crosscheck.sh가 한다.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var subject: String = args[0] if args.size() > 0 else "fmt"
	var out: String = ""
	match subject:
		"fmt":
			out = _fmt_cases()
		"rng":
			out = _rng_cases()
		"content":
			out = _content_dump()
		"sim":
			# 문제 파일 첫 줄이 "씨앗 초 틱"
			var a: PackedStringArray = _lines()[0].split(" ")
			out = RunSim.run(a[0].to_int(), a[1].to_float(), a[2].to_float())
		_:
			push_error("모르는 조각: " + subject)
			quit(1)
			return
	var w: FileAccess = FileAccess.open("res://out_godot.txt", FileAccess.WRITE)
	w.store_string(out)
	quit()

func _lines() -> PackedStringArray:
	var f: FileAccess = FileAccess.open("res://cases.txt", FileAccess.READ)
	if f == null:
		push_error("cases.txt가 없다 — tools/crosscheck.sh로 실행할 것")
		quit(1)
		return PackedStringArray()
	return f.get_as_text().strip_edges().split("\n")

func _fmt_cases() -> String:
	var out: String = ""
	for line in _lines():
		var s: String = line.strip_edges()
		if s != "":
			out += Num.fmt(s.to_float()) + "\n"
	return out

## 씨앗마다 앞의 여러 개를 뽑아 적는다. 한 개만 맞아도 통과해 버리면
## 수열이 어긋나는 걸 못 잡는다 — 난수는 흐름 전체가 같아야 한다.
func _rng_cases() -> String:
	var out: String = ""
	for line in _lines():
		var s: String = line.strip_edges()
		if s == "":
			continue
		var r := Rng.new(s.to_int())
		for i in range(20):
			out += str(r.next_u32()) + "\n"
	return out

## content.gd에 담긴 숫자를 **하나도 빠짐없이** 늘어놓는다.
##
## content.gd는 content.js에서 뽑아낸 것이라 원래 같아야 하지만,
## 뽑아내는 도구가 틀릴 수도 있고(큰 수가 잘리거나 소수가 뭉개지거나)
## 누가 content.gd를 손으로 고칠 수도 있다. 그럼 조용히 갈라진다.
## 1,600줄쯤 되지만 대조는 0.1초다 — 안 볼 이유가 없다.
func _content_dump() -> String:
	var script: GDScript = load("res://rules/content.gd")
	var consts: Dictionary = script.get_script_constant_map()
	# ★ StringName 그대로 정렬하면 **글자순으로 안 된다.** Godot은 StringName의
	#   대소를 내부 주소로 비교한다(빠르라고). 그래서 만들어진 순서가 나온다.
	#   에러도 경고도 없이 그냥 다른 순서가 나오니 눈치채기 어렵다.
	#   String으로 바꾼 뒤에 정렬한다.
	var names: Array[String] = []
	for k in consts.keys():
		names.append(String(k))
	names.sort()
	var out: Array[String] = []
	for n in names:
		_flat(consts[n], n, out)
	return "\n".join(out) + "\n"

func _flat(v: Variant, path: String, out: Array[String]) -> void:
	match typeof(v):
		TYPE_ARRAY:
			for i in range((v as Array).size()):
				_flat(v[i], "%s[%d]" % [path, i], out)
		TYPE_DICTIONARY:
			var keys: Array[String] = []
			for k in (v as Dictionary).keys():
				keys.append(String(k))   # StringName째로 정렬하면 글자순이 안 된다
			keys.sort()
			for k in keys:
				_flat(v[k], "%s.%s" % [path, k], out)
		TYPE_FLOAT:
			var f: float = v
			out.append(path + "\t" + (("%.1f" % f) if f == floor(f) else str(f)))
		_:
			out.append(path + "\t" + str(v))
