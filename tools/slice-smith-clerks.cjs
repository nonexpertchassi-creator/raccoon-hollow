#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const sharp = require(process.env.CODEX_NODE_PATH ? `${process.env.CODEX_NODE_PATH}/sharp` : 'sharp');

const root = path.resolve(__dirname, '..');
const sourceDir = path.join(root, 'docs/art/generated');
const outputDir = path.join(root, 'godot/art/clerks');
const previewPath = path.join(sourceDir, 'SMITH-CLERK-RUNTIME-24-PREVIEW-V0.4.png');
const types = ['a', 'b', 'c', 'd'];
const sourceFiles = {
  a: 'CLERK-SMITH-TYPE-A-GROWTH-RUNTIME-DIRECTIONS-V0.1-P01.png',
  b: 'CLERK-SMITH-TYPE-B-GROWTH-RUNTIME-DIRECTIONS-V0.1-P01.png',
  c: 'CLERK-SMITH-TYPE-C-GROWTH-RUNTIME-DIRECTIONS-V0.1-P02.png',
  d: 'CLERK-SMITH-TYPE-D-GROWTH-RUNTIME-DIRECTIONS-V0.1-P02.png',
};
// Only the two right-facing masters are produced. Godot mirrors them for left-facing movement.
const directions = [
  { column: 0, name: 'side', targetWidth: 110, targetHeight: 134 }, // down-right
  { column: 1, name: 'back', targetWidth: 97, targetHeight: 130 }, // up-right
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

  // The generated checker sometimes leaves enclosed neutral islands. Keep every
  // component containing real colored ink so a detached tail or hand cannot vanish.
  const visited = new Uint8Array(count);
  const keep = new Uint8Array(count);
  const keptComponents = [];
  for (let start = 0; start < count; start += 1) {
    if (seen[start] || visited[start]) continue;
    const component = [];
    let ink = 0;
    let componentMinX = width;
    let componentMinY = height;
    let componentMaxX = -1;
    let componentMaxY = -1;
    head = 0;
    tail = 0;
    visited[start] = 1;
    queue[tail++] = start;
    while (head < tail) {
      const index = queue[head++];
      component.push(index);
      const pixel = index * 3;
      const x = index % width;
      const y = Math.floor(index / width);
      if (!isBackground(rgb[pixel], rgb[pixel + 1], rgb[pixel + 2])) {
        ink += 1;
        componentMinX = Math.min(componentMinX, x);
        componentMinY = Math.min(componentMinY, y);
        componentMaxX = Math.max(componentMaxX, x);
        componentMaxY = Math.max(componentMaxY, y);
      }
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
    if (ink >= 12) {
      for (const index of component) keep[index] = 1;
      keptComponents.push({
        ink,
        left: componentMinX,
        top: componentMinY,
        width: componentMaxX - componentMinX + 1,
        height: componentMaxY - componentMinY + 1,
      });
    }
  }

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
  const bodyBox = keptComponents.sort((a, b) => b.ink - a.ink)[0];
  return {
    rgba,
    bodyBox,
    box: { left: minX, top: minY, width: maxX - minX + 1, height: maxY - minY + 1 },
  };
}

async function main() {
  fs.mkdirSync(outputDir, { recursive: true });
  const cells = [];

  for (const type of types) {
    const input = path.join(sourceDir, sourceFiles[type]);
    const image = sharp(input).removeAlpha();
    const meta = await image.metadata();
    if (!meta.width || !meta.height) throw new Error(`Unexpected sheet size: ${input}`);
    const cellWidth = Math.floor(meta.width / 2);

    for (let rank = 0; rank < 3; rank += 1) {
      const top = Math.round(rank * meta.height / 3);
      const bottom = Math.round((rank + 1) * meta.height / 3);
      for (const direction of directions) {
        // Generated sheets may contain a one-pixel center seam. Discard it
        // instead of shifting the right-facing cell off its visual center.
        const left = direction.column === 0 ? 0 : meta.width - cellWidth;
        const { data, info } = await sharp(input)
          .removeAlpha()
          .extract({ left, top, width: cellWidth, height: bottom - top })
          .raw()
          .toBuffer({ resolveWithObject: true });
        const cut = clearConnectedBackground(data, info.width, info.height);
        cells.push({ type, rank, direction: direction.name, width: info.width, height: info.height, ...cut });
      }
    }
  }

  const preview = [];
  const bodyTargets = new Map();

  for (const cell of cells.filter((entry) => entry.type === 'a')) {
    const direction = directions.find((entry) => entry.name === cell.direction);
    bodyTargets.set(`${cell.rank}:${cell.direction}`, {
      width: cell.bodyBox.width * direction.targetWidth / cell.box.width,
      height: cell.bodyBox.height * direction.targetHeight / cell.box.height,
    });
  }

  for (const cell of cells) {
    const target = bodyTargets.get(`${cell.rank}:${cell.direction}`);
    const scaleX = target.width / cell.bodyBox.width;
    const scaleY = target.height / cell.bodyBox.height;
    const width = Math.round(cell.box.width * scaleX);
    const height = Math.round(cell.box.height * scaleY);
    const bodyLeft = Math.round((cell.bodyBox.left - cell.box.left) * scaleX);
    const bodyTop = Math.round((cell.bodyBox.top - cell.box.top) * scaleY);
    const bodyWidth = Math.round(cell.bodyBox.width * scaleX);
    const bodyHeight = Math.round(cell.bodyBox.height * scaleY);
    const cropped = await sharp(cell.rgba, { raw: { width: cell.width, height: cell.height, channels: 4 } })
      .extract(cell.box)
      .resize(width, height, { fit: 'fill', kernel: sharp.kernel.lanczos3 })
      .png()
      .toBuffer();
    const left = Math.round(canvas / 2 - bodyLeft - bodyWidth / 2);
    const top = canvas - bodyTop - bodyHeight;
    const margin = canvas;
    if (
      width > canvas * 3 || height > canvas * 3 ||
      left + margin < 0 || top + margin < 0 ||
      left + margin + width > canvas * 3 || top + margin + height > canvas * 3
    ) {
      throw new Error(`Invalid crop ${cell.type}${cell.rank}-${cell.direction}: ${width}x${height} at ${left},${top}; body ${cell.bodyBox.width}x${cell.bodyBox.height}`);
    }
    const staged = await sharp({
      create: {
        width: canvas + margin * 2,
        height: canvas + margin * 2,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      },
    })
      .composite([{ input: cropped, left: left + margin, top: top + margin }])
      .png()
      .toBuffer();
    const sprite = await sharp(staged)
      .extract({ left: margin, top: margin, width: canvas, height: canvas })
      .png()
      .toBuffer();
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
  console.log('Normalized A-D by A core-body geometry; detached tails do not shrink the body');
  console.log(`Preview ${path.relative(root, previewPath)}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
