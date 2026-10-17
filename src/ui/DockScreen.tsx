// 改造：艦を選ぶ・改造する・特殊兵装を選ぶ（金を使う）
import { useEffect, useRef, useState } from 'react';
import { playSe } from '../audio/sound';
import { SHIPS, SHIP_IDS, SPECIALS, SPECIAL_IDS, UPGRADES, W, upgradeCost } from '../game/data';
import { buyUpgrade, chooseShip, chooseSpecial, shipError, shipStats, specialError, upgradeError } from '../game/progress';
import type { Progress, ShipId } from '../game/types';
import { drawShip } from '../view/art';
import { fmt } from './common';

function ShipView({ id, half }: { id: ShipId; half: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    let raf = 0;
    const t0 = performance.now();
    const frame = (now: number) => {
      raf = requestAnimationFrame(frame);
      const c = ref.current;
      if (!c) return;
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const cw = Math.round(c.clientWidth * dpr), ch = Math.round(c.clientHeight * dpr);
      if (c.width !== cw || c.height !== ch) { c.width = cw; c.height = ch; }
      const g = c.getContext('2d');
      if (!g) return;
      const k = ch / 150;
      g.setTransform(1, 0, 0, 1, 0, 0);
      const gr = g.createLinearGradient(0, 0, 0, ch);
      gr.addColorStop(0, '#9ac8e8'); gr.addColorStop(0.62, '#d8eef8'); gr.addColorStop(0.62, '#1d7aa0'); gr.addColorStop(1, '#0d3e5e');
      g.fillStyle = gr;
      g.fillRect(0, 0, cw, ch);
      g.setTransform(k, 0, 0, k, cw / 2 - (W / 2) * k, 0);
      drawShip(g, id, SHIPS[id].color, W / 2, 93, (now - t0) / 1000, half, 0);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [id, half]);
  return <canvas ref={ref} className="ship-view" />;
}

export function DockScreen({ p, onChange, onBack }: { p: Progress; onChange: () => void; onBack: () => void }) {
  const [tab, setTab] = useState<'up' | 'ship' | 'special'>('up');
  const st = shipStats(p);
  const u = p.upgrades[p.ship];
  return (
    <div className="screen dock-screen">
      <div className="topbar">
        <button className="btn small" onClick={() => { playSe('menu'); onBack(); }}>◀ 海図</button>
        <b className="dock-title">改造ドック</b>
        <span className="grow" />
        <span className="chip gold-chip">金 <b>{fmt(p.gold)}</b></span>
      </div>
      <ShipView id={p.ship} half={st.half} />
      <div className="stats-row">
        <span>船体<b>{st.hull}</b></span>
        <span>速さ<b>{Math.round(st.speed)}</b></span>
        <span>装填<b>{st.reload.toFixed(2)}秒</b></span>
        <span>投下数<b>{st.capacity}</b></span>
        <span>威力<b>{st.power.toFixed(2)}</b></span>
        <span>範囲<b>{Math.round(st.radius)}</b></span>
      </div>
      <div className="seg tabs">
        <button className={tab === 'up' ? 'on' : ''} onClick={() => setTab('up')}>改造</button>
        <button className={tab === 'ship' ? 'on' : ''} onClick={() => setTab('ship')}>艦</button>
        <button className={tab === 'special' ? 'on' : ''} onClick={() => setTab('special')}>特殊兵装</button>
      </div>
      <div className="dock-list">
        {tab === 'up' && UPGRADES.map((d) => {
          const lv = u[d.id];
          const err = upgradeError(p, d.id);
          return (
            <div className="up-row" key={d.id}>
              <div className="up-main">
                <b>{d.name}</b>
                <span className="pips">{Array.from({ length: d.max }, (_, i) => <i key={i} className={i < lv ? 'on' : ''} />)}</span>
                <small>{lv ? d.desc(lv) : 'まだ'}{lv < d.max && <em>{` → ${d.desc(lv + 1)}`}</em>}</small>
              </div>
              {lv < d.max
                ? <button className="btn gold small" disabled={!!err} onClick={() => { if (buyUpgrade(p, d.id)) { playSe('lvup'); onChange(); } }}>金 {fmt(upgradeCost(d.id, lv))}</button>
                : <span className="muted">最大</span>}
            </div>
          );
        })}
        {tab === 'ship' && SHIP_IDS.map((id) => {
          const d = SHIPS[id];
          const own = p.ships.includes(id);
          const err = shipError(p, id);
          return (
            <div className={`up-row ${p.ship === id ? 'sel' : ''}`} key={id}>
              <div className="up-main">
                <b>{d.name}</b>
                <small>{d.desc}</small>
                <small className="muted">船体{d.hull}・速さ{d.speed}・装填{d.reload}秒・投下{d.capacity}・威力{d.power}・範囲{d.radius}</small>
              </div>
              {p.ship === id ? <span className="goldc">使用中</span>
                : <button className={`btn small ${own ? '' : 'gold'}`} disabled={!!err} onClick={() => { if (chooseShip(p, id)) { playSe('special'); onChange(); } }}>{own ? '使う' : err ?? `買う 金 ${fmt(d.price)}`}</button>}
            </div>
          );
        })}
        {tab === 'special' && SPECIAL_IDS.map((id) => {
          const d = SPECIALS[id];
          const own = p.specials.includes(id);
          const err = specialError(p, id);
          return (
            <div className={`up-row ${p.special === id ? 'sel' : ''}`} key={id}>
              <div className="up-main">
                <b style={{ color: d.color }}>{d.name}</b>
                <small>{d.desc}</small>
              </div>
              {p.special === id ? <span className="goldc">装備中</span>
                : <button className={`btn small ${own ? '' : 'gold'}`} disabled={!!err} onClick={() => { if (chooseSpecial(p, id)) { playSe('special'); onChange(); } }}>{own ? '装備' : err ?? `買う 金 ${fmt(d.price)}`}</button>}
            </div>
          );
        })}
        {tab === 'up' && <p className="muted pad">改造は艦ごと。特殊兵装のレベルはどの兵装にも効く。</p>}
      </div>
    </div>
  );
}
