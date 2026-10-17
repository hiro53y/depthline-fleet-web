// 進み：金・改造・艦・特殊兵装・ステージの結果・無限の海・毎日の挑戦
import { SHIPS, SPECIALS, STAGE_COUNT, UPGRADES, emptyUpgrades, upgradeCost } from './data';
import type { Battle, ShipStats } from './sim';
import { accuracy, starsOf } from './sim';
import type { Difficulty, Progress, ShipId, SpecialId, UpgradeId } from './types';

export const PROGRESS_VERSION = 1;

export function newProgress(difficulty: Difficulty, seed: number): Progress {
  return {
    v: PROGRESS_VERSION, seed: seed | 0, difficulty, unlocked: 1, stars: {}, best: {}, gold: 0,
    ship: 'destroyer', ships: ['destroyer'],
    upgrades: { destroyer: emptyUpgrades(), corvette: emptyUpgrades(), cruiser: emptyUpgrades() },
    special: 'mortar', specials: ['mortar'],
    endless: { best: 0, score: 0 },
    daily: { date: '', cleared: false, best: 0 },
    tips: [],
    stats: { kills: 0, drops: 0, hits: 0, battles: 0, bestChain: 0 },
  };
}

/** 今の艦の能力（艦の種類＋改造） */
export function shipStats(p: Progress, ship: ShipId = p.ship): ShipStats {
  const d = SHIPS[ship];
  const u = p.upgrades[ship];
  return {
    hull: d.hull + u.hull,
    speed: d.speed * (1 + u.engine * 0.08),
    reload: d.reload * (1 - u.reload * 0.08),
    capacity: d.capacity + u.capacity,
    power: d.power * (1 + u.power * 0.25),
    radius: d.radius * (1 + u.radius * 0.08),
    sonarEvery: 8 - u.sonar * 0.8,
    sonarR: 300 + u.sonar * 60,
    special: p.special,
    specialLv: 1 + u.special,
    half: ship === 'cruiser' ? 82 : ship === 'corvette' ? 62 : 72,
  };
}

// ── 改造・艦・特殊兵装 ──

export function upgradeError(p: Progress, id: UpgradeId): string | null {
  const lv = p.upgrades[p.ship][id];
  const def = UPGRADES.find((u) => u.id === id)!;
  if (lv >= def.max) return '最大';
  if (p.gold < upgradeCost(id, lv)) return '金が足りない';
  return null;
}

export function buyUpgrade(p: Progress, id: UpgradeId): boolean {
  if (upgradeError(p, id)) return false;
  p.gold -= upgradeCost(id, p.upgrades[p.ship][id]);
  p.upgrades[p.ship][id] += 1;
  return true;
}

export function shipError(p: Progress, id: ShipId): string | null {
  if (p.ships.includes(id)) return null;
  const d = SHIPS[id];
  if (p.unlocked <= d.unlockStage) return `ステージ${d.unlockStage}を越えると買える`;
  if (p.gold < d.price) return '金が足りない';
  return null;
}

/** 艦を選ぶ（持っていなければ買う） */
export function chooseShip(p: Progress, id: ShipId): boolean {
  if (!p.ships.includes(id)) {
    if (shipError(p, id)) return false;
    p.gold -= SHIPS[id].price;
    p.ships.push(id);
  }
  p.ship = id;
  return true;
}

export function specialError(p: Progress, id: SpecialId): string | null {
  if (p.specials.includes(id)) return null;
  const d = SPECIALS[id];
  if (p.unlocked <= d.unlockStage) return `ステージ${d.unlockStage}を越えると買える`;
  if (p.gold < d.price) return '金が足りない';
  return null;
}

export function chooseSpecial(p: Progress, id: SpecialId): boolean {
  if (!p.specials.includes(id)) {
    if (specialError(p, id)) return false;
    p.gold -= SPECIALS[id].price;
    p.specials.push(id);
  }
  p.special = id;
  return true;
}

// ── 結果 ──

export interface Result {
  win: boolean;
  stage: number;
  kills: number;
  score: number;
  gold: number;
  bonus: number;
  stars: number;
  accuracy: number;
  bestChain: number;
  hullLost: number;
  firstClear: boolean;
  newBest: boolean;
}

/** 合戦の結果を進みに入れる（金は勝ち負けにかかわらず入る。勝つとクリアの報酬） */
export function applyResult(p: Progress, b: Battle): Result {
  const win = b.phase === 'won';
  const id = b.def.id;
  const stars = starsOf(b);
  const firstClear = b.kind === 'stage' && win && !p.stars[id];
  const bonus = win && b.kind === 'stage' ? Math.round((40 + id * 18) * stars * (p.difficulty === 'captain' ? 1.3 : 1)) : 0;
  p.gold += b.gold + bonus;
  p.stats.kills += b.kills;
  p.stats.drops += b.drops;
  p.stats.hits += b.hits;
  p.stats.battles += 1;
  p.stats.bestChain = Math.max(p.stats.bestChain, b.bestChain);
  let newBest = false;
  if (b.kind === 'stage') {
    if (win) {
      p.stars[id] = Math.max(p.stars[id] ?? 0, stars);
      if (id >= p.unlocked) p.unlocked = Math.min(STAGE_COUNT, id + 1);
      if (id === STAGE_COUNT) p.cleared = true;
    }
    if (b.score > (p.best[id] ?? 0)) { p.best[id] = b.score; newBest = true; }
  } else if (b.kind === 'endless') {
    if (b.wave > p.endless.best) { p.endless.best = b.wave; newBest = true; }
    p.endless.score = Math.max(p.endless.score, b.score);
  }
  return {
    win, stage: id, kills: b.kills, score: b.score, gold: b.gold, bonus, stars, accuracy: accuracy(b), bestChain: b.bestChain,
    hullLost: b.ship.maxHp - b.ship.hp, firstClear, newBest,
  };
}

/** 毎日の挑戦の結果。今日はじめて勝つと金の報酬。もらえた金を返す */
export function applyDaily(p: Progress, date: string, win: boolean, score: number): number {
  if (p.daily.date !== date) p.daily = { date, cleared: false, best: 0 };
  p.daily.best = Math.max(p.daily.best, score);
  if (win && !p.daily.cleared) {
    p.daily.cleared = true;
    const reward = 300 + p.unlocked * 40;
    p.gold += reward;
    return reward;
  }
  return 0;
}

export function canPlay(p: Progress, id: number): boolean {
  return id >= 1 && id <= Math.min(STAGE_COUNT, p.unlocked);
}

export function clone<T>(v: T): T {
  return JSON.parse(JSON.stringify(v)) as T;
}
