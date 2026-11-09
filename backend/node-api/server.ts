import express from 'express';
const app = express();
const PORT = Number(process.env.PORT) || 3001;
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

app.get('/metrics', async (req, res) => {
  try {
    // Metrics được đọc từ Python service vì mỗi dịch vụ Render có filesystem riêng.
    const response = await fetch(`${SVM_API_URL}/metrics`);
    const body = await response.text();
    if (!response.ok) return res.status(response.status).send(body);
    const data = JSON.parse(body || '{}');
    const kernel = req.query.kernel as string | undefined;
    if (kernel) {
      const selected = data[kernel.toLowerCase()];
      if (!selected) return res.status(404).json({ error: 'Không tìm thấy metrics cho kernel.' });
      return res.json(selected);
    }
    return res.json({
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
  } catch (error) {
    console.error('[server.ts] FastAPI /metrics error:', error);
    return res.status(503).json({ error: 'Không thể đọc metrics từ Python API.' });
  }
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


// Node.js chỉ cung cấp API trung gian; giao diện được chạy độc lập trong frontend/.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Node API running at http://0.0.0.0:${PORT}`);
});
