// 効果音（Web Audio で合成。音声ファイルは使わない）
type Ctor = typeof AudioContext;

let ctx: AudioContext | null = null;
let volume = 0.7;

export function setSeVolume(v: number) {
  volume = Math.max(0, Math.min(1, v));
}

function audio(): AudioContext | null {
  if (volume <= 0) return null;
  if (ctx) return ctx;
  try {
    const C: Ctor | undefined = window.AudioContext ?? (window as unknown as { webkitAudioContext?: Ctor }).webkitAudioContext;
    if (!C) return null;
    ctx = new C();
  } catch {
    return null;
  }
  return ctx;
}

/** 画面に触れた時に音を鳴らせる状態にする（ブラウザの決まり） */
export function unlockAudio() {
  const c = audio();
  if (c && c.state === 'suspended') c.resume().catch(() => undefined);
}

function env(c: AudioContext, start: number, peak: number, dur: number): GainNode {
  const gain = c.createGain();
  gain.gain.setValueAtTime(0.0001, start);
  gain.gain.exponentialRampToValueAtTime(Math.max(0.0002, peak * volume), start + Math.min(0.02, dur / 4));
  gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
  gain.connect(c.destination);
  return gain;
}

function tone(c: AudioContext, type: OscillatorType, f0: number, f1: number, dur: number, peak: number, delay = 0) {
  const start = c.currentTime + delay;
  const out = env(c, start, peak, dur);
  const osc = c.createOscillator();
  osc.type = type;
  osc.frequency.setValueAtTime(f0, start);
  osc.frequency.exponentialRampToValueAtTime(Math.max(20, f1), start + dur);
  osc.connect(out);
  osc.start(start);
  osc.stop(start + dur + 0.02);
}

