# 필방 계산대 프롬프트 V0.1

- 방식: built-in image generation
- 참고 1: `godot/art/counters/smith.png` — 크기·시점·단순화 기준
- 참고 2: `godot/art/stalls/brush.png` — 필방 나무색·한지 질감 기준
- 게임 파일: `godot/art/counters/brush.png`
- 파생: `tools/fit-transparent-prop.cjs`로 168×144 RGBA에 정렬

```text
Use case: stylized-concept
Asset type: 168x144 transparent game sales-counter sprite for a Korean Joseon-era brush-and-ink shop
Input images: Image 1 is the exact counter scale, camera, silhouette simplicity, outline thickness, and runtime readability reference. Image 2 is the exact brush-shop wood palette and hand-painted style reference.
Primary request: Draw one small waist-high Korean wooden sales counter for the brush-and-ink shop. Use a broad low timber front, a slightly visible flat top, a centered pair of very shallow traditional wood drawers, and one narrow pale hanji writing-mat strip inset along the top. Keep almost all of the top empty so code can place sold goods or effects. It must feel like a simple Joseon wooden writing counter, not a Western cashier desk.
Style/medium: cute hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple shapes, maximum two shading steps, readable at 84x72, matching both references.
Composition/framing: near-front three-quarter view, not an isometric box; the wide customer-facing plane must face screen down-right. Centered, stable bottom edge, generous transparent margin, close to bilateral symmetry so mirroring stays natural.
Palette: warm wood #8a6a45/#6d5236, pale hanji #ece2cb, tiny restrained dark ink accent #2b241b.
Constraints: genuine transparent alpha; no cast shadow, floor, wall, roof, character, brush, ink stick, inkstone, paper roll, product, coin, abacus, text, emblem, UI, border, watermark.
Avoid: isometric cube, tall cabinet, Western shop bar, fantasy counter, ornate carving, photorealism, 3D rendering, strong perspective distortion, black background.
```
