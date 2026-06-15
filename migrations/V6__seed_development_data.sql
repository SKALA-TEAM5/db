-- =============================================================
-- V6__seed_development_data.sql
-- 개발 환경 시드 데이터 (기존 V6/V7/V12/V13/V14 통합)
--
-- 기존 마이그레이션 체인의 순효과를 단일 파일로 정리:
--   · V6  : 레거시 목업 계정 시드 (V12가 덮어씀)
--   · V7  : 프로젝트/사용내역서/증빙 데이터 정리 (DELETE)
--   · V12 : 개발 계정 동기화 (최종 사용자 셋)  ← 여기로 흡수
--   · V13 : 개발 프로젝트 + 챗봇 추적용 프로젝트  ← 여기로 흡수
--   · V14 : 프로젝트 담당자 배정              ← 여기로 흡수
--
-- ON CONFLICT 멱등 처리 — 재실행/부분 적용 시에도 안전.
-- =============================================================
SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- 1. 개발 사용자
--    SYS-001 기본 비밀번호: P@ssw0rd123!
--    ADMIN-* 기본 비밀번호: Admin1234!
--    USER-*  기본 비밀번호: User1234!
-- ─────────────────────────────────────────────────────────────
INSERT INTO users (employee_no, real_name, password_hash, role_code)
VALUES
    ('SYS-001',   '이베리', '$2y$12$joImXqDiNtrBwXV6wbDo8uoEsKzYfQjD4n6flnTzs8vR6vg9cfV6m', 'system_admin'),
    ('ADMIN-001', '김동우', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('ADMIN-002', '한채윤', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('ADMIN-003', '차현주', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('ADMIN-004', '송상민', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('ADMIN-005', '이현수', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('USER-001',  '김소연', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-002',  '한준수', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-003',  '차태현', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-004',  '송지효', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-005',  '이재성', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user')
ON CONFLICT (employee_no) DO UPDATE
SET
    real_name = EXCLUDED.real_name,
    role_code = EXCLUDED.role_code,
    updated_at = now();

-- ─────────────────────────────────────────────────────────────
-- 2. 개발 프로젝트 + 챗봇 사용량 추적용 프로젝트
-- ─────────────────────────────────────────────────────────────
INSERT INTO projects (
    contract_no,
    construction_company,
    project_name,
    site_location,
    representative_name,
    contract_amount,
    construction_start_date,
    construction_end_date,
    client_name,
    appropriated_amount,
    project_status_code
)
VALUES
    ('2026-0107', '(주)한국종합건설', '부산 해운대구 주상복합 신축공사', '부산광역시 해운대구 마린시티로 45', '이건설',  2200000000, DATE '2025-05-01', DATE '2026-12-31', '해운대구청', 51810000, 'active'),
    ('2026-0106', '(주)스칼라 건설',  '서울 강남구 사무용 빌딩 신축공사', '서울특별시 강남구 테헤란로 123',  '김스칼라', 1500000000, DATE '2025-03-04', DATE '2026-07-03', '강남구청',  35349000, 'active'),
    ('2026-0108', '(주)대한토건',     '인천 연수구 물류센터 신축공사',   '인천광역시 연수구 송도과학로 87', '박토건',   980000000,  DATE '2025-06-15', DATE '2026-09-30', '연수구청',  23079000, 'active'),
    ('2026-0109', '(주)미래건설',     '대전 유성구 연구소 리모델링공사', '대전광역시 유성구 대학로 291',   '최미래',   670000000,  DATE '2025-08-01', DATE '2026-05-31', '유성구청',  15307500, 'active'),
    ('999',       'CHATBOT-999',      '챗봇',                            '챗봇 사용량 추적용',             '시스템',   0,          DATE '2026-01-01', DATE '2099-12-31', '내부 시스템', 0,        'active')
ON CONFLICT (contract_no) DO UPDATE
SET
    construction_company = EXCLUDED.construction_company,
    project_name = EXCLUDED.project_name,
    site_location = EXCLUDED.site_location,
    representative_name = EXCLUDED.representative_name,
    contract_amount = EXCLUDED.contract_amount,
    construction_start_date = EXCLUDED.construction_start_date,
    construction_end_date = EXCLUDED.construction_end_date,
    client_name = EXCLUDED.client_name,
    appropriated_amount = EXCLUDED.appropriated_amount,
    project_status_code = EXCLUDED.project_status_code,
    updated_at = now();

-- ─────────────────────────────────────────────────────────────
-- 3. 프로젝트 담당자 배정
--    숫자 ID는 시퀀스 상태에 따라 달라지므로 계약번호·사번 기준으로 관계 생성
-- ─────────────────────────────────────────────────────────────
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
