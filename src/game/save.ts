// 保存：進みと設定。壊れたデータは読まない（Flutter 版の保存は別の場所で、読まない・消さない）
import { SHIP_IDS, SPECIAL_IDS, STAGE_COUNT, UPGRADES } from './data';
import { PROGRESS_VERSION } from './progress';
import { DEFAULT_SETTINGS, type Progress, type Settings } from './types';

export const KEY_PROGRESS = 'depthline-fleet-v2:progress';
export const KEY_SETTINGS = 'depthline-fleet-v2:settings';

export interface KV {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

function store(): KV | null {
  try {
    return (globalThis as { localStorage?: KV }).localStorage ?? null;
  } catch {
    return null;
  }
}

const num = (n: unknown) => typeof n === 'number' && Number.isFinite(n);

export function validProgress(v: unknown): v is Progress {
  const p = v as Progress;
  if (!p || p.v !== PROGRESS_VERSION) return false;
  if (p.difficulty !== 'normal' && p.difficulty !== 'captain') return false;
  if (![p.gold, p.unlocked, p.seed].every(num) || p.gold < 0 || p.unlocked < 1 || p.unlocked > STAGE_COUNT) return false;
  if (!SHIP_IDS.includes(p.ship) || !Array.isArray(p.ships) || !p.ships.includes(p.ship) || !p.ships.every((s) => SHIP_IDS.includes(s))) return false;
  if (!SPECIAL_IDS.includes(p.special) || !Array.isArray(p.specials) || !p.specials.includes(p.special)) return false;
  if (!p.upgrades) return false;
  for (const s of SHIP_IDS) {
    const u = p.upgrades[s];
    if (!u) return false;
    for (const d of UPGRADES) if (!num(u[d.id]) || u[d.id] < 0 || u[d.id] > d.max) return false;
  }
  return !!p.stars && !!p.best && !!p.endless && !!p.daily && Array.isArray(p.tips) && !!p.stats;
}

export function parseProgress(text: string | null): Progress | null {
  if (!text) return null;
  try {
    const p = JSON.parse(text) as Progress;
    return validProgress(p) ? p : null;
  } catch {
    return null;
  }
}

function put(kv: KV | null, key: string, value: string | null) {
  if (!kv) return;
  try {
    if (value === null) kv.removeItem(key); else kv.setItem(key, value);
  } catch {
    // 容量不足などでも遊びは続ける
  }
}

function get(kv: KV | null, key: string): string | null {
  if (!kv) return null;
  try { return kv.getItem(key); } catch { return null; }
}

export function saveProgress(p: Progress | null, kv: KV | null = store()) { put(kv, KEY_PROGRESS, p ? JSON.stringify(p) : null); }
export function loadProgress(kv: KV | null = store()): Progress | null { return parseProgress(get(kv, KEY_PROGRESS)); }

export function saveSettings(s: Settings, kv: KV | null = store()) { put(kv, KEY_SETTINGS, JSON.stringify(s)); }
export function loadSettings(kv: KV | null = store()): Settings {
  try {
    const raw = get(kv, KEY_SETTINGS);
    if (!raw) return { ...DEFAULT_SETTINGS };
    const s = { ...DEFAULT_SETTINGS, ...(JSON.parse(raw) as Partial<Settings>) };
    s.bgm = Math.max(0, Math.min(1, Number(s.bgm) || 0));
    s.se = Math.max(0, Math.min(1, Number(s.se) || 0));
    return s;
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function wipe(kv: KV | null = store()) {
  put(kv, KEY_PROGRESS, null);
}
