// ゲームの決まりの単体テスト：爆雷・爆発と連鎖・敵と攻撃・ボス・強化・目標・改造・無限・毎日・保存・総当たり
import { describe, expect, it } from 'vitest';
import { BANDS, ENEMIES, FLOOR, SHIPS, STAGE_COUNT, UPGRADES, W, WL, applyDifficulty, enemy, objectiveText, stage, upgradeCost } from '../src/game/data';
import { DAILY_RULES, dailyDef, dailyRule, endlessDef, waveTarget } from '../src/game/modes';
import { applyDaily, applyResult, buyUpgrade, chooseShip, chooseSpecial, clone, newProgress, shipError, shipStats, specialError, upgradeError } from '../src/game/progress';
import { loadSettings, parseProgress, saveSettings, type KV } from '../src/game/save';
import { accuracy, createBattle, foeRects, idleInput, objectiveProgress, starsOf, startFight, step, visible, type Battle, type Foe, type Input } from '../src/game/sim';
import type { StageDef } from '../src/game/types';
import { playRun, playStage } from './bot';

function memKV(): KV {
  const m = new Map<string, string>();
  return { getItem: (k) => m.get(k) ?? null, setItem: (k, v) => void m.set(k, v), removeItem: (k) => void m.delete(k) };
}

/** 敵が勝手に出てこない静かな海 */
function calm(over: Partial<StageDef> = {}): StageDef {
  return { ...stage(1), objective: { kind: 'survive', t: 9999 }, interval: 1e9, maxAlive: 0, ...over };
}

function battle(over: Partial<StageDef> = {}, seed = 1): Battle {
  const p = newProgress('normal', 1);
  const b = createBattle(calm(over), shipStats(p), seed);
  b.spawnCd = 1e9;
  startFight(b);
  return b;
}

/** 敵を決まった所に置く */
function put(b: Battle, id: string, x: number, y: number, o: Partial<Foe> = {}): Foe {
  const d = enemy(id);
  const f: Foe = {
    uid: b.nextId++, def: id, x, y, baseY: y, dir: 1, hp: d.hp, maxHp: d.hp, fireCd: [1e9, 1e9, 1e9], revealedUntil: 0,
    parts: d.parts ? d.parts.map((q) => ({ hp: q.hp, maxHp: q.hp, dead: false })) : null, phase: 0, summonCd: 1e9, dead: false, out: false, t0: -100, ...o,
  };
  if (f.parts) { f.hp = f.parts.reduce((s, q) => s + q.hp, 0); f.maxHp = f.hp; }
  b.foes.push(f);
  return f;
}

const run = (b: Battle, sec: number, inp: Partial<Input> = {}) => {
  const n = Math.round(sec * 60);
  for (let i = 0; i < n && b.phase === 'fight'; i++) step(b, { ...idleInput(), ...(i === 0 ? inp : { move: inp.move ?? 0, targetX: inp.targetX ?? null }) });
};

describe('爆雷', () => {
  it('空中は速く落ち、着水で遅くなって沈む。速さには上限がある', () => {
    const b = battle();
    run(b, 1 / 60, { dropR: true });
    expect(b.charges.length).toBe(1);
    const c = b.charges[0];
    expect(c.water).toBe(false);
    let maxV = 0, splashed = false;
    for (let i = 0; i < 600 && b.charges.length; i++) {
      step(b, idleInput());
      if (c.water) { splashed = true; maxV = Math.max(maxV, c.vy); }
    }
    expect(splashed).toBe(true);
    expect(maxV).toBeLessThanOrEqual(230.01);
    expect(b.events.some((e) => e.k === 'splash')).toBe(true);
    expect(b.events.some((e) => e.k === 'boom')).toBe(true);
  });

  it('同時に出せる数に上限がある。左右それぞれ装填がある', () => {
    const b = battle();
    const cap = b.stats.capacity;
    for (let i = 0; i < 40; i++) step(b, { ...idleInput(), dropL: true, dropR: true });
    expect(b.charges.filter((c) => c.kind === 'charge').length).toBeLessThanOrEqual(cap);
    const b2 = battle();
    step(b2, { ...idleInput(), dropL: true });
    step(b2, { ...idleInput(), dropL: true });
    expect(b2.charges.length).toBe(1);
    step(b2, { ...idleInput(), dropR: true });
    expect(b2.charges.length).toBe(2);
  });

  it('艦は左右に動き、端で止まる。なぞった位置へ向かう', () => {
    const b = battle();
    run(b, 5, { move: -1 });
    expect(b.ship.x).toBe(60);
    run(b, 5, { targetX: 500 });
    expect(Math.abs(b.ship.x - 500)).toBeLessThan(8);
  });
});

