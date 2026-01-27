-- 更新aibi_dataset表

ALTER TABLE aibi_dataset
    ALTER COLUMN create_time TYPE TIMESTAMP(3) USING create_time,
    ALTER COLUMN update_time TYPE TIMESTAMP(3) USING update_time;

ALTER TABLE aibi_dataset
ALTER COLUMN create_time SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE aibi_dataset
ALTER COLUMN update_time SET DEFAULT CURRENT_TIMESTAMP;

-- 更新ai_file_record表
ALTER TABLE ai_file_record 
ADD COLUMN trace_id VARCHAR(256);


-- 更新agent_plan_sop表
ALTER TABLE agent_plan_sop
ADD COLUMN sop_tags VARCHAR(256);

COMMENT ON COLUMN agent_plan_sop.sop_tags IS 'sop 的业务标签';