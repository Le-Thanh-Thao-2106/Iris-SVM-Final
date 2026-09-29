# Iris SVM Platform

Ứng dụng web phân loại hoa Iris bằng SVM với 4 kernel: Linear, RBF, Polynomial và Sigmoid.

## Chạy local

```bash
npm install
npm run dev
```

Mở `http://localhost:3000`.

> Không nên mở `index.html` bằng cách double-click (`file://...`). Vite cần xử lý module và CSS.

## Build production

```bash
npm install
npm run build
npm start
```

## Deploy Render

Render Web Service:

- Runtime: Node
- Build Command: `npm install && npm run build`
- Start Command: `npm start`
- Health Check Path: `/health`

`render.yaml` trong repository đã chứa cấu hình tương ứng.


## Huấn luyện Python thực trên Web
Các nút huấn luyện trên web gọi FastAPI `/train`. Backend dùng `sklearn.svm.SVC`, `load_iris()`, `train_test_split(test_size=0.2, random_state=42, stratify=y)`, sau đó lưu `svm_<kernel>.pkl`, cập nhật `metrics.json` và trả decision grid/support vectors thật về frontend. Không còn SVM huấn luyện bằng JavaScript trong trình duyệt. `/train-all` huấn luyện lại cả bốn kernel.


### Bản sửa 31/10/2026
- Nút **Nhận diện** chỉ chuyển trang, không tự động gọi `/train`.
- Huấn luyện Python `sklearn.SVC` chỉ chạy khi người dùng bấm nút huấn luyện.
- Các nút điều hướng dùng `type="button"` để tránh submit form ngoài ý muốn.
