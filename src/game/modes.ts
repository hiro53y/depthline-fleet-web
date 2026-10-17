// 無限の海と毎日の挑戦のステージを作る
import { AREAS, STAGE_COUNT, applyDifficulty, stage } from './data';
import { hashSeed, next, type Rng } from './rng';
import type { Difficulty, StageDef } from './types';

export const ENDLESS_ID = 100;
export const DAILY_ID = 200;

/** 波を越えるのに要る撃沈数 */
export function waveTarget(n: number): number {
  return 6 + n * 2;
}

/** 無限の海の波 n（本編のステージ相当で強くなり、30を越えるとさらに伸びる） */
export function endlessDef(n: number, d: Difficulty): StageDef {
  const sid = Math.min(STAGE_COUNT, 1 + n);
  const base = stage(sid);
  const over = Math.max(0, n + 1 - STAGE_COUNT);
  // 海域は5波ごとに巡る（ボスの回は手下の顔ぶれだけ使う）
  const area = AREAS[Math.floor((n - 1) / 5) % AREAS.length];
  const def: StageDef = {
    ...base,
    id: ENDLESS_ID + n,
    area: area.id,
    name: `無限の海 第${n}波`,
    objective: { kind: 'sink', n: 9999 },
    pool: area.pool(5),
    hpMul: base.hpMul * Math.pow(1.1, over),
    fireMul: base.fireMul * Math.pow(1.04, over),
    maxAlive: base.maxAlive + Math.floor(over / 4),
    reward: base.reward * 0.6,
    storm: area.id === 'storm' || undefined,
    ice: undefined,
    current: area.id === 'storm' ? 26 : 0,
    dark: area.id === 'abyss' || undefined,
  };
  return applyDifficulty(def, d);
}

export type DailyRule = 'deep' | 'swarm' | 'mines' | 'storm' | 'boats';
export const DAILY_RULES: Record<DailyRule, { name: string; desc: string }> = {
  deep: { name: '深い海の日', desc: '深い所の敵ばかり。爆雷が届くまでを読め。' },
  swarm: { name: '群れの日', desc: '小型潜水艇が群れで来る。連鎖の好機。' },
  mines: { name: '機雷の日', desc: '機雷敷設艦が多い。誘爆で一網打尽に。' },
  storm: { name: '大嵐の日', desc: '波が高く、海の流れが強い。' },
  boats: { name: '魚雷艇の日', desc: '海面を走る魚雷艇が次々に来る。' },
};

/** 端末の日付（YYYY-MM-DD） */
export function dateKey(d: Date = new Date()): string {
  const z = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${z(d.getMonth() + 1)}-${z(d.getDate())}`;
}

export function dailyRule(date: string): DailyRule {
  const r: Rng = { s: hashSeed('daily', date) };
  const list = Object.keys(DAILY_RULES) as DailyRule[];
  return list[Math.floor(next(r) * list.length)];
}

export function dailyDef(date: string, unlocked: number, d: Difficulty): { def: StageDef; rule: DailyRule } {
  const rule = dailyRule(date);
  const sid = Math.max(3, Math.min(STAGE_COUNT, unlocked));
  const base = stage(sid);
  const P = (enemy: string, weight: number) => ({ enemy, weight });
  let def: StageDef = { ...base, id: DAILY_ID, name: DAILY_RULES[rule].name, objective: { kind: 'sink', n: 18 + Math.floor(sid / 3) }, reward: base.reward * 1.3 };
  switch (rule) {
    case 'deep': def = { ...def, pool: [P('deep', 4), P('ghost', 2), P('layer', 1)], dark: true }; break;
    case 'swarm': def = { ...def, pool: [P('scout', 8), P('sub', 1)], maxAlive: base.maxAlive + 3, interval: base.interval * 0.5, objective: { kind: 'sink', n: 30 + sid } }; break;
    case 'mines': def = { ...def, pool: [P('layer', 5), P('sub', 2), P('scout', 2)] }; break;
    case 'storm': def = { ...def, pool: AREAS[2].pool(5), storm: true, current: 40 }; break;
    case 'boats': def = { ...def, pool: [P('boat', 5), P('sub', 2), P('hunter', 1)], objective: { kind: 'survive', t: 60 } }; break;
  }
  return { def: applyDifficulty(def, d), rule };
}
