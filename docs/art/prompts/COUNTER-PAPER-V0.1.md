# 지물포 계산대 프롬프트 V0.1

- 방식: built-in image generation
- 참고 1: `godot/art/counters/brush.png` — 크기·시점·단순화 기준
- 참고 2: `godot/art/stalls/paper.png` — 지물포 나무색·한지 질감 기준
- 게임 파일: `godot/art/counters/paper.png`
- 파생: `tools/fit-transparent-prop.cjs`로 168×144 RGBA에 정렬

```text
Use case: stylized-concept
Asset type: 168x144 transparent game sales-counter sprite for a Korean Joseon-era paper shop
Input images: Image 1 is the exact runtime size, near-front camera, broad silhouette, outline thickness, and simplification reference. Image 2 is the exact paper-shop wood palette and hand-painted style reference.
Primary request: Draw one small waist-high Korean wooden sales counter for a traditional paper shop. Use a broad low timber front, a slightly visible mostly empty top, and two centered pale hanji sliding-door panels framed by simple wood on the customer-facing front. The paper panels should be broad blank cream rectangles with a subtle fibrous pencil texture, not loose paper products. Keep the design compact and unmistakably different from the brush shop's drawer counter.
Style/medium: cute hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple shapes, maximum two shading steps, readable at 84x72, matching both references.
Composition/framing: near-front three-quarter view, not an isometric box; the wide customer-facing plane must face screen down-right. Centered, stable bottom edge, generous transparent margin, almost bilateral symmetry so mirroring stays natural.
Palette: pale hanji #ece2cb as the distinguishing front panels, warm wood #8a6a45/#6d5236, tiny restrained ink-dark hardware #2b241b.
Constraints: genuine transparent alpha; no cast shadow, floor, wall, roof, character, paper roll, scroll, fan, brush, inkstone, product, coin, abacus, text, emblem, UI, border, watermark.
Avoid: Japanese shoji room divider, tall cabinet, isometric cube, Western shop bar, fantasy counter, ornate carving, photorealism, 3D rendering, strong perspective distortion, black background.
```
