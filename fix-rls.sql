-- ============================================================
-- 优学帮 安全修复迁移脚本
-- 请在 Supabase Dashboard → SQL Editor 中执行此文件
-- ============================================================

-- ════════════════════════════════════════════════════════
-- 第 1 步：删除旧的（有安全漏洞的）RLS 策略
-- ════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "tutors_select_public" ON tutors;
DROP POLICY IF EXISTS "tutors_insert_admin" ON tutors;
DROP POLICY IF EXISTS "tutors_update_admin" ON tutors;
DROP POLICY IF EXISTS "tutors_delete_admin" ON tutors;
DROP POLICY IF EXISTS "bookings_insert_public" ON bookings;
DROP POLICY IF EXISTS "bookings_select_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_update_admin" ON bookings;
DROP POLICY IF EXISTS "bookings_delete_admin" ON bookings;

-- ════════════════════════════════════════════════════════
-- 第 2 步：创建管理员表
-- ════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 管理员表也需要 RLS 保护
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- 仅已认证用户可以查看管理员列表
DROP POLICY IF EXISTS "admins_select_authenticated" ON admins;
CREATE POLICY "admins_select_authenticated" ON admins
  FOR SELECT USING (auth.role() = 'authenticated');

-- ════════════════════════════════════════════════════════
-- 第 3 步：创建 is_admin() 安全定义函数
-- ════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins WHERE user_id = auth.uid()
  );
END;
$$;

-- ════════════════════════════════════════════════════════
-- 第 4 步：创建学生自助查询 RPC 函数
-- ════════════════════════════════════════════════════════
-- 学生通过手机号查询自己的预约，无需登录
-- 不暴露 phone 和 payment_screenshot_url 字段
-- LIMIT 20 防止批量数据爬取
CREATE OR REPLACE FUNCTION lookup_bookings_by_phone(p_phone TEXT)
RETURNS TABLE (
  id UUID,
  student_name TEXT,
  grade TEXT,
  demand TEXT,
  tutor_id UUID,
  status TEXT,
  payment_status TEXT,
  created_at TIMESTAMPTZ,
  tutor_name TEXT,
  tutor_subject TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id,
    b.student_name,
    b.grade,
    b.demand,
    b.tutor_id,
    b.status,
    b.payment_status,
    b.created_at,
    t.name AS tutor_name,
    t.subject AS tutor_subject
  FROM bookings b
  LEFT JOIN tutors t ON b.tutor_id = t.id
  WHERE b.phone = p_phone
  ORDER BY b.created_at DESC
  LIMIT 20;
END;
$$;

-- ════════════════════════════════════════════════════════
-- 第 5 步：创建安全的 RLS 策略
-- ════════════════════════════════════════════════════════

-- ── 导师表 (tutors) ──
-- 所有人可查看
CREATE POLICY "tutors_select_public" ON tutors
  FOR SELECT USING (true);

-- 仅管理员可增删改
CREATE POLICY "tutors_insert_admin" ON tutors
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "tutors_update_admin" ON tutors
  FOR UPDATE USING (is_admin());

CREATE POLICY "tutors_delete_admin" ON tutors
  FOR DELETE USING (is_admin());

-- ── 预约表 (bookings) ──
-- 所有人可提交预约（学生无需登录）
CREATE POLICY "bookings_insert_public" ON bookings
  FOR INSERT WITH CHECK (true);

-- 仅管理员可查看全部预约
CREATE POLICY "bookings_select_admin" ON bookings
  FOR SELECT USING (is_admin());

-- 仅管理员可更新/删除预约
CREATE POLICY "bookings_update_admin" ON bookings
  FOR UPDATE USING (is_admin());

CREATE POLICY "bookings_delete_admin" ON bookings
  FOR DELETE USING (is_admin());

-- ════════════════════════════════════════════════════════
-- 第 6 步：设置管理员（请手动执行）
-- ════════════════════════════════════════════════════════
-- 6.1 在 Supabase Dashboard → Authentication → Users 中
--     创建或确认管理员用户账号
-- 6.2 复制该用户的 UUID
-- 6.3 取消下面语句的注释并粘贴 UUID，然后执行：
--
-- INSERT INTO admins (user_id) VALUES ('粘贴管理员UUID');
--
-- 6.4 验证：执行以下查询，确认返回 true
-- SELECT is_admin();

-- ════════════════════════════════════════════════════════
-- Storage Bucket 安全提示
-- ════════════════════════════════════════════════════════
-- 建议将 payment-proofs 存储桶设为非公开：
--   1. 进入 Supabase Dashboard → Storage → payment-proofs
--   2. 取消勾选 "Public bucket"
--   3. 如设为非公开，需同步修改 index.html 和 admin.html
--      将 getPublicUrl() 改为 createSignedUrl(60) 生成临时签名 URL
-- ============================================================
