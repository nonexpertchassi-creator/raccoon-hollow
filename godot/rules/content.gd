class_name Content
## content.js에서 **뽑아낸** 파일이다. 손으로 고치지 말 것 —
## content.js를 고치고 `node tools/gen-content.mjs`를 다시 돌린다.
##
## 숫자가 전부 실수(3.0, 12.0)인 이유: GDScript는 정수끼리 나누면 정수가
## 나온다(7 / 2 = 3). 자바스크립트는 3.5다. 그대로 옮기면 조용히 달라진다.
## 우리 숫자는 최대 2조라 실수로 둬도 정확히 담긴다 — 위험만 없앤 것이다.
##
## 개수를 세거나 자리를 셀 때는 int()로 감싸 쓸 것.

const ASK_EVERY := 14.0

const ASK_LINES := [
	"{item} 있소?",
	"혹시 {item} 파시오?",
	"{item}을 찾고 있는데…",
	"{item} 하나 구할 수 있겠소?",
	"{item}은 안 파시나?"
]

const AUTO_COST := 45000.0

const AUTO_PER_TICK := 40.0

const AUTO_SHARE := 0.6

const BASKET_SPREAD := 3.0

const EVENT := {
	"gapHours": 12.0,
	"afterShops": 2.0
}

const EVENTS := [
	{
		"id": "moonfair",
		"name": "달빛 장터",
		"face": "🌙",
		"hours": 48.0,
		"goal": "quest",
		"need": 35.0,
		"desc": "마을 의뢰를 35건 마친다",
		"gems": 30.0,
		"skin": "moon",
		"skinName": "달빛 너구리"
	},
	{
		"id": "ratchase",
		"name": "쥐잡이 대회",
		"face": "🐭",
		"hours": 48.0,
		"goal": "catch",
		"need": 45.0,
		"desc": "나쁜 놈을 45마리 잡는다",
		"gems": 25.0,
		"skin": "straw",
		"skinName": "도롱이 너구리"
	},
	{
		"id": "bigfair",
		"name": "큰 장",
		"face": "🎪",
		"hours": 48.0,
		"goal": "fair",
		"need": 40.0,
		"desc": "장을 40번 연다",
		"gems": 25.0,
		"skin": "red",
		"skinName": "홍의 너구리"
	}
]

const FAIR := {
	"every": 95.0,
	"window": 12.0,
	"boost": 30.0,
	"mult": 2.0
}

const GEM := {
	"onMax": 1.0,
	"catchRate": 0.1,
	"rush": {
		"cost": 3.0,
		"secs": 30.0,
		"mult": 2.0
	}
}

const GEM_UPGRADES := [
	{
		"id": "forge",
		"name": "벼린 연장",
		"face": "🔨",
		"max": 5.0,
		"step": 0.03,
		"cost": [
			3.0,
			5.0,
			8.0,
			12.0,
			18.0
		],
		"desc": "만드는 시간 −3%"
	},
	{
		"id": "hands",
		"name": "잰 손놀림",
		"face": "🖐️",
		"max": 5.0,
		"step": 0.2,
		"cost": [
			4.0,
			7.0,
			11.0,
			16.0,
			24.0
		],
		"desc": "계산하느라 망치를 놓는 시간 −0.2초"
	},
	{
		"id": "haggle",
		"name": "흥정 솜씨",
		"face": "🤝",
		"max": 10.0,
		"step": 0.015,
		"cost": [
			5.0,
			7.0,
			10.0,
			14.0,
			19.0,
			25.0,
			32.0,
			40.0,
			50.0,
			62.0
		],
		"desc": "모든 물건 값 +1.5%"
	}
]

const GUARD := {
	"id": "dog",
	"name": "삽살개",
	"face": "🐕",
	"cost": 25000.0,
	"rate": 0.6,
	"fine": 3.0,
	"desc": "자리를 비운 사이 나쁜 놈을 대신 잡는다"
}

