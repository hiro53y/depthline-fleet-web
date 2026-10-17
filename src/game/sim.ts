// 海戦の進行（固定の刻み・seed 付き乱数で決定的）
// 自艦は海面を動き、左右の舷側から爆雷を落とす。爆雷は空中→着水→沈降し、当たると爆発。爆発は爆雷・機雷を誘爆させて連鎖になる
import { hashSeed, next, type Rng } from './rng';
import { endlessDef, waveTarget } from './modes';
import { BANDS, FLOOR, W, WL, depthMul, enemy } from './data';
import type { Band, Difficulty, EnemyDef, EnemyFire, ItemKind, Side, SpecialId, StageDef } from './types';

export const STEP = 1 / 60;
const AIR_ACC = 520, AIR_MAX = 420;
const WATER_ACC = 110, WATER_MAX = 230, MINI_MAX = 380;
const SHIP_Y = WL - 14;
const X_MIN = 60, X_MAX = W - 60;

export interface ShipStats {
  hull: number;
  speed: number;
  reload: number;
  capacity: number;
  power: number;
  radius: number;
  sonarEvery: number;
  sonarR: number;
  special: SpecialId;
  specialLv: number;
  half: number;
}

export interface Ship {
  x: number;
  hp: number;
  maxHp: number;
  inv: number;
  shield: number;
  rapidUntil: number;
  bigUntil: number;
  tripleUntil: number;
  cool: { L: number; R: number };
  sp: number;
  /** 嵐の揺れ（描画と投下の位置） */
  sway: number;
}

export interface Charge { id: number; x: number; y: number; vx: number; vy: number; water: boolean; power: number; radius: number; kind: 'charge' | 'mini' | 'mortar'; hit: boolean }
export interface PTorp { id: number; x: number; y: number; vx: number; vy: number; target: number | null; life: number; power: number }
export interface Part { hp: number; maxHp: number; dead: boolean }
export interface Foe {
  uid: number;
  def: string;
  x: number;
  y: number;
  baseY: number;
  dir: Side;
  hp: number;
  maxHp: number;
  fireCd: number[];
  revealedUntil: number;
  parts: Part[] | null;
  phase: number;
  summonCd: number;
  dead: boolean;
  out: boolean;
  t0: number;
}
export interface Shot { id: number; kind: EnemyFire['kind']; x: number; y: number; vx: number; vy: number; life: number; surfaced: boolean }
export interface Item { id: number; kind: ItemKind; x: number; y: number; surfaced: boolean; life: number }
export interface Convoy { id: number; x: number; hp: number; state: 'wait' | 'sail' | 'done' | 'sunk' }
export interface Ice { id: number; x: number; y: number; w: number; hp: number; vx: number }

export type SimEvent =
  | { k: 'spawn'; uid: number; boss: boolean }
  | { k: 'drop'; x: number; side: Side; kind: Charge['kind'] }
  | { k: 'splash'; x: number; big: boolean }
  | { k: 'boom'; x: number; y: number; r: number; chain: number; big: boolean }
  | { k: 'hit'; uid: number; x: number; y: number; n: number; part: number }
  | { k: 'kill'; uid: number; def: string; x: number; y: number; score: number; gold: number; chain: number }
  | { k: 'chain'; n: number; x: number; y: number }
  | { k: 'fire'; kind: EnemyFire['kind']; x: number; y: number }
  | { k: 'hurt'; x: number; dmg: number; shield: boolean }
  | { k: 'item'; kind: ItemKind; x: number; y: number }
  | { k: 'pick'; kind: ItemKind }
  | { k: 'sonar'; x: number; r: number }
  | { k: 'convoy'; id: number; s: 'hit' | 'sunk' | 'done' }
  | { k: 'part'; uid: number; part: number }
  | { k: 'phase'; uid: number; phase: number }
  | { k: 'special'; kind: SpecialId }
  | { k: 'ice'; x: number; y: number }
  | { k: 'wave'; n: number }
  | { k: 'end'; win: boolean };

export interface Input {
  /** 左右の移動（長押し） */
  move: -1 | 0 | 1;
  /** 指でなぞった位置（null は使わない） */
  targetX: number | null;
  dropL: boolean;
  dropR: boolean;
  special: boolean;
}

export const idleInput = (): Input => ({ move: 0, targetX: null, dropL: false, dropR: false, special: false });

