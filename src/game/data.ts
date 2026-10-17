// 表：海の形・艦・改造・特殊兵装・敵・海域・ステージ
import type { AreaId, Band, Difficulty, EnemyDef, ShipDef, ShipId, SpawnPick, SpecialId, StageDef, UpgradeId, Upgrades } from './types';

// ── 海の形（論理座標、縦 720×1280） ──
export const W = 720;
export const H = 1280;
/** 海面 */
export const WL = 230;
/** 海底 */
export const FLOOR = 1220;
export const BANDS: Record<Band, [number, number]> = {
  shallow: [290, 450],
  mid: [480, 690],
  deep: [720, 920],
  abyss: [950, 1170],
};
export const BAND_NAME: Record<Band, string> = { shallow: '浅い', mid: '中層', deep: '深い', abyss: '深淵' };
/** 深さによる点の倍率 */
export function depthMul(y: number): number {
  if (y < BANDS.mid[0]) return 1;
  if (y < BANDS.deep[0]) return 1.5;
  if (y < BANDS.abyss[0]) return 2;
  return 3;
}

// ── 艦 ──
export const SHIPS: Record<ShipId, ShipDef> = {
  destroyer: { id: 'destroyer', name: '駆逐艦', desc: '釣り合いのとれた主力艦。', hull: 5, speed: 300, reload: 0.42, capacity: 4, power: 1, radius: 72, price: 0, unlockStage: 0, color: '#9fb6c8' },
  corvette: { id: 'corvette', name: 'コルベット', desc: '速く身軽。装填も早いが船体は薄い。', hull: 4, speed: 390, reload: 0.33, capacity: 3, power: 1, radius: 66, price: 1800, unlockStage: 6, color: '#c8d8a0' },
  cruiser: { id: 'cruiser', name: '巡洋艦', desc: '重く遅いが、硬く、一度に多く落とせる。爆雷も大きい。', hull: 8, speed: 235, reload: 0.5, capacity: 6, power: 1.5, radius: 84, price: 5200, unlockStage: 18, color: '#c8a888' },
};
export const SHIP_IDS: ShipId[] = ['destroyer', 'corvette', 'cruiser'];

// ── 改造 ──
export interface UpgradeDef { id: UpgradeId; name: string; max: number; base: number; desc: (lv: number) => string }
export const UPGRADES: UpgradeDef[] = [
  { id: 'hull', name: '船体', max: 5, base: 120, desc: (lv) => `船体 +${lv}` },
  { id: 'engine', name: '機関', max: 5, base: 100, desc: (lv) => `速さ +${lv * 8}%` },
  { id: 'reload', name: '装填', max: 5, base: 140, desc: (lv) => `装填 -${lv * 8}%` },
  { id: 'capacity', name: '投下数', max: 4, base: 180, desc: (lv) => `同時に +${lv}発` },
  { id: 'power', name: '炸薬', max: 5, base: 200, desc: (lv) => `威力 +${lv * 25}%` },
  { id: 'radius', name: '爆発範囲', max: 5, base: 150, desc: (lv) => `範囲 +${lv * 8}%` },
  { id: 'sonar', name: 'ソナー', max: 5, base: 120, desc: (lv) => `探知 ${(8 - lv * 0.8).toFixed(1)}秒ごと・半径 ${300 + lv * 60}` },
  { id: 'special', name: '特殊兵装', max: 3, base: 260, desc: (lv) => `特殊兵装 Lv${lv + 1}` },
];
export function upgradeCost(id: UpgradeId, lv: number): number {
  const d = UPGRADES.find((u) => u.id === id)!;
  return Math.round((d.base * Math.pow(1.85, lv)) / 10) * 10;
}
export const emptyUpgrades = (): Upgrades => ({ hull: 0, engine: 0, reload: 0, capacity: 0, power: 0, radius: 0, sonar: 0, special: 0 });

// ── 特殊兵装 ──
export const SPECIALS: Record<SpecialId, { name: string; desc: string; price: number; unlockStage: number; color: string }> = {
  mortar: { name: '投射爆雷', desc: '左右遠くへ弧を描いて爆雷を3発ずつ撃ち出す。', price: 0, unlockStage: 0, color: '#ffb04a' },
  hedgehog: { name: '散布爆雷', desc: '真下へ扇状に小さな爆雷をばらまく。速く沈む。', price: 700, unlockStage: 3, color: '#9fe7ff' },
  torpedo: { name: '誘導魚雷', desc: '近い敵を追いかける魚雷を撃つ。ボスの区画にも強い。', price: 1500, unlockStage: 9, color: '#ff8a6a' },
  sonar: { name: 'ソナー爆発', desc: 'すべての敵をあばき、全体に打撃。敵の弾を消す。', price: 2200, unlockStage: 15, color: '#7dea8c' },
};
export const SPECIAL_IDS: SpecialId[] = ['mortar', 'hedgehog', 'torpedo', 'sonar'];

