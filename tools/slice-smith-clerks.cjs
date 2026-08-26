#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const root = path.resolve(__dirname, '..');
const sourceDir = path.join(root, 'docs/art/generated');
const outputDir = path.join(root, 'godot/art/clerks');
const previewPath = path.join(sourceDir, 'SMITH-CLERK-RUNTIME-24-PREVIEW-V0.2.png');
const types = ['a', 'b', 'c', 'd'];
const sourceRevision = { a: 'P02', b: 'P03', c: 'P02', d: 'P03' };
// The source sheet keeps all four diagonals for art review. Runtime only needs
// the two right-facing masters; Godot mirrors them for left-facing movement.
const directions = [
  { column: 1, name: 'side' }, // down-right
  { column: 3, name: 'back' }, // up-right
];
const canvas = 144;

function isBackground(r, g, b) {
  return Math.min(r, g, b) >= 225 && Math.max(r, g, b) - Math.min(r, g, b) <= 12;
}

function clearConnectedBackground(rgb, width, height) {
  const count = width * height;
  const seen = new Uint8Array(count);
  const queue = new Int32Array(count);
  let head = 0;
  let tail = 0;

  const enqueue = (index) => {
    if (seen[index]) return;
    const p = index * 3;
    if (!isBackground(rgb[p], rgb[p + 1], rgb[p + 2])) return;
    seen[index] = 1;
    queue[tail++] = index;
  };

  for (let x = 0; x < width; x += 1) {
    enqueue(x);
    enqueue((height - 1) * width + x);
  }
  for (let y = 0; y < height; y += 1) {
    enqueue(y * width);
    enqueue(y * width + width - 1);
  }

  while (head < tail) {
    const index = queue[head++];
    const x = index % width;
    const y = Math.floor(index / width);
    if (x > 0) enqueue(index - 1);
    if (x + 1 < width) enqueue(index + 1);
    if (y > 0) enqueue(index - width);
    if (y + 1 < height) enqueue(index + width);
  }

  // The generated checker sometimes leaves tiny enclosed neutral islands.
  // Keep only the largest connected foreground component: the complete character.
  const visited = new Uint8Array(count);
  const keep = new Uint8Array(count);
  let largest = [];
  for (let start = 0; start < count; start += 1) {
    if (seen[start] || visited[start]) continue;
    const component = [];
    head = 0;
    tail = 0;
    visited[start] = 1;
    queue[tail++] = start;
    while (head < tail) {
      const index = queue[head++];
      component.push(index);
      const x = index % width;
      const y = Math.floor(index / width);
      const visit = (next) => {
        if (seen[next] || visited[next]) return;
        visited[next] = 1;
        queue[tail++] = next;
      };
      if (x > 0) visit(index - 1);
      if (x + 1 < width) visit(index + 1);
      if (y > 0) visit(index - width);
      if (y + 1 < height) visit(index + width);
    }
    if (component.length > largest.length) largest = component;
  }
  for (const index of largest) keep[index] = 1;

  const rgba = Buffer.alloc(count * 4);
  let minX = width;
  let minY = height;
  let maxX = -1;
  let maxY = -1;
  for (let i = 0; i < count; i += 1) {
    const src = i * 3;
    const dst = i * 4;
    rgba[dst] = rgb[src];
    rgba[dst + 1] = rgb[src + 1];
    rgba[dst + 2] = rgb[src + 2];
    rgba[dst + 3] = keep[i] ? 255 : 0;
    if (keep[i]) {
      const x = i % width;
      const y = Math.floor(i / width);
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < 0 || maxY < 0) throw new Error('No foreground found in cell');
  return { rgba, box: { left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 } };
}

async function main() {
  fs.mkdirSync(outputDir, { recursive: true });
  const cells = [];

  for (const type of types) {
    const input = path.join(sourceDir, `CLERK-SMITH-TYPE-${type.toUpperCase()}-GROWTH-DIAGONALS-V0.1-${sourceRevision[type]}.png`);
    const image = sharp(input).removeAlpha();
    const meta = await image.metadata();
    if (meta.width !== 1536 || meta.height !== 1024) throw new Error(`Unexpected sheet size: ${input}`);

    for (let rank = 0; rank < 3; rank += 1) {
      const top = Math.round(rank * meta.height / 3);
      const bottom = Math.round((rank + 1) * meta.height / 3);
      for (const direction of directions) {
        const left = direction.column * (meta.width / 4);
        const { data, info } = await sharp(input)
          .removeAlpha()
          .extract({ left, top, width: meta.width / 4, height: bottom - top })
          .raw()
          .toBuffer({ resolveWithObject: true });
        const cut = clearConnectedBackground(data, info.width, info.height);
        cells.push({ type, rank, direction: direction.name, width: info.width, height: info.height, ...cut });
      }
    }
  }

  const maxWidth = Math.max(...cells.map((cell) => cell.box.width));
  const maxHeight = Math.max(...cells.map((cell) => cell.box.height));
  const scale = Math.min(134 / maxWidth, 140 / maxHeight);
  const preview = [];

  for (const cell of cells) {
    const width = Math.max(1, Math.round(cell.box.width * scale));
    const height = Math.max(1, Math.round(cell.box.height * scale));
    const cropped = await sharp(cell.rgba, { raw: { width: cell.width, height: cell.height, channels: 4 } })
      .extract(cell.box)
      .resize(width, height, { fit: 'fill', kernel: sharp.kernel.lanczos3 })
      .png()
      .toBuffer();
    const sprite = await sharp({
      create: { width: canvas, height: canvas, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
    }).composite([{ input: cropped, left: Math.floor((canvas - width) / 2), top: canvas - height }]).png().toBuffer();
    const suffix = cell.rank === 0 ? '' : `-${cell.rank}`;
    const filename = `smith-${cell.type}-${cell.direction}${suffix}.png`;
    fs.writeFileSync(path.join(outputDir, filename), sprite);
    preview.push({
      input: sprite,
      left: (cell.rank * directions.length + directions.findIndex((direction) => direction.name === cell.direction)) * canvas,
      top: types.indexOf(cell.type) * canvas,
    });
  }

  await sharp({
    create: { width: canvas * 6, height: canvas * 4, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite(preview).png().toFile(previewPath);

  console.log(`Wrote ${cells.length} sprites to ${path.relative(root, outputDir)}`);
  console.log(`Shared scale ${scale.toFixed(4)} from max foreground ${maxWidth}x${maxHeight}`);
  console.log(`Preview ${path.relative(root, previewPath)}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
