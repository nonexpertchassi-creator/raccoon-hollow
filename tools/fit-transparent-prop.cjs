#!/usr/bin/env node
'use strict';

const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const [input, output, ...raw] = process.argv.slice(2);
const [canvasW, canvasH, maxW, maxH, bottomMargin = 0] = raw.map(Number);
if (!input || !output || [canvasW, canvasH, maxW, maxH, bottomMargin].some((n) => !Number.isInteger(n))) {
  console.error('usage: fit-transparent-prop input output canvasW canvasH maxW maxH [bottomMargin]');
  process.exit(2);
}

(async () => {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let minX = info.width;
  let minY = info.height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < info.height; y += 1) {
    for (let x = 0; x < info.width; x += 1) {
      if (data[(y * info.width + x) * 4 + 3] <= 12) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < 0) throw new Error('no visible pixels');
  const fitted = await sharp(input)
    .extract({ left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 })
    .resize(maxW, maxH, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  const meta = await sharp(fitted).metadata();
  const left = Math.floor((canvasW - meta.width) / 2);
  const top = canvasH - bottomMargin - meta.height;
  await sharp({
    create: { width: canvasW, height: canvasH, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite([{ input: fitted, left, top }]).png().toFile(output);
  console.log(`${output}: ${canvasW}x${canvasH}, fitted within ${maxW}x${maxH}`);
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
