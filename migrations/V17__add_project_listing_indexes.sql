-- GET /projects 무거움 해소 (보고서: Stress p99 90s)
-- - 정렬 컬럼 인덱스 부재로 ORDER BY ... LIMIT 시 정렬 비용 증가
-- - latest_statement CTE의 DISTINCT ON 패턴이 (project_id, report_month DESC, revision_no DESC) 인덱스 부재로 풀스캔

-- 1) projects 정렬·기간 필터 인덱스
--    ProjectSort: START_DATE_ASC/DESC, END_DATE_ASC/DESC
--    필터: construction_start_date <= :periodTo, construction_end_date >= :periodFrom
CREATE INDEX IF NOT EXISTS idx_projects_construction_start_date
    ON service.projects (construction_start_date);

CREATE INDEX IF NOT EXISTS idx_projects_construction_end_date
    ON service.projects (construction_end_date);

-- ProjectSort: PROJECT_NAME_ASC/DESC (tie-break id DESC)
CREATE INDEX IF NOT EXISTS idx_projects_project_name_id
    ON service.projects (project_name, id DESC);

-- 2) usage_statements latest_statement CTE 최적화
--    DISTINCT ON (project_id) ORDER BY project_id, report_month DESC, revision_no DESC
--    → 복합 인덱스로 skip-scan 가능
CREATE INDEX IF NOT EXISTS idx_usage_statements_project_month_revision
    ON service.usage_statements (project_id, report_month DESC, revision_no DESC);
