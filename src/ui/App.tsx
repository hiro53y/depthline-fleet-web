// 画面の切り替えと、進み・設定の保存
import { useCallback, useEffect, useState } from 'react';
import { playBgm, resumeBgm, setBgmVolume } from '../audio/bgm';
import { setSeVolume, unlockAudio } from '../audio/sound';
import { newProgress } from '../game/progress';
import { loadProgress, loadSettings, saveProgress, saveSettings, wipe } from '../game/save';
import type { Difficulty, Progress, Settings } from '../game/types';
import { BattleScreen, type BattleMode } from './BattleScreen';
import { applyRot, computeRot, tryLock } from '../orientation';
import { DockScreen } from './DockScreen';
import { MapScreen } from './MapScreen';
import { Title } from './Title';

type Screen = { k: 'title' } | { k: 'map' } | { k: 'dock' } | { k: 'battle'; mode: BattleMode; key: number };

export function App() {
  const [screen, setScreen] = useState<Screen>({ k: 'title' });
  const [p, setP] = useState<Progress | null>(() => loadProgress());
  const [settings, setSettings] = useState<Settings>(() => loadSettings());
  const [, setRev] = useState(0);

  useEffect(() => { setSeVolume(settings.se); setBgmVolume(settings.bgm); saveSettings(settings); }, [settings]);
  // いつも縦に：縦に固定を頼み、横長のままなら中身を回す
  useEffect(() => {
    const fit = () => applyRot(computeRot(settings.flip));
    fit();
    tryLock();
    window.addEventListener('resize', fit);
    window.screen.orientation?.addEventListener?.('change', fit);
    return () => { window.removeEventListener('resize', fit); window.screen.orientation?.removeEventListener?.('change', fit); };
  }, [settings.flip]);
  useEffect(() => {
    const on = () => { unlockAudio(); resumeBgm(); tryLock(); };
    window.addEventListener('pointerdown', on);
    window.addEventListener('keydown', on);
    return () => { window.removeEventListener('pointerdown', on); window.removeEventListener('keydown', on); };
  }, []);
  useEffect(() => { if (screen.k !== 'battle') playBgm('title'); }, [screen.k]);

  const touch = useCallback(() => {
    if (p) saveProgress(p);
    setRev((r) => r + 1);
  }, [p]);

  const start = (d: Difficulty) => {
    const np = newProgress(d, (Date.now() & 0x7fffffff) ^ 0xdee9);
    saveProgress(np);
    setP(np);
    setScreen({ k: 'map' });
  };
  const play = (mode: BattleMode) => setScreen({ k: 'battle', mode, key: Date.now() });
  const onWipe = () => { wipe(); setP(null); setScreen({ k: 'title' }); };

  if (screen.k === 'title' || !p) {
    return <Title hasSave={!!p} settings={settings} onSettings={setSettings} onNew={start} onContinue={() => p && setScreen({ k: 'map' })} onWipe={onWipe} />;
  }
  if (screen.k === 'map') {
    return (
      <MapScreen
        p={p} settings={settings} onSettings={setSettings}
        onPlay={(id) => play({ kind: 'stage', id })}
        onEndless={() => play({ kind: 'endless' })}
        onDaily={() => play({ kind: 'daily' })}
        onDock={() => setScreen({ k: 'dock' })}
        onTitle={() => setScreen({ k: 'title' })}
        onWipe={onWipe}
      />
    );
  }
  if (screen.k === 'dock') return <DockScreen p={p} onChange={touch} onBack={() => setScreen({ k: 'map' })} />;
  return (
    <BattleScreen
      key={screen.key} p={p} mode={screen.mode} settings={settings} onSettings={setSettings} onChange={touch}
      onMap={() => setScreen({ k: 'map' })} onDock={() => setScreen({ k: 'dock' })} onPlay={play}
    />
  );
}
