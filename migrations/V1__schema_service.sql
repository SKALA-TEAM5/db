CREATE SCHEMA IF NOT EXISTS service;
SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- Tables
-- ─────────────────────────────────────────────────────────────

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    employee_no VARCHAR(50) NOT NULL,
    real_name VARCHAR(100) NOT NULL,
    password_hash TEXT NOT NULL,
    role_code VARCHAR(30) NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_users_employee_no UNIQUE (employee_no),
    CONSTRAINT chk_users_role_code CHECK (role_code IN ('system_admin', 'admin', 'user', 'agent'))
);

CREATE TABLE usage_categories (
    code VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    CONSTRAINT uq_usage_categories_name UNIQUE (name)
);

CREATE TABLE evidence_types (
    code VARCHAR(30) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE projects (
    id BIGSERIAL PRIMARY KEY,
    contract_no VARCHAR(100),
    construction_company VARCHAR(200) NOT NULL,
    project_name VARCHAR(300) NOT NULL,
    site_location VARCHAR(500) NOT NULL,
    representative_name VARCHAR(100),
    contract_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    construction_start_date DATE NOT NULL,
    construction_end_date DATE NOT NULL,
    client_name VARCHAR(200),
    appropriated_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    project_status_code VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_projects_contract_amount_non_negative CHECK (contract_amount >= 0),
    CONSTRAINT chk_projects_appropriated_amount_non_negative CHECK (appropriated_amount >= 0),
    CONSTRAINT chk_projects_construction_date_range CHECK (construction_end_date >= construction_start_date),
    CONSTRAINT chk_projects_status_code CHECK (project_status_code IN ('active', 'completed', 'suspended')),
    -- V8 편입: contract_no / project_name 고유 제약
    CONSTRAINT uq_projects_contract_no UNIQUE (contract_no),
    CONSTRAINT uq_projects_project_name UNIQUE (project_name)
);

CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_refresh_tokens_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_refresh_tokens_user_id
        FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE project_user_assignments (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    assigned_by_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_project_user_assignments_project_user UNIQUE (project_id, user_id),
    CONSTRAINT fk_project_user_assignments_project_id
        FOREIGN KEY (project_id) REFERENCES projects (id),
    CONSTRAINT fk_project_user_assignments_user_id
        FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_project_user_assignments_assigned_by_user_id
        FOREIGN KEY (assigned_by_user_id) REFERENCES users (id)
);

CREATE TABLE files (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL,
    uploaded_by_user_id BIGINT NOT NULL,
    uploaded_evidence_type_code VARCHAR(30) NOT NULL,
    original_filename VARCHAR(500) NOT NULL,
    storage_key TEXT NOT NULL,
    mime_type VARCHAR(150) NOT NULL,
    size_bytes BIGINT NOT NULL,
    captured_at TIMESTAMPTZ,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status_code VARCHAR(20) NOT NULL DEFAULT 'draft',
    deleted_at TIMESTAMPTZ,
    deleted_by_user_id BIGINT,
    detail JSONB,
    CONSTRAINT uq_files_storage_key UNIQUE (storage_key),
    CONSTRAINT chk_files_size_bytes_non_negative CHECK (size_bytes >= 0),
    CONSTRAINT chk_files_status_code CHECK (status_code IN ('draft', 'success', 'fail'))
);

CREATE TABLE usage_statements (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL,
    source_file_id BIGINT,
    report_month DATE NOT NULL,
    revision_no INTEGER NOT NULL DEFAULT 1,
    document_written_date DATE NOT NULL,
    cumulative_progress_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
    status_code VARCHAR(30) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_usage_statements_source_file_id UNIQUE (source_file_id),
    CONSTRAINT uq_usage_statements_project_month_revision UNIQUE (project_id, report_month, revision_no),
    CONSTRAINT chk_usage_statements_revision_no_positive CHECK (revision_no >= 1),
    CONSTRAINT chk_usage_statements_report_month_first_day CHECK (report_month = date_trunc('month', report_month)::date),
    CONSTRAINT chk_usage_statements_progress_rate CHECK (cumulative_progress_rate BETWEEN 0 AND 100),
    CONSTRAINT chk_usage_statements_status_code CHECK (status_code IN ('draft', 'upload_completed', 'supplement_required', 'review_completed'))
);

CREATE TABLE usage_statement_summaries (
    id BIGSERIAL PRIMARY KEY,
    usage_statement_id BIGINT NOT NULL,
    category_code VARCHAR(50) NOT NULL,
    previous_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    current_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    cumulative_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_usage_statement_summaries_statement_category UNIQUE (usage_statement_id, category_code),
    CONSTRAINT chk_usage_statement_summaries_previous_amount_non_negative CHECK (previous_amount >= 0),
    CONSTRAINT chk_usage_statement_summaries_current_amount_non_negative CHECK (current_amount >= 0),
    CONSTRAINT chk_usage_statement_summaries_cumulative_amount_non_negative CHECK (cumulative_amount >= 0)
);

CREATE TABLE usage_statement_items (
    id BIGSERIAL PRIMARY KEY,
    usage_statement_id BIGINT NOT NULL,
    category_code VARCHAR(50) NOT NULL,
    used_on DATE NOT NULL,
    item_name VARCHAR(300) NOT NULL,
    unit VARCHAR(50),
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 0,
    unit_price NUMERIC(18, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18, 0) NOT NULL DEFAULT 0,
    remark VARCHAR(1000),
    page_no INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_usage_statement_items_quantity_non_negative CHECK (quantity >= 0),
    CONSTRAINT chk_usage_statement_items_unit_price_non_negative CHECK (unit_price >= 0),
    CONSTRAINT chk_usage_statement_items_total_amount_non_negative CHECK (total_amount >= 0),
    CONSTRAINT chk_usage_statement_items_page_no_positive CHECK (page_no >= 1)
);

CREATE TABLE evidence_file_links (
    id BIGSERIAL PRIMARY KEY,
    usage_statement_item_id BIGINT NOT NULL,
    file_id BIGINT NOT NULL,
    evidence_type_code VARCHAR(30) NOT NULL,
    checked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_evidence_file_links_item_file UNIQUE (usage_statement_item_id, file_id)
);

CREATE TABLE evidence_requirements (
    id BIGSERIAL PRIMARY KEY,
    usage_statement_item_id BIGINT NOT NULL,
    evidence_type_code VARCHAR(30) NOT NULL,
    is_satisfied BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE agent_logs (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL,
    usage_statement_id BIGINT,
    usage_statement_item_id BIGINT,
    agent_type_code VARCHAR(20) NOT NULL,
    status_code VARCHAR(20) NOT NULL DEFAULT 'pending',
    result_code VARCHAR(20),
    reason TEXT,
    details JSONB,
    model_name VARCHAR(100),
    token BIGINT,
    token_current    BIGINT,
    token_cumulative BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_agent_logs_agent_type_code CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'vlm')),
    CONSTRAINT chk_agent_logs_status_code CHECK (status_code IN ('pending', 'running', 'success', 'fail', 'canceled')),
    CONSTRAINT chk_agent_logs_result_code CHECK (result_code IN ('success', 'hil', 'fail'))
);

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
        CHECK (agent_type_code IN ('classi', 'safety-doc', 'link', 'vision', 'legal', 'report', 'orchestrator', 'chatbot', 'vlm')),
    CONSTRAINT chk_agent_usage_records_tokens_non_negative
        CHECK (input_tokens >= 0 AND output_tokens >= 0),
    CONSTRAINT chk_agent_usage_records_cost_non_negative
        CHECK (cost_usd >= 0)
);