describe('爆発と連鎖', () => {
  it('当たると爆発し、範囲の敵に打撃。近くの爆雷を誘爆させ、同じ連鎖で倒すほど点が増える', () => {
    const b = battle();
    const y = 400;
    const a = put(b, 'scout', 300, y), c = put(b, 'scout', 420, y);
    a.hp = 1; c.hp = 1;
    b.charges.push({ id: 900, x: 300, y: y - 30, vx: 0, vy: 100, water: true, power: 1, radius: 70, kind: 'charge', hit: false });
    b.charges.push({ id: 901, x: 360, y: y - 30, vx: 0, vy: 0, water: true, power: 1, radius: 70, kind: 'charge', hit: false });
    for (let i = 0; i < 30; i++) step(b, idleInput());
    expect(a.dead && c.dead).toBe(true);
    const kills = b.events.filter((e) => e.k === 'kill');
    expect(kills.length).toBe(2);
    expect(b.events.some((e) => e.k === 'chain' && e.n === 2)).toBe(true);
    const k2 = kills[1];
    if (k2.k === 'kill') expect(k2.score).toBe(Math.round(100 * 1 * 1.5));
    expect(b.bestChain).toBe(2);
  });

  it('機雷は爆発で誘爆し、魚雷は爆発で消える', () => {
    const b = battle();
    b.shots.push({ id: 800, kind: 'mine', x: 300, y: 500, vx: 0, vy: 0, life: 99, surfaced: false });
    b.shots.push({ id: 801, kind: 'torpedo', x: 330, y: 520, vx: 0, vy: 0, life: 99, surfaced: false });
    const f = put(b, 'sub', 380, 520);
    f.hp = 1;
    b.charges.push({ id: 900, x: 300, y: 470, vx: 0, vy: 60, water: true, power: 1, radius: 50, kind: 'charge', hit: false });
    for (let i = 0; i < 40; i++) step(b, idleInput());
    expect(b.shots.length).toBe(0);
    expect(f.dead).toBe(true);
  });

  it('命中率と星：当たった爆雷の割合', () => {
    const b = battle({ objective: { kind: 'survive', t: 1 } });
    b.drops = 10; b.hits = 5;
    expect(accuracy(b)).toBeCloseTo(0.5);
    run(b, 1.1);
    expect(b.phase).toBe('won');
    expect(starsOf(b)).toBe(3);
  });
});

describe('敵と攻撃', () => {
  it('魚雷は真上へ上がり、海面で艦に当たる。盾が1回防ぎ、当たった後は少し無敵', () => {
    const b = battle();
    b.ship.shield = 1;
    const hp = b.ship.hp;
    b.shots.push({ id: 800, kind: 'torpedo', x: b.ship.x, y: WL + 100, vx: 0, vy: -200, life: 9, surfaced: false });
    run(b, 1);
    expect(b.ship.hp).toBe(hp);
    expect(b.ship.shield).toBe(0);
    b.ship.inv = 0;
    b.shots.push({ id: 801, kind: 'torpedo', x: b.ship.x, y: WL + 100, vx: 0, vy: -200, life: 9, surfaced: false });
    b.shots.push({ id: 802, kind: 'torpedo', x: b.ship.x, y: WL + 110, vx: 0, vy: -200, life: 9, surfaced: false });
    run(b, 1);
    expect(b.ship.hp).toBe(hp - 1);
  });

  it('追尾魚雷は艦の方へ曲がる。機雷は浮かんで留まり、触れると2減る', () => {
    const b = battle();
    b.shots.push({ id: 800, kind: 'homing', x: b.ship.x + 200, y: WL + 500, vx: 0, vy: -130, life: 9, surfaced: false });
    run(b, 1);
    expect(b.shots[0].vx).toBeLessThan(0);
    const b2 = battle();
    b2.shots.push({ id: 801, kind: 'mine', x: b2.ship.x + 300, y: WL + 40, vx: 0, vy: -38, life: 20, surfaced: false });
    run(b2, 2);
    expect(b2.shots[0].surfaced).toBe(true);
    const hp = b2.ship.hp;
    run(b2, 3, { targetX: b2.shots[0].x });
    expect(b2.ship.hp).toBe(hp - 2);
  });

  it('魚雷艇は艦へ向かって体当たり。着水の爆雷で沈む', () => {
    const b = battle();
    put(b, 'boat', b.ship.x + 250, WL + 4);
    const hp = b.ship.hp;
    run(b, 4);
    expect(b.ship.hp).toBe(hp - 1);
    const b2 = battle();
    const boat = put(b2, 'boat', b2.ship.x + 100, WL + 4);
    run(b2, 0.6, { dropR: true });
    expect(boat.dead).toBe(true);
  });

  it('潜水艦は横に進んで画面の外へ出る。撃つのは艦の近くの時だけ', () => {
    const b = battle();
    const f = put(b, 'sub', 650, 560, { fireCd: [0] });
    run(b, 0.2);
    expect(b.shots.length).toBe(0);
    f.x = b.ship.x; f.fireCd = [0];
    run(b, 0.1);
    expect(b.shots.length).toBe(1);
    run(b, 10);
    expect(b.foes.includes(f)).toBe(false);
  });

  it('影の潜水艦はソナーか当たった時だけ見える。暗い海の深い所も同じ', () => {
    const b = battle();
    const g = put(b, 'ghost', 300, 1000);
    expect(visible(b, g)).toBe(false);
    g.revealedUntil = b.t + 1;
    expect(visible(b, g)).toBe(true);
    const b2 = battle({ dark: true });
    const d = put(b2, 'deep', 300, 1000);
    const m = put(b2, 'sub', 300, 500);
    expect(visible(b2, d)).toBe(false);
    expect(visible(b2, m)).toBe(true);
    b2.sonarCd = 0;
    b2.ship.x = 300;
    b2.stats = { ...b2.stats, sonarR: 700 };
    step(b2, idleInput());
    expect(visible(b2, d)).toBe(true);
  });
});