function noise(c: AudioContext, dur: number, peak: number, filter: BiquadFilterType, freq: number, delay = 0) {
  const start = c.currentTime + delay;
  const out = env(c, start, peak, dur);
  const buffer = c.createBuffer(1, Math.max(1, Math.floor(c.sampleRate * dur)), c.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
  const src = c.createBufferSource();
  src.buffer = buffer;
  const f = c.createBiquadFilter();
  f.type = filter;
  f.frequency.setValueAtTime(freq, start);
  src.connect(f);
  f.connect(out);
  src.start(start);
  src.stop(start + dur + 0.02);
}

const SOUNDS: Record<string, (c: AudioContext) => void> = {
  hit: (c) => { tone(c, 'sawtooth', 900, 200, 0.14, 0.18); noise(c, 0.12, 0.16, 'highpass', 1400); },
  crit: (c) => { tone(c, 'sawtooth', 1400, 180, 0.22, 0.22); noise(c, 0.2, 0.22, 'highpass', 900); tone(c, 'square', 1800, 1200, 0.1, 0.08, 0.05); },
  miss: (c) => noise(c, 0.12, 0.08, 'bandpass', 2400),
  swing: (c) => noise(c, 0.1, 0.07, 'bandpass', 3000),
  hurt: (c) => { tone(c, 'square', 300, 90, 0.16, 0.14); noise(c, 0.1, 0.1, 'lowpass', 800); },
  pickup: (c) => { tone(c, 'triangle', 660, 990, 0.08, 0.14); tone(c, 'triangle', 990, 1320, 0.08, 0.12, 0.06); },
  coin: (c) => { tone(c, 'square', 1320, 1320, 0.06, 0.08); tone(c, 'square', 1760, 1760, 0.12, 0.08, 0.06); },
  eat: (c) => { noise(c, 0.08, 0.1, 'lowpass', 600); noise(c, 0.08, 0.1, 'lowpass', 600, 0.12); },
  stairs: (c) => { [523, 440, 349, 262].forEach((f, i) => tone(c, 'triangle', f, f, 0.12, 0.12, i * 0.08)); },
  lvup: (c) => { [523, 659, 784, 1047].forEach((f, i) => tone(c, 'square', f, f, 0.12, 0.1, i * 0.08)); },
  magic: (c) => { tone(c, 'sine', 400, 1600, 0.25, 0.14); tone(c, 'triangle', 800, 2400, 0.2, 0.06, 0.04); },
  fire: (c) => { noise(c, 0.4, 0.2, 'lowpass', 900); tone(c, 'sawtooth', 160, 60, 0.35, 0.08); },
  thunder: (c) => { noise(c, 0.5, 0.3, 'lowpass', 1600); tone(c, 'sawtooth', 120, 40, 0.5, 0.12); },
  boom: (c) => { noise(c, 0.6, 0.35, 'lowpass', 500); tone(c, 'sine', 120, 30, 0.6, 0.25); },
  trap: (c) => { tone(c, 'square', 220, 220, 0.08, 0.12); tone(c, 'square', 180, 180, 0.12, 0.12, 0.08); },
  throw: (c) => noise(c, 0.18, 0.08, 'bandpass', 1600),
  gun: (c) => { noise(c, 0.3, 0.32, 'lowpass', 1800); tone(c, 'square', 220, 60, 0.18, 0.14); },
  arrow: (c) => { noise(c, 0.14, 0.1, 'highpass', 3000); tone(c, 'triangle', 1200, 600, 0.1, 0.05); },
  equip: (c) => { noise(c, 0.06, 0.12, 'bandpass', 2000); tone(c, 'square', 700, 700, 0.06, 0.06, 0.04); },
  break: (c) => { noise(c, 0.25, 0.22, 'highpass', 2500); },
  death: (c) => { [392, 349, 311, 262].forEach((f, i) => tone(c, 'triangle', f, f * 0.98, 0.3, 0.14, i * 0.22)); },
  revive: (c) => { [262, 392, 523, 784].forEach((f, i) => tone(c, 'sine', f, f, 0.2, 0.12, i * 0.1)); },
  house: (c) => { [880, 660, 880, 660].forEach((f, i) => tone(c, 'square', f, f, 0.08, 0.1, i * 0.09)); },
  roar: (c) => { tone(c, 'sawtooth', 110, 60, 0.6, 0.2); noise(c, 0.5, 0.15, 'lowpass', 400); },
  clear: (c) => { [523, 659, 784, 1047, 1319].forEach((f, i) => tone(c, 'triangle', f, f, 0.25, 0.12, i * 0.12)); },
  bump: (c) => { tone(c, 'sine', 160, 60, 0.15, 0.2); },
  dig: (c) => { noise(c, 0.2, 0.18, 'lowpass', 700); },
  slash: (c) => { noise(c, 0.3, 0.2, 'highpass', 2000); tone(c, 'sawtooth', 2000, 300, 0.3, 0.08); },
  menu: (c) => tone(c, 'triangle', 880, 880, 0.05, 0.06),
  // ── 海戦 ──
  drop: (c) => { tone(c, 'square', 420, 260, 0.06, 0.06); noise(c, 0.05, 0.05, 'bandpass', 1800); },
  splash: (c) => { noise(c, 0.22, 0.12, 'bandpass', 1400); noise(c, 0.3, 0.06, 'lowpass', 600, 0.04); },
  boom2: (c) => { noise(c, 0.7, 0.34, 'lowpass', 420); tone(c, 'sine', 140, 28, 0.7, 0.3); tone(c, 'triangle', 600, 900, 0.12, 0.06, 0.05); },
  bigboom: (c) => { noise(c, 1.4, 0.45, 'lowpass', 300); tone(c, 'sine', 90, 20, 1.4, 0.35); noise(c, 0.6, 0.2, 'bandpass', 900, 0.15); },
  sink: (c) => { tone(c, 'sine', 300, 60, 0.9, 0.12); noise(c, 0.8, 0.08, 'bandpass', 500, 0.1); },
  chain: (c) => { [660, 880, 1100].forEach((f, i) => tone(c, 'square', f, f * 1.05, 0.08, 0.08, i * 0.05)); },
  launch: (c) => { noise(c, 0.25, 0.08, 'bandpass', 900); tone(c, 'sawtooth', 200, 420, 0.25, 0.04); },
  mine: (c) => { tone(c, 'square', 160, 160, 0.06, 0.08); tone(c, 'square', 120, 120, 0.06, 0.08, 0.08); },
  shield: (c) => { tone(c, 'sine', 900, 1500, 0.25, 0.14); tone(c, 'triangle', 1500, 900, 0.2, 0.06, 0.1); },
  ping: (c) => { tone(c, 'sine', 1480, 1400, 0.9, 0.12); tone(c, 'sine', 1480, 1400, 0.6, 0.04, 0.5); },
  alarm: (c) => { [880, 660, 880, 660].forEach((f, i) => tone(c, 'square', f, f, 0.14, 0.09, i * 0.16)); },
  crunch: (c) => { noise(c, 0.35, 0.28, 'lowpass', 1200); tone(c, 'sawtooth', 160, 50, 0.3, 0.12); },
  special: (c) => { tone(c, 'sawtooth', 200, 900, 0.3, 0.12); noise(c, 0.3, 0.12, 'highpass', 1600, 0.05); },
  lose: (c) => { [392, 330, 262, 196].forEach((f, i) => tone(c, 'triangle', f, f * 0.97, 0.35, 0.14, i * 0.25)); },
  step: (c) => noise(c, 0.04, 0.025, 'lowpass', 500),
};

export function playSe(name: string) {
  const c = audio();
  if (!c) return;
  const fn = SOUNDS[name];
  if (!fn) return;
  try {
    if (c.state === 'suspended') c.resume().catch(() => undefined);
    fn(c);
  } catch {
    // 音が出せなくてもゲームは続ける
  }
}