// ── 敵 ──
const E = (e: EnemyDef) => e;
export const ENEMIES: Record<string, EnemyDef> = Object.fromEntries([
  E({ id: 'scout', name: '小型潜水艇', cls: 'sub', hp: 1, speed: 140, bands: ['shallow', 'mid'], w: 92, h: 28, score: 100, gold: 6, fire: { kind: 'torpedo', every: 4.8, near: 110 }, color: '#7f9aa8', desc: '浅い所を速く走る。' }),
  E({ id: 'sub', name: '潜水艦', cls: 'sub', hp: 2, speed: 85, bands: ['mid'], w: 122, h: 34, score: 150, gold: 9, fire: { kind: 'torpedo', every: 3.6, near: 140 }, color: '#5f7d8c', desc: '真上へ魚雷を撃つ。' }),
  E({ id: 'deep', name: '深海潜水艦', cls: 'sub', hp: 4, speed: 55, bands: ['deep', 'abyss'], w: 142, h: 40, score: 300, gold: 16, fire: { kind: 'torpedo', every: 3.2, near: 170 }, color: '#4a5f74', desc: '深く硬い。爆雷が届くまで時間がかかる。' }),
  E({ id: 'layer', name: '機雷敷設艦', cls: 'sub', hp: 3, speed: 65, bands: ['mid', 'deep'], w: 132, h: 38, score: 250, gold: 14, fire: { kind: 'mine', every: 3.0 }, color: '#7a6a4a', desc: '浮き上がる機雷を残す。機雷は爆雷で誘爆する。' }),
  E({ id: 'hunter', name: '追尾潜水艦', cls: 'sub', hp: 3, speed: 70, bands: ['mid', 'deep'], w: 126, h: 36, score: 280, gold: 15, fire: { kind: 'homing', every: 4.2 }, color: '#8a4a4a', desc: '艦を追いかける魚雷を撃つ。' }),
  E({ id: 'boat', name: '魚雷艇', cls: 'boat', hp: 1, speed: 170, bands: ['shallow'], w: 84, h: 22, score: 120, gold: 7, color: '#b08a60', desc: '海面を走って体当たりしてくる。着水した爆雷で沈む。' }),
  E({ id: 'ghost', name: '影の潜水艦', cls: 'sub', hp: 3, speed: 60, bands: ['deep', 'abyss'], w: 128, h: 36, score: 400, gold: 20, fire: { kind: 'torpedo', every: 3.8, near: 160 }, stealth: true, color: '#3a4a6a', desc: '姿を消している。ソナーか、当たった時だけ見える。' }),
  // ── ボス ──
  E({
    id: 'titan', name: '巨大潜水艦', cls: 'boss', hp: 0, speed: 42, bands: ['mid'], w: 380, h: 92, score: 3000, gold: 220, color: '#55707f', desc: '3つの区画を壊すと沈む。手下を呼ぶ。',
    parts: [{ dx: -120, dy: 0, w: 120, h: 70, hp: 14, name: '艦首' }, { dx: 0, dy: -12, w: 110, h: 86, hp: 18, name: '司令塔' }, { dx: 120, dy: 0, w: 120, h: 70, hp: 14, name: '艦尾' }],
    bossFire: [{ kind: 'torpedo', every: 1.8 }, { kind: 'homing', every: 3.2 }, { kind: 'torpedo', every: 0.9 }], summon: 'scout',
  }),
  E({
    id: 'mother', name: '機雷母艦', cls: 'boss', hp: 0, speed: 34, bands: ['deep'], w: 360, h: 100, score: 4000, gold: 300, color: '#6a5a40', desc: '機雷を大量にまく。誘爆を使え。',
    parts: [{ dx: -115, dy: 0, w: 110, h: 76, hp: 18, name: '前の倉' }, { dx: 0, dy: -14, w: 110, h: 92, hp: 22, name: '艦橋' }, { dx: 115, dy: 0, w: 110, h: 76, hp: 18, name: '後ろの倉' }],
    bossFire: [{ kind: 'mine', every: 1.4 }, { kind: 'mine', every: 0.9 }, { kind: 'homing', every: 2.6 }], summon: 'layer',
  }),
  E({
    id: 'twin', name: '双胴潜水艦', cls: 'boss', hp: 0, speed: 48, bands: ['mid', 'deep'], w: 400, h: 120, score: 5000, gold: 380, color: '#5a6a8a', desc: '2つの船体が上下に揺れながら進む。',
    parts: [{ dx: -130, dy: -26, w: 130, h: 60, hp: 22, name: '左の船体' }, { dx: 0, dy: 0, w: 100, h: 50, hp: 16, name: '連結部' }, { dx: 130, dy: 26, w: 130, h: 60, hp: 22, name: '右の船体' }],
    bossFire: [{ kind: 'torpedo', every: 1.4 }, { kind: 'homing', every: 2.4 }, { kind: 'torpedo', every: 0.7 }], summon: 'hunter',
  }),
  E({
    id: 'fortress', name: '深淵の要塞', cls: 'boss', hp: 0, speed: 22, bands: ['abyss'], w: 420, h: 130, score: 6500, gold: 480, color: '#3a4a5a', desc: '深淵に潜む動く要塞。砲塔から追尾魚雷。',
    parts: [{ dx: -140, dy: -20, w: 100, h: 70, hp: 24, name: '左の砲塔' }, { dx: 0, dy: 0, w: 140, h: 110, hp: 34, name: '動力炉' }, { dx: 140, dy: -20, w: 100, h: 70, hp: 24, name: '右の砲塔' }],
    bossFire: [{ kind: 'homing', every: 3.0 }, { kind: 'mine', every: 2.4 }, { kind: 'homing', every: 1.8 }], summon: 'ghost',
  }),
  E({
    id: 'flagship', name: '敵の旗艦', cls: 'boss', hp: 0, speed: 38, bands: ['deep'], w: 440, h: 116, score: 9000, gold: 700, color: '#6a4a5a', desc: '最後の敵。あらゆる攻撃を使う。',
    parts: [{ dx: -150, dy: 0, w: 130, h: 80, hp: 30, name: '艦首' }, { dx: 0, dy: -14, w: 120, h: 100, hp: 40, name: '艦橋' }, { dx: 150, dy: 0, w: 130, h: 80, hp: 30, name: '艦尾' }],
    bossFire: [{ kind: 'torpedo', every: 1.2 }, { kind: 'homing', every: 2.2 }, { kind: 'mine', every: 1.0 }], summon: 'ghost',
  }),
].map((e) => [e.id, e]));

