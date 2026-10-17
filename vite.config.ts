import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// 出力先は build/web（Cloudflare Workers の配信先 wrangler.toml と同じ）
export default defineConfig({
  plugins: [react()],
  build: { outDir: 'build/web', emptyOutDir: true },
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
} as Parameters<typeof defineConfig>[0]);
