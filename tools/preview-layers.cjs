#!/usr/bin/env node
'use strict';

const sharp = require('sharp');
const path = require('path');

const output = process.argv[2] || 'docs/art/generated/HERO-TYPES-RUNTIME-PREVIEW.png';
const types = ['a', 'b', 'c', 'd'];
const views = ['front', 'side', 'back'];
const tile = 180;

(async () => {
  const composites = [];
  for (let row = 0; row < types.length; row += 1) {
    for (let col = 0; col < views.length; col += 1) {
      const type = types[row], view = views[col];
      const layers = [];
      if (view === 'side') layers.push(`godot/art/hero-tail/${type}-side.png`);
      layers.push(`godot/art/hero-body/${type}-${view}.png`);
      if (view === 'back') layers.push(`godot/art/hero-tail/${type}-back.png`);
      for (const layer of layers) {
        layers[ layers.indexOf(layer) ] = await sharp(layer).png().toBuffer();
      }
      for (const input of layers) composites.push({ input, left: col * tile + 18, top: row * tile + 18 });
    }
  }
  await sharp({
    create: { width: tile * views.length, height: tile * types.length, channels: 4,
      background: { r: 248, g: 238, b: 224, alpha: 1 } },
  }).composite(composites).png().toFile(output);
  console.log(path.resolve(output));
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
