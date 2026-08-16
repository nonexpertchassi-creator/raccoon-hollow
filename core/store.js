/* store.js — 저장 계층.
 * 왜 이게 첫 파일이냐면: 양산형이든 찐 게임이든, 플레이어 데이터를 잃는 순간
 * 리텐션도 결제도 없다. 그리고 플랫폼마다 저장 위치가 다르다.
 *   web      → localStorage
 *   Android  → Capacitor Preferences (네이티브 SharedPreferences)
 *   Steam    → Steam Cloud / 파일시스템
 * 아래 Store는 그 셋을 같은 인터페이스로 감싸기 위한 껍데기다.
 * 지금은 web 드라이버 하나만 살아있고, 나머지는 이식할 때 driver만 갈아끼운다.
 */

const memory = new Map();

// localStorage는 sandbox/iframe/시크릿모드에서 throw 한다. 절대 그냥 쓰지 마라.
function probe() {
  try {
    const k = '__probe__';
    window.localStorage.setItem(k, '1');
    window.localStorage.removeItem(k);
    return true;
  } catch (_) {
    return false;
  }
}

const persistent = typeof window !== 'undefined' && probe();

export const Store = {
  persistent,

  get(key, fallback = null) {
    try {
      const raw = persistent ? window.localStorage.getItem(key) : memory.get(key);
      return raw == null ? fallback : JSON.parse(raw);
    } catch (_) {
      return fallback;
    }
  },

  set(key, value) {
    const raw = JSON.stringify(value);
    try {
      if (persistent) window.localStorage.setItem(key, raw);
      else memory.set(key, raw);
    } catch (_) {
      memory.set(key, raw); // 용량 초과(QuotaExceeded)시 메모리로 강등
    }
    return value;
  },

  del(key) {
    try {
      if (persistent) window.localStorage.removeItem(key);
    } catch (_) {}
    memory.delete(key);
  },

  /** 여러 키를 한 번에 읽는다. 세이브 파일 전체를 통째로 다루고 싶을 때. */
  dump(prefix) {
    const out = {};
    const keys = persistent ? Object.keys(window.localStorage) : [...memory.keys()];
    for (const k of keys) if (k.startsWith(prefix)) out[k] = Store.get(k);
    return out;
  },
};
