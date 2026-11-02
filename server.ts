import express from 'express';
import { createServer as createViteServer } from 'vite';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const SVM_API_URL = (process.env.SVM_API_URL || (process.env.SVM_API_HOST ? `http://${process.env.SVM_API_HOST}` : 'http://127.0.0.1:8000')).replace(/\/$/, '');

app.use(express.json());

// CORS configuration
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Load metrics from metrics.json or weights.json
function getMetricsData(): Record<string, any> {
  const metricsPath = path.join(__dirname, 'metrics.json');
  const weightsPath = path.join(__dirname, 'weights.json');
  try {
    if (fs.existsSync(metricsPath)) {
      const raw = fs.readFileSync(metricsPath, 'utf-8');
      return JSON.parse(raw);
    } else if (fs.existsSync(weightsPath)) {
      const raw = fs.readFileSync(weightsPath, 'utf-8');
      const parsed = JSON.parse(raw);
      return parsed.models_metrics || {};
    }
  } catch (err) {
    console.warn('[server.ts] Error reading metrics data:', err);
  }
  return {};
}

const SPECIES: Record<number, string> = {
  0: 'setosa',
  1: 'versicolor',
  2: 'virginica',
};

const AVAILABLE_KERNELS = ['rbf', 'linear', 'poly', 'sigmoid'];

function roundTo(num: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(num * factor) / factor;
}

function randRange(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

// ── API Endpoints ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    available_kernels: AVAILABLE_KERNELS,
    total_models: AVAILABLE_KERNELS.length,
  });
});

app.get('/metrics', (req, res) => {
  const data = getMetricsData();
  const kernel = req.query.kernel as string | undefined;
  if (kernel && data[kernel.toLowerCase()]) {
    return res.json(data[kernel.toLowerCase()]);
  }

  res.json({
    active_models: AVAILABLE_KERNELS,
    summary: data,
    default: data['linear'] || {
      name: 'SVM (Linear - Tuyến tính)',
      accuracy: 1.0,
      precision: 1.0,
      recall: 1.0,
      f1_score: 1.0,
    },
  });
});

app.post('/train', async (req, res) => {
  try {
    const response = await fetch(`${SVM_API_URL}/train`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {}),
    });
    const body = await response.text();
    const contentType = response.headers.get('content-type');
    if (contentType) res.setHeader('Content-Type', contentType);
    return res.status(response.status).send(body);
  } catch (error) {
    console.error('[server.ts] FastAPI /train error:', error);
    return res.status(503).json({
      error: 'FastAPI backend không khả dụng',
      message: 'Không thể kết nối tới Python SVM API để huấn luyện mô hình.'
    });
  }
});

app.post('/train-all', async (req, res) => {
  try {
    const response = await fetch(`${SVM_API_URL}/train-all`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {}),
    });
    const body = await response.text();
    const contentType = response.headers.get('content-type');
    if (contentType) res.setHeader('Content-Type', contentType);
    return res.status(response.status).send(body);
  } catch (error) {
    console.error('[server.ts] FastAPI /train-all error:', error);
    return res.status(503).json({
      error: 'FastAPI backend không khả dụng',
      message: 'Không thể kết nối tới Python SVM API để huấn luyện 4 kernel.'
    });
  }
});

app.post('/predict', async (req, res) => {
  try {
    const response = await fetch(`${SVM_API_URL}/predict`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {}),
    });

    const body = await response.text();
    const contentType = response.headers.get('content-type');
    if (contentType) res.setHeader('Content-Type', contentType);
    return res.status(response.status).send(body);
  } catch (error) {
    console.error('[server.ts] FastAPI /predict error:', error);
    return res.status(503).json({
      error: 'FastAPI backend không khả dụng',
      message: 'Không thể kết nối tới Python SVM API.'
    });
  }
});

