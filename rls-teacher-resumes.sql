-- ============================================================
-- 优学帮：teacher_resumes RLS 策略
-- 在 Supabase Dashboard → SQL Editor 中执行
-- ============================================================

-- ─── 1. 创建教师简历表（如果尚未创建） ───
CREATE TABLE IF NOT EXISTS teacher_resumes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  gender TEXT,
  school TEXT,
  subject TEXT,
  phone TEXT,
  email TEXT,
  intro TEXT,
  status TEXT DEFAULT 'pending',
  id_card_front_url TEXT,
  id_card_back_url TEXT,
  degree_cert_url TEXT,
  teaching_cert_url TEXT,
  resume_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 2. 开启 RLS ───
ALTER TABLE teacher_resumes ENABLE ROW LEVEL SECURITY;

-- ─── 3. 所有人可提交简历（无需登录） ───
DROP POLICY IF EXISTS "teacher_resumes_insert_public" ON teacher_resumes;
CREATE POLICY "teacher_resumes_insert_public" ON teacher_resumes
  FOR INSERT
  WITH CHECK (true);

-- ─── 4. 仅管理员可查看全部简历 ───
DROP POLICY IF EXISTS "teacher_resumes_select_admin" ON teacher_resumes;
CREATE POLICY "teacher_resumes_select_admin" ON teacher_resumes
  FOR SELECT
  USING (is_admin());

-- ─── 5. 仅管理员可更新简历状态 ───
DROP POLICY IF EXISTS "teacher_resumes_update_admin" ON teacher_resumes;
CREATE POLICY "teacher_resumes_update_admin" ON teacher_resumes
  FOR UPDATE
  USING (is_admin());

-- ─── 6. 仅管理员可删除简历 ───
DROP POLICY IF EXISTS "teacher_resumes_delete_admin" ON teacher_resumes;
CREATE POLICY "teacher_resumes_delete_admin" ON teacher_resumes
  FOR DELETE
  USING (is_admin());

-- ============================================================
-- Storage Bucket 设置说明
-- ============================================================
-- 1. 在 Supabase Dashboard → Storage 中创建名为 resume-assets 的存储桶
-- 2. 设为公开桶（Public bucket）以便前端可直接通过 URL 预览证件图片
-- 3. 如需要隐私保护，可设为非公开桶，前端改为使用 createSignedUrl() 生成临时签名 URL
-- ============================================================
