-- -----------------------------------------------------------------------------
-- Schema separation in a single RDB (PostgreSQL)
--   - service   : application/service domain tables
--   - legal_rag : legal data + RAG-oriented tables
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS legal_rag;

-- All objects in this file are created under legal_rag.
SET LOCAL search_path TO legal_rag, public;

-- Trigram indexes are useful for Korean substring search over legal text, titles, and patterns.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- -----------------------------------------------------------------------------
-- 법령 소스 문서
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_source_documents (
    source_id      TEXT PRIMARY KEY,
    source_name    TEXT NOT NULL,
    source_type    TEXT NOT NULL,
    source_path    TEXT NOT NULL,
    title          TEXT,
    effective_date DATE,
    notice_no      TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_legal_source_documents_source_type
        CHECK (source_type IN ('law', 'guideline', 'qa'))
);

COMMENT ON TABLE legal_source_documents IS '법령 소스 문서';
COMMENT ON COLUMN legal_source_documents.source_id IS '법령 소스 문서 고유ID';
COMMENT ON COLUMN legal_source_documents.source_name IS '소스명 (예: 산업안전보건관리비계상및사용기준)';
COMMENT ON COLUMN legal_source_documents.source_type IS '소스유형 (law / guideline / qa)';
COMMENT ON COLUMN legal_source_documents.source_path IS '원본 파일 경로 또는 URL';
COMMENT ON COLUMN legal_source_documents.title IS '문서 제목';
COMMENT ON COLUMN legal_source_documents.effective_date IS '시행일';
COMMENT ON COLUMN legal_source_documents.notice_no IS '고시번호';
COMMENT ON COLUMN legal_source_documents.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_source_documents_source_type
    ON legal_source_documents (source_type);

