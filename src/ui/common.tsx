// 共通の部品：小窓・遊び方・設定・敵の小さな絵
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { playSe } from '../audio/sound';
import { enemy } from '../game/data';
import type { Settings } from '../game/types';
import { drawBoat, drawBoss, drawSub } from '../view/art';

export const VERSION = '2.0.0';

export function fmt(n: number): string {
  return Math.floor(n).toLocaleString('ja-JP');
}

export function Modal({ title, onClose, children, className }: { title?: ReactNode; onClose?: () => void; children: ReactNode; className?: string }) {
  return (
    <div className="modal-back" onPointerDown={(e) => { if (e.target === e.currentTarget && onClose) onClose(); }}>
      <div className={`modal ${className ?? ''}`} role="dialog" aria-modal="true">
        {(title || onClose) && (
          <div className="modal-head">
            <div className="modal-title">{title}</div>
            {onClose && <button className="x" aria-label="閉じる" onClick={() => { playSe('menu'); onClose(); }}>×</button>}
          </div>
        )}
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
}

/** 敵の小さな絵 */
export function EnemyIcon({ id, size = 64 }: { id: string; size?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const c = ref.current;
    if (!c) return;
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    c.width = size * dpr; c.height = size * 0.6 * dpr;
    const g = c.getContext('2d');
    if (!g) return;
    const d = enemy(id);
    const k = (size * dpr) / (d.w * 1.15);
    g.setTransform(k, 0, 0, k, (size * dpr) / 2, (size * 0.6 * dpr) / 2 + (d.cls === 'boat' ? 8 * k : 0));
    if (d.cls === 'boss') drawBoss(g, d, 0, 0, 1, 1, [], false);
    else if (d.cls === 'boat') drawBoat(g, d, 0, 0, 1, 0);
    else drawSub(g, d, 0, d.h * 0.15, 1, 0, false);
  }, [id, size]);
  return <canvas ref={ref} className="enemy-icon" style={{ width: size, height: size * 0.6 }} />;
}

export function Help({ onClose }: { onClose: () => void }) {
  return (
    <Modal title="遊び方" onClose={onClose} className="wide">
      <div className="help">
        <section>
          <h3>爆雷で潜水艦を沈める</h3>
          <p>海面の艦を左右に動かし、<b>左投下・右投下</b>で艦の左右から爆雷を落とします。爆雷は着水すると遅くなって沈み、敵に当たると爆発します。<b>敵が真下に来る少し前</b>に落とすのがコツ。点線が落ちる場所の目安です。</p>
        </section>
        <section>
          <h3>操作</h3>
          <p>下の ◀ ▶ を押している間動きます。海面より上を指でなぞっても動けます。海の中に触れると、触れた側へ投下。投下ボタンは押しっぱなしで連続投下。PC は ← → で移動、Z・X で投下、スペースで特殊兵装。</p>
        </section>
        <section>
          <h3>連鎖</h3>
          <p>爆発は近くの爆雷や<b>機雷を誘爆</b>させます。1回の爆発の連鎖で2隻以上沈めると点が大きく増えます。深い敵ほど点が高い。</p>
        </section>
        <section>
          <h3>敵の攻撃</h3>
          <p>魚雷は真上へ、追尾魚雷は艦を追って上がってきます。機雷は浮かんで海面に留まります。どれも<b>爆雷の爆発で消せます</b>。魚雷艇は海面を走って体当たりしてきます。</p>
        </section>
        <section>
          <h3>強化と特殊兵装</h3>
          <p>沈めた敵が落とす箱は海面に浮かびます。艦で触れると連射・大型爆雷・盾・修理・三連投下・金。ゲージが満ちたら<b>特殊</b>で投射爆雷・散布爆雷・誘導魚雷・ソナー爆発を撃てます。</p>
        </section>
        <section>
          <h3>改造と艦</h3>
          <p>ステージで得た金で船体・機関・装填・投下数・炸薬・範囲・ソナー・特殊兵装を改造。先へ進むとコルベット（速い）と巡洋艦（硬い）も買えます。改造は艦ごと。</p>
        </section>
        <section>
          <h3>海域</h3>
          <p>大陸棚・船団航路（味方の船団を守る）・嵐の海（艦が揺れ、流れがある）・氷の海（流氷が爆雷を止める）・深淵（暗い。ソナーの波で影が見える）。各海域の最後にボス。区画を1つずつ壊して沈めます。</p>
        </section>
      </div>
    </Modal>
  );
}

export function SettingsPanel({ settings, onSettings, onClose, onWipe }: { settings: Settings; onSettings: (s: Settings) => void; onClose: () => void; onWipe?: () => void }) {
  const [confirm, setConfirm] = useState(false);
  const set = (k: Partial<Settings>) => onSettings({ ...settings, ...k });
  return (
    <Modal title="設定" onClose={onClose}>
      <div className="settings">
        <label className="row"><span>BGM</span><input type="range" min={0} max={1} step={0.05} value={settings.bgm} onChange={(e) => set({ bgm: Number(e.target.value) })} /><b>{Math.round(settings.bgm * 100)}</b></label>
        <label className="row"><span>効果音</span><input type="range" min={0} max={1} step={0.05} value={settings.se} onChange={(e) => set({ se: Number(e.target.value) })} onPointerUp={() => playSe('boom')} /><b>{Math.round(settings.se * 100)}</b></label>
        <div className="row"><span>振動</span><button className={`toggle ${settings.vibrate ? 'on' : ''}`} onClick={() => set({ vibrate: !settings.vibrate })}>{settings.vibrate ? 'する' : 'しない'}</button></div>
        <div className="row"><span>上下を反転</span><button className={`toggle ${settings.flip ? 'on' : ''}`} onClick={() => set({ flip: !settings.flip })}>{settings.flip ? '反転' : 'そのまま'}</button></div>
        <p className="muted">スマホを縦に持っても画面が横になる時は、中身を回して縦に見せます。上下が逆に見える時は「上下を反転」を押してください。</p>
        <div className="row"><span>大きいボタン</span><button className={`toggle ${settings.bigButtons ? 'on' : ''}`} onClick={() => set({ bigButtons: !settings.bigButtons })}>{settings.bigButtons ? '大きく' : 'ふつう'}</button></div>
        {onWipe && (
          <div className="row danger">
            <span>データ削除</span>
            {!confirm ? <button className="btn small red" onClick={() => setConfirm(true)}>記録を消す…</button> : (
              <span className="confirm">本当に消しますか？<button className="btn small red" onClick={() => { playSe('crunch'); onWipe(); }}>消す</button><button className="btn small" onClick={() => setConfirm(false)}>やめる</button></span>
            )}
          </div>
        )}
        <p className="ver">Depthline Fleet Ver.{VERSION}</p>
      </div>
    </Modal>
  );
}
