// 演出の状態：合戦の出来事（SimEvent）を、爆発・水柱・泡・沈む艦・数字・帯・揺れ・効果音に直す
import { playSe } from '../audio/sound';
import { WL, enemy } from '../game/data';
import type { Battle, Foe, SimEvent } from '../game/sim';
import { foeDef } from '../game/sim';
import type { ItemKind } from '../game/types';

export interface Particle { x: number; y: number; vx: number; vy: number; t0: number; dur: number; color: string; r: number; g: number; kind: 'bubble' | 'spark' | 'debris' | 'spray' | 'smoke' }
export interface Ring { x: number; y: number; r: number; t0: number; dur: number; color: string; w: number }
export interface Column { x: number; t0: number; h: number; w: number }
export interface FloatText { text: string; x: number; y: number; t0: number; dur: number; color: string; size: number }
export interface Banner { title: string; sub?: string; color: string; t0: number; dur: number }
export interface Wreck { def: string; x: number; y: number; dir: number; t0: number; parts: boolean[] | null }

export interface Fx {
  now: number;
  particles: Particle[];
  rings: Ring[];
  columns: Column[];
  texts: FloatText[];
  banners: Banner[];
  wrecks: Wreck[];
  flashUntil: number;
  flashColor: string;
  freeze: number;
  shakeUntil: number;
  shakeMag: number;
  /** 敵の白い点滅の終わり */
  hitUntil: Map<number, number>;
  /** 最後に見えた敵（消えた後の演出用） */
  last: Map<number, Foe>;
  /** 艦が被弾した時刻（煙） */
  hurtAt: number;
  /** 連鎖の表示 */
  chain: { n: number; t0: number };
  vibrate: boolean;
}

export function newFx(): Fx {
  return {
    now: 0, particles: [], rings: [], columns: [], texts: [], banners: [], wrecks: [], flashUntil: 0, flashColor: '#fff', freeze: 0,
    shakeUntil: 0, shakeMag: 0, hitUntil: new Map(), last: new Map(), hurtAt: -9, chain: { n: 0, t0: -9 }, vibrate: true,
  };
}

const lastSe = new Map<string, number>();
function se(name: string, gapMs = 60) {
  const t = performance.now();
  if ((lastSe.get(name) ?? -1e9) + gapMs > t) return;
  lastSe.set(name, t);
  playSe(name);
}

function buzz(fx: Fx, ms: number | number[]) {
  if (!fx.vibrate) return;
  const nav = navigator as Navigator & { vibrate?: (p: number | number[]) => boolean; userActivation?: { hasBeenActive: boolean } };
  // 画面に触れる前の振動はブラウザに止められるので呼ばない
  if (nav.userActivation && !nav.userActivation.hasBeenActive) return;
  try { nav.vibrate?.(ms); } catch { /* 振動できない端末 */ }
}

export function shake(fx: Fx, mag: number, dur: number) {
  fx.shakeMag = Math.max(fx.now < fx.shakeUntil ? fx.shakeMag : 0, mag);
  fx.shakeUntil = Math.max(fx.shakeUntil, fx.now + dur);
}

export function text(fx: Fx, s: string, x: number, y: number, color = '#fff', size = 30, dur = 1) {
  if (fx.texts.length > 60) fx.texts.shift();
  fx.texts.push({ text: s, x, y, t0: fx.now, dur, color, size });
}

export function banner(fx: Fx, title: string, color: string, sub?: string, dur = 2) {
  fx.banners = fx.banners.filter((b) => fx.now - b.t0 < b.dur * 0.6);
  fx.banners.push({ title, sub, color, t0: fx.now, dur });
}

function bubbles(fx: Fx, x: number, y: number, n: number, spread = 30) {
  for (let i = 0; i < n; i++) {
    fx.particles.push({ x: x + (Math.random() - 0.5) * spread, y: y + (Math.random() - 0.5) * spread, vx: (Math.random() - 0.5) * 30, vy: -40 - Math.random() * 80, t0: fx.now, dur: 1 + Math.random() * 1.6, color: 'rgba(220,245,255,0.75)', r: 2 + Math.random() * 5, g: -20, kind: 'bubble' });
  }
}

function burst(fx: Fx, x: number, y: number, n: number, color: string, spd: number, r: number, kind: Particle['kind'] = 'spark', g = 0) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2;
    const v = spd * (0.3 + Math.random() * 0.9);
    fx.particles.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, t0: fx.now, dur: 0.4 + Math.random() * 0.5, color, r: r * (0.5 + Math.random()), g, kind });
  }
}

const ITEM_NAME: Record<ItemKind, string> = { rapid: '連射', big: '大型爆雷', shield: '盾', repair: '修理', triple: '三連投下', gold: '金' };
const ITEM_COLOR: Record<ItemKind, string> = { rapid: '#ffd23f', big: '#ff8a4a', shield: '#7fd0ff', repair: '#7dea8c', triple: '#c58cff', gold: '#ffe08a' };

export function consume(fx: Fx, events: SimEvent[], b: Battle) {
  for (const f of b.foes) fx.last.set(f.uid, f);
  for (const ev of events) {
    switch (ev.k) {
      case 'spawn':
        if (ev.boss) {
          const f = b.foes.find((x) => x.uid === ev.uid);
          banner(fx, '警告：大型艦接近', '#ff6050', f ? foeDef(f).name : undefined, 2.6);
          shake(fx, 10, 1.2);
          se('alarm', 0);
          buzz(fx, [80, 60, 80]);
        }
        break;
      case 'drop':
        se('drop', 50);
        break;
      case 'splash':
        fx.columns.push({ x: ev.x, t0: fx.now, h: ev.big ? 46 : 26, w: ev.big ? 22 : 14 });
        for (let i = 0; i < (ev.big ? 8 : 4); i++) fx.particles.push({ x: ev.x, y: WL, vx: (Math.random() - 0.5) * 140, vy: -120 - Math.random() * 160, t0: fx.now, dur: 0.6, color: 'rgba(230,248,255,0.9)', r: 3 + Math.random() * 3, g: 600, kind: 'spray' });
        se('splash', 60);
        break;
      case 'boom': {
        const deep = ev.y > WL + 40;
        fx.rings.push({ x: ev.x, y: ev.y, r: ev.r * 1.25, t0: fx.now, dur: 0.55, color: deep ? 'rgba(200,240,255,0.9)' : 'rgba(255,230,180,0.9)', w: 10 });
        fx.rings.push({ x: ev.x, y: ev.y, r: ev.r * 0.7, t0: fx.now, dur: 0.3, color: 'rgba(255,240,200,1)', w: 22 });
        bubbles(fx, ev.x, ev.y, deep ? 18 : 6, ev.r * 0.8);
        burst(fx, ev.x, ev.y, 10, '#fff2c8', 260, 4);
        if (!deep || ev.y < WL + 160) fx.columns.push({ x: ev.x, t0: fx.now, h: 90 + ev.r * 0.6, w: 30 + ev.r * 0.3 });
        shake(fx, ev.big ? 10 : 4, 0.25);
        se(ev.chain > 0 && (b.chainKills[ev.chain] ?? 0) > 1 ? 'boom2' : 'boom', 45);
        break;
      }
      case 'hit':
        fx.hitUntil.set(ev.uid, fx.now + 0.1);
        break;
      case 'part': {
        const f = b.foes.find((x) => x.uid === ev.uid) ?? fx.last.get(ev.uid);
        if (f) {
          const p = enemy(f.def).parts![ev.part];
          text(fx, `${p.name} 破壊！`, f.x + p.dx * f.dir, f.y - 70, '#ffd23f', 34, 1.4);
          burst(fx, f.x + p.dx * f.dir, f.y + p.dy, 30, '#ffb04a', 320, 6, 'debris', 200);
          bubbles(fx, f.x + p.dx * f.dir, f.y, 30, 80);
          fx.freeze = Math.max(fx.freeze, 0.12);
          shake(fx, 14, 0.5);
          se('crunch', 0);
          buzz(fx, 60);
        }
        break;
      }
      case 'kill': {
        const f = fx.last.get(ev.uid);
        fx.wrecks.push({ def: ev.def, x: ev.x, y: ev.y, dir: f?.dir ?? 1, t0: fx.now, parts: f?.parts ? f.parts.map((q) => q.dead) : null });
        if (fx.wrecks.length > 30) fx.wrecks.shift();
        bubbles(fx, ev.x, ev.y, 24, 60);
        burst(fx, ev.x, ev.y, 14, '#c8d0d8', 200, 5, 'debris', 120);
        const boss = enemy(ev.def).cls === 'boss';
        text(fx, `+${ev.score}`, ev.x, ev.y - 40, ev.chain >= 2 ? '#ffd23f' : '#ffffff', ev.chain >= 2 ? 34 : 28, 1.1);
        if (boss) {
          banner(fx, '撃沈！', '#ffd23f', enemy(ev.def).name, 2.4);
          fx.flashUntil = fx.now + 0.35; fx.flashColor = '#ffffff';
          fx.freeze = Math.max(fx.freeze, 0.5);
          shake(fx, 24, 1.4);
          se('bigboom', 0);
          buzz(fx, [120, 60, 200]);
        } else {
          se('sink', 70);
          fx.freeze = Math.max(fx.freeze, 0.03);
        }
        break;
      }
      case 'chain':
        fx.chain = { n: ev.n, t0: fx.now };
        text(fx, `${ev.n} 連鎖！`, ev.x, ev.y - 90, '#ff9a3a', 30 + Math.min(20, ev.n * 4), 1.2);
        if (ev.n >= 3) { fx.freeze = Math.max(fx.freeze, 0.08); fx.flashUntil = fx.now + 0.12; fx.flashColor = '#ffd23f'; }
        se('chain', 0);
        break;
      case 'fire':
        se(ev.kind === 'mine' ? 'mine' : 'launch', 120);
        break;
      case 'hurt':
        if (ev.shield) { text(fx, '防いだ！', b.ship.x, WL - 90, '#7fd0ff', 28); fx.rings.push({ x: b.ship.x, y: WL - 20, r: 110, t0: fx.now, dur: 0.4, color: '#7fd0ff', w: 8 }); se('shield', 0); break; }
        fx.hurtAt = fx.now;
        fx.flashUntil = fx.now + 0.2; fx.flashColor = '#ff2a20';
        shake(fx, 16, 0.5);
        burst(fx, ev.x, WL - 10, 18, '#ffb04a', 260, 6, 'debris', 500);
        text(fx, `被弾 -${ev.dmg}`, b.ship.x, WL - 100, '#ff6a50', 30);
        se('hurt', 0);
        buzz(fx, 140);
        break;
      case 'item': break;
      case 'pick':
        text(fx, ITEM_NAME[ev.kind], b.ship.x, WL - 110, ITEM_COLOR[ev.kind], 32, 1.2);
        fx.rings.push({ x: b.ship.x, y: WL - 20, r: 120, t0: fx.now, dur: 0.5, color: ITEM_COLOR[ev.kind], w: 6 });
        se('pickup', 0);
        break;
      case 'sonar':
        fx.rings.push({ x: ev.x, y: WL + 10, r: Math.min(ev.r, 1400), t0: fx.now, dur: ev.r > 1500 ? 1.2 : 1.6, color: 'rgba(120,255,170,0.55)', w: 3 });
        se('ping', 300);
        break;
      case 'convoy':
        if (ev.s === 'sunk') { banner(fx, '味方の船が沈んだ', '#ff8a6a', undefined, 1.8); se('hurt', 0); }
        else if (ev.s === 'done') { text(fx, '船団 通過！', 600, WL - 80, '#7dea8c', 30); se('pickup', 0); }
        else se('bump', 100);
        break;
      case 'phase':
        banner(fx, ev.phase === 2 ? '敵艦 最後の抵抗！' : '敵艦 損傷 — 攻撃が激しくなる', '#ff6050', undefined, 1.8);
        fx.flashUntil = fx.now + 0.3; fx.flashColor = '#ffffff';
        shake(fx, 14, 0.6);
        se('alarm', 0);
        break;
      case 'special':
        fx.flashUntil = fx.now + 0.15; fx.flashColor = '#bff0ff';
        fx.freeze = Math.max(fx.freeze, 0.12);
        se('special', 0);
        buzz(fx, 50);
        break;
      case 'ice':
        burst(fx, ev.x, ev.y, 20, '#e8f8ff', 240, 6, 'debris', 300);
        se('crunch', 80);
        break;
      case 'wave':
        banner(fx, `第${ev.n}波`, '#9fe7ff', '敵が強くなる', 2);
        se('alarm', 0);
        break;
      case 'end':
        if (ev.win) { banner(fx, '任務完了', '#ffd23f', undefined, 2.6); se('clear', 0); }
        else { banner(fx, '撃沈された…', '#ff6a50', undefined, 2.6); shake(fx, 20, 1); se('lose', 0); buzz(fx, [200, 80, 300]); }
        break;
    }
  }
  if (fx.last.size > 200) {
    const live = new Set(b.foes.map((f) => f.uid));
    for (const k of fx.last.keys()) if (!live.has(k)) fx.last.delete(k);
  }
}

export function tickFx(fx: Fx, dt: number) {
  fx.now += dt;
  const n = fx.now;
  for (const p of fx.particles) {
    p.x += p.vx * dt;
    p.y += p.vy * dt;
    p.vy += p.g * dt;
    p.vx *= 1 - Math.min(1, dt * 1.5);
    if (p.kind === 'bubble' && p.y < WL + 2) p.t0 = -999;
  }
  fx.particles = fx.particles.filter((p) => n - p.t0 < p.dur);
  if (fx.particles.length > 700) fx.particles.splice(0, fx.particles.length - 700);
  fx.rings = fx.rings.filter((r) => n - r.t0 < r.dur);
  fx.columns = fx.columns.filter((c) => n - c.t0 < 0.9);
  fx.texts = fx.texts.filter((t) => n - t.t0 < t.dur);
  fx.banners = fx.banners.filter((b) => n - b.t0 < b.dur);
  fx.wrecks = fx.wrecks.filter((w) => n - w.t0 < 4);
}