export interface Battle {
  kind: 'stage' | 'endless' | 'daily';
  difficulty: Difficulty;
  def: StageDef;
  seed: number;
  rng: number;
  t: number;
  phase: 'ready' | 'fight' | 'won' | 'lost';
  stats: ShipStats;
  ship: Ship;
  charges: Charge[];
  ptorps: PTorp[];
  foes: Foe[];
  shots: Shot[];
  items: Item[];
  convoy: Convoy[];
  ice: Ice[];
  nextId: number;
  spawnCd: number;
  kills: number;
  score: number;
  gold: number;
  drops: number;
  hits: number;
  bestChain: number;
  /** 連鎖ごとの撃沈数 */
  chainKills: Record<number, number>;
  nextChain: number;
  sonarCd: number;
  revealAllUntil: number;
  bossUid: number | null;
  bossSpawned: boolean;
  /** ボスを沈めた */
  bossDown: boolean;
  /** 無限の海：波・この波の撃沈・次の波までの休み */
  wave: number;
  waveKills: number;
  waveBreak: number;
  events: SimEvent[];
}

export interface BattleOpts { kind?: Battle['kind']; difficulty?: Difficulty }

function rngOf(b: Battle): Rng { return { s: b.rng }; }
function rand(b: Battle): number { const r = rngOf(b); const v = next(r); b.rng = r.s; return v; }

export function createBattle(def: StageDef, stats: ShipStats, seed: number, o: BattleOpts = {}): Battle {
  const b: Battle = {
    kind: o.kind ?? 'stage', difficulty: o.difficulty ?? 'normal', def, seed, rng: hashSeed(seed, 'battle', def.id), t: 0, phase: 'ready', stats,
    ship: { x: W / 2, hp: stats.hull, maxHp: stats.hull, inv: 0, shield: 0, rapidUntil: 0, bigUntil: 0, tripleUntil: 0, cool: { L: 0, R: 0 }, sp: 0, sway: 0 },
    charges: [], ptorps: [], foes: [], shots: [], items: [], convoy: [], ice: [], nextId: 1, spawnCd: 1.2,
    kills: 0, score: 0, gold: 0, drops: 0, hits: 0, bestChain: 0, chainKills: {}, nextChain: 1, sonarCd: 2, revealAllUntil: 0,
    bossUid: null, bossSpawned: false, bossDown: false, wave: 1, waveKills: 0, waveBreak: 0, events: [],
  };
  if (def.objective.kind === 'escort') {
    for (let i = 0; i < def.objective.ships; i++) b.convoy.push({ id: b.nextId++, x: -80 - i * 230, hp: 3, state: 'sail' });
  }
  for (let i = 0; i < (def.ice ?? 0); i++) {
    const w = 90 + rand(b) * 70;
    b.ice.push({ id: b.nextId++, x: 80 + rand(b) * (W - 160), y: WL + 34 + rand(b) * 40, w, hp: 1, vx: (rand(b) < 0.5 ? -1 : 1) * (10 + rand(b) * 14) });
  }
  return b;
}

export function startFight(b: Battle) {
  if (b.phase === 'ready') b.phase = 'fight';
}

// ── 便利 ──

export const foeDef = (f: Foe): EnemyDef => enemy(f.def);
export const isBoss = (f: Foe) => foeDef(f).cls === 'boss';
export const liveFoes = (b: Battle) => b.foes.filter((f) => !f.dead && !f.out);

/** 敵の当たりの四角（ボスは区画ごと） */
export function foeRects(f: Foe): { x: number; y: number; w: number; h: number; part: number }[] {
  const d = foeDef(f);
  if (d.parts && f.parts) {
    return d.parts.map((p, i) => ({ x: f.x + p.dx * f.dir - p.w / 2, y: f.y + p.dy - p.h / 2, w: p.w, h: p.h, part: i })).filter((_, i) => !f.parts![i].dead);
  }
  const w = d.w * 0.88, h = d.h * 0.8;
  return [{ x: f.x - w / 2, y: f.y - h / 2, w, h, part: -1 }];
}

function circleRect(cx: number, cy: number, r: number, x: number, y: number, w: number, h: number): boolean {
  const nx = Math.max(x, Math.min(cx, x + w)), ny = Math.max(y, Math.min(cy, y + h));
  return (cx - nx) ** 2 + (cy - ny) ** 2 <= r * r;
}

/** 見えているか（影の潜水艦・暗い海の深い所はソナーか当たった時だけ） */
export function visible(b: Battle, f: Foe): boolean {
  if (b.t < b.revealAllUntil || b.t < f.revealedUntil) return true;
  const d = foeDef(f);
  if (d.stealth) return false;
  if (b.def.dark && f.y > BANDS.deep[0]) return false;
  return true;
}

// ── 出現 ──

function bandY(b: Battle, band: Band): number {
  const [y0, y1] = BANDS[band];
  return y0 + rand(b) * (y1 - y0);
}

