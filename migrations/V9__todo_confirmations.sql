SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- todos
--   agent_logs.details JSONB 안의 payload.todos[] 를 평탄화하여 보관하는 읽기 모델.
--   agent 실행 직후 Spring이 해당 사용내역서 단위로 재생성(merge)한다:
--     · 파싱된 각 TODO를 todo_key 기준 UPSERT (내용 필드 갱신, confirmed는 보존)
--     · 이번 파싱 결과에 없는 todo_key 행은 삭제(이슈 해소분 제거)
--
--   todo_key = sha256(usage_statement_id | agent_type_code |
--                     usage_statement_item_id | category_code | reason)
--   → reason이 바뀌면 키가 바뀌어 "새 TODO"로 취급되므로 confirmed가 자동 해제된다.
--     내용이 완전히 동일하게 재생성되면 같은 키 → confirmed 유지.
--
--   파생 데이터이므로 item/file 참조는 FK를 걸지 않는다(원본 변경에도 재생성이 깨지지 않게).
-- ─────────────────────────────────────────────────────────────

CREATE TABLE service.todos (
    id                         BIGSERIAL   PRIMARY KEY,
    usage_statement_id         BIGINT      NOT NULL,
    usage_statement_item_id    BIGINT,
    usage_statement_item_name  TEXT,
    category_code              VARCHAR(20),
    category_name              VARCHAR(100),
    agent_type_code            VARCHAR(20) NOT NULL,
    file_id                    BIGINT,
    reason                     TEXT,
    todo_key                   VARCHAR(64) NOT NULL,
    confirmed                  BOOLEAN     NOT NULL DEFAULT false,
    confirmed_by               BIGINT,
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_todos_key UNIQUE (todo_key),
    CONSTRAINT fk_todos_statement
        FOREIGN KEY (usage_statement_id) REFERENCES service.usage_statements(id) ON DELETE CASCADE,
    CONSTRAINT fk_todos_confirmed_by
        FOREIGN KEY (confirmed_by)       REFERENCES service.users(id)            ON DELETE SET NULL
);

CREATE INDEX idx_todos_statement ON service.todos (usage_statement_id);

CREATE TRIGGER trg_todos_set_updated_at
BEFORE UPDATE ON service.todos FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON TABLE  service.todos IS 'agent_logs.details JSONB의 todos[]를 평탄화한 읽기 모델 — agent 실행 직후 Spring이 statement 단위 merge';
COMMENT ON COLUMN service.todos.todo_key IS 'TODO 식별 해시 sha256(statement_id|agent_type_code|item_id|category_code|reason). reason 변경 시 키가 바뀌어 새 TODO로 취급';
COMMENT ON COLUMN service.todos.confirmed IS '사용자 확인(체크) 여부 — merge 시 보존됨';
COMMENT ON COLUMN service.todos.confirmed_by IS '확인 처리한 사용자 ID';