-- ─────────────────────────────────────────────────────────────
-- Foreign keys
-- ─────────────────────────────────────────────────────────────

ALTER TABLE files
    ADD CONSTRAINT fk_files_project_id
    FOREIGN KEY (project_id) REFERENCES projects (id);

ALTER TABLE files
    ADD CONSTRAINT fk_files_uploaded_by_user_id
    FOREIGN KEY (uploaded_by_user_id) REFERENCES users (id);

ALTER TABLE files
    ADD CONSTRAINT fk_files_uploaded_evidence_type_code
    FOREIGN KEY (uploaded_evidence_type_code) REFERENCES evidence_types (code);

ALTER TABLE files
    ADD CONSTRAINT fk_files_deleted_by_user_id
    FOREIGN KEY (deleted_by_user_id) REFERENCES users (id);

ALTER TABLE usage_statements
    ADD CONSTRAINT fk_usage_statements_project_id
    FOREIGN KEY (project_id) REFERENCES projects (id);

ALTER TABLE usage_statements
    ADD CONSTRAINT fk_usage_statements_source_file_id
    FOREIGN KEY (source_file_id) REFERENCES files (id);

ALTER TABLE usage_statement_summaries
    ADD CONSTRAINT fk_usage_statement_summaries_usage_statement_id
    FOREIGN KEY (usage_statement_id) REFERENCES usage_statements (id);

