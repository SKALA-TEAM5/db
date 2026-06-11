-- =============================================================
-- V6__mockup.sql
-- 개발 로그인 계정 + 전체 시나리오 목업 데이터 시드
-- 프로젝트 5개:
--   동탄(조치요청) / 평택(보고서작성중) / 광명(업로드대기)
--   용인(검토완료+보고서생성) / 인천(보완요청)
-- =============================================================
SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- 1. 사용자
--    SYS-001 기본 비밀번호: P@ssw0rd123!
--    ADMIN-* 기본 비밀번호: Admin1234!
--    USER-* 기본 비밀번호: User1234!
-- ─────────────────────────────────────────────────────────────
INSERT INTO users (employee_no, real_name, password_hash, role_code) VALUES
    -- 시스템 관리자
    ('SYS-001', '시스템관리자', '$2y$12$joImXqDiNtrBwXV6wbDo8uoEsKzYfQjD4n6flnTzs8vR6vg9cfV6m', 'system_admin'),
    -- 개발 로그인 계정
    ('ADMIN-001', '김서연', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('ADMIN-002', '박민준', '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu', 'admin'),
    ('USER-001', '이현우', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-002', '최지훈', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-003', '정유진', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    ('USER-004', '한도윤', '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2', 'user'),
    -- SHE 담당자
    ('SHE-001', '홍길동',  '$2b$12$placeholder_hash_hong',   'admin'),
    ('SHE-002', '최안전',  '$2b$12$placeholder_hash_choi',   'admin'),
    ('SHE-003', '이검토',  '$2b$12$placeholder_hash_lee_r',  'admin'),
    -- 프로젝트 담당자 (동탄)
    ('USR-101', '김현장',  '$2b$12$placeholder_hash_kim',    'user'),
    -- 프로젝트 담당자 (평택)
    ('USR-201', '박공무',  '$2b$12$placeholder_hash_park',   'user'),
    ('USR-202', '오정산',  '$2b$12$placeholder_hash_oh',     'user'),
    -- 프로젝트 담당자 (광명)
    ('USR-301', '이프로',  '$2b$12$placeholder_hash_lee_p',  'user'),
    ('USR-302', '정현장',  '$2b$12$placeholder_hash_jung',   'user')
ON CONFLICT (employee_no) DO UPDATE
SET
    real_name = EXCLUDED.real_name,
    password_hash = EXCLUDED.password_hash,
    role_code = EXCLUDED.role_code;