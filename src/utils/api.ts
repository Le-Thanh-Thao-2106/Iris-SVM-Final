import { normalizeSpecies } from './svmModel';
import { IrisSpecies } from '../types';

export const API_URL = '/predict';

export interface PredictInput {
  sepal_length: number;
  sepal_width: number;
  petal_length: number;
  petal_width: number;
}

export interface PredictResult {
  species: IrisSpecies;
  confidence: number;
  source: 'remote';
}

export async function callSVM(data: PredictInput): Promise<PredictResult> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...data, kernel: 'linear' }),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`SVM API error: ${response.status}`);
    }

    const result = await response.json();
    const norm = normalizeSpecies(result.prediction);

    return {
      species: norm,
      // API hiện trả nhãn dự đoán và thời gian suy luận; không giả định đây là xác suất.
      confidence: typeof result.confidence === 'number' ? result.confidence : 0,
      source: 'remote',
    };
  } finally {
    clearTimeout(timeoutId);
  }
}