ALTER TABLE usage_statement_summaries
    ADD CONSTRAINT fk_usage_statement_summaries_category_code
    FOREIGN KEY (category_code) REFERENCES usage_categories (code);

ALTER TABLE usage_statement_items
    ADD CONSTRAINT fk_usage_statement_items_usage_statement_id
    FOREIGN KEY (usage_statement_id) REFERENCES usage_statements (id);

ALTER TABLE usage_statement_items
    ADD CONSTRAINT fk_usage_statement_items_category_code
    FOREIGN KEY (category_code) REFERENCES usage_categories (code);

ALTER TABLE evidence_file_links
    ADD CONSTRAINT fk_evidence_file_links_usage_statement_item_id
    FOREIGN KEY (usage_statement_item_id) REFERENCES usage_statement_items (id);

ALTER TABLE evidence_file_links
    ADD CONSTRAINT fk_evidence_file_links_file_id
    FOREIGN KEY (file_id) REFERENCES files (id);

ALTER TABLE evidence_file_links
    ADD CONSTRAINT fk_evidence_file_links_evidence_type_code
    FOREIGN KEY (evidence_type_code) REFERENCES evidence_types (code);

ALTER TABLE evidence_requirements
    ADD CONSTRAINT fk_evidence_requirements_usage_statement_item_id
    FOREIGN KEY (usage_statement_item_id) REFERENCES usage_statement_items (id);

ALTER TABLE evidence_requirements
    ADD CONSTRAINT fk_evidence_requirements_evidence_type_code
    FOREIGN KEY (evidence_type_code) REFERENCES evidence_types (code);

ALTER TABLE agent_logs
    ADD CONSTRAINT fk_agent_logs_project_id
    FOREIGN KEY (project_id) REFERENCES projects (id);

ALTER TABLE agent_logs
    ADD CONSTRAINT fk_agent_logs_usage_statement_id
    FOREIGN KEY (usage_statement_id) REFERENCES usage_statements (id);

ALTER TABLE agent_logs
    ADD CONSTRAINT fk_agent_logs_usage_statement_item_id
    FOREIGN KEY (usage_statement_item_id) REFERENCES usage_statement_items (id);


-- ─────────────────────────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────────────────────────

CREATE INDEX idx_projects_status_created_at ON projects (project_status_code, created_at DESC);
CREATE INDEX idx_projects_created_at ON projects (created_at DESC);
-- V8 편입: idx_projects_contract_no 는 uq_projects_contract_no(고유 인덱스)로 대체되어 제거

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_active_user ON refresh_tokens (user_id, expires_at) WHERE revoked_at IS NULL;

CREATE INDEX idx_project_user_assignments_user_project ON project_user_assignments (user_id, project_id);
CREATE INDEX idx_project_user_assignments_project_id ON project_user_assignments (project_id);
CREATE INDEX idx_project_user_assignments_assigned_by_user_id ON project_user_assignments (assigned_by_user_id) WHERE assigned_by_user_id IS NOT NULL;

