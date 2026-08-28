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

const BUILD_RUSH_PER := 1800.0

const CARD_GRADES := [
	{
		"id": 1.0,
		"name": "베이직",
		"face": "⚪",
		"color": "#b3a992"
	},
	{
		"id": 2.0,
		"name": "레어",
		"face": "🟢",
		"color": "#6f8a5c"
	},
	{
		"id": 3.0,
		"name": "에픽",
		"face": "🔵",
		"color": "#4a7c9e"
	},
	{
		"id": 4.0,
		"name": "유니크",
		"face": "🟣",
		"color": "#8a5c9e"
	},
	{
		"id": 5.0,
		"name": "레전드",
		"face": "🟠",
		"color": "#c78a3f"
	},
	{
		"id": 6.0,
		"name": "신화",
		"face": "🔴",
		"color": "#c7563f"
	}
]

const CRAFT := {
	"handSpeed": 3.5,
	"walk": 1.4,
	"regrip": 2.5
}

const DAY := {
	"cycle": 2400.0,
	"night": [
		0.62,
		0.92
	],
	"nightCome": 2.0,
	"nightCraft": 1.35,
	"nightPest": 0.55
}

const DISTRICTS := [
	{
		"id": "angol",
		"name": "안골",
		"rows": [
			0.0,
			17.0
		],
		"cost": 0.0,
		"stars": 0.0,
		"shops": [
			"smith",
			"brush",
			"paper",
			"pot",
			"herb",
			"soup"
		],
		"desc": "처음부터 열려 있는 마을 안쪽"
	},
	{
		"id": "jeoja",
		"name": "저잣거리",
		"rows": [
			18.0,
			29.0
		],
		"cost": 50000000.0,
		"stars": 10.0,
		"shops": [
			"gaekju",
			"skewer",
			"ricecake",
			"fruit"
		],
		"desc": "객주와 먹거리 가게가 늘어선 아랫동네"
	},
	{
		"id": "keunjang",
		"name": "큰장마당",
		"rows": [
			30.0,
			47.0
		],
		"cost": 15000000000.0,
		"stars": 33.0,
		"shops": [
			"fish",
			"cloth",
			"hat",
			"brass",
			"lacquer"
		],
		"desc": "팔도의 물산이 모이는 큰 장"
	}
]

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

const GACHA := {
	"cost": [
		{
			"n": 1.0,
			"gems": 1.0
		},
		{
			"n": 10.0,
			"gems": 9.0
		},
		{
			"n": 30.0,
			"gems": 25.0
		}
	],
	"levelAt": [
		0.0,
		10.0,
		40.0,
		100.0,
		200.0,
		350.0,
		600.0,
		1000.0,
		1700.0,
		3000.0
	],
	"rates": [
		[
			100.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
		],
		[
			95.0,
			5.0,
			0.0,
			0.0,
			0.0,
			0.0
		],
		[
			88.0,
			11.0,
			1.0,
			0.0,
			0.0,
			0.0
		],
		[
			80.0,
			17.0,
			3.0,
			0.0,
			0.0,
			0.0
		],
		[
			70.0,
			23.0,
			6.0,
			1.0,
			0.0,
			0.0
		],
		[
			60.0,
			28.0,
			10.0,
			2.0,
			0.0,
			0.0
		],
		[
			50.0,
			31.0,
			15.0,
			3.5,
			0.5,
			0.0
		],
		[
			40.0,
			33.0,
			20.0,
			6.0,
			1.0,
			0.0
		],
		[
			30.0,
			33.0,
			26.0,
			9.0,
			1.8,
			0.2
		],
		[
			20.0,
			32.0,
			32.0,
			13.0,
			2.5,
			0.5
		]
	],
	"tenPity": 2.0
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
	},
	{
		"id": "walk",
		"name": "손님 걸음",
		"face": "👣",
		"max": 20.0,
		"step": 0.0275,
		"costMul": 5.0,
		"desc": "손님이 오는 걸음 +2.75%p (45% → 100%)"
	},
	{
		"id": "carry",
		"name": "너구리 걸음",
		"face": "🏃",
		"max": 20.0,
		"step": 0.01,
		"costMul": 5.0,
		"desc": "너구리가 걷고 나르는 속도 +1%"
	},
	{
		"id": "night",
		"name": "밤일 익숙",
		"face": "🌙",
		"max": 20.0,
		"step": 0.01,
		"costMul": 5.0,
		"desc": "밤에 손이 느려지는 정도 −1%p"
	},
	{
		"id": "rainy",
		"name": "비 오는 날 장사",
		"face": "🌧️",
		"max": 20.0,
		"step": 0.01,
		"costMul": 5.0,
		"desc": "비 올 때 줄어드는 발길 −1%p"
	},
	{
		"id": "offtime",
		"name": "오프라인 시간",
		"face": "🛏️",
		"max": 20.0,
		"step": 1080.0,
		"costMul": 10.0,
		"desc": "자리 비운 벌이를 쳐주는 시간 +18분 (2시간 → 8시간)"
	},
	{
		"id": "offrate",
		"name": "오프라인 배율",
		"face": "💰",
		"max": 20.0,
		"step": 0.025,
		"costMul": 10.0,
		"desc": "자리 비운 벌이 +2.5%p (50% → 100%)"
	},
	{
		"id": "offleaf",
		"name": "오프라인 나뭇잎",
		"face": "🍃",
		"max": 20.0,
		"step": 0.05,
		"costMul": 10.0,
		"desc": "자리 비운 동안 모이는 나뭇잎 +5%"
	},
	{
		"id": "questpay",
		"name": "의뢰 보상",
		"face": "📜",
		"max": 20.0,
		"step": 0.025,
		"costMul": 10.0,
		"desc": "의뢰 보상 엽전 +2.5%p (90% → 140%)"
	},
	{
		"id": "questleaf",
		"name": "의뢰 나뭇잎",
		"face": "🌿",
		"max": 20.0,
		"step": 0.05,
		"costMul": 10.0,
		"desc": "의뢰가 주는 나뭇잎 +5%"
	},
	{
		"id": "questslot",
		"name": "의뢰 자리",
		"face": "📋",
		"max": 4.0,
		"step": 1.0,
		"cost": [
			100.0,
			300.0,
			600.0,
			1000.0
		],
		"desc": "동시에 받는 의뢰 +1 (1 → 5)"
	}
]

