// 海図：30のステージを、下へ行くほど深くなる航路で並べる。改造・無限の海・毎日の挑戦への入口
import { useEffect, useRef, useState } from 'react';
import { playSe } from '../audio/sound';
import { AREAS, PER_AREA, STAGE_COUNT, applyDifficulty, enemy, objectiveText, stage } from '../game/data';
import { DAILY_RULES, dailyDef, dateKey } from '../game/modes';
import { canPlay } from '../game/progress';
import type { Progress, Settings } from '../game/types';
import { EnemyIcon, Help, Modal, SettingsPanel, fmt } from './common';

interface Props {
  p: Progress;
  settings: Settings;
  onSettings: (s: Settings) => void;
  onPlay: (id: number) => void;
  onEndless: () => void;
  onDaily: () => void;
  onDock: () => void;
  onTitle: () => void;
  onWipe: () => void;
}

/** 無限の海・毎日の挑戦が開くステージ */
export const EXTRA_UNLOCK = 6;

export function MapScreen({ p, settings, onSettings, onPlay, onEndless, onDaily, onDock, onTitle, onWipe }: Props) {
  const [pick, setPick] = useState<number | null>(null);
  const [modal, setModal] = useState<'' | 'help' | 'settings' | 'endless' | 'daily'>('');
  const listRef = useRef<HTMLDivElement>(null);
  const extra = p.unlocked > EXTRA_UNLOCK || !!p.stars[EXTRA_UNLOCK];
  const totalStars = Object.values(p.stars).reduce((a, b) => a + b, 0);

  useEffect(() => {
    const el = listRef.current?.querySelector('.node.cur');
    if (el) el.scrollIntoView({ block: 'center' });
  }, []);

  return (
    <div className="screen map-screen">
      <div className="topbar">
        <button className="btn small" onClick={() => { playSe('menu'); onTitle(); }}>タイトル</button>
        <span className="chip gold-chip">金 <b>{fmt(p.gold)}</b></span>
        <span className="chip">★ <b>{totalStars}</b>/{STAGE_COUNT * 3}</span>
        <span className="grow" />
        <button className="btn small" onClick={() => { playSe('menu'); setModal('help'); }}>?</button>
        <button className="btn small" onClick={() => { playSe('menu'); setModal('settings'); }}>設定</button>
      </div>

      <div className="route" ref={listRef}>
        {AREAS.map((a, ai) => (
          <section key={a.id} className={`area area-${a.id}`} style={{ background: `linear-gradient(${a.sea[0]}, ${a.sea[1]})` }}>
            <div className="area-head"><b>{ai + 1}. {a.name}</b><span>{a.desc}</span></div>
            <div className="nodes">
              {Array.from({ length: PER_AREA }, (_, k) => {
                const id = ai * PER_AREA + k + 1;
                const s = stage(id);
                const open = canPlay(p, id);
                const st = p.stars[id] ?? 0;
                const cur = id === p.unlocked && !st;
                const boss = s.objective.kind === 'boss';
                return (
                  <button key={id} className={`node ${boss ? 'boss' : ''} ${open ? '' : 'locked'} ${cur ? 'cur' : ''} ${st ? 'done' : ''} side${k % 2}`} disabled={!open} onClick={() => { playSe('menu'); setPick(id); }} aria-label={`ステージ${id}`}>
                    <span className="num">{boss ? '☠' : id}</span>
                    <span className="nname">{s.name}</span>
                    <span className="stars">{st ? '★'.repeat(st) + '☆'.repeat(3 - st) : open ? '' : '🔒'}</span>
                  </button>
                );
              })}
            </div>
          </section>
        ))}
        {p.cleared && <div className="cleared-flag">全30ステージ制覇！ 艦隊の勝利だ。</div>}
      </div>

      <div className="dockbar">
        <button className="btn gold" onClick={() => { playSe('menu'); onDock(); }}><b>改造</b><small>艦・兵装</small></button>
        <button className={`btn ${extra ? '' : 'off'}`} onClick={() => { playSe('menu'); setModal('endless'); }}><b>無限の海</b><small>{p.endless.best ? `最高 第${p.endless.best}波` : extra ? '挑む' : `ステージ${EXTRA_UNLOCK}の後`}</small></button>
        <button className={`btn ${extra ? (p.daily.date === dateKey() && p.daily.cleared ? '' : 'hot') : 'off'}`} onClick={() => { playSe('menu'); setModal('daily'); }}><b>毎日の挑戦</b><small>{p.daily.date === dateKey() && p.daily.cleared ? '今日は済み' : extra ? '報酬あり' : `ステージ${EXTRA_UNLOCK}の後`}</small></button>
      </div>

      {pick !== null && <StageModal p={p} id={pick} onClose={() => setPick(null)} onPlay={() => { playSe('special'); onPlay(pick); }} />}
      {modal === 'help' && <Help onClose={() => setModal('')} />}
      {modal === 'settings' && <SettingsPanel settings={settings} onSettings={onSettings} onClose={() => setModal('')} onWipe={onWipe} />}
      {modal === 'endless' && (
        <Modal title="無限の海" onClose={() => setModal('')}>
          <div className="info">
            <p>波を越えるごとに敵が強くなる。どこまで耐えられるか。波を越えると船体が1つ直る。得た金は持ち帰れる。</p>
            <div className="meta"><span>最高 <b>第{p.endless.best}波</b></span><span>最高点 <b>{fmt(p.endless.score)}</b></span></div>
            {extra ? <button className="btn gold big" onClick={() => { playSe('special'); onEndless(); }}>出撃</button> : <p className="warn">ステージ{EXTRA_UNLOCK}（最初のボス）を越えると挑める。</p>}
          </div>
        </Modal>
      )}
      {modal === 'daily' && <DailyModal p={p} extra={extra} onClose={() => setModal('')} onStart={() => { playSe('special'); onDaily(); }} />}
    </div>
  );
}

