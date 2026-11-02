# IRIS SVM – HỆ THỐNG PHÂN LOẠI HOA IRIS BẰNG THUẬT TOÁN SUPPORT VECTOR MACHINE

## 1. Giới thiệu dự án

**Iris SVM** là hệ thống ứng dụng công nghệ học máy (Machine Learning) nhằm phân loại hoa Iris dựa trên bốn đặc trưng hình thái:

- Sepal Length: Chiều dài đài hoa.
- Sepal Width: Chiều rộng đài hoa.
- Petal Length: Chiều dài cánh hoa.
- Petal Width: Chiều rộng cánh hoa.

Hệ thống sử dụng thuật toán **Support Vector Machine (SVM)** với bốn loại Kernel:

1. Linear Kernel.
2. Radial Basis Function (RBF) Kernel.
3. Polynomial (Poly) Kernel.
4. Sigmoid Kernel.

Dự án được xây dựng theo kiến trúc phân tách các thành phần, bao gồm:

- **Frontend:** React, TypeScript, Vite.
- **Backend Web:** Node.js, Express, TypeScript.
- **Machine Learning API:** Python, FastAPI, Scikit-learn.
- **Database:** Supabase (PostgreSQL).
- **Triển khai:** GitHub và Render.

Mục tiêu của hệ thống là cung cấp một nền tảng trực quan để người dùng có thể thực hiện dự đoán, huấn luyện mô hình, phân tích dữ liệu, so sánh các Kernel SVM và lưu trữ lịch sử sử dụng.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Giao diện | React 19 | Xây dựng giao diện người dùng |
| Ngôn ngữ Frontend | TypeScript | Phát triển các thành phần giao diện có kiểu dữ liệu |
| Công cụ xây dựng | Vite | Khởi chạy môi trường phát triển và build ứng dụng |
| Backend Web | Node.js, Express | Tiếp nhận và xử lý các yêu cầu từ Frontend |
| Ngôn ngữ Backend | TypeScript | Xây dựng API trung gian |
| Machine Learning | Python | Xử lý dữ liệu và huấn luyện mô hình |
| ML Framework | Scikit-learn | Triển khai thuật toán SVM |
| ML API | FastAPI | Cung cấp API dự đoán và huấn luyện |
| Xử lý dữ liệu | NumPy, SciPy | Tính toán và xử lý dữ liệu số |
| Lưu trữ mô hình | Joblib, Pickle | Đọc và lưu các mô hình SVM đã huấn luyện |
| Cơ sở dữ liệu | Supabase | Lưu trữ dữ liệu người dùng, lịch sử và cấu hình |
| Giao diện biểu tượng | Lucide React | Hiển thị các biểu tượng |
| Hiệu ứng giao diện | Motion | Tạo hiệu ứng chuyển động |
| Triển khai | Render | Hosting Frontend, Backend và ML API |

---

## 3. Cấu trúc thư mục dự án

Dự án được tổ chức theo cấu trúc sau:

