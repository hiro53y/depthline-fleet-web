// 戦闘：上の帯（点・目標・船体）＋ Canvas の海 ＋ 下の操作盤（移動・特殊・左右投下）
import { useEffect, useRef, useState } from 'react';
import { playBgm } from '../audio/bgm';
import { playSe } from '../audio/sound';
import { STAGE_COUNT, WL, applyDifficulty, objectiveText, stage } from '../game/data';
import { dailyDef, dateKey, endlessDef, waveTarget } from '../game/modes';
import { applyDaily, applyResult, canPlay, shipStats, type Result } from '../game/progress';
import { saveProgress } from '../game/save';
import { STEP, accuracy, createBattle, idleInput, objectiveProgress, specialReady, startFight, step, type Battle, type Input } from '../game/sim';
import type { Progress, Settings } from '../game/types';
import { banner, consume, newFx, tickFx, type Fx } from '../view/effects';
import { draw, toField, viewportOf } from '../view/renderer';
import { Help, Modal, SettingsPanel, fmt } from './common';
import { toLocal } from '../orientation';

export type BattleMode = { kind: 'stage'; id: number } | { kind: 'endless' } | { kind: 'daily' };

interface Props {
  p: Progress;
  mode: BattleMode;
  settings: Settings;
  onSettings: (s: Settings) => void;
  onChange: () => void;
  onMap: () => void;
  onDock: () => void;
  onPlay: (m: BattleMode) => void;
}

interface Held { left: boolean; right: boolean; dropL: boolean; dropR: boolean; special: boolean; targetX: number | null; tapL: boolean; tapR: boolean }

const TIPS: Record<string, string> = {
  move: '◀ ▶ で艦を動かし、左投下・右投下で爆雷を落とす。点線が落ちる場所の目安。',
  lead: '爆雷は沈むのに時間がかかる。敵が進む先に落とそう。深い敵ほど早めに。',
  special: '特殊ゲージが満ちた！ まん中の「特殊」で強力な兵装を撃てる。',
  chain: '爆発は近くの爆雷や機雷を誘爆させる。まとめて沈めると連鎖で点が増える。',
  shots: '上がってくる魚雷や機雷は、爆雷の爆発で消せる。',
};