const GUARD := {
	"id": "dog",
	"name": "삽살개",
	"face": "🐕",
	"cost": 25000.0,
	"costMul": 2.2,
	"perShops": 4.0,
	"rate": 0.6,
	"fine": 3.0,
	"rateCap": 0.9,
	"desc": "마당을 지키며 나쁜 놈을 대신 물어 잡는다"
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
		"grade": 1.0,
		"wild": 0.25,
		"at": 0.0,
		"desc": "4.6초마다 와서 최대 3개, 제값을 낸다",
		"look": "흰 털에 귀끝만 갈색, 등에 장보기 보따리를 짊어졌다"
	},
	{
		"id": "magpie",
		"name": "까치",
		"face": "🐦‍⬛",
		"every": 3.1,
		"qty": 2.0,
		"pay": 0.85,
		"spread": 2.0,
		"speed": 1.7,
		"grade": 1.0,
		"wild": 0.25,
		"at": 5800.0,
		"desc": "3.1초마다 오는 흥정꾼 — 값을 15% 깎는다",
		"look": "검고 흰 깃, 부리에 엽전 꾸러미를 문 동네 흥정꾼"
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
		"grade": 1.0,
		"wild": 0.3,
		"at": 180000.0,
		"desc": "4.2초마다 잰걸음으로 와서 한두 개, 값은 15% 더 쳐준다",
		"look": "줄무늬 등, 도토리 망태기를 멘 야무진 손"
	},
	{
		"id": "hedgehog",
		"name": "고슴도치",
		"face": "🦔",
		"every": 17.0,
		"qty": 5.0,
		"pay": 1.5,
		"spread": 3.0,
		"speed": 0.9,
		"grade": 2.0,
		"wild": 0.3,
		"at": 10000000.0,
		"desc": "17초마다 조심스레 골라 최대 5개, 값은 1.5배",
		"look": "등가시에 산 것을 꽂아 나른다, 조심스러운 걸음"
	},
	{
		"id": "otter",
		"name": "수달",
		"face": "🦦",
		"every": 32.0,
		"qty": 8.0,
		"pay": 1.2,
		"spread": 3.0,
		"speed": 1.35,
		"grade": 2.0,
		"wild": 0.4,
		"at": 120000000.0,
		"desc": "32초마다 와서 만져 보고 고른다 — 최대 8개, 값은 1.2배",
		"look": "매끈한 물빛 털, 물건을 앞발로 조몰락거려 보고 산다"
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
		"grade": 3.0,
		"wild": 0.5,
		"at": 1700000000.0,
		"desc": "50초마다 점잖게 와서 최대 9개, 값을 2.8배로 후하게 친다",
		"look": "늘씬한 목에 점잖은 걸음, 값을 묻지 않고 후하게 쳐준다"
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
		"grade": 3.0,
		"wild": 0.6,
		"at": 5400000000.0,
		"desc": "80초마다 와서 한 종류를 최대 12개까지 쓸어간다, 값은 2.2배",
		"look": "우락부락한 어깨, 마음에 든 것을 통째로 쓸어 담는다"
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
		"grade": 4.0,
		"wild": 0.7,
		"at": 17000000000.0,
		"desc": "120초마다 와서 매대를 비운다 — 최대 16개, 값은 4배",
		"look": "산만한 덩치, 매대를 통째로 비우고 어슬렁 간다"
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
		"grade": 4.0,
		"wild": 0.8,
		"at": 44000000000.0,
		"desc": "110초마다 아주 느리게 와서 최대 14개, 값은 7배",
		"look": "등딱지에 보따리를 얹고 아주 천천히, 씀씀이는 크다"
	},
	{
		"id": "falcon",
		"name": "매",
		"face": "🦅",
		"every": 145.0,
		"qty": 16.0,
		"pay": 6.0,
		"spread": 4.0,
		"speed": 1.1,
		"grade": 5.0,
		"wild": 0.8,
		"at": 69000000000.0,
		"desc": "145초마다 날개를 접고 내려앉는다 — 최대 16개, 값은 6배",
		"look": "날개를 접고 꼿꼿이 선 매, 꽁지에 주인 이름을 적은 시치미를 달았다"
	},
	{
		"id": "ox",
		"name": "소",
		"face": "🐄",
		"every": 260.0,
		"qty": 26.0,
		"pay": 5.0,
		"spread": 3.0,
		"speed": 0.4,
		"grade": 5.0,
		"wild": 0.9,
		"at": 160000000000.0,
		"desc": "260초마다 느릿느릿 와서 최대 26개, 값은 5배",
		"look": "등에 길마를 얹은 황소, 목에 건 워낭이 걸음마다 울린다"
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
		"grade": 6.0,
		"wild": 1.0,
		"at": 300000000000.0,
		"desc": "400초마다 어쩌다 오지만 한 번에 최대 34개, 값은 13배",
		"look": "민화에서 나온 듯한 줄무늬 산군님, 곰방대를 물었다"
	},
	{
		"id": "sparrow",
		"name": "참새",
		"face": "🐦",
		"every": 2.8,
		"qty": 1.0,
		"pay": 0.9,
		"spread": 1.0,
		"speed": 1.8,
		"grade": 1.0,
		"wild": 0.2,
		"at": 999000000000000.0,
		"desc": "2.8초마다 쉴 새 없이 오지만 한 개씩만 집는다. 값은 10% 깎는다",
		"look": "통통한 몸에 낟알 주머니 하나, 재잘거리며 종종거린다"
	},
	{
		"id": "dog",
		"name": "개",
		"face": "🐶",
		"every": 5.5,
		"qty": 3.0,
		"pay": 1.0,
		"spread": 2.0,
		"speed": 1.0,
		"grade": 1.0,
		"wild": 0.3,
		"at": 999000000000000.0,
		"desc": "5.5초마다 주인 심부름으로 와서 최대 3개",
		"look": "누런 털에 순한 눈, 등에 장바구니를 지고 종종 따라온다"
	},
	{
		"id": "hen",
		"name": "닭",
		"face": "🐔",
		"every": 6.0,
		"qty": 4.0,
		"pay": 0.95,
		"spread": 1.0,
		"speed": 0.7,
		"grade": 1.0,
		"wild": 0.3,
		"at": 999000000000000.0,
		"desc": "6초마다 종종거리며 와서 최대 4개, 값은 5% 깎는다",
		"look": "붉은 볏에 통통한 몸, 모이 쪼듯 골라 담는다"
	},
	{
		"id": "cat",
		"name": "고양이",
		"face": "🐱",
		"every": 5.0,
		"qty": 2.0,
		"pay": 1.1,
		"spread": 2.0,
		"speed": 0.9,
		"grade": 1.0,
		"wild": 0.25,
		"at": 999000000000000.0,
		"desc": "5초마다 느긋하게 와서 마음에 든 것 한두 개, 값은 10% 더 쳐준다",
		"look": "윤나는 털에 꼿꼿한 꼬리, 마음에 드는 것 앞에서만 걸음을 멈춘다"
	},
	{
		"id": "duck",
		"name": "오리",
		"face": "🦆",
		"every": 4.0,
		"qty": 3.0,
		"pay": 0.9,
		"spread": 3.0,
		"speed": 1.1,
		"grade": 1.0,
		"wild": 0.3,
		"at": 999000000000000.0,
		"desc": "뒤뚱뒤뚱 4초마다 와서 최대 3개, 값은 10% 깎는다",
		"look": "노란 부리에 뒤뚱거리는 걸음, 물갈퀴에 진 물자국을 남긴다"
	},
	{
		"id": "badger",
		"name": "오소리",
		"face": "🦡",
		"every": 14.0,
		"qty": 4.0,
		"pay": 1.6,
		"spread": 2.0,
		"speed": 1.3,
		"grade": 2.0,
		"wild": 0.35,
		"at": 999000000000000.0,
		"desc": "14초마다 부지런히 오간다 — 최대 4개, 값은 1.6배",
		"look": "두툼한 몸에 곰방대, 하루에도 몇 번씩 들르는 동네 어르신"
	},
	{
		"id": "frog",
		"name": "개구리",
		"face": "🐸",
		"every": 20.0,
		"qty": 6.0,
		"pay": 1.4,
		"spread": 3.0,
		"speed": 1.5,
		"grade": 2.0,
		"wild": 0.35,
		"at": 999000000000000.0,
		"desc": "20초마다 폴짝폴짝 와서 최대 6개. 비 오는 날에는 1.8배로 자주 온다",
		"look": "연둣빛 몸에 연잎 삿갓, 비 오는 날이 제일 신난다",
		"wx": "rain",
		"wxMul": 1.8
	},
	{
		"id": "weasel",
		"name": "족제비",
		"face": "🦫",
		"every": 12.0,
		"qty": 3.0,
		"pay": 1.8,
		"spread": 1.0,
		"speed": 1.6,
		"grade": 2.0,
		"wild": 0.4,
		"at": 999000000000000.0,
		"desc": "12초마다 재빠르게 와서 좋은 것만 최대 3개, 값은 1.8배",
		"look": "길쭉한 몸에 빠른 눈, 좋은 것만 골라 채간다"
	},
	{
		"id": "fox",
		"name": "여우",
		"face": "🦊",
		"every": 26.0,
		"qty": 7.0,
		"pay": 1.5,
		"spread": 2.0,
		"speed": 1.45,
		"grade": 2.0,
		"wild": 0.4,
		"at": 999000000000000.0,
		"desc": "26초마다 재빠르게 와서 최대 7개, 값은 1.5배",
		"look": "붉은 털에 눈웃음, 값을 흥정할 때 꼬리가 살랑인다"
	},
	{
		"id": "sheep",
		"name": "양",
		"face": "🐑",
		"every": 38.0,
		"qty": 9.0,
		"pay": 1.35,
		"spread": 4.0,
		"speed": 0.85,
		"grade": 2.0,
		"wild": 0.45,
		"at": 999000000000000.0,
		"desc": "38초마다 느긋하게 와서 최대 9개, 값은 1.35배",
		"look": "도톰한 털뭉치, 느릿느릿 두루 살피다 한 아름 사 간다"
	},
	{
		"id": "pig",
		"name": "돼지",
		"face": "🐷",
		"every": 45.0,
		"qty": 9.0,
		"pay": 2.4,
		"spread": 2.0,
		"speed": 1.55,
		"grade": 3.0,
		"wild": 0.55,
		"at": 999000000000000.0,
		"desc": "45초마다 — 먹을 것 앞에서는 잰걸음이다. 최대 9개, 값은 2.4배",
		"look": "통통한 분홍 몸에 들뜬 콧구멍, 먹을거리 앞에서 걸음이 빨라진다"
	},
	{
		"id": "mandarin",
		"name": "원앙",
		"face": "🦚",
		"every": 60.0,
		"qty": 10.0,
		"pay": 3.0,
		"spread": 2.0,
		"speed": 1.25,
		"grade": 3.0,
		"wild": 0.5,
		"at": 999000000000000.0,
		"desc": "60초마다 곱게 차려입고 와서 최대 10개, 값은 3배",
		"look": "오색 깃을 곱게 세운 한 마리, 혼례에 쓸 것을 고른다"
	},
	{
		"id": "owl",
		"name": "부엉이",
		"face": "🦉",
		"every": 70.0,
		"qty": 13.0,
		"pay": 2.6,
		"spread": 1.0,
		"speed": 1.3,
		"grade": 3.0,
		"wild": 0.6,
		"at": 999000000000000.0,
		"desc": "70초마다 조용히 와서 최대 13개, 값은 2.6배",
		"look": "동그란 눈에 뭉툭한 몸, 밤눈이 밝은 큰손"
	},
	{
		"id": "horse",
		"name": "말",
		"face": "🐴",
		"every": 95.0,
		"qty": 14.0,
		"pay": 3.2,
		"spread": 4.0,
		"speed": 1.15,
		"grade": 3.0,
		"wild": 0.65,
		"at": 999000000000000.0,
		"desc": "95초마다 와서 한 짐 최대 14개, 값은 3.2배",
		"look": "윤나는 갈기에 안장 자국, 등에 짐을 잔뜩 싣고 간다"
	},
	{
		"id": "leopard",
		"name": "표범",
		"face": "🐆",
		"every": 100.0,
		"qty": 15.0,
		"pay": 5.0,
		"spread": 2.0,
		"speed": 1.5,
		"grade": 4.0,
		"wild": 0.7,
		"at": 999000000000000.0,
		"desc": "100초마다 드물게 나타나 최대 15개, 값은 5배",
		"look": "금빛 무늬 털, 값을 묻지 않고 사 간다"
	},
	{
		"id": "wolf",
		"name": "늑대",
		"face": "🐺",
		"every": 130.0,
		"qty": 13.0,
		"pay": 8.0,
		"spread": 3.0,
		"speed": 1.0,
		"grade": 4.0,
		"wild": 0.75,
		"at": 999000000000000.0,
		"desc": "130초마다 정해 둔 것만 사러 온다 — 최대 13개, 값은 8배",
		"look": "잿빛 털에 곧은 눈, 정한 것만 사 가는 외골수"
	},
	{
		"id": "moonbear",
		"name": "반달곰",
		"face": "🐻‍❄️",
		"every": 150.0,
		"qty": 20.0,
		"pay": 4.5,
		"spread": 1.0,
		"speed": 0.75,
		"grade": 4.0,
		"wild": 0.75,
		"at": 999000000000000.0,
		"desc": "150초마다 와서 한 종류를 최대 20개까지, 값은 4.5배",
		"look": "가슴의 흰 반달, 마음에 든 한 종류만 통째로"
	},
	{
		"id": "elephant",
		"name": "코끼리",
		"face": "🐘",
		"every": 300.0,
		"qty": 24.0,
		"pay": 9.0,
		"spread": 3.0,
		"speed": 0.9,
		"grade": 5.0,
		"wild": 0.9,
		"at": 999000000000000.0,
		"desc": "300초마다 어쩌다 나타나 최대 24개, 값은 9배",
		"look": "먼 나라에서 바친 짐승 — 장터가 통째로 술렁인다"
	}
]