```text
Iris-SVM-Updated/
│
├── .github/
│   └── workflows/
│       └── static.yml
│
├── images/
│   ├── admin_avatar.png
│   ├── setosa.jpg
│   ├── setosa.svg
│   ├── versicolor.jpg
│   ├── versicolor.svg
│   ├── virginica.jpg
│   └── virginica.svg
│
├── public/
│   ├── favicon.ico
│   ├── favicon.svg
│   ├── health
│   ├── health.json
│   └── images/
│       ├── admin_avatar.jpg
│       ├── setosa.jpg
│       ├── setosa.svg
│       ├── versicolor.jpg
│       ├── versicolor.svg
│       ├── virginica.jpg
│       └── virginica.svg
│
├── src/
│   ├── asscts/
│   │   └── images/
│   │       └── admin_avatar.jpg
│   │
│   ├── assets/
│   │   └── images/
│   │       ├── admin_avatar.png
│   │       ├── setosa_flower_1790247011121.jpg
│   │       ├── versicolor_flower_1790246999683.jpg
│   │       └── virginica_flower_1790246987613.jpg
│   │
│   ├── components/
│   │   ├── BenchmarkPage.tsx
│   │   ├── ExperimentsPage.tsx
│   │   ├── FileAnalysisPage.tsx
│   │   ├── GuessPage.tsx
│   │   ├── HistoryPage.tsx
│   │   ├── PlaygroundPage.tsx
│   │   ├── PredictPage.tsx
│   │   ├── VerifyModal.tsx
│   │   └── VisualizationPage.tsx
│   │
│   ├── data/
│   │   └── irisData.ts
│   │
│   ├── types/
│   │   └── index.ts
│   │
│   ├── utils/
│   │   ├── api.ts
│   │   └── svmModel.ts
│   │
│   ├── App.tsx
│   ├── index.css
│   ├── main.js
│   ├── main.tsx
│   └── supabase.js
│
├── .env.example
├── .gitignore
├── .python-version
├── app.py
├── bun.lock
├── data.json
├── DEPLOY_GUIDE.md
├── index.html
├── metadata.json
├── metrics.json
├── package-lock.json
├── package.json
├── README.md
├── render.yaml
├── requirements.txt
├── server.ts
├── supabase_schema.sql
│
├── svm_linear.pkl
├── svm_poly.pkl
├── svm_rbf.pkl
├── svm_sigmoid.pkl
│
├── train.py
├── tsconfig.json
├── vite.config.ts
└── weights.json
```

### 3.1. Thư mục `.github/`

Chứa các cấu hình liên quan đến GitHub Actions.

- `workflows/static.yml`: File cấu hình quy trình tự động hóa trên GitHub Actions, phục vụ các tác vụ được thiết lập trong workflow.

### 3.2. Thư mục `images/`

Chứa các tài nguyên hình ảnh sử dụng trong hệ thống.

- `admin_avatar.png`: Hình ảnh đại diện quản trị viên.
- `setosa.jpg`, `setosa.svg`: Hình ảnh minh họa hoa Iris Setosa.
- `versicolor.jpg`, `versicolor.svg`: Hình ảnh minh họa hoa Iris Versicolor.
- `virginica.jpg`, `virginica.svg`: Hình ảnh minh họa hoa Iris Virginica.

### 3.3. Thư mục `public/`

Chứa các tài nguyên tĩnh được Vite phục vụ trực tiếp khi ứng dụng chạy.

- `favicon.ico`, `favicon.svg`: Biểu tượng của website.
- `health`, `health.json`: Các tài nguyên phục vụ việc kiểm tra trạng thái được cấu hình trong thư mục public.
- `images/`: Chứa hình ảnh đại diện và hình ảnh minh họa ba loại hoa Iris để sử dụng trên giao diện.

### 3.4. Thư mục `src/`

Đây là thư mục chính của Frontend, chứa mã nguồn giao diện và các thành phần xử lý phía trình duyệt.

#### a. Thư mục `src/components/`

Chứa các trang chức năng chính của hệ thống. Mỗi file tương ứng với một khu vực chức năng riêng.

| File | Chức năng |
|---|---|
| `PredictPage.tsx` | Giao diện nhập bốn đặc trưng của hoa Iris và thực hiện dự đoán loài hoa bằng mô hình SVM. |
| `GuessPage.tsx` | Cho phép người dùng tự đưa ra dự đoán trước khi hệ thống sử dụng SVM để kiểm tra và đối chiếu kết quả. |
| `FileAnalysisPage.tsx` | Phân tích dữ liệu hoa Iris từ file đầu vào, thực hiện dự đoán trên nhiều mẫu và đối chiếu với nhãn thực tế nếu có. |
| `VisualizationPage.tsx` | Hiển thị các biểu đồ trực quan về dữ liệu Iris và kết quả phân loại. |
| `PlaygroundPage.tsx` | Môi trường thử nghiệm SVM, cho phép thay đổi các tham số và quan sát kết quả mô hình. |
| `ExperimentsPage.tsx` | Quản lý và hiển thị các lần thử nghiệm mô hình SVM đã thực hiện. |
| `BenchmarkPage.tsx` | So sánh và đánh giá hiệu suất của các mô hình SVM thông qua những chỉ số đánh giá. |
| `HistoryPage.tsx` | Hiển thị lịch sử dự đoán và các thông tin liên quan đến những lần sử dụng hệ thống. |
| `VerifyModal.tsx` | Thành phần hộp thoại xác minh trước khi người dùng truy cập vào các chức năng của hệ thống. |

#### b. Thư mục `src/data/`

- `irisData.ts`: Chứa dữ liệu mẫu Iris được sử dụng trong ứng dụng, bao gồm các đặc trưng của hoa và nhãn phân loại tương ứng.

#### c. Thư mục `src/types/`

- `index.ts`: Khai báo các kiểu dữ liệu TypeScript dùng chung trong hệ thống như:
  - `IrisSpecies`: Các loại hoa Iris.
  - `SVMKernel`: Các loại Kernel SVM.
  - `SVMConfig`: Cấu hình mô hình SVM.
  - `SVMModelReport`: Cấu trúc kết quả đánh giá mô hình.
  - `ExperimentRecord`: Cấu trúc thông tin thử nghiệm.
  - `HistoryRecord`: Cấu trúc lịch sử dự đoán.
  - `FileAnalysisRow`: Cấu trúc dữ liệu phân tích từ file.

#### d. Thư mục `src/utils/`

Chứa các hàm tiện ích và logic xử lý dùng chung.

- `api.ts`: Xây dựng hàm gửi yêu cầu HTTP từ Frontend đến Backend để thực hiện chức năng dự đoán.
- `svmModel.ts`: Chứa các hàm xử lý liên quan đến SVM ở phía TypeScript, bao gồm tính toán Kernel, xử lý nhãn và các thuật toán hỗ trợ mô phỏng, thử nghiệm mô hình trên giao diện.

**Lưu ý:** Chức năng huấn luyện mô hình thực tế được thực hiện bởi Python Scikit-learn thông qua FastAPI, không phải bằng mã JavaScript trên trình duyệt.

#### e. Các file trực tiếp trong `src/`

- `App.tsx`: Thành phần giao diện chính, quản lý các trang chức năng, điều hướng giữa các trang, trạng thái xác minh, lịch sử và danh sách thử nghiệm.
- `main.tsx`: Điểm khởi chạy chính của ứng dụng React, thực hiện render thành phần App.
- `main.js`: File JavaScript hỗ trợ phần khởi tạo được giữ lại trong dự án.
- `index.css`: Chứa các quy tắc CSS, định dạng giao diện, bố cục, màu sắc và hiệu ứng hiển thị.
- `supabase.js`: Khởi tạo kết nối Supabase thông qua URL và khóa truy cập, phục vụ việc giao tiếp với cơ sở dữ liệu.

### 3.5. Các file Backend và Machine Learning

#### a. `server.ts` – Backend Node.js

Đây là thành phần Backend Web sử dụng Node.js, Express và TypeScript.

Nhiệm vụ chính:

- Khởi tạo máy chủ Express.
- Tiếp nhận các yêu cầu HTTP từ Frontend.
- Cung cấp các API trung gian cho ứng dụng.
- Chuyển tiếp yêu cầu dự đoán và huấn luyện đến Python FastAPI.
- Tiếp nhận kết quả từ Python API và trả về cho Frontend.
- Cung cấp API kiểm tra trạng thái hoạt động.
- Cung cấp API lấy thông tin đánh giá mô hình.
- Hỗ trợ chế độ phát triển với Vite và chế độ production.

Các API chính được triển khai:

| Phương thức | Endpoint | Chức năng |
|---|---|---|
| GET | `/health` | Kiểm tra trạng thái Backend và kết nối API mô hình. |
| GET | `/metrics` | Lấy thông tin đánh giá các mô hình. |
| POST | `/train` | Chuyển yêu cầu huấn luyện một Kernel đến Python API. |
| POST | `/train-all` | Yêu cầu huấn luyện toàn bộ bốn Kernel. |
| POST | `/predict` | Chuyển yêu cầu dự đoán một mẫu dữ liệu. |
| POST | `/predict-batch` | Chuyển yêu cầu dự đoán nhiều mẫu dữ liệu. |
| GET | `/random-sample` | Lấy mẫu dữ liệu ngẫu nhiên phục vụ thử nghiệm. |

Node.js đóng vai trò là lớp Backend trung gian giữa giao diện và dịch vụ Machine Learning.

