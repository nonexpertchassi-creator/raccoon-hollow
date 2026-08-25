#!/usr/bin/env node
'use strict';

// 새 원화를 기준 그림과 같은 캔버스·가시 영역에 비율을 지켜 앉힌다.
const sharp = require('sharp');
const [input, reference, output] = process.argv.slice(2);
if (!input || !reference || !output) {
  console.error('usage: fit-like input.png reference.png output.png');
  process.exit(2);
}

async function bounds(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let minX = info.width, minY = info.height, maxX = -1, maxY = -1;
  for (let y = 0; y < info.height; y += 1) {
    for (let x = 0; x < info.width; x += 1) {
      if (data[(y * info.width + x) * 4 + 3] <= 12) continue;
      minX = Math.min(minX, x); minY = Math.min(minY, y);
      maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
    }
  }
  if (maxX < minX) throw new Error(`no visible pixels in ${file}`);
  return { ...info, minX, minY, maxX, maxY };
}

(async () => {
  const source = await bounds(input);
  const target = await bounds(reference);
  const boxW = target.maxX - target.minX + 1, boxH = target.maxY - target.minY + 1;
  const cutout = await sharp(input)
    .extract({ left: source.minX, top: source.minY,
      width: source.maxX - source.minX + 1, height: source.maxY - source.minY + 1 })
    .resize(boxW, boxH, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  await sharp({ create: { width: target.width, height: target.height, channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([{ input: cutout, left: target.minX, top: target.minY }])
    .png()
    .toFile(output);
  console.log(`${output}: matched ${reference}`);
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
