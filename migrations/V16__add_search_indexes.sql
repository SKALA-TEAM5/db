-- 검색 성능 개선: LIKE '%keyword%' 풀스캔 해소 (보고서: Stress p99 93s → 인덱스로 단축 기대)
-- - GET /projects?keyword=... : projects.project_name, contract_no LIKE
-- - GET /projects?assigneeName=... : users.real_name LIKE
-- - 모든 패턴이 LOWER(컬럼) LIKE 형태이므로 expression index + gin_trgm_ops 적용

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- projects.project_name (LOWER 표현식 매칭)
CREATE INDEX IF NOT EXISTS idx_projects_project_name_trgm
    ON service.projects USING gin (LOWER(project_name) gin_trgm_ops);

-- projects.contract_no (NULL 가능 → COALESCE 매칭과 동일하게 LOWER만 적용)
CREATE INDEX IF NOT EXISTS idx_projects_contract_no_trgm
    ON service.projects USING gin (LOWER(contract_no) gin_trgm_ops);

-- users.real_name (담당자 이름 검색)
CREATE INDEX IF NOT EXISTS idx_users_real_name_trgm
    ON service.users USING gin (LOWER(real_name) gin_trgm_ops);

-- dashboard 집계: reviewNeededProjects (status IN ('upload_completed','supplement_required')) 풀스캔 해소
-- - GET /dashboard : 보고서 Stress p99 91s
-- - usage_statements.status_code 필터를 자주 사용 → 부분 인덱스로 review needed 집합만 빠르게 조회
CREATE INDEX IF NOT EXISTS idx_usage_statements_review_needed
    ON service.usage_statements (project_id)
    WHERE status_code IN ('upload_completed', 'supplement_required');