export function enemy(id: string): EnemyDef {
  const e = ENEMIES[id];
  if (!e) throw new Error(`unknown enemy ${id}`);
  return e;
}

// ── 海域とステージ ──
export const STAGE_COUNT = 30;
export const PER_AREA = 6;

export interface AreaDef { id: AreaId; name: string; desc: string; sky: [string, string]; sea: [string, string, string]; boss: string; pool: (k: number) => SpawnPick[] }

const P = (enemy: string, weight: number): SpawnPick => ({ enemy, weight });
export const AREAS: AreaDef[] = [
  { id: 'shelf', name: '大陸棚', desc: '浅く明るい海。基本を覚える。', sky: ['#8ec8f0', '#d8f0ff'], sea: ['#1d7aa0', '#0f4a6e', '#082a40'], boss: 'titan',
    pool: (k) => [P('scout', 5), P('sub', 4), ...(k >= 3 ? [P('boat', 1)] : []), ...(k >= 4 ? [P('layer', 1)] : [])] },
  { id: 'convoy', name: '船団航路', desc: '味方の船団を守る海。魚雷艇が多い。', sky: ['#f0b880', '#ffe0c0'], sea: ['#1a6a8a', '#0d3e5e', '#06243a'], boss: 'mother',
    pool: (k) => [P('sub', 4), P('scout', 3), P('boat', 2), P('layer', 1), ...(k >= 3 ? [P('hunter', 1)] : [])] },
  { id: 'storm', name: '嵐の海', desc: '波で艦が揺れ、視界が悪い。', sky: ['#3a4a5a', '#6a7a8a'], sea: ['#245a6a', '#123a4a', '#06202c'], boss: 'twin',
    pool: () => [P('sub', 3), P('hunter', 2), P('boat', 3), P('deep', 1), P('scout', 2)] },
  { id: 'ice', name: '氷の海', desc: '流氷が爆雷を止める。深い敵が多い。', sky: ['#c8d8e8', '#f0f8ff'], sea: ['#2a7a9a', '#164a68', '#082840'], boss: 'fortress',
    pool: () => [P('deep', 2), P('layer', 3), P('hunter', 2), P('sub', 3)] },
  { id: 'abyss', name: '深淵', desc: '暗い海。ソナーで影を探せ。', sky: ['#1a1030', '#3a2a50'], sea: ['#143850', '#081e30', '#02080e'], boss: 'flagship',
    pool: () => [P('deep', 3), P('ghost', 3), P('hunter', 2), P('layer', 1), P('sub', 1)] },
];

