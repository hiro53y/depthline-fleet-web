// 戦場を Canvas に描く：空と海（海域ごと）・波・海底・暗い海とソナー・落下の目安線・艦・敵・弾・演出
import { AREAS, BANDS, BAND_NAME, FLOOR, H, SHIPS, W, WL, enemy } from '../game/data';
import { foeDef, visible, type Battle } from '../game/sim';
import type { AreaId, Band, ShipId } from '../game/types';
import { drawBoat, drawBoss, drawCharge, drawConvoy, drawIce, drawItem, drawMine, drawShip, drawSub, drawTorpedo } from './art';
import type { Fx } from './effects';

export interface Viewport { s: number; ox: number; oy: number }

/** 見せたい範囲（空の一部〜海底） */
const FOCUS = { y0: 96, y1: 1250 };

export function viewportOf(cw: number, ch: number): Viewport {
  const s = Math.min(cw / W, ch / (FOCUS.y1 - FOCUS.y0));
  const ox = (cw - W * s) / 2;
  let oy = ch / 2 - ((FOCUS.y0 + FOCUS.y1) / 2) * s;
  oy = Math.min(0, Math.max(ch - H * s, oy));
  if (H * s < ch) oy = (ch - H * s) / 2;
  return { s, ox, oy };
}

export function toField(v: Viewport, sx: number, sy: number): [number, number] {
  return [(sx - v.ox) / v.s, (sy - v.oy) / v.s];
}

// ── 背景（海域ごとに1回だけ描いて取っておく） ──
const bgCache = new Map<string, HTMLCanvasElement>();

function bgFor(area: AreaId): HTMLCanvasElement | null {
  let c = bgCache.get(area);
  if (c) return c;
  if (typeof document === 'undefined') return null;
  const a = AREAS.find((x) => x.id === area)!;
  c = document.createElement('canvas');
  c.width = W; c.height = H;
  const g = c.getContext('2d');
  if (!g) return null;
  const sky = g.createLinearGradient(0, 0, 0, WL);
  sky.addColorStop(0, a.sky[0]);
  sky.addColorStop(1, a.sky[1]);
  g.fillStyle = sky;
  g.fillRect(0, 0, W, WL);
  const sea = g.createLinearGradient(0, WL, 0, H);
  sea.addColorStop(0, a.sea[0]);
  sea.addColorStop(0.45, a.sea[1]);
  sea.addColorStop(1, a.sea[2]);
  g.fillStyle = sea;
  g.fillRect(0, WL, W, H - WL);
  // 深さの帯の境（うすい線と名前）
  g.font = '600 18px system-ui, sans-serif';
  g.textBaseline = 'top';
  (Object.keys(BANDS) as Band[]).forEach((k) => {
    const [y0] = BANDS[k];
    g.fillStyle = 'rgba(255,255,255,0.05)';
    g.fillRect(0, y0 - 14, W, 1);
    g.fillStyle = 'rgba(220,240,255,0.22)';
    g.fillText(BAND_NAME[k], 8, y0 - 10);
  });
  // 海底：岩と海藻
  g.fillStyle = 'rgba(10,14,18,0.9)';
  g.beginPath();
  g.moveTo(0, H);
  for (let x = 0; x <= W; x += 24) g.lineTo(x, FLOOR + 10 + Math.sin(x * 0.05) * 10 + Math.sin(x * 0.013) * 16);
  g.lineTo(W, H);
  g.closePath();
  g.fill();
  g.strokeStyle = 'rgba(40,90,60,0.6)';
  g.lineWidth = 4;
  for (let i = 0; i < 14; i++) {
    const x = 20 + i * 52 + Math.sin(i * 7) * 12;
    g.beginPath();
    g.moveTo(x, FLOOR + 14);
    g.quadraticCurveTo(x + 10, FLOOR - 30, x - 4, FLOOR - 60 - (i % 3) * 20);
    g.stroke();
  }
  // 空の飾り
  if (area === 'abyss') {
    g.fillStyle = 'rgba(255,255,255,0.7)';
    for (let i = 0; i < 40; i++) g.fillRect((i * 97) % W, (i * 53) % (WL - 40), 2, 2);
  } else if (area !== 'storm') {
    g.fillStyle = area === 'convoy' ? 'rgba(255,220,150,0.9)' : 'rgba(255,250,220,0.9)';
    g.beginPath(); g.arc(600, 80, 34, 0, Math.PI * 2); g.fill();
  }
  bgCache.set(area, c);
  return c;
}

