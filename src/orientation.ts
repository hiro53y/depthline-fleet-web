// 画面をいつも縦に：①縦に固定を頼む（ホーム画面のアプリなら効く）②それでもスマホが横長なら、中身を90度回して縦に見せる
export type Rot = 0 | 90 | -90;

let rot: Rot = 0;

export function currentRot(): Rot {
  return rot;
}

/** 縦に固定を頼む（使えない環境では何もしない） */
export function tryLock() {
  try {
    const so = screen.orientation as ScreenOrientation & { lock?: (o: string) => Promise<void> };
    so?.lock?.('portrait-primary').catch(() => undefined);
  } catch {
    // 固定できない環境
  }
}

/** 回す角度（スマホで横長の時だけ。flip で上下を反転） */
export function computeRot(flip: boolean): Rot {
  const touch = window.matchMedia?.('(pointer: coarse)').matches ?? false;
  const landscape = window.innerWidth > window.innerHeight;
  if (!touch || !landscape || window.innerHeight > 600) return 0;
  // 端末の画面が左回りに回っている（角度90）なら中身を左へ90度戻す
  const angle = screen.orientation?.angle ?? 90;
  const base: Rot = angle === 270 ? 90 : -90;
  return flip ? (base === 90 ? -90 : 90) : base;
}

/** #root を回し、縦の大きさを CSS の変数で渡す */
export function applyRot(r: Rot) {
  rot = r;
  const root = document.getElementById('root');
  const de = document.documentElement;
  if (!root) return;
  const w = window.innerWidth, h = window.innerHeight;
  if (r === 0) {
    root.removeAttribute('style');
    de.style.removeProperty('--vw');
    de.style.removeProperty('--vh');
    return;
  }
  // 回した後の幅＝元の高さ、高さ＝元の幅
  root.style.position = 'fixed';
  root.style.left = '0';
  root.style.top = '0';
  root.style.width = `${h}px`;
  root.style.height = `${w}px`;
  root.style.transformOrigin = '0 0';
  root.style.transform = r === -90 ? `translateY(${h}px) rotate(-90deg)` : `translateX(${w}px) rotate(90deg)`;
  de.style.setProperty('--vw', `${h}px`);
  de.style.setProperty('--vh', `${w}px`);
}

/** 画面の座標を、回した要素の中の座標に直す */
export function toLocal(el: Element, cx: number, cy: number): [number, number] {
  const r = el.getBoundingClientRect();
  if (rot === -90) return [r.bottom - cy, cx - r.left];
  if (rot === 90) return [cy - r.top, r.right - cx];
  return [cx - r.left, cy - r.top];
}
