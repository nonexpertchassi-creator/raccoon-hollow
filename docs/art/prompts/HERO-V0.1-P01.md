# HERO-V0.1-P01 — 한국 너구리 점주 2포즈 초안

## 상태

- 제작 상태: `Generated`
- 승인 상태: 사용자 검토 전
- 용도: 모바일 실제 플레이 크기 점주 스프라이트 시험
- 런타임 규격: `72×72 PNG`, 투명 배경
- 화면 표시 예상: 약 `34×34`

## 공통 입력

- 스타일 참조: `../generated/BP-V0.1-P01.png`
- 캐릭터: 한국 너구리(raccoon dog), 작은 둥근 귀, 회갈색/갈색 털, 약한 눈 주변 어두운 털, 짧은 다리, 통통하지만 일하는 체형, 고리무늬 없는 복슬한 꼬리
- 복식: 짧은 베이지 저고리, 넓은 흙갈색 바지, 작은 작업 앞치마
- 스타일: 따뜻한 2D 모바일 게임 스프라이트, 큰 실루엣, charcoal-brown 외곽선, 절제된 명암과 미세한 한지 질감
- 금지: 라쿤식 고리 꼬리, 선명한 검은 마스크, 배경, 그림자, 소품, 텍스트, UI, 테두리, 워터마크

## Make prompt

```text
Use case: stylized-concept
Asset type: production-oriented small mobile game character sprite, transparent-background cutout
Primary request: Create the first draft of the Korean raccoon dog shopkeeper in a clear "making / crafting" pose for the vertical idle tycoon game Raccoon General Store.
Input images: Image 1 is style and world-direction reference only; do not copy its composition or background.
Subject: one true Korean raccoon dog, not a North American raccoon. Small rounded ears, warm gray-brown and brown fur, only soft subtle darker fur around the eyes, short legs, compact plump capable body, fluffy tail with absolutely no clear rings. Cute but not babyish.
Clothing: highly simplified late-Joseon commoner work clothes: short beige jeogori, loose earth-brown baji, small practical muted-brown work apron. No ornate hanbok and no royal clothing.
Pose: full body, three-quarter front view facing RIGHT. Leaning forward to work, knees slightly bent, one arm raised and the other reaching forward as if hammering. BOTH HANDS MUST BE EMPTY because the game code draws the hammer separately. Strongly different silhouette from an upright selling pose.
Style/medium: warm stylized 2D mobile game sprite matching the reference's visual DNA; broad readable shapes; consistent thick dark charcoal-brown outline; flat fills; restrained soft shading; light hand-painted material feel; extremely subtle hanji grain. Simplify fur and clothing so the character remains readable at 34x34 screen pixels.
Composition/framing: one character only, centered on a square canvas, full body fully visible, feet aligned on the bottom baseline, minimal transparent margin, no cropping.
Lighting/mood: gentle upper-left light, warm and hardworking.
Color palette: warm hanji beige, earth brown, charcoal, restrained muted rust accents.
Constraints: genuinely transparent alpha background; no floor, no contact shadow, no scenery, no building, no props, no tool, no hammer, no product, no text, no UI, no border, no watermark.
Avoid: raccoon ringed tail, sharply painted bandit mask, pointed large ears, baby proportions, glossy 3D, pixel art, anime style, excessive costume detail, Chinese or Japanese motifs, white or colored background matte.
```

## Sell prompt

판매 포즈는 먼저 동일 캐릭터의 새 포즈로 생성한 뒤, 팔 동작이 약해 아래의 단일 수정 프롬프트를 적용했다.

```text
Use case: precise-object-edit
Asset type: small mobile game character sprite with transparent background
Primary request: Change ONLY the pose of the raccoon dog shopkeeper's arms and upper-body gesture so it clearly reads as selling or handing goods to a customer on the RIGHT.
Required pose: keep the body mostly upright with a slight polite forward lean. Extend BOTH EMPTY HANDS together toward the RIGHT at chest-to-waist height, palms/paws slightly upward and close together, clearly ready to present an object. The hands must project outside the torso silhouette so the action remains obvious at 34x34 pixels.
Invariants: preserve the exact same character identity, Korean raccoon dog species, face, eyes, ears, fur colors and markings, fluffy unringed tail, body proportions, beige jeogori, earth-brown baji, brown apron, rendering style, line weight, palette, lighting, canvas size, foot baseline, and genuine transparent alpha background.
Constraints: hands empty; no goods, coin bag, tool, hammer, floor, shadow, scenery, text, UI, border, or watermark.
Avoid: changing the face, costume, tail, colors, proportions, or style; avoid arms hanging down; avoid a waving pose.
```

수정 결과에 체크무늬 배경이 실제 픽셀로 들어가 배경 제거를 한 번 더 수행했다. 캐릭터 외형은 유지하고 배경만 genuine transparent alpha로 변환했다.

## 산출물

- 원본 make: `../generated/hero/HERO-V0.1-make-master.png`
- 원본 sell: `../generated/hero/HERO-V0.1-sell-master.png`
- 게임용 보존본 make: `../../../art/hero/raccoon-make-v001.png`
- 게임용 보존본 sell: `../../../art/hero/raccoon-sell-v001.png`
