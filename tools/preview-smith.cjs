#!/usr/bin/env node
'use strict';

const sharp = require('sharp');
const path = require('path');

const output = process.argv[2] || 'docs/art/generated/SMITH-GEAR-RUNTIME-PREVIEW.png';
const views = ['front', 'side', 'back'];
const tile = 180;

(async () => {
  const composites = [];
  for (let rank = 1; rank <= 3; rank += 1) {
    for (let col = 0; col < views.length; col += 1) {
      const view = views[col];
      const paths = [];
      if (view === 'side') paths.push('godot/art/hero-tail/a-side.png');
      paths.push(`godot/art/hero-body/a-${view}.png`);
      paths.push(`godot/art/gear/smith-${rank}-${view}.png`);
      if (view === 'back') paths.push('godot/art/hero-tail/a-back.png');
      for (const file of paths) {
        composites.push({ input: await sharp(file).png().toBuffer(), left: col * tile + 18, top: (rank - 1) * tile + 18 });
      }
    }
  }
  await sharp({
    create: { width: tile * views.length, height: tile * 3, channels: 4,
      background: { r: 248, g: 238, b: 224, alpha: 1 } },
  }).composite(composites).png().toFile(output);
  console.log(path.resolve(output));
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
