import json
import os
import time
from typing import Literal

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC

KERNELS = ["linear", "rbf", "poly", "sigmoid"]
SPECIES_MAP = {0: "setosa", 1: "versicolor", 2: "virginica"}
FEATURE_NAMES = ["Sepal Length", "Sepal Width", "Petal Length", "Petal Width"]

app = FastAPI(
    title="Iris Multi-Kernel SVM API",
    description="API phân loại Iris với 4 Kernel SVM và huấn luyện thực bằng scikit-learn.",
    version="3.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

models = {}
metrics_data = {}


def load_saved_models():
    models.clear()
    for k in KERNELS:
        pkl_file = f"svm_{k}.pkl"
        if os.path.exists(pkl_file):
            models[k] = joblib.load(pkl_file)


def load_metrics_file():
    global metrics_data
    metrics_data = {}
    if os.path.exists("metrics.json"):
        try:
            with open("metrics.json", "r", encoding="utf-8") as f:
                metrics_data = json.load(f)
        except Exception:
            metrics_data = {}


load_saved_models()
load_metrics_file()


class IrisInput(BaseModel):
    sepal_length: float = Field(..., description="Chiều dài đài hoa (cm)", json_schema_extra={"example": 5.1})
    sepal_width: float = Field(..., description="Chiều rộng đài hoa (cm)", json_schema_extra={"example": 3.5})
    petal_length: float = Field(..., description="Chiều dài cánh hoa (cm)", json_schema_extra={"example": 1.4})
    petal_width: float = Field(..., description="Chiều rộng cánh hoa (cm)", json_schema_extra={"example": 0.2})
    kernel: Literal["linear", "rbf", "poly", "sigmoid"] = "linear"


class TrainInput(BaseModel):
    kernel: Literal["linear", "rbf", "poly", "sigmoid"] = "linear"
    feature_x: int = Field(2, ge=0, le=3)
    feature_y: int = Field(3, ge=0, le=3)
    input_features: list[float] | None = None
    grid_resolution: int = Field(80, ge=20, le=120)


class BatchItem(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float
    true_label: str | None = None


class BatchInput(BaseModel):
    items: list[BatchItem]
    kernel: Literal["linear", "rbf", "poly", "sigmoid"] = "linear"


def model_for_kernel(kernel: str) -> SVC:
    k = kernel.lower()
    if k == "linear":
        return SVC(kernel="linear", C=1.0)
    if k == "rbf":
        return SVC(kernel="rbf", C=1.0, gamma="scale")
    if k == "poly":
        return SVC(kernel="poly", degree=3, C=1.0, coef0=1.0, gamma="scale")
    if k == "sigmoid":
        return SVC(kernel="sigmoid", C=1.0, gamma="scale", coef0=0.0)
    raise ValueError(f"Unsupported kernel: {kernel}")


def params_for_kernel(kernel: str) -> dict:
    k = kernel.lower()
    if k == "linear":
        return {"C": 1.0}
    if k == "rbf":
        return {"C": 1.0, "gamma": "scale"}
    if k == "poly":
        return {"C": 1.0, "gamma": "scale", "degree": 3, "coef0": 1.0}
    return {"C": 1.0, "gamma": "scale", "coef0": 0.0}


def train_one_kernel(kernel: str):
    """Train exactly the same 80/20 Iris experiment used by train.py."""
    iris = load_iris()
    X, y = iris.data, iris.target
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = model_for_kernel(kernel)
    start = time.perf_counter()
    model.fit(X_train, y_train)
    train_time_ms = (time.perf_counter() - start) * 1000.0

    start = time.perf_counter()
    y_pred = model.predict(X_test)
    pred_time_ms = (time.perf_counter() - start) * 1000.0 / len(X_test)

    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average="macro", zero_division=0)
    recall = recall_score(y_test, y_pred, average="macro", zero_division=0)
    f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)
    cm = confusion_matrix(y_test, y_pred).tolist()

    k = kernel.lower()
    names = {
        "linear": "SVM (Linear - Tuyến tính)",
        "rbf": "SVM (RBF - Phi tuyến Gaussian)",
        "poly": "SVM (Polynomial - Đa thức bậc 3)",
        "sigmoid": "SVM (Sigmoid - Hàm Hyperbolic)",
    }
    result = {
        "name": names[k],
        "kernel": k,
        "accuracy": round(float(accuracy), 4),
        "precision": round(float(precision), 4),
        "recall": round(float(recall), 4),
        "f1_score": round(float(f1), 4),
        "support_vectors_count": int(model.n_support_.sum()),
        "support_vectors_per_class": [int(v) for v in model.n_support_.tolist()],
        "train_time_ms": round(float(train_time_ms), 3),
        "pred_time_ms": round(float(pred_time_ms), 3),
        "confusion_matrix": cm,
        "params": params_for_kernel(k),
        "train_samples": int(len(X_train)),
        "test_samples": int(len(X_test)),
    }
    return model, X_train, y_train, result