const GUEST_WALK := 0.45

const LEDGER := {
	"dayMinutes": 8.0,
	"daysPerFair": 5.0,
	"keepDays": 10.0,
	"topItems": 6.0,
	"topBuyers": 4.0
}

const LEVEL := {
	"costGrowth": 1.09,
	"priceStep": 0.12,
	"timeReduce": 0.985,
	"timeFloor": 0.8
}

const MAX_BULK := 1000.0

const MILESTONE_EVERY := 25.0

const MILESTONE_MULT := 1.25

const OFFLINE := {
	"capHours": 2.0,
	"efficiency": 0.5
}

const OFFLINE_DICE := {
	"free": 1.0,
	"ad": 3.0,
	"faces": [
		{
			"mult": 1.0,
			"weight": 30.0
		},
		{
			"mult": 2.0,
			"weight": 25.0
		},
		{
			"mult": 3.0,
			"weight": 20.0
		},
		{
			"mult": 4.0,
			"weight": 12.0
		},
		{
			"mult": 5.0,
			"weight": 8.0
		},
		{
			"mult": 6.0,
			"weight": 5.0
		}
	]
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
	"slots": 1.0,
	"every": 90.0,
	"first": 240.0,
	"seconds": 300.0,
	"min": 3.0,
	"payMul": 0.9,
	"gemPerStar": 6.0,
	"gemCap": 5.0
}

