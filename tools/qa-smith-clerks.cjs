#!/usr/bin/env node

const path = require('path');
const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const root = path.resolve(__dirname, '..');
const artDir = path.join(root, 'godot/art/clerks');
const types = ['a', 'b', 'c', 'd'];
const directions = ['side', 'back'];

function largestComponent(data, width, height) {
  const seen = new Uint8Array(width * height);
  const queue = new Int32Array(width * height);
  let largest = null;

  for (let seed = 0; seed < width * height; seed += 1) {
    if (seen[seed] || data[seed * 4 + 3] <= 16) continue;
    let head = 0;
    let tail = 0;
    let count = 0;
    let minX = width;
    let minY = height;
    let maxX = -1;
    let maxY = -1;
    seen[seed] = 1;
    queue[tail++] = seed;

    while (head < tail) {
      const index = queue[head++];
      const x = index % width;
      const y = Math.floor(index / width);
      count += 1;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
      const visit = (next) => {
        if (seen[next] || data[next * 4 + 3] <= 16) return;
        seen[next] = 1;
        queue[tail++] = next;
      };
      if (x > 0) visit(index - 1);
      if (x + 1 < width) visit(index + 1);
      if (y > 0) visit(index - width);
      if (y + 1 < height) visit(index + width);
    }

    const box = { count, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1, bottom: maxY };
    if (!largest || box.count > largest.count) largest = box;
  }
  return largest;
}

async function inspect(filename) {
  const { data, info } = await sharp(path.join(artDir, filename)).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  if (info.width !== 144 || info.height !== 144 || info.channels !== 4) {
    throw new Error(`${filename}: expected 144x144 RGBA, got ${info.width}x${info.height}x${info.channels}`);
  }
  const body = largestComponent(data, info.width, info.height);
  if (!body) throw new Error(`${filename}: no visible pixels`);
  return body;
}

async function main() {
  const rows = [];
  let failed = false;
  for (let rank = 0; rank < 3; rank += 1) {
    const suffix = rank === 0 ? '' : `-${rank}`;
    for (const direction of directions) {
      const measurements = {};
      for (const type of types) {
        const filename = `smith-${type}-${direction}${suffix}.png`;
        measurements[type] = await inspect(filename);
      }
      const reference = measurements.a;
      for (const type of types) {
        const body = measurements[type];
        const center = body.x + body.width / 2;
        const referenceCenter = reference.x + reference.width / 2;
        const deltas = {
          dWidth: Math.abs(body.width - reference.width),
          dHeight: Math.abs(body.height - reference.height),
          dCenter: Math.abs(center - referenceCenter),
          dBottom: Math.abs(body.bottom - reference.bottom),
        };
        const pass = deltas.dWidth <= 3 && deltas.dHeight <= 3 && deltas.dCenter <= 2 && deltas.dBottom === 0;
        failed ||= !pass;
        rows.push({ rank: rank + 1, direction, type: type.toUpperCase(), ...body, ...deltas, pass });
      }
    }
  }

  console.table(rows.map(({ count, ...row }) => row));
  if (failed) throw new Error('A-D core-body geometry differs beyond the blueprint tolerance');
  console.log('PASS: 24/24 sprites are 144x144 RGBA and A-D core-body geometry is within tolerance.');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
