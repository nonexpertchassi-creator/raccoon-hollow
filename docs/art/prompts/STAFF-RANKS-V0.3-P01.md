# STAFF-RANKS-V0.3-P01

## 목적

사용자가 마음에 들어 한 `band-work.png`와 `band-sleep.png`의 한국 너구리 몸을 기준으로,
직원 등급을 몸 크기나 복식이 아니라 머리 장식만으로 구분하는 초안을 만든다.

## 입력 이미지

- 작업 기준: `godot/art/staff/band-work.png`
- 수면 기준: `godot/art/staff/band-sleep.png`

## 공통 프롬프트

```text
Use case: precise-object-edit
Asset type: 144×144 transparent PNG game staff sprite
Input images: Image 1 is the exact edit target and character/style anchor.
Primary request: Replace only the cream cloth headband with the requested Joseon-era staff hat.
Constraints: Preserve the Korean raccoon dog’s body, face, ears, fur colors, fluffy unringed tail,
pose, empty paws, proportions, outline thickness, lighting, feet touching the bottom edge, and
genuine transparent background. Change only the headwear. Front 3/4 view slightly right. Flat fills,
thick dark-brown outline, minimal gradients, no cast shadow, no text, no watermark, no checkerboard.
Avoid: raccoon ringed tail, sharp black eye mask, clothing, tools, extra props, changed expression or
pose, Chinese or Japanese hat styling.
```

## 등급별 변경값

- `chorip`: 따뜻한 누런 풀색, 둥근 관과 짧고 좁은 챙의 작은 초립
- `paeraengi`: 자연 대나무색, 낮은 관과 넓고 평평한 챙의 패랭이
- `baengnip`: 한지빛 미색, 단정한 원통형 관과 넓은 챙의 백립

수면 포즈는 눈을 감은 자세와 몽글 수면방울을 유지한다.

## 후처리

- 체크무늬가 실제 픽셀로 생성된 결과는 `background-extraction`으로 진짜 알파 투명 처리
- 내용 비율을 유지해 `144×144` 캔버스 안에 맞춤
- 가로 중앙 정렬, 발끝을 아래 변에 맞춤

## 출력

- `godot/art/staff/chorip-work.png`
- `godot/art/staff/chorip-sleep.png`
- `godot/art/staff/paeraengi-work.png`
- `godot/art/staff/paeraengi-sleep.png`
- `godot/art/staff/baengnip-work.png`
- `godot/art/staff/baengnip-sleep.png`

