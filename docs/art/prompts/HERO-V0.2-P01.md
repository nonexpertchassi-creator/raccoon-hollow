# HERO-V0.2-P01 — 무복식 소형 점주 2포즈

## 상태

- 제작 상태: `Generated`
- 승인 상태: 사용자 검토 전
- 계기: 사용자가 V0.1의 전신 서민복보다 작은 참고 이미지처럼 단순한 캐릭터를 선호할 가능성을 제안
- 핵심 Hypothesis: 복식을 모두 제거하고 털 실루엣과 행동 포즈만 남기면 34×34에서 더 잘 읽힌다.

## 입력 이미지 역할

- `BP-V0.1-P01.png`: 따뜻한 한국 마을 팔레트와 세계관 스타일 참조
- 사용자 제공 소형 이미지: 작은 크기에서 한 덩어리로 읽히는 단순함과 캐릭터 점유율 참조. 캐릭터·색·소품은 복제하지 않음

## Make prompt 핵심

```text
Create V0.2 of the Korean raccoon dog shopkeeper in a clear making/crafting pose, redesigned to be much simpler and unclothed. Use broad clean shapes, a thick charcoal-brown contour, very few interior lines, flat color blocks, one restrained shadow tone, and almost no fur micro-detail. The true raccoon dog has small rounded ears, warm gray-brown fur, subtle eye shading, short legs, compact round body, and a fluffy tail with no rings. No clothing or accessories. Face right, crouch and lean forward, lift one empty forepaw and reach the other toward the work area. Both paws remain empty because the game draws the hammer separately. Genuine transparent alpha; no floor, shadow, props, text, UI, border, or watermark.
```

## Sell prompt 핵심

```text
Create the matching V0.2 selling pose of the exact same unclothed Korean raccoon dog. Preserve identity, fur, proportions, palette, outline, simplified flat style, and transparent background. Stand slightly more upright with a gentle forward lean and extend both empty forepaws together toward the right at chest height. The paws must extend outside the torso silhouette so the gesture reads at 34×34. No clothes, accessories, product, coin bag, floor, shadow, scenery, text, UI, border, or watermark.
```

## 산출물

- 원본 make: `../generated/hero/HERO-V0.2-make-master.png`
- 원본 sell: `../generated/hero/HERO-V0.2-sell-master.png`
- 게임용 보존본: `../../../art/hero/raccoon-make-v002.png`, `../../../art/hero/raccoon-sell-v002.png`