def save_metrics():
    with open("metrics.json", "w", encoding="utf-8") as f:
        json.dump(metrics_data, f, ensure_ascii=False, indent=4)


def build_decision_grid(model: SVC, feature_x: int, feature_y: int, resolution: int):
    iris = load_iris()
    X = iris.data
    means = X.mean(axis=0)
    all_x = X[:, feature_x]
    all_y = X[:, feature_y]
    min_x, max_x = float(all_x.min()), float(all_x.max())
    min_y, max_y = float(all_y.min()), float(all_y.max())
    pad_x = (max_x - min_x) * 0.12 or 0.5
    pad_y = (max_y - min_y) * 0.12 or 0.5
    x_min = max(0.0, min_x - pad_x)
    x_max = max_x + pad_x
    y_min = max(0.0, min_y - pad_y)
    y_max = max_y + pad_y

    xs = np.linspace(x_min, x_max, resolution + 1)
    ys = np.linspace(y_min, y_max, resolution + 1)
    mesh = []
    points = []
    for x in xs:
        for y in ys:
            row = means.copy()
            row[feature_x] = x
            row[feature_y] = y
            points.append(row)
    preds = model.predict(np.asarray(points)).astype(int)
    cursor = 0
    for _ in range(resolution + 1):
        row = []
        for _ in range(resolution + 1):
            row.append(int(preds[cursor]))
            cursor += 1
        mesh.append(row)

    return {
        "gridData": mesh,
        "xMin": round(x_min, 4),
        "xMax": round(x_max, 4),
        "yMin": round(y_min, 4),
        "yMax": round(y_max, 4),
        "resX": resolution,
        "resY": resolution,
        "featXIdx": feature_x,
        "featYIdx": feature_y,
        "featureMeans": [round(float(v), 6) for v in means],
    }


@app.get("/")
def home():
    return {
        "message": "Iris Multi-Kernel SVM API is running",
        "supported_kernels": KERNELS,
        "training_engine": "Python scikit-learn SVC",
        "dataset": "sklearn.datasets.load_iris",
        "split": "80/20, random_state=42, stratify=y",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "models_loaded": list(models.keys()),
        "total_kernels": len(models),
        "training_engine": "Python scikit-learn SVC",
    }


@app.get("/metrics")
def get_metrics(kernel: str | None = None):
    if kernel:
        k = kernel.lower()
        if k not in KERNELS:
            raise HTTPException(status_code=400, detail="Kernel không hợp lệ.")
        if k in metrics_data:
            return metrics_data[k]
        raise HTTPException(status_code=404, detail=f"Không tìm thấy metrics cho kernel: {k}")
    return metrics_data


