-- ============================================================
-- PostgreSQL DDL
-- Generated from DBML schema
-- ============================================================

-- ─── Extensions ─────────────────────────────────────────────

-- pgcrypto는 필요 시 활성화 (password_hash 생성 등)
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ─── Tables ─────────────────────────────────────────────────

CREATE TABLE users (
    id              BIGSERIAL       PRIMARY KEY,
    username        VARCHAR(100)    NOT NULL UNIQUE,
    password_hash   TEXT            NOT NULL,
    role_code       VARCHAR(30)     NOT NULL DEFAULT 'user',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN users.id            IS '사용자ID';
COMMENT ON COLUMN users.username      IS '로그인아이디';
COMMENT ON COLUMN users.password_hash IS '비밀번호해시';
COMMENT ON COLUMN users.role_code     IS '권한';
COMMENT ON COLUMN users.created_at    IS '생성일시';
COMMENT ON COLUMN users.updated_at    IS '수정일시';


CREATE TABLE projects (
    id                      BIGSERIAL       PRIMARY KEY,
    user_id                 BIGINT          NOT NULL REFERENCES users(id),
    construction_company    VARCHAR(200)    NOT NULL,
    project_name            VARCHAR(300)    NOT NULL,
    site_location           VARCHAR(500)    NOT NULL,
    representative_name     VARCHAR(100),
    contract_amount         NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    construction_start_date DATE            NOT NULL,
    construction_end_date   DATE            NOT NULL,
    client_name             VARCHAR(200),
    appropriated_amount     NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    project_status_code     VARCHAR(30)     NOT NULL DEFAULT 'active',
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_projects_status
        CHECK (project_status_code IN ('active', 'completed', 'suspended')),
    CONSTRAINT chk_projects_dates
        CHECK (construction_end_date >= construction_start_date)
);

COMMENT ON COLUMN projects.id                      IS '프로젝트ID';
COMMENT ON COLUMN projects.user_id                 IS '유저ID';
COMMENT ON COLUMN projects.construction_company    IS '건설업체';
COMMENT ON COLUMN projects.project_name            IS '공사명';
COMMENT ON COLUMN projects.site_location           IS '소재지';
COMMENT ON COLUMN projects.representative_name     IS '대표자';
COMMENT ON COLUMN projects.contract_amount         IS '공사금액';
COMMENT ON COLUMN projects.construction_start_date IS '공사시작일';
COMMENT ON COLUMN projects.construction_end_date   IS '공사종료일';
COMMENT ON COLUMN projects.client_name             IS '발주자';
COMMENT ON COLUMN projects.appropriated_amount     IS '계상금액';
COMMENT ON COLUMN projects.project_status_code     IS '프로젝트진행상태 (active/completed/suspended)';
COMMENT ON COLUMN projects.created_at              IS '생성일시';
COMMENT ON COLUMN projects.updated_at              IS '수정일시';


CREATE TABLE usage_categories (
    code    VARCHAR(50)     PRIMARY KEY,
    name    VARCHAR(200)    NOT NULL UNIQUE
);

COMMENT ON COLUMN usage_categories.code IS '카테고리코드';
COMMENT ON COLUMN usage_categories.name IS '카테고리명';


CREATE TABLE files (
    id                          BIGSERIAL       PRIMARY KEY,
    project_id                  BIGINT          NOT NULL REFERENCES projects(id),
    uploaded_by_user_id         BIGINT          NOT NULL REFERENCES users(id),
    uploaded_evidence_type_code VARCHAR(30)     NOT NULL,
    original_filename           VARCHAR(500)    NOT NULL,
    storage_key                 TEXT            NOT NULL UNIQUE,
    mime_type                   VARCHAR(150)    NOT NULL,
    size_bytes                  BIGINT          NOT NULL,
    captured_at                 TIMESTAMPTZ,
    uploaded_at                 TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN files.id                          IS '파일ID';
COMMENT ON COLUMN files.project_id                  IS '어느 프로젝트에 올렸나';
COMMENT ON COLUMN files.uploaded_by_user_id         IS '업로드사용자ID';
COMMENT ON COLUMN files.uploaded_evidence_type_code IS '유저가업로드할때선택한증빙유형코드';
COMMENT ON COLUMN files.original_filename           IS '원본파일명';
COMMENT ON COLUMN files.storage_key                 IS '저장경로 (S3 key 등)';
COMMENT ON COLUMN files.mime_type                   IS 'MIME유형';
COMMENT ON COLUMN files.size_bytes                  IS '파일크기(bytes)';
COMMENT ON COLUMN files.captured_at                 IS '촬영일시 (현장사진인 경우 EXIF 등)';
COMMENT ON COLUMN files.uploaded_at                 IS '업로드일시';


-- files 테이블 이후에 생성 (source_file_id FK 때문에)
CREATE TABLE usage_statements (
    id                      BIGSERIAL       PRIMARY KEY,
    project_id              BIGINT          NOT NULL REFERENCES projects(id),
    source_file_id          BIGINT          UNIQUE REFERENCES files(id),
    report_month            DATE            NOT NULL,  -- 해당월 1일로 저장
    revision_no             INTEGER         NOT NULL DEFAULT 1,
    document_written_date   DATE            NOT NULL,
    statement_status_code   VARCHAR(30)     NOT NULL,
    cumulative_progress_rate NUMERIC(5, 2)  NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_usage_statements_status
        CHECK (statement_status_code IN ('draft', 'reviewing', 'confirmed')),
    CONSTRAINT chk_usage_statements_progress_rate
        CHECK (cumulative_progress_rate BETWEEN 0 AND 100),
    CONSTRAINT chk_usage_statements_revision_no
        CHECK (revision_no >= 1),
    -- 동일 프로젝트·보고월·개정번호 중복 방지
    CONSTRAINT uq_usage_statements_project_month_rev
        UNIQUE (project_id, report_month, revision_no)
);

COMMENT ON COLUMN usage_statements.id                       IS '사용내역서ID';
COMMENT ON COLUMN usage_statements.project_id               IS '프로젝트ID';
COMMENT ON COLUMN usage_statements.source_file_id           IS '원본PDF파일ID';
COMMENT ON COLUMN usage_statements.report_month             IS '보고월 (해당월 1일로 저장)';
COMMENT ON COLUMN usage_statements.revision_no              IS '개정번호';
COMMENT ON COLUMN usage_statements.document_written_date    IS '문서작성일';
COMMENT ON COLUMN usage_statements.statement_status_code    IS '내역서업무진행상태 (draft/reviewing/confirmed)';
COMMENT ON COLUMN usage_statements.cumulative_progress_rate IS '누계공정률';
COMMENT ON COLUMN usage_statements.created_at               IS '생성일시';
COMMENT ON COLUMN usage_statements.updated_at               IS '수정일시';


CREATE TABLE usage_statement_summaries (
    id                   BIGSERIAL       PRIMARY KEY,
    usage_statement_id   BIGINT          NOT NULL REFERENCES usage_statements(id),
    category_code        VARCHAR(50)     NOT NULL REFERENCES usage_categories(code),
    previous_amount      NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    current_amount       NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    cumulative_amount    NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_usage_statement_summaries_stmt_cat
        UNIQUE (usage_statement_id, category_code)
);

COMMENT ON COLUMN usage_statement_summaries.id                 IS '요약항목ID';
COMMENT ON COLUMN usage_statement_summaries.usage_statement_id IS '사용내역서ID';
COMMENT ON COLUMN usage_statement_summaries.category_code      IS '카테고리코드';
COMMENT ON COLUMN usage_statement_summaries.previous_amount    IS '전회금액';
COMMENT ON COLUMN usage_statement_summaries.current_amount     IS '금회금액';
COMMENT ON COLUMN usage_statement_summaries.cumulative_amount  IS '누계금액';
COMMENT ON COLUMN usage_statement_summaries.created_at         IS '생성일시';
COMMENT ON COLUMN usage_statement_summaries.updated_at         IS '수정일시';


CREATE TABLE usage_statement_items (
    id                   BIGSERIAL       PRIMARY KEY,
    usage_statement_id   BIGINT          NOT NULL REFERENCES usage_statements(id),
    category_code        VARCHAR(50)     NOT NULL REFERENCES usage_categories(code),
    used_on              DATE            NOT NULL,
    item_name            VARCHAR(300)    NOT NULL,
    unit                 VARCHAR(50),
    quantity             NUMERIC(14, 3)  NOT NULL DEFAULT 0,
    unit_price           NUMERIC(18, 2)  NOT NULL DEFAULT 0,
    total_amount         NUMERIC(18, 0)  NOT NULL DEFAULT 0,
    remark               VARCHAR(1000),
    page_no              INTEGER         NOT NULL,
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN usage_statement_items.id                 IS '상세항목ID';
COMMENT ON COLUMN usage_statement_items.usage_statement_id IS '사용내역서ID';
COMMENT ON COLUMN usage_statement_items.category_code      IS '카테고리코드';
COMMENT ON COLUMN usage_statement_items.used_on            IS '사용일자';
COMMENT ON COLUMN usage_statement_items.item_name          IS '품목';
COMMENT ON COLUMN usage_statement_items.unit               IS '단위';
COMMENT ON COLUMN usage_statement_items.quantity           IS '수량';
COMMENT ON COLUMN usage_statement_items.unit_price         IS '단가';
COMMENT ON COLUMN usage_statement_items.total_amount       IS '합계';
COMMENT ON COLUMN usage_statement_items.remark             IS '비고';
COMMENT ON COLUMN usage_statement_items.page_no            IS '페이지번호';
COMMENT ON COLUMN usage_statement_items.created_at         IS '생성일시';
COMMENT ON COLUMN usage_statement_items.updated_at         IS '수정일시';


CREATE TABLE evidence_types (
    code        VARCHAR(30)     PRIMARY KEY,
    name        VARCHAR(100)    NOT NULL,
    description VARCHAR(100)    NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN evidence_types.code        IS '증빙유형코드 (receipt / site_photo / etc)';
COMMENT ON COLUMN evidence_types.name        IS '증빙유형명';
COMMENT ON COLUMN evidence_types.description IS '설명';


CREATE TABLE evidence_file_links (
    id                       BIGSERIAL       PRIMARY KEY,
    usage_statement_item_id  BIGINT          NOT NULL REFERENCES usage_statement_items(id),
    file_id                  BIGINT          NOT NULL REFERENCES files(id),
    category_code            VARCHAR(50)     NOT NULL REFERENCES usage_categories(code),
    evidence_type_code       VARCHAR(30)     NOT NULL REFERENCES evidence_types(code),
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_evidence_file_links_item_file
        UNIQUE (usage_statement_item_id, file_id)
);

COMMENT ON COLUMN evidence_file_links.id                      IS '매핑ID';
COMMENT ON COLUMN evidence_file_links.usage_statement_item_id IS '증빙 대상 상세항목ID';
COMMENT ON COLUMN evidence_file_links.file_id                 IS '증빙 파일ID';
COMMENT ON COLUMN evidence_file_links.category_code           IS '증빙 카테고리 (items에서 복사, 조회 최적화)';
COMMENT ON COLUMN evidence_file_links.evidence_type_code      IS '증빙유형 (receipt / site_photo / etc)';
COMMENT ON COLUMN evidence_file_links.created_at              IS '생성일시';
COMMENT ON COLUMN evidence_file_links.updated_at              IS '수정일시';


CREATE TABLE evidence_requirements (
    id                       BIGSERIAL       PRIMARY KEY,
    usage_statement_item_id  BIGINT          NOT NULL REFERENCES usage_statement_items(id),
    evidence_type_code       VARCHAR(30)     NOT NULL REFERENCES evidence_types(code),
    is_satisfied             BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_evidence_requirements_item_type
        UNIQUE (usage_statement_item_id, evidence_type_code)
);

COMMENT ON COLUMN evidence_requirements.id                      IS '요구증빙ID';
COMMENT ON COLUMN evidence_requirements.usage_statement_item_id IS '상세항목ID';
COMMENT ON COLUMN evidence_requirements.evidence_type_code      IS 'receipt / site_photo / etc';
COMMENT ON COLUMN evidence_requirements.is_satisfied            IS '제출완료여부';
COMMENT ON COLUMN evidence_requirements.created_at              IS '생성일시';
COMMENT ON COLUMN evidence_requirements.updated_at              IS '수정일시';


CREATE TABLE validation_logs (
    id                       BIGSERIAL       PRIMARY KEY,
    project_id               BIGINT          NOT NULL REFERENCES projects(id),
    usage_statement_id       BIGINT          REFERENCES usage_statements(id),
    usage_statement_item_id  BIGINT          REFERENCES usage_statement_items(id),
    file_id                  BIGINT          REFERENCES files(id),
    validation_type_code     VARCHAR(50)     NOT NULL,
    result_code              VARCHAR(30)     NOT NULL,
    severity_code            VARCHAR(30)     NOT NULL DEFAULT 'info',
    message                  TEXT,
    details                  JSONB,
    model_name               VARCHAR(100),
    prompt_version           VARCHAR(50),
    policy_version           VARCHAR(50),
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN validation_logs.id                      IS '검증로그ID';
COMMENT ON COLUMN validation_logs.project_id              IS '프로젝트ID';
COMMENT ON COLUMN validation_logs.usage_statement_id      IS '사용내역서ID';
COMMENT ON COLUMN validation_logs.usage_statement_item_id IS '상세항목ID';
COMMENT ON COLUMN validation_logs.file_id                 IS '파일ID';
COMMENT ON COLUMN validation_logs.validation_type_code    IS '검증유형코드';
COMMENT ON COLUMN validation_logs.result_code             IS '결과코드';
COMMENT ON COLUMN validation_logs.severity_code           IS '심각도 (info/warn/error)';
COMMENT ON COLUMN validation_logs.message                 IS '검증메시지';
COMMENT ON COLUMN validation_logs.details                 IS '상세정보(JSON)';
COMMENT ON COLUMN validation_logs.model_name              IS 'AI모델명';
COMMENT ON COLUMN validation_logs.prompt_version          IS '프롬프트버전';
COMMENT ON COLUMN validation_logs.policy_version          IS '정책버전';
COMMENT ON COLUMN validation_logs.created_at              IS '생성일시';


CREATE TABLE action_requests (
    id                       BIGSERIAL       PRIMARY KEY,
    project_id               BIGINT          NOT NULL REFERENCES projects(id),
    usage_statement_id       BIGINT          REFERENCES usage_statements(id),
    usage_statement_item_id  BIGINT          REFERENCES usage_statement_items(id),
    title                    VARCHAR(300)    NOT NULL,
    reason                   TEXT,
    status_code              VARCHAR(30)     NOT NULL,
    requested_by_user_id     BIGINT          NOT NULL REFERENCES users(id),
    assignee_user_id         BIGINT          REFERENCES users(id),
    due_date                 DATE,
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    resolved_at              TIMESTAMPTZ,

    CONSTRAINT chk_action_requests_status
        CHECK (status_code IN ('open', 'in_progress', 'resolved', 'closed'))
);

COMMENT ON COLUMN action_requests.id                      IS '액션요청ID';
COMMENT ON COLUMN action_requests.project_id              IS '프로젝트ID';
COMMENT ON COLUMN action_requests.usage_statement_id      IS '관련 사용내역서ID';
COMMENT ON COLUMN action_requests.usage_statement_item_id IS '관련 상세항목ID';
COMMENT ON COLUMN action_requests.title                   IS '요청제목';
COMMENT ON COLUMN action_requests.reason                  IS '요청사유';
COMMENT ON COLUMN action_requests.status_code             IS '처리상태 (open/in_progress/resolved/closed)';
COMMENT ON COLUMN action_requests.requested_by_user_id    IS '요청자ID';
COMMENT ON COLUMN action_requests.assignee_user_id        IS '담당자ID';
COMMENT ON COLUMN action_requests.due_date                IS '처리기한';
COMMENT ON COLUMN action_requests.created_at              IS '생성일시';
COMMENT ON COLUMN action_requests.resolved_at             IS '처리완료일시';


-- ─── Indexes ────────────────────────────────────────────────

-- projects
CREATE INDEX idx_projects_user_id           ON projects (user_id);
CREATE INDEX idx_projects_status_code       ON projects (project_status_code);

-- files
CREATE INDEX idx_files_project_id           ON files (project_id);
CREATE INDEX idx_files_uploaded_by_user_id  ON files (uploaded_by_user_id);
CREATE INDEX idx_files_uploaded_at          ON files (uploaded_at DESC);

-- usage_statements
CREATE INDEX idx_usage_statements_project_id    ON usage_statements (project_id);
CREATE INDEX idx_usage_statements_report_month  ON usage_statements (report_month DESC);
CREATE INDEX idx_usage_statements_status        ON usage_statements (statement_status_code);

-- usage_statement_summaries
CREATE INDEX idx_uss_statement_id   ON usage_statement_summaries (usage_statement_id);
CREATE INDEX idx_uss_category_code  ON usage_statement_summaries (category_code);

-- usage_statement_items
CREATE INDEX idx_usi_statement_id   ON usage_statement_items (usage_statement_id);
CREATE INDEX idx_usi_category_code  ON usage_statement_items (category_code);
CREATE INDEX idx_usi_used_on        ON usage_statement_items (used_on DESC);

-- evidence_file_links (DBML 명시 인덱스 포함)
CREATE INDEX idx_evidence_file_links_file_category
    ON evidence_file_links (file_id, category_code);
-- usage_statement_item_id 단독 조회용
CREATE INDEX idx_evidence_file_links_item_id
    ON evidence_file_links (usage_statement_item_id);

-- evidence_requirements
CREATE INDEX idx_evidence_requirements_item_id
    ON evidence_requirements (usage_statement_item_id);
-- 미제출 항목 빠른 필터링
CREATE INDEX idx_evidence_requirements_unsatisfied
    ON evidence_requirements (usage_statement_item_id)
    WHERE is_satisfied = FALSE;

-- validation_logs
CREATE INDEX idx_validation_logs_project_id     ON validation_logs (project_id);
CREATE INDEX idx_validation_logs_statement_id   ON validation_logs (usage_statement_id);
CREATE INDEX idx_validation_logs_item_id        ON validation_logs (usage_statement_item_id);
CREATE INDEX idx_validation_logs_created_at     ON validation_logs (created_at DESC);
-- severity 필터링 (error/warn 조회)
CREATE INDEX idx_validation_logs_severity       ON validation_logs (severity_code, created_at DESC);

-- action_requests
CREATE INDEX idx_action_requests_project_id         ON action_requests (project_id);
CREATE INDEX idx_action_requests_statement_id        ON action_requests (usage_statement_id);
CREATE INDEX idx_action_requests_status_code         ON action_requests (status_code);
CREATE INDEX idx_action_requests_requested_by        ON action_requests (requested_by_user_id);
CREATE INDEX idx_action_requests_assignee            ON action_requests (assignee_user_id)
    WHERE assignee_user_id IS NOT NULL;
-- 미처리 요청 빠른 필터링
CREATE INDEX idx_action_requests_open
    ON action_requests (project_id, due_date)
    WHERE status_code IN ('open', 'in_progress');