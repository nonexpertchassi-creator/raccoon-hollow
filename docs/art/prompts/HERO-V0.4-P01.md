# HERO-V0.4-P01

## 목적

짧은 황토색 앞치마를 두른 점장 V0.3을 기준으로, Godot이 실제로 찾는 빈 자세
`walk1`, `walk2`, `sleep`과 마을의 `mayor`를 새 2배 규격으로 만든다.

## 공통 기준

- 기준 이미지: `generated/hero/HERO-V0.3-*-master.png`
- 한국 너구리: 작은 둥근 귀, 회갈색 털, 부드러운 눈 주변 무늬, 고리 없는 복슬한 꼬리
- 점장: 짧은 황토색 허리 앞치마만 유지
- 시점: 정면에 가까운 3/4, 화면 오른쪽을 향함
- 스타일: 굵은 짙은 갈색 외곽선, 큰 색면, 최소 명암
- 출력: 실제 투명 PNG, 런타임 `144×144`, 발끝 하단 정렬

## 자세

- `raccoon-walk1`: 왼발 앞, 오른발 뒤, 팔은 반대로 작게 흔듦
- `raccoon-walk2`: 오른발 앞, 왼발 뒤, 머리·몸·꼬리·앞치마는 최대한 고정
- `raccoon-sleep`: 서서 눈을 감고 두 앞발을 모음, 작은 몽글방울 세 개
- `mayor`: 점장과 같은 크기, 앞치마 없음, 짧은 흰 수염과 단순한 나무 지팡이

## 금지

- 라쿤 고리 꼬리, 선명한 검은 마스크
- 유아형 비율, 전신 의상, 왕관·관복
- 그림자, 글자, UI, 워터마크, 체크무늬 배경

## 출력

- `godot/art/hero/raccoon-walk1.png`
- `godot/art/hero/raccoon-walk2.png`
- `godot/art/hero/raccoon-sleep.png`
- `godot/art/hero/mayor.png`