function spawnFoe(b: Battle, id: string, x?: number, y?: number, dir?: Side): Foe {
  const d = enemy(id);
  const side: Side = dir ?? (rand(b) < 0.5 ? 1 : -1);
  const boss = d.cls === 'boss';
  const yy = y ?? (d.cls === 'boat' ? WL + 4 : bandY(b, d.bands[Math.floor(rand(b) * d.bands.length)]));
  const xx = x ?? (boss ? (side === 1 ? -d.w / 2 : W + d.w / 2) : side === 1 ? -d.w / 2 - 10 : W + d.w / 2 + 10);
  const hp = boss ? 0 : d.hp * b.def.hpMul;
  const f: Foe = {
    uid: b.nextId++, def: id, x: xx, y: yy, baseY: yy, dir: side, hp, maxHp: hp,
    fireCd: (d.bossFire ?? (d.fire ? [d.fire] : [])).map((fr) => fr.every * (0.6 + rand(b) * 0.6)),
    revealedUntil: 0, parts: d.parts ? d.parts.map((p) => ({ hp: p.hp * b.def.hpMul, maxHp: p.hp * b.def.hpMul, dead: false })) : null,
    phase: 0, summonCd: 9, dead: false, out: false, t0: b.t,
  };
  if (f.parts) { f.hp = f.parts.reduce((s, p) => s + p.hp, 0); f.maxHp = f.hp; }
  b.foes.push(f);
  b.events.push({ k: 'spawn', uid: f.uid, boss });
  if (boss) b.bossUid = f.uid;
  return f;
}

function pickEnemy(b: Battle): string {
  const pool = b.def.pool;
  const total = pool.reduce((s, p) => s + p.weight, 0);
  let r = rand(b) * total;
  for (const p of pool) { r -= p.weight; if (r < 0) return p.enemy; }
  return pool[pool.length - 1].enemy;
}

function spawnStep(b: Battle, dt: number) {
  const o = b.def.objective;
  if (b.kind === 'endless' && b.waveBreak > 0) { b.waveBreak -= dt; return; }
  if (o.kind === 'boss' && !b.bossSpawned && b.t >= 2.5) { b.bossSpawned = true; spawnFoe(b, o.boss, undefined, BANDS[enemy(o.boss).bands[0]][0] + 90); }
  b.spawnCd -= dt;
  if (b.spawnCd > 0) return;
  const alive = b.foes.filter((f) => !f.dead && !f.out && !isBoss(f)).length;
  const cap = o.kind === 'boss' ? Math.max(1, b.def.maxAlive - 2) : b.def.maxAlive;
  if (o.kind === 'sink' && b.kills + alive >= o.n + 2) { b.spawnCd = 0.5; return; }
  if (alive >= cap) { b.spawnCd = 0.4; return; }
  spawnFoe(b, pickEnemy(b));
  b.spawnCd = b.def.interval * (o.kind === 'boss' ? 1.7 : 1) * (0.75 + rand(b) * 0.5);
}

// ── 自艦 ──

function moveShip(b: Battle, inp: Input, dt: number) {
  const s = b.ship;
  let dir = inp.move;
  if (inp.targetX !== null) {
    const d = inp.targetX - s.x;
    dir = Math.abs(d) < 6 ? 0 : d > 0 ? 1 : -1;
    const step = Math.min(Math.abs(d), b.stats.speed * dt);
    s.x += Math.sign(d) * step;
  } else {
    s.x += dir * b.stats.speed * dt;
  }
  s.x = Math.max(X_MIN, Math.min(X_MAX, s.x));
  s.sway = b.def.storm ? Math.sin(b.t * 1.7) * 14 + Math.sin(b.t * 0.7) * 8 : 0;
}

function inFlight(b: Battle): number {
  return b.charges.filter((c) => c.kind === 'charge').length;
}

function drop(b: Battle, side: Side) {
  const key = side === -1 ? 'L' : 'R';
  const s = b.ship;
  if (s.cool[key] > 0) return;
  if (inFlight(b) >= b.stats.capacity) return;
  const big = b.t < s.bigUntil;
  const triple = b.t < s.tripleUntil;
  const x0 = s.x + s.sway + side * (b.stats.half - 8);
  const vxs = triple ? [side * 40, side * 110, side * 180] : [side * 70];
  for (const vx of vxs) {
    b.charges.push({ id: b.nextId++, x: x0, y: SHIP_Y - 6, vx, vy: -40, water: false, power: b.stats.power * (big ? 1.5 : 1), radius: b.stats.radius * (big ? 1.5 : 1), kind: 'charge', hit: false });
    b.drops += 1;
  }
  s.cool[key] = b.stats.reload * (b.t < s.rapidUntil ? 0.45 : 1);
  b.events.push({ k: 'drop', x: x0, side, kind: 'charge' });
}

function hurtShip(b: Battle, dmg: number, x: number) {
  const s = b.ship;
  if (s.inv > 0) return;
  if (s.shield > 0) { s.shield -= 1; s.inv = 0.4; b.events.push({ k: 'hurt', x, dmg: 0, shield: true }); return; }
  s.hp = Math.max(0, s.hp - dmg);
  s.inv = 1.0;
  b.events.push({ k: 'hurt', x, dmg, shield: false });
}