#### b. `app.py` – Python FastAPI

Đây là thành phần quan trọng chịu trách nhiệm thực hiện các chức năng Machine Learning.

Sử dụng:
- Python.
- FastAPI.
- Scikit-learn.
- NumPy.
- Joblib.
- Pydantic.

Nhiệm vụ chính:

- Tiếp nhận dữ liệu đầu vào từ Node.js.
- Kiểm tra và xác thực cấu trúc dữ liệu.
- Tải các mô hình SVM đã được lưu trữ.
- Huấn luyện mô hình bằng thuật toán `sklearn.svm.SVC`.
- Thực hiện dự đoán loài hoa Iris.
- Tính toán các chỉ số đánh giá mô hình.
- Tạo dữ liệu phục vụ hiển thị Decision Boundary.
- Lưu mô hình sau khi huấn luyện.
- Cập nhật thông tin đánh giá vào `metrics.json`.

Bốn Kernel được hỗ trợ:

| Kernel | Đặc điểm |
|---|---|
| Linear | Phân loại bằng siêu phẳng tuyến tính. |
| RBF | Sử dụng hàm Gaussian để xử lý dữ liệu phi tuyến. |
| Polynomial | Xây dựng ranh giới phân loại dựa trên đa thức. |
| Sigmoid | Sử dụng hàm Sigmoid trong phép biến đổi Kernel. |

#### c. `train.py`

File phục vụ quá trình huấn luyện và xây dựng các mô hình SVM bằng Python.

Các nhiệm vụ bao gồm:

- Tải và xử lý bộ dữ liệu Iris.
- Chuẩn bị dữ liệu đầu vào.
- Chia dữ liệu huấn luyện và kiểm tra.
- Khởi tạo các mô hình SVM.
- Huấn luyện các Kernel.
- Đánh giá hiệu suất.
- Lưu các mô hình đã huấn luyện dưới dạng file `.pkl`.

#### d. Các file mô hình `.pkl`

Hệ thống lưu trữ bốn mô hình SVM:

- `svm_linear.pkl`: Mô hình Linear Kernel.
- `svm_rbf.pkl`: Mô hình RBF Kernel.
- `svm_poly.pkl`: Mô hình Polynomial Kernel.
- `svm_sigmoid.pkl`: Mô hình Sigmoid Kernel.

Các file này được sử dụng bởi Python FastAPI để tải mô hình đã huấn luyện và phục vụ quá trình dự đoán.

### 3.6. Các file dữ liệu và đánh giá

| File | Chức năng |
|---|---|
| `data.json` | Lưu trữ dữ liệu JSON phục vụ ứng dụng. |
| `metadata.json` | Chứa thông tin metadata của dự án hoặc dữ liệu được sử dụng. |
| `metrics.json` | Lưu các chỉ số đánh giá mô hình SVM sau quá trình huấn luyện. |
| `weights.json` | Chứa dữ liệu trọng số và thông tin đánh giá mô hình được sử dụng trong ứng dụng. |

Trong đó, `metrics.json` được Backend sử dụng để cung cấp thông tin đánh giá cho Frontend và phục vụ hiển thị kết quả so sánh.

### 3.7. Cơ sở dữ liệu – Supabase

- `supabase_schema.sql`: File chứa các câu lệnh SQL để khởi tạo và cấu hình cơ sở dữ liệu PostgreSQL trên Supabase.
- `src/supabase.js`: File cấu hình và khởi tạo Supabase Client để Frontend giao tiếp với cơ sở dữ liệu.

Các bảng dữ liệu chính được định nghĩa trong hệ thống:

| Bảng | Chức năng |
|---|---|
| `app_users` | Lưu thông tin tài khoản người dùng như ID, họ tên, email, mật khẩu đã mã hóa và vai trò. |
| `profiles` | Lưu thông tin hồ sơ người dùng, phục vụ quản lý thông tin cá nhân. |
| `user_preferences` | Lưu cấu hình và các tham số SVM của từng người dùng. |
| `prediction_history` | Lưu lịch sử dự đoán của người dùng. |
| `experiment_history` | Lưu thông tin các lần thử nghiệm mô hình SVM. |
| `app_content` | Lưu trữ nội dung phục vụ ứng dụng. |
| `auth_rate_limits` | Hỗ trợ giới hạn tần suất các thao tác xác thực, giảm nguy cơ thử đăng nhập hoặc đăng ký liên tục. |

