SET search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- 1. agent_logs UPSERT unique index
--    FastAPI가 재실행 시 같은 row를 덮어쓸 수 있도록
-- ─────────────────────────────────────────────────────────────

-- 항목별 agent (classi, vision, link)
CREATE UNIQUE INDEX uq_agent_logs_item_type
    ON agent_logs (usage_statement_item_id, agent_type_code)
    WHERE usage_statement_item_id IS NOT NULL;

-- 사용내역서별 agent (safety-doc, legal, report)
CREATE UNIQUE INDEX uq_agent_logs_statement_type
    ON agent_logs (usage_statement_id, agent_type_code)
    WHERE usage_statement_item_id IS NULL;

-- ─────────────────────────────────────────────────────────────
-- 2. agent_logs 토큰 컬럼 추가
--    token (기존) 컬럼은 유지
-- ─────────────────────────────────────────────────────────────

ALTER TABLE agent_logs
    ADD COLUMN token_current    BIGINT,
    ADD COLUMN token_cumulative BIGINT;

COMMENT ON COLUMN agent_logs.token_current    IS '이번 회차 토큰 사용량';
COMMENT ON COLUMN agent_logs.token_cumulative IS '누적 토큰 사용량 (재실행 시 합산)';
