SET search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- agent_usage_records
--   agent_logs는 UPSERT(update-in-place) 구조라 이력이 소실됨.
--   토큰/비용 집계를 위한 append-only 불변 기록 테이블.
-- ─────────────────────────────────────────────────────────────

CREATE TABLE agent_usage_records (
    id                   BIGSERIAL PRIMARY KEY,
    user_id              BIGINT        NOT NULL REFERENCES users(id),
    project_id           BIGINT        NOT NULL REFERENCES projects(id),
    usage_statement_id   BIGINT        REFERENCES usage_statements(id),
    agent_type_code      VARCHAR(20)   NOT NULL,
    model_name           VARCHAR(100),
    input_tokens         BIGINT,
    output_tokens        BIGINT,
    cost_usd             NUMERIC(12,8),
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT chk_agent_usage_records_agent_type_code
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator')),
    CONSTRAINT chk_agent_usage_records_tokens_non_negative
        CHECK (input_tokens >= 0 AND output_tokens >= 0),
    CONSTRAINT chk_agent_usage_records_cost_non_negative
        CHECK (cost_usd >= 0)
);

COMMENT ON COLUMN agent_usage_records.input_tokens  IS '입력 토큰 수';
COMMENT ON COLUMN agent_usage_records.output_tokens IS '출력 토큰 수';
COMMENT ON COLUMN agent_usage_records.cost_usd      IS 'API 호출 비용 (USD), 소수점 8자리';

CREATE INDEX idx_agent_usage_records_user_project_date
    ON agent_usage_records (user_id, project_id, created_at);

CREATE INDEX idx_agent_usage_records_project_date
    ON agent_usage_records (project_id, created_at);