const STAGE_NAMES = [
  ['初陣', '浅瀬の影', '朝の哨戒', '機雷の気配', '群れなす艇', '巨影'],
  ['出航', '船団護衛', '夕凪の待ち伏せ', '長い航路', '追う魚雷', '浮かぶ倉庫'],
  ['黒雲', '荒波の下', '嵐の護衛', '稲妻の夜', '渦の中', '二つの船体'],
  ['白い海', '流氷の間', '凍える深み', '氷山の陰', '冷たい群れ', '深淵の門'],
  ['闇の入口', '影を探せ', '最後の船団', '音のない海', '深淵の底', '旗艦'],
];

/** ステージごとの調整（上手なボットが初回に船体の3割〈ボスは5割〉を失う強さの8割。上限3、1・2面は手で 1.0・1.6 に下げた） */
export const CALIB: number[] = [
  1.0, 1.6, 1.66, 2.09, 1.23, 0.38,
  1.58, 1.23, 1.56, 1.78, 0.94, 2.33,
  1.44, 0.49, 0.62, 1.46, 0.93, 0.55,
  1.71, 2.11, 1.7, 1.86, 2.48, 0.44,
  1.22, 1.46, 1.11, 0.98, 0.65, 0.5,
];

export function areaOf(id: number): AreaDef {
  return AREAS[Math.min(AREAS.length - 1, Math.max(0, Math.ceil(id / PER_AREA) - 1))];
}

function build(id: number): StageDef {
  const a = Math.ceil(id / PER_AREA) - 1;
  const k = (id - 1) % PER_AREA + 1;
  const area = AREAS[a];
  const c = CALIB[id - 1] ?? 1;
  let objective: StageDef['objective'];
  if (k === 6) objective = { kind: 'boss', boss: area.boss };
  else if (k === 4 || (area.id === 'convoy' && k === 2) || (id === 27)) objective = { kind: 'escort', ships: 3 + (a >= 3 ? 1 : 0), need: 2 };
  else if (k === 2 || k === 5 && a % 2 === 1) objective = { kind: 'survive', t: 45 + a * 5 };
  else objective = { kind: 'sink', n: (k === 1 ? 7 : k === 3 ? 11 : 14) + a * 2 };
  return {
    id, area: area.id, name: STAGE_NAMES[a][k - 1], objective, pool: area.pool(k),
    interval: Math.max(0.9, 2.5 - id * 0.045) / Math.sqrt(c),
    maxAlive: 3 + Math.floor(id / 5),
    hpMul: (1 + (id - 1) * 0.035) * c,
    speedMul: 1 + (id - 1) * 0.012,
    fireMul: (1 + (id - 1) * 0.02) * Math.sqrt(c),
    reward: 1 + (id - 1) * 0.07,
    current: area.id === 'storm' ? 26 : area.id === 'ice' ? 12 : 0,
    storm: area.id === 'storm' || undefined,
    ice: area.id === 'ice' ? 3 + Math.floor(k / 2) : undefined,
    dark: area.id === 'abyss' || undefined,
  };
}

export function stage(id: number): StageDef {
  if (id < 1 || id > STAGE_COUNT) throw new Error(`unknown stage ${id}`);
  return build(id);
}

/** 難しさ（艦長は敵が硬く、多く、よく撃つ。報酬も多い） */
export function applyDifficulty(s: StageDef, d: Difficulty): StageDef {
  if (d === 'normal') return s;
  return { ...s, hpMul: s.hpMul * 1.7, maxAlive: s.maxAlive + 2, fireMul: s.fireMul * 1.45, interval: s.interval * 0.78, speedMul: s.speedMul * 1.1, reward: s.reward * 1.3 };
}

export function objectiveText(o: StageDef['objective']): string {
  switch (o.kind) {
    case 'sink': return `敵を${o.n}隻沈める`;
    case 'survive': return `${o.t}秒 耐える`;
    case 'escort': return `船団${o.ships}隻のうち${o.need}隻以上を守る`;
    case 'boss': return `${enemy(o.boss).name}を沈める`;
  }
}