Ngoài ra, file SQL còn định nghĩa:

- Các hàm đăng ký và đăng nhập.
- Chức năng thay đổi và đặt lại mật khẩu.
- Hàm băm mật khẩu bằng BCrypt.
- Trigger tự động xử lý mật khẩu.
- Các chỉ mục hỗ trợ truy vấn.
- Phân quyền truy cập dữ liệu.
- Cấu hình liên quan đến Supabase Realtime.

**Lưu ý:** `supabase_schema.sql` là file cấu trúc và cấu hình cơ sở dữ liệu. Việc triển khai các bảng, hàm và trigger cần được thực hiện trên dự án Supabase tương ứng.

### 3.8. Các file cấu hình dự án

| File | Chức năng |
|---|---|
| `package.json` | Khai báo thông tin dự án, các thư viện Node.js và những lệnh chạy ứng dụng. |
| `package-lock.json` | Khóa phiên bản các gói npm đã cài đặt. |
| `bun.lock` | File khóa phụ thuộc dành cho Bun. |
| `requirements.txt` | Khai báo các thư viện Python cần thiết cho Machine Learning API. |
| `tsconfig.json` | Cấu hình trình biên dịch TypeScript. |
| `vite.config.ts` | Cấu hình Vite và các plugin cần thiết cho Frontend. |
| `.env.example` | File mẫu khai báo các biến môi trường. |
| `.gitignore` | Quy định những file và thư mục không đưa lên Git. |
| `.python-version` | Xác định phiên bản Python sử dụng trong quá trình triển khai. |
| `index.html` | Trang HTML gốc để khởi tạo ứng dụng React. |
| `render.yaml` | Khai báo cấu hình triển khai các dịch vụ trên Render. |
| `DEPLOY_GUIDE.md` | Hướng dẫn chạy ứng dụng, kiểm thử, đẩy mã nguồn lên GitHub và triển khai trên Render. |

---

## 4. Kiến trúc tổng thể và cách thức hoạt động

Hệ thống được tổ chức thành các thành phần riêng biệt, giúp phân tách giao diện, xử lý nghiệp vụ, huấn luyện mô hình và lưu trữ dữ liệu.

### 4.1. Các thành phần chính

**1. Frontend – React + TypeScript**

Frontend là nơi người dùng tương tác với hệ thống.

Nhiệm vụ:
- Hiển thị giao diện.
- Nhận dữ liệu người dùng nhập vào.
- Gửi yêu cầu đến Backend.
- Hiển thị kết quả dự đoán.
- Hiển thị biểu đồ và các chỉ số đánh giá.
- Quản lý các trang chức năng.

**2. Backend Web – Node.js + Express**

Đây là lớp trung gian tiếp nhận yêu cầu từ Frontend.

Nhiệm vụ:
- Tiếp nhận và xử lý request.
- Điều phối các yêu cầu đến Python API.
- Nhận kết quả từ Python API.
- Trả dữ liệu về Frontend.

**3. Machine Learning API – Python + FastAPI**

Đây là thành phần trực tiếp xử lý thuật toán học máy.

Nhiệm vụ:
- Tiếp nhận dữ liệu từ Backend.
- Huấn luyện mô hình SVM.
- Thực hiện dự đoán.
- Đánh giá mô hình.
- Trả kết quả về Backend.

**4. Database – Supabase**

Đảm nhiệm việc lưu trữ và quản lý dữ liệu.

Nhiệm vụ:
- Quản lý tài khoản người dùng.
- Quản lý thông tin hồ sơ.
- Lưu cấu hình mô hình.
- Lưu lịch sử dự đoán.
- Lưu lịch sử thử nghiệm.

### 4.2. Sơ đồ kiến trúc hệ thống

