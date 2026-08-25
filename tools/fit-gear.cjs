#!/usr/bin/env node
'use strict';

// 장비 원화에서 떨어져 있는 앞치마와 망치를 각각 찾아, 손을 가리지 않는 핀에 앉힌다.
const sharp = require('sharp');

const [input, output, view] = process.argv.slice(2);
if (!input || !output || !['front', 'side', 'back'].includes(view)) {
  console.error('usage: fit-gear input.png output.png front|side|back');
  process.exit(2);
}

const slots = {
  front: { hammer: [15, 45, 34, 82], apron: [44, 86, 62, 42] },
  side:  { apron: [46, 84, 48, 44], hammer: [93, 61, 51, 23] },
  back:  { hammer: [16, 45, 34, 82], apron: [43, 84, 62, 44] },
};

(async () => {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const seen = new Uint8Array(info.width * info.height);
  const components = [];
  const queue = new Int32Array(info.width * info.height);
  const alphaAt = (index) => data[index * 4 + 3];

  for (let seed = 0; seed < seen.length; seed += 1) {
    if (seen[seed] || alphaAt(seed) <= 32) continue;
    let head = 0, tail = 0;
    queue[tail++] = seed;
    seen[seed] = 1;
    const pixels = [];
    let minX = info.width, minY = info.height, maxX = -1, maxY = -1;
    while (head < tail) {
      const index = queue[head++];
      pixels.push(index);
      const x = index % info.width, y = Math.floor(index / info.width);
      minX = Math.min(minX, x); minY = Math.min(minY, y);
      maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
      const neighbors = [];
      if (x > 0) neighbors.push(index - 1);
      if (x + 1 < info.width) neighbors.push(index + 1);
      if (y > 0) neighbors.push(index - info.width);
      if (y + 1 < info.height) neighbors.push(index + info.width);
      for (const next of neighbors) {
        if (seen[next] || alphaAt(next) <= 32) continue;
        seen[next] = 1;
        queue[tail++] = next;
      }
    }
    if (pixels.length > 500) components.push({ pixels, minX, minY, maxX, maxY });
  }
  components.sort((a, b) => b.pixels.length - a.pixels.length);
  if (components.length < 2) {
    // 측면은 망치 자루가 앞치마에, 뒷면은 망치 머리가 허리띠에 한 픽셀 닿아
    // 한 덩어리로 읽힐 수 있다. 두 물건 사이의 약속된 세로 골에서 나눈다.
    const whole = components[0];
    if (!whole) throw new Error('no equipment pixels');
    const spanX = whole.maxX - whole.minX, spanY = whole.maxY - whole.minY;
    let halves;
    if (view === 'back') {
      // 망치 머리는 앞치마보다 위, 자루는 훨씬 왼쪽이다. 두 영역을 조금 겹쳐
      // 잡아도 각자의 색면만 남기면 앞치마 왼쪽을 잘라 먹지 않는다.
      halves = [
        whole.pixels.filter((index) => {
          const x = index % info.width, y = Math.floor(index / info.width);
          return x <= whole.minX + spanX * 0.38
            && (y <= whole.minY + spanY * 0.28 || x <= whole.minX + spanX * 0.22);
        }),
        whole.pixels.filter((index) => {
          const x = index % info.width, y = Math.floor(index / info.width);
          return x >= whole.minX + spanX * 0.20 && y >= whole.minY + spanY * 0.22;
        }),
      ];
    } else {
      const splitX = Math.round(whole.minX + spanX * 0.39);
      halves = [whole.pixels.filter((index) => index % info.width <= splitX),
        whole.pixels.filter((index) => index % info.width > splitX)];
    }
    components.length = 0;
    for (const pixels of halves) {
      let minX = info.width, minY = info.height, maxX = -1, maxY = -1;
      for (const index of pixels) {
        const x = index % info.width, y = Math.floor(index / info.width);
        minX = Math.min(minX, x); minY = Math.min(minY, y);
        maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
      }
      components.push({ pixels, minX, minY, maxX, maxY });
    }
  }
  const pieces = components.slice(0, 2).sort((a, b) => a.minX - b.minX);
  const named = view === 'side' ? { apron: pieces[0], hammer: pieces[1] } : { hammer: pieces[0], apron: pieces[1] };

  const overlays = [];
  for (const name of ['apron', 'hammer']) {
    const part = named[name];
    const width = part.maxX - part.minX + 1, height = part.maxY - part.minY + 1;
    const raw = Buffer.alloc(width * height * 4);
    for (const index of part.pixels) {
      const x = index % info.width, y = Math.floor(index / info.width);
      const source = index * 4, target = ((y - part.minY) * width + x - part.minX) * 4;
      data.copy(raw, target, source, source + 4);
    }
    const [left, top, boxW, boxH] = slots[view][name];
    const image = await sharp(raw, { raw: { width, height, channels: 4 } })
      .resize(boxW, boxH, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png()
      .toBuffer();
    overlays.push({ input: image, left, top });
  }

  await sharp({ create: { width: 144, height: 144, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(overlays)
    .png()
    .toFile(output);
  console.log(`${output}: apron + hammer separated and pinned (${view})`);
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
