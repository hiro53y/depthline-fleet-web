// 硬さの調整（CALIBRATE=1 の時だけ）：上手なボットが初回に船体の目標の割合を失う強さを、ステージごとに二分探索で探す
import { it } from 'vitest';
import { CALIB, STAGE_COUNT, stage } from '../src/game/data';
import { clone, newProgress, shipStats } from '../src/game/progress';
import { botTrain, playStage } from './bot';

it.runIf(Number(process.env.CALIBRATE ?? 0) > 0)('硬さの調整', () => {
  const seeds = [11, 23, 37];
  const out: number[] = [];
  let p = newProgress('normal', 7);
  for (let id = 1; id <= STAGE_COUNT; id++) {
    botTrain(p);
    const hull = shipStats(p).hull;
    // ボスは半分、他は3割ほど失う強さ
    const target = Math.max(1, Math.round(hull * (stage(id).objective.kind === 'boss' ? 0.5 : 0.3)));
    const start = clone(p);
    let lo = 0.3, hi = 8;
    for (let k = 0; k < 12; k++) {
      const m = Math.sqrt(lo * hi);
      CALIB[id - 1] = m;
      const ok = seeds.filter((s) => { const q = clone(start); const { r } = playStage(q, id, s * 100 + id); return r.win && r.hullLost <= target; }).length >= 2;
      if (ok) lo = m; else hi = m;
    }
    CALIB[id - 1] = Math.floor(lo * 100) / 100;
    out.push(CALIB[id - 1]);
    const q = clone(start);
    const { r } = playStage(q, id, seeds[0] * 100 + id);
    p = q;
    console.log(`stage ${id} calib ${CALIB[id - 1]} win ${r.win} lost ${r.hullLost}/${hull} gold ${p.gold}`);
  }
  console.log(`CALIB = [${out.join(', ')}]`);
}, 3_600_000);