// 暗い海の覆い（半分の大きさで作って広げる）
let darkCanvas: HTMLCanvasElement | null = null;

function drawDark(g: CanvasRenderingContext2D, b: Battle, fx: Fx) {
  if (typeof document === 'undefined') return;
  if (!darkCanvas) { darkCanvas = document.createElement('canvas'); darkCanvas.width = W / 2; darkCanvas.height = H / 2; }
  const d = darkCanvas.getContext('2d');
  if (!d) return;
  d.setTransform(0.5, 0, 0, 0.5, 0, 0);
  d.globalCompositeOperation = 'source-over';
  d.clearRect(0, 0, W, H);
  const gr = d.createLinearGradient(0, BANDS.mid[0], 0, BANDS.deep[0] + 80);
  gr.addColorStop(0, 'rgba(0,4,10,0)');
  gr.addColorStop(1, 'rgba(0,4,10,0.94)');
  d.fillStyle = gr;
  d.fillRect(0, BANDS.mid[0], W, H);
  d.globalCompositeOperation = 'destination-out';
  const hole = (x: number, y: number, r: number, a = 1) => {
    const h = d.createRadialGradient(x, y, 0, x, y, r);
    h.addColorStop(0, `rgba(0,0,0,${a})`);
    h.addColorStop(1, 'rgba(0,0,0,0)');
    d.fillStyle = h;
    d.fillRect(x - r, y - r, r * 2, r * 2);
  };
  if (b.t < b.revealAllUntil) { d.fillStyle = 'rgba(0,0,0,0.75)'; d.fillRect(0, 0, W, H); }
  for (const r of fx.rings) {
    const k = (fx.now - r.t0) / r.dur;
    if (r.r > 300) {
      // ソナーの波：輪の通り道を明るくする
      d.lineWidth = 120;
      d.strokeStyle = `rgba(0,0,0,${0.7 * (1 - k)})`;
      d.beginPath(); d.arc(r.x, r.y, r.r * Math.sqrt(k), 0, Math.PI * 2); d.stroke();
    } else hole(r.x, r.y, r.r * 1.6, 1 - k);
  }
  for (const f of b.foes) if (visible(b, f)) hole(f.x, f.y, foeDef(f).w * 0.8, 0.85);
  for (const c of b.charges) hole(c.x, c.y, 50, 0.5);
  g.drawImage(darkCanvas, 0, 0, W, H);
}

export interface DrawOpts {
  shipId: ShipId;
  /** 落下の目安線 */
  guide: boolean;
}

