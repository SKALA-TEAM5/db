-- 검색 성능 개선: LIKE '%keyword%' 풀스캔 해소 (보고서: Stress p99 93s → 인덱스로 단축 기대)
-- - GET /projects?keyword=... : projects.project_name, contract_no LIKE
-- - GET /projects?assigneeName=... : users.real_name LIKE
-- - 모든 패턴이 LOWER(컬럼) LIKE 형태이므로 expression index + gin_trgm_ops 적용
--
-- 주의: pg_trgm 이 비표준 schema(예: extensions)에 설치된 환경(AWS RDS 등)에서도
--       gin_trgm_ops 가 resolve 되도록 DO 블록으로 search_path 를 동적 설정한다.

DO $migration$
DECLARE
    ext_schema text;
BEGIN
    -- pg_trgm 확장이 설치된 schema 조회 (없으면 public 에 신규 설치)
    SELECT n.nspname INTO ext_schema
    FROM pg_extension e
    JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'pg_trgm';

    IF ext_schema IS NULL THEN
        CREATE EXTENSION pg_trgm SCHEMA public;
        ext_schema := 'public';
    END IF;

    -- pg_trgm 의 실제 schema 를 search_path 에 포함시켜 unqualified gin_trgm_ops 가 resolve 되게 함
    EXECUTE 'SET LOCAL search_path = service, ' || quote_ident(ext_schema) || ', public, pg_catalog';

    -- projects.project_name (LOWER 표현식 매칭)
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_projects_project_name_trgm
                 ON service.projects USING gin (LOWER(project_name) gin_trgm_ops)';

    -- projects.contract_no (NULL 가능 → COALESCE 매칭과 동일하게 LOWER만 적용)
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_projects_contract_no_trgm
                 ON service.projects USING gin (LOWER(contract_no) gin_trgm_ops)';

    -- users.real_name (담당자 이름 검색)
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_users_real_name_trgm
                 ON service.users USING gin (LOWER(real_name) gin_trgm_ops)';
END
$migration$;

-- dashboard 집계: reviewNeededProjects (status IN ('upload_completed','supplement_required')) 풀스캔 해소
-- - GET /dashboard : 보고서 Stress p99 91s
-- - usage_statements.status_code 필터를 자주 사용 → 부분 인덱스로 review needed 집합만 빠르게 조회
-- - pg_trgm 무관하므로 DO 블록 밖
CREATE INDEX IF NOT EXISTS idx_usage_statements_review_needed
    ON service.usage_statements (project_id)
    WHERE status_code IN ('upload_completed', 'supplement_required');
