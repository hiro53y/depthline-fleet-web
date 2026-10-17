// BGM（mp3 を1曲ずつ流す。切り替えは短く絞ってから）
const BASE = '/assets/audio/bgm/';

let el: HTMLAudioElement | null = null;
let current = '';
let wanted = '';
let volume = 0.5;
let fadeTimer: number | null = null;

export function setBgmVolume(v: number) {
  volume = Math.max(0, Math.min(1, v));
  if (el) el.volume = volume;
  if (volume <= 0 && el) el.pause();
  else if (volume > 0 && wanted) playBgm(wanted, true);
}

/** 曲を流す（同じ曲なら続ける）。ブラウザに止められたら、次に触れた時に流す */
export function playBgm(name: string, force = false) {
  wanted = name;
  if (volume <= 0) return;
  if (!force && name === current && el && !el.paused) return;
  if (name === current && el) {
    el.volume = volume;
    el.play().catch(() => undefined);
    return;
  }
  const old = el;
  if (fadeTimer !== null) { window.clearInterval(fadeTimer); fadeTimer = null; }
  if (old) {
    let v = old.volume;
    fadeTimer = window.setInterval(() => {
      v -= 0.08;
      if (v <= 0) { old.pause(); if (fadeTimer !== null) window.clearInterval(fadeTimer); fadeTimer = null; }
      else old.volume = v;
    }, 40);
  }
  current = name;
  const a = new Audio(`${BASE}${name}.mp3`);
  a.loop = true;
  a.preload = 'auto';
  a.volume = volume;
  el = a;
  a.play().catch(() => undefined);
}

/** 画面に触れた時：止められていた曲を流す */
export function resumeBgm() {
  if (el && el.paused && volume > 0 && wanted === current) el.play().catch(() => undefined);
}

export function stopBgm() {
  wanted = '';
  if (el) el.pause();
}

