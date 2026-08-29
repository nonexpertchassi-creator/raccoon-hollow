extends Node
class_name Sfx
## 소리 — **아직 더미다.** 소리 파일이 한 장도 없어서 실제로는 아무것도 안 울린다.
##
## 그런데 왜 지금 넣나. 넣는 것은 소리가 아니라 **부르는 자리**다.
## 나중에 파일이 왔을 때 "어디서 울려야 하지"를 다시 찾아 헤매면, 화면 코드를
## 통째로 다시 읽어야 한다. 자리를 미리 박아 두면 그때 할 일은 파일 이름을
## 채우는 것뿐이다. 그림(스프라이트)을 도형 자리에 끼워 넣기로 한 것과 같은 수법이다.
##
## ★ **돈 오르는 소리는 일부러 없다.**
##   후반에는 초당 수십 번이 팔린다. 그때 파는 순간마다 소리가 나면 그건
##   소리가 아니라 소음이고, 사람은 소음을 끄지 소리만 골라 끄지 않는다.
##   돈이 오르는 것은 이미 숫자와 🪙 표로 보인다 — 귀까지 쓸 이유가 없다.
##   드물게 일어나는 일에만 소리를 준다. 그게 소리가 뜻을 갖는 조건이다.

## 낼 소리와, 그 소리가 뜻하는 것. 파일이 오면 값 자리에 파일 이름을 넣는다.
const KINDS := {
	"tap": "작업대를 눌러 강화했다",
	"open": "칸·가게·건물을 새로 열었다",
	"catch": "나쁜 놈을 잡았다",
	"fair": "장을 열었다",
	"quest": "의뢰를 마쳤다",
	"guest": "새 손님이 마을에 왔다",
	"sweep": "길에 떨어진 것을 주웠다",
}

## 무엇이 몇 번 울렸나. 소리를 안 내는 지금도 이건 센다 —
## "이 소리가 분당 몇 번인가"는 파일이 오기 전에 답이 나와야 하는 질문이다.
var counts: Dictionary = {}

func play(kind: String) -> void:
	# 오타로 조용해지는 것을 막는다. 안 나는 소리는 고장인지 아닌지 귀로 못 가른다.
	assert(KINDS.has(kind), "모르는 소리: " + kind)
	counts[kind] = int(counts.get(kind, 0)) + 1
	if OS.has_environment("SFX_LOG"):
		print("SFX %s" % kind)

## "쇠망치 · 3번" 처럼 한 줄로. 도구가 화면 옆에 적어 주는 데 쓴다.
func summary() -> String:
	if counts.is_empty():
		return "없음"
	var parts: Array[String] = []
	for k in counts:
		parts.append("%s %d" % [k, int(counts[k])])
	return " · ".join(parts)
