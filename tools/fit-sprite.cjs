#!/usr/bin/env node
'use strict';

// 생성 원화의 실제 알파 영역만 잘라, 계약 캔버스의 지정 사각형에 정확히 앉힌다.
// 사용: node fit-sprite.cjs input.png output.png canvasW canvasH x y width height
const sharp = require('sharp');

const [input, output, ...rawNumbers] = process.argv.slice(2);
const numbers = rawNumbers.map(Number);
if (!input || !output || numbers.length !== 6 || numbers.some((n) => !Number.isInteger(n))) {
  console.error('usage: fit-sprite input output canvasW canvasH x y width height');
  process.exit(2);
}
const [canvasW, canvasH, targetX, targetY, targetW, targetH] = numbers;

(async () => {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let minX = info.width, minY = info.height, maxX = -1, maxY = -1;
  for (let y = 0; y < info.height; y += 1) {
    for (let x = 0; x < info.width; x += 1) {
      if (data[(y * info.width + x) * 4 + 3] <= 12) continue;
      minX = Math.min(minX, x); minY = Math.min(minY, y);
      maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
    }
  }
  if (maxX < minX || maxY < minY) throw new Error(`no visible pixels in ${input}`);

  const cropped = await sharp(input)
    .extract({ left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 })
    .resize(targetW, targetH, { fit: 'fill', kernel: sharp.kernel.lanczos3 })
    .png()
    .toBuffer();
  await sharp({
    create: { width: canvasW, height: canvasH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite([{ input: cropped, left: targetX, top: targetY }])
    .png()
    .toFile(output);
  console.log(`${output}: alpha ${minX},${minY}-${maxX},${maxY} -> ${targetX},${targetY} ${targetW}x${targetH}`);
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