@app.post("/train")
def train_endpoint(data: TrainInput):
    if data.feature_x == data.feature_y:
        raise HTTPException(status_code=400, detail="Trục X và Y phải khác nhau.")

    k = data.kernel.lower()
    model, X_train, y_train, result = train_one_kernel(k)

    # Replace the in-memory model immediately, then persist it.
    models[k] = model
    joblib.dump(model, f"svm_{k}.pkl")
    metrics_data[k] = result
    save_metrics()

    grid = build_decision_grid(model, data.feature_x, data.feature_y, data.grid_resolution)

    input_values = data.input_features or [5.1, 3.5, 1.4, 0.2]
    if len(input_values) != 4:
        raise HTTPException(status_code=400, detail="input_features phải có đúng 4 giá trị.")
    input_array = np.asarray([input_values], dtype=float)
    current_class = int(model.predict(input_array)[0])

    # Exact support-vector coordinates from the real sklearn model.
    sv_points = []
    for row in model.support_vectors_:
        sv_points.append([round(float(v), 6) for v in row.tolist()])

    return {
        "status": "trained",
        "training_engine": "Python scikit-learn SVC",
        "kernel": k,
        "metrics": result,
        "decision_grid": grid,
        "support_vectors": sv_points,
        "support_vectors_count": len(sv_points),
        "current_prediction": {
            "class_id": current_class,
            "prediction": SPECIES_MAP[current_class],
        },
        "input_features": [float(v) for v in input_values],
        "dataset": {
            "total": 150,
            "train": 120,
            "test": 30,
            "features": 4,
            "classes": 3,
        },
    }


@app.post("/train-all")
def train_all_endpoint():
    results = {}
    for k in KERNELS:
        model, _, _, result = train_one_kernel(k)
        models[k] = model
        joblib.dump(model, f"svm_{k}.pkl")
        metrics_data[k] = result
        results[k] = result
    save_metrics()
    return {
        "status": "trained_all",
        "training_engine": "Python scikit-learn SVC",
        "kernels": KERNELS,
        "metrics": results,
    }


@app.post("/predict")
def predict(data: IrisInput):
    k = data.kernel.lower()
    if k not in models:
        raise HTTPException(status_code=400, detail=f"Kernel '{k}' chưa được load.")

    features = np.array([[data.sepal_length, data.sepal_width, data.petal_length, data.petal_width]], dtype=float)
    start = time.perf_counter()
    prediction = int(models[k].predict(features)[0])
    exec_time_ms = (time.perf_counter() - start) * 1000.0

    return {
        "kernel_used": k,
        "class_id": prediction,
        "prediction": SPECIES_MAP[prediction],
        "execution_time_ms": round(exec_time_ms, 3),
        "input_features": {
            "sepal_length": data.sepal_length,
            "sepal_width": data.sepal_width,
            "petal_length": data.petal_length,
            "petal_width": data.petal_width,
        },
    }


@app.post("/predict-batch")
def predict_batch(data: BatchInput):
    k = data.kernel.lower()
    if k not in models:
        raise HTTPException(status_code=400, detail=f"Kernel '{k}' chưa được load.")
    if not data.items:
        return {"kernel_used": k, "results": []}

    features = np.array([[i.sepal_length, i.sepal_width, i.petal_length, i.petal_width] for i in data.items], dtype=float)
    predictions = models[k].predict(features).astype(int).tolist()
    results = []
    for item, prediction in zip(data.items, predictions):
        pred_name = SPECIES_MAP[int(prediction)]
        true_label = (item.true_label or "").strip().lower()
        correct = None
        if true_label:
            correct = true_label == pred_name or true_label in pred_name or pred_name in true_label
        results.append({
            "sepal_length": item.sepal_length,
            "sepal_width": item.sepal_width,
            "petal_length": item.petal_length,
            "petal_width": item.petal_width,
            "class_id": int(prediction),
            "prediction": pred_name,
            "true_label": item.true_label,
            "correct": correct,
        })
    return {"kernel_used": k, "results": results}
