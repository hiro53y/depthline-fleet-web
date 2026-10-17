// 難しさの集計（BALANCE=回数 の時だけ動く）
import { describe, it } from 'vitest';
import { playRun } from './bot';

const N = Number(process.env.BALANCE ?? 0);

describe.runIf(N > 0)('難しさの集計', () => {
  for (const d of ['normal', 'captain'] as const) {
    for (let i = 0; i < N; i++) {
      it(`${d} ${i + 1}`, () => {
        const r = playRun(d, 100 + i * 17, Number(process.env.MAX_BATTLES ?? 150));
        const p = r.p;
        console.log(JSON.stringify({ d, seed: 100 + i * 17, cleared: r.cleared, reached: p.unlocked, battles: p.stats.battles, retries: r.retries, firstTry: r.firstTry, gold: p.gold, up: p.upgrades[p.ship], per: r.perStage.join(' ') }));
      }, 600000);
    }
  }
});
