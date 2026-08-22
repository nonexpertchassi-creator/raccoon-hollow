# HERO-V0.3-P01 — 짧은 허리 앞치마 점주 2포즈

## 상태

- 제작 상태: `Generated`
- 승인 상태: 사용자 검토 전
- 계기: 사용자가 V0.2의 무복식 방향을 선호하면서, 전신 옷 대신 일부 요소로 앞치마를 제안
- 핵심 Hypothesis: 자연 털 실루엣은 유지하고 짧은 허리 앞치마만 추가하면 34×34에서 점주 역할을 더 잘 전달한다.

## 편집 기준

- 편집 대상: `HERO-V0.2-make-master.png`, `HERO-V0.2-sell-master.png`
- 변경 요소: 허리 아래만 덮는 짧은 황토갈색 작업 앞치마 1개
- 유지 요소: 얼굴, 털, 귀, 고리 없는 꼬리, 몸 비율, make/sell 포즈, 외곽선, 팔레트, 투명 배경
- 금지: 상의, 바지, 두루마기, 머리띠, 모자, 신발, 무늬, 자수, 주머니, 큰 장식 매듭

## 공통 prompt 핵심

```text
Use case: precise-object-edit
Add ONLY one small practical waist apron to the Korean raccoon dog shopkeeper. The apron is a short waist-only work apron in muted warm ochre-earth brown, one broad simple flat color shape with a dark charcoal-brown outline and tiny side ties. It starts at the waist and ends above the knees. No bib, shoulder straps, pocket, pattern, embroidery, or decorative knot. Preserve the exact character identity, fur, rounded ears, fluffy unringed tail, compact body proportions, pose, direction, silhouette, line weight, flat rendering, lighting, foot baseline, and genuine transparent alpha background. No other clothing, accessories, props, floor, shadow, scenery, text, UI, border, or watermark.
```

두 편집 결과에서 체크무늬가 실제 배경 픽셀로 들어가, 캐릭터와 앞치마를 유지한 채 background extraction을 각각 한 번 수행했다.

## 산출물

- 원본 make: `../generated/hero/HERO-V0.3-make-master.png`
- 원본 sell: `../generated/hero/HERO-V0.3-sell-master.png`
- 게임용 현재 후보 make: `../../../art/hero/raccoon-make.png`
- 게임용 현재 후보 sell: `../../../art/hero/raccoon-sell.png`
- 비교 보존본: `../../../art/hero/raccoon-make-v003.png`, `../../../art/hero/raccoon-sell-v003.png`