const RANKS := [
	{
		"maxLv": 30.0,
		"priceMul": 1.0,
		"guests": 0.0,
		"ips": 0.0,
		"build": 0.0
	},
	{
		"maxLv": 60.0,
		"priceMul": 4.0,
		"guests": 10.0,
		"ips": 15000.0,
		"build": 14400.0
	},
	{
		"maxLv": 100.0,
		"priceMul": 16.0,
		"guests": 40.0,
		"ips": 800000.0,
		"build": 28800.0
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

const REGULAR_COME := 0.05

const ROULETTE := {
	"freePerDay": 1.0,
	"adPerDay": 3.0,
	"adSeconds": 2.0,
	"wedges": [
		{
			"kind": "coin",
			"amount": 30.0,
			"weight": 18.0,
			"label": "엽전 한 줌"
		},
		{
			"kind": "gem",
			"amount": 3.0,
			"weight": 14.0,
			"label": "🍃 3"
		},
		{
			"kind": "coin",
			"amount": 180.0,
			"weight": 12.0,
			"label": "엽전 한 꾸러미"
		},
		{
			"kind": "card",
			"amount": 1.0,
			"weight": 10.0,
			"label": "손님 카드 1장"
		},
		{
			"kind": "coin",
			"amount": 30.0,
			"weight": 12.0,
			"label": "엽전 한 줌"
		},
		{
			"kind": "gem",
			"amount": 5.0,
			"weight": 9.0,
			"label": "🍃 5"
		},
		{
			"kind": "coin",
			"amount": 600.0,
			"weight": 6.0,
			"label": "엽전 한 자루"
		},
		{
			"kind": "card",
			"amount": 2.0,
			"weight": 5.0,
			"label": "손님 카드 2장"
		},
		{
			"kind": "gem",
			"amount": 10.0,
			"weight": 5.0,
			"label": "🍃 10"
		},
		{
			"kind": "coin",
			"amount": 1800.0,
			"weight": 4.0,
			"label": "엽전 한 궤"
		},
		{
			"kind": "card",
			"amount": 5.0,
			"weight": 3.0,
			"label": "손님 카드 5장"
		},
		{
			"kind": "gem",
			"amount": 30.0,
			"weight": 2.0,
			"label": "🍃 30"
		}
	]
}

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
			3000000.0,
			1500000000.0
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
				"cost": 1200000.0,
				"icon": "✂️"
			},
			{
				"id": "knife",
				"name": "부엌칼",
				"price": 1900.0,
				"time": 7.2,
				"cost": 3600000.0,
				"icon": "🔪"
			},
			{
				"id": "lock",
				"name": "자물쇠",
				"price": 5000.0,
				"time": 8.0,
				"cost": 600000000.0,
				"icon": "🔒"
			},
			{
				"id": "cauldr",
				"name": "가마솥",
				"price": 13000.0,
				"time": 8.8,
				"cost": 1800000000.0,
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
			85000000.0,
			15000000000.0
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
				"cost": 34000000.0,
				"icon": "🗃️"
			},
			{
				"id": "bookmk",
				"name": "서산",
				"price": 12700.0,
				"time": 8.3,
				"cost": 100000000.0,
				"icon": "🔖"
			},
			{
				"id": "brushrk",
				"name": "붓걸이",
				"price": 19400.0,
				"time": 9.0,
				"cost": 6000000000.0,
				"icon": "🪝"
			},
			{
				"id": "album",
				"name": "화첩",
				"price": 30000.0,
				"time": 9.8,
				"cost": 18000000000.0,
				"icon": "📖"
			}
		]
	},
	{
		"id": "paper",
		"name": "지물포",
		"sign": "紙",
		"cost": 100000.0,
		"desc": "닥나무를 떠서 종이를 만든다",
		"color": "#8a7440",
		"ranks": [
			"막",
			"고운",
			"진상"
		],
		"promote": [
			150000000.0,
			30000000000.0
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
				"cost": 60000000.0,
				"icon": "🪁"
			},
			{
				"id": "umbrel",
				"name": "지우산",
				"price": 25500.0,
				"time": 9.3,
				"cost": 180000000.0,
				"icon": "☂️"
			},
			{
				"id": "lantrn",
				"name": "지등",
				"price": 39000.0,
				"time": 10.1,
				"cost": 12000000000.0,
				"icon": "🏮"
			},
			{
				"id": "screen",
				"name": "병풍",
				"price": 60000.0,
				"time": 10.9,
				"cost": 36000000000.0,
				"icon": "🖼️"
			}
		]
	},
	{
		"id": "pot",
		"name": "옹기점",
		"sign": "甕",
		"cost": 2000000.0,
		"desc": "흙을 빚어 항아리를 굽는다",
		"color": "#6b4a3a",
		"ranks": [
			"질",
			"오지",
			"왕실"
		],
		"promote": [
			350000000.0,
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
				"cost": 140000000.0,
				"icon": "🍶"
			},
			{
				"id": "teaset",
				"name": "다기",
				"price": 52300.0,
				"time": 10.2,
				"cost": 420000000.0,
				"icon": "🍵"
			},
			{
				"id": "censer",
				"name": "향로",
				"price": 79000.0,
				"time": 11.0,
				"cost": 24000000000.0,
				"icon": "🪔"
			},
			{
				"id": "moonjr",
				"name": "달항아리",
				"price": 120000.0,
				"time": 11.8,
				"cost": 72000000000.0,
				"icon": "🌕"
			}
		]
	},
	{
		"id": "herb",
		"name": "약재상",
		"sign": "藥",
		"cost": 15000000.0,
		"desc": "산에서 캔 것을 말리고 썬다",
		"color": "#4a5f7a",
		"ranks": [
			"햇",
			"묵은",
			"천년"
		],
		"promote": [
			850000000.0,
			150000000000.0
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
				"id": "hasuo",
				"name": "하수오",
				"price": 28000.0,
				"time": 8.4,
				"cost": 1000000000.0,
				"icon": "🌿"
			},
			{
				"id": "gamcho",
				"name": "감초",
				"price": 65000.0,
				"time": 9.5,
				"cost": 1500000000.0,
				"icon": "🌱"
			},
			{
				"id": "danggui",
				"name": "당귀",
				"price": 95000.0,
				"time": 10.3,
				"cost": 340000000.0,
				"icon": "🍂"
			},
			{
				"id": "reishi",
				"name": "영지",
				"price": 139000.0,
				"time": 11.1,
				"cost": 1000000000.0,
				"icon": "🍄"
			},
			{
				"id": "agar",
				"name": "침향",
				"price": 204000.0,
				"time": 12.0,
				"cost": 60000000000.0,
				"icon": "🪵"
			},
			{
				"id": "elixir",
				"name": "경옥고",
				"price": 300000.0,
				"time": 12.9,
				"cost": 180000000000.0,
				"icon": "🍯"
			}
		]
	},
	{
		"id": "soup",
		"name": "국밥집",
		"sign": "湯",
		"cost": 40000000.0,
		"desc": "뜨끈한 국밥 한 그릇을 만다",
		"color": "#8a6a45",
		"ranks": [
			"된장",
			"들깨",
			"송이"
		],
		"promote": [
			2500000000.0,
			900000000000.0
		],
		"items": [
			{
				"id": "bap",
				"name": "국밥",
				"price": 10000.0,
				"time": 6.2,
				"cost": 0.0,
				"icon": "🍲"
			},
			{
				"id": "kuk",
				"name": "장국",
				"price": 27000.0,
				"time": 7.0,
				"cost": 1200000.0,
				"icon": "🥣"
			},
			{
				"id": "sujebi",
				"name": "수제비",
				"price": 71000.0,
				"time": 7.8,
				"cost": 3200000.0,
				"icon": "🥟"
			},
			{
				"id": "naeng",
				"name": "냉국",
				"price": 180000.0,
				"time": 8.6,
				"cost": 8100000.0,
				"icon": "🧊"
			},
			{
				"id": "kongguk",
				"name": "콩국",
				"price": 480000.0,
				"time": 9.4,
				"cost": 1000000000.0,
				"icon": "🥛"
			},
			{
				"id": "deulkkae",
				"name": "들깨탕",
				"price": 1200000.0,
				"time": 10.2,
				"cost": 3000000000.0,
				"icon": "🥣"
			},
			{
				"id": "jeongol",
				"name": "버섯전골",
				"price": 3200000.0,
				"time": 11.0,
				"cost": 360000000000.0,
				"icon": "🍲"
			},
			{
				"id": "yeonip",
				"name": "연잎밥",
				"price": 8400000.0,
				"time": 11.8,
				"cost": 1100000000000.0,
				"icon": "🍚"
			}
		]
	},
	{
		"id": "gaekju",
		"name": "객주",
		"sign": "客",
		"cost": 80000000.0,
		"desc": "길손을 재우고 술과 안주를 낸다",
		"color": "#8a6a45",
		"ranks": [
			"막",
			"청",
			"법"
		],
		"promote": [
			5000000000.0,
			2000000000000.0
		],
		"items": [
			{
				"id": "makgeol",
				"name": "막걸리",
				"price": 22000.0,
				"time": 6.8,
				"cost": 0.0,
				"icon": "🍶"
			},
			{
				"id": "jeon",
				"name": "파전",
				"price": 57000.0,
				"time": 7.6,
				"cost": 2600000.0,
				"icon": "🥞"
			},
			{
				"id": "dongdong",
				"name": "동동주",
				"price": 150000.0,
				"time": 8.4,
				"cost": 6800000.0,
				"icon": "🍯"
			},
			{
				"id": "muk",
				"name": "묵무침",
				"price": 390000.0,
				"time": 9.2,
				"cost": 18000000.0,
				"icon": "🥗"
			},
			{
				"id": "cheongju",
				"name": "청주",
				"price": 1000000.0,
				"time": 10.0,
				"cost": 2000000000.0,
				"icon": "🍾"
			},
			{
				"id": "modeum",
				"name": "모둠전",
				"price": 2600000.0,
				"time": 10.8,
				"cost": 6000000000.0,
				"icon": "🥘"
			},
			{
				"id": "beopju",
				"name": "법주",
				"price": 6800000.0,
				"time": 11.6,
				"cost": 800000000000.0,
				"icon": "🏺"
			},
			{
				"id": "gujeol",
				"name": "구절판",
				"price": 18000000.0,
				"time": 12.4,
				"cost": 2400000000000.0,
				"icon": "🍱"
			}
		]
	},
	{
		"id": "skewer",
		"name": "꼬치집",
		"sign": "串",
		"cost": 250000000.0,
		"desc": "숯불에 꿰어 굽는다",
		"color": "#8a6a45",
		"ranks": [
			"숯",
			"참숯",
			"백탄"
		],
		"promote": [
			10000000000.0,
			4000000000000.0
		],
		"items": [
			{
				"id": "tteokggo",
				"name": "떡꼬치",
				"price": 46000.0,
				"time": 7.4,
				"cost": 0.0,
				"icon": "🍡"
			},
			{
				"id": "gamja",
				"name": "감자꼬치",
				"price": 120000.0,
				"time": 8.2,
				"cost": 5400000.0,
				"icon": "🥔"
			},
			{
				"id": "beoseot",
				"name": "버섯꼬치",
				"price": 310000.0,
				"time": 9.0,
				"cost": 14000000.0,
				"icon": "🍄"
			},
			{
				"id": "saengseon",
				"name": "생선꼬치",
				"price": 810000.0,
				"time": 9.8,
				"cost": 36000000.0,
				"icon": "🐠"
			},
			{
				"id": "eunhaeng",
				"name": "은행꼬치",
				"price": 2100000.0,
				"time": 10.6,
				"cost": 4000000000.0,
				"icon": "🌰"
			},
			{
				"id": "jangeo",
				"name": "장어구이",
				"price": 5500000.0,
				"time": 11.4,
				"cost": 12000000000.0,
				"icon": "🐍"
			},
			{
				"id": "deodeok",
				"name": "더덕구이",
				"price": 14000000.0,
				"time": 12.2,
				"cost": 1600000000000.0,
				"icon": "🌿"
			},
			{
				"id": "songi",
				"name": "송이꼬치",
				"price": 37000000.0,
				"time": 13.0,
				"cost": 4800000000000.0,
				"icon": "🍄"
			}
		]
	},
	{
		"id": "ricecake",
		"name": "떡집",
		"sign": "餠",
		"cost": 1000000000.0,
		"desc": "쌀을 쳐서 떡을 빚는다",
		"color": "#8a6a45",
		"ranks": [
			"햅쌀",
			"찹쌀",
			"진상"
		],
		"promote": [
			20000000000.0,
			8500000000000.0
		],
		"items": [
			{
				"id": "garae",
				"name": "가래떡",
				"price": 97000.0,
				"time": 8.0,
				"cost": 0.0,
				"icon": "🍥"
			},
			{
				"id": "injeol",
				"name": "인절미",
				"price": 250000.0,
				"time": 8.8,
				"cost": 11000000.0,
				"icon": "🍡"
			},
			{
				"id": "songpyeon",
				"name": "송편",
				"price": 660000.0,
				"time": 9.6,
				"cost": 30000000.0,
				"icon": "🥠"
			},
			{
				"id": "baekseol",
				"name": "백설기",
				"price": 1700000.0,
				"time": 10.4,
				"cost": 76000000.0,
				"icon": "🍚"
			},
			{
				"id": "yaksik",
				"name": "약식",
				"price": 4400000.0,
				"time": 11.2,
				"cost": 8000000000.0,
				"icon": "🍯"
			},
			{
				"id": "hwajeon",
				"name": "화전",
				"price": 12000000.0,
				"time": 12.0,
				"cost": 24000000000.0,
				"icon": "🌸"
			},
			{
				"id": "dasik",
				"name": "다식",
				"price": 30000000.0,
				"time": 12.8,
				"cost": 3400000000000.0,
				"icon": "🍪"
			},
			{
				"id": "yugwa",
				"name": "유과",
				"price": 78000000.0,
				"time": 13.6,
				"cost": 10000000000000.0,
				"icon": "🍬"
			}
		]
	},
	{
		"id": "fruit",
		"name": "과일전",
		"sign": "果",
		"cost": 6000000000.0,
		"desc": "철 따라 나는 과일을 골라 판다",
		"color": "#8a6a45",
		"ranks": [
			"풋",
			"햇",
			"꿀"
		],
		"promote": [
			45000000000.0,
			20000000000000.0
		],
		"items": [
			{
				"id": "chamoe",
				"name": "참외",
				"price": 200000.0,
				"time": 8.6,
				"cost": 0.0,
				"icon": "🍈"
			},
			{
				"id": "salgu",
				"name": "살구",
				"price": 530000.0,
				"time": 9.4,
				"cost": 24000000.0,
				"icon": "🍑"
			},
			{
				"id": "jadu",
				"name": "자두",
				"price": 1400000.0,
				"time": 10.2,
				"cost": 63000000.0,
				"icon": "🫐"
			},
			{
				"id": "boksung",
				"name": "복숭아",
				"price": 3600000.0,
				"time": 11.0,
				"cost": 160000000.0,
				"icon": "🍑"
			},
			{
				"id": "subak",
				"name": "수박",
				"price": 9300000.0,
				"time": 11.8,
				"cost": 18000000000.0,
				"icon": "🍉"
			},
			{
				"id": "hongsi",
				"name": "홍시",
				"price": 24000000.0,
				"time": 12.6,
				"cost": 54000000000.0,
				"icon": "🍊"
			},
			{
				"id": "yuja",
				"name": "유자",
				"price": 63000000.0,
				"time": 13.4,
				"cost": 8000000000000.0,
				"icon": "🍋"
			},
			{
				"id": "seokryu",
				"name": "석류",
				"price": 160000000.0,
				"time": 14.2,
				"cost": 24000000000000.0,
				"icon": "🍎"
			}
		]
	},
	{
		"id": "fish",
		"name": "어물전",
		"sign": "魚",
		"cost": 25000000000.0,
		"desc": "바닷것을 절이고 말려 판다",
		"color": "#8a6a45",
		"ranks": [
			"갯",
			"말린",
			"진상"
		],
		"promote": [
			95000000000.0,
			40000000000000.0
		],
		"items": [
			{
				"id": "gulbi",
				"name": "굴비",
				"price": 430000.0,
				"time": 9.2,
				"cost": 0.0,
				"icon": "🐟"
			},
			{
				"id": "miyeok",
				"name": "미역",
				"price": 1100000.0,
				"time": 10.0,
				"cost": 50000000.0,
				"icon": "🌿"
			},
			{
				"id": "jeotgal",
				"name": "젓갈",
				"price": 2900000.0,
				"time": 10.8,
				"cost": 130000000.0,
				"icon": "🫙"
			},
			{
				"id": "bugeo",
				"name": "북어",
				"price": 7500000.0,
				"time": 11.6,
				"cost": 340000000.0,
				"icon": "🎣"
			},
			{
				"id": "gim",
				"name": "김",
				"price": 20000000.0,
				"time": 12.4,
				"cost": 38000000000.0,
				"icon": "🍙"
			},
			{
				"id": "jaban",
				"name": "자반",
				"price": 51000000.0,
				"time": 13.2,
				"cost": 110000000000.0,
				"icon": "🐠"
			},
			{
				"id": "muneo",
				"name": "문어",
				"price": 130000000.0,
				"time": 14.0,
				"cost": 16000000000000.0,
				"icon": "🐙"
			},
			{
				"id": "jeonbok",
				"name": "전복",
				"price": 340000000.0,
				"time": 14.8,
				"cost": 48000000000000.0,
				"icon": "🦪"
			}
		]
	},
	{
		"id": "cloth",
		"name": "포목전",
		"sign": "布",
		"cost": 300000000000.0,
		"desc": "베를 짜고 물들여 판다",
		"color": "#8a6a45",
		"ranks": [
			"무명",
			"명주",
			"비단"
		],
		"promote": [
			200000000000.0,
			80000000000000.0
		],
		"items": [
			{
				"id": "mumyeong",
				"name": "무명",
				"price": 900000.0,
				"time": 9.8,
				"cost": 0.0,
				"icon": "🧵"
			},
			{
				"id": "sambe",
				"name": "삼베",
				"price": 2300000.0,
				"time": 10.6,
				"cost": 100000000.0,
				"icon": "🪢"
			},
			{
				"id": "mosi",
				"name": "모시",
				"price": 6100000.0,
				"time": 11.4,
				"cost": 270000000.0,
				"icon": "🎽"
			},
			{
				"id": "myeongju",
				"name": "명주",
				"price": 16000000.0,
				"time": 12.2,
				"cost": 720000000.0,
				"icon": "🧣"
			},
			{
				"id": "yeomnang",
				"name": "염낭",
				"price": 41000000.0,
				"time": 13.0,
				"cost": 80000000000.0,
				"icon": "👛"
			},
			{
				"id": "bidan",
				"name": "비단",
				"price": 110000000.0,
				"time": 13.8,
				"cost": 240000000000.0,
				"icon": "🎀"
			},
			{
				"id": "gwanbok",
				"name": "관복감",
				"price": 280000000.0,
				"time": 14.6,
				"cost": 32000000000000.0,
				"icon": "🥻"
			},
			{
				"id": "hollye",
				"name": "혼례비단",
				"price": 720000000.0,
				"time": 15.4,
				"cost": 96000000000000.0,
				"icon": "💒"
			}
		]
	},
	{
		"id": "hat",
		"name": "갓방",
		"sign": "笠",
		"cost": 1500000000000.0,
		"desc": "갓을 겯고 다듬어 판다",
		"color": "#8a6a45",
		"ranks": [
			"대",
			"중",
			"진상"
		],
		"promote": [
			400000000000.0,
			150000000000000.0
		],
		"items": [
			{
				"id": "satgat",
				"name": "삿갓",
				"price": 1900000.0,
				"time": 10.4,
				"cost": 0.0,
				"icon": "👒"
			},
			{
				"id": "manggeon",
				"name": "망건",
				"price": 4900000.0,
				"time": 11.2,
				"cost": 220000000.0,
				"icon": "🪖"
			},
			{
				"id": "tanggeon",
				"name": "탕건",
				"price": 13000000.0,
				"time": 12.0,
				"cost": 580000000.0,
				"icon": "🎩"
			},
			{
				"id": "gatkkeun",
				"name": "갓끈",
				"price": 33000000.0,
				"time": 12.8,
				"cost": 1500000000.0,
				"icon": "📿"
			},
			{
				"id": "heungnip",
				"name": "흑립",
				"price": 86000000.0,
				"time": 13.6,
				"cost": 160000000000.0,
				"icon": "🎓"
			},
			{
				"id": "jurip",
				"name": "주립",
				"price": 220000000.0,
				"time": 14.4,
				"cost": 480000000000.0,
				"icon": "⛑️"
			},
			{
				"id": "jeongjagwan",
				"name": "정자관",
				"price": 580000000.0,
				"time": 15.2,
				"cost": 60000000000000.0,
				"icon": "👑"
			},
			{
				"id": "oknorip",
				"name": "옥로립",
				"price": 1500000000.0,
				"time": 16.0,
				"cost": 180000000000000.0,
				"icon": "💎"
			}
		]
	},
	{
		"id": "brass",
		"name": "유기전",
		"sign": "鍮",
		"cost": 4000000000000.0,
		"desc": "놋쇠를 두드려 그릇을 만든다",
		"color": "#8a6a45",
		"ranks": [
			"방짜",
			"상",
			"왕실"
		],
		"promote": [
			900000000000.0,
			350000000000000.0
		],
		"items": [
			{
				"id": "notsujeo",
				"name": "놋수저",
				"price": 4000000.0,
				"time": 11.0,
				"cost": 0.0,
				"icon": "🥄"
			},
			{
				"id": "notjubal",
				"name": "놋주발",
				"price": 10000000.0,
				"time": 11.8,
				"cost": 450000000.0,
				"icon": "🥣"
			},
			{
				"id": "notjaengban",
				"name": "놋쟁반",
				"price": 27000000.0,
				"time": 12.6,
				"cost": 1200000000.0,
				"icon": "🍽️"
			},
			{
				"id": "notchotdae",
				"name": "놋촛대",
				"price": 70000000.0,
				"time": 13.4,
				"cost": 3200000000.0,
				"icon": "🕯️"
			},
			{
				"id": "nothwaro",
				"name": "놋화로",
				"price": 180000000.0,
				"time": 14.2,
				"cost": 360000000000.0,
				"icon": "🔥"
			},
			{
				"id": "notdaeya",
				"name": "놋대야",
				"price": 470000000.0,
				"time": 15.0,
				"cost": 1100000000000.0,
				"icon": "🛁"
			},
			{
				"id": "jegi",
				"name": "제기",
				"price": 1200000000.0,
				"time": 15.8,
				"cost": 140000000000000.0,
				"icon": "⚱️"
			},
			{
				"id": "bansangki",
				"name": "반상기",
				"price": 3200000000.0,
				"time": 16.6,
				"cost": 420000000000000.0,
				"icon": "🍱"
			}
		]
	},
	{
		"id": "lacquer",
		"name": "나전방",
		"sign": "螺",
		"cost": 8000000000000.0,
		"desc": "자개를 박아 세간을 꾸민다",
		"color": "#8a6a45",
		"ranks": [
			"자개",
			"진주",
			"왕실"
		],
		"promote": [
			2000000000000.0,
			750000000000000.0
		],
		"items": [
			{
				"id": "najeonbit",
				"name": "나전빗",
				"price": 8300000.0,
				"time": 11.6,
				"cost": 0.0,
				"icon": "💈"
			},
			{
				"id": "gyeongdae",
				"name": "경대",
				"price": 22000000.0,
				"time": 12.4,
				"cost": 990000000.0,
				"icon": "🪞"
			},
			{
				"id": "ham",
				"name": "함",
				"price": 56000000.0,
				"time": 13.2,
				"cost": 2500000000.0,
				"icon": "🎁"
			},
			{
				"id": "mungap",
				"name": "문갑",
				"price": 150000000.0,
				"time": 14.0,
				"cost": 6800000000.0,
				"icon": "🗄️"
			},
			{
				"id": "jwagyeong",
				"name": "좌경",
				"price": 380000000.0,
				"time": 14.8,
				"cost": 800000000000.0,
				"icon": "🔍"
			},
			{
				"id": "samcheungjang",
				"name": "삼층장",
				"price": 990000000.0,
				"time": 15.6,
				"cost": 2400000000000.0,
				"icon": "🪜"
			},
			{
				"id": "byeongpung",
				"name": "자개병풍",
				"price": 2600000000.0,
				"time": 16.4,
				"cost": 300000000000000.0,
				"icon": "🖼️"
			},
			{
				"id": "najeonnong",
				"name": "나전롱",
				"price": 6700000000.0,
				"time": 17.2,
				"cost": 900000000000000.0,
				"icon": "👘"
			}
		]
	}
]

