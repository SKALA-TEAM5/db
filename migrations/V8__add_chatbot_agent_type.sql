SET LOCAL search_path TO service, public;

-- agent_usage_records.agent_type_code CHECK 제약조건에 chatbot 추가
ALTER TABLE agent_usage_records
    DROP CONSTRAINT chk_agent_usage_records_agent_type_code;

ALTER TABLE agent_usage_records
    ADD CONSTRAINT chk_agent_usage_records_agent_type_code
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'chatbot'));

-- projects 테이블 unique 제약조건 추가
DROP INDEX IF EXISTS service.idx_projects_contract_no;

ALTER TABLE service.projects
    ADD CONSTRAINT uq_projects_contract_no UNIQUE (contract_no),
    ADD CONSTRAINT uq_projects_project_name UNIQUE (project_name);