// ── 特殊兵装 ──

export function specialReady(b: Battle): boolean {
  return b.phase === 'fight' && b.ship.sp >= 1;
}

function useSpecial(b: Battle) {
  if (!specialReady(b)) return;
  const s = b.ship;
  s.sp = 0;
  const lv = b.stats.specialLv;
  const x0 = s.x + s.sway;
  switch (b.stats.special) {
    case 'mortar': {
      const n = 2 + lv;
      for (const side of [-1, 1] as const) {
        for (let i = 0; i < n; i++) {
          b.charges.push({ id: b.nextId++, x: x0 + side * 30, y: SHIP_Y - 20, vx: side * (150 + i * (260 / n)), vy: -300 - i * 20, water: false, power: b.stats.power * 1.2, radius: b.stats.radius, kind: 'mortar', hit: false });
        }
      }
      break;
    }
    case 'hedgehog': {
      const n = 7 + lv * 2;
      for (let i = 0; i < n; i++) {
        const a = -1 + (2 * i) / (n - 1);
        b.charges.push({ id: b.nextId++, x: x0 + a * 40, y: SHIP_Y, vx: a * 170, vy: 60, water: false, power: b.stats.power * 0.8, radius: b.stats.radius * 0.6, kind: 'mini', hit: false });
      }
      break;
    }
    case 'torpedo': {
      const n = 1 + lv;
      for (let i = 0; i < n; i++) b.ptorps.push({ id: b.nextId++, x: x0 + (i - (n - 1) / 2) * 30, y: WL + 10, vx: (i - (n - 1) / 2) * 60, vy: 120, target: null, life: 7, power: b.stats.power * (2 + lv) });
      break;
    }
    case 'sonar': {
      b.revealAllUntil = b.t + 6 + lv;
      for (const f of liveFoes(b)) {
        if (f.parts) { const i = f.parts.findIndex((p) => !p.dead); if (i >= 0) damageFoe(b, f, b.stats.power * (1 + lv * 0.6), i, b.nextChain++); }
        else damageFoe(b, f, b.stats.power * (1 + lv * 0.6), -1, b.nextChain++);
      }
      for (const sh of b.shots) sh.life = 0;
      b.events.push({ k: 'sonar', x: x0, r: 2000 });
      break;
    }
  }
  b.events.push({ k: 'special', kind: b.stats.special });
}

// ── 敵 ──

function fireTargetX(b: Battle, f: Foe): number {
  let best = b.ship.x, bd = Math.abs(b.ship.x - f.x);
  for (const c of b.convoy) if (c.state === 'sail' && c.x > 0 && c.x < W && Math.abs(c.x - f.x) < bd) { bd = Math.abs(c.x - f.x); best = c.x; }
  return best;
}

function enemyFire(b: Battle, f: Foe, fr: EnemyFire) {
  const y = f.y - foeDef(f).h * 0.4;
  if (fr.kind === 'torpedo') b.shots.push({ id: b.nextId++, kind: 'torpedo', x: f.x, y, vx: 0, vy: -170 * b.def.speedMul, life: 12, surfaced: false });
  else if (fr.kind === 'homing') b.shots.push({ id: b.nextId++, kind: 'homing', x: f.x, y, vx: 0, vy: -130 * b.def.speedMul, life: 14, surfaced: false });
  else b.shots.push({ id: b.nextId++, kind: 'mine', x: f.x, y: f.y + 10, vx: 0, vy: -38, life: 22, surfaced: false });
  b.events.push({ k: 'fire', kind: fr.kind, x: f.x, y });
}

