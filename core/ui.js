/* ui.js — 광고/상점 오버레이.
 * 실제 광고 SDK도 캔버스 위에 네이티브 뷰나 iframe을 덮는다. 구조를 똑같이 흉내냈다.
 * 그래야 나중에 진짜 SDK로 바꿔도 레이아웃이 안 깨진다.
 */

const css = `
.sy-ov{position:fixed;inset:0;background:rgba(4,6,15,.88);display:flex;align-items:center;
justify-content:center;z-index:50;font-family:system-ui,-apple-system,sans-serif;backdrop-filter:blur(6px)}
.sy-card{background:#141829;border:1px solid #262b45;border-radius:18px;padding:26px;
width:min(400px,88vw);color:#e8ecff;box-shadow:0 24px 60px rgba(0,0,0,.6)}
.sy-card h3{margin:0 0 6px;font-size:19px}
.sy-sub{color:#8b93b8;font-size:13px;margin:0 0 18px;line-height:1.5}
.sy-adbox{background:linear-gradient(135deg,#1e2547,#2d1b47);border-radius:12px;height:190px;
display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;margin-bottom:16px;
border:1px solid #303760;position:relative;overflow:hidden}
.sy-adbox .tag{position:absolute;top:8px;left:8px;background:#f5c542;color:#231a00;font-size:10px;
font-weight:800;padding:2px 6px;border-radius:4px;letter-spacing:.4px}
.sy-adbox .skip{position:absolute;top:8px;right:8px;background:rgba(0,0,0,.5);font-size:11px;
padding:4px 9px;border-radius:6px;color:#c9d0f0}
.sy-btn{width:100%;padding:13px;border:0;border-radius:11px;font-size:15px;font-weight:700;
cursor:pointer;background:#4f7cff;color:#fff;margin-top:8px;transition:filter .15s}
.sy-btn:hover{filter:brightness(1.15)} .sy-btn:disabled{opacity:.45;cursor:not-allowed}
.sy-btn.ghost{background:#232840;color:#aab2d8}
.sy-row{display:flex;justify-content:space-between;align-items:center;padding:13px;
background:#1b2038;border-radius:11px;margin-bottom:9px;border:1px solid #262b45}
.sy-row b{display:block;font-size:14px} .sy-row span{font-size:11.5px;color:#8b93b8}
.sy-row button{background:#4f7cff;border:0;color:#fff;padding:8px 15px;border-radius:8px;
font-weight:700;cursor:pointer;font-size:13px;white-space:nowrap}
.sy-row button:disabled{background:#2b3150;color:#666f95;cursor:default}
.sy-banner{position:fixed;bottom:0;left:0;right:0;height:52px;background:#151a2e;
border-top:1px solid #262b45;display:flex;align-items:center;justify-content:center;
color:#7d85ab;font:600 12px system-ui;z-index:40;letter-spacing:.3px}
.sy-toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);background:#1b2038;
color:#e8ecff;padding:11px 18px;border-radius:10px;font:600 13px system-ui;z-index:60;
border:1px solid #303760;box-shadow:0 8px 24px rgba(0,0,0,.5)}
.sy-spin{width:26px;height:26px;border:3px solid #303760;border-top-color:#4f7cff;
border-radius:50%;animation:sysp .8s linear infinite}
@keyframes sysp{to{transform:rotate(360deg)}}
`;

let styled = false;
function ensureStyle() {
  if (styled) return;
  const s = document.createElement('style');
  s.textContent = css;
  document.head.appendChild(s);
  styled = true;
}

function overlay(html) {
  ensureStyle();
  const el = document.createElement('div');
  el.className = 'sy-ov';
  el.innerHTML = `<div class="sy-card">${html}</div>`;
  document.body.appendChild(el);
  return el;
}

