class_name Num
## 숫자를 사람이 읽을 수 있게 줄인다. sim.js의 fmt()를 옮긴 것.
##
## ★ 옮긴 것이 맞는지는 눈으로 안 본다. tools/crosscheck.sh가 JS판과
##   같은 숫자 4,000개를 통과시켜 한 글자라도 다르면 잡아낸다.
##   JS판은 몇 달간 실제로 돌아간 코드라 **답안지로 쓸 수 있다** —
##   엔진을 옮길 때 제일 무서운 건 "옮기다 조용히 달라지는 것"이고,
##   답안지가 있으면 그게 안 조용해진다.

static func fmt(x: float) -> String:
	var n: float = floor(x)
	if n < 1000.0:
		return str(int(n))
	# Qa 뒤로 여섯 더 — 가게 스무 채까지 갈 자리를 미리 낸다.
	# 여기서 멈추면 '12345678Qa' 처럼 줄인 숫자가 다시 안 읽히게 된다.
	# sim.js와 **같이** 고쳐야 한다(fmt 시험이 둘을 대조 중이다).
	var U: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var i: int = 0
	var v: float = n
	while v >= 1000.0 and i < U.size() - 1:
		v /= 1000.0
		i += 1
	if v < 10.0:
		return _cut(v, 2) + U[i]
	elif v < 100.0:
		return _cut(v, 1) + U[i]
	return str(int(floor(v))) + U[i]

## 소수점 아래를 버린다. 반올림을 쓰면 JS와 갈린다 — sim.js의 cut() 주석 참고.
static func _cut(x: float, d: int) -> String:
	var p: float = pow(10.0, d)
	var t: float = floor(x * p) / p
	return ("%.2f" % t) if d == 2 else ("%.1f" % t)

## 조사 붙이기. '쥐이(가)'처럼 나오면 글이 삭는다.
## 한글 마지막 글자에 받침이 있으면 앞쪽, 없으면 뒤쪽을 쓴다.
static func josa(word: String, with_jong: String, without: String) -> String:
	if word.is_empty():
		return word
	var c: int = word.unicode_at(word.length() - 1) - 0xac00
	var jong: bool = c >= 0 and c <= 11171 and c % 28 != 0
	return word + (with_jong if jong else without)
