/* telemetry.js — 퍼널 계측.
 *
 * "어떻게 수익이 발견되는지"의 답은 사실 여기서 나온다. 광고비도 결제도
 * 아래 숫자들의 함수일 뿐이다. 게임사가 실제로 매일 보는 지표를 그대로 옮겼다:
 *
 *   session_start      세션 수      → DAU
 *   game_start         플레이 수    → 세션당 플레이 (참여도)
 *   game_over          이탈 지점    → 난이도 튜닝
 *   ad_request/fill/impression/click/reward
 *                                  → 필레이트, CTR, eCPM (광고 매출의 전부)
 *   store_open/purchase_intent/purchase_success/purchase_fail
 *                                  → 결제 퍼널. 여기 드랍이 곧 잃은 돈
 *   d1_return          복귀        → 리텐션
 *
 * 지금은 로컬에만 쌓는다. 실제 출시 땐 sink 를 GA4 / Firebase / PostHog 로 바꾼다.
 * 스키마를 처음부터 이렇게 잡아두면 나중에 갈아끼울 때 게임 코드는 안 건드린다.
 */

import { Store } from './store.js';

const LOG_KEY = 'sy:telemetry:log';
const MAX_EVENTS = 2000; // 무한히 쌓이면 저장소가 터진다

let sinks = [];
let ctx = {};

function today() {
  return new Date().toISOString().slice(0, 10);
}

export const Telemetry = {
  /** game: 게임 id. 모든 이벤트에 자동으로 붙는다. */
  init(game) {
    ctx = { game, session: Math.random().toString(36).slice(2, 10) };

    // 리텐션 계산용 방문일 기록
    const days = Store.get('sy:days', []);
    if (!days.includes(today())) {
      days.push(today());
      Store.set('sy:days', days.slice(-90));
    }
    const installedAt = Store.get('sy:installedAt') || Store.set('sy:installedAt', today());

    Telemetry.track('session_start', {
      day_index: days.length,
      days_since_install: Math.round(
        (Date.parse(today()) - Date.parse(installedAt)) / 86400000
      ),
      persistent: Store.persistent,
    });
    return Telemetry;
  },

  /** 외부 분석 도구를 붙이는 자리. sink(event) 형태의 함수. */
  addSink(fn) {
    sinks.push(fn);
  },

  track(name, props = {}) {
    const ev = { t: Date.now(), name, ...ctx, ...props };
    const log = Store.get(LOG_KEY, []);
    log.push(ev);
    Store.set(LOG_KEY, log.slice(-MAX_EVENTS));
    for (const s of sinks) {
      try { s(ev); } catch (_) {}
    }
    return ev;
  },

  all() {
    return Store.get(LOG_KEY, []);
  },

  clear() {
    Store.del(LOG_KEY);
  },

  /** 대시보드가 먹을 요약. 실제 퍼블리셔 리포트와 같은 계산식. */
  summary() {
    const log = Telemetry.all();
    const c = (n) => log.filter((e) => e.name === n).length;
    const revenue = log
      .filter((e) => e.name === 'ad_impression' || e.name === 'purchase_success')
      .reduce((s, e) => s + (e.revenue_usd || 0), 0);

    const impressions = c('ad_impression');
    const days = Store.get('sy:days', []).length;

    return {
      days_active: days,
      sessions: c('session_start'),
      plays: c('game_start'),
      plays_per_session: ratio(c('game_start'), c('session_start')),

      // 광고: 요청 → 필 → 노출 → 클릭. 각 단계 드랍이 손실이다.
      ad_requests: c('ad_request'),
      fill_rate: pct(c('ad_fill'), c('ad_request')),
      impressions,
      ctr: pct(c('ad_click'), impressions),
      // eCPM = 1000노출당 매출. 광고 매출의 유일한 환율.
      ecpm: impressions
        ? (log.filter((e) => e.name === 'ad_impression')
              .reduce((s, e) => s + (e.revenue_usd || 0), 0) / impressions) * 1000
        : 0,

      // 결제: 상점 진입 → 시도 → 성공. 사이의 드랍이 잃은 돈.
      store_opens: c('store_open'),
      purchase_intents: c('purchase_intent'),
      purchases: c('purchase_success'),
      purchase_fails: c('purchase_fail'),
      conversion: pct(c('purchase_success'), c('store_open')),

      revenue_usd: revenue,
      // ARPDAU = 일일 활성 유저당 매출. 퍼블리셔가 제일 먼저 보는 한 줄.
      arpdau: days ? revenue / days : 0,
    };
  },
};

function ratio(a, b) { return b ? +(a / b).toFixed(2) : 0; }
function pct(a, b) { return b ? +((a / b) * 100).toFixed(1) : 0; }