const GUESTS := [
	{
		"id": "rabbit",
		"name": "토끼",
		"face": "🐰",
		"every": 4.6,
		"qty": 3.0,
		"pay": 1.0,
		"spread": 3.0,
		"speed": 1.4,
		"wild": 0.0,
		"at": 0.0,
		"desc": "발이 빠르지만 조금씩만 산다"
	},
	{
		"id": "magpie",
		"name": "까치",
		"face": "🐦",
		"every": 3.1,
		"qty": 2.0,
		"pay": 0.85,
		"spread": 2.0,
		"speed": 1.7,
		"wild": 0.0,
		"at": 5800.0,
		"desc": "쉴 새 없이 들르는 대신 값을 깎는다"
	},
	{
		"id": "squirrel",
		"name": "다람쥐",
		"face": "🐿️",
		"every": 4.2,
		"qty": 2.0,
		"pay": 1.15,
		"spread": 2.0,
		"speed": 1.5,
		"wild": 0.15,
		"at": 180000.0,
		"desc": "자주 오지만 한두 개면 족하다"
	},
	{
		"id": "badger",
		"name": "오소리",
		"face": "🦡",
		"every": 17.0,
		"qty": 5.0,
		"pay": 1.5,
		"spread": 3.0,
		"speed": 0.9,
		"wild": 0.3,
		"at": 10000000.0,
		"desc": "느긋하게 두루 산다"
	},
	{
		"id": "fox",
		"name": "여우",
		"face": "🦊",
		"every": 32.0,
		"qty": 8.0,
		"pay": 1.2,
		"spread": 3.0,
		"speed": 1.35,
		"wild": 0.4,
		"at": 120000000.0,
		"desc": "재빠르지만 값을 깎는 데 능하다"
	},
	{
		"id": "deer",
		"name": "사슴",
		"face": "🦌",
		"every": 50.0,
		"qty": 9.0,
		"pay": 2.8,
		"spread": 3.0,
		"speed": 1.2,
		"wild": 0.5,
		"at": 1700000000.0,
		"desc": "값을 후하게 쳐준다"
	},
	{
		"id": "boar",
		"name": "멧돼지",
		"face": "🐗",
		"every": 80.0,
		"qty": 12.0,
		"pay": 2.2,
		"spread": 1.0,
		"speed": 1.1,
		"wild": 0.6,
		"at": 5400000000.0,
		"desc": "한 종류를 통째로 쓸어간다"
	},
	{
		"id": "bear",
		"name": "곰",
		"face": "🐻",
		"every": 120.0,
		"qty": 16.0,
		"pay": 4.0,
		"spread": 1.0,
		"speed": 0.8,
		"wild": 0.7,
		"at": 17000000000.0,
		"desc": "진열대를 품절 내고 간다"
	},
	{
		"id": "turtle",
		"name": "거북",
		"face": "🐢",
		"every": 110.0,
		"qty": 14.0,
		"pay": 7.0,
		"spread": 3.0,
		"speed": 0.45,
		"wild": 0.8,
		"at": 44000000000.0,
		"desc": "걸음은 느리나 씀씀이가 크다"
	},
	{
		"id": "crane",
		"name": "두루미",
		"face": "🦢",
		"every": 145.0,
		"qty": 16.0,
		"pay": 6.0,
		"spread": 4.0,
		"speed": 1.1,
		"wild": 0.8,
		"at": 69000000000.0,
		"desc": "이것저것 골고루 챙긴다"
	},
	{
		"id": "ox",
		"name": "소",
		"face": "🐂",
		"every": 260.0,
		"qty": 26.0,
		"pay": 5.0,
		"spread": 3.0,
		"speed": 0.4,
		"wild": 0.9,
		"at": 160000000000.0,
		"desc": "느릿느릿 오지만 수레가 가득 찬다"
	},
	{
		"id": "tiger",
		"name": "호랑이",
		"face": "🐯",
		"every": 400.0,
		"qty": 34.0,
		"pay": 13.0,
		"spread": 2.0,
		"speed": 0.95,
		"wild": 1.0,
		"at": 300000000000.0,
		"desc": "어쩌다 오지만 한 번에 어마어마하게 산다"
	}
]

const LEVEL := {
	"costGrowth": 1.09,
	"priceStep": 0.12,
	"timeReduce": 0.985,
	"timeFloor": 0.4
}

const MAX_BULK := 1000.0

const MILESTONE_EVERY := 25.0

const MILESTONE_MULT := 1.25

const OFFLINE := {
	"capHours": 4.0,
	"efficiency": 0.6
}

const PESTS := [
	{
		"id": "rat",
		"name": "쥐",
		"face": "🐀",
		"at": 4000.0,
		"every": 75.0,
		"wild": 1.0,
		"life": 5.5,
		"steal": "goods",
		"take": 0.12,
		"max": 8.0,
		"fine": 20.0,
		"say": "진열대에 손을 댔다"
	},
	{
		"id": "crow",
		"name": "까마귀",
		"face": "🐦‍⬛",
		"at": 200000.0,
		"every": 110.0,
		"wild": 1.0,
		"life": 4.0,
		"steal": "money",
		"take": 2.0,
		"fine": 13.0,
		"say": "전대를 노린다"
	}
]

