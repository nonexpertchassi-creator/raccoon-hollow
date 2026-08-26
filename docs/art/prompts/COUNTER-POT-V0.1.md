# 옹기점 계산대 프롬프트 V0.1

- 방식: built-in image generation
- 참고 1: `godot/art/counters/paper.png` — 크기·시점·단순화 기준
- 참고 2: `godot/art/stalls/pot.png` — 옹기점 흙·벽돌·나무색 기준
- 게임 파일: `godot/art/counters/pot.png`
- 파생: `tools/fit-transparent-prop.cjs`로 168×144 RGBA에 정렬

```text
Use case: stylized-concept
Asset type: 168x144 transparent game sales-counter sprite for a Korean Joseon-era onggi pottery shop
Input images: Image 1 is the exact runtime size, near-front camera, broad counter silhouette, outline thickness, and simplification reference. Image 2 is the exact pottery-shop warm clay, brick, and wood palette reference.
Primary request: Draw one small waist-high Korean sales counter for an onggi pottery shop. Use a broad simple timber top over a low sturdy warm-ochre earthen-brick base. Divide the customer-facing front into three broad clay panels with very subtle hand-pressed uneven texture and a narrow dark wood frame. Keep the top completely empty so code can place sold goods or effects. It should suggest an onggi workshop through the clay-built base, without placing any jar or pottery product on it.
Style/medium: cute hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple shapes, maximum two shading steps, readable at 84x72, matching both references.
Composition/framing: near-front three-quarter view, not an isometric box; the wide customer-facing plane must face screen down-right. Centered, stable bottom edge, generous transparent margin, almost bilateral symmetry so mirroring stays natural.
Palette: warm clay #a8763e and muted terracotta-brown, wood #8a6a45/#6d5236, small hanji highlights; no saturated orange.
Constraints: genuine transparent alpha; no cast shadow, floor, wall, roof, character, jar, pot, bowl, kiln, clay tools, product, coin, abacus, text, emblem, UI, border, watermark.
Avoid: brick building wall, modern tile counter, isometric cube, Western shop bar, fantasy counter, ornate carving, photorealism, 3D rendering, strong perspective distortion, black background.
```
