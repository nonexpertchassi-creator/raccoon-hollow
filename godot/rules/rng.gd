class_name Rng
## 운 번호를 고정한 난수. balance.mjs가 쓰는 mulberry32를 그대로 옮긴 것.
##
## ★ 이게 왜 이관에서 제일 먼저인가.
##
## 옮긴 규칙이 맞는지 확인하는 방법은 "같은 판을 양쪽에서 돌려 결과를 대조하는
## 것"이다. 그런데 난수가 다르면 같은 판이 아니다. 손님이 다른 물건을 집고,
## 도둑이 다른 때에 나온다. 그러면 매출이 달라져도 **옮기다 틀린 건지 그냥
## 다른 주사위가 나온 건지 구분할 수 없다.** 대조가 통째로 무의미해진다.
##
## ★ 자바스크립트의 32비트 정수를 흉내 내는 부분이 까다롭다.
##
## JS의 `|0`, `>>>`, `Math.imul`은 전부 **32비트**로 자른다. GDScript의 int는
## 64비트라 그냥 옮기면 자리가 넘쳐서 완전히 다른 수열이 나온다.
## 그래서 연산마다 0xFFFFFFFF로 자른다.
##
## 부호는 신경 쓰지 않아도 된다 — XOR·AND·OR·곱셈의 아래 32비트는 부호를
## 어떻게 보든 같은 비트가 나온다(2의 보수). 그래서 전부 부호 없는 쪽으로 통일했다.

const MASK: int = 0xFFFFFFFF

var _a: int = 0

func _init(seed_value: int) -> void:
	_a = seed_value & MASK

## JS의 Math.imul — 32비트 곱셈의 아래 32비트
static func _imul(a: int, b: int) -> int:
	return (a * b) & MASK

## 다음 32비트 정수. **대조는 이 정수로 한다.**
##
## 소수(0~1)로 맞춰보고 싶겠지만 그러면 안 된다 — 소수를 글자로 찍는 순간
## 반올림 규칙이 끼어들고, JS와 C는 그게 다르다(num.gd 주석 참고).
## 난수가 맞는지 보려고 만든 시험에서 반올림 때문에 빨간불이 뜨면
## 어디가 문제인지 못 찾는다. 정수는 그런 게 없다.
func next_u32() -> int:
	_a = (_a + 0x6D2B79F5) & MASK
	var a: int = _a
	var x: int = _imul(a ^ (a >> 15), a | 1) & MASK
	x = (x ^ (x + _imul(x ^ (x >> 7), x | 61))) & MASK
	return (x ^ (x >> 14)) & MASK

## 0 이상 1 미만
func next() -> float:
	return float(next_u32()) / 4294967296.0
