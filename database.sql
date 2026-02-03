-- Supabase 数据库表结构（无用户认证版本）
-- 家庭信息管理系统 - 共享数据源

-- 创建共享数据表（所有用户访问同一数据）
CREATE TABLE IF NOT EXISTS shared_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    data_key TEXT NOT NULL UNIQUE,
    data_value JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_shared_data_key ON shared_data(data_key);

-- 注意：此版本不使用 RLS，因为所有用户共享同一数据源
-- 如需限制访问，请在应用层或网络层控制

-- 创建更新时间的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建触发器
DROP TRIGGER IF EXISTS update_shared_data_updated_at ON shared_data;
CREATE TRIGGER update_shared_data_updated_at
    BEFORE UPDATE ON shared_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 启用 Realtime
BEGIN;
  -- 删除现有订阅（如果有）
  DROP PUBLICATION IF EXISTS supabase_realtime;
  -- 创建新的发布
  CREATE PUBLICATION supabase_realtime;
COMMIT;

-- 将表添加到 Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE shared_data;

-- 注释说明
COMMENT ON TABLE shared_data IS '共享数据表，所有访问者共享同一数据源';
COMMENT ON COLUMN shared_data.data_key IS '数据键名，如: familyFinanceData, studyData, taskData, houseworkData';
COMMENT ON COLUMN shared_data.data_value IS 'JSON格式的数据内容';

-- 插入初始数据（可选）
-- INSERT INTO shared_data (data_key, data_value) VALUES
--     ('familyFinanceData', '{}'),
--     ('studyData', '{}'),
--     ('taskData', '{}'),
--     ('houseworkData', '{}')
-- ON CONFLICT (data_key) DO NOTHING;
