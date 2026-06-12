SET LOCAL search_path TO service, public;

-- agent_logs CHECK 제약에 'vlm' 추가
ALTER TABLE agent_logs
    DROP CONSTRAINT chk_agent_logs_agent_type_code;
ALTER TABLE agent_logs
    ADD CONSTRAINT chk_agent_logs_agent_type_code
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'vlm'));

-- agent_usage_records CHECK 제약에 'vlm' 추가
ALTER TABLE agent_usage_records
    DROP CONSTRAINT chk_agent_usage_records_agent_type_code;
ALTER TABLE agent_usage_records
    ADD CONSTRAINT chk_agent_usage_records_agent_type_code
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'vlm'));
