// Canvas で描く絵：艦・潜水艦・魚雷艇・ボス・爆雷・魚雷・機雷・強化・船団・流氷（画像は使わない）
import type { EnemyDef, ItemKind, ShipId } from '../game/types';

type G = CanvasRenderingContext2D;

function shade(hex: string, k: number): string {
  const n = parseInt(hex.slice(1), 16);
  const f = (v: number) => Math.max(0, Math.min(255, Math.round(k >= 0 ? v + (255 - v) * k : v * (1 + k))));
  return `rgb(${f((n >> 16) & 255)},${f((n >> 8) & 255)},${f(n & 255)})`;
}

function rr(g: G, x: number, y: number, w: number, h: number, r: number) {
  g.beginPath();
  g.moveTo(x + r, y);
  g.arcTo(x + w, y, x + w, y + h, r);
  g.arcTo(x + w, y + h, x, y + h, r);
  g.arcTo(x, y + h, x, y, r);
  g.arcTo(x, y, x + w, y, r);
  g.closePath();
}

/** 自艦（横向き。x,y は喫水線の真ん中） */
export function drawShip(g: G, id: ShipId, color: string, x: number, y: number, t: number, half: number, hurt: number) {
  const L = half * 2;
  g.save();
  g.translate(x, y + Math.sin(t * 2.2) * 2);
  g.rotate(Math.sin(t * 1.6) * 0.018);
  // 船体
  g.beginPath();
  g.moveTo(-L / 2 - 6, -14);
  g.lineTo(L / 2 + 14, -16);
  g.lineTo(L / 2 - 6, 10);
  g.lineTo(-L / 2 + 10, 10);
  g.closePath();
  const hg = g.createLinearGradient(0, -16, 0, 10);
  hg.addColorStop(0, shade(color, -0.1));
  hg.addColorStop(1, shade(color, -0.55));
  g.fillStyle = hg;
  g.fill();
  // 喫水の赤
  g.fillStyle = '#8a2a24';
  g.beginPath();
  g.moveTo(-L / 2 + 6, 4);
  g.lineTo(L / 2 - 2, 4);
  g.lineTo(L / 2 - 6, 10);
  g.lineTo(-L / 2 + 10, 10);
  g.closePath();
  g.fill();
  // 甲板の上
  g.fillStyle = shade(color, 0.15);
  const heavy = id === 'cruiser';
  rr(g, -L * 0.18, -34, L * 0.3, 20, 3); g.fill();
  rr(g, -L * 0.08, -50, L * 0.14, 18, 3); g.fill();
  g.fillStyle = shade(color, -0.3);
  rr(g, -L * 0.05, -46, L * 0.08, 5, 2); g.fill();
  // 煙突
  g.fillStyle = shade(color, -0.2);
  rr(g, L * 0.14, -40, 14, 26, 3); g.fill();
  g.fillStyle = '#222';
  g.fillRect(L * 0.14, -40, 14, 4);
  if (heavy) { rr(g, L * 0.24, -36, 12, 22, 3); g.fillStyle = shade(color, -0.2); g.fill(); }
  // 砲塔
  g.fillStyle = shade(color, -0.15);
  for (const gx of id === 'corvette' ? [L * 0.36] : [L * 0.36, -L * 0.34]) {
    rr(g, gx - 11, -24, 22, 10, 4); g.fill();
    g.fillRect(gx + (gx > 0 ? 8 : -26), -21, 18, 3);
  }
  // マスト
  g.strokeStyle = shade(color, -0.4);
  g.lineWidth = 2;
  g.beginPath(); g.moveTo(0, -50); g.lineTo(0, -78); g.moveTo(-10, -70); g.lineTo(10, -70); g.stroke();
  // 爆雷の棚（両舷）
  g.fillStyle = '#3a3a30';
  for (const sx of [-1, 1]) { rr(g, sx * (half - 22) - 7, -22, 14, 10, 2); g.fill(); }
  // 舷窓
  g.fillStyle = 'rgba(255,240,180,0.7)';
  for (let i = -3; i <= 3; i++) g.fillRect(i * L * 0.11 - 2, -9, 3, 3);
  // 被弾の赤
  if (hurt > 0) {
    g.globalAlpha = hurt;
    g.fillStyle = '#ff3020';
    g.fillRect(-L / 2, -50, L, 60);
  }
  g.restore();
}

