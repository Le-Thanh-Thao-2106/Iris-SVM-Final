-- =====================================================================
-- IRIS SVM - CƠ SỞ DỮ LIỆU GỌN (chỉ giữ các bảng ứng dụng thực sự dùng)
--   app_users          : tài khoản (tên, email, mật khẩu BCrypt, vai trò)
--   prediction_history : lịch sử dự đoán hoa
--   experiment_history : lịch sử huấn luyện / benchmark SVM
--   auth_rate_limits   : đếm số lần nhập sai (chống dò mật khẩu), web không truy cập được
-- Đăng ký / đăng nhập / đổi mật khẩu / quên mật khẩu đều chạy bằng hàm trong CSDL
-- (register_user, login_user, change_password, reset_password_by_email), không gửi email.
-- Hướng dẫn: Supabase Dashboard -> SQL Editor -> dán toàn bộ -> RUN. Chạy lại nhiều lần an toàn.
-- =====================================================================

-- 1. Tiện ích mã hoá + dọn trigger cũ của kiểu đăng nhập bằng Supabase Auth
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- =====================================================================
-- 2. CÁC BẢNG
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.app_users (
    id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name       TEXT NOT NULL,
    email      TEXT UNIQUE NOT NULL,
    password   TEXT NOT NULL,                       -- luôn là bản băm BCrypt
    role       TEXT DEFAULT 'USER' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.prediction_history (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      TEXT,
    sepal_length NUMERIC NOT NULL,
    sepal_width  NUMERIC NOT NULL,
    petal_length NUMERIC NOT NULL,
    petal_width  NUMERIC NOT NULL,
    prediction   TEXT NOT NULL,
    confidence   NUMERIC DEFAULT 100.0,
    method       TEXT DEFAULT 'Nhập số liệu' NOT NULL,
    created_at   TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.experiment_history (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              TEXT,
    name                 TEXT DEFAULT 'Huấn luyện SVM' NOT NULL,
    kernel               TEXT NOT NULL,
    c_param              NUMERIC NOT NULL,
    gamma_param          NUMERIC,                   -- NULL khi gamma = 'scale'
    degree               INT DEFAULT 3,
    features             JSONB NOT NULL DEFAULT '["Petal Length", "Petal Width"]'::jsonb,
    feature_indices      JSONB NOT NULL DEFAULT '{"sl": 5.1, "sw": 3.5, "pl": 1.4, "pw": 0.2}'::jsonb,
    accuracy             NUMERIC NOT NULL,
    train_accuracy       NUMERIC,
    precision            NUMERIC DEFAULT 0.967,
    recall               NUMERIC DEFAULT 0.967,
    f1_score             NUMERIC DEFAULT 0.967,
    support_vector_count INT DEFAULT 0,
    execution_time_ms    NUMERIC NOT NULL DEFAULT 1.0,
    note                 TEXT,
    created_at           TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.auth_rate_limits (
    email         TEXT NOT NULL,
    action        TEXT NOT NULL,            -- 'pw' (đăng nhập + đổi mật khẩu) | 'reset' (quên mật khẩu)
    fail_count    INT  NOT NULL DEFAULT 0,
    first_fail_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_until  TIMESTAMPTZ,
    PRIMARY KEY (email, action)
);

-- Nâng cấp CSDL cũ: user_id về TEXT, bỏ khoá ngoại, cho phép gamma_param NULL
DO $$ BEGIN
    ALTER TABLE public.prediction_history DROP CONSTRAINT IF EXISTS prediction_history_user_id_fkey;
    ALTER TABLE public.prediction_history ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    ALTER TABLE public.prediction_history ALTER COLUMN user_id DROP NOT NULL;
    ALTER TABLE public.experiment_history DROP CONSTRAINT IF EXISTS experiment_history_user_id_fkey;
    ALTER TABLE public.experiment_history ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    ALTER TABLE public.experiment_history ALTER COLUMN user_id DROP NOT NULL;
    ALTER TABLE public.experiment_history ALTER COLUMN gamma_param DROP NOT NULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_pred_user_id    ON public.prediction_history(user_id);
CREATE INDEX IF NOT EXISTS idx_pred_created_at ON public.prediction_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exp_user_id     ON public.experiment_history(user_id);
CREATE INDEX IF NOT EXISTS idx_exp_created_at  ON public.experiment_history(created_at DESC);

-- =====================================================================
-- 3. QUYỀN TRUY CẬP CHO LỊCH SỬ (web đọc / ghi / xoá trực tiếp, không dùng RLS)
-- =====================================================================
ALTER TABLE public.prediction_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.experiment_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users          DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.prediction_history, public.experiment_history TO anon, authenticated, service_role;
GRANT ALL ON public.app_users, public.auth_rate_limits TO service_role;

-- =====================================================================
-- 4. TỰ ĐỘNG BĂM BCRYPT KHI CHÈN / SỬA MẬT KHẨU TRỰC TIẾP TRONG SQL EDITOR
-- =====================================================================
CREATE OR REPLACE FUNCTION public.hash_user_password()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR NEW.password IS DISTINCT FROM OLD.password)
       AND NEW.password IS NOT NULL
       AND NEW.password !~ '^\$2[aby]\$' THEN
        NEW.password := crypt(NEW.password, gen_salt('bf', 12));
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hash_app_users_password ON public.app_users;
CREATE TRIGGER trg_hash_app_users_password
BEFORE INSERT OR UPDATE OF password ON public.app_users
FOR EACH ROW EXECUTE FUNCTION public.hash_user_password();

-- Chuyển mật khẩu cũ (dạng thô) sang BCrypt; bản ghi đã băm sẽ được bỏ qua
UPDATE public.app_users
SET password = extensions.crypt(password, extensions.gen_salt('bf', 12))
WHERE password !~ '^\$2[aby]\$';

-- Tài khoản admin mẫu (chỉ tạo nếu chưa có, chạy lại KHÔNG reset mật khẩu). Mật khẩu ban đầu: admin
INSERT INTO public.app_users (id, name, email, password, role)
VALUES ('00000000-0000-0000-0000-000000000001', 'Lê Thanh Thảo', 'lethao8130@gmail.com', 'admin', 'ADMIN')
ON CONFLICT DO NOTHING;

-- =========================================================
-- 5. GIỚI HẠN SỐ LẦN NHẬP SAI (CHỐNG DÒ MẬT KHẨU)
-- Sai 5 lần trong 15 phút -> khoá thao tác đó 15 phút cho email tương ứng.
-- Bảng này chỉ các hàm SECURITY DEFINER bên dưới được đọc/ghi; anon không truy cập được.
-- =========================================================
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
-- 6. CÁC HÀM BACKEND CHO WEB (GỌI QUA supabase.rpc)
-- Mật khẩu luôn được băm BCrypt (cost 12) ngay trong CSDL; web không bao giờ đọc được mật khẩu/bản băm.
-- Mỗi hàm trả về jsonb: {ok: true, ...} hoặc {ok: false, code: '...'}
-- Lưu ý: BCrypt chỉ dùng 72 ký tự đầu của mật khẩu nên giới hạn tối đa 72.
-- =========================================================

-- 6.1 ĐĂNG KÝ
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

    RETURN jsonb_build_object('ok', true, 'user', jsonb_build_object(
        'id', v_id, 'name', v_name, 'email', v_email, 'role', v_role, 'created_at', v_created));
END;
$$;

-- 6.2 ĐĂNG NHẬP: đối chiếu mật khẩu nhập với bản băm BCrypt
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

-- 6.3 ĐỔI MẬT KHẨU (đã nhớ mật khẩu hiện tại)
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

    PERFORM public._auth_clear_fail(v_email, 'pw');
    RETURN jsonb_build_object('ok', true);
END;
$$;

-- 6.4 QUÊN MẬT KHẨU (không gửi email, không cần mật khẩu cũ):
-- chỉ cần email của tài khoản + mật khẩu mới.
-- Giới hạn 5 lần đặt lại / 15 phút cho mỗi email để tránh bị spam.
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

    PERFORM public._auth_clear_fail(v_email, 'pw');   -- mở khoá đăng nhập nếu đang bị khoá
    RETURN jsonb_build_object('ok', true);
END;
$$;

-- =========================================================
-- 7. KHOÁ QUYỀN VÀO MẬT KHẨU + REALTIME + DỌN BẢNG/HÀM THỪA
-- (đặt cuối để luôn có hiệu lực mỗi lần chạy lại)
-- =========================================================
-- Web chỉ đọc được cột không nhạy cảm của app_users; mọi thao tác mật khẩu đi qua hàm ở mục 6.
REVOKE ALL ON public.app_users FROM anon, authenticated;
GRANT SELECT (id, name, email, role, created_at) ON public.app_users TO anon, authenticated;

REVOKE ALL ON public.auth_rate_limits FROM PUBLIC, anon, authenticated;
ALTER TABLE public.auth_rate_limits ENABLE ROW LEVEL SECURITY;   -- không có policy = anon không thấy gì

REVOKE ALL ON FUNCTION public._auth_lock_minutes(TEXT, TEXT)  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._auth_register_fail(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._auth_clear_fail(TEXT, TEXT)    FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.register_user(TEXT, TEXT, TEXT)    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.login_user(TEXT, TEXT)             FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.change_password(TEXT, TEXT, TEXT)  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reset_password_by_email(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_user(TEXT, TEXT, TEXT)    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.login_user(TEXT, TEXT)             TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.change_password(TEXT, TEXT, TEXT)  TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_password_by_email(TEXT, TEXT) TO anon, authenticated;

-- Dọn bảng/hàm không còn dùng (nếu CSDL cũ đang có). Lỗi ở đây không làm dừng script.
DO $$ BEGIN
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.profiles';          EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.user_preferences';  EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP TABLE IF EXISTS public.app_content';       EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP FUNCTION IF EXISTS public.verify_user_password(TEXT, TEXT)'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'DROP FUNCTION IF EXISTS public.reset_password_by_identity(TEXT, TEXT, TEXT)'; EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- Realtime cho 3 bảng web đang lắng nghe. app_users chỉ phát các cột không chứa mật khẩu
-- (danh sách cột cần PostgreSQL 15+; nếu không hỗ trợ thì app_users bị gỡ khỏi realtime cho an toàn).
DO $$ BEGIN
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.prediction_history'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.experiment_history'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime DROP TABLE public.app_users';         EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.app_users (id, name, email, role, created_at)'; EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- Báo cho API Supabase nạp lại danh sách hàm
NOTIFY pgrst, 'reload schema';