```text
                 NGƯỜI DÙNG
                      |
                      v
        +---------------------------+
        |         FRONTEND          |
        |      React + TypeScript   |
        |                           |
        |  - Dự đoán Iris            |
        |  - Phân tích file           |
        |  - Trực quan hóa            |
        |  - Thử nghiệm SVM           |
        |  - Benchmark                |
        |  - Lịch sử                  |
        +---------------------------+
                      |
                      | HTTP Request
                      v
        +---------------------------+
        |         BACKEND           |
        |      Node.js + Express    |
        |                           |
        |  - Tiếp nhận yêu cầu       |
        |  - Điều phối xử lý         |
        |  - Chuyển tiếp API         |
        +---------------------------+
                |             |
                |             |
                v             v
    +------------------+  +------------------+
    |  PYTHON FASTAPI  |  |     SUPABASE     |
    |                  |  |                  |
    |  - Huấn luyện    |  |  - Người dùng    |
    |  - Dự đoán       |  |  - Hồ sơ         |
    |  - Đánh giá      |  |  - Cấu hình SVM  |
    |  - Decision      |  |  - Lịch sử       |
    |    Boundary      |  |  - Thử nghiệm    |
    +------------------+  +------------------+
                |
                v
    +------------------+
    |  SVM MODELS      |
    |                  |
    |  - Linear        |
    |  - RBF           |
    |  - Polynomial    |
    |  - Sigmoid       |
    +------------------+
```

### 4.3. Luồng xử lý chức năng dự đoán

Khi người dùng nhập thông số của một mẫu hoa Iris và thực hiện dự đoán, hệ thống hoạt động theo trình tự:

1. Người dùng nhập bốn đặc trưng của hoa trên giao diện Frontend.
2. Frontend kiểm tra dữ liệu đầu vào và gửi yêu cầu HTTP đến Node.js Backend.
3. Node.js tiếp nhận yêu cầu tại API `/predict`.
4. Backend chuyển tiếp dữ liệu đến Python FastAPI.
5. Python API lựa chọn mô hình SVM tương ứng với Kernel được yêu cầu.
6. Mô hình thực hiện dự đoán dựa trên bốn đặc trưng đầu vào.
7. Python API trả về kết quả dự đoán cho Node.js.
8. Node.js nhận kết quả và phản hồi cho Frontend.
9. Frontend hiển thị loài hoa được dự đoán và các thông tin liên quan.

### 4.4. Luồng xử lý huấn luyện mô hình

Đối với chức năng huấn luyện:

1. Người dùng lựa chọn Kernel SVM.
2. Người dùng nhấn nút huấn luyện trên giao diện.
3. Frontend gửi yêu cầu đến Backend thông qua API `/train`.
4. Node.js chuyển tiếp yêu cầu đến Python FastAPI.
5. Python sử dụng Scikit-learn để huấn luyện mô hình SVC.
6. Dữ liệu được chia thành tập huấn luyện và tập kiểm tra.
7. Mô hình được đánh giá bằng các chỉ số như Accuracy, Precision, Recall, F1-score và Confusion Matrix.
8. Mô hình sau huấn luyện được lưu thành file `.pkl`.
9. Các thông tin đánh giá được cập nhật vào `metrics.json`.
10. Python trả kết quả về Node.js và Frontend hiển thị kết quả.

Việc huấn luyện chỉ được thực hiện khi người dùng chủ động nhấn nút huấn luyện, không tự động chạy khi chuyển trang.

---

## 5. Chức năng chính của hệ thống

### 5.1. Nhận diện hoa Iris

- Nhập bốn đặc trưng của hoa.
- Gửi dữ liệu đến mô hình SVM.
- Lựa chọn Kernel phù hợp.
- Hiển thị kết quả phân loại.
- Xác định một trong ba loài hoa:
  - Iris Setosa.
  - Iris Versicolor.
  - Iris Virginica.

### 5.2. Dự đoán và kiểm tra kết quả

Cho phép người dùng tự đưa ra dự đoán về loài hoa trước khi sử dụng mô hình SVM.

Sau đó hệ thống thực hiện dự đoán và so sánh kết quả giữa người dùng và mô hình.

### 5.3. Phân tích dữ liệu từ file

- Tiếp nhận dữ liệu từ file đầu vào.
- Đọc các thông số của từng mẫu hoa.
- Thực hiện dự đoán trên nhiều mẫu.
- So sánh nhãn dự đoán với nhãn thực tế nếu dữ liệu có cung cấp.
- Tổng hợp kết quả phân tích.