function moveFoes(b: Battle, dt: number) {
  const sm = b.def.speedMul;
  for (const f of b.foes) {
    if (f.dead || f.out) continue;
    const d = foeDef(f);
    if (d.cls === 'boat') {
      // 海面を走って艦へ（体当たり）
      const tx = b.ship.x;
      const dx = tx - f.x;
      f.dir = dx >= 0 ? 1 : -1;
      f.x += Math.sign(dx) * Math.min(Math.abs(dx), d.speed * sm * dt);
      if (Math.abs(f.x - b.ship.x) < b.stats.half + d.w * 0.35) {
        hurtShip(b, 1, f.x);
        f.dead = true;
        b.events.push({ k: 'boom', x: f.x, y: WL, r: 50, chain: 0, big: false });
      }
      continue;
    }
    if (d.cls === 'boss') {
      // 端で折り返して居座る
      const half = d.w / 2 + 10;
      const enter = b.t - f.t0 < 4;
      f.x += f.dir * d.speed * sm * (enter ? 1.6 : 1) * (1 + f.phase * 0.25) * dt;
      if (!enter && f.x > W - half) { f.x = W - half; f.dir = -1; }
      if (!enter && f.x < half) { f.x = half; f.dir = 1; }
      if (enter && ((f.dir === 1 && f.x > half) || (f.dir === -1 && f.x < W - half))) f.t0 = b.t - 4;
      f.y = f.baseY + Math.sin((b.t - f.t0) * (d.id === 'twin' ? 0.9 : 0.5)) * (d.id === 'twin' ? 70 : 24);
      // 形態：残りの体力で
      const left = f.parts ? f.parts.reduce((s, p) => s + Math.max(0, p.hp), 0) / f.maxHp : 1;
      const ph = left < 0.34 ? 2 : left < 0.67 ? 1 : 0;
      if (ph > f.phase) { f.phase = ph; b.events.push({ k: 'phase', uid: f.uid, phase: ph }); }
      if (d.summon && f.phase >= 1) {
        f.summonCd -= dt;
        if (f.summonCd <= 0) { f.summonCd = 10 - f.phase * 2; spawnFoe(b, d.summon); }
      }
    } else {
      f.x += f.dir * d.speed * sm * dt;
      f.y = f.baseY + Math.sin((b.t - f.t0) * 1.3 + f.uid) * 4;
      if ((f.dir === 1 && f.x - d.w / 2 > W + 30) || (f.dir === -1 && f.x + d.w / 2 < -30)) f.out = true;
    }
    // 撃つ
    const fires = d.bossFire ? d.bossFire.slice(0, f.phase + 1) : d.fire ? [d.fire] : [];
    fires.forEach((fr, i) => {
      f.fireCd[i] = (f.fireCd[i] ?? fr.every) - dt * b.def.fireMul;
      if (f.fireCd[i] > 0) return;
      if (f.x < 30 || f.x > W - 30) return;
      if (fr.near && Math.abs(fireTargetX(b, f) - f.x) > fr.near) return;
      f.fireCd[i] = fr.every * (0.8 + rand(b) * 0.4);
      enemyFire(b, f, fr);
    });
  }
}

function moveShots(b: Battle, dt: number) {
  for (const sh of b.shots) {
    sh.life -= dt;
    if (sh.life <= 0) continue;
    if (sh.kind === 'homing' && !sh.surfaced) {
      const want = Math.max(-90, Math.min(90, (b.ship.x - sh.x) * 1.4));
      sh.vx += (want - sh.vx) * Math.min(1, dt * 1.8);
    }
    if (sh.kind === 'mine' && sh.surfaced) {
      sh.x += Math.sin(b.t * 0.8 + sh.id) * 8 * dt;
    } else {
      sh.x += sh.vx * dt;
      sh.y += sh.vy * dt;
    }
    if (sh.y <= WL + 6 && !sh.surfaced) {
      if (sh.kind === 'mine') { sh.surfaced = true; sh.y = WL + 8; sh.life = Math.min(sh.life, 7); continue; }
      // 魚雷が海面に出た：艦か船団に当たる
      sh.life = 0;
      if (Math.abs(sh.x - (b.ship.x + b.ship.sway)) < b.stats.half) hurtShip(b, 1, sh.x);
      else {
        const c = b.convoy.find((cv) => cv.state === 'sail' && Math.abs(cv.x - sh.x) < 60);
        if (c) {
          c.hp -= 1;
          b.events.push({ k: 'convoy', id: c.id, s: 'hit' });
          if (c.hp <= 0) { c.state = 'sunk'; b.events.push({ k: 'convoy', id: c.id, s: 'sunk' }); }
        }
      }
      b.events.push({ k: 'splash', x: sh.x, big: false });
      continue;
    }
    if (sh.kind === 'mine' && sh.surfaced && Math.abs(sh.x - (b.ship.x + b.ship.sway)) < b.stats.half * 0.85) {
      sh.life = 0;
      hurtShip(b, 2, sh.x);
      b.events.push({ k: 'boom', x: sh.x, y: WL, r: 60, chain: 0, big: false });
    }
  }
  b.shots = b.shots.filter((s) => s.life > 0);
}

function moveConvoy(b: Battle, dt: number) {
  for (const c of b.convoy) {
    if (c.state !== 'sail') continue;
    c.x += 42 * dt;
    if (c.x > W + 90) { c.state = 'done'; b.events.push({ k: 'convoy', id: c.id, s: 'done' }); }
  }
}

function moveIce(b: Battle, dt: number) {
  for (const ic of b.ice) {
    if (ic.hp <= 0) continue;
    ic.x += ic.vx * dt;
    if (ic.x < ic.w / 2 + 10) { ic.x = ic.w / 2 + 10; ic.vx = Math.abs(ic.vx); }
    if (ic.x > W - ic.w / 2 - 10) { ic.x = W - ic.w / 2 - 10; ic.vx = -Math.abs(ic.vx); }
  }
}

// ── 爆発と連鎖 ──

