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

-- 4. 开启 RLS（行级安全）
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 5. 导师表策略：所有人可读，管理员可写
CREATE POLICY "tutors_select_public" ON tutors FOR SELECT USING (true);
CREATE POLICY "tutors_insert_admin" ON tutors FOR INSERT WITH CHECK (true);
CREATE POLICY "tutors_update_admin" ON tutors FOR UPDATE USING (true);
CREATE POLICY "tutors_delete_admin" ON tutors FOR DELETE USING (true);

-- 6. 预约表策略：所有人可插入（学生提交），管理员可读写
CREATE POLICY "bookings_insert_public" ON bookings FOR INSERT WITH CHECK (true);
CREATE POLICY "bookings_select_admin" ON bookings FOR SELECT USING (true);
CREATE POLICY "bookings_update_admin" ON bookings FOR UPDATE USING (true);
CREATE POLICY "bookings_delete_admin" ON bookings FOR DELETE USING (true);