### 5.4. Trực quan hóa dữ liệu

Cung cấp các biểu đồ giúp người dùng quan sát đặc điểm của bộ dữ liệu Iris, mối quan hệ giữa các thuộc tính và kết quả phân loại.

### 5.5. SVM Playground

Cung cấp môi trường thử nghiệm thuật toán SVM.

Người dùng có thể thay đổi cấu hình và tham số mô hình để quan sát sự thay đổi trong kết quả phân loại.

### 5.6. Quản lý thử nghiệm

- Lưu lại thông tin các lần thử nghiệm.
- Theo dõi Kernel được sử dụng.
- Theo dõi các tham số cấu hình.
- Xem lại Accuracy và số lượng Support Vectors.
- So sánh kết quả giữa các lần thử nghiệm.

### 5.7. Benchmark – Đánh giá mô hình

Hỗ trợ đánh giá và so sánh bốn Kernel SVM thông qua các chỉ số:

- Accuracy.
- Precision.
- Recall.
- F1-score.
- Confusion Matrix.
- Support Vectors.
- Thời gian huấn luyện.

### 5.8. Lịch sử hoạt động

Lưu và hiển thị thông tin các lần dự đoán, bao gồm:

- Thời gian thực hiện.
- Bốn đặc trưng đầu vào.
- Loài hoa được dự đoán.
- Thông tin kết quả.
- Phương thức thực hiện dự đoán.

---

## 6. Cài đặt và chạy dự án trên máy tính cá nhân

### 6.1. Yêu cầu môi trường

Cài đặt các công cụ sau:

- Node.js phiên bản từ 22.12 trở lên.
- npm.
- Python 3.11.
- Git.
- Tài khoản Supabase nếu sử dụng cơ sở dữ liệu trực tuyến.

### 6.2. Cài đặt thư viện Frontend và Backend

Mở Terminal tại thư mục `Iris-SVM-Updated` và thực hiện:

```bash
npm install
```

Lệnh này cài đặt các thư viện được khai báo trong `package.json`.

### 6.3. Cài đặt thư viện Python

Tạo môi trường ảo:

```bash
python -m venv .venv
```

Kích hoạt môi trường ảo trên Windows:

```powershell
.venv\Scripts\activate
```

Cài đặt các thư viện:

```bash
pip install -r requirements.txt
```

### 6.4. Cấu hình biến môi trường

Tạo file `.env` tại thư mục gốc dự án dựa trên `.env.example`.

Nội dung mẫu:

```env
VITE_SUPABASE_URL=YOUR_SUPABASE_URL
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

SVM_API_URL=http://127.0.0.1:8000
```

Trong đó:

- `VITE_SUPABASE_URL`: URL dự án Supabase.
- `VITE_SUPABASE_ANON_KEY`: Khóa truy cập công khai của Supabase.
- `SVM_API_URL`: Địa chỉ Python FastAPI.

Không đưa các khóa bí mật hoặc thông tin xác thực quản trị lên GitHub.

### 6.5. Khởi chạy Python FastAPI

Mở cửa sổ Terminal thứ nhất:

```bash
uvicorn app:app --host 127.0.0.1 --port 8000
```

Sau khi khởi chạy thành công, Python API hoạt động tại:

```text
http://127.0.0.1:8000
```

Kiểm tra trạng thái:

```text
http://127.0.0.1:8000/health
```

Kiểm tra thông tin đánh giá:

```text
http://127.0.0.1:8000/metrics
```

Có thể truy cập tài liệu API tự động của FastAPI tại:

```text
http://127.0.0.1:8000/docs
```

### 6.6. Khởi chạy ứng dụng Web

Mở cửa sổ Terminal thứ hai tại thư mục dự án:

```bash
npm run dev
```

Sau khi khởi chạy thành công, mở địa chỉ được hiển thị trên Terminal, thông thường:

```text
http://localhost:3000
```

**Lưu ý:** Không mở trực tiếp file `index.html` bằng trình duyệt theo dạng `file:///...`. Cần khởi chạy ứng dụng thông qua máy chủ Node.js để các module, API và CSS hoạt động đúng.

---