describe('ボス', () => {
  it('区画ごとに壊れ、残りで形態が変わる。全部壊すと勝ち', () => {
    const b = battle({ objective: { kind: 'boss', boss: 'titan' } });
    b.bossSpawned = true;
    const f = put(b, 'titan', 360, 560);
    b.bossUid = f.uid;
    expect(foeRects(f).length).toBe(3);
    f.parts![0].hp = 0.1;
    b.charges.push({ id: 900, x: 360 - 120, y: 540, vx: 0, vy: 50, water: true, power: 1, radius: 40, kind: 'charge', hit: false });
    run(b, 0.3);
    expect(f.parts![0].dead).toBe(true);
    expect(foeRects(f).length).toBe(2);
    f.parts![1].hp = 0.1;
    f.parts![2].hp = 0.1;
    expect(objectiveProgress(b)).toBeGreaterThan(0.9);
    b.charges.push({ id: 901, x: 360, y: 520, vx: 0, vy: 50, water: true, power: 1, radius: 160, kind: 'charge', hit: false });
    run(b, 0.4);
    expect(b.phase).toBe('won');
  });

  it('5つの海域にそれぞれボス。区画と技がある', () => {
    for (const id of [6, 12, 18, 24, 30]) {
      const o = stage(id).objective;
      expect(o.kind).toBe('boss');
      if (o.kind === 'boss') { expect(enemy(o.boss).parts!.length).toBe(3); expect(enemy(o.boss).bossFire!.length).toBe(3); }
    }
  });
});

describe('強化・特殊兵装', () => {
  it('強化は海面に浮かび、艦が触れると効く', () => {
    const b = battle();
    b.items.push({ id: 700, kind: 'rapid', x: b.ship.x, y: WL + 200, surfaced: false, life: 9 });
    b.items.push({ id: 701, kind: 'repair', x: b.ship.x, y: WL + 200, surfaced: false, life: 9 });
    b.ship.hp = 2;
    run(b, 3);
    expect(b.ship.rapidUntil).toBeGreaterThan(b.t);
    expect(b.ship.hp).toBe(4);
  });

  it('特殊ゲージが満ちると撃てる。4種それぞれ働く', () => {
    for (const sp of ['mortar', 'hedgehog', 'torpedo', 'sonar'] as const) {
      const b = battle();
      b.stats = { ...b.stats, special: sp };
      const f = put(b, 'deep', b.ship.x - 60, 560);
      f.hp = 0.5;
      b.ship.sp = 1;
      run(b, 6, { special: true });
      expect(b.ship.sp).toBeLessThan(1);
      expect(b.events.some((e) => e.k === 'special')).toBe(true);
      if (sp !== 'mortar') expect(f.dead, sp).toBe(true);
    }
  });
});

