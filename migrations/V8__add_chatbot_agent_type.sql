-- agent_usage_records.agent_type_code CHECK 제약조건에 chatbot 추가
ALTER TABLE agent_usage_records
    DROP CONSTRAINT chk_agent_usage_records_agent_type_code;

ALTER TABLE agent_usage_records
    ADD CONSTRAINT chk_agent_usage_records_agent_type_code
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'chatbot'));