const QUEST := {
	"slots": 3.0,
	"every": 90.0,
	"first": 240.0,
	"seconds": 300.0,
	"min": 3.0,
	"payMul": 1.5,
	"gemPerStar": 6.0,
	"gemCap": 5.0
}

const RANKS := [
	{
		"maxLv": 30.0,
		"priceMul": 1.0,
		"guests": 0.0,
		"ips": 0.0
	},
	{
		"maxLv": 60.0,
		"priceMul": 4.0,
		"guests": 32.0,
		"ips": 15000.0
	},
	{
		"maxLv": 100.0,
		"priceMul": 16.0,
		"guests": 135.0,
		"ips": 800000.0
	}
]

const REGULARS := [
	{
		"at": 0.0,
		"name": "뜨내기",
		"qty": 1.0,
		"pay": 1.0
	},
	{
		"at": 120.0,
		"name": "스치는 손",
		"qty": 1.05,
		"pay": 1.05
	},
	{
		"at": 300.0,
		"name": "낯익은",
		"qty": 1.1,
		"pay": 1.1
	},
	{
		"at": 600.0,
		"name": "눈인사",
		"qty": 1.17,
		"pay": 1.17
	},
	{
		"at": 1000.0,
		"name": "단골",
		"qty": 1.23,
		"pay": 1.23
	},
	{
		"at": 1600.0,
		"name": "참단골",
		"qty": 1.3,
		"pay": 1.3
	},
	{
		"at": 2400.0,
		"name": "왕단골",
		"qty": 1.37,
		"pay": 1.37
	},
	{
		"at": 3400.0,
		"name": "귀한 손",
		"qty": 1.44,
		"pay": 1.44
	},
	{
		"at": 4700.0,
		"name": "극진한 손",
		"qty": 1.52,
		"pay": 1.52
	},
	{
		"at": 6400.0,
		"name": "터줏대감",
		"qty": 1.59,
		"pay": 1.59
	},
	{
		"at": 8600.0,
		"name": "상터줏대감",
		"qty": 1.67,
		"pay": 1.67
	},
	{
		"at": 11500.0,
		"name": "만물상 지킴이",
		"qty": 1.75,
		"pay": 1.75
	},
	{
		"at": 15300.0,
		"name": "은패",
		"qty": 1.82,
		"pay": 1.82
	},
	{
		"at": 20200.0,
		"name": "금패",
		"qty": 1.91,
		"pay": 1.91
	},
	{
		"at": 26500.0,
		"name": "옥패",
		"qty": 1.99,
		"pay": 1.99
	},
	{
		"at": 34500.0,
		"name": "어사또",
		"qty": 2.07,
		"pay": 2.07
	},
	{
		"at": 45000.0,
		"name": "원님",
		"qty": 2.15,
		"pay": 2.15
	},
	{
		"at": 58000.0,
		"name": "판서",
		"qty": 2.23,
		"pay": 2.23
	},
	{
		"at": 75000.0,
		"name": "정승",
		"qty": 2.32,
		"pay": 2.32
	},
	{
		"at": 96000.0,
		"name": "상감마마",
		"qty": 2.4,
		"pay": 2.4
	}
]

const SERVICE := {
	"patience": 6.0,
	"linePatience": 9.0,
	"servePause": 1.2
}