interface Blast { x: number; y: number; r: number; power: number; chain: number; big: boolean; src: Charge | PTorp | null }

/** 敵に打撃を与える（倒れたら報酬・連鎖） */
function damageFoe(b: Battle, f: Foe, n: number, part: number, chain: number) {
  if (f.dead || f.out) return;
  f.revealedUntil = Math.max(f.revealedUntil, b.t + 1.5);
  if (f.parts && part >= 0) {
    const p = f.parts[part];
    if (p.dead) return;
    p.hp -= n;
    b.events.push({ k: 'hit', uid: f.uid, x: f.x, y: f.y, n, part });
    if (p.hp <= 0) { p.dead = true; p.hp = 0; b.events.push({ k: 'part', uid: f.uid, part }); }
    f.hp = f.parts.reduce((s, q) => s + Math.max(0, q.hp), 0);
    if (!f.parts.every((q) => q.dead)) return;
  } else {
    f.hp -= n;
    b.events.push({ k: 'hit', uid: f.uid, x: f.x, y: f.y, n, part: -1 });
    if (f.hp > 0) return;
  }
  // 撃沈
  f.dead = true;
  const d = foeDef(f);
  if (f.uid === b.bossUid) b.bossDown = true;
  const ck = (b.chainKills[chain] ?? 0) + 1;
  b.chainKills[chain] = ck;
  b.bestChain = Math.max(b.bestChain, ck);
  const mul = 1 + 0.5 * (ck - 1);
  const score = Math.round(d.score * depthMul(f.y) * mul);
  const gold = Math.max(1, Math.round(d.gold * b.def.reward * (ck >= 3 ? 1.2 : 1)));
  b.score += score;
  b.gold += gold;
  b.kills += 1;
  b.waveKills += 1;
  b.ship.sp = Math.min(1, b.ship.sp + (d.cls === 'boss' ? 0.5 : 0.1));
  b.events.push({ k: 'kill', uid: f.uid, def: f.def, x: f.x, y: f.y, score, gold, chain: ck });
  if (ck >= 2) b.events.push({ k: 'chain', n: ck, x: f.x, y: f.y });
  // 落とし物
  const drops = d.cls === 'boss' ? 2 : rand(b) < 0.12 ? 1 : 0;
  for (let i = 0; i < drops; i++) {
    const kinds: ItemKind[] = ['rapid', 'big', 'shield', 'repair', 'triple', 'gold'];
    const kind = kinds[Math.floor(rand(b) * kinds.length)];
    b.items.push({ id: b.nextId++, kind, x: f.x + (i - 0.5) * 60, y: f.y, surfaced: false, life: 9 });
  }
}

function explode(b: Battle, first: Blast) {
  const queue: Blast[] = [first];
  let guard = 0;
  while (queue.length && guard++ < 400) {
    const bl = queue.shift()!;
    b.events.push({ k: 'boom', x: bl.x, y: bl.y, r: bl.r, chain: bl.chain, big: bl.big });
    let hitAny = false;
    for (const f of b.foes) {
      if (f.dead || f.out) continue;
      for (const r of foeRects(f)) {
        if (!circleRect(bl.x, bl.y, bl.r, r.x, r.y, r.w, r.h)) continue;
        damageFoe(b, f, bl.power, r.part, bl.chain);
        hitAny = true;
        if (r.part < 0) break;
      }
    }
    if (hitAny && bl.src && 'hit' in bl.src && !bl.src.hit) { bl.src.hit = true; b.hits += 1; b.ship.sp = Math.min(1, b.ship.sp + 0.03); }
    // 敵の弾を消す。機雷は誘爆する
    for (const sh of b.shots) {
      if (sh.life <= 0) continue;
      if ((sh.x - bl.x) ** 2 + (sh.y - bl.y) ** 2 > (bl.r + 10) ** 2) continue;
      sh.life = 0;
      if (sh.kind === 'mine') queue.push({ x: sh.x, y: sh.y, r: 90, power: 1.5, chain: bl.chain, big: false, src: null });
    }
    // 他の爆雷を誘爆
    for (const c of b.charges) {
      if (c === bl.src || !c.water) continue;
      if ((c.x - bl.x) ** 2 + (c.y - bl.y) ** 2 > (bl.r * 0.9) ** 2) continue;
      const cy = c.y;
      c.y = -9999;
      queue.push({ x: c.x, y: cy, r: c.radius, power: c.power, chain: bl.chain, big: false, src: c });
    }
    // 流氷
    for (const ic of b.ice) {
      if (ic.hp > 0 && circleRect(bl.x, bl.y, bl.r, ic.x - ic.w / 2, ic.y - 14, ic.w, 28)) {
        ic.hp -= 1;
        if (ic.hp <= 0) b.events.push({ k: 'ice', x: ic.x, y: ic.y });
      }
    }
  }
  b.charges = b.charges.filter((c) => c.y > -9000);
}