const SHOP_UP := {
	"smith": {
		"name": "풀무",
		"face": "🔥",
		"max": 5.0,
		"step": 0.06,
		"desc": "이 가게가 만드는 시간 −6%"
	},
	"brush": {
		"name": "먹 갈기",
		"face": "⚫",
		"max": 5.0,
		"step": 0.08,
		"desc": "이 가게 물건값 +8%"
	},
	"paper": {
		"name": "의뢰방",
		"face": "📜",
		"max": 3.0,
		"step": 1.0,
		"desc": "마을 의뢰가 한 자리 더 걸린다"
	},
	"pot": {
		"name": "질그릇 한 벌",
		"face": "🏺",
		"max": 5.0,
		"step": 0.15,
		"desc": "이 가게 물건을 한 번에 15% 더 사간다"
	},
	"herb": {
		"name": "약재 말리기",
		"face": "🌾",
		"max": 5.0,
		"step": 0.05,
		"desc": "5% 확률로 판 값을 두 배로 쳐준다"
	}
}

const SHOP_UP_COST := [
	0.05,
	0.12,
	0.25,
	0.5,
	1.0
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
	"capAdd": 0.0,
	"costMul": [
		0.5,
		0.01,
		0.03,
		0.08
	],
	"max": 4.0
}

const STAFF_RANKS := [
	{
		"id": "band",
		"name": "머리띠",
		"hat": "수건 머리띠"
	},
	{
		"id": "whitehood",
		"name": "흰 두건",
		"hat": "흰 무명 두건"
	},
	{
		"id": "grayhood",
		"name": "회색 두건",
		"hat": "잿빛 두건"
	},
	{
		"id": "blackhood",
		"name": "검정 두건",
		"hat": "검정 두건 — 제일 높다"
	}
]

