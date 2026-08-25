#!/usr/bin/env node
'use strict';

const sharp = require('sharp');
const path = require('path');

const output = process.argv[2] || 'docs/art/generated/SMITH-ITEMS-RUNTIME-PREVIEW.png';
const items = ['pick', 'sickle', 'hoe', 'axe', 'shears', 'knife', 'lock'];
const tileW = 150, tileH = 250;

(async () => {
  const composites = [];
  for (let rank = 0; rank < 3; rank += 1) {
    for (let col = 0; col < items.length; col += 1) {
      const suffix = rank ? `-${rank}` : '';
      const file = `godot/art/items/${items[col]}${suffix}.png`;
      composites.push({ input: await sharp(file).png().toBuffer(), left: col * tileW + 11, top: rank * tileH + 13 });
    }
  }
  await sharp({ create: { width: tileW * items.length, height: tileH * 3, channels: 4,
    background: { r: 248, g: 238, b: 224, alpha: 1 } } })
    .composite(composites)
    .png()
    .toFile(output);
  console.log(path.resolve(output));
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
