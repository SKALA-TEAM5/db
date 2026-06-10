-- =============================================================
-- V7__cleanup_mockup_projects.sql
-- V6 목업 데이터 중 프로젝트/사용내역서/증빙 관련 데이터 삭제
-- 사용자(users) 데이터는 유지
-- =============================================================
SET LOCAL search_path TO service, public;

-- FK 순서에 따라 자식 테이블부터 삭제

DELETE FROM agent_usage_records;
DELETE FROM agent_logs;
DELETE FROM evidence_requirements;
DELETE FROM evidence_file_links;
DELETE FROM usage_statement_items;
DELETE FROM usage_statement_summaries;
DELETE FROM usage_statements;
DELETE FROM files;
DELETE FROM project_user_assignments;
DELETE FROM projects;