function StageModal({ p, id, onClose, onPlay }: { p: Progress; id: number; onClose: () => void; onPlay: () => void }) {
  const s = applyDifficulty(stage(id), p.difficulty);
  const ids = [...new Set([...(s.objective.kind === 'boss' ? [s.objective.boss] : []), ...s.pool.map((x) => x.enemy)])];
  const st = p.stars[id] ?? 0;
  const area = AREAS.find((a) => a.id === s.area)!;
  return (
    <Modal title={<>{area.name} {id}「{s.name}」</>} onClose={onClose}>
      <div className="info">
        <div className="objective">目標：<b>{objectiveText(s.objective)}</b></div>
        <div className="enemy-list">
          {ids.map((e) => (
            <div key={e} className={`enemy-chip ${enemy(e).cls === 'boss' ? 'boss' : ''}`}>
              <EnemyIcon id={e} size={enemy(e).cls === 'boss' ? 84 : 60} />
              <div><b>{enemy(e).name}</b><small>{enemy(e).desc}</small></div>
            </div>
          ))}
        </div>
        <div className="meta">
          {s.storm && <span className="tag">嵐</span>}
          {s.ice && <span className="tag">流氷</span>}
          {s.dark && <span className="tag">暗い海</span>}
          <span>最高点 <b>{fmt(p.best[id] ?? 0)}</b></span>
          <span>星 <b className="goldc">{st ? '★'.repeat(st) + '☆'.repeat(3 - st) : 'まだ'}</b></span>
        </div>
        <button className="btn gold big" onClick={onPlay}>出撃</button>
      </div>
    </Modal>
  );
}

function DailyModal({ p, extra, onClose, onStart }: { p: Progress; extra: boolean; onClose: () => void; onStart: () => void }) {
  const date = dateKey();
  const { def, rule } = dailyDef(date, p.unlocked, p.difficulty);
  const done = p.daily.date === date && p.daily.cleared;
  return (
    <Modal title={<>毎日の挑戦 <small className="muted">{date}</small></>} onClose={onClose}>
      <div className="info">
        <div className="objective"><b>{DAILY_RULES[rule].name}</b>　{DAILY_RULES[rule].desc}</div>
        <div className="objective">目標：<b>{objectiveText(def.objective)}</b></div>
        <div className="enemy-list">{[...new Set(def.pool.map((x) => x.enemy))].map((e) => <div key={e} className="enemy-chip"><EnemyIcon id={e} size={54} /><div><b>{enemy(e).name}</b></div></div>)}</div>
        <div className="meta"><span>今日の最高 <b>{p.daily.date === date ? fmt(p.daily.best) : 0}</b></span><span>報酬 <b className="goldc">{done ? '受け取り済み' : `初めて勝つと金 ${fmt(300 + p.unlocked * 40)}`}</b></span></div>
        {extra ? <button className="btn gold big" onClick={onStart}>挑む</button> : <p className="warn">ステージ{EXTRA_UNLOCK}（最初のボス）を越えると挑める。</p>}
      </div>
    </Modal>
  );
}
