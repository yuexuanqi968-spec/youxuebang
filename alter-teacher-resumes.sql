-- ============================================================
-- 优学帮：teacher_resumes 表结构补全（修正版）
-- 在 Supabase Dashboard → SQL Editor 中逐条或全选执行
-- ============================================================

-- 1. 添加缺失列（ADD COLUMN IF NOT EXISTS 在 PG 9.6+ 可用）
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS real_name TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS wechat_id TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS grade TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS school TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS subject TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS intro TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS degree_cert_url TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS teaching_cert_url TEXT;
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- 2. 添加 user_id（如果报错，手动在 Supabase 表编辑器里加一列）
ALTER TABLE teacher_resumes ADD COLUMN IF NOT EXISTS user_id UUID;

-- 3. 如果旧表有 name 列，把数据迁移到 real_name
UPDATE teacher_resumes SET real_name = name WHERE real_name IS NULL AND name IS NOT NULL;
