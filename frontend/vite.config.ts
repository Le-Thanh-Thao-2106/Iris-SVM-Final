import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig} from 'vite';

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      host: '0.0.0.0',
      port: 3000,
      proxy: {
        '/predict-batch': 'http://127.0.0.1:3001',
        '/predict': 'http://127.0.0.1:3001',
        '/train': 'http://127.0.0.1:3001',
        '/train-all': 'http://127.0.0.1:3001',
        '/metrics': 'http://127.0.0.1:3001',
        '/health': 'http://127.0.0.1:3001',
        '/random-sample': 'http://127.0.0.1:3001'
      },
      // Training is performed by FastAPI and writes model/metrics files into the
      // project directory. Vite must NOT treat those generated files as a web
      // change, otherwise it triggers a full browser reload and returns the SPA
      // to the default Trang chủ page immediately after /train completes.
      hmr: false,
      watch: {
        ignored: [
          '**/svm_*.pkl',
          '**/metrics.json',
          '**/weights.json',
          '**/__pycache__/**',
          '**/.venv/**',
        ],
      },
    },
  };
});