CREATE INDEX IF NOT EXISTS idx_legal_source_documents_effective_date
    ON legal_source_documents (effective_date)
    WHERE effective_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_source_documents_notice_no
    ON legal_source_documents (notice_no)
    WHERE notice_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_source_documents_title_trgm
    ON legal_source_documents USING gin (title gin_trgm_ops)
    WHERE title IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 법령 본문 청크
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_corpus (
    corpus_id    TEXT PRIMARY KEY,
    source_id    TEXT NOT NULL,
    content_type TEXT NOT NULL,
    title        TEXT,
    article_no   TEXT,
    section_path TEXT,
    body         TEXT NOT NULL,
    cited_laws   TEXT[],
    metadata     JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_legal_corpus_source
        FOREIGN KEY (source_id)
        REFERENCES legal_source_documents (source_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_legal_corpus_content_type
        CHECK (content_type IN ('article', 'appendix', 'qa', 'guideline'))
);

COMMENT ON TABLE legal_corpus IS '법령 본문 청크';
COMMENT ON COLUMN legal_corpus.corpus_id IS '법령 본문 청크 고유ID';
COMMENT ON COLUMN legal_corpus.source_id IS '출처 소스 문서ID';
COMMENT ON COLUMN legal_corpus.content_type IS '본문 유형 (article / appendix / qa / guideline)';
COMMENT ON COLUMN legal_corpus.title IS '조문 또는 섹션 제목';
COMMENT ON COLUMN legal_corpus.article_no IS '조항 번호 (예: 제7조)';
COMMENT ON COLUMN legal_corpus.section_path IS '섹션 계층 경로 (예: 제7조 > 제1항 > 제2호)';
COMMENT ON COLUMN legal_corpus.body IS '실제 법령 본문';
COMMENT ON COLUMN legal_corpus.cited_laws IS '본문 내 인용된 법령 조항 목록';
COMMENT ON COLUMN legal_corpus.metadata IS '추가 메타 (breadcrumb, 헤더 등)';
COMMENT ON COLUMN legal_corpus.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_corpus_source_id
    ON legal_corpus (source_id);

CREATE INDEX IF NOT EXISTS idx_legal_corpus_content_type
    ON legal_corpus (content_type);

CREATE INDEX IF NOT EXISTS idx_legal_corpus_article_no
    ON legal_corpus (article_no)
    WHERE article_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_corpus_source_content_type
    ON legal_corpus (source_id, content_type);

CREATE INDEX IF NOT EXISTS idx_legal_corpus_metadata_gin
    ON legal_corpus USING gin (metadata jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_legal_corpus_cited_laws_gin
    ON legal_corpus USING gin (cited_laws)
    WHERE cited_laws IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_corpus_body_trgm
    ON legal_corpus USING gin (body gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_legal_corpus_title_trgm
    ON legal_corpus USING gin (title gin_trgm_ops)
    WHERE title IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_corpus_section_path_trgm
    ON legal_corpus USING gin (section_path gin_trgm_ops)
    WHERE section_path IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 법령 인용 단위
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_citations (
    citation_id   TEXT PRIMARY KEY,
    source_id     TEXT NOT NULL,
    parent_type   TEXT NOT NULL,
    parent_id     TEXT NOT NULL,
    sequence_no   INTEGER NOT NULL,
    citation_text TEXT NOT NULL,
    article_no    TEXT,
    paragraph_no  TEXT,
    item_no       TEXT,
    subitem_no    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_legal_citations_source
        FOREIGN KEY (source_id)
        REFERENCES legal_source_documents (source_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_legal_citations_parent_type
        CHECK (parent_type IN ('corpus', 'rule')),

    CONSTRAINT chk_legal_citations_sequence_no
        CHECK (sequence_no > 0),

    CONSTRAINT uq_legal_citations_parent_sequence
        UNIQUE (parent_type, parent_id, sequence_no)
);

COMMENT ON TABLE legal_citations IS '법령 인용 단위';
COMMENT ON COLUMN legal_citations.citation_id IS '인용 단위 고유ID';
COMMENT ON COLUMN legal_citations.source_id IS '출처 소스 문서ID';
COMMENT ON COLUMN legal_citations.parent_type IS '상위 객체 유형 (corpus / rule)';
COMMENT ON COLUMN legal_citations.parent_id IS '상위 객체 ID';
COMMENT ON COLUMN legal_citations.sequence_no IS '같은 부모 내 인용 순번';
COMMENT ON COLUMN legal_citations.citation_text IS '인용 원문 텍스트';
COMMENT ON COLUMN legal_citations.article_no IS '인용된 조항 번호';
COMMENT ON COLUMN legal_citations.paragraph_no IS '항 번호 (예: 제1항)';
COMMENT ON COLUMN legal_citations.item_no IS '호 번호 (예: 제2호)';
COMMENT ON COLUMN legal_citations.subitem_no IS '목 번호';
COMMENT ON COLUMN legal_citations.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_citations_source_id
    ON legal_citations (source_id);

CREATE INDEX IF NOT EXISTS idx_legal_citations_parent
    ON legal_citations (parent_type, parent_id);

CREATE INDEX IF NOT EXISTS idx_legal_citations_article_no
    ON legal_citations (article_no)
    WHERE article_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_citations_article_detail
    ON legal_citations (article_no, paragraph_no, item_no, subitem_no)
    WHERE article_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_citations_text_trgm
    ON legal_citations USING gin (citation_text gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- 법령 규칙
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_rules (
    rule_id         TEXT PRIMARY KEY,
    source_id       TEXT NOT NULL,
    rule_type       TEXT NOT NULL,
    category_code   TEXT,
    category_number INTEGER,
    category_name   TEXT,
    allowed         BOOLEAN,
    keyword         TEXT,
    item_pattern    TEXT,
    legal_basis     TEXT,
    limit_pct       NUMERIC(6, 4),
    rule_text       TEXT NOT NULL,
    metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_legal_rules_source
        FOREIGN KEY (source_id)
        REFERENCES legal_source_documents (source_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_legal_rules_rule_type
        CHECK (rule_type IN ('allowed', 'disallowed', 'limit', 'progress', 'qa', 'category')),

    CONSTRAINT chk_legal_rules_category_number
        CHECK (category_number IS NULL OR category_number BETWEEN 1 AND 9),

    CONSTRAINT chk_legal_rules_limit_pct
        CHECK (limit_pct IS NULL OR (limit_pct >= 0 AND limit_pct <= 1))
);

COMMENT ON TABLE legal_rules IS '법령 규칙';
COMMENT ON COLUMN legal_rules.rule_id IS '법령 규칙 고유ID';
COMMENT ON COLUMN legal_rules.source_id IS '출처 소스 문서ID';
COMMENT ON COLUMN legal_rules.rule_type IS '규칙 유형 (allowed / disallowed / limit / progress / qa)';
COMMENT ON COLUMN legal_rules.category_code IS '적용 카테고리코드 (CAT_01~CAT_09, null이면 전체 적용)';
COMMENT ON COLUMN legal_rules.category_number IS '카테고리 번호 (1~9)';
COMMENT ON COLUMN legal_rules.category_name IS '카테고리 한글명';
COMMENT ON COLUMN legal_rules.allowed IS '허용 여부 (true=허용, false=불가, null=조건부)';
COMMENT ON COLUMN legal_rules.keyword IS '검색/매칭용 핵심 키워드';
COMMENT ON COLUMN legal_rules.item_pattern IS '품목명 패턴 (정규식 또는 키워드)';
COMMENT ON COLUMN legal_rules.legal_basis IS '법적 근거 조항 (예: 제7조제1항제2호)';
COMMENT ON COLUMN legal_rules.limit_pct IS '카테고리별 법령상 한도 비율 (예: 0.2 = 20%)';
COMMENT ON COLUMN legal_rules.rule_text IS '규칙 원문';
COMMENT ON COLUMN legal_rules.metadata IS '추가 메타';
COMMENT ON COLUMN legal_rules.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_rules_source_id
    ON legal_rules (source_id);

CREATE INDEX IF NOT EXISTS idx_legal_rules_category_code
    ON legal_rules (category_code)
    WHERE category_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rules_rule_type
    ON legal_rules (rule_type);

CREATE INDEX IF NOT EXISTS idx_legal_rules_category_rule_type
    ON legal_rules (category_code, rule_type)
    WHERE category_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rules_legal_basis
    ON legal_rules (legal_basis)
    WHERE legal_basis IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rules_metadata_gin
    ON legal_rules USING gin (metadata jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_legal_rules_keyword_trgm
    ON legal_rules USING gin (keyword gin_trgm_ops)
    WHERE keyword IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rules_item_pattern_trgm
    ON legal_rules USING gin (item_pattern gin_trgm_ops)
    WHERE item_pattern IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rules_rule_text_trgm
    ON legal_rules USING gin (rule_text gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- 법령 규칙 프로파일
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_rule_profiles (
    profile_id    TEXT PRIMARY KEY,
    profile_scope TEXT NOT NULL,
    category_code TEXT,
    profile_key   TEXT NOT NULL,
    values_json   JSONB NOT NULL,
    metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_legal_rule_profiles_profile_scope
        CHECK (profile_scope IN ('category', 'global', 'item')),

    CONSTRAINT chk_legal_rule_profiles_global_category
        CHECK ((profile_scope = 'global' AND category_code IS NULL) OR profile_scope <> 'global'),

    CONSTRAINT uq_legal_rule_profiles_scope_category_key
        UNIQUE (profile_scope, category_code, profile_key)
);

COMMENT ON TABLE legal_rule_profiles IS '법령 규칙 프로파일';
COMMENT ON COLUMN legal_rule_profiles.profile_id IS '프로파일 고유ID';
COMMENT ON COLUMN legal_rule_profiles.profile_scope IS '프로파일 적용 범위 (category / global / item)';
COMMENT ON COLUMN legal_rule_profiles.category_code IS '적용 카테고리코드 (global이면 null)';
COMMENT ON COLUMN legal_rule_profiles.profile_key IS '프로파일 키 (예: allowed_keywords / disallowed_patterns)';
COMMENT ON COLUMN legal_rule_profiles.values_json IS '프로파일 값 목록 (JSON 배열 또는 객체)';
COMMENT ON COLUMN legal_rule_profiles.metadata IS '추가 메타';
COMMENT ON COLUMN legal_rule_profiles.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_rule_profiles_scope_category
    ON legal_rule_profiles (profile_scope, category_code);

CREATE INDEX IF NOT EXISTS idx_legal_rule_profiles_profile_key
    ON legal_rule_profiles (profile_key);

CREATE INDEX IF NOT EXISTS idx_legal_rule_profiles_values_json_gin
    ON legal_rule_profiles USING gin (values_json jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_legal_rule_profiles_metadata_gin
    ON legal_rule_profiles USING gin (metadata jsonb_path_ops);

-- -----------------------------------------------------------------------------
-- 통합 법령 마스터
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS legal_rule_master (
    master_id     TEXT PRIMARY KEY,
    source_id     TEXT,
    source_name   TEXT,
    source_type   TEXT,
    record_type   TEXT NOT NULL,
    content_type  TEXT,
    rule_type     TEXT,
    profile_scope TEXT,
    category_code TEXT,
    category_name TEXT,
    article_no    TEXT,
    title         TEXT,
    section_path  TEXT,
    legal_basis   TEXT,
    item_key      TEXT,
    item_pattern  TEXT,
    allowed       BOOLEAN,
    limit_pct     NUMERIC(6, 4),
    body          TEXT NOT NULL,
    cited_laws    TEXT[],
    keywords      TEXT[],
    metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_legal_rule_master_source
        FOREIGN KEY (source_id)
        REFERENCES legal_source_documents (source_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_legal_rule_master_source_type
        CHECK (source_type IS NULL OR source_type IN ('law', 'guideline', 'qa')),

    CONSTRAINT chk_legal_rule_master_record_type
        CHECK (record_type IN ('corpus', 'rule', 'profile')),

    CONSTRAINT chk_legal_rule_master_content_type
        CHECK (content_type IS NULL OR content_type IN ('article', 'appendix', 'qa', 'guideline')),

    CONSTRAINT chk_legal_rule_master_rule_type
        CHECK (rule_type IS NULL OR rule_type IN ('allowed', 'disallowed', 'limit', 'progress', 'qa', 'category')),

    CONSTRAINT chk_legal_rule_master_profile_scope
        CHECK (profile_scope IS NULL OR profile_scope IN ('category', 'global', 'item')),

    CONSTRAINT chk_legal_rule_master_limit_pct
        CHECK (limit_pct IS NULL OR (limit_pct >= 0 AND limit_pct <= 1))
);

COMMENT ON TABLE legal_rule_master IS '통합 법령 마스터';
COMMENT ON COLUMN legal_rule_master.master_id IS '통합 마스터 레코드 고유ID';
COMMENT ON COLUMN legal_rule_master.source_id IS '출처 소스 문서ID';
COMMENT ON COLUMN legal_rule_master.source_name IS '소스명 (조회 최적화용 비정규화)';
COMMENT ON COLUMN legal_rule_master.source_type IS '소스유형 (조회 최적화용 비정규화)';
COMMENT ON COLUMN legal_rule_master.record_type IS '레코드 유형 (corpus / rule / profile) — 단일 테이블 통합 관리용';
COMMENT ON COLUMN legal_rule_master.content_type IS '본문 유형 (corpus일 때만 사용)';
COMMENT ON COLUMN legal_rule_master.rule_type IS '규칙 유형 (rule일 때만 사용)';
COMMENT ON COLUMN legal_rule_master.profile_scope IS '프로파일 범위 (profile일 때만 사용)';
COMMENT ON COLUMN legal_rule_master.category_code IS '적용 카테고리코드 (CAT_01~CAT_09)';
COMMENT ON COLUMN legal_rule_master.category_name IS '카테고리 한글명';
COMMENT ON COLUMN legal_rule_master.article_no IS '조항 번호';
COMMENT ON COLUMN legal_rule_master.title IS '조문 또는 섹션 제목';
COMMENT ON COLUMN legal_rule_master.section_path IS '섹션 계층 경로';
COMMENT ON COLUMN legal_rule_master.legal_basis IS '법적 근거 조항';
COMMENT ON COLUMN legal_rule_master.item_key IS '품목 식별 키';
COMMENT ON COLUMN legal_rule_master.item_pattern IS '품목명 패턴';
COMMENT ON COLUMN legal_rule_master.allowed IS '허용 여부 (null=조건부)';
COMMENT ON COLUMN legal_rule_master.limit_pct IS '법령상 한도 비율 (0.2 = 20%)';
COMMENT ON COLUMN legal_rule_master.body IS '본문 또는 규칙 원문 (VectorDB 임베딩 대상)';
COMMENT ON COLUMN legal_rule_master.cited_laws IS '인용 법령 조항 목록';
COMMENT ON COLUMN legal_rule_master.keywords IS 'RDB 매칭용 핵심 키워드 배열';
COMMENT ON COLUMN legal_rule_master.metadata IS '추가 메타';
COMMENT ON COLUMN legal_rule_master.created_at IS '생성일시';

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_record_type
    ON legal_rule_master (record_type);

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_category_code
    ON legal_rule_master (category_code)
    WHERE category_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_source_id
    ON legal_rule_master (source_id)
    WHERE source_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_record_category
    ON legal_rule_master (record_type, category_code)
    WHERE category_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_source_record
    ON legal_rule_master (source_id, record_type)
    WHERE source_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_article_no
    ON legal_rule_master (article_no)
    WHERE article_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_rule_type
    ON legal_rule_master (rule_type)
    WHERE rule_type IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_profile_scope
    ON legal_rule_master (profile_scope)
    WHERE profile_scope IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_legal_basis
    ON legal_rule_master (legal_basis)
    WHERE legal_basis IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_item_key
    ON legal_rule_master (item_key)
    WHERE item_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_cited_laws_gin
    ON legal_rule_master USING gin (cited_laws)
    WHERE cited_laws IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_keywords_gin
    ON legal_rule_master USING gin (keywords)
    WHERE keywords IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_metadata_gin
    ON legal_rule_master USING gin (metadata jsonb_path_ops);

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_body_trgm
    ON legal_rule_master USING gin (body gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_title_trgm
    ON legal_rule_master USING gin (title gin_trgm_ops)
    WHERE title IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_rule_master_item_pattern_trgm
    ON legal_rule_master USING gin (item_pattern gin_trgm_ops)
    WHERE item_pattern IS NOT NULL;