export function draw(g: CanvasRenderingContext2D, cw: number, ch: number, b: Battle, fx: Fx, o: DrawOpts) {
  const v = viewportOf(cw, ch);
  const area = AREAS.find((a) => a.id === b.def.area)!;
  g.setTransform(1, 0, 0, 1, 0, 0);
  g.fillStyle = area.sea[2];
  g.fillRect(0, 0, cw, ch);
  // 空の上の余白は空の色
  g.fillStyle = area.sky[0];
  g.fillRect(0, 0, cw, Math.max(0, v.oy + WL * v.s));
  let sx = 0, sy = 0;
  if (fx.now < fx.shakeUntil) {
    const k = Math.min(1, (fx.shakeUntil - fx.now) * 3);
    sx = (Math.random() - 0.5) * fx.shakeMag * k;
    sy = (Math.random() - 0.5) * fx.shakeMag * k;
  }
  g.setTransform(v.s, 0, 0, v.s, v.ox + sx * v.s, v.oy + sy * v.s);
  const t = fx.now;
  const bg = bgFor(area.id);
  if (bg) g.drawImage(bg, 0, 0);
  // 横の余白にも海を伸ばす
  if (v.ox > 0) {
    g.fillStyle = area.sea[1];
    g.fillRect(-v.ox / v.s - 2, WL, v.ox / v.s + 2, H);
    g.fillRect(W, WL, v.ox / v.s + 2, H);
  }

  // 光の筋
  g.save();
  g.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 5; i++) {
    const x = ((i * 170 + t * 12) % (W + 200)) - 100;
    const gr = g.createLinearGradient(0, WL, 0, WL + 500);
    gr.addColorStop(0, 'rgba(160,220,255,0.08)');
    gr.addColorStop(1, 'rgba(160,220,255,0)');
    g.fillStyle = gr;
    g.beginPath(); g.moveTo(x, WL); g.lineTo(x + 50, WL); g.lineTo(x + 140, WL + 500); g.lineTo(x + 60, WL + 500); g.closePath(); g.fill();
  }
  g.restore();

  // 嵐：雲と雨
  if (b.def.storm) {
    g.fillStyle = 'rgba(30,36,44,0.6)';
    for (let i = 0; i < 6; i++) { g.beginPath(); g.ellipse(((i * 160 + t * 20) % (W + 300)) - 150, 50 + (i % 2) * 30, 140, 40, 0, 0, Math.PI * 2); g.fill(); }
    g.strokeStyle = 'rgba(200,220,240,0.35)';
    g.lineWidth = 2;
    for (let i = 0; i < 60; i++) {
      const x = (i * 53 + t * 300) % W, y = (i * 97 + t * 900) % WL;
      g.beginPath(); g.moveTo(x, y); g.lineTo(x - 8, y + 26); g.stroke();
    }
    if (Math.sin(t * 0.9) > 0.995) { g.fillStyle = 'rgba(255,255,255,0.4)'; g.fillRect(0, 0, W, H); }
  }
  if (b.def.area === 'ice') {
    g.fillStyle = 'rgba(255,255,255,0.8)';
    for (let i = 0; i < 30; i++) g.fillRect((i * 71 + Math.sin(t + i) * 20) % W, (i * 37 + t * 40) % WL, 3, 3);
  }

  // 沈む残骸
  for (const w of fx.wrecks) {
    const d = enemy(w.def);
    const k = (fx.now - w.t0) / 4;
    g.save();
    g.globalAlpha = Math.max(0, 1 - k);
    g.translate(w.x, w.y + k * 260);
    g.rotate(w.dir * k * 0.9);
    if (d.cls === 'boss') drawBoss(g, d, 0, 0, w.dir, t, w.parts ?? [], false);
    else if (d.cls === 'boat') drawBoat(g, d, 0, 0, w.dir, t);
    else drawSub(g, d, 0, 0, w.dir, t, false);
    g.restore();
  }

  // 敵
  for (const f of b.foes) {
    const d = foeDef(f);
    const seen = visible(b, f);
    const flash = (fx.hitUntil.get(f.uid) ?? 0) > fx.now;
    g.save();
    if (!seen) g.globalAlpha = 0.12;
    else if (d.stealth) g.globalAlpha = 0.75;
    if (d.cls === 'boss') drawBoss(g, d, f.x, f.y, f.dir, t, f.parts?.map((p) => p.dead) ?? [], flash);
    else if (d.cls === 'boat') drawBoat(g, d, f.x, f.y, f.dir, t);
    else drawSub(g, d, f.x, f.y, f.dir, t, flash);
    g.restore();
    // 体力（減っている時だけ）
    if (seen && d.cls !== 'boss' && f.hp < f.maxHp) {
      g.fillStyle = 'rgba(0,0,0,0.5)';
      g.fillRect(f.x - 30, f.y - d.h * 0.5 - 16, 60, 6);
      g.fillStyle = '#ff6a50';
      g.fillRect(f.x - 29, f.y - d.h * 0.5 - 15, 58 * Math.max(0, f.hp / f.maxHp), 4);
    }
  }

  // 暗い海
  if (b.def.dark) drawDark(g, b, fx);

  // 敵の弾
  for (const sh of b.shots) {
    if (sh.kind === 'mine') drawMine(g, sh.x, sh.y, t);
    else drawTorpedo(g, sh.x, sh.y, sh.vx, sh.vy, sh.kind === 'homing');
  }
  // 自分の魚雷
  for (const p of b.ptorps) drawTorpedo(g, p.x, p.y, p.vx, p.vy, false);
  // 爆雷
  const big = b.t < b.ship.bigUntil;
  for (const c of b.charges) drawCharge(g, c.x, c.y, t, c.kind, big && c.kind === 'charge');
  // 強化
  for (const it of b.items) drawItem(g, it.kind, it.x, it.y, t);

  // 水柱（爆発・着水）
  for (const c of fx.columns) {
    const k = (fx.now - c.t0) / 0.9;
    const h = c.h * Math.sin(Math.min(1, k * 2.2) * Math.PI * 0.5) * (1 - k * 0.6);
    g.fillStyle = `rgba(235,248,255,${0.85 * (1 - k)})`;
    g.beginPath();
    g.moveTo(c.x - c.w, WL);
    g.quadraticCurveTo(c.x - c.w * 0.3, WL - h * 0.5, c.x, WL - h);
    g.quadraticCurveTo(c.x + c.w * 0.3, WL - h * 0.5, c.x + c.w, WL);
    g.closePath();
    g.fill();
  }

  // 海面の波
  g.fillStyle = 'rgba(255,255,255,0.18)';
  g.beginPath();
  g.moveTo(-200, WL + 12);
  const amp = b.def.storm ? 9 : 4;
  for (let x = -200; x <= W + 200; x += 16) g.lineTo(x, WL + Math.sin(x * 0.03 + t * 2.4) * amp + Math.sin(x * 0.011 - t) * amp * 0.6);
  g.lineTo(W + 200, WL + 12);
  g.closePath();
  g.fill();

  // 流氷・船団
  b.ice.forEach((ic) => { if (ic.hp > 0) drawIce(g, ic.x, ic.y, ic.w, ic.id); });
  for (const c of b.convoy) if (c.state === 'sail' && c.x > -100 && c.x < W + 100) drawConvoy(g, c.x, WL - 6, t, c.hp);

  // 落下の目安線
  const ship = b.ship;
  const shx = ship.x + ship.sway;
  if (o.guide && b.phase === 'fight') {
    for (const side of [-1, 1]) {
      const x = shx + side * (b.stats.half - 8) + side * 14;
      const ready = (side === -1 ? ship.cool.L : ship.cool.R) <= 0;
      const gr = g.createLinearGradient(0, WL, 0, WL + 520);
      gr.addColorStop(0, ready ? 'rgba(255,230,120,0.5)' : 'rgba(255,255,255,0.15)');
      gr.addColorStop(1, 'rgba(255,230,120,0)');
      g.strokeStyle = gr;
      g.lineWidth = 3;
      g.setLineDash([10, 12]);
      g.beginPath(); g.moveTo(x, WL + 8); g.lineTo(x + b.def.current * 2, WL + 520); g.stroke();
      g.setLineDash([]);
    }
  }

  // 艦
  if (b.phase !== 'lost' || fx.now % 0.2 < 0.1) {
    const hurt = Math.max(0, 1 - (fx.now - fx.hurtAt) / 0.4) * 0.5;
    const blink = ship.inv > 0 && Math.floor(fx.now * 12) % 2 === 0;
    g.save();
    if (blink) g.globalAlpha = 0.5;
    drawShip(g, o.shipId, SHIPS[o.shipId].color, shx, WL - 4, t, b.stats.half, hurt);
    g.restore();
    if (ship.shield > 0) {
      g.strokeStyle = `rgba(127,208,255,${0.5 + 0.2 * Math.sin(t * 6)})`;
      g.lineWidth = 4;
      g.beginPath(); g.ellipse(shx, WL - 26, b.stats.half + 26, 54, 0, Math.PI, 0); g.stroke();
    }
    // 煙（船体が減るほど）
    const dmg = 1 - ship.hp / ship.maxHp;
    if (dmg > 0.3 && Math.random() < dmg * 0.6) fx.particles.push({ x: shx + (Math.random() - 0.5) * 40, y: WL - 40, vx: -10 + Math.random() * 20, vy: -40, t0: fx.now, dur: 1.4, color: 'rgba(60,60,60,0.5)', r: 8 + Math.random() * 8, g: -10, kind: 'smoke' });
  }

  // 粒・輪
  for (const p of fx.particles) {
    const k = (fx.now - p.t0) / p.dur;
    if (k < 0) continue;
    g.globalAlpha = Math.max(0, 1 - k);
    if (p.kind === 'bubble') {
      g.strokeStyle = p.color;
      g.lineWidth = 1.5;
      g.beginPath(); g.arc(p.x, p.y, p.r, 0, Math.PI * 2); g.stroke();
    } else {
      g.fillStyle = p.color;
      g.beginPath(); g.arc(p.x, p.y, p.r * (p.kind === 'smoke' ? 1 + k : 1 - k * 0.5), 0, Math.PI * 2); g.fill();
    }
  }
  g.globalAlpha = 1;
  for (const r of fx.rings) {
    const k = (fx.now - r.t0) / r.dur;
    g.globalAlpha = Math.max(0, 1 - k);
    g.strokeStyle = r.color;
    g.lineWidth = r.w * (1 - k) + 1;
    g.beginPath(); g.arc(r.x, r.y, r.r * Math.sqrt(k), 0, Math.PI * 2); g.stroke();
  }
  g.globalAlpha = 1;

  // 数字
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.lineJoin = 'round';
  for (const tx of fx.texts) {
    const k = (fx.now - tx.t0) / tx.dur;
    const pop = k < 0.12 ? 0.6 + (k / 0.12) * 0.6 : 1.2 - Math.min(0.2, (k - 0.12));
    g.globalAlpha = k > 0.7 ? Math.max(0, 1 - (k - 0.7) / 0.3) : 1;
    g.font = `900 ${Math.round(tx.size * pop)}px system-ui, sans-serif`;
    const y = tx.y - 50 * Math.sqrt(k);
    g.lineWidth = 6;
    g.strokeStyle = 'rgba(0,10,20,0.85)';
    g.strokeText(tx.text, tx.x, y);
    g.fillStyle = tx.color;
    g.fillText(tx.text, tx.x, y);
  }
  g.globalAlpha = 1;

  // ここからは画面の大きさ
  g.setTransform(1, 0, 0, 1, 0, 0);
  if (fx.now < fx.flashUntil) {
    g.globalAlpha = Math.min(0.45, (fx.flashUntil - fx.now) * 2.5);
    g.fillStyle = fx.flashColor;
    g.fillRect(0, 0, cw, ch);
    g.globalAlpha = 1;
  }
  for (const bn of fx.banners) {
    const k = (fx.now - bn.t0) / bn.dur;
    const inK = Math.min(1, k / 0.12), outK = k > 0.8 ? (k - 0.8) / 0.2 : 0;
    const fs = Math.max(20, Math.round(Math.min(cw * 0.075, 48)));
    const bh = fs * (bn.sub ? 2.4 : 1.8);
    const y = ch * 0.34 - bh / 2;
    g.globalAlpha = inK * (1 - outK);
    const gr = g.createLinearGradient(0, 0, cw, 0);
    gr.addColorStop(0, 'rgba(0,0,0,0)'); gr.addColorStop(0.15, 'rgba(4,12,22,0.86)'); gr.addColorStop(0.85, 'rgba(4,12,22,0.86)'); gr.addColorStop(1, 'rgba(0,0,0,0)');
    g.fillStyle = gr;
    g.fillRect(0, y, cw, bh);
    g.fillStyle = bn.color;
    g.fillRect(0, y, cw, 2); g.fillRect(0, y + bh - 2, cw, 2);
    g.font = `900 ${fs}px system-ui, sans-serif`;
    g.textAlign = 'center';
    g.textBaseline = 'middle';
    g.lineWidth = 6;
    g.strokeStyle = 'rgba(0,0,0,0.85)';
    const ty = y + (bn.sub ? bh * 0.38 : bh / 2);
    g.strokeText(bn.title, cw / 2 + (1 - inK) * -cw * 0.3, ty);
    g.fillStyle = bn.color;
    g.fillText(bn.title, cw / 2 + (1 - inK) * -cw * 0.3, ty);
    if (bn.sub) {
      g.font = `700 ${Math.round(fs * 0.5)}px system-ui, sans-serif`;
      g.fillStyle = '#e8f4ff';
      g.fillText(bn.sub, cw / 2, y + bh * 0.76);
    }
    g.globalAlpha = 1;
  }
}