/** 潜水艦（dir 1 は右向き） */
export function drawSub(g: G, d: EnemyDef, x: number, y: number, dir: number, t: number, flash: boolean) {
  const w = d.w, h = d.h;
  g.save();
  g.translate(x, y);
  g.scale(dir, 1);
  const body = g.createLinearGradient(0, -h / 2, 0, h / 2);
  body.addColorStop(0, shade(d.color, 0.35));
  body.addColorStop(0.45, d.color);
  body.addColorStop(1, shade(d.color, -0.5));
  // 船体（先が丸く、後ろがすぼまる）
  g.beginPath();
  g.moveTo(w * 0.5, 0);
  g.bezierCurveTo(w * 0.5, -h * 0.55, w * 0.28, -h * 0.5, 0, -h * 0.5);
  g.lineTo(-w * 0.32, -h * 0.42);
  g.quadraticCurveTo(-w * 0.5, -h * 0.15, -w * 0.5, 0);
  g.quadraticCurveTo(-w * 0.5, h * 0.15, -w * 0.32, h * 0.42);
  g.lineTo(0, h * 0.5);
  g.bezierCurveTo(w * 0.28, h * 0.5, w * 0.5, h * 0.55, w * 0.5, 0);
  g.closePath();
  g.fillStyle = body;
  g.fill();
  // 司令塔
  g.fillStyle = shade(d.color, -0.1);
  const tw = d.id === 'scout' ? w * 0.16 : w * 0.2;
  rr(g, w * 0.02, -h * 0.5 - h * 0.45, tw, h * 0.5, 4);
  g.fill();
  g.fillStyle = shade(d.color, -0.4);
  g.fillRect(w * 0.02 + tw * 0.5, -h * 0.5 - h * 0.75, 3, h * 0.32);
  // 印（種類ごと）
  if (d.id === 'hunter') { g.fillStyle = '#d04040'; g.fillRect(-w * 0.2, -3, w * 0.45, 6); }
  if (d.id === 'layer') { g.fillStyle = shade(d.color, 0.2); rr(g, -w * 0.32, -h * 0.62, w * 0.26, h * 0.3, 4); g.fill(); }
  if (d.id === 'deep') { g.strokeStyle = shade(d.color, -0.35); g.lineWidth = 2; for (let i = -2; i <= 2; i++) { g.beginPath(); g.moveTo(i * w * 0.12, -h * 0.4); g.lineTo(i * w * 0.12, h * 0.4); g.stroke(); } }
  // 舷窓
  g.fillStyle = d.id === 'ghost' ? 'rgba(140,200,255,0.9)' : 'rgba(255,230,140,0.85)';
  for (let i = 0; i < 3; i++) { g.beginPath(); g.arc(w * (0.32 - i * 0.12), -h * 0.08, 2.5, 0, Math.PI * 2); g.fill(); }
  // スクリュー
  g.fillStyle = shade(d.color, -0.3);
  const s = Math.sin(t * 30) * h * 0.3;
  g.fillRect(-w * 0.53, -Math.abs(s), 5, Math.abs(s) * 2 + 2);
  // 尾びれ
  g.beginPath(); g.moveTo(-w * 0.42, 0); g.lineTo(-w * 0.52, -h * 0.4); g.lineTo(-w * 0.47, 0); g.lineTo(-w * 0.52, h * 0.4); g.closePath(); g.fill();
  if (flash) {
    g.globalCompositeOperation = 'lighter';
    g.globalAlpha = 0.7;
    g.fillStyle = '#ffffff';
    g.beginPath(); g.ellipse(0, 0, w * 0.5, h * 0.5, 0, 0, Math.PI * 2); g.fill();
  }
  g.restore();
}

/** 魚雷艇（海面） */
export function drawBoat(g: G, d: EnemyDef, x: number, y: number, dir: number, t: number) {
  g.save();
  g.translate(x, y + Math.sin(t * 6) * 1.5);
  g.scale(dir, 1);
  g.fillStyle = shade(d.color, -0.3);
  g.beginPath(); g.moveTo(d.w * 0.55, -8); g.lineTo(-d.w * 0.45, -8); g.lineTo(-d.w * 0.4, 6); g.lineTo(d.w * 0.3, 6); g.closePath(); g.fill();
  g.fillStyle = d.color;
  rr(g, -d.w * 0.2, -22, d.w * 0.32, 14, 3); g.fill();
  g.fillStyle = '#d04040'; g.fillRect(-d.w * 0.45, -6, d.w * 0.9, 3);
  // 航跡
  g.fillStyle = 'rgba(255,255,255,0.6)';
  for (let i = 0; i < 4; i++) { g.beginPath(); g.ellipse(-d.w * 0.55 - i * 14, 4, 8 - i, 3, 0, 0, Math.PI * 2); g.fill(); }
  g.restore();
}

