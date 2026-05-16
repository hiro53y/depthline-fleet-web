# Depthline Fleet Web Package

## 概要
このフォルダは、そのまま GitHub リポジトリ化して Netlify に接続できる  
`Depthline Fleet` の Web 公開パッケージです。

現在の内容:
- タイトル画面
- 設定画面
- `3ステージ攻略` と `スコアアタック` の2モード
- 3つの海域ステージ
- ランダム無限スポーンのスコアアタック
- ハイスコアとステージアンロック保存
- スコアアタック専用ハイスコア保存
- パワーアップ
- 効果音
- タイトル / 3ステージ攻略 / スコアアタックのMP3 BGM差し替え
- MP3未配置時の生成BGMフォールバック
- 泡エフェクト
- スマホのホーム画面追加向け manifest

重要:
- **この `depthline_fleet_web` フォルダの中身を、GitHub リポジトリのルートとして使ってください。**
- 親フォルダごとではなく、このフォルダの内容一式がリポジトリ直下にある状態が前提です。

## このフォルダに含めたもの
- Flutter Web 用アプリ本体
- `lib/`
- `web/`
- `test/`
- `pubspec.yaml`
- `.nvmrc`
- `scripts/netlify_build.sh`
- `netlify.toml`

Netlify 側は、このフォルダ単体で完結します。

## BGM の差し替え
MP3 はこのフォルダ内の `assets/audio/bgm/` に保存してください。
このフォルダの外に音源を置く必要はありません。

基本ファイル名:

| 用途 | ファイル名 |
|---|---|
| タイトル画面 | `assets/audio/bgm/title.mp3` |
| 3ステージ攻略 共通 | `assets/audio/bgm/campaign.mp3` |
| スコアアタック | `assets/audio/bgm/score_attack.mp3` |

該当MP3がない場合は、既存の生成BGMが再生されます。

## GitHub へアップロードする手順
1. `depthline_fleet_web` フォルダを開く
2. その中身を GitHub リポジトリのルートに置く
3. GitHub に push する

ローカルで Git を使う場合:

```powershell
cd deliverables\depthline_fleet_web
git init
git add .
git commit -m "Initial web package"
git branch -M main
git remote add origin <GitHubのリポジトリURL>
git push -u origin main
```

## Netlify 公開手順
1. Netlify で `Add new project`
2. GitHub を選ぶ
3. この `depthline_fleet_web` 専用リポジトリを接続する
4. `netlify.toml` が読まれていることを確認する
5. `Deploy site` を実行する

## Netlify で使う設定
このパッケージでは、リポジトリのルートがそのまま Flutter プロジェクトです。

`netlify.toml` の内容:
- Build command: `bash scripts/netlify_build.sh`
- Publish directory: `build/web`
- SPA rewrite: `/* -> /index.html`

Base directory:
- **設定しない**
- もしくは `/` のままにする

補足:
- 以前の monorepo 前提とは違い、このパッケージでは `src/depthline_fleet` の指定は不要です。

## Build スクリプトの内容
`scripts/netlify_build.sh` は次を行います。
- Flutter `3.41.9` を取得
- `flutter pub get`
- `flutter precache --web`
- `flutter build web --release`

## 公開後の確認
公開 URL を開いて次を確認してください。
- 404 でない
- タイトル画面が表示される
- `出撃` でゲーム画面へ進む
- `スコアアタック開始` で無限モードへ進む
- 画面下左側の `左移動` / `右移動` 長押しで自艦が動く
- 画面下右側の `左投下` / `右投下` で左右舷から爆雷が落ちる
- スマホで開ける
- Chrome の `ホーム画面に追加` でホーム画面に追加できる
- 設定、通常ハイスコア、スコアアタックハイスコアが次回起動時にも残る

## 未確認事項
- このセッションでは `flutter` コマンドが使えなかったため、ローカルの `flutter build web --release` 成功確認は未実施です
- Netlify 実サービスでの最終公開確認は、これからこのパッケージで行う前提です
