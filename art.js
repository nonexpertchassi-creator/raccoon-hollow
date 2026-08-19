/* art.js — 그림을 끼우는 자리.
 *
 * 규칙 하나: **그림이 없어도 게임은 그대로 돈다.**
 *
 * 이걸 지키면 32장을 다 그릴 때까지 기다릴 필요가 없다. 토끼 한 장이
 * 들어오면 토끼만 그림이 되고 나머지는 이모지로 남는다. 폰에서 실제
 * 크기로 확인해 가며 한 장씩 넣을 수 있다 — 24장을 다 그린 뒤에
 * "너무 작아서 뭔지 모르겠다"를 발견하면 24장을 다시 그려야 한다.
 *
 * 파일 자리:
 *   art/guests/rabbit.png   손님 12종      64×64
 *   art/items/pick.png      물건 17종      64×112
 *   art/pests/rat.png       나쁜 놈 2종    64×64
 *   art/pests/dog.png       삽살개         64×64
 *
 * 파일명은 content.js의 id 그대로다. 그것 말고 맞출 게 없다.
 *
 * 묶음 파일(artifact)로 낼 때는 그림을 못 불러온다 — 바깥 파일을 막기
 * 때문이다. 그래서 만드는 쪽에서 그림을 글자로 바꿔 심어 두고,
 * 여기서는 그 심어둔 것을 먼저 본다(window.ART_DATA).
 */

const cache = {};

export const Art = {
  /** 이 id의 그림을 쓸 수 있으면 그림, 아니면 null. */
  get(kind, id) {
    const key = `${kind}/${id}`;
    const c = cache[key];
    if (c === undefined) { this._start(kind, id, key); return null; }
    return c && c.ok ? c.img : null;
  },

  _start(kind, id, key) {
    cache[key] = null;                        // 두 번 시도하지 않는다
    const data = (typeof window !== 'undefined' && window.ART_DATA) || null;
    const src = data ? data[key] : `art/${kind}/${id}.png`;
    if (data && !src) return;                 // 묶음 안에 없다 = 아직 안 그린 것
    if (typeof Image === 'undefined') return; // 브라우저가 아니면 그림도 없다
    const img = new Image();
    const rec = { img, ok: false };
    img.onload = () => { rec.ok = true; };
    img.onerror = () => { rec.ok = false; };  // 없어도 조용히 넘어간다
    img.src = src;
    cache[key] = rec;
  },
};

/** 그림이 있으면 그리고 true, 없으면 아무것도 안 하고 false.
 *  x·y는 **발끝 가운데**다 — 코드가 발끝 높이로 앞뒤를 가리기 때문이다. */
export function drawArt(c, kind, id, x, footY, w, h) {
  const img = Art.get(kind, id);
  if (!img) return false;
  c.drawImage(img, x - w / 2, footY - h, w, h);
  return true;
}
