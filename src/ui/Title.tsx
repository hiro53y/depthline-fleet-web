// タイトル：背景で海戦が自動で動く。はじめる（難しさ）／つづきから／遊び方／設定
import { useEffect, useRef, useState } from 'react';
import { playSe } from '../audio/sound';
import { stage } from '../game/data';
import { createBattle, startFight, step, idleInput } from '../game/sim';
import type { Difficulty, Settings } from '../game/types';
import { newFx, consume, tickFx } from '../view/effects';
import { draw } from '../view/renderer';
import { Help, Modal, SettingsPanel, VERSION } from './common';

function DemoSea() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const b = createBattle({ ...stage(3), objective: { kind: 'survive', t: 1e9 } }, { hull: 99, speed: 220, reload: 0.5, capacity: 4, power: 1, radius: 72, sonarEvery: 6, sonarR: 400, special: 'mortar', specialLv: 1, half: 72 }, 7);
    startFight(b);
    const fx = newFx();
    fx.vibrate = false;
    let raf = 0, last = performance.now(), acc = 0, cd = 1, target = 360;
    const frame = (now: number) => {
      raf = requestAnimationFrame(frame);
      const dt = Math.min(0.1, (now - last) / 1000);
      last = now;
      acc += dt;
      while (acc >= 1 / 60) {
        acc -= 1 / 60;
        cd -= 1 / 60;
        const f = b.foes.find((x) => x.y > 300);
        if (f) target = f.x;
        const inp = { ...idleInput(), targetX: target };
        if (cd <= 0) { cd = 0.9; if (f) { if (f.x < b.ship.x) inp.dropL = true; else inp.dropR = true; } }
        b.ship.inv = 1;
        step(b, inp);
      }
      b.events = b.events.filter((e) => e.k !== 'spawn' && e.k !== 'end');
      consume(fx, b.events, b);
      b.events = [];
      fx.banners = [];
      tickFx(fx, dt);
      const c = ref.current;
      if (!c) return;
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const cw = Math.round(c.clientWidth * dpr), ch = Math.round(c.clientHeight * dpr);
      if (c.width !== cw || c.height !== ch) { c.width = cw; c.height = ch; }
      const g = c.getContext('2d');
      if (g) draw(g, cw, ch, b, fx, { shipId: 'destroyer', guide: false });
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, []);
  return <canvas ref={ref} className="demo-sea" />;
}

interface Props {
  hasSave: boolean;
  settings: Settings;
  onSettings: (s: Settings) => void;
  onNew: (d: Difficulty) => void;
  onContinue: () => void;
  onWipe: () => void;
}

export function Title({ hasSave, settings, onSettings, onNew, onContinue, onWipe }: Props) {
  const [modal, setModal] = useState<'' | 'mode' | 'help' | 'settings'>('');
  const [overwrite, setOverwrite] = useState<Difficulty | null>(null);
  const pick = (d: Difficulty) => {
    if (hasSave && overwrite !== d) { setOverwrite(d); playSe('menu'); return; }
    playSe('special');
    onNew(d);
  };
  return (
    <div className="screen title-screen">
      <DemoSea />
      <div className="title-shade" />
      <div className="title-box">
        <div className="logo">
          <div className="logo-en">DEPTHLINE<br />FLEET</div>
          <div className="logo-ja">爆雷で深海の敵を沈めろ</div>
        </div>
        <div className="title-menu">
          {hasSave && <button className="btn gold big" onClick={() => { playSe('special'); onContinue(); }}>つづきから</button>}
          <button className={`btn ${hasSave ? '' : 'gold big'}`} onClick={() => { playSe('menu'); setOverwrite(null); setModal('mode'); }}>はじめから</button>
          <div className="title-sub">
            <button className="btn small" onClick={() => { playSe('menu'); setModal('help'); }}>遊び方</button>
            <button className="btn small" onClick={() => { playSe('menu'); setModal('settings'); }}>設定</button>
          </div>
        </div>
      </div>
      <div className="title-ver">Ver.{VERSION}</div>
      {modal === 'mode' && (
        <Modal title="難しさを選ぶ" onClose={() => setModal('')}>
          <div className="modes">
            <button className="mode-card" onClick={() => pick('normal')}><b>ふつう</b><span>はじめての人はこちら。</span></button>
            <button className="mode-card pro" onClick={() => pick('captain')}><b>艦長</b><span>敵が硬く、多く、よく撃つ。報酬は多い。</span></button>
          </div>
          {overwrite && <p className="warn">今の記録は消えて最初からになります。もう一度押すと始めます。</p>}
        </Modal>
      )}
      {modal === 'help' && <Help onClose={() => setModal('')} />}
      {modal === 'settings' && <SettingsPanel settings={settings} onSettings={onSettings} onClose={() => setModal('')} onWipe={hasSave ? onWipe : undefined} />}
    </div>
  );
}