## 7. Triển khai hệ thống trên Render

Dự án sử dụng file `render.yaml` để cấu hình triển khai các dịch vụ trên Render.

Hệ thống được triển khai thành hai Web Service độc lập:

### 7.1. Frontend và Node.js Backend

Tên dịch vụ:

```text
iris-svm
```

Cấu hình:

- Runtime: Node.
- Build Command:

```bash
npm install && npm run build
```

- Start Command:

```bash
npm start
```

- Health Check Path:

```text
/health
```

Dịch vụ này chịu trách nhiệm phục vụ giao diện và xử lý các yêu cầu từ người dùng.

### 7.2. Python Machine Learning API

Tên dịch vụ:

```text
iris-svm-api
```

Cấu hình:

- Runtime: Python.
- Build Command:

```bash
pip install -r requirements.txt
```

- Start Command:

```bash
uvicorn app:app --host 0.0.0.0 --port $PORT
```

- Health Check Path:

```text
/health
```

Dịch vụ này chịu trách nhiệm huấn luyện, dự đoán và đánh giá các mô hình SVM.

### 7.3. Kết nối hai dịch vụ

Trong `render.yaml`, biến môi trường `SVM_API_HOST` của dịch vụ Node.js được cấu hình tham chiếu đến dịch vụ `iris-svm-api`.

Nhờ đó, Node.js có thể chuyển tiếp các yêu cầu đến Python API thông qua địa chỉ dịch vụ nội bộ.

---

## 8. Kiểm thử hệ thống

Sau khi cài đặt và khởi chạy, cần kiểm tra các chức năng sau:

| STT | Nội dung kiểm thử | Kết quả mong đợi |
|---|---|---|
| 1 | Khởi chạy Frontend | Website hiển thị bình thường. |
| 2 | Kiểm tra Backend | API `/health` phản hồi thành công. |
| 3 | Kiểm tra Python API | FastAPI hoạt động và tải được các mô hình. |
| 4 | Dự đoán một mẫu Iris | Trả về đúng định dạng kết quả dự đoán. |
| 5 | Huấn luyện Linear | Mô hình Linear được huấn luyện và trả kết quả. |
| 6 | Huấn luyện RBF | Mô hình RBF được huấn luyện và trả kết quả. |
| 7 | Huấn luyện Polynomial | Mô hình Polynomial được huấn luyện và trả kết quả. |
| 8 | Huấn luyện Sigmoid | Mô hình Sigmoid được huấn luyện và trả kết quả. |
| 9 | Phân tích file | Hệ thống đọc và phân tích nhiều mẫu dữ liệu. |
| 10 | Benchmark | Hiển thị các chỉ số đánh giá mô hình. |
| 11 | Lịch sử | Hiển thị thông tin các lần sử dụng đã được lưu. |
| 12 | Supabase | Kiểm tra kết nối và khả năng truy vấn dữ liệu. |

---

## 9. Tổng kết

Dự án Iris SVM được xây dựng nhằm ứng dụng thuật toán Support Vector Machine vào bài toán phân loại dữ liệu hoa Iris.

Hệ thống kết hợp các công nghệ React, TypeScript, Node.js, Express, Python, FastAPI, Scikit-learn và Supabase để hình thành một nền tảng có khả năng dự đoán, huấn luyện, phân tích, trực quan hóa và đánh giá mô hình học máy.

Việc phân tách Frontend, Backend Web, Machine Learning API và cơ sở dữ liệu thành các thành phần riêng biệt giúp hệ thống dễ quản lý, bảo trì và mở rộng trong tương lai.

Bên cạnh chức năng phân loại hoa Iris, dự án còn cung cấp môi trường thực nghiệm để người dùng tìm hiểu và so sánh hiệu suất của các loại Kernel trong thuật toán SVM.

---

**Tên dự án:** Iris SVM Platform  
**Thuật toán chính:** Support Vector Machine (SVM)  
**Số lượng Kernel:** 4  
**Bài toán:** Phân loại hoa Iris  
**Frontend:** React + TypeScript  
**Backend:** Node.js + Express  
**Machine Learning API:** Python + FastAPI + Scikit-learn  
**Database:** Supabase (PostgreSQL)  
**Deployment:** Render
