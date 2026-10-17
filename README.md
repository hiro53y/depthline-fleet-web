# Depthline Fleet 2.0

縦画面の海戦アクション PWA です（公開先 https://depthline-fleet-web.seto0807.workers.dev/ ）。
2.0 で Flutter＋Flame から TypeScript＋Canvas に作り直しました（読み込み約 80KB）。昔の海戦アクションに影響を受けていますが、固有名詞・画像・音は流用していません（絵はすべて Canvas で描画）。

## 遊び方
- 海面の艦を左右に動かし、左右の舷側から爆雷を落として潜水艦を沈める。爆雷は空中→着水→ゆっくり沈む。点線が落ちる場所の目安。
- 操作：下の ◀ ▶（長押しで移動）・左投下・右投下（長押しで連続）・特殊。海面より上をなぞっても移動、海の中に触れるとその側へ投下。PC は ← → / Z X / スペース。
- 爆発は近くの爆雷・機雷を誘爆させて連鎖になる。連鎖で複数沈めると点が増える。深い敵ほど高得点。
- 敵：小型潜水艇・潜水艦・深海潜水艦・機雷敷設艦・追尾潜水艦・魚雷艇・影の潜水艦。魚雷・追尾魚雷・機雷は爆発で消せる。
- ボス5種（区画を壊していく。体力で形態が変わる）。
- 強化（連射・大型爆雷・盾・修理・三連投下・金）と特殊兵装（投射爆雷・散布爆雷・誘導魚雷・ソナー爆発）。
- 全30ステージ（大陸棚・船団航路・嵐の海・氷の海・深淵 × 6）。目標は撃沈・耐える・船団の護衛・ボス。星1〜3。
- 改造（船体・機関・装填・投下数・炸薬・範囲・ソナー・特殊兵装）と艦3種（駆逐艦・コルベット・巡洋艦）。
- 無限の海（波ごとに強くなる）と毎日の挑戦（日替わりの条件・初勝利で報酬）。難しさはふつう／艦長。

## 起動・確認
```bash
npm install
npm run dev
npm run test
npm run build
```
- `npm run test`：単体テスト・全ステージの総当たり・ボットによる全30ステージ通し（Vitest）。
- `BALANCE=1 npm run test`：ボットで難しさを集計。`CALIBRATE=1`：ステージごとの硬さ（`CALIB`）を探し直す（出た値の8割を使い、上限3、1・2面は手で下げる）。`PROBE=<面>`（＋`MAXUP=1`）：1面を細かく見る。
- 確かめ用：開発中か `?dbg=1` で `window.__df`（`start()`・`run(秒, 入力)`）。`?rafshim=1` で描画をタイマーで回す。

## 構成
- `src/game/`：純粋な TS（固定の刻み 1/60・seed 付き乱数）。表 `data.ts`、進行 `sim.ts`、無限と毎日 `modes.ts`、進みと改造 `progress.ts`、保存 `save.ts`（キー `depthline-fleet-v2:*`。Flutter 版の保存は読まない・消さない）。
- `src/view/`：絵 `art.ts`、描画 `renderer.ts`、演出 `effects.ts`。
- `src/ui/`：タイトル・海図・改造・戦闘。`src/audio/`：BGM（mp3）と効果音（WebAudio の合成音）。
- `public/`：manifest（向きは固定しない）・アイコン・Service Worker（キャッシュ名 `depthline-fleet-v3`）・BGM。

## 公開
GitHub `hiro53y/depthline-fleet-web` の main に push すると、Cloudflare Workers Builds が `bash scripts/netlify_build.sh`（中身は `npm ci && npm run build`）を実行し、`npx wrangler deploy` で `build/web` を配る（`wrangler.toml`）。ビルドスクリプトの名前は Cloudflare の設定に合わせて昔のまま。
