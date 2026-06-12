-- =============================================================
-- V14__seed_project_user_assignments.sql
-- 개발 프로젝트 담당자 배정
--
-- 숫자 ID는 초기화 및 시퀀스 상태에 따라 달라질 수 있으므로
-- 프로젝트 계약번호와 사용자 사번을 기준으로 관계를 생성한다.
-- =============================================================
SET LOCAL search_path TO service, public;

WITH assignment_seed (
    contract_no,
    employee_no,
    assigned_by_employee_no
) AS (
    VALUES
        ('2026-0107', 'ADMIN-001', 'ADMIN-001'),
        ('2026-0106', 'ADMIN-002', 'ADMIN-002'),
        ('2026-0108', 'ADMIN-003', 'ADMIN-003'),
        ('2026-0109', 'ADMIN-004', 'ADMIN-004'),
        ('999',       'SYS-001',   'SYS-001')
)
INSERT INTO project_user_assignments (
    project_id,
    user_id,
    assigned_by_user_id
)
SELECT
    project.id,
    assigned_user.id,
    assigning_user.id
FROM assignment_seed seed
JOIN projects project
  ON project.contract_no = seed.contract_no
JOIN users assigned_user
  ON assigned_user.employee_no = seed.employee_no
JOIN users assigning_user
  ON assigning_user.employee_no = seed.assigned_by_employee_no
ON CONFLICT (project_id, user_id) DO UPDATE
SET assigned_by_user_id = EXCLUDED.assigned_by_user_id;
