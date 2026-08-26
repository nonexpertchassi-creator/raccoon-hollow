# 약재상 계산대 프롬프트 V0.1

- 방식: built-in image generation
- 참고 1: `godot/art/counters/pot.png` — 크기·시점·단순화 기준
- 참고 2: `godot/art/stalls/herb.png` — 약장 서랍·나무색 기준
- 게임 파일: `godot/art/counters/herb.png`
- 파생: `tools/fit-transparent-prop.cjs`로 168×144 RGBA에 정렬

```text
Use case: stylized-concept
Asset type: 168x144 transparent game sales-counter sprite for a Korean Joseon-era herbal medicine shop
Input images: Image 1 is the exact runtime size, near-front camera, broad counter silhouette, outline thickness, and simplification reference. Image 2 is the exact herbal-shop drawer motif, warm wood palette, and hand-painted style reference.
Primary request: Draw one small waist-high Korean wooden sales counter for a traditional herbal medicine shop. Use a broad low timber body with a slightly visible completely empty top. Center exactly six shallow medicine drawers on the customer-facing front in a simple 3-column by 2-row grid, each with one tiny dark round pull and no label. Keep the drawers broad and readable, not densely detailed. It should resemble a compact Korean yakjang medicine chest adapted as a sales counter.
Style/medium: cute hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple shapes, maximum two shading steps, readable at 84x72, matching both references.
Composition/framing: near-front three-quarter view, not an isometric box; the wide customer-facing plane must face screen down-right. Centered, stable bottom edge, generous transparent margin, almost bilateral symmetry so mirroring stays natural.
Palette: warm wood #8a6a45/#6d5236, tiny restrained ink-dark pulls #2b241b, optional very small muted jade accent #4a7c59 only if needed.
Constraints: genuine transparent alpha; no cast shadow, floor, wall, roof, character, herb, root, ginseng, mushroom, bottle, jar, mortar, product, coin, abacus, text, paper labels, emblem, UI, border, watermark.
Avoid: dozens of tiny drawers, apothecary wall cabinet, Chinese calligraphy labels, modern pharmacy counter, isometric cube, Western shop bar, fantasy counter, ornate carving, photorealism, 3D rendering, strong perspective distortion, black background.
```
