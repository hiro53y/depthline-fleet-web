import { it } from 'vitest';
import { applyDifficulty, stage } from '../src/game/data';
import { newProgress, shipStats } from '../src/game/progress';
import { createBattle, startFight, step } from '../src/game/sim';
import { botInput } from './bot';

it.runIf(!!process.env.PROBE)('probe', () => {
  const p = newProgress('normal', 1);
  if (process.env.MAXUP) for (const k of Object.keys(p.upgrades.destroyer) as (keyof typeof p.upgrades.destroyer)[]) p.upgrades.destroyer[k] = k === 'capacity' ? 4 : k === 'special' ? 3 : 5;
  const def = applyDifficulty(stage(Number(process.env.PROBE)), 'normal');
  const b = createBattle(def, shipStats(p), 5);
  startFight(b);
  let lastLog = -10;
  const ev: Record<string, number> = {};
  while (b.phase === 'fight' && b.t < 300) {
    step(b, botInput(b));
    for (const e of b.events) ev[e.k] = (ev[e.k] ?? 0) + 1;
    b.events = [];
    if (b.t - lastLog >= 10) {
      lastLog = b.t;
      const boss = b.foes.find((f) => f.uid === b.bossUid);
      console.log(`t=${b.t.toFixed(0)} hp=${b.ship.hp} kills=${b.kills} foes=${b.foes.length} boss=${boss ? `${boss.x.toFixed(0)},${boss.y.toFixed(0)} hp${boss.hp.toFixed(1)} parts ${boss.parts!.map((q) => q.hp.toFixed(0)).join('/')}` : '-'} charges=${b.charges.length} shots=${b.shots.length} drops=${b.drops} hits=${b.hits}`);
    }
  }
  console.log(b.phase, b.t.toFixed(1), JSON.stringify(ev));
});