/** ボス（区画ごとに。壊れた区画は黒く煙を吐く） */
export function drawBoss(g: G, d: EnemyDef, x: number, y: number, dir: number, t: number, dead: boolean[], flash: boolean) {
  const w = d.w, h = d.h;
  g.save();
  g.translate(x, y);
  g.scale(dir, 1);
  // 本体
  const body = g.createLinearGradient(0, -h / 2, 0, h / 2);
  body.addColorStop(0, shade(d.color, 0.3));
  body.addColorStop(0.5, d.color);
  body.addColorStop(1, shade(d.color, -0.55));
  g.fillStyle = body;
  if (d.id === 'twin') {
    for (const sy of [-26, 26]) { g.beginPath(); g.ellipse(0, sy, w * 0.5, h * 0.24, 0, 0, Math.PI * 2); g.fill(); }
    g.fillRect(-w * 0.1, -26, w * 0.2, 52);
  } else {
    g.beginPath();
    g.moveTo(w * 0.52, 0);
    g.bezierCurveTo(w * 0.52, -h * 0.5, w * 0.3, -h * 0.42, 0, -h * 0.42);
    g.lineTo(-w * 0.38, -h * 0.36);
    g.quadraticCurveTo(-w * 0.52, -h * 0.1, -w * 0.52, 0);
    g.quadraticCurveTo(-w * 0.52, h * 0.1, -w * 0.38, h * 0.36);
    g.lineTo(0, h * 0.42);
    g.bezierCurveTo(w * 0.3, h * 0.42, w * 0.52, h * 0.5, w * 0.52, 0);
    g.closePath();
    g.fill();
  }
  // 区画
  (d.parts ?? []).forEach((p, i) => {
    const px = p.dx, py = p.dy;
    if (dead[i]) {
      g.fillStyle = '#1a1a1a';
      rr(g, px - p.w / 2 + 6, py - p.h / 2 + 6, p.w - 12, p.h - 12, 10); g.fill();
      g.fillStyle = 'rgba(255,120,40,0.6)';
      for (let k = 0; k < 3; k++) { g.beginPath(); g.arc(px + (k - 1) * p.w * 0.25, py + Math.sin(t * 5 + k) * 4, 5 + Math.sin(t * 9 + k) * 2, 0, Math.PI * 2); g.fill(); }
      return;
    }
    g.fillStyle = shade(d.color, 0.12);
    rr(g, px - p.w / 2 + 8, py - p.h / 2 + 8, p.w - 16, p.h - 16, 10); g.fill();
    g.strokeStyle = shade(d.color, -0.4);
    g.lineWidth = 3;
    g.stroke();
    // 弱点の光
    const pulse = 0.5 + 0.5 * Math.sin(t * 4 + i);
    g.fillStyle = `rgba(255,${80 + pulse * 80},60,${0.7 + 0.3 * pulse})`;
    g.beginPath(); g.arc(px, py, 9 + pulse * 3, 0, Math.PI * 2); g.fill();
  });
  // 司令塔
  if (d.id !== 'twin') {
    g.fillStyle = shade(d.color, -0.1);
    rr(g, -w * 0.06, -h * 0.42 - h * 0.35, w * 0.16, h * 0.38, 6); g.fill();
  }
  if (flash) {
    g.globalCompositeOperation = 'lighter';
    g.globalAlpha = 0.45;
    g.fillStyle = '#fff';
    g.beginPath(); g.ellipse(0, 0, w * 0.52, h * 0.5, 0, 0, Math.PI * 2); g.fill();
  }
  g.restore();
}

export function drawCharge(g: G, x: number, y: number, t: number, kind: 'charge' | 'mini' | 'mortar', big: boolean) {
  const s = kind === 'mini' ? 0.6 : big ? 1.35 : 1;
  g.save();
  g.translate(x, y);
  g.rotate(Math.sin(t * 8 + x) * 0.25);
  g.scale(s, s);
  g.fillStyle = '#3a3a34';
  rr(g, -7, -9, 14, 18, 4); g.fill();
  g.fillStyle = '#c8b060';
  g.fillRect(-7, -3, 14, 3);
  g.fillStyle = Math.sin(t * 20) > 0 ? '#ff4030' : '#601810';
  g.beginPath(); g.arc(0, -9, 2.5, 0, Math.PI * 2); g.fill();
  g.restore();
}

