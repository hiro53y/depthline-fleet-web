// 自動で遊ぶボット（難しさの集計・調整と総当たりに使う）
// 敵が爆雷の届く深さに来る時の位置を読んで真上に回り、弾を避け、強化を拾い、特殊兵装を使う
import { STAGE_COUNT, UPGRADES, WL, applyDifficulty, stage, upgradeCost } from '../src/game/data';
import { applyResult, buyUpgrade, newProgress, shipStats, type Result } from '../src/game/progress';
import { createBattle, foeDef, liveFoes, startFight, step, visible, type Battle, type Input } from '../src/game/sim';
import type { Difficulty, Progress, UpgradeId } from '../src/game/types';

/** 海面から深さ dy まで爆雷が沈む時間（だいたい） */
function sinkTime(dy: number): number {
  const acc = 110, max = 230, v0 = 25;
  const tMax = (max - v0) / acc;
  const dMax = v0 * tMax + 0.5 * acc * tMax * tMax;
  if (dy <= dMax) return (-v0 + Math.sqrt(v0 * v0 + 2 * acc * dy)) / acc;
  return tMax + (dy - dMax) / max;
}

export function botInput(b: Battle): Input {
  const s = b.ship;
  const sx = s.x + s.sway;
  const half = b.stats.half;
  const inp: Input = { move: 0, targetX: null, dropL: false, dropR: false, special: false };
  // 危ない弾
  let threat: number | null = null;
  for (const sh of b.shots) {
    const near = sh.kind === 'mine' ? (sh.surfaced || sh.y < WL + 120) : sh.y < WL + 300;
    if (near && Math.abs(sh.x - sx) < half + 46) { threat = sh.x; break; }
  }
  // 真下に上がってくる魚雷・機雷は爆雷で迎え撃つ
  for (const sh of b.shots) {
    if (sh.surfaced || sh.y < WL + 70 || sh.y > WL + 520) continue;
    const dx = sh.x - sx;
    if (Math.abs(dx) < half + 30) { if (dx < 0) inp.dropL = true; else inp.dropR = true; }
  }
  for (const f of liveFoes(b)) if (foeDef(f).cls === 'boat' && Math.abs(f.x - sx) < half + 140) {
    // 艇：近い側に落とす
    if (f.x < sx) inp.dropL = true; else inp.dropR = true;
  }
  if (threat !== null) {
    const away = threat < sx ? 1 : -1;
    let tx = sx + away * (half + 120);
    if (tx < 70 || tx > 650) tx = sx - away * (half + 120);
    inp.targetX = tx;
  }
  // 狙う敵（見えている物。爆雷が届く時の位置を読む）
  let best: { x: number; side: -1 | 1; cost: number; w: number } | null = null;
  for (const f of liveFoes(b)) {
    const d = foeDef(f);
    if (d.cls === 'boat' || !visible(b, f)) continue;
    const t = sinkTime(Math.max(0, f.y - WL)) + 0.15;
    const vx = d.cls === 'boss' ? 0 : f.dir * d.speed * b.def.speedMul;
    const px = f.x + vx * t - b.def.current * t * 0.6;
    if (px < 20 || px > 700) continue;
    for (const side of [-1, 1] as const) {
      const dropX = px - side * (half - 8);
      if (dropX < 60 || dropX > 660) continue;
      const cost = Math.abs(dropX - sx) / b.stats.speed - (d.cls === 'boss' ? 0.5 : 0) - f.y / 4000;
      if (!best || cost < best.cost) best = { x: dropX, side, cost, w: d.cls === 'boss' ? 120 : d.w };
    }
  }
  if (best && threat === null) {
    inp.targetX = best.x;
    if (Math.abs(best.x - sx) < Math.max(14, best.w * 0.3)) { if (best.side === -1) inp.dropL = true; else inp.dropR = true; }
  } else if (best && Math.abs(best.x - sx) < best.w * 0.3) {
    if (best.side === -1) inp.dropL = true; else inp.dropR = true;
  }
  // 強化を拾う（危なくなければ）
  if (threat === null && !best) {
    const it = b.items.find((i) => i.surfaced);
    if (it) inp.targetX = it.x;
  }
  // 特殊兵装
  if (s.sp >= 1 && (liveFoes(b).length >= 3 || b.bossUid !== null)) inp.special = true;
  return inp;
}

const PRIORITY: UpgradeId[] = ['reload', 'capacity', 'power', 'radius', 'hull', 'engine', 'special', 'sonar'];

/** 改造：安い順に買えるだけ */
export function botTrain(p: Progress) {
  for (let guard = 0; guard < 100; guard++) {
    const cand = PRIORITY
      .filter((id) => p.upgrades[p.ship][id] < UPGRADES.find((u) => u.id === id)!.max)
      .map((id) => ({ id, c: upgradeCost(id, p.upgrades[p.ship][id]) }))
      .sort((a, b) => a.c - b.c)[0];
    if (!cand || !buyUpgrade(p, cand.id)) break;
  }
}

export interface PlayOpts { train?: boolean; maxTime?: number }

export function playStage(p: Progress, id: number, seed: number, o: PlayOpts = {}): { r: Result; b: Battle } {
  const def = applyDifficulty(stage(id), p.difficulty);
  const b = createBattle(def, shipStats(p), seed, { difficulty: p.difficulty });
  startFight(b);
  const maxT = o.maxTime ?? 400;
  while (b.phase === 'fight' && b.t < maxT) step(b, botInput(b));
  if (b.phase === 'fight') { b.phase = 'lost'; }
  return { r: applyResult(p, b), b };
}

export interface RunResult { p: Progress; cleared: boolean; retries: number; firstTry: number; perStage: string[] }

/** 最初から最後まで。負けても金は残る。3回負けたら1つ前で稼ぐ */
export function playRun(difficulty: Difficulty, seed: number, maxBattles = 200, o: PlayOpts = {}): RunResult {
  const p = newProgress(difficulty, seed);
  let retries = 0, fails = 0, battles = 0, firstTry = 0;
  const perStage: string[] = [];
  while (!p.cleared && battles < maxBattles) {
    const id = Math.min(STAGE_COUNT, p.unlocked);
    if (o.train !== false) botTrain(p);
    const { r } = playStage(p, id, seed * 1000 + battles++, o);
    if (r.win) {
      if (fails === 0) firstTry++;
      perStage.push(`${id}:${fails}-${r.hullLost}`);
      fails = 0;
      continue;
    }
    retries++;
    fails++;
    if (fails >= 3 && id > 1) {
      if (o.train !== false) botTrain(p);
      playStage(p, id - 1, seed * 1000 + battles++, o);
    }
  }
  return { p, cleared: !!p.cleared, retries, firstTry, perStage };
}
