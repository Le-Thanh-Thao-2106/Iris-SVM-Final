# Iris SVM - Chạy local, kiểm thử và Deploy GitHub/Render

## 1. Chạy local

### Cửa sổ PowerShell 1 - FastAPI

```powershell
cd "D:\Downloads\Iris-SVM-fixed-4features\Iris-SVM-main"
.venv\Scripts\python.exe --version
.venv\Scripts\python.exe -m uvicorn app:app --host 127.0.0.1 --port 8000
```

Kiểm tra:

- `http://127.0.0.1:8000/health`
- `http://127.0.0.1:8000/metrics`

`/health` phải báo 4 kernel và `training_engine: Python scikit-learn SVC`.

### Cửa sổ PowerShell 2 - Web

```powershell
cd "D:\Downloads\Iris-SVM-fixed-4features\Iris-SVM-main"
npm.cmd install
npm.cmd run dev
```

Mở URL `Local:` mà terminal in ra, thường là `http://localhost:3000`.

Không mở `index.html` bằng `file:///...`.

## 2. Kiểm thử huấn luyện thật

Trên trang Nhận diện:

1. Xác nhận 4/4 features đều được khóa ở trạng thái chọn.
2. Chọn Linear/RBF/Poly/Sigmoid.
3. Bấm `Huấn luyện & Vẽ Decision Boundary` hoặc `Chạy mô hình với đầy đủ 4 đặc trưng`.
4. Chờ kết quả.
5. Timeline và Benchmark phải nhận cùng một kết quả từ Python.

Backend endpoint được gọi là `POST /train`; Node chỉ proxy request sang FastAPI.

Không còn JavaScript SVM trainer trong `src/main.js`.

## 3. Kiểm thử 4 kernel

Với cùng cấu hình:

- 150 mẫu Iris.
- 4 features.
- Train/Test = 80/20.
- `random_state=42`.
- `stratify=y`.

Các kết quả accuracy/support-vector của lần train chuẩn phải khớp:

| Kernel | Accuracy | Support Vectors |
|---|---:|---:|
| Linear | 100% | 23 |
| RBF | 96.67% | 49 |
| Poly | 96.67% | 16 |
| Sigmoid | 10% | 120 |

Thời gian train là thời gian đo thực tế của máy/backend nên có thể thay đổi.

## 4. Kiểm thử prediction

Dùng:

- Sepal Length = 5.1
- Sepal Width = 3.5
- Petal Length = 1.4
- Petal Width = 0.2

Linear/RBF/Poly phải dự đoán Setosa; Sigmoid dùng đúng model Python hiện tại.

## 5. GitHub

Sau khi test local thành công:

```powershell
git status
git add .
git commit -m "Replace browser SVM training with real Python training"
git push origin main
```

Nếu branch của bạn là `master` thì dùng `git push origin master`.

## 6. Render

Repository cần có:

- `render.yaml`
- `requirements.txt`
- `.python-version` = `3.11`
- `app.py`
- `server.ts`
- 4 file `svm_*.pkl`

`render.yaml` tạo 2 web services:

### Node frontend
- Name: `iris-svm`
- Runtime: Node
- Build: `npm install && npm run build`
- Start: `npm start`
- Env: `SVM_API_HOST` lấy từ service `iris-svm-api`

### Python API
- Name: `iris-svm-api`
- Runtime: Python
- Build: `pip install -r requirements.txt`
- Start: `uvicorn app:app --host 0.0.0.0 --port $PORT`
- Health: `/health`

Sau khi deploy, kiểm tra Python service trước:

`https://iris-svm-api.onrender.com/health`

Sau đó mở frontend:

`https://iris-svm.onrender.com`

## 7. Kiểm thử Render

1. `/health` phải báo 4 models.
2. Trang web phải báo API Online.
3. Prediction phải trả kết quả.
4. Bấm Train phải chạy `POST /train` qua Node -> FastAPI.
5. Accuracy/Support Vectors trong kết quả Train, Timeline và Benchmark phải giống nhau.
6. Refresh trang và kiểm tra không còn các run JavaScript cũ 50%.
