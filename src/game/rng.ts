// seed 付きの乱数（mulberry32）。状態は 32bit の整数1つで、セーブにそのまま入る

export interface Rng { s: number }

export function next(r: Rng): number {
  let t = (r.s = (r.s + 0x6d2b79f5) | 0);
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

/** 0〜n-1 の整数 */
export function int(r: Rng, n: number): number {
  return n <= 1 ? 0 : Math.floor(next(r) * n);
}

/** a〜b の整数（両端を含む） */
export function range(r: Rng, a: number, b: number): number {
  return a + int(r, b - a + 1);
}

export function chance(r: Rng, p: number): boolean {
  return next(r) < p;
}

export function pick<T>(r: Rng, list: readonly T[]): T {
  return list[int(r, list.length)];
}

export function shuffle<T>(r: Rng, list: T[]): T[] {
  for (let i = list.length - 1; i > 0; i--) {
    const j = int(r, i + 1);
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
}

/** 重み付きの抽選 */
export function weighted<T>(r: Rng, list: readonly T[], weight: (item: T) => number): T | null {
  let total = 0;
  for (const item of list) total += Math.max(0, weight(item));
  if (total <= 0) return null;
  let roll = next(r) * total;
  for (const item of list) {
    roll -= Math.max(0, weight(item));
    if (roll < 0) return item;
  }
  return list[list.length - 1];
}

/** 文字列や数の組から seed を作る */
export function hashSeed(...parts: (string | number)[]): number {
  let h = 2166136261 >>> 0;
  for (const part of parts) {
    const text = String(part);
    for (let i = 0; i < text.length; i++) {
      h ^= text.charCodeAt(i);
      h = Math.imul(h, 16777619) >>> 0;
    }
    h ^= 0x9e3779b9;
    h = Math.imul(h, 16777619) >>> 0;
  }
  return h | 0;
}