const SHOPS := [
	{
		"id": "smith",
		"name": "대장간",
		"sign": "⚒",
		"cost": 0.0,
		"desc": "무쇠를 두드려 연장을 만든다",
		"color": "#b8622f",
		"ranks": [
			"무쇠",
			"참쇠",
			"강철"
		],
		"promote": [
			8000000.0,
			10000000000.0
		],
		"items": [
			{
				"id": "pick",
				"name": "곡괭이",
				"price": 12.0,
				"time": 3.0,
				"cost": 0.0,
				"icon": "⛏️"
			},
			{
				"id": "sickle",
				"name": "낫",
				"price": 34.0,
				"time": 3.8,
				"cost": 80.0,
				"icon": "🌾"
			},
			{
				"id": "hoe",
				"name": "호미",
				"price": 95.0,
				"time": 4.6,
				"cost": 300.0,
				"icon": "🪴"
			},
			{
				"id": "axe",
				"name": "도끼",
				"price": 260.0,
				"time": 5.6,
				"cost": 900.0,
				"icon": "🪓"
			},
			{
				"id": "shears",
				"name": "가위",
				"price": 700.0,
				"time": 6.4,
				"cost": 100000.0,
				"icon": "✂️"
			},
			{
				"id": "knife",
				"name": "부엌칼",
				"price": 1900.0,
				"time": 7.2,
				"cost": 1000000.0,
				"icon": "🔪"
			},
			{
				"id": "lock",
				"name": "자물쇠",
				"price": 5000.0,
				"time": 8.0,
				"cost": 15000000000.0,
				"icon": "🔒"
			},
			{
				"id": "cauldr",
				"name": "가마솥",
				"price": 13000.0,
				"time": 8.8,
				"cost": 40000000000.0,
				"icon": "🍲"
			}
		]
	},
	{
		"id": "brush",
		"name": "필방",
		"sign": "筆",
		"cost": 900.0,
		"desc": "붓과 먹을 다룬다",
		"color": "#3f6f4a",
		"ranks": [
			"거친",
			"고운",
			"명품"
		],
		"promote": [
			90000000.0,
			20000000000.0
		],
		"items": [
			{
				"id": "brush",
				"name": "붓",
				"price": 500.0,
				"time": 4.2,
				"cost": 0.0,
				"icon": "🖌️"
			},
			{
				"id": "ink",
				"name": "먹",
				"price": 1300.0,
				"time": 5.0,
				"cost": 2500.0,
				"icon": "🖋️"
			},
			{
				"id": "inkstone",
				"name": "벼루",
				"price": 3400.0,
				"time": 6.2,
				"cost": 15000.0,
				"icon": "🪨"
			},
			{
				"id": "waterp",
				"name": "연적",
				"price": 5300.0,
				"time": 6.9,
				"cost": 60000.0,
				"icon": "💧"
			},
			{
				"id": "brushpot",
				"name": "필통",
				"price": 8200.0,
				"time": 7.6,
				"cost": 250000000.0,
				"icon": "🗃️"
			},
			{
				"id": "bookmk",
				"name": "서산",
				"price": 12700.0,
				"time": 8.3,
				"cost": 900000000.0,
				"icon": "🔖"
			},
			{
				"id": "brushrk",
				"name": "붓걸이",
				"price": 19400.0,
				"time": 9.0,
				"cost": 70000000000.0,
				"icon": "🪝"
			},
			{
				"id": "album",
				"name": "화첩",
				"price": 30000.0,
				"time": 9.8,
				"cost": 130000000000.0,
				"icon": "📖"
			}
		]
	},
	{
		"id": "paper",
		"name": "지물포",
		"sign": "紙",
		"cost": 20000.0,
		"desc": "닥나무를 떠서 종이를 만든다",
		"color": "#8a7440",
		"ranks": [
			"막",
			"고운",
			"진상"
		],
		"promote": [
			450000000.0,
			35000000000.0
		],
		"items": [
			{
				"id": "hanji",
				"name": "한지",
				"price": 1100.0,
				"time": 5.0,
				"cost": 0.0,
				"icon": "📜"
			},
			{
				"id": "fan",
				"name": "부채",
				"price": 2800.0,
				"time": 6.0,
				"cost": 65000.0,
				"icon": "🪭"
			},
			{
				"id": "window",
				"name": "창호지",
				"price": 7000.0,
				"time": 7.2,
				"cost": 350000.0,
				"icon": "🪟"
			},
			{
				"id": "floorp",
				"name": "장지",
				"price": 10800.0,
				"time": 7.9,
				"cost": 800000.0,
				"icon": "🟫"
			},
			{
				"id": "kite",
				"name": "연",
				"price": 16600.0,
				"time": 8.6,
				"cost": 1200000000.0,
				"icon": "🪁"
			},
			{
				"id": "umbrel",
				"name": "지우산",
				"price": 25500.0,
				"time": 9.3,
				"cost": 2500000000.0,
				"icon": "☂️"
			},
			{
				"id": "lantrn",
				"name": "지등",
				"price": 39000.0,
				"time": 10.1,
				"cost": 200000000000.0,
				"icon": "🏮"
			},
			{
				"id": "screen",
				"name": "병풍",
				"price": 60000.0,
				"time": 10.9,
				"cost": 320000000000.0,
				"icon": "🖼️"
			}
		]
	},
	{
		"id": "pot",
		"name": "옹기점",
		"sign": "甕",
		"cost": 1000000.0,
		"desc": "흙을 빚어 항아리를 굽는다",
		"color": "#6b4a3a",
		"ranks": [
			"질",
			"오지",
			"왕실"
		],
		"promote": [
			2000000000.0,
			60000000000.0
		],
		"items": [
			{
				"id": "jar",
				"name": "옹기",
				"price": 2400.0,
				"time": 5.4,
				"cost": 0.0,
				"icon": "🏺"
			},
			{
				"id": "bowl",
				"name": "사발",
				"price": 6000.0,
				"time": 6.4,
				"cost": 3000000.0,
				"icon": "🥣"
			},
			{
				"id": "celad",
				"name": "청자",
				"price": 15000.0,
				"time": 8.0,
				"cost": 18000000.0,
				"icon": "🫖"
			},
			{
				"id": "steamr",
				"name": "시루",
				"price": 22700.0,
				"time": 8.7,
				"cost": 40000000.0,
				"icon": "🫕"
			},
			{
				"id": "bottle",
				"name": "술병",
				"price": 34500.0,
				"time": 9.4,
				"cost": 3000000000.0,
				"icon": "🍶"
			},
			{
				"id": "teaset",
				"name": "다기",
				"price": 52300.0,
				"time": 10.2,
				"cost": 5000000000.0,
				"icon": "🍵"
			},
			{
				"id": "censer",
				"name": "향로",
				"price": 79000.0,
				"time": 11.0,
				"cost": 500000000000.0,
				"icon": "🪔"
			},
			{
				"id": "moonjr",
				"name": "달항아리",
				"price": 120000.0,
				"time": 11.8,
				"cost": 800000000000.0,
				"icon": "🌕"
			}
		]
	},
	{
		"id": "herb",
		"name": "약재상",
		"sign": "藥",
		"cost": 45000000.0,
		"desc": "산에서 캔 것을 말리고 썬다",
		"color": "#4a5f7a",
		"ranks": [
			"햇",
			"묵은",
			"천년"
		],
		"promote": [
			3000000000.0,
			100000000000.0
		],
		"items": [
			{
				"id": "root",
				"name": "도라지",
				"price": 5000.0,
				"time": 5.6,
				"cost": 0.0,
				"icon": "🌿"
			},
			{
				"id": "ginseng",
				"name": "산삼",
				"price": 12000.0,
				"time": 7.0,
				"cost": 100000000.0,
				"icon": "🌱"
			},
			{
				"id": "antler",
				"name": "녹용",
				"price": 28000.0,
				"time": 8.4,
				"cost": 1000000000.0,
				"icon": "🦌"
			},
			{
				"id": "bezoar",
				"name": "우황",
				"price": 65000.0,
				"time": 9.5,
				"cost": 1500000000.0,
				"icon": "💊"
			},
			{
				"id": "danggui",
				"name": "당귀",
				"price": 95000.0,
				"time": 10.3,
				"cost": 6000000000.0,
				"icon": "🍂"
			},
			{
				"id": "reishi",
				"name": "영지",
				"price": 139000.0,
				"time": 11.1,
				"cost": 9000000000.0,
				"icon": "🍄"
			},
			{
				"id": "agar",
				"name": "침향",
				"price": 204000.0,
				"time": 12.0,
				"cost": 1300000000000.0,
				"icon": "🪵"
			},
			{
				"id": "elixir",
				"name": "경옥고",
				"price": 300000.0,
				"time": 12.9,
				"cost": 2000000000000.0,
				"icon": "🍯"
			}
		]
	}
]

const SMALL_SHOPS := [
	{
		"id": "store1",
		"name": "점포",
		"k": "store",
		"cost": 400.0
	},
	{
		"id": "inn",
		"name": "주막",
		"k": "inn",
		"cost": 12000.0
	},
	{
		"id": "cart",
		"name": "포장마차",
		"k": "cart",
		"cost": 300000.0
	},
	{
		"id": "store2",
		"name": "점포",
		"k": "store",
		"cost": 12000000.0
	}
]

const STAFF := {
	"capAdd": 10.0,
	"max": 1.0,
	"costMul": [
		0.12
	]
}

const STOCK_CAP := 40.0

