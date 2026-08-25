# SMITH-MODULAR-ASSETS-V0.1

## 범위

- 점장 본체 B·C·D 각 `front/side/back`
- 점장 꼬리 B·C·D 각 `side/back`
- 대장간 장비 1·2·3단 각 `front/side/back`
- 대장간 판매 물건 7종의 무쇠·참쇠·강철 3단

## 공통 점장 prompt

```text
Use case: precise-object-edit / stylized-concept
Preserve the approved A body silhouette, pose, face, limb positions, compact proportions,
soft colored-pencil/crayon texture, broken dark-brown outline and simple two-tone shading.
Change only the fur palette and irregular markings to Pattern B, C or D.
No clothing, apron, tool, tail, equipment, floor shadow, text or border.
Genuine transparent background. Feet are the lowest visible pixels.
```

## 공통 장비 prompt

```text
Create only two paper-doll equipment pieces: a short waist apron and one slightly oversized
long-handled smith hammer. Output no raccoon/body/paw/tail pixels. No shirt, pants, shoes,
sleeves, headwear or bow. Preserve the 144-square direction pin. Rank 1 is plain cast iron
and charcoal brown; rank 2 uses neat medium steel, ochre seam and a tiny bronze collar;
rank 3 uses ink-navy charcoal, restrained brick-red stitching and deep polished steel.
Korean-folk colored-pencil/crayon texture, genuine transparent alpha, no fantasy effects.
```

## 공통 물건 prompt

```text
Redraw the referenced blacksmith item as a compact, chunky, adorable late-Joseon village-game
object. Preserve identity and orientation. Use a readable toy-like silhouette without a face
or anthropomorphism, soft colored-pencil/crayon texture, broken dark-brown outline, flat warm
colors and one shadow tone. Rank 1 is warm cast iron and honey wood; rank 2 is clean blue-gray
chamsoe with a restrained brass detail; rank 3 is deep blue-charcoal gangcheol with a pale
forged edge and dark red-brown wood. No magic, gems, runes, text, floor shadow or scenery.
Genuine transparent alpha.
```

## 후처리 규칙

- 체크무늬가 실제 픽셀인 결과는 `background-extraction`으로 다시 분리한다.
- 본체는 A와 같은 방향별 가시 상자에 맞추고 발끝을 144px 캔버스 아래 변에 붙인다.
- 꼬리는 A의 방향별 가시 상자와 뿌리 핀을 그대로 쓴다.
- 장비는 앞치마와 망치를 분리해 앞치마 윗선을 손 아래로 내린다.
- 물건은 기존 128×224 기준 그림과 같은 가시 상자에 비율을 지켜 앉힌다.
