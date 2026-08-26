# 가마솥 2·3단 승급판 프롬프트 V0.1

- 방식: built-in image generation/edit
- 기준 이미지: `godot/art/items/cauldr.png`
- 스타일 참고: `pick.png`, `pick-1.png`, `pick-2.png`
- 게임용 파생: `tools/fit-item-variant.cjs`로 기준 가마솥의 알파 실루엣과 위치를 복제

## 2단 · 참쇠

```text
Use case: precise-object-edit
Asset type: tiny 128x224 Korean shop game item sprite
Input images: Image 1 is the only edit target, the base gamasot. Images 2-4 are style and rank-progression references only.
Primary request: Make rank 2 of Image 1. Keep the exact cute compact Korean gamasot silhouette, exact lid, knob, loop handles, three short feet, three-quarter camera, scale and placement. Change only the iron material to the same restrained rank-2 treatment seen between Images 2 and 3: slightly cleaner, slightly lighter cool gray, one simple edge highlight.
Style/medium: match the simplified hand-painted small sprite in all references; broad color areas, dark warm-brown outline, minimal two-step shading, not realistic, not 3D.
Constraints: genuine fully transparent alpha outside the object; preserve generous transparent canvas around it; readable when shown at 64px.
Avoid: black or colored background, halo, floor shadow, photorealism, detailed metal scratches, dramatic lighting, glow, border, text, symbols, ornament, fantasy effects, extra objects, or changed silhouette.
```

## 3단 · 강철

```text
Use case: precise-object-edit
Asset type: tiny 128x224 Korean shop game item sprite
Input images: Image 1 is the base gamasot identity and silhouette. Image 2 is its approved rank-2 treatment. Image 3 is the rank-3 palette progression reference.
Primary request: Make rank 3 of the exact same Korean gamasot. Preserve the compact silhouette, lid, knob, loop handles, three short feet, three-quarter camera and broad simple painted shapes. Make it clearly superior to Image 2 with deeper charcoal steel, a cleaner forged surface, and one restrained cool edge highlight; keep it non-magical and traditional.
Style/medium: simplified warm hand-painted game sprite, thick dark warm-brown outline, minimal two-step shading, readable at 64px, not realistic and not 3D.
Constraints: preserve generous blank space; no silhouette changes.
Avoid: black or colored background, floor shadow, halo, photorealism, dense scratches, dramatic lighting, glow, border, text, symbols, ornament, fantasy effects, extra objects.
```
