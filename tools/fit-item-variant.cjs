#!/usr/bin/env node
'use strict';

// 생성된 등급 변형의 색만 가져오고, 기준 물건의 알파 실루엣·크기·위치를 고정한다.
const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const [input, reference, output] = process.argv.slice(2);
if (!input || !reference || !output) {
  console.error('usage: fit-item-variant input.png reference.png output.png');
  process.exit(2);
}

function isChecker(r, g, b) {
  return Math.min(r, g, b) >= 220 && Math.max(r, g, b) - Math.min(r, g, b) <= 14;
}

async function alphaBounds(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
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
  if (maxX < 0) throw new Error(`no visible pixels in ${file}`);
  return { data, info, minX, minY, maxX, maxY };
}

async function checkerBounds(file) {
  const { data, info } = await sharp(file).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  let minX = info.width;
  let minY = info.height;
  let maxX = -1;
  let maxY = -1;
  for (let y = 0; y < info.height; y += 1) {
    for (let x = 0; x < info.width; x += 1) {
      const p = (y * info.width + x) * 3;
      if (isChecker(data[p], data[p + 1], data[p + 2])) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < 0) throw new Error(`no non-checker pixels in ${file}`);
  return { minX, minY, maxX, maxY };
}

(async () => {
  const source = await checkerBounds(input);
  const target = await alphaBounds(reference);
  const width = target.maxX - target.minX + 1;
  const height = target.maxY - target.minY + 1;
  const { data: color } = await sharp(input)
    .extract({
      left: source.minX,
      top: source.minY,
      width: source.maxX - source.minX + 1,
      height: source.maxY - source.minY + 1,
    })
    .resize(width, height, { fit: 'fill', kernel: sharp.kernel.lanczos3 })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const mask = await sharp(reference)
    .extract({ left: target.minX, top: target.minY, width, height })
    .ensureAlpha()
    .raw()
    .toBuffer();
  const rgba = Buffer.alloc(width * height * 4);
  for (let i = 0; i < width * height; i += 1) {
    rgba[i * 4] = color[i * 3];
    rgba[i * 4 + 1] = color[i * 3 + 1];
    rgba[i * 4 + 2] = color[i * 3 + 2];
    rgba[i * 4 + 3] = mask[i * 4 + 3];
  }
  const fitted = await sharp(rgba, { raw: { width, height, channels: 4 } }).png().toBuffer();
  await sharp({
    create: {
      width: target.info.width,
      height: target.info.height,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  }).composite([{ input: fitted, left: target.minX, top: target.minY }]).png().toFile(output);
  console.log(`${output}: matched ${reference} alpha box ${width}x${height}`);
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
