# Iris SVM – cấu trúc đã tách Frontend / Backend / Database

## 1. Cấu trúc
- `frontend/`: giao diện HTML/JavaScript và React/TypeScript, chạy bằng Vite.
- `backend/node-api/`: Express API trung gian, mặc định cổng 3001.
- `backend/python-api/`: FastAPI, huấn luyện và dự đoán 4 Kernel SVM, mặc định cổng 8000.
- `database/supabase_schema.sql`: cấu trúc SQL Supabase.
- `documents/`: slide, báo cáo và tài liệu dự án.

## 2. Phiên bản môi trường khuyến nghị
- Python 3.11 (đã ghim trong `backend/python-api/.python-version`, phù hợp với các phiên bản thư viện trong `requirements.txt`).
- Node.js >= 22.12.0.

## 3. Chạy local (mở 3 terminal tại thư mục gốc)

### Terminal 1 – Python API
```bash
cd backend/python-api
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### Terminal 2 – Node API
```bash
cd backend/node-api
npm install
# Windows PowerShell nếu npm bị chặn: npm.cmd install
# SVM_API_URL mặc định là http://127.0.0.1:8000
npm run dev
```

### Terminal 3 – Frontend
```bash
cd frontend
npm install
npm run dev
```
Mở địa chỉ Vite hiển thị trong terminal (mặc định http://localhost:3000).

## 4. Cấu hình Supabase
- Điền `VITE_SUPABASE_URL` và `VITE_SUPABASE_ANON_KEY` trong môi trường build frontend nếu cần.
- Không đưa service-role key hoặc mật khẩu quản trị vào frontend/Git.
- SQL gốc được giữ tại `database/supabase_schema.sql`; kiểm tra chính sách RLS trước khi triển khai công khai.

## 5. Huấn luyện lại 4 Kernel
Chạy trong `backend/python-api` sau khi kích hoạt môi trường Python:
```bash
python train.py
```
Các file `svm_*.pkl`, `metrics.json`, `weights.json` được ghi cùng thư mục `backend/python-api`.

## 6. Ghi chú triển khai
`render.yaml` đã được tách thành ba dịch vụ độc lập. Sau khi tạo dịch vụ trên Render, kiểm tra lại URL Node API thực tế và cập nhật `VITE_API_BASE_URL` của dịch vụ frontend nếu tên miền khác.

## 7. Bảo toàn mã nguồn
`frontend/src/main.js` (giao diện hiện đang được index.html nạp) và mã React/TypeScript trong `frontend/src/` đều được giữ lại. Không xóa một trong hai nếu chưa xác nhận phần nào còn được sử dụng.
