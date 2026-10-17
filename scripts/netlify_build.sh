#!/usr/bin/env bash
# Cloudflare Workers Builds（と Netlify）が呼ぶビルド。名前は昔のまま（Cloudflare の設定を変えないため）
# 2.0 から TypeScript＋Vite。出力は build/web（wrangler.toml の配信先）
set -euo pipefail
npm ci --no-audit --no-fund
npm run build