export function drawTorpedo(g: G, x: number, y: number, vx: number, vy: number, homing: boolean) {
  g.save();
  g.translate(x, y);
  g.rotate(Math.atan2(vy, vx) + Math.PI / 2);
  g.fillStyle = homing ? '#b03030' : '#9aa4ac';
  rr(g, -5, -20, 10, 40, 5); g.fill();
  g.fillStyle = homing ? '#ffcc40' : '#e04030';
  g.beginPath(); g.arc(0, -18, 5, Math.PI, 0); g.fill();
  g.fillStyle = '#444';
  g.fillRect(-7, 16, 14, 3);
  g.restore();
}

export function drawMine(g: G, x: number, y: number, t: number) {
  g.save();
  g.translate(x, y);
  g.strokeStyle = '#2a2a2a';
  g.lineWidth = 3;
  for (let i = 0; i < 8; i++) { const a = (i / 8) * Math.PI * 2 + t * 0.3; g.beginPath(); g.moveTo(Math.cos(a) * 10, Math.sin(a) * 10); g.lineTo(Math.cos(a) * 17, Math.sin(a) * 17); g.stroke(); }
  const gr = g.createRadialGradient(-4, -4, 2, 0, 0, 13);
  gr.addColorStop(0, '#6a6a6a');
  gr.addColorStop(1, '#1a1a1a');
  g.fillStyle = gr;
  g.beginPath(); g.arc(0, 0, 13, 0, Math.PI * 2); g.fill();
  g.fillStyle = Math.sin(t * 6) > 0 ? '#ff3a2a' : '#5a1a10';
  g.beginPath(); g.arc(0, 0, 3.5, 0, Math.PI * 2); g.fill();
  g.restore();
}

export const ITEM_STYLE: Record<ItemKind, { c: string; ch: string }> = {
  rapid: { c: '#ffd23f', ch: '速' }, big: { c: '#ff8a4a', ch: '大' }, shield: { c: '#7fd0ff', ch: '盾' }, repair: { c: '#7dea8c', ch: '修' }, triple: { c: '#c58cff', ch: '三' }, gold: { c: '#ffe08a', ch: '金' },
};

export function drawItem(g: G, kind: ItemKind, x: number, y: number, t: number) {
  const st = ITEM_STYLE[kind];
  g.save();
  g.translate(x, y + Math.sin(t * 3 + x) * 3);
  g.rotate(Math.sin(t * 2 + x) * 0.15);
  g.fillStyle = 'rgba(0,0,0,0.25)';
  g.beginPath(); g.ellipse(0, 14, 20, 5, 0, 0, Math.PI * 2); g.fill();
  g.fillStyle = '#8a6a40';
  rr(g, -17, -15, 34, 30, 5); g.fill();
  g.strokeStyle = st.c;
  g.lineWidth = 3;
  g.stroke();
  g.fillStyle = st.c;
  g.font = '900 20px system-ui, sans-serif';
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.fillText(st.ch, 0, 1);
  g.restore();
}

/** 味方の輸送船 */
export function drawConvoy(g: G, x: number, y: number, t: number, hp: number) {
  g.save();
  g.translate(x, y + Math.sin(t * 2 + x * 0.01) * 2);
  g.fillStyle = '#3a5a3a';
  g.beginPath(); g.moveTo(-70, -12); g.lineTo(76, -12); g.lineTo(62, 10); g.lineTo(-60, 10); g.closePath(); g.fill();
  g.fillStyle = '#c8b890';
  for (let i = 0; i < 4; i++) { rr(g, -54 + i * 26, -32, 22, 20, 2); g.fill(); }
  g.fillStyle = '#e8e0d0';
  rr(g, 40, -40, 22, 28, 3); g.fill();
  // 体力
  for (let i = 0; i < 3; i++) { g.fillStyle = i < hp ? '#7dea8c' : 'rgba(255,255,255,0.2)'; g.fillRect(-24 + i * 18, -54, 14, 6); }
  g.restore();
}

export function drawIce(g: G, x: number, y: number, w: number, seed: number) {
  g.save();
  g.translate(x, y);
  g.fillStyle = 'rgba(232,246,255,0.95)';
  g.beginPath();
  const n = 7;
  for (let i = 0; i <= n; i++) {
    const a = i / n;
    const yy = -10 - Math.abs(Math.sin(seed + i * 1.7)) * 8;
    if (i === 0) g.moveTo(-w / 2, 0); g.lineTo(-w / 2 + a * w, yy);
  }
  g.lineTo(w / 2, 0);
  g.lineTo(w / 2 - 8, 14);
  g.lineTo(-w / 2 + 8, 14);
  g.closePath();
  g.fill();
  g.fillStyle = 'rgba(150,200,230,0.6)';
  g.fillRect(-w / 2 + 8, 6, w - 16, 8);
  g.restore();
}