function moveCharges(b: Battle, dt: number) {
  const done: Charge[] = [];
  for (const c of b.charges) {
    if (!c.water) {
      c.vy = Math.min(AIR_MAX, c.vy + AIR_ACC * dt);
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      // 魚雷艇には空中・着水の時に当たる
      const boat = b.foes.find((f) => !f.dead && foeDef(f).cls === 'boat' && Math.abs(f.x - c.x) < foeDef(f).w * 0.5 && c.y > WL - 30);
      if (boat) { done.push(c); continue; }
      if (c.y >= WL) {
        c.water = true;
        c.vy *= 0.32;
        c.vx *= 0.28;
        b.events.push({ k: 'splash', x: c.x, big: c.kind !== 'mini' });
      }
    } else {
      const max = c.kind === 'mini' ? MINI_MAX : WATER_MAX;
      c.vy = Math.min(max, c.vy + (c.kind === 'mini' ? WATER_ACC * 3 : WATER_ACC) * dt);
      c.x += (c.vx + b.def.current) * dt;
      c.vx *= 1 - Math.min(1, dt * 1.2);
      c.y += c.vy * dt;
    }
    if (c.x < -40 || c.x > W + 40) { c.y = -9999; continue; }
    // 当たり
    let hit = c.y >= FLOOR;
    if (!hit && c.water) {
      for (const f of b.foes) {
        if (f.dead || f.out) continue;
        if (foeRects(f).some((r) => c.x > r.x - 4 && c.x < r.x + r.w + 4 && c.y > r.y - 4 && c.y < r.y + r.h + 4)) { hit = true; break; }
      }
      if (!hit) hit = b.shots.some((sh) => (sh.x - c.x) ** 2 + (sh.y - c.y) ** 2 < 24 ** 2);
      if (!hit) hit = b.ice.some((ic) => ic.hp > 0 && Math.abs(c.x - ic.x) < ic.w / 2 && Math.abs(c.y - ic.y) < 16);
    }
    if (hit) done.push(c);
  }
  for (const c of done) {
    if (c.y < -9000) continue;
    const y = Math.min(FLOOR, Math.max(WL, c.y));
    c.y = -9999;
    explode(b, { x: c.x, y, r: c.radius, power: c.power, chain: b.nextChain++, big: c.kind !== 'mini' && c.radius > 90, src: c });
  }
  b.charges = b.charges.filter((c) => c.y > -9000);
}

function movePTorps(b: Battle, dt: number) {
  for (const t of b.ptorps) {
    t.life -= dt;
    let target = b.foes.find((f) => f.uid === t.target && !f.dead && !f.out) ?? null;
    if (!target) {
      let bd = Infinity;
      for (const f of liveFoes(b)) { if (foeDef(f).cls === 'boat' || f.y < t.y - 40) continue; const d = Math.hypot(f.x - t.x, f.y - t.y); if (d < bd) { bd = d; target = f; } }
      t.target = target?.uid ?? null;
    }
    const sp = 280;
    if (target) {
      const a = Math.atan2(target.y - t.y, target.x - t.x);
      t.vx += (Math.cos(a) * sp - t.vx) * Math.min(1, dt * 3);
      t.vy += (Math.sin(a) * sp - t.vy) * Math.min(1, dt * 3);
    }
    t.x += t.vx * dt;
    t.y += t.vy * dt;
    if (target && foeRects(target).some((r) => t.x > r.x && t.x < r.x + r.w && t.y > r.y && t.y < r.y + r.h)) t.life = -1;
    if (t.y > FLOOR) t.life = -1;
    if (t.life < 0) {
      t.life = -99;
      explode(b, { x: t.x, y: Math.min(FLOOR, t.y), r: 64, power: t.power, chain: b.nextChain++, big: false, src: null });
    }
  }
  b.ptorps = b.ptorps.filter((t) => t.life > -50 && t.life > 0);
}

function moveItems(b: Battle, dt: number) {
  for (const it of b.items) {
    if (!it.surfaced) {
      it.y -= 90 * dt;
      if (it.y <= WL + 4) { it.y = WL + 4; it.surfaced = true; }
    } else {
      it.life -= dt;
      it.x += Math.sin(b.t + it.id) * 10 * dt;
      if (Math.abs(it.x - (b.ship.x + b.ship.sway)) < b.stats.half + 16) { pick(b, it.kind); it.life = 0; }
    }
  }
  b.items = b.items.filter((i) => i.life > 0);
}

function pick(b: Battle, kind: ItemKind) {
  const s = b.ship;
  switch (kind) {
    case 'rapid': s.rapidUntil = b.t + 10; break;
    case 'big': s.bigUntil = b.t + 10; break;
    case 'triple': s.tripleUntil = b.t + 10; break;
    case 'shield': s.shield = Math.min(3, s.shield + 2); break;
    case 'repair': s.hp = Math.min(s.maxHp, s.hp + 2); break;
    case 'gold': b.gold += Math.round(30 * b.def.reward); break;
  }
  b.events.push({ k: 'pick', kind });
}