const STAR_CARDS := [
	5.0,
	10.0,
	15.0,
	20.0,
	30.0,
	40.0,
	55.0,
	70.0,
	90.0,
	115.0,
	145.0,
	180.0,
	220.0,
	270.0,
	330.0,
	400.0,
	480.0,
	580.0,
	700.0
]

const STOCK_CAP := 5.0

const SWEEPER := {
	"id": "sweeper",
	"name": "장터 청소부",
	"face": "🧹",
	"cost": 60000.0,
	"picks": 20.0,
	"max": 1.0,
	"desc": "길에 떨어진 것을 대신 줍는다 — 자리를 비워도 돈다"
}

const TRASH := {
	"every": 40.0,
	"max": 5.0,
	"handLeaf": 2.0,
	"sweepLeaf": 1.0
}

const WEATHER := {
	"every": [
		300.0,
		700.0
	],
	"kinds": [
		{
			"id": "clear",
			"name": "맑음",
			"face": "☀️",
			"come": 1.0,
			"craft": 1.0,
			"pest": 1.0,
			"weight": 5.0
		},
		{
			"id": "breeze",
			"name": "산들바람",
			"face": "🍃",
			"come": 1.25,
			"craft": 1.0,
			"pest": 1.0,
			"weight": 2.0
		},
		{
			"id": "cloud",
			"name": "흐림",
			"face": "☁️",
			"come": 0.85,
			"craft": 1.0,
			"pest": 1.0,
			"weight": 3.0
		},
		{
			"id": "rain",
			"name": "비",
			"face": "🌧️",
			"come": 0.55,
			"craft": 0.9,
			"pest": 1.7,
			"weight": 2.0
		}
	]
}

