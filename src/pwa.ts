export function registerServiceWorker() {
  if (!('serviceWorker' in navigator) || import.meta.env.DEV) {
    return;
  }

  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/service-worker.js')
      .then((registration) => registration.update())
      .catch((error: unknown) => {
        console.warn('Service worker registration failed', error);
      });
  });
}
