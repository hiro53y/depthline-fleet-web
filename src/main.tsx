import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './ui/App';
import { registerServiceWorker } from './pwa';
import './styles/app.css';

// 確かめ用：画面が見えていない時も進めるため、?rafshim=1 で描画をタイマーで回す
if (location.search.includes('rafshim=1')) {
  window.requestAnimationFrame = (cb) => window.setTimeout(() => cb(performance.now()), 16);
  window.cancelAnimationFrame = (id) => window.clearTimeout(id);
}

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);

registerServiceWorker();
