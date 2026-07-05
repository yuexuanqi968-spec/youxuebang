-- ========================================
-- 优学帮 数据库初始化脚本
-- 在 Supabase Dashboard → SQL Editor 中执行
-- ========================================

-- 1. 创建导师表
CREATE TABLE IF NOT EXISTS tutors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  avatar TEXT DEFAULT '👨‍🏫',
  hourly_rate INTEGER NOT NULL,
  rating DECIMAL(2,1) DEFAULT 5.0,
  students_count INTEGER DEFAULT 0,
  intro TEXT,
  tags TEXT[] DEFAULT '{}',
  phone TEXT,
  wechat TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. 创建预约表
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  grade TEXT NOT NULL,
  demand TEXT,
  tutor_id UUID REFERENCES tutors(id),
  status TEXT DEFAULT 'pending',
  payment_status TEXT DEFAULT 'unpaid',
  payment_screenshot_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. 插入示例导师数据
INSERT INTO tutors (name, subject, avatar, hourly_rate, rating, students_count, intro, tags) VALUES
('王明辉', '数学', '👨‍🏫', 180, 4.9, 126, '清华数学系毕业，10年高考数学辅导经验，擅长函数与几何综合题解析。', ARRAY['高考冲刺', '竞赛辅导']),
('李思琪', '英语', '👩‍🏫', 160, 4.8, 98, '英语专业八级，雅思8分，专注初高中英语阅读写作提升。', ARRAY['雅思托福', '阅读写作']),
('张伟', '物理', '👨‍🔬', 200, 4.9, 85, '北大物理博士，擅长将抽象物理概念可视化，让学习变得简单有趣。', ARRAY['力学电学', '实验指导']),
('陈雨萱', '数学', '👩‍💻', 150, 4.7, 112, '985高校研究生，耐心细致，专攻初中数学基础巩固与提分。', ARRAY['基础巩固', '中考备考']),
('刘建国', '英语', '👨‍🎓', 190, 4.8, 76, '海归硕士，纯正美式发音，口语教学经验丰富，商务英语专家。', ARRAY['口语提升', '商务英语']),
('赵思远', '物理', '👩‍🔬', 170, 4.6, 64, '物理竞赛金牌教练，带出多名省一等奖学员，解题思路清晰。', ARRAY['竞赛辅导', '解题技巧']);

-- ============================================================
-- 4. 创建管理员表（引用 Supabase Auth 用户）
-- ============================================================
CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 5. 开启 RLS（行级安全）
-- ============================================================
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. 管理员表 RLS：仅已认证用户可查看
-- ============================================================
CREATE POLICY "admins_select_authenticated" ON admins
  FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================
-- 7. 创建 is_admin() 安全定义函数
-- ============================================================
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

-- ============================================================
-- 8. 导师表 RLS 策略：所有人可读，仅管理员可增删改
-- ============================================================
CREATE POLICY "tutors_select_public" ON tutors
  FOR SELECT USING (true);

CREATE POLICY "tutors_insert_admin" ON tutors
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "tutors_update_admin" ON tutors
  FOR UPDATE USING (is_admin());

CREATE POLICY "tutors_delete_admin" ON tutors
  FOR DELETE USING (is_admin());

-- ============================================================
-- 9. 预约表 RLS 策略
--    学生可提交预约（无需登录）
--    仅管理员可查看全部、更新、删除
-- ============================================================
CREATE POLICY "bookings_insert_public" ON bookings
  FOR INSERT WITH CHECK (true);

CREATE POLICY "bookings_select_admin" ON bookings
  FOR SELECT USING (is_admin());

CREATE POLICY "bookings_update_admin" ON bookings
  FOR UPDATE USING (is_admin());

CREATE POLICY "bookings_delete_admin" ON bookings
  FOR DELETE USING (is_admin());

-- ============================================================
-- 10. 学生自助查询 RPC（通过手机号查预约，限制 20 条）
-- ============================================================
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

-- ============================================================
-- 11. 设置管理员（初始步骤）
-- ============================================================
-- 11.1 在 Supabase Dashboard → Authentication 创建管理员用户
-- 11.2 复制用户的 UUID
-- 11.3 执行：
--   INSERT INTO admins (user_id) VALUES ('粘贴UUID');
-- 11.4 验证：
--   SELECT is_admin();
-- ============================================================