export function BattleScreen({ p, mode, settings, onSettings, onChange, onMap, onDock, onPlay }: Props) {
  const wrap = useRef<HTMLDivElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const [setup] = useState(() => {
    const stats = shipStats(p);
    const seed = (p.seed ^ Date.now()) | 0;
    if (mode.kind === 'endless') return { b: createBattle(endlessDef(1, p.difficulty), stats, seed, { kind: 'endless', difficulty: p.difficulty }), date: '' };
    if (mode.kind === 'daily') { const date = dateKey(); return { b: createBattle(dailyDef(date, p.unlocked, p.difficulty).def, stats, seed, { kind: 'daily', difficulty: p.difficulty }), date }; }
    return { b: createBattle(applyDifficulty(stage(mode.id), p.difficulty), stats, seed, { difficulty: p.difficulty }), date: '' };
  });
  const b: Battle = setup.b;
  const fxRef = useRef<Fx>(newFx());
  const held = useRef<Held>({ left: false, right: false, dropL: false, dropR: false, special: false, targetX: null, tapL: false, tapR: false });
  const [menu, setMenu] = useState<'' | 'pause' | 'help' | 'settings'>('');
  const [result, setResult] = useState<(Result & { reward: number }) | null>(null);
  const [tip, setTip] = useState<string | null>(null);
  const [, setTick] = useState(0);
  const live = useRef({ stop: false });
  live.current = { stop: menu !== '' || !!result || b.phase === 'ready' };
  const ended = useRef<{ at: number; r: Result & { reward: number } } | null>(null);

  useEffect(() => { playBgm(mode.kind === 'stage' ? 'campaign' : 'score_attack'); }, [mode.kind]);
  useEffect(() => { fxRef.current.vibrate = settings.vibrate; }, [settings.vibrate]);

  const finish = (): Result & { reward: number } => {
    const r = applyResult(p, b);
    let reward = 0;
    if (mode.kind === 'daily') reward = applyDaily(p, setup.date, r.win, b.score);
    saveProgress(p);
    return { ...r, reward };
  };

  // 進行と描画
  useEffect(() => {
    let raf = 0, last = performance.now(), acc = 0;
    const fx = fxRef.current;
    const frame = (now: number) => {
      raf = requestAnimationFrame(frame);
      const dt = Math.min(0.1, Math.max(0, (now - last) / 1000));
      last = now;
      const el = wrap.current, cv = canvas.current;
      if (!el || !cv) return;
      if (!live.current.stop) {
        if (b.phase === 'fight') {
          if (fx.freeze > 0) fx.freeze = Math.max(0, fx.freeze - dt);
          else {
            acc += dt;
            let n = 0;
            while (acc >= STEP && n++ < 8 && b.phase === 'fight') {
              acc -= STEP;
              const h = held.current;
              const inp: Input = { move: h.left === h.right ? 0 : h.left ? -1 : 1, targetX: h.targetX, dropL: h.dropL || h.tapL, dropR: h.dropR || h.tapR, special: h.special };
              h.tapL = false; h.tapR = false; h.special = false;
              step(b, inp);
            }
          }
          if (b.events.length) { consume(fx, b.events, b); b.events = []; }
        }
        tickFx(fx, dt);
        if ((b.phase === 'won' || b.phase === 'lost') && !ended.current) {
          if (b.events.length) { consume(fx, b.events, b); b.events = []; }
          ended.current = { at: fx.now, r: finish() };
        }
        if (ended.current && fx.now - ended.current.at > 2.2) {
          const r = ended.current.r;
          ended.current = { at: Infinity, r };
          setResult(r);
          onChange();
        }
      }
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const cw = Math.round(el.clientWidth * dpr), ch = Math.round(el.clientHeight * dpr);
      if (cv.width !== cw || cv.height !== ch) { cv.width = cw; cv.height = ch; }
      const g = cv.getContext('2d');
      if (g) draw(g, cw, ch, b, fx, { shipId: p.ship, guide: true });
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [b, p, onChange]);

  // 帯の描き直し・案内
  useEffect(() => {
    let n = 0;
    const id = window.setInterval(() => {
      setTick((t) => t + 1);
      if (++n % 8 !== 0 || b.phase !== 'fight') return;
      const seen = (k: string) => p.tips.includes(k);
      let want: string | null = null;
      if (!seen('lead') && b.t > 6 && b.drops >= 3) want = 'lead';
      else if (!seen('special') && b.ship.sp >= 1) want = 'special';
      else if (!seen('shots') && b.shots.length > 0 && b.t > 10) want = 'shots';
      else if (!seen('chain') && b.kills >= 4) want = 'chain';
      setTip((cur) => cur ?? want);
    }, 125);
    return () => window.clearInterval(id);
  }, [b, p]);

  // キー操作（PC）
  useEffect(() => {
    const key = (e: KeyboardEvent, on: boolean) => {
      const h = held.current;
      switch (e.key) {
        case 'ArrowLeft': case 'a': h.left = on; break;
        case 'ArrowRight': case 'd': h.right = on; break;
        case 'z': case 'Z': case 'j': h.dropL = on; break;
        case 'x': case 'X': case 'k': h.dropR = on; break;
        case ' ': if (on) h.special = true; break;
        case 'p': case 'Escape': if (on && b.phase === 'fight') setMenu('pause'); break;
        default: return;
      }
      e.preventDefault();
    };
    const down = (e: KeyboardEvent) => key(e, true), up = (e: KeyboardEvent) => key(e, false);
    window.addEventListener('keydown', down);
    window.addEventListener('keyup', up);
    return () => { window.removeEventListener('keydown', down); window.removeEventListener('keyup', up); };
  }, [b]);

  // 裏に回ったら止める
  useEffect(() => {
    const on = () => { if (document.hidden && b.phase === 'fight') { setMenu('pause'); saveProgress(p); } };
    document.addEventListener('visibilitychange', on);
    return () => document.removeEventListener('visibilitychange', on);
  }, [b, p]);

  // 確かめ用の口（開発中か ?dbg=1）
  useEffect(() => {
    if (!import.meta.env.DEV && !location.search.includes('dbg=1')) return;
    const w = window as unknown as { __df?: unknown };
    w.__df = {
      b, p, fx: fxRef.current, held: held.current,
      start: () => startFight(b),
      run: (sec: number, inp: Partial<Input> = {}) => { const n = Math.round(sec * 60); for (let i = 0; i < n && b.phase === 'fight'; i++) step(b, { ...idleInput(), ...inp }); consume(fxRef.current, b.events, b); b.events = []; return { phase: b.phase, t: b.t, hp: b.ship.hp, kills: b.kills, score: b.score }; },
    };
    return () => { delete w.__df; };
  }, [b, p]);

  const begin = () => {
    if (b.phase !== 'ready') return;
    startFight(b);
    banner(fxRef.current, mode.kind === 'endless' ? '第1波' : '出撃！', '#9fe7ff', mode.kind === 'stage' ? objectiveText(b.def.objective) : undefined, 2);
    playSe('alarm');
    if (!p.tips.includes('move')) setTip('move');
  };

  // 海に触れる：海面より上をなぞると移動、海の中に触れるとその側へ投下
  const fieldAt = (e: React.PointerEvent): [number, number] | null => {
    const el = wrap.current;
    if (!el) return null;
    const [lx, ly] = toLocal(el, e.clientX, e.clientY);
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const v = viewportOf(Math.round(el.clientWidth * dpr), Math.round(el.clientHeight * dpr));
    return toField(v, lx * dpr, ly * dpr);
  };
  const dragging = useRef<number | null>(null);
  const onDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (b.phase === 'ready') { begin(); return; }
    const pt = fieldAt(e);
    if (!pt) return;
    if (pt[1] < WL + 60) {
      dragging.current = e.pointerId;
      held.current.targetX = pt[0];
      try { (e.target as HTMLElement).setPointerCapture?.(e.pointerId); } catch { /* 指が離れていた */ }
    } else if (pt[0] < b.ship.x) held.current.tapL = true;
    else held.current.tapR = true;
  };
  const onMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (dragging.current !== e.pointerId) return;
    const pt = fieldAt(e);
    if (pt) held.current.targetX = pt[0];
  };
  const onUp = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (dragging.current === e.pointerId) { dragging.current = null; held.current.targetX = null; }
  };

  /** 押している間だけ効くボタン */
  const hold = (k: 'left' | 'right' | 'dropL' | 'dropR') => ({
    onPointerDown: (e: React.PointerEvent) => { e.preventDefault(); held.current[k] = true; if (b.phase === 'ready') begin(); },
    onPointerUp: () => { held.current[k] = false; },
    onPointerLeave: () => { held.current[k] = false; },
    onPointerCancel: () => { held.current[k] = false; },
    onContextMenu: (e: React.MouseEvent) => e.preventDefault(),
  });

  const closeTip = () => { if (tip && !p.tips.includes(tip)) p.tips.push(tip); setTip(null); saveProgress(p); };
  const retry = () => { saveProgress(p); onPlay(mode); };

  const s = b.ship;
  const o = b.def.objective;
  const prog = objectiveProgress(b);
  const objText = b.kind === 'endless' ? `第${b.wave}波 ${b.waveKills}/${waveTarget(b.wave)}`
    : o.kind === 'sink' ? `撃沈 ${b.kills}/${o.n}` : o.kind === 'survive' ? `残り ${Math.max(0, Math.ceil(o.t - b.t))}秒`
      : o.kind === 'escort' ? `船団 ${b.convoy.filter((c) => c.state === 'done').length}/${o.ships}（沈没 ${b.convoy.filter((c) => c.state === 'sunk').length}）` : `ボス ${Math.round(prog * 100)}%`;
  const label = mode.kind === 'stage' ? `${mode.id}. ${b.def.name}` : b.def.name;
  const buffs = [
    b.t < s.rapidUntil && `連射 ${Math.ceil(s.rapidUntil - b.t)}`,
    b.t < s.bigUntil && `大型 ${Math.ceil(s.bigUntil - b.t)}`,
    b.t < s.tripleUntil && `三連 ${Math.ceil(s.tripleUntil - b.t)}`,
    s.shield > 0 && `盾 ${s.shield}`,
  ].filter(Boolean) as string[];
  const ready = specialReady(b);

  return (
    <div className={`screen battle-screen ${settings.bigButtons ? 'big-ui' : ''}`}>
      <div className="hud">
        <button className="btn icon" aria-label="一時停止" onClick={() => { playSe('menu'); setMenu('pause'); }}>Ⅱ</button>
        <div className="hud-mid">
          <div className="hud-line"><span className="hud-stage">{label}</span><span className="hud-score">{fmt(b.score)}</span></div>
          <div className="obj-bar"><i style={{ width: `${Math.min(1, b.kind === 'endless' ? b.waveKills / waveTarget(b.wave) : prog) * 100}%` }} /><span>{objText}</span></div>
        </div>
        <div className="hull" aria-label={`船体 ${s.hp}/${s.maxHp}`}>
          {Array.from({ length: s.maxHp }, (_, i) => <i key={i} className={i < s.hp ? 'on' : ''} />)}
        </div>
      </div>

      <div className="sea" ref={wrap}>
        <canvas ref={canvas} onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp} />
        {buffs.length > 0 && <div className="buffs">{buffs.map((x) => <span key={x}>{x}</span>)}</div>}
        {b.phase === 'ready' && (
          <div className="ready-card" onPointerDown={begin}>
            <b>{label}</b>
            <span>{b.kind === 'endless' ? '波ごとに強くなる敵を沈め続けよ' : objectiveText(o)}</span>
            {b.def.storm && <small>嵐：艦が揺れ、海の流れで爆雷が流される</small>}
            {b.def.ice && <small>流氷：爆雷を止める。爆発で割れる</small>}
            {b.def.dark && <small>暗い海：深い所はソナーの波で見える</small>}
            <button className="btn gold big">出撃！</button>
          </div>
        )}
        {tip && !result && !menu && (
          <div className="tip" onPointerDown={(e) => e.stopPropagation()}>
            <span>{TIPS[tip]}</span>
            <button className="btn small" onClick={closeTip}>わかった</button>
          </div>
        )}
      </div>

      <div className="controls">
        <button className="cbtn move" aria-label="左へ" {...hold('left')}>◀</button>
        <button className="cbtn move" aria-label="右へ" {...hold('right')}>▶</button>
        <button className={`cbtn special ${ready ? 'ready' : ''}`} aria-label="特殊兵装" onPointerDown={(e) => { e.preventDefault(); held.current.special = true; }}>
          <i style={{ height: `${s.sp * 100}%` }} /><span>特殊</span>
        </button>
        <button className={`cbtn drop ${s.cool.L > 0 ? 'cool' : ''}`} aria-label="左に投下" {...hold('dropL')}><span>左</span>投下</button>
        <button className={`cbtn drop ${s.cool.R > 0 ? 'cool' : ''}`} aria-label="右に投下" {...hold('dropR')}><span>右</span>投下</button>
      </div>

      {menu === 'pause' && (
        <Modal title="一時停止" onClose={() => setMenu('')}>
          <div className="pause-menu">
            <button className="btn gold big" onClick={() => { playSe('menu'); setMenu(''); }}>再開する</button>
            <button className="btn" onClick={retry}>はじめからやり直す</button>
            <button className="btn" onClick={() => { saveProgress(p); onMap(); }}>海図へ戻る</button>
            <div className="row2">
              <button className="btn small" onClick={() => setMenu('help')}>遊び方</button>
              <button className="btn small" onClick={() => setMenu('settings')}>設定</button>
            </div>
            <p className="muted">やめると、この戦闘で得た金は入りません。</p>
          </div>
        </Modal>
      )}
      {menu === 'help' && <Help onClose={() => setMenu('pause')} />}
      {menu === 'settings' && <SettingsPanel settings={settings} onSettings={onSettings} onClose={() => setMenu('pause')} />}

      {result && (
        <Modal className={`result ${result.win ? 'win' : 'lose'}`}>
          <div className="result-box">
            <div className={`res-title ${result.win ? '' : 'lose'}`}>{b.kind === 'endless' ? `第${b.wave}波で撃沈` : result.win ? '任務完了！' : '撃沈された…'}</div>
            {b.kind === 'stage' && result.win && <div className="res-stars">{[1, 2, 3].map((i) => <span key={i} className={i <= result.stars ? 'on' : ''} style={{ animationDelay: `${i * 0.18}s` }}>★</span>)}</div>}
            {result.newBest && <div className="goldc">最高記録！</div>}
            <div className="res-rows">
              <div><span>撃沈</span><b>{result.kills}</b></div>
              <div><span>最大連鎖</span><b>{result.bestChain}</b></div>
              <div><span>命中率</span><b>{Math.round(accuracy(b) * 100)}%</b></div>
              <div><span>被弾</span><b>{result.hullLost}</b></div>
              <div><span>点数</span><b>{fmt(result.score)}</b></div>
              <div><span>得た金</span><b>{fmt(result.gold + result.bonus + result.reward)}</b></div>
            </div>
            {result.bonus > 0 && <p className="muted">クリアの報酬 金 {fmt(result.bonus)} を含む</p>}
            {result.reward > 0 && <p className="goldc">今日の挑戦の報酬 金 {fmt(result.reward)}！</p>}
            {mode.kind === 'stage' && mode.id === STAGE_COUNT && result.win && result.firstClear && <p className="ending">敵の旗艦は深淵に沈んだ。海に静けさが戻る──艦隊の勝利だ。</p>}
            <div className="res-btns">
              {mode.kind === 'stage' && result.win && mode.id < STAGE_COUNT && canPlay(p, mode.id + 1) && <button className="btn gold big" onClick={() => { playSe('special'); onPlay({ kind: 'stage', id: mode.id + 1 }); }}>次のステージへ</button>}
              <button className={`btn ${result.win ? '' : 'gold big'}`} onClick={() => { playSe('menu'); retry(); }}>{result.win ? 'もう一度' : 'やり直す'}</button>
              <button className="btn" onClick={() => { playSe('menu'); onDock(); }}>改造</button>
              <button className="btn" onClick={() => { playSe('menu'); onMap(); }}>海図へ</button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