describe('目標', () => {
  it('護衛：船団が多く沈むと負け。渡りきれば勝ち', () => {
    const b2 = createBattle(calm({ objective: { kind: 'escort', ships: 3, need: 2 } }), shipStats(newProgress('normal', 1)), 1);
    b2.spawnCd = 1e9;
    startFight(b2);
    expect(b2.convoy.length).toBe(3);
    b2.convoy[0].state = 'sunk'; b2.convoy[1].state = 'sunk';
    step(b2, idleInput());
    expect(b2.phase).toBe('lost');
    const b3 = createBattle(calm({ objective: { kind: 'escort', ships: 2, need: 2 } }), shipStats(newProgress('normal', 1)), 1);
    b3.spawnCd = 1e9;
    startFight(b3);
    run(b3, 60);
    expect(b3.phase).toBe('won');
  });

  it('撃沈数の目標・耐える目標', () => {
    const b = battle({ objective: { kind: 'sink', n: 1 } });
    const f = put(b, 'scout', 300, 400);
    f.hp = 0.1;
    b.charges.push({ id: 900, x: 300, y: 380, vx: 0, vy: 50, water: true, power: 1, radius: 50, kind: 'charge', hit: false });
    run(b, 0.3);
    expect(b.phase).toBe('won');
    expect(objectiveText({ kind: 'survive', t: 45 })).toContain('45');
  });

  it('30ステージ。目標と敵はすべて定義済み', () => {
    expect(STAGE_COUNT).toBe(30);
    for (let id = 1; id <= STAGE_COUNT; id++) {
      const s = stage(id);
      for (const p of s.pool) expect(ENEMIES[p.enemy], p.enemy).toBeTruthy();
      expect(s.hpMul).toBeGreaterThan(0);
    }
    expect(applyDifficulty(stage(5), 'captain').hpMul).toBeGreaterThan(stage(5).hpMul);
  });
});

describe('改造・艦・特殊兵装', () => {
  it('金で改造。値段は上がり、最大で止まる。効果は能力に出る', () => {
    const p = newProgress('normal', 1);
    expect(upgradeError(p, 'power')).toBe('金が足りない');
    p.gold = 1e6;
    const before = shipStats(p);
    for (let i = 0; i < 9; i++) buyUpgrade(p, 'power');
    expect(p.upgrades.destroyer.power).toBe(UPGRADES.find((u) => u.id === 'power')!.max);
    expect(upgradeError(p, 'power')).toBe('最大');
    expect(shipStats(p).power).toBeCloseTo(before.power * 2.25);
    expect(upgradeCost('power', 1)).toBeGreaterThan(upgradeCost('power', 0));
  });

  it('艦と特殊兵装は進むと買える。改造は艦ごと', () => {
    const p = newProgress('normal', 1);
    p.gold = 1e6;
    expect(shipError(p, 'corvette')).toContain('ステージ');
    p.unlocked = 7;
    expect(chooseShip(p, 'corvette')).toBe(true);
    expect(p.ship).toBe('corvette');
    expect(shipStats(p).hull).toBe(SHIPS.corvette.hull);
    expect(specialError(p, 'torpedo')).toContain('ステージ');
    p.unlocked = 10;
    expect(chooseSpecial(p, 'torpedo')).toBe(true);
    expect(shipStats(p).special).toBe('torpedo');
  });

  it('結果：勝つと次が開き、金と星が入る。負けても金は残る', () => {
    const p = newProgress('normal', 1);
    const b = battle({ id: 1, objective: { kind: 'survive', t: 0.5 } });
    b.gold = 50;
    run(b, 1);
    const r = applyResult(p, b);
    expect(r.win).toBe(true);
    expect(p.unlocked).toBe(2);
    expect(p.gold).toBe(50 + r.bonus);
    expect(r.firstClear).toBe(true);
  });
});

