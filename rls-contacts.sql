-- ============================================================
-- 优学帮：tutors + tutor_contacts RLS 策略
-- 在 Supabase Dashboard → SQL Editor 中执行
-- ============================================================

-- ─── 1. 开启 RLS ───
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_contacts ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. tutors 表：任何人（含匿名游客）可读
-- ============================================================
DROP POLICY IF EXISTS "tutors_select_public" ON tutors;
CREATE POLICY "tutors_select_public" ON tutors
  FOR SELECT
  USING (true);

-- ============================================================
-- 3. tutor_contacts 表：仅付款学生可读
-- ============================================================
-- 规则说明：
--   只有当 orders 表中存在一条记录，同时满足以下三个条件时，
--   当前用户才能 SELECT 该 tutor 的联系方式：
--     ① tutor_id  匹配（你买的谁的服务）
--     ② status  = 'paid'（你真的付了钱）
--     ③ student_id = auth.uid()（你就是买服务的那个人）
-- ============================================================
DROP POLICY IF EXISTS "tutor_contacts_select_paid_students" ON tutor_contacts;
CREATE POLICY "tutor_contacts_select_paid_students" ON tutor_contacts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM orders
      WHERE orders.tutor_id   = tutor_contacts.tutor_id   -- ① 对应导师
        AND orders.status     = 'paid'                    -- ② 已付款
        AND orders.student_id = auth.uid()                -- ③ 当前登录用户
    )
  );

-- ============================================================
-- 4. 管理员可管理 tutor_contacts（增删改）
-- ============================================================
-- 如果你已有 admins 表和 is_admin() 函数，取消下面注释：
-- DROP POLICY IF EXISTS "tutor_contacts_admin_all" ON tutor_contacts;
-- CREATE POLICY "tutor_contacts_admin_all" ON tutor_contacts
--   FOR ALL
--   USING (is_admin())
--   WITH CHECK (is_admin());

-- ============================================================
-- 5. tutors 表管理员可增删改（如果还没设的话）
-- ============================================================
-- DROP POLICY IF EXISTS "tutors_admin_write" ON tutors;
-- CREATE POLICY "tutors_admin_write" ON tutors
--   FOR ALL
--   USING (is_admin())
--   WITH CHECK (is_admin());
