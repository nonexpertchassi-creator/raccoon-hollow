#!/usr/bin/env node
'use strict';

const path = require('path');
const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const root = path.resolve(__dirname, '..');
const specs = process.argv.slice(2).map((value) => {
  const [item, ranks = '012'] = value.split(':');
  return { item, ranks: [...ranks].map(Number) };
});
if (!specs.length) {
  console.error('usage: qa-item-ranks item-id[:rank-indices] [...] (0=base, 1=rank2, 2=rank3)');
  process.exit(2);
}

async function inspect(file) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (info.width !== 128 || info.height !== 224 || info.channels !== 4) {
    throw new Error(`${file}: expected 128x224 RGBA`);
  }
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
  if (maxX < 0) throw new Error(`${file}: no visible pixels`);
  return { x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

(async () => {
  const rows = [];
  let failed = false;
  for (const { item, ranks } of specs) {
    const boxes = [];
    for (const rank of ranks) {
      const suffix = rank ? `-${rank}` : '';
      const file = path.join(root, 'godot/art/items', `${item}${suffix}.png`);
      boxes.push({ rank, box: await inspect(file) });
    }
    for (const { rank, box } of boxes) {
      const base = boxes[0].box;
      const delta = Math.max(
        Math.abs(box.x - base.x),
        Math.abs(box.y - base.y),
        Math.abs(box.width - base.width),
        Math.abs(box.height - base.height),
      );
      const pass = delta <= 6;
      failed ||= !pass;
      rows.push({ item, rank: rank + 1, ...box, maxDelta: delta, pass });
    }
  }
  console.table(rows);
  if (failed) throw new Error('item rank alpha boxes differ by more than 6px');
  console.log(`PASS: ${specs.length} item progressions use only requested ranks and are 128x224 RGBA.`);
})().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