describe('無限の海・毎日の挑戦', () => {
  it('波を越えると強くなる。撃沈数で次の波へ', () => {
    expect(endlessDef(40, 'normal').hpMul).toBeGreaterThan(endlessDef(10, 'normal').hpMul);
    expect(waveTarget(3)).toBeGreaterThan(waveTarget(1));
    const p = newProgress('normal', 1);
    const b = createBattle(endlessDef(1, 'normal'), shipStats(p), 3, { kind: 'endless' });
    startFight(b);
    b.waveKills = waveTarget(1);
    step(b, idleInput());
    expect(b.wave).toBe(2);
    expect(b.events.some((e) => e.k === 'wave')).toBe(true);
  });

  it('毎日の挑戦は同じ日付なら同じ。今日はじめて勝つと報酬', () => {
    expect(JSON.stringify(dailyDef('2026-10-17', 8, 'normal'))).toBe(JSON.stringify(dailyDef('2026-10-17', 8, 'normal')));
    const rules = new Set<string>();
    for (let d = 1; d <= 28; d++) rules.add(dailyRule(`2026-11-${String(d).padStart(2, '0')}`));
    expect(rules.size).toBeGreaterThanOrEqual(4);
    expect(DAILY_RULES[dailyRule('2026-10-17')]).toBeTruthy();
    const p = newProgress('normal', 1);
    expect(applyDaily(p, '2026-10-17', true, 100)).toBeGreaterThan(0);
    expect(applyDaily(p, '2026-10-17', true, 200)).toBe(0);
    expect(p.daily.best).toBe(200);
  });
});

describe('保存', () => {
  it('書いて読むと同じ。壊れたデータは読まない。設定は範囲に収める', () => {
    const p = newProgress('captain', 9);
    const text = JSON.stringify(p);
    expect(JSON.stringify(parseProgress(text))).toBe(text);
    expect(parseProgress('{')).toBeNull();
    expect(parseProgress(JSON.stringify({ ...p, v: 99 }))).toBeNull();
    const bad = clone(p); bad.upgrades.destroyer.power = 99;
    expect(parseProgress(JSON.stringify(bad))).toBeNull();
    const bad2 = clone(p); bad2.ship = 'cruiser';
    expect(parseProgress(JSON.stringify(bad2))).toBeNull();
    const kv = memKV();
    kv.setItem('depthline-fleet-v2:settings', JSON.stringify({ bgm: 9, se: -1 }));
    expect(loadSettings(kv).bgm).toBe(1);
    expect(loadSettings(kv).se).toBe(0);
    saveSettings({ bgm: 0.2, se: 0.3, vibrate: false, bigButtons: true }, kv);
    expect(loadSettings(kv)).toEqual({ bgm: 0.2, se: 0.3, vibrate: false, bigButtons: true });
  });
});

describe('総当たりと再現', () => {
  it('でたらめな操作をすべてのステージで行っても、数が壊れない', () => {
    for (let id = 1; id <= STAGE_COUNT; id++) {
      const p = newProgress(id % 2 ? 'normal' : 'captain', id);
      const def = applyDifficulty(stage(id), p.difficulty);
      const b = createBattle(def, shipStats(p), id * 13);
      startFight(b);
      let s = id;
      const rnd = () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
      for (let i = 0; i < 3600 && b.phase === 'fight'; i++) {
        const r = rnd();
        step(b, { move: r < 0.3 ? -1 : r < 0.6 ? 1 : 0, targetX: r > 0.95 ? rnd() * W : null, dropL: rnd() < 0.2, dropR: rnd() < 0.2, special: rnd() < 0.02 });
        if (i % 60 === 0) {
          for (const f of b.foes) expect(Number.isFinite(f.x) && Number.isFinite(f.y) && Number.isFinite(f.hp), `${id} ${f.def}`).toBe(true);
          for (const c of b.charges) expect(Number.isFinite(c.x) && Number.isFinite(c.y) && c.y <= FLOOR + 10).toBe(true);
          expect(b.ship.hp).toBeGreaterThanOrEqual(0);
          expect(b.ship.x).toBeGreaterThanOrEqual(60);
          expect(b.ship.x).toBeLessThanOrEqual(W - 60);
          expect(b.score).toBeGreaterThanOrEqual(0);
          expect(Number.isFinite(b.gold)).toBe(true);
        }
      }
      expect(['fight', 'won', 'lost']).toContain(b.phase);
      expect(BANDS.abyss[1]).toBeLessThan(FLOOR);
    }
  });

  it('同じ seed と同じ操作なら同じ結果', () => {
    const go = () => { const p = newProgress('normal', 4); const { r } = playStage(p, 3, 77); return JSON.stringify({ r, p }); };
    expect(go()).toBe(go());
  });

  it('上手なボットは、ふつうで30ステージを最後まで通せる', () => {
    const r = playRun('normal', 100, 120);
    expect(r.cleared).toBe(true);
  }, 600000);
});
