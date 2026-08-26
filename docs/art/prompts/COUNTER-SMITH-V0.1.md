# 대장간 계산대 프롬프트 V0.1

- 방식: built-in image generation
- 스타일 참고: `godot/art/stalls/smith.png`, `godot/art/kilns/smith.png`
- 게임 파일: `godot/art/counters/smith.png`
- 파생: `tools/fit-transparent-prop.cjs`로 168×144 RGBA에 정렬

```text
Use case: stylized-concept
Asset type: 168x144 transparent game sales-counter sprite for a Korean blacksmith courtyard
Input images: Images 1-2 are the exact runtime style, palette, outline thickness, and simplification references.
Primary request: Draw one small waist-high Korean wooden sales counter for the blacksmith shop. Use a broad sturdy timber front, a slightly visible flat top, two simple legs or a solid low base, and one narrow dark iron reinforcing strip centered on the front. Keep the top mostly empty so code can place sold goods or effects. This is a compact counter, not a workbench and not an anvil.
Style/medium: cute hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple shapes, maximum two shading steps, readable at 84x72.
Composition/framing: near-front three-quarter view; the wide customer-facing plane must face screen down-right. Centered, stable bottom edge, generous transparent margin, close to bilateral symmetry so mirroring stays natural.
Palette: warm wood #8a6a45/#6d5236, small charcoal iron #3b342b, restrained hanji highlight.
Constraints: genuine transparent alpha; no cast shadow, floor, wall, roof, character, anvil, hammer, tools, product, coin, abacus, text, emblem, UI, border, watermark.
Avoid: isometric cube, tall cabinet, Western shop bar, fantasy counter, ornate carving, photorealism, 3D rendering, strong perspective distortion.
```
