// ゲームの型（DOM に依存しない）

export type Difficulty = 'normal' | 'captain';
export type ShipId = 'destroyer' | 'corvette' | 'cruiser';
export type SpecialId = 'mortar' | 'hedgehog' | 'torpedo' | 'sonar';
export type UpgradeId = 'hull' | 'engine' | 'reload' | 'capacity' | 'power' | 'radius' | 'sonar' | 'special';
export type ItemKind = 'rapid' | 'big' | 'shield' | 'repair' | 'triple' | 'gold';
export type AreaId = 'shelf' | 'convoy' | 'storm' | 'ice' | 'abyss';
export type Side = -1 | 1;

/** 深さの帯（y の範囲） */
export type Band = 'shallow' | 'mid' | 'deep' | 'abyss';

export interface ShipDef {
  id: ShipId;
  name: string;
  desc: string;
  hull: number;
  speed: number;
  reload: number;
  capacity: number;
  power: number;
  radius: number;
  /** 買う値段（0 は初めから） */
  price: number;
  /** このステージを越えると買える */
  unlockStage: number;
  color: string;
}

export interface EnemyFire {
  kind: 'torpedo' | 'homing' | 'mine';
  /** 撃つ間隔（秒） */
  every: number;
  /** 自艦の近くでだけ撃つ（横の距離） */
  near?: number;
}

export interface BossPart { dx: number; dy: number; w: number; h: number; hp: number; name: string }

export interface EnemyDef {
  id: string;
  name: string;
  /** sub 潜水艦・boat 海面の艇・boss */
  cls: 'sub' | 'boat' | 'boss';
  hp: number;
  speed: number;
  bands: Band[];
  w: number;
  h: number;
  score: number;
  gold: number;
  fire?: EnemyFire;
  /** 姿を消す（ソナーか当たった時だけ見える） */
  stealth?: boolean;
  color: string;
  desc: string;
  /** ボスの区画 */
  parts?: BossPart[];
  /** ボスの技（形態ごとに増える） */
  bossFire?: EnemyFire[];
  /** 手下 */
  summon?: string;
}

export interface SpawnPick { enemy: string; weight: number }

export type Objective =
  | { kind: 'sink'; n: number }
  | { kind: 'survive'; t: number }
  | { kind: 'escort'; ships: number; need: number }
  | { kind: 'boss'; boss: string };

export interface StageDef {
  /** 本編 1〜30、無限 100+波、毎日 200 */
  id: number;
  area: AreaId;
  name: string;
  objective: Objective;
  pool: SpawnPick[];
  /** 出てくる間隔（秒） */
  interval: number;
  /** 同時にいる数の上限 */
  maxAlive: number;
  /** 敵の硬さ・速さ・撃つ速さの倍率 */
  hpMul: number;
  speedMul: number;
  fireMul: number;
  /** 報酬の倍率 */
  reward: number;
  /** 海の流れ（水中の爆雷が横に流される速さ） */
  current: number;
  /** 嵐（艦が揺れ、視界が悪い） */
  storm?: boolean;
  /** 流氷の数 */
  ice?: number;
  /** 暗い（深い所はソナーでしか見えない） */
  dark?: boolean;
}

export interface Upgrades { hull: number; engine: number; reload: number; capacity: number; power: number; radius: number; sonar: number; special: number }

export interface Progress {
  v: number;
  seed: number;
  difficulty: Difficulty;
  /** 次に挑めるステージ（解放済みの最大） */
  unlocked: number;
  stars: Record<number, number>;
  best: Record<number, number>;
  gold: number;
  ship: ShipId;
  ships: ShipId[];
  /** 艦ごとの改造 */
  upgrades: Record<ShipId, Upgrades>;
  special: SpecialId;
  specials: SpecialId[];
  endless: { best: number; score: number };
  daily: { date: string; cleared: boolean; best: number };
  tips: string[];
  stats: { kills: number; drops: number; hits: number; battles: number; bestChain: number };
  cleared?: boolean;
}

export interface Settings { bgm: number; se: number; vibrate: boolean; bigButtons: boolean; flip: boolean }
export const DEFAULT_SETTINGS: Settings = { bgm: 0.5, se: 0.7, vibrate: true, bigButtons: false, flip: false };