export const UI = {
  /** 소리 끄기 버튼. 모바일에서 소리 못 끄는 게임은 그냥 닫힌다. */
  muteButton(Sfx, { top = 10, left = 12 } = {}) {
    ensureStyle();
    const b = document.createElement('button');
    b.style.cssText = `position:fixed;top:${top}px;left:${left}px;z-index:45;background:#1b2038;
      color:#8b93b8;border:1px solid #303760;border-radius:8px;padding:6px 10px;
      font:600 13px system-ui;cursor:pointer;line-height:1`;
    b.textContent = '🔊';
    b.title = '소리 켜기/끄기';
    b.onclick = () => { b.textContent = Sfx.toggleMute() ? '🔇' : '🔊'; };
    document.body.appendChild(b);
    return b;
  },

  /**
   * 광고 재생 UI. 실제 SDK 흐름을 그대로 따라간다:
   *   로딩(필 대기) → 재생(카운트다운) → 닫기 → 보상 지급
   * 리워드 광고에서 카운트다운 전에 닫으면 보상이 없다. 이게 완주율을 만든다.
   */
  async playAd(ads, format, { title = '광고', seconds = 5 } = {}) {
    const el = overlay(`
      <h3>${title}</h3>
      <p class="sy-sub">광고를 불러오는 중…</p>
      <div class="sy-adbox"><div class="sy-spin"></div></div>
    `);
    const sub = el.querySelector('.sy-sub');
    const box = el.querySelector('.sy-adbox');

    const res = await ads.show(format);

    if (!res.shown) {
      // 필이 안 됐을 때 유저에게 뭘 보여줄지가 실무의 진짜 난제다.
      // 보상형이면 그냥 줘야 하나? 안 주면 별점 1점이 날아온다.
      sub.textContent = '지금은 광고가 없습니다 (no fill)';
      box.innerHTML = `<div style="color:#7d85ab;font-size:13px">재고 없음 · 8% 확률로 발생</div>`;
      await new Promise((r) => {
        const b = document.createElement('button');
        b.className = 'sy-btn'; b.textContent = '닫기';
        b.onclick = r; el.querySelector('.sy-card').appendChild(b);
      });
      el.remove();
      return res;
    }

    // 재생 화면
    sub.textContent = format === 'rewarded'
      ? `끝까지 봐야 보상을 받습니다`
      : `잠시 후 계속됩니다`;
    box.innerHTML = `
      <div class="tag">AD</div><div class="skip" id="sy-skip">${seconds}</div>
      <div style="font-size:30px">🎯</div>
      <div style="font-weight:800;font-size:16px">RAID OF LEGEND SAGA</div>
      <div style="font-size:12px;color:#a8b0d8">지금 설치하면 10연차 무료!</div>`;

    let left = seconds;
    const skipEl = box.querySelector('#sy-skip');
    const closed = await new Promise((resolve) => {
      const timer = setInterval(() => {
        left -= 1;
        if (left > 0) { skipEl.textContent = left; return; }
        clearInterval(timer);
        skipEl.textContent = '✕ 닫기';
        skipEl.style.cursor = 'pointer';
        skipEl.onclick = () => resolve(true);
        const b = document.createElement('button');
        b.className = 'sy-btn'; b.textContent = '닫기';
        b.onclick = () => resolve(true);
        el.querySelector('.sy-card').appendChild(b);
      }, 1000);
      // 조기 이탈 경로: 카운트다운 중 배경 클릭
      el.onclick = (e) => { if (e.target === el && left > 0) { clearInterval(timer); resolve(false); } };
    });

    el.remove();
    return { ...res, rewarded: res.rewarded && closed };
  },

  /** 인앱상점. 실제 스토어 다이얼로그처럼 지연·실패가 있다. */
  store(billing, { title = '상점', note = '', onBuy } = {}) {
    const rows = Object.entries(billing.catalog).map(([sku, it]) => {
      const owned = it.type === 'non_consumable' && billing.has(sku);
      return `<div class="sy-row"><div><b>${it.name}</b><span>${it.desc}</span></div>
        <button data-sku="${sku}" ${owned ? 'disabled' : ''}>${owned ? '보유중' : '$' + it.price.toFixed(2)}</button></div>`;
    }).join('');

    const cut = Math.round(billing.cut() * 100);
    const el = overlay(`
      <h3>${title}</h3>
      <p class="sy-sub">${note}플랫폼(${billing.platform}) 수수료 ${cut}% — 표시가격의 ${100 - cut}%만 개발자 몫입니다.</p>
      ${rows}
      <button class="sy-btn ghost" id="sy-restore">구매 복원</button>
      <button class="sy-btn ghost" id="sy-close">닫기</button>
    `);

    el.querySelectorAll('[data-sku]').forEach((b) => {
      b.onclick = async () => {
        const sku = b.dataset.sku;
        b.disabled = true; b.textContent = '처리중…';
        const r = await billing.purchase(sku);
        if (r.ok) {
          UI.toast(`구매 완료 · 실수령 $${r.net.toFixed(2)}`);
          onBuy?.(sku, r);
          el.remove();
        } else {
          UI.toast(`결제 실패: ${r.reason}`);
          b.disabled = false; b.textContent = '$' + billing.catalog[sku].price.toFixed(2);
        }
      };
    });
    el.querySelector('#sy-restore').onclick = async () => {
      const owned = await billing.restore();
      UI.toast(`복원 ${Object.keys(owned).length}건`);
    };
    el.querySelector('#sy-close').onclick = () => el.remove();
    return el;
  },

  banner(text = 'AD · 320×50 배너 자리') {
    ensureStyle();
    const el = document.createElement('div');
    el.className = 'sy-banner';
    el.textContent = text;
    document.body.appendChild(el);
    return el;
  },

  toast(msg, ms = 2200) {
    ensureStyle();
    const el = document.createElement('div');
    el.className = 'sy-toast';
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), ms);
  },

  dialog(html) { return overlay(html); },
};
