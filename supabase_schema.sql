-- =====================================================================
-- IRIS SVM - HỆ THỐNG CƠ SỞ DỮ LIỆU ĐƠN GIẢN HÓA (100% KHÔNG CẦN XÁC MINH EMAIL)
-- Đăng ký: Lưu tên, email, mật khẩu (đã mã hoá BCrypt) vào CSDL qua hàm register_user.
-- Đăng nhập: Hàm login_user đối chiếu email + mật khẩu với bản băm BCrypt trong CSDL.
-- Đổi mật khẩu: hàm change_password (email + mật khẩu hiện tại + mật khẩu mới).
-- Quên mật khẩu: hàm reset_password_by_email (chỉ cần email + mật khẩu mới).
-- Không gửi email, không gọi dịch vụ ngoài. Có thể chạy lại script nhiều lần an toàn.
-- Hướng dẫn: Mở Supabase Dashboard -> SQL Editor -> Dán toàn bộ script này -> Nhấn "RUN"
-- =====================================================================

-- 1. BẬT TIỆN ÍCH MỞ RỘNG (EXTENSIONS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- 2. DỌN DẸP CÁC TRIGGER CŨ TRÊN auth.users ĐỂ TRÁNH LỖI PHỤ THUỘC
-- =====================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS tr_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS user_created_trigger ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- =====================================================================
-- 3. BẢNG APP_USERS (BẢNG TÀI KHOẢN NGƯỜI DÙNG ĐƠN GIẢN HÓA)
-- Lưu trực tiếp: Họ tên, Email, Mật khẩu, Vai trò
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.app_users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'USER' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================================
-- 4. BẢNG PROFILES (TƯƠNG THÍCH DỮ LIỆU CŨ)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    password TEXT,
    role TEXT DEFAULT 'USER' NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Bổ sung cột password vào profiles nếu bảng đã có từ trước
DO $$ BEGIN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS password TEXT;
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- =====================================================================
-- 5. BẢNG USER_PREFERENCES (CẤU HÌNH THAM SỐ SVM)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    selected_kernel TEXT DEFAULT 'linear' NOT NULL,
    selected_c NUMERIC DEFAULT 1.0 NOT NULL,
    selected_gamma NUMERIC DEFAULT 0.1 NOT NULL,
    selected_degree INT DEFAULT 3 NOT NULL,
    selected_features JSONB DEFAULT '["Petal Length", "Petal Width"]'::jsonb NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================================
-- 6. BẢNG PREDICTION_HISTORY (LỊCH SỬ DỰ ĐOÁN HOA)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.prediction_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    sepal_length NUMERIC NOT NULL,
    sepal_width NUMERIC NOT NULL,
    petal_length NUMERIC NOT NULL,
    petal_width NUMERIC NOT NULL,
    prediction TEXT NOT NULL,
    confidence NUMERIC DEFAULT 100.0,
    method TEXT DEFAULT 'Nhập số liệu' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

DO $$ BEGIN
    ALTER TABLE public.prediction_history DROP CONSTRAINT IF EXISTS prediction_history_user_id_fkey;
    ALTER TABLE public.prediction_history ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    ALTER TABLE public.prediction_history ALTER COLUMN user_id DROP NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- =====================================================================
-- 7. BẢNG EXPERIMENT_HISTORY (LỊCH SỬ HUẤN LUYỆN & BENCHMARK)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.experiment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    name TEXT DEFAULT 'Huấn luyện SVM' NOT NULL,
    kernel TEXT NOT NULL,
    c_param NUMERIC NOT NULL,
    gamma_param NUMERIC NOT NULL,
    degree INT DEFAULT 3,
    features JSONB NOT NULL DEFAULT '["Petal Length", "Petal Width"]'::jsonb,
    feature_indices JSONB NOT NULL DEFAULT '{"sl": 5.1, "sw": 3.5, "pl": 1.4, "pw": 0.2}'::jsonb,
    accuracy NUMERIC NOT NULL,
    train_accuracy NUMERIC,
    precision NUMERIC DEFAULT 0.967,
    recall NUMERIC DEFAULT 0.967,
    f1_score NUMERIC DEFAULT 0.967,
    support_vector_count INT DEFAULT 0,
    execution_time_ms NUMERIC NOT NULL DEFAULT 1.0,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

DO $$ BEGIN
    ALTER TABLE public.experiment_history DROP CONSTRAINT IF EXISTS experiment_history_user_id_fkey;
    ALTER TABLE public.experiment_history ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    ALTER TABLE public.experiment_history ALTER COLUMN user_id DROP NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- =====================================================================
-- 8. BẢNG APP_CONTENT (QUẢN LÝ NỘI DUNG VÀ HƯỚNG DẪN)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.app_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    updated_by TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================================
-- 9. TẠO INDEXES TỐI ƯU HIỆU SUẤT TRUY VẤN
-- =====================================================================
CREATE INDEX IF NOT EXISTS idx_app_users_email ON public.app_users(email);
CREATE INDEX IF NOT EXISTS idx_pred_user_id ON public.prediction_history(user_id);
CREATE INDEX IF NOT EXISTS idx_pred_created_at ON public.prediction_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exp_user_id ON public.experiment_history(user_id);
CREATE INDEX IF NOT EXISTS idx_exp_kernel ON public.experiment_history(kernel);
CREATE INDEX IF NOT EXISTS idx_exp_created_at ON public.experiment_history(created_at DESC);

-- =====================================================================
-- 10. TẮT HOÀN TOÀN ROW LEVEL SECURITY (RLS) ĐỂ KHÔNG BỊ CHẶN QUYỀN
-- =====================================================================
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname, tablename 
        FROM pg_policies 
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

ALTER TABLE public.app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.experiment_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_content DISABLE ROW LEVEL SECURITY;

-- Cấp toàn quyền thực thi cho ứng dụng Web
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- =====================================================================
-- 11. BẬT SUPABASE REALTIME (TỰ ĐỘNG ĐỒNG BỘ DỮ LIỆU)
-- =====================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_users;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.prediction_history;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.experiment_history;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION WHEN others THEN null;
END $$;

-- =====================================================================
-- 12. TẠO SẴN TÀI KHOẢN ADMIN MẪU (AN TOÀN TUYỆT ĐỐI KHÔNG BỊ TRÙNG ID/EMAIL)
-- Email: lethao8130@gmail.com (hoặc admin@gmail.com) | Mật khẩu: admin
-- =====================================================================
-- Chỉ tạo admin nếu chưa tồn tại: chạy lại script KHÔNG reset mật khẩu admin về 'admin'.
DO $$ BEGIN
    INSERT INTO public.app_users (id, name, email, password, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Lê Thanh Thảo', 'lethao8130@gmail.com', 'admin', 'ADMIN')
    ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    INSERT INTO public.profiles (id, email, full_name, password, role)
    VALUES ('00000000-0000-0000-0000-000000000001', 'lethao8130@gmail.com', 'Lê Thanh Thảo', 'admin', 'ADMIN')
    ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Dữ liệu nội dung hướng dẫn
INSERT INTO public.app_content (key, title, content)
VALUES 
(
    'about_app',
    'Giới thiệu hệ thống Iris SVM',
    'Website phân loại hoa Iris bằng mô hình SVM (Support Vector Machine) chuyên sâu. Hệ thống cung cấp khả năng tự động nhận diện 4 đặc trưng, trực quan hóa ranh giới quyết định (Decision Boundary), huấn luyện đa Kernel (Linear, RBF, Poly, Sigmoid), lưu trữ thí nghiệm và so sánh Benchmark hiệu năng thuật toán.'
)
ON CONFLICT (key) DO NOTHING;

-- =========================================================
-- 13. BẢO MẬT MẬT KHẨU BẰNG BCRYPT
-- =========================================================

-- Hàm tự động băm mật khẩu
CREATE OR REPLACE FUNCTION public.hash_user_password()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
    -- Chỉ xử lý khi thêm mới hoặc mật khẩu thực sự thay đổi
    IF TG_OP = 'INSERT'
       OR NEW.password IS DISTINCT FROM OLD.password THEN

        -- Không băm lại nếu mật khẩu đã ở dạng BCrypt
        IF NEW.password IS NOT NULL
           AND NEW.password NOT LIKE '$2a$%'
           AND NEW.password NOT LIKE '$2b$%'
           AND NEW.password NOT LIKE '$2y$%' THEN

            NEW.password := crypt(NEW.password, gen_salt('bf', 12));

        END IF;
    END IF;

    RETURN NEW;
END;
$$;


-- Tự động băm mật khẩu trong bảng app_users
DROP TRIGGER IF EXISTS trg_hash_app_users_password
ON public.app_users;

CREATE TRIGGER trg_hash_app_users_password
BEFORE INSERT OR UPDATE OF password
ON public.app_users
FOR EACH ROW
EXECUTE FUNCTION public.hash_user_password();


-- Tự động băm mật khẩu trong bảng profiles
DROP TRIGGER IF EXISTS trg_hash_profiles_password
ON public.profiles;

CREATE TRIGGER trg_hash_profiles_password
BEFORE INSERT OR UPDATE OF password
ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.hash_user_password();


-- =========================================================
-- 14. CHUYỂN MẬT KHẨU CŨ (DẠNG THÔ) SANG BCRYPT
-- Băm trực tiếp bằng crypt() (trigger bỏ qua UPDATE không đổi giá trị nên không dùng được ở đây).
-- Chạy lại nhiều lần vẫn an toàn: bản ghi đã là BCrypt sẽ được bỏ qua.
-- =========================================================

UPDATE public.app_users
SET password = extensions.crypt(password, extensions.gen_salt('bf', 12))
WHERE password IS NOT NULL
  AND password !~ '^\$2[aby]\$';

UPDATE public.profiles
SET password = extensions.crypt(password, extensions.gen_salt('bf', 12))
WHERE password IS NOT NULL
  AND password !~ '^\$2[aby]\$';


-- =========================================================
-- 15. HÀM KIỂM TRA MẬT KHẨU KHI ĐĂNG NHẬP
-- =========================================================

CREATE OR REPLACE FUNCTION public.verify_user_password(
    p_email TEXT,
    p_password TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    stored_password TEXT;
BEGIN
    SELECT password
    INTO stored_password
    FROM public.app_users
    WHERE email = LOWER(TRIM(p_email));

    IF stored_password IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN stored_password = crypt(p_password, stored_password);
END;
$$;

-- Hàm này chỉ dùng nội bộ / từ SQL Editor. KHÔNG cho anon gọi trực tiếp
-- (vì không có giới hạn số lần thử). Web đăng nhập qua login_user ở mục 17.
REVOKE ALL ON FUNCTION public.verify_user_password(TEXT, TEXT)
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 16. GIỚI HẠN SỐ LẦN NHẬP SAI (CHỐNG DÒ MẬT KHẨU)
-- Sai 5 lần trong 15 phút -> khoá thao tác đó 15 phút cho email tương ứng.
-- Bảng này chỉ các hàm SECURITY DEFINER bên dưới được đọc/ghi; anon không truy cập được.
-- =========================================================
CREATE TABLE IF NOT EXISTS public.auth_rate_limits (
    email         TEXT NOT NULL,
    action        TEXT NOT NULL,            -- 'pw' (đăng nhập + đổi mật khẩu) | 'reset' (quên mật khẩu, giới hạn tần suất)
    fail_count    INT  NOT NULL DEFAULT 0,
    first_fail_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_until  TIMESTAMPTZ,
    PRIMARY KEY (email, action)
);

-- Số phút còn bị khoá (0 = không bị khoá)
CREATE OR REPLACE FUNCTION public._auth_lock_minutes(p_email TEXT, p_action TEXT)
RETURNS INT
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE(
        (SELECT CEIL(EXTRACT(EPOCH FROM (locked_until - NOW())) / 60)::INT
         FROM public.auth_rate_limits
         WHERE email = p_email AND action = p_action AND locked_until > NOW()),
        0);
$$;

-- Ghi nhận 1 lần sai
CREATE OR REPLACE FUNCTION public._auth_register_fail(p_email TEXT, p_action TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    r public.auth_rate_limits%ROWTYPE;
    v_count INT;
BEGIN
    -- Dọn bản ghi cũ để bảng không phình to
    DELETE FROM public.auth_rate_limits
    WHERE first_fail_at < NOW() - INTERVAL '1 day'
      AND (locked_until IS NULL OR locked_until < NOW());

    SELECT * INTO r FROM public.auth_rate_limits
    WHERE email = p_email AND action = p_action
    FOR UPDATE;

    IF NOT FOUND OR r.first_fail_at < NOW() - INTERVAL '15 minutes' THEN
        v_count := 1;
        INSERT INTO public.auth_rate_limits (email, action, fail_count, first_fail_at, locked_until)
        VALUES (p_email, p_action, 1, NOW(), NULL)
        ON CONFLICT (email, action)
        DO UPDATE SET fail_count = 1, first_fail_at = NOW(), locked_until = NULL;
    ELSE
        v_count := r.fail_count + 1;
        UPDATE public.auth_rate_limits SET fail_count = v_count
        WHERE email = p_email AND action = p_action;
    END IF;

    IF v_count >= 5 THEN
        UPDATE public.auth_rate_limits
        SET locked_until = NOW() + INTERVAL '15 minutes'
        WHERE email = p_email AND action = p_action;
    END IF;
END;
$$;

-- Xoá bộ đếm khi thao tác thành công
CREATE OR REPLACE FUNCTION public._auth_clear_fail(p_email TEXT, p_action TEXT)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    DELETE FROM public.auth_rate_limits WHERE email = p_email AND action = p_action;
$$;

-- =========================================================
-- 17. CÁC HÀM BACKEND CHO WEB (GỌI QUA supabase.rpc)
-- Mật khẩu luôn được băm BCrypt (cost 12) ngay trong CSDL; web không bao giờ đọc được mật khẩu/bản băm.
-- Mỗi hàm trả về jsonb: {ok: true, ...} hoặc {ok: false, code: '...'}
-- Lưu ý: BCrypt chỉ dùng 72 ký tự đầu của mật khẩu nên giới hạn tối đa 72.
-- =========================================================

-- 17.1 ĐĂNG KÝ
CREATE OR REPLACE FUNCTION public.register_user(p_name TEXT, p_email TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_email TEXT := LOWER(TRIM(COALESCE(p_email, '')));
    v_name  TEXT := TRIM(COALESCE(p_name, ''));
    v_hash  TEXT;
    v_id    TEXT;
    v_role  TEXT;
    v_created TIMESTAMPTZ;
BEGIN
    IF v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' OR LENGTH(v_email) > 254 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_input');
    END IF;
    IF v_name = '' THEN v_name := SPLIT_PART(v_email, '@', 1); END IF;
    IF LENGTH(v_name) > 100 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_input');
    END IF;
    IF p_password IS NULL OR LENGTH(p_password) < 5 OR LENGTH(p_password) > 72 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'weak_password');
    END IF;

    IF EXISTS (SELECT 1 FROM public.app_users WHERE LOWER(email) = v_email) THEN
        RETURN jsonb_build_object('ok', false, 'code', 'email_exists');
    END IF;

    -- Vai trò do SERVER quyết định, không tin dữ liệu từ trình duyệt
    v_role := CASE WHEN v_email IN ('admin@gmail.com', 'huylechill@gmail.com') THEN 'ADMIN' ELSE 'USER' END;
    v_hash := crypt(p_password, gen_salt('bf', 12));
    v_id   := 'u_' || (EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000)::BIGINT::TEXT || SUBSTR(MD5(RANDOM()::TEXT), 1, 4);

    BEGIN
        INSERT INTO public.app_users (id, name, email, password, role)
        VALUES (v_id, v_name, v_email, v_hash, v_role)
        RETURNING created_at INTO v_created;
    EXCEPTION WHEN unique_violation THEN
        RETURN jsonb_build_object('ok', false, 'code', 'email_exists');
    END;

    -- Đồng bộ bảng profiles (tương thích dữ liệu cũ); lỗi ở đây không làm hỏng đăng ký
    BEGIN
        INSERT INTO public.profiles (id, email, full_name, password, role)
        VALUES (v_id, v_email, v_name, v_hash, v_role);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    RETURN jsonb_build_object('ok', true, 'user', jsonb_build_object(
        'id', v_id, 'name', v_name, 'email', v_email, 'role', v_role, 'created_at', v_created));
END;
$$;

-- 17.2 ĐĂNG NHẬP: đối chiếu mật khẩu nhập với bản băm BCrypt
CREATE OR REPLACE FUNCTION public.login_user(p_email TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_email TEXT := LOWER(TRIM(COALESCE(p_email, '')));
    v_user  public.app_users%ROWTYPE;
    v_wait  INT;
BEGIN
    IF v_email = '' OR LENGTH(v_email) > 254
       OR COALESCE(p_password, '') = '' OR LENGTH(p_password) > 72 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_input');
    END IF;

    v_wait := public._auth_lock_minutes(v_email, 'pw');
    IF v_wait > 0 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'locked', 'retry_minutes', v_wait);
    END IF;

    SELECT * INTO v_user FROM public.app_users WHERE LOWER(email) = v_email LIMIT 1;

    IF NOT FOUND THEN
        PERFORM crypt(p_password, gen_salt('bf', 12));   -- giữ thời gian xử lý như khi có tài khoản
        PERFORM public._auth_register_fail(v_email, 'pw');
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_credentials');
    END IF;

    IF v_user.password !~ '^\$2[aby]\$' OR v_user.password <> crypt(p_password, v_user.password) THEN
        PERFORM public._auth_register_fail(v_email, 'pw');
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_credentials');
    END IF;

    PERFORM public._auth_clear_fail(v_email, 'pw');
    RETURN jsonb_build_object('ok', true, 'user', jsonb_build_object(
        'id', v_user.id, 'name', v_user.name, 'email', v_user.email,
        'role', v_user.role, 'created_at', v_user.created_at));
END;
$$;

-- 17.3 ĐỔI MẬT KHẨU (đã nhớ mật khẩu hiện tại)
CREATE OR REPLACE FUNCTION public.change_password(p_email TEXT, p_current_password TEXT, p_new_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_email TEXT := LOWER(TRIM(COALESCE(p_email, '')));
    v_user  public.app_users%ROWTYPE;
    v_hash  TEXT;
    v_wait  INT;
BEGIN
    IF v_email = '' OR LENGTH(v_email) > 254
       OR COALESCE(p_current_password, '') = '' OR LENGTH(p_current_password) > 72 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_input');
    END IF;
    IF p_new_password IS NULL OR LENGTH(p_new_password) < 8 OR LENGTH(p_new_password) > 72 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'weak_password');
    END IF;
    IF p_new_password = p_current_password THEN
        RETURN jsonb_build_object('ok', false, 'code', 'same_password');
    END IF;

    v_wait := public._auth_lock_minutes(v_email, 'pw');
    IF v_wait > 0 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'locked', 'retry_minutes', v_wait);
    END IF;

    SELECT * INTO v_user FROM public.app_users WHERE LOWER(email) = v_email LIMIT 1;

    IF NOT FOUND THEN
        PERFORM crypt(p_current_password, gen_salt('bf', 12));
        PERFORM public._auth_register_fail(v_email, 'pw');
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_credentials');
    END IF;

    IF v_user.password !~ '^\$2[aby]\$' OR v_user.password <> crypt(p_current_password, v_user.password) THEN
        PERFORM public._auth_register_fail(v_email, 'pw');
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_credentials');
    END IF;

    v_hash := crypt(p_new_password, gen_salt('bf', 12));
    UPDATE public.app_users SET password = v_hash WHERE id = v_user.id;
    UPDATE public.profiles  SET password = v_hash, updated_at = NOW() WHERE LOWER(email) = v_email;

    PERFORM public._auth_clear_fail(v_email, 'pw');
    RETURN jsonb_build_object('ok', true);
END;
$$;

-- 17.4 QUÊN MẬT KHẨU (không gửi email, không cần mật khẩu cũ):
-- chỉ cần email của tài khoản + mật khẩu mới.
-- Giới hạn 5 lần đặt lại / 15 phút cho mỗi email để tránh bị spam.
DROP FUNCTION IF EXISTS public.reset_password_by_identity(TEXT, TEXT, TEXT);  -- hàm bản trước (có họ tên)

CREATE OR REPLACE FUNCTION public.reset_password_by_email(p_email TEXT, p_new_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_email TEXT := LOWER(TRIM(COALESCE(p_email, '')));
    v_user  public.app_users%ROWTYPE;
    v_hash  TEXT;
    v_wait  INT;
BEGIN
    IF v_email = '' OR LENGTH(v_email) > 254 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'invalid_input');
    END IF;
    IF p_new_password IS NULL OR LENGTH(p_new_password) < 8 OR LENGTH(p_new_password) > 72 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'weak_password');
    END IF;

    v_wait := public._auth_lock_minutes(v_email, 'reset');
    IF v_wait > 0 THEN
        RETURN jsonb_build_object('ok', false, 'code', 'locked', 'retry_minutes', v_wait);
    END IF;

    -- Mỗi lần gọi đều được đếm (kể cả thành công) để giới hạn tần suất
    PERFORM public._auth_register_fail(v_email, 'reset');

    SELECT * INTO v_user FROM public.app_users WHERE LOWER(email) = v_email LIMIT 1;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('ok', false, 'code', 'email_not_found');
    END IF;

    v_hash := crypt(p_new_password, gen_salt('bf', 12));
    UPDATE public.app_users SET password = v_hash WHERE id = v_user.id;
    UPDATE public.profiles  SET password = v_hash, updated_at = NOW() WHERE LOWER(email) = v_email;

    PERFORM public._auth_clear_fail(v_email, 'pw');   -- mở khoá đăng nhập nếu đang bị khoá
    RETURN jsonb_build_object('ok', true);
END;
$$;

-- =========================================================
-- 18. KHOÁ QUYỀN TRUY CẬP TRỰC TIẾP VÀO MẬT KHẨU
-- Trước đây GRANT ALL cho anon nên ai có anon key cũng đọc/ghi được cột password.
-- Từ giờ: web chỉ được ĐỌC các cột không nhạy cảm; mọi thao tác mật khẩu đi qua hàm ở mục 17.
-- (Mục này đặt ở cuối để luôn có hiệu lực sau lệnh GRANT ALL ở mục 10 khi chạy lại script.)
-- =========================================================
REVOKE ALL ON public.app_users FROM anon, authenticated;
GRANT SELECT (id, name, email, role, created_at) ON public.app_users TO anon, authenticated;

REVOKE ALL ON public.profiles FROM anon, authenticated;
GRANT SELECT (id, email, full_name, role, avatar_url, created_at, updated_at) ON public.profiles TO anon, authenticated;

REVOKE ALL ON public.auth_rate_limits FROM PUBLIC, anon, authenticated;
ALTER TABLE public.auth_rate_limits ENABLE ROW LEVEL SECURITY;   -- không có policy = anon không thấy gì

-- Hàm nội bộ: chỉ các hàm SECURITY DEFINER gọi
REVOKE ALL ON FUNCTION public._auth_lock_minutes(TEXT, TEXT)  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._auth_register_fail(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._auth_clear_fail(TEXT, TEXT)    FROM PUBLIC, anon, authenticated;

-- Hàm công khai cho web
REVOKE ALL ON FUNCTION public.register_user(TEXT, TEXT, TEXT)                 FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.login_user(TEXT, TEXT)                          FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.change_password(TEXT, TEXT, TEXT)               FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reset_password_by_email(TEXT, TEXT)             FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_user(TEXT, TEXT, TEXT)              TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.login_user(TEXT, TEXT)                       TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.change_password(TEXT, TEXT, TEXT)            TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_password_by_email(TEXT, TEXT)          TO anon, authenticated;

-- Realtime: không phát cột password (bản băm) ra kênh realtime.
-- Dùng danh sách cột (PostgreSQL 15+); nếu không hỗ trợ thì gỡ bảng khỏi realtime cho an toàn.
DO $$ BEGIN
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.app_users';
    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.app_users (id, name, email, role, created_at)';
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.profiles';
    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles (id, email, full_name, role, avatar_url, created_at, updated_at)';
    EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- Báo cho API Supabase nạp lại danh sách hàm mới
NOTIFY pgrst, 'reload schema';
