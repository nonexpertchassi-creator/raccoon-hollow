# 대장간 풀무·화덕 프롬프트 V0.1

- 방식: built-in image generation
- 스타일 참고: `godot/art/stalls/smith.png`
- 구조 참고: `docs/art/generated/SMITH-CONCEPT-V0.1-P01.png`
- 게임용 파생: `tools/fit-transparent-prop.cjs`, 168×192 RGBA

```text
Use case: stylized-concept
Asset type: 168x192 transparent game production-machine sprite for a Korean blacksmith courtyard
Input images: Image 1 is the required runtime style and simplification reference. Image 2 is subject reference only for the Korean charcoal forge and wooden bellows.
Primary request: Draw one compact traditional Korean blacksmith forge unit: a short rounded charcoal-brick furnace with one clear arched fire mouth glowing warm orange, plus one small simple wooden hand bellows attached behind-left. It is a single stationary production machine, not a building and not a stall.
Style/medium: match Image 1 exactly—cute compact hand-painted colored-pencil/crayon game prop, thick uneven dark reddish-brown outline, broad simple color shapes, maximum two shading steps, readable at 84x96.
Composition/framing: nearly front-facing three-quarter view with only a little top surface visible; centered, generous transparent margin, stable bottom edge.
Palette: charcoal #3b342b and roof-tile gray #4a4139, wood #8a6a45/#6d5236, restrained ember orange; warm Korean folk palette.
Constraints: genuine transparent alpha, no cast shadow, no floor, no wall, no roof, no character, no anvil, no tools, no baskets, no smoke cloud, no text, no UI, no border, no watermark.
Avoid: isometric cube, Western medieval fantasy forge, stone castle chimney, photorealism, 3D rendering, ornate metalwork, magic glow, sparks filling the canvas.
```