CREATE INDEX idx_files_project_uploaded_at ON files (project_id, uploaded_at DESC);
CREATE INDEX idx_files_uploaded_by_user_id ON files (uploaded_by_user_id);
CREATE INDEX idx_files_uploaded_evidence_type_uploaded_at ON files (uploaded_evidence_type_code, uploaded_at DESC);
CREATE INDEX idx_files_captured_at ON files (captured_at) WHERE captured_at IS NOT NULL;
CREATE INDEX idx_files_project_active_uploaded_at ON files (project_id, uploaded_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_files_deleted_by_user_id ON files (deleted_by_user_id) WHERE deleted_by_user_id IS NOT NULL;

CREATE INDEX idx_usage_statements_project_id ON usage_statements (project_id);
CREATE INDEX idx_usage_statements_report_month ON usage_statements (report_month DESC);
CREATE INDEX idx_usage_statements_status_code ON usage_statements (status_code);

CREATE INDEX idx_usage_statement_summaries_category_code ON usage_statement_summaries (category_code);

CREATE INDEX idx_usage_statement_items_statement_date ON usage_statement_items (usage_statement_id, used_on DESC);
CREATE INDEX idx_usage_statement_items_statement_category ON usage_statement_items (usage_statement_id, category_code);
CREATE INDEX idx_usage_statement_items_category_date ON usage_statement_items (category_code, used_on DESC);

CREATE INDEX idx_evidence_file_links_evidence_type_code ON evidence_file_links (evidence_type_code);
CREATE INDEX idx_evidence_file_links_checked_at ON evidence_file_links (checked_at) WHERE checked_at IS NOT NULL;
CREATE INDEX idx_evidence_file_links_unchecked ON evidence_file_links (usage_statement_item_id, file_id) WHERE checked_at IS NULL;

CREATE UNIQUE INDEX uq_evidence_requirements_active_item_type
    ON evidence_requirements (usage_statement_item_id, evidence_type_code)
    WHERE is_active = true;

CREATE INDEX idx_evidence_requirements_active_unsatisfied
    ON evidence_requirements (usage_statement_item_id, evidence_type_code)
    WHERE is_active = true AND is_satisfied = false;

CREATE INDEX idx_evidence_requirements_evidence_type_code ON evidence_requirements (evidence_type_code);

CREATE INDEX idx_agent_logs_project_created_at ON agent_logs (project_id, created_at DESC);
CREATE INDEX idx_agent_logs_statement_created_at ON agent_logs (usage_statement_id, created_at DESC)
    WHERE usage_statement_id IS NOT NULL;
CREATE INDEX idx_agent_logs_type_status_created_at ON agent_logs (agent_type_code, status_code, created_at DESC);
CREATE INDEX idx_agent_logs_details_gin ON agent_logs USING GIN (details);
CREATE INDEX idx_agent_logs_result_code ON agent_logs (result_code) WHERE result_code IS NOT NULL;
CREATE INDEX idx_agent_logs_item_id ON agent_logs (usage_statement_item_id) WHERE usage_statement_item_id IS NOT NULL;

CREATE UNIQUE INDEX uq_agent_logs_item_type
    ON agent_logs (usage_statement_item_id, agent_type_code)
    WHERE usage_statement_item_id IS NOT NULL;

CREATE UNIQUE INDEX uq_agent_logs_statement_type
    ON agent_logs (usage_statement_id, agent_type_code)
    WHERE usage_statement_item_id IS NULL;


CREATE INDEX idx_agent_usage_records_user_project_date
    ON agent_usage_records (user_id, project_id, created_at);

CREATE INDEX idx_agent_usage_records_project_date
    ON agent_usage_records (project_id, created_at);

-- ─────────────────────────────────────────────────────────────
-- updated_at trigger
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_projects_set_updated_at
BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_usage_statements_set_updated_at
BEFORE UPDATE ON usage_statements FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_usage_statement_summaries_set_updated_at
BEFORE UPDATE ON usage_statement_summaries FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_usage_statement_items_set_updated_at
BEFORE UPDATE ON usage_statement_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_evidence_file_links_set_updated_at
BEFORE UPDATE ON evidence_file_links FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_evidence_requirements_set_updated_at
BEFORE UPDATE ON evidence_requirements FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_agent_logs_set_updated_at
BEFORE UPDATE ON agent_logs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
-- ─────────────────────────────────────────────────────────────
-- Column comments
-- ─────────────────────────────────────────────────────────────

COMMENT ON COLUMN users.id IS '사용자ID';
COMMENT ON COLUMN users.employee_no IS '로그인용 사번';
COMMENT ON COLUMN users.real_name IS '실제 이름';
COMMENT ON COLUMN users.password_hash IS '비밀번호해시';
COMMENT ON COLUMN users.role_code IS '권한 (system_admin/admin/user/agent)';
COMMENT ON COLUMN users.created_at IS '생성일시';
COMMENT ON COLUMN users.updated_at IS '수정일시';

COMMENT ON COLUMN projects.id IS '프로젝트ID';
COMMENT ON COLUMN projects.construction_company IS '건설업체';
COMMENT ON COLUMN projects.project_name IS '공사명';
COMMENT ON COLUMN projects.site_location IS '소재지';
COMMENT ON COLUMN projects.representative_name IS '대표자';
COMMENT ON COLUMN projects.contract_amount IS '공사금액';
COMMENT ON COLUMN projects.construction_start_date IS '공사시작일';
COMMENT ON COLUMN projects.construction_end_date IS '공사종료일';
COMMENT ON COLUMN projects.client_name IS '발주자';
COMMENT ON COLUMN projects.appropriated_amount IS '계상금액';
COMMENT ON COLUMN projects.project_status_code IS '프로젝트진행상태 (active/completed/suspended)';
COMMENT ON COLUMN projects.created_at IS '생성일시';
COMMENT ON COLUMN projects.updated_at IS '수정일시';

COMMENT ON COLUMN usage_categories.code IS '카테고리코드';
COMMENT ON COLUMN usage_categories.name IS '카테고리명';

COMMENT ON COLUMN usage_statements.id IS '사용내역서ID';
COMMENT ON COLUMN usage_statements.project_id IS '프로젝트ID';
COMMENT ON COLUMN usage_statements.source_file_id IS '원본PDF파일ID';
COMMENT ON COLUMN usage_statements.report_month IS '보고월 (해당월 1일로 저장)';
COMMENT ON COLUMN usage_statements.revision_no IS '개정번호';
COMMENT ON COLUMN usage_statements.document_written_date IS '문서작성일';
COMMENT ON COLUMN usage_statements.cumulative_progress_rate IS '누계공정률';
COMMENT ON COLUMN usage_statements.status_code IS '사용내역서 제출·검토 단계 (draft → upload_completed → supplement_required → review_completed)';
COMMENT ON COLUMN usage_statements.created_at IS '생성일시';
COMMENT ON COLUMN usage_statements.updated_at IS '수정일시';

COMMENT ON COLUMN usage_statement_summaries.id IS '요약항목ID';
COMMENT ON COLUMN usage_statement_summaries.usage_statement_id IS '사용내역서ID';
COMMENT ON COLUMN usage_statement_summaries.category_code IS '카테고리코드';
COMMENT ON COLUMN usage_statement_summaries.previous_amount IS '전회금액';
COMMENT ON COLUMN usage_statement_summaries.current_amount IS '금회금액';
COMMENT ON COLUMN usage_statement_summaries.cumulative_amount IS '누계금액';
COMMENT ON COLUMN usage_statement_summaries.created_at IS '생성일시';
COMMENT ON COLUMN usage_statement_summaries.updated_at IS '수정일시';

COMMENT ON COLUMN usage_statement_items.id IS '상세항목ID';
COMMENT ON COLUMN usage_statement_items.usage_statement_id IS '사용내역서ID';
COMMENT ON COLUMN usage_statement_items.category_code IS '카테고리코드';
COMMENT ON COLUMN usage_statement_items.used_on IS '사용일자';
COMMENT ON COLUMN usage_statement_items.item_name IS '품목';
COMMENT ON COLUMN usage_statement_items.unit IS '단위';
COMMENT ON COLUMN usage_statement_items.quantity IS '수량';
COMMENT ON COLUMN usage_statement_items.unit_price IS '단가';
COMMENT ON COLUMN usage_statement_items.total_amount IS '합계';
COMMENT ON COLUMN usage_statement_items.remark IS '비고';
COMMENT ON COLUMN usage_statement_items.page_no IS '페이지번호';
COMMENT ON COLUMN usage_statement_items.created_at IS '생성일시';
COMMENT ON COLUMN usage_statement_items.updated_at IS '수정일시';

COMMENT ON COLUMN files.id IS '파일ID';
COMMENT ON COLUMN files.project_id IS '어느 프로젝트에 올렸나';
COMMENT ON COLUMN files.uploaded_by_user_id IS '업로드사용자ID';
COMMENT ON COLUMN files.uploaded_evidence_type_code IS '유저가업로드할때선택한증빙유형코드';
COMMENT ON COLUMN files.original_filename IS '원본파일명';
COMMENT ON COLUMN files.storage_key IS '저장경로 (S3 key 등)';
COMMENT ON COLUMN files.mime_type IS 'MIME유형';
COMMENT ON COLUMN files.size_bytes IS '파일크기(bytes)';
COMMENT ON COLUMN files.captured_at IS '촬영일시 (현장사진인 경우 EXIF 등)';
COMMENT ON COLUMN files.uploaded_at IS '업로드일시';
COMMENT ON COLUMN files.deleted_at IS '소프트삭제일시';
COMMENT ON COLUMN files.deleted_by_user_id IS '삭제한사용자ID';
COMMENT ON COLUMN files.detail IS '파일 부가 정보 (현장사진 EXIF, AI 분석 결과 등) — FastAPI가 기록';

COMMENT ON COLUMN evidence_file_links.id IS '매핑ID';
COMMENT ON COLUMN evidence_file_links.usage_statement_item_id IS '증빙 대상 상세항목ID';
COMMENT ON COLUMN evidence_file_links.file_id IS '증빙 파일ID';
COMMENT ON COLUMN evidence_file_links.evidence_type_code IS '증빙유형 (receipt / site_photo / etc)';
COMMENT ON COLUMN evidence_file_links.checked_at IS '사용자 확인 일시';
COMMENT ON COLUMN evidence_file_links.created_at IS '생성일시';
COMMENT ON COLUMN evidence_file_links.updated_at IS '수정일시';

COMMENT ON COLUMN evidence_requirements.evidence_type_code IS 'receipt / site_photo / etc';
COMMENT ON COLUMN evidence_requirements.is_satisfied IS '제출완료여부';
COMMENT ON COLUMN evidence_requirements.is_active IS 'Agent 재실행 시 무효화 플래그';

COMMENT ON COLUMN evidence_types.code IS '증빙유형코드 (receipt / site_photo / etc)';
COMMENT ON COLUMN evidence_types.name IS '증빙유형명';
COMMENT ON COLUMN evidence_types.description IS '설명';

COMMENT ON COLUMN agent_logs.id IS 'agent 로그 ID';
COMMENT ON COLUMN agent_logs.agent_type_code IS '실행한 에이전트 코드 (classi / safety-doc / link / vision / legal / report / orchestrator)';
COMMENT ON COLUMN agent_logs.status_code IS '실행 상태 (pending / running / success / fail / canceled)';
COMMENT ON COLUMN agent_logs.result_code IS '판단 결과 (success / hil / fail) — status=success일 때만 유효';
COMMENT ON COLUMN agent_logs.reason IS '프론트 표시용 한 줄 사유';
COMMENT ON COLUMN agent_logs.details IS '에이전트별 추가 페이로드 JSONB (issue_type, 수치 등)';
COMMENT ON COLUMN agent_logs.model_name IS '사용된 AI 모델명';
COMMENT ON COLUMN agent_logs.token IS '사용 토큰 수';
COMMENT ON COLUMN agent_logs.usage_statement_item_id IS '상세항목ID — 항목 기준 1 row. legal·report는 NULL.';
COMMENT ON COLUMN agent_logs.updated_at IS '최종 수정일시 (update-in-place 갱신 추적용)';
COMMENT ON COLUMN agent_logs.token_current    IS '이번 회차 토큰 사용량';
COMMENT ON COLUMN agent_logs.token_cumulative IS '누적 토큰 사용량 (재실행 시 합산)';


COMMENT ON COLUMN agent_usage_records.input_tokens  IS '입력 토큰 수';
COMMENT ON COLUMN agent_usage_records.output_tokens IS '출력 토큰 수';
COMMENT ON COLUMN agent_usage_records.cost_usd      IS 'API 호출 비용 (USD), 소수점 8자리';


-- ═════════════════════════════════════════════════════════════
-- V9 편입: todos 읽기 모델 (+ V18 편입: evidence_type_code 컬럼)
--   agent_logs.details JSONB 안의 payload.todos[] 를 평탄화하여 보관하는 읽기 모델.
--   agent 실행 직후 Spring이 사용내역서 단위로 재생성(merge)한다.
--   todo_key = sha256(usage_statement_id | agent_type_code |
--                     usage_statement_item_id | category_code | reason)
--   파생 데이터이므로 item/file 참조는 FK를 걸지 않는다.
-- ═════════════════════════════════════════════════════════════

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
    evidence_type_code         VARCHAR(50),
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
COMMENT ON COLUMN service.todos.evidence_type_code IS 'safety-doc TODO가 가리키는 증빙 유형 코드(evidence_types.code). 조회 시 한글 표시명으로 변환. 해당 없으면 NULL';


-- ═════════════════════════════════════════════════════════════
-- V17 편입: 프로젝트 목록 정렬·기간 필터 인덱스
-- ═════════════════════════════════════════════════════════════

CREATE INDEX idx_projects_construction_start_date
    ON projects (construction_start_date);

CREATE INDEX idx_projects_construction_end_date
    ON projects (construction_end_date);

CREATE INDEX idx_projects_project_name_id
    ON projects (project_name, id DESC);

CREATE INDEX idx_usage_statements_project_month_revision
    ON usage_statements (project_id, report_month DESC, revision_no DESC);


-- ═════════════════════════════════════════════════════════════
-- V16 편입: 검색 trigram 인덱스 + dashboard review-needed 부분 인덱스
--   pg_trgm 이 비표준 schema 에 설치된 환경에서도 gin_trgm_ops 가 resolve 되도록
--   DO 블록으로 search_path 를 동적 설정한다.
-- ═════════════════════════════════════════════════════════════

DO $migration$
DECLARE
    ext_schema text;
BEGIN
    SELECT n.nspname INTO ext_schema
    FROM pg_extension e
    JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'pg_trgm';

    IF ext_schema IS NULL THEN
        -- 기존 체인은 V2(legal_rag)가 pg_trgm 을 legal_rag 스키마에 먼저 설치한다.
        -- 통합 후 V1 이 먼저 실행되더라도 동일하게 legal_rag 에 설치해
        -- 모든 trgm 인덱스의 연산자 클래스 스키마(legal_rag.gin_trgm_ops)를 일치시킨다.
        CREATE SCHEMA IF NOT EXISTS legal_rag;
        CREATE EXTENSION pg_trgm SCHEMA legal_rag;
        ext_schema := 'legal_rag';
    END IF;

    EXECUTE 'SET LOCAL search_path = service, ' || quote_ident(ext_schema) || ', public, pg_catalog';

    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_projects_project_name_trgm
                 ON service.projects USING gin (LOWER(project_name) gin_trgm_ops)';

    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_projects_contract_no_trgm
                 ON service.projects USING gin (LOWER(contract_no) gin_trgm_ops)';

    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_users_real_name_trgm
                 ON service.users USING gin (LOWER(real_name) gin_trgm_ops)';
END
$migration$;

CREATE INDEX IF NOT EXISTS idx_usage_statements_review_needed
    ON service.usage_statements (project_id)
    WHERE status_code IN ('upload_completed', 'supplement_required');