app.post('/predict-batch', async (req, res) => {
  try {
    const response = await fetch(`${SVM_API_URL}/predict-batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {}),
    });

    const body = await response.text();
    const contentType = response.headers.get('content-type');
    if (contentType) res.setHeader('Content-Type', contentType);
    return res.status(response.status).send(body);
  } catch (error) {
    console.error('[server.ts] FastAPI /predict-batch error:', error);
    return res.status(503).json({
      error: 'FastAPI backend không khả dụng',
      message: 'Không thể kết nối tới Python SVM API.'
    });
  }
});

app.get('/random-sample', async (req, res) => {
  const mode = Math.random();
  let pl: number;
  let pw: number;
  let sl: number;
  let sw: number;
  let difficulty: string;

  if (mode < 0.4) {
    const isVersiVirgi = Math.random() < 0.5;
    if (isVersiVirgi) {
      pl = roundTo(randRange(4.5, 5.3), 1);
      pw = roundTo(randRange(1.4, 1.8), 1);
      sl = roundTo(randRange(5.6, 6.8), 1);
      sw = roundTo(randRange(2.5, 3.2), 1);
      difficulty = 'Khó 🔥 (Vùng ranh giới Versicolor - Virginica)';
    } else {
      pl = roundTo(randRange(2.0, 2.8), 1);
      pw = roundTo(randRange(0.6, 0.9), 1);
      sl = roundTo(randRange(4.8, 5.6), 1);
      sw = roundTo(randRange(2.8, 3.8), 1);
      difficulty = 'Thử thách ⚡ (Vùng chuyển tiếp Setosa)';
    }
  } else if (mode < 0.7) {
    pl = roundTo(randRange(1.0, 6.9), 1);
    pw = roundTo(randRange(0.1, 2.5), 1);
    sl = roundTo(randRange(4.3, 7.9), 1);
    sw = roundTo(randRange(2.0, 4.4), 1);
    difficulty = 'Khắp bảng 🎲 (Tọa độ tự do)';
  } else {
    pl = roundTo(randRange(1.2, 6.7), 1);
    pw = roundTo(randRange(0.2, 2.4), 1);
    sl = roundTo(randRange(4.5, 7.7), 1);
    sw = roundTo(randRange(2.2, 4.2), 1);
    difficulty = 'Tiêu chuẩn 🎯';
  }

  try {
    const response = await fetch(`${SVM_API_URL}/predict`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sepal_length: sl,
        sepal_width: sw,
        petal_length: pl,
        petal_width: pw,
        kernel: 'linear'
      })
    });
    if (!response.ok) throw new Error(`FastAPI status ${response.status}`);
    const prediction = await response.json();

    return res.json({
      sepal_length: sl,
      sepal_width: sw,
      petal_length: pl,
      petal_width: pw,
      class_id: prediction.class_id,
      true_class: prediction.prediction,
      difficulty
    });
  } catch (error) {
    console.error('[server.ts] random-sample prediction error:', error);
    return res.status(503).json({ error: 'FastAPI backend không khả dụng' });
  }
});

// Direct route to serve Admin Avatar from src/assets/images/ (or fallback locations) with no-cache
app.get(
  [
    '/images/admin_avatar.jpg',
    '/images/admin_avatar.png',
    '/images/admin_avatar.jpeg',
    '/images/admin_avatar.webp',
    '/api/admin-avatar',
    '/admin_avatar.jpg',
  ],
  (req, res) => {
    const candidatePaths = [
      path.join(__dirname, 'src', 'assets', 'images', 'admin_avatar.jpg'),
      path.join(__dirname, 'src', 'assets', 'images', 'admin_avatar.png'),
      path.join(__dirname, 'src', 'assets', 'images', 'admin_avatar.jpeg'),
      path.join(__dirname, 'src', 'assets', 'images', 'admin_avatar.webp'),
      path.join(__dirname, 'src', 'asscts', 'images', 'admin_avatar.jpg'),
      path.join(__dirname, 'src', 'asscts', 'images', 'admin_avatar.png'),
      path.join(__dirname, 'public', 'images', 'admin_avatar.jpg'),
      path.join(__dirname, 'images', 'admin_avatar.jpg'),
    ];

    for (const p of candidatePaths) {
      if (fs.existsSync(p)) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
        return res.sendFile(p);
      }
    }

    const fallback = path.join(__dirname, 'public', 'images', 'setosa.jpg');
    if (fs.existsSync(fallback)) {
      return res.sendFile(fallback);
    }
    res.status(404).send('Avatar not found');
  }
);

// Serve images statically as fallback
const srcAssetsImagesPath = path.join(__dirname, 'src', 'assets', 'images');
if (fs.existsSync(srcAssetsImagesPath)) {
  app.use('/src/assets/images', express.static(srcAssetsImagesPath));
}
const srcAssctsImagesPath = path.join(__dirname, 'src', 'asscts', 'images');
if (fs.existsSync(srcAssctsImagesPath)) {
  app.use('/src/asscts/images', express.static(srcAssctsImagesPath));
}
const imagesPath = path.join(__dirname, 'images');
const publicImagesPath = path.join(__dirname, 'public', 'images');
if (fs.existsSync(publicImagesPath)) {
  app.use('/images', express.static(publicImagesPath));
} else if (fs.existsSync(imagesPath)) {
  app.use('/images', express.static(imagesPath));
}

async function startServer() {
  if (process.env.NODE_ENV === 'production') {
    app.use(express.static(path.join(__dirname, 'dist')));
    app.get('*', (req, res) => {
      res.sendFile(path.join(__dirname, 'dist', 'index.html'));
    });
  } else {
    const vite = await createViteServer({
      server: { middlewareMode: true, hmr: process.env.DISABLE_HMR !== 'true' },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${PORT}`);
  });
}

startServer();