function sonarStep(b: Battle, dt: number) {
  b.sonarCd -= dt;
  if (b.sonarCd > 0) return;
  b.sonarCd = b.stats.sonarEvery;
  const x = b.ship.x;
  for (const f of liveFoes(b)) if (Math.hypot(f.x - x, f.y - WL) <= b.stats.sonarR + 200) f.revealedUntil = Math.max(f.revealedUntil, b.t + 2.4);
  b.events.push({ k: 'sonar', x, r: b.stats.sonarR + 200 });
}

/** 目標の進み（0〜1） */
export function objectiveProgress(b: Battle): number {
  const o = b.def.objective;
  switch (o.kind) {
    case 'sink': return Math.min(1, b.kills / o.n);
    case 'survive': return Math.min(1, b.t / o.t);
    case 'escort': return b.convoy.filter((c) => c.state === 'done').length / o.ships;
    case 'boss': {
      if (b.bossDown) return 1;
      const f = b.foes.find((x) => x.uid === b.bossUid);
      if (!f) return 0;
      const left = f.parts ? f.parts.reduce((n, q) => n + Math.max(0, q.hp), 0) : f.hp;
      return 1 - left / Math.max(1, f.maxHp);
    }
  }
}

function judge(b: Battle) {
  if (b.ship.hp <= 0) { b.phase = 'lost'; b.events.push({ k: 'end', win: false }); return; }
  const o = b.def.objective;
  if (b.kind === 'endless') {
    // 波の撃沈数に届いたら次の波（少し休み、船体を1つ直す）
    if (b.waveKills >= waveTarget(b.wave)) {
      b.wave += 1;
      b.waveKills = 0;
      b.waveBreak = 3;
      b.def = endlessDef(b.wave, b.difficulty);
      b.ship.hp = Math.min(b.ship.maxHp, b.ship.hp + 1);
      b.events.push({ k: 'wave', n: b.wave });
    }
    return;
  }
  let win = false;
  switch (o.kind) {
    case 'sink': win = b.kills >= o.n; break;
    case 'survive': win = b.t >= o.t; break;
    case 'escort': {
      const sunk = b.convoy.filter((c) => c.state === 'sunk').length;
      if (sunk > o.ships - o.need) { b.phase = 'lost'; b.events.push({ k: 'end', win: false }); return; }
      win = b.convoy.every((c) => c.state !== 'sail');
      break;
    }
    case 'boss': win = b.bossDown; break;
  }
  if (win) { b.phase = 'won'; b.events.push({ k: 'end', win: true }); }
}

/** 1刻み進める */
export function step(b: Battle, inp: Input, dt = STEP) {
  if (b.phase !== 'fight') return;
  b.t += dt;
  const s = b.ship;
  s.inv = Math.max(0, s.inv - dt);
  s.cool.L = Math.max(0, s.cool.L - dt);
  s.cool.R = Math.max(0, s.cool.R - dt);
  s.sp = Math.min(1, s.sp + dt * 0.012);
  moveShip(b, inp, dt);
  if (inp.dropL) drop(b, -1);
  if (inp.dropR) drop(b, 1);
  if (inp.special) useSpecial(b);
  spawnStep(b, dt);
  moveFoes(b, dt);
  moveConvoy(b, dt);
  moveIce(b, dt);
  moveShots(b, dt);
  moveCharges(b, dt);
  movePTorps(b, dt);
  moveItems(b, dt);
  sonarStep(b, dt);
  b.foes = b.foes.filter((f) => !f.dead && !f.out);
  for (const k of Object.keys(b.chainKills)) if (Number(k) < b.nextChain - 200) delete b.chainKills[Number(k)];
  judge(b);
}

/** 何秒ぶん進める（刻みに分ける）。入力は最初の刻みだけ投下・特殊を効かせる */
export function advance(b: Battle, inp: Input, seconds: number) {
  let left = seconds;
  let first = true;
  while (left > 1e-9 && b.phase === 'fight') {
    const dt = Math.min(STEP, left);
    step(b, first ? inp : { ...inp, dropL: false, dropR: false, special: false }, dt);
    first = false;
    left -= dt;
  }
}

/** 命中率 */
export function accuracy(b: Battle): number {
  return b.drops ? b.hits / b.drops : 0;
}

/** 星：船体の被害と命中率 */
export function starsOf(b: Battle): number {
  if (b.phase !== 'won') return 0;
  const lost = b.ship.maxHp - b.ship.hp;
  return 1 + (lost <= 1 ? 1 : 0) + (accuracy(b) >= 0.4 ? 1 : 0);
}
