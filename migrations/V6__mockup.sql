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

-- ─────────────────────────────────────────────────────────────
-- 2. 프로젝트
-- ─────────────────────────────────────────────────────────────
INSERT INTO projects (
    contract_no, construction_company, project_name,
    site_location, representative_name, contract_amount,
    construction_start_date, construction_end_date,
    client_name, appropriated_amount, project_status_code
) VALUES
    -- 동탄 물류센터 (조치 요청)
    (
        '2024-0042', '스칼라건설', '동탄 물류센터 증축공사',
        '경기도 화성시 동탄물류단지', '정대표', 12000000000,
        '2024-10-23', '2025-06-21',
        '동탄물류센터', 12000000000, 'active'
    ),
    -- 평택 제조시설 (보고서 작성 중)
    (
        '2024-0108', '평택산업개발', '평택 제조시설 증설',
        '경기도 평택시 고덕산업단지', '강대표', 8500000000,
        '2023-06-01', '2024-12-31',
        '평택제조시설', 8500000000, 'active'
    ),
    -- 광명 데이터센터 (업로드 대기)
    (
        '2025-0016', '광명디씨건설', '광명 데이터센터 신축',
        '경기도 광명시 첨단산업지구', '문대표', 15700000000,
        '2025-02-01', '2026-08-31',
        '광명데이터센터', 15700000000, 'active'
    )
ON CONFLICT DO NOTHING;

INSERT INTO project_user_assignments (project_id, user_id, assigned_by_user_id)
VALUES
    ((SELECT id FROM projects WHERE contract_no = '2024-0042'), (SELECT id FROM users WHERE employee_no = 'USR-101'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001')),
    ((SELECT id FROM projects WHERE contract_no = '2024-0108'), (SELECT id FROM users WHERE employee_no = 'USR-201'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001')),
    ((SELECT id FROM projects WHERE contract_no = '2025-0016'), (SELECT id FROM users WHERE employee_no = 'USR-301'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001'))
ON CONFLICT (project_id, user_id) DO NOTHING;

-- 편의 변수: 프로젝트 ID 를 서브쿼리로 참조
-- ─────────────────────────────────────────────────────────────
-- 3. 파일 (동탄)
-- ─────────────────────────────────────────────────────────────

-- 동탄 사용내역서 파일 (xlsx)
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'usage_statement',
        '동탄_산안비_사용내역서_2026-04.xlsx',
        'projects/dt-logistics/statements/동탄_산안비_사용내역서_2026-04.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        204800,
        '2026-04-23 09:10:00+09'
    );

-- 동탄 증빙 파일들 (사용내역서 type)
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'usage_statement',
        '사용내역서_안전관리자_1분기.pdf',
        'projects/dt-logistics/evidence/사용내역서_안전관리자_1분기.pdf',
        'application/pdf', 512000, '2026-04-23 09:15:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'usage_statement',
        '사용내역서_보호구_1분기.xlsx',
        'projects/dt-logistics/evidence/사용내역서_보호구_1분기.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        153600, '2026-04-23 09:15:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'usage_statement',
        '사용내역서_안전시설_2분기.pdf',
        'projects/dt-logistics/evidence/사용내역서_안전시설_2분기.pdf',
        'application/pdf', 409600, '2026-04-23 09:16:00+09'
    );

-- 동탄 영수증 파일들
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'transaction_statement',
        '안전관리자_선임수수료_1월.pdf',
        'projects/dt-logistics/evidence/안전관리자_선임수수료_1월.pdf',
        'application/pdf', 307200, '2026-04-23 09:20:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'transaction_statement',
        '안전모_구입_영수증.jpg',
        'projects/dt-logistics/evidence/안전모_구입_영수증.jpg',
        'image/jpeg', 204800, '2026-04-23 09:20:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'transaction_statement',
        '안전화_구입_영수증.jpg',
        'projects/dt-logistics/evidence/안전화_구입_영수증.jpg',
        'image/jpeg', 184320, '2026-04-23 09:21:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'transaction_statement',
        '보호구_세트_영수증.pdf',
        'projects/dt-logistics/evidence/보호구_세트_영수증.pdf',
        'application/pdf', 245760, '2026-04-23 09:21:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'transaction_statement',
        '안전난간_영수증.jpg',
        'projects/dt-logistics/evidence/안전난간_영수증.jpg',
        'image/jpeg', 163840, '2026-04-23 09:22:00+09'
    );

-- 동탄 현장사진
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, captured_at, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'wearing_photo',
        '안전관리자_현장순찰_사진.jpg',
        'projects/dt-logistics/evidence/안전관리자_현장순찰_사진.jpg',
        'image/jpeg', 3145728,
        '2026-04-10 10:30:00+09', '2026-04-23 09:25:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'wearing_photo',
        '안전모_착용_현장.jpg',
        'projects/dt-logistics/evidence/안전모_착용_현장.jpg',
        'image/jpeg', 2621440,
        '2026-04-11 11:00:00+09', '2026-04-23 09:25:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'wearing_photo',
        '안전화_지급_사진.jpg',
        'projects/dt-logistics/evidence/안전화_지급_사진.jpg',
        'image/jpeg', 2097152,
        '2026-04-12 09:00:00+09', '2026-04-23 09:26:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'wearing_photo',
        '보호구_착용확인.jpg',
        'projects/dt-logistics/evidence/보호구_착용확인.jpg',
        'image/jpeg', 2359296,
        '2026-04-13 14:00:00+09', '2026-04-23 09:26:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'site_photo',
        '안전시설_전체사진.jpg',
        'projects/dt-logistics/evidence/안전시설_전체사진.jpg',
        'image/jpeg', 4194304,
        '2026-04-14 15:00:00+09', '2026-04-23 09:27:00+09'
    );

-- 동탄 세금내역서 + 제3자사실관계확인서
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'tax_invoice',
        '세금내역서_안전관리자_1월.pdf',
        'projects/dt-logistics/evidence/세금내역서_안전관리자_1월.pdf',
        'application/pdf', 409600, '2026-04-23 09:30:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'tax_invoice_confirm',
        '제3자사실관계확인서_안전관리자_1월.pdf',
        'projects/dt-logistics/evidence/제3자사실관계확인서_안전관리자_1월.pdf',
        'application/pdf', 307200, '2026-04-23 09:30:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'tax_invoice',
        '세금내역서_보호구_4월.pdf',
        'projects/dt-logistics/evidence/세금내역서_보호구_4월.pdf',
        'application/pdf', 358400, '2026-04-23 09:31:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'tax_invoice_confirm',
        '제3자사실관계확인서_보호구_4월.pdf',
        'projects/dt-logistics/evidence/제3자사실관계확인서_보호구_4월.pdf',
        'application/pdf', 286720, '2026-04-23 09:31:30+09'
    );

-- 동탄 기타 서류
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'appointment_report',
        '안전관리자_선임계.pdf',
        'projects/dt-logistics/evidence/안전관리자_선임계.pdf',
        'application/pdf', 204800, '2026-04-23 09:35:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'supply_ledger',
        '보호구_지급대장.xlsx',
        'projects/dt-logistics/evidence/보호구_지급대장.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        122880, '2026-04-23 09:35:30+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0042'),
        (SELECT id FROM users WHERE employee_no = 'USR-101'),
        'site_photo',
        '안전시설_설치확인서.pdf',
        'projects/dt-logistics/evidence/안전시설_설치확인서.pdf',
        'application/pdf', 307200, '2026-04-23 09:36:00+09'
    );

-- ─────────────────────────────────────────────────────────────
-- 4. 사용내역서 (동탄 4차 2026-04)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statements (
    project_id, source_file_id, report_month, revision_no,
    document_written_date, cumulative_progress_rate, status_code
) VALUES (
    (SELECT id FROM projects WHERE contract_no = '2024-0042'),
    (SELECT id FROM files WHERE storage_key = 'projects/dt-logistics/statements/동탄_산안비_사용내역서_2026-04.xlsx'),
    '2026-04-01',
    4,
    '2026-04-22',
    78.00,
    'supplement_required'
);

-- ─────────────────────────────────────────────────────────────
-- 5. 사용내역서 요약 (동탄)
--    금회 합계 = 7,840,000 / 누계 = 48,614,045
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_summaries (
    usage_statement_id, category_code, previous_amount, current_amount, cumulative_amount
)
SELECT
    us.id,
    v.category_code,
    v.previous_amount,
    v.current_amount,
    v.cumulative_amount
FROM usage_statements us
CROSS JOIN (VALUES
    -- CAT_01 안전·보건관리자 임금 등 (정상)
    ('CAT_01', 15000000::NUMERIC, 2500000::NUMERIC, 17500000::NUMERIC),
    -- CAT_02 안전시설비 등 (조건부 인정, 850,000 문제) — 항목 합계: 850,000 + 1,080,000 = 1,930,000
    ('CAT_02',  8200000::NUMERIC, 1930000::NUMERIC, 10130000::NUMERIC),
    -- CAT_03 보호구 등 (부적정, 금액 불일치 220,000)
    ('CAT_03',  9500000::NUMERIC, 1200000::NUMERIC, 10700000::NUMERIC),
    -- CAT_04 안전보건진단비 등
    ('CAT_04',  1500000::NUMERIC,       0::NUMERIC,  1500000::NUMERIC),
    -- CAT_05 안전보건교육비 등 (해당 없음)
    ('CAT_05',        0::NUMERIC,        0::NUMERIC,        0::NUMERIC),
    -- CAT_06 근로자 건강장해예방비 등
    ('CAT_06',  2000000::NUMERIC,  500000::NUMERIC,  2500000::NUMERIC),
    -- CAT_07 건설재해예방전문지도기관 기술지도비
    ('CAT_07',  1200000::NUMERIC,  700000::NUMERIC,  1900000::NUMERIC),
    -- CAT_08 본사 전담조직 근로자 임금 등 (부적정, 한도 초과)
    ('CAT_08',  3474045::NUMERIC, 1000000::NUMERIC,  4474045::NUMERIC),
    -- CAT_09 위험성평가 등에 따른 소요비용 (해당 없음)
    ('CAT_09',        0::NUMERIC,        0::NUMERIC,        0::NUMERIC)
) AS v(category_code, previous_amount, current_amount, cumulative_amount)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 6. 사용내역서 상세 항목 (동탄 핵심 3개 문제 항목)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_items (
    usage_statement_id, category_code, used_on, item_name,
    unit, quantity, unit_price, total_amount, remark, page_no
)
SELECT
    us.id,
    v.category_code,
    v.used_on::DATE,
    v.item_name,
    v.unit,
    v.quantity,
    v.unit_price,
    v.total_amount,
    v.remark,
    v.page_no
FROM usage_statements us
CROSS JOIN (VALUES
    -- CAT_01 안전관리자 임금 (정상)
    ('CAT_01', '2026-04-30', '안전관리자 임금 (4월)',         '월', 1, 2500000.00, 2500000, '정규 선임 안전관리자', 3),
    -- CAT_02 안전시설비 - 안전난간 부품 (조건부 인정)
    ('CAT_02', '2026-04-15', '안전난간 설치 부품 구매',       '식', 1,  850000.00,  850000, '안전난간 부품 일체', 7),
    ('CAT_02', '2026-04-20', '안전표지판 설치',               '개', 6,  180000.00, 1080000, '현장 진입로 표지판', 8),
    -- CAT_03 보호구 (부적정: 내역서 1,200,000 vs 영수증 합계 980,000)
    ('CAT_03', '2026-04-05', '안전모 구입',                   '개', 20,  30000.00,  600000, '신규 입사자용 안전모', 11),
    ('CAT_03', '2026-04-08', '안전화 구입',                   '켤레', 10, 45000.00, 450000, '안전화 10켤레', 12),
    ('CAT_03', '2026-04-10', '안전벨트 구입',                 '개',  5,  30000.00,  150000, '고소작업용 안전벨트', 13),
    -- CAT_08 본사 전담조직 임금 (한도 초과)
    ('CAT_08', '2026-04-30', '본사 전담조직 안전담당자 임금', '월', 1, 1000000.00, 1000000, '한도 초과 의심', 18)
) AS v(category_code, used_on, item_name, unit, quantity, unit_price, total_amount, remark, page_no)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 7. 증빙 파일 링크 (동탄 항목 ↔ 파일)
-- ─────────────────────────────────────────────────────────────

-- CAT_01 안전관리자 임금 ↔ 관련 파일
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT
    item.id,
    f.id,
    f.uploaded_evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
JOIN files f ON f.project_id = us.project_id
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.item_name = '안전관리자 임금 (4월)'
  AND f.original_filename IN (
      '안전관리자_선임수수료_1월.pdf',
      '세금내역서_안전관리자_1월.pdf',
      '제3자사실관계확인서_안전관리자_1월.pdf',
      '안전관리자_선임계.pdf',
      '안전관리자_현장순찰_사진.jpg'
  );

-- CAT_03 안전모 구입 ↔ 관련 파일
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT
    item.id,
    f.id,
    f.uploaded_evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
JOIN files f ON f.project_id = us.project_id
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.item_name = '안전모 구입'
  AND f.original_filename IN ('안전모_구입_영수증.jpg', '안전모_착용_현장.jpg');

-- CAT_03 안전화 구입 ↔ 관련 파일
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT
    item.id,
    f.id,
    f.uploaded_evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
JOIN files f ON f.project_id = us.project_id
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.item_name = '안전화 구입'
  AND f.original_filename IN ('안전화_구입_영수증.jpg', '안전화_지급_사진.jpg');

-- CAT_03 안전벨트 구입 ↔ 관련 파일
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT
    item.id,
    f.id,
    f.uploaded_evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
JOIN files f ON f.project_id = us.project_id
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.item_name = '안전벨트 구입'
  AND f.original_filename IN ('보호구_세트_영수증.pdf', '보호구_착용확인.jpg', '보호구_지급대장.xlsx');

-- ─────────────────────────────────────────────────────────────
-- 8. 증빙 요건 (동탄 문제 항목)
--    CAT_03: wearing_photo 미충족, supply_ledger 미충족
-- ─────────────────────────────────────────────────────────────
INSERT INTO evidence_requirements (usage_statement_item_id, evidence_type_code, is_satisfied)
SELECT item.id, req.evidence_type_code, req.is_satisfied
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
CROSS JOIN (VALUES
    ('tax_invoice',      true),
    ('wearing_photo',    false),  -- 착용 상태 불명확
    ('supply_ledger',    false),  -- 지급대장 누락
    ('transaction_statement', true)
) AS req(evidence_type_code, is_satisfied)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.category_code = 'CAT_03';

INSERT INTO evidence_requirements (usage_statement_item_id, evidence_type_code, is_satisfied)
SELECT item.id, req.evidence_type_code, req.is_satisfied
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
CROSS JOIN (VALUES
    ('transaction_statement', true),
    ('site_photo',       false)  -- 설치 완료 사진 부족
) AS req(evidence_type_code, is_satisfied)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01'
  AND item.item_name = '안전난간 설치 부품 구매';

-- ─────────────────────────────────────────────────────────────
-- 9. 검증 로그 (동탄)
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_logs (
    project_id, usage_statement_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id,
    us.id,
    vd.agent_type_code,
    'success',
    vd.result_code,
    vd.reason,
    vd.details::JSONB,
    'claude-sonnet-4-20250514',
    vd.token_current,
    vd.token_current,
    vd.token_current,
    '2026-04-23 11:00:00+09'
FROM usage_statements us
CROSS JOIN (VALUES
    ('vision',  'hil', '보호구 착용 사진 불명확 및 안전시설 설치 위치 사진 부족',
     '{"result":"issues_found","issues":[{"item":"안전모 구입","issue":"턱끈 미체결, 지급대장 불일치"},{"item":"안전화 구입","issue":"착용 사진 부족"},{"item":"안전벨트 구입","issue":"체결 부위 미확인"},{"item":"안전난간 설치 부품 구매","issue":"설치 위치 사진 부족"}]}',
     1240::BIGINT),
    ('classi',  'hil', '금액 불일치 항목 발견 (CAT_03 내역서 1,200,000 vs 영수증 합계 980,000)',
     '{"result":"issues_found","issues":[{"item":"안전모 구입","issue":"금액 불일치","statement_amount":1200000,"receipt_total":980000,"difference":220000}]}',
     890::BIGINT),
    ('legal',   'hil', '본사 전담조직 계상금액 허용 한도 초과 의심',
     '{"result":"issues_found","issues":[{"item":"본사 전담조직 안전담당자 임금","issue":"한도 초과","limit_rate":0.06,"claimed_amount":4800000}]}',
     1680::BIGINT)
) AS vd(agent_type_code, result_code, reason, details, token_current)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0042')
  AND us.report_month = '2026-04-01';

-- ═════════════════════════════════════════════════════════════
-- 평택 제조시설 (보고서 작성 중 - 정상 시나리오)
-- ═════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 11. 파일 (평택)
-- ─────────────────────────────────────────────────────────────
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    -- 사용내역서 파일 (4월)
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'usage_statement',
        '평택_사용내역서_2026-04.xlsx',
        'projects/pt-manufacturing/statements/평택_사용내역서_2026-04.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        174080, '2026-04-21 09:00:00+09'
    ),
    -- 사용내역서 파일 (3월)
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'usage_statement',
        '평택_사용내역서_2026-03.xlsx',
        'projects/pt-manufacturing/statements/평택_사용내역서_2026-03.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        163840, '2026-03-21 09:00:00+09'
    ),
    -- 증빙 영수증
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'transaction_statement',
        '보건관리_용역비_청구서.pdf',
        'projects/pt-manufacturing/evidence/보건관리_용역비_청구서.pdf',
        'application/pdf', 307200, '2026-04-21 09:10:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'transaction_statement',
        '보건관리자_4월_영수증.jpg',
        'projects/pt-manufacturing/evidence/보건관리자_4월_영수증.jpg',
        'image/jpeg', 204800, '2026-04-21 09:11:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'transfer_confirm',
        '교육비_납입증명서.pdf',
        'projects/pt-manufacturing/evidence/교육비_납입증명서.pdf',
        'application/pdf', 245760, '2026-04-21 09:12:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'transaction_statement',
        '위험성평가_컨설팅비.pdf',
        'projects/pt-manufacturing/evidence/위험성평가_컨설팅비.pdf',
        'application/pdf', 286720, '2026-04-21 09:13:00+09'
    ),
    -- 현장사진
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'work_photo',
        '보건관리자_현장방문.jpg',
        'projects/pt-manufacturing/evidence/보건관리자_현장방문.jpg',
        'image/jpeg', 2621440, '2026-04-21 09:20:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'inspection_log',
        '보건시설_점검_사진.jpg',
        'projects/pt-manufacturing/evidence/보건시설_점검_사진.jpg',
        'image/jpeg', 2097152, '2026-04-21 09:21:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'work_photo',
        '보건관리_활동사진.jpg',
        'projects/pt-manufacturing/evidence/보건관리_활동사진.jpg',
        'image/jpeg', 1835008, '2026-04-21 09:22:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'site_photo',
        '위험성평가_현장사진.jpg',
        'projects/pt-manufacturing/evidence/위험성평가_현장사진.jpg',
        'image/jpeg', 3145728, '2026-04-21 09:23:00+09'
    ),
    -- 세금내역서 + 제3자확인서
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'tax_invoice',
        '세금내역서_위험성평가_6월.pdf',
        'projects/pt-manufacturing/evidence/세금내역서_위험성평가_6월.pdf',
        'application/pdf', 358400, '2026-04-21 09:30:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM users WHERE employee_no = 'USR-201'),
        'tax_invoice_confirm',
        '제3자사실관계확인서_위험성평가_6월.pdf',
        'projects/pt-manufacturing/evidence/제3자사실관계확인서_위험성평가_6월.pdf',
        'application/pdf', 286720, '2026-04-21 09:30:30+09'
    );

-- ─────────────────────────────────────────────────────────────
-- 12. 사용내역서 (평택 4월, 3월)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statements (
    project_id, source_file_id, report_month, revision_no,
    document_written_date, cumulative_progress_rate, status_code
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM files WHERE storage_key = 'projects/pt-manufacturing/statements/평택_사용내역서_2026-04.xlsx'),
        '2026-04-01', 2, '2026-04-20', 91.00, 'upload_completed'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2024-0108'),
        (SELECT id FROM files WHERE storage_key = 'projects/pt-manufacturing/statements/평택_사용내역서_2026-03.xlsx'),
        '2026-03-01', 1, '2026-03-20', 88.00, 'review_completed'
    );

-- ─────────────────────────────────────────────────────────────
-- 13. 사용내역서 요약 (평택 4월)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_summaries (
    usage_statement_id, category_code, previous_amount, current_amount, cumulative_amount
)
SELECT
    us.id,
    v.category_code,
    v.previous_amount,
    v.current_amount,
    v.cumulative_amount
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_01', 12000000::NUMERIC, 1800000::NUMERIC, 13800000::NUMERIC),
    ('CAT_02',  5500000::NUMERIC,  800000::NUMERIC,  6300000::NUMERIC),
    ('CAT_03',  2800000::NUMERIC,  320000::NUMERIC,  3120000::NUMERIC),
    ('CAT_04',  1000000::NUMERIC,  500000::NUMERIC,  1500000::NUMERIC),
    ('CAT_05',        0::NUMERIC,  500000::NUMERIC,   500000::NUMERIC),
    ('CAT_06',  3200000::NUMERIC, 1000000::NUMERIC,  4200000::NUMERIC),
    ('CAT_07',        0::NUMERIC,        0::NUMERIC,        0::NUMERIC),
    ('CAT_08',        0::NUMERIC,        0::NUMERIC,        0::NUMERIC),
    ('CAT_09',  1700000::NUMERIC,        0::NUMERIC,  1700000::NUMERIC)
) AS v(category_code, previous_amount, current_amount, cumulative_amount)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0108')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 14. 상세 항목 (평택 4월)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_items (
    usage_statement_id, category_code, used_on, item_name,
    unit, quantity, unit_price, total_amount, remark, page_no
)
SELECT
    us.id,
    v.category_code,
    v.used_on::DATE,
    v.item_name,
    v.unit,
    v.quantity,
    v.unit_price,
    v.total_amount,
    v.remark,
    v.page_no
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_01', '2026-04-30', '보건관리자 임금 (4월)',     '월',  1, 1800000.00, 1800000, '보건관리 용역',   3),
    ('CAT_06', '2026-04-25', '근로자 건강검진 비용',       '명', 10,  100000.00, 1000000, '정기 건강검진',   7),
    ('CAT_05', '2026-04-18', '안전보건교육비',             '식',  1,   500000.00,  500000, '신규 입사자 교육', 9),
    ('CAT_04', '2026-04-15', '안전진단 용역비',            '식',  1,   500000.00,  500000, '1분기 정기 진단', 11),
    ('CAT_03', '2026-04-10', '보호구 구입',                '식',  1,   320000.00,  320000, '소모성 보호구',   13)
) AS v(category_code, used_on, item_name, unit, quantity, unit_price, total_amount, remark, page_no)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0108')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 15. 증빙 요건 (평택 - 모두 충족)
-- ─────────────────────────────────────────────────────────────
INSERT INTO evidence_requirements (usage_statement_item_id, evidence_type_code, is_satisfied)
SELECT item.id, req.evidence_type_code, true
FROM usage_statement_items item
JOIN usage_statements us ON item.usage_statement_id = us.id
CROSS JOIN (VALUES
    ('tax_invoice'),
    ('transaction_statement'),
    ('work_photo')
) AS req(evidence_type_code)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0108')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 15-b. 증빙 파일 링크 (평택 4월 - 모두 충족 시나리오)
-- ─────────────────────────────────────────────────────────────
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT item.id, f.id, link.evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON us.id = item.usage_statement_id
JOIN files f ON f.project_id = us.project_id
JOIN (VALUES
    ('보건관리자 임금 (4월)', '보건관리_용역비_청구서.pdf',       'transaction_statement'),
    ('보건관리자 임금 (4월)', '세금내역서_위험성평가_6월.pdf',     'tax_invoice'),
    ('보건관리자 임금 (4월)', '보건관리자_현장방문.jpg',           'work_photo'),
    ('근로자 건강검진 비용',  '보건관리자_4월_영수증.jpg',         'transaction_statement'),
    ('근로자 건강검진 비용',  '세금내역서_위험성평가_6월.pdf',     'tax_invoice'),
    ('근로자 건강검진 비용',  '보건시설_점검_사진.jpg',            'work_photo'),
    ('안전보건교육비',        '교육비_납입증명서.pdf',             'transaction_statement'),
    ('안전보건교육비',        '세금내역서_위험성평가_6월.pdf',     'tax_invoice'),
    ('안전보건교육비',        '보건관리_활동사진.jpg',             'work_photo'),
    ('안전진단 용역비',       '위험성평가_컨설팅비.pdf',           'transaction_statement'),
    ('안전진단 용역비',       '세금내역서_위험성평가_6월.pdf',     'tax_invoice'),
    ('안전진단 용역비',       '위험성평가_현장사진.jpg',           'work_photo'),
    ('보호구 구입',           '보건관리_용역비_청구서.pdf',        'transaction_statement'),
    ('보호구 구입',           '세금내역서_위험성평가_6월.pdf',     'tax_invoice'),
    ('보호구 구입',           '보건관리자_현장방문.jpg',           'work_photo')
) AS link(item_name, original_filename, evidence_type_code)
  ON item.item_name = link.item_name
 AND f.original_filename = link.original_filename
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0108')
  AND us.report_month = '2026-04-01';

-- ─────────────────────────────────────────────────────────────
-- 16. 검증 로그 (평택 - 정상)
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_logs (
    project_id, usage_statement_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id,
    us.id,
    vd.agent_type_code,
    'success',
    vd.result_code,
    vd.reason,
    vd.details::JSONB,
    'claude-sonnet-4-20250514',
    vd.token_current,
    vd.token_current,
    vd.token_current,
    '2026-04-21 14:00:00+09'
FROM usage_statements us
CROSS JOIN (VALUES
    ('classi', 'success', '사용내역서 금액과 영수증 합계 일치',
     '{"result":"pass","summary":"사용내역서 금액과 영수증 합계 일치","total_statement":4920000,"total_receipts":4920000}',
     750::BIGINT),
    ('vision', 'success', '현장 사진 목적 적합성 확인',
     '{"result":"pass","summary":"보건관리자 현장 방문 및 활동 사진 목적 적합성 확인"}',
     1020::BIGINT),
    ('legal',  'success', '법령 기준 내 정산 적합',
     '{"result":"pass","summary":"모든 항목 법령 기준 내 정산 적합"}',
     1560::BIGINT)
) AS vd(agent_type_code, result_code, reason, details, token_current)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2024-0108')
  AND us.report_month = '2026-04-01';

-- ═════════════════════════════════════════════════════════════
-- 광명 데이터센터 (업로드 대기 - 초기 시나리오)
-- 이전 차수(3월) 데이터만 존재, 4월은 업로드 미완료
-- ═════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 17. 파일 (광명 3월 - 이미 제출된 이전 차수)
-- ─────────────────────────────────────────────────────────────
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes, uploaded_at
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2025-0016'),
        (SELECT id FROM users WHERE employee_no = 'USR-301'),
        'usage_statement',
        '광명_사용내역서_2026-03.xlsx',
        'projects/gm-datacenter/statements/광명_사용내역서_2026-03.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        143360, '2026-03-19 09:00:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2025-0016'),
        (SELECT id FROM users WHERE employee_no = 'USR-301'),
        'transaction_statement',
        '안전관리비_3월_영수증_일부.pdf',
        'projects/gm-datacenter/evidence/안전관리비_3월_영수증_일부.pdf',
        'application/pdf', 245760, '2026-03-19 09:10:00+09'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2025-0016'),
        (SELECT id FROM users WHERE employee_no = 'USR-301'),
        'site_photo',
        '현장_안전시설_3월.jpg',
        'projects/gm-datacenter/evidence/현장_안전시설_3월.jpg',
        'image/jpeg', 3145728, '2026-03-19 09:15:00+09'
    );

-- ─────────────────────────────────────────────────────────────
-- 18. 사용내역서 (광명 3월만 등록, 4월은 미등록)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statements (
    project_id, source_file_id, report_month, revision_no,
    document_written_date, cumulative_progress_rate
) VALUES (
    (SELECT id FROM projects WHERE contract_no = '2025-0016'),
    (SELECT id FROM files WHERE storage_key = 'projects/gm-datacenter/statements/광명_사용내역서_2026-03.xlsx'),
    '2026-03-01', 1, '2026-03-18', 12.00
);

-- ─────────────────────────────────────────────────────────────
-- 19. 사용내역서 요약 (광명 3월)
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_summaries (
    usage_statement_id, category_code, previous_amount, current_amount, cumulative_amount
)
SELECT
    us.id,
    v.category_code,
    v.previous_amount,
    v.current_amount,
    v.cumulative_amount
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_01', 5200000::NUMERIC, 1500000::NUMERIC, 6700000::NUMERIC),
    ('CAT_02', 1800000::NUMERIC,  620000::NUMERIC, 2420000::NUMERIC),
    ('CAT_03',  300000::NUMERIC,  100000::NUMERIC,  400000::NUMERIC),
    ('CAT_04',       0::NUMERIC,       0::NUMERIC,       0::NUMERIC),
    ('CAT_05',       0::NUMERIC,       0::NUMERIC,       0::NUMERIC),
    ('CAT_06',  200000::NUMERIC,  100000::NUMERIC,  300000::NUMERIC),
    ('CAT_07',       0::NUMERIC,       0::NUMERIC,       0::NUMERIC),
    ('CAT_08',       0::NUMERIC,       0::NUMERIC,       0::NUMERIC),
    ('CAT_09',       0::NUMERIC,       0::NUMERIC,       0::NUMERIC)
) AS v(category_code, previous_amount, current_amount, cumulative_amount)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2025-0016')
  AND us.report_month = '2026-03-01';

-- ─────────────────────────────────────────────────────────────
-- 20. Agent 토큰/비용 사용 이력 (동탄 / 평택 / 광명)
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_usage_records (
    user_id, project_id, usage_statement_id,
    agent_type_code, model_name, input_tokens, output_tokens, cost_usd, created_at
)
SELECT
    (SELECT id FROM users WHERE employee_no = usage.employee_no),
    us.project_id,
    us.id,
    usage.agent_type_code,
    'claude-sonnet-4-20250514',
    usage.input_tokens,
    usage.output_tokens,
    usage.cost_usd,
    usage.created_at::TIMESTAMPTZ
FROM usage_statements us
JOIN projects p ON p.id = us.project_id
JOIN (VALUES
    -- 동탄 (2024-0042)
    ('2024-0042', 'USR-101', 'classi',    720::BIGINT, 280::BIGINT, 0.00452000::NUMERIC, '2026-04-23 11:05:00+09'),
    ('2024-0042', 'USR-101', 'vision',   1080::BIGINT, 430::BIGINT, 0.00713000::NUMERIC, '2026-04-23 11:10:00+09'),
    ('2024-0042', 'SHE-001', 'legal',    1940::BIGINT, 720::BIGINT, 0.01316000::NUMERIC, '2026-04-23 11:15:00+09'),
    -- 평택 (2024-0108)
    ('2024-0108', 'USR-201', 'classi',    680::BIGINT, 260::BIGINT, 0.00424000::NUMERIC, '2026-04-21 14:05:00+09'),
    ('2024-0108', 'USR-201', 'vision',    920::BIGINT, 380::BIGINT, 0.00622000::NUMERIC, '2026-04-21 14:10:00+09'),
    ('2024-0108', 'SHE-001', 'legal',    1820::BIGINT, 690::BIGINT, 0.01244000::NUMERIC, '2026-04-21 14:15:00+09'),
    -- 광명 (2025-0016)
    ('2025-0016', 'USR-301', 'classi',    540::BIGINT, 200::BIGINT, 0.00308000::NUMERIC, '2026-03-20 10:05:00+09')
) AS usage(contract_no, employee_no, agent_type_code, input_tokens, output_tokens, cost_usd, created_at)
  ON p.contract_no = usage.contract_no
WHERE (us.report_month = '2026-04-01' AND p.contract_no IN ('2024-0042', '2024-0108'))
   OR (us.report_month = '2026-03-01' AND p.contract_no = '2025-0016');

-- ─────────────────────────────────────────────────────────────
-- 21. 검증 로그 (광명 3월 - 이슈 1건 검증 중)
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_logs (
    project_id, usage_statement_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id,
    us.id,
    'classi',
    'success',
    'hil',
    '일부 영수증 OCR 인식 오류, 수동 확인 필요',
    '{"result":"conditional","issue":"일부 영수증 금액 OCR 인식 오류 - 수동 확인 필요","affected_items":1}'::JSONB,
    'claude-sonnet-4-20250514',
    540, 540, 540,
    '2026-03-20 10:00:00+09'
FROM usage_statements us
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2025-0016')
  AND us.report_month = '2026-03-01';

-- ─────────────────────────────────────────────────────────────
-- 보정: 동탄·평택·광명 파일 status_code 일괄 처리
-- files INSERT에 status_code/detail 미지정 → DEFAULT 'draft'로 삽입됨
-- 실제 시나리오에서는 업로드 완료 상태여야 하므로 success로 변경
-- ─────────────────────────────────────────────────────────────
UPDATE files
SET status_code = 'success'
WHERE project_id IN (
    SELECT id FROM projects WHERE contract_no IN ('2024-0042', '2024-0108', '2025-0016')
)
  AND status_code = 'draft'
  AND deleted_at IS NULL;

-- ═════════════════════════════════════════════════════════════
-- 추가 시나리오: 용인(검토완료+보고서생성) / 인천(보완요청)
-- ═════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- 1. 프로젝트
-- ─────────────────────────────────────────────────────────────
INSERT INTO projects (
    contract_no, construction_company, project_name,
    site_location, representative_name, contract_amount,
    construction_start_date, construction_end_date,
    client_name, appropriated_amount, project_status_code
) VALUES
    (
        '2026-0201', '용인인프라건설', '용인 반도체 클러스터 진입터널 공사',
        '경기도 용인시 처인구 원삼면', '서대표', 23800000000,
        '2025-09-01', '2027-02-28',
        '용인시', 23800000000, 'active'
    ),
    (
        '2026-0202', '인천항만시설', '인천 항만 배후도로 안전시설 정비',
        '인천광역시 중구 항동', '윤대표', 6400000000,
        '2026-01-10', '2026-11-30',
        '인천항만공사', 6400000000, 'active'
    )
ON CONFLICT DO NOTHING;

INSERT INTO project_user_assignments (project_id, user_id, assigned_by_user_id)
VALUES
    ((SELECT id FROM projects WHERE contract_no = '2026-0201'), (SELECT id FROM users WHERE employee_no = 'USER-001'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001')),
    ((SELECT id FROM projects WHERE contract_no = '2026-0201'), (SELECT id FROM users WHERE employee_no = 'USER-002'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001')),
    ((SELECT id FROM projects WHERE contract_no = '2026-0202'), (SELECT id FROM users WHERE employee_no = 'USER-003'), (SELECT id FROM users WHERE employee_no = 'ADMIN-001'));

-- ─────────────────────────────────────────────────────────────
-- 2. 파일: 용인 터널공사
-- ─────────────────────────────────────────────────────────────
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes,
    captured_at, uploaded_at, status_code, detail
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-001'),
        'usage_statement',
        '용인_터널_산안비_사용내역서_2026-05.xlsx',
        'projects/yi-tunnel/statements/용인_터널_산안비_사용내역서_2026-05.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        225280,
        NULL, '2026-05-23 08:40:00+09', 'success',
        '{"sheet_count":3,"parsed_rows":4,"ai_status":"parsed"}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-001'),
        'tax_invoice',
        '용인_안전관리자_5월_세금계산서.pdf',
        'projects/yi-tunnel/evidence/용인_안전관리자_5월_세금계산서.pdf',
        'application/pdf',
        344064,
        NULL, '2026-05-23 08:45:00+09', 'success',
        '{"issuer":"한빛안전관리","amount":3200000,"ocr_confidence":0.98}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-001'),
        'work_log',
        '용인_안전관리자_5월_업무일지.pdf',
        'projects/yi-tunnel/evidence/용인_안전관리자_5월_업무일지.pdf',
        'application/pdf',
        430080,
        NULL, '2026-05-23 08:46:00+09', 'success',
        '{"work_days":22,"matched_employee":"김안전"}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-001'),
        'site_photo',
        '용인_터널_환기덕트_설치완료.jpg',
        'projects/yi-tunnel/evidence/용인_터널_환기덕트_설치완료.jpg',
        'image/jpeg',
        3670016,
        '2026-05-18 14:10:00+09', '2026-05-23 08:48:00+09', 'success',
        '{"camera":"Galaxy S25","gps_area":"원삼터널 A구간","vision_tags":["ventilation","installed","safety_facility"]}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-002'),
        'edu_attendance',
        '용인_신규근로자_교육참석부_5월.pdf',
        'projects/yi-tunnel/evidence/용인_신규근로자_교육참석부_5월.pdf',
        'application/pdf',
        286720,
        NULL, '2026-05-23 08:50:00+09', 'success',
        '{"attendee_count":18,"signature_pages":2}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM users WHERE employee_no = 'USER-002'),
        'transaction_statement',
        '용인_터널_위험성평가_컨설팅_거래명세표.pdf',
        'projects/yi-tunnel/evidence/용인_터널_위험성평가_컨설팅_거래명세표.pdf',
        'application/pdf',
        270336,
        NULL, '2026-05-23 08:52:00+09', 'success',
        '{"vendor":"세이프리스크","amount":950000,"ocr_confidence":0.96}'::JSONB
    );

-- ─────────────────────────────────────────────────────────────
-- 3. 파일: 인천 항만정비
-- ─────────────────────────────────────────────────────────────
INSERT INTO files (
    project_id, uploaded_by_user_id, uploaded_evidence_type_code,
    original_filename, storage_key, mime_type, size_bytes,
    captured_at, uploaded_at, status_code, detail
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0202'),
        (SELECT id FROM users WHERE employee_no = 'USER-003'),
        'usage_statement',
        '인천_항만_산안비_사용내역서_2026-05.xlsx',
        'projects/ic-port/statements/인천_항만_산안비_사용내역서_2026-05.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        196608,
        NULL, '2026-05-24 09:05:00+09', 'success',
        '{"sheet_count":2,"parsed_rows":3,"ai_status":"parsed_with_warnings"}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0202'),
        (SELECT id FROM users WHERE employee_no = 'USER-003'),
        'transaction_statement',
        '인천_야간안전조명_거래명세표.pdf',
        'projects/ic-port/evidence/인천_야간안전조명_거래명세표.pdf',
        'application/pdf',
        319488,
        NULL, '2026-05-24 09:12:00+09', 'success',
        '{"vendor":"항만전기안전","amount":1450000,"ocr_confidence":0.94}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0202'),
        (SELECT id FROM users WHERE employee_no = 'USER-003'),
        'site_photo',
        '인천_야간안전조명_부분사진.jpg',
        'projects/ic-port/evidence/인천_야간안전조명_부분사진.jpg',
        'image/jpeg',
        2146304,
        '2026-05-20 20:35:00+09', '2026-05-24 09:14:00+09', 'success',
        '{"camera":"iPhone 17","gps_area":"항만배후도로 2구간","vision_tags":["lighting","partial_view"]}'::JSONB
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0202'),
        (SELECT id FROM users WHERE employee_no = 'USER-003'),
        'wearing_photo',
        '인천_안전대_착용사진_흐림.jpg',
        'projects/ic-port/evidence/인천_안전대_착용사진_흐림.jpg',
        'image/jpeg',
        1887436,
        '2026-05-21 10:20:00+09', '2026-05-24 09:16:00+09', 'success',
        '{"camera":"Galaxy S24","quality":"blurred","vision_tags":["ppe","harness","unclear_fastening"]}'::JSONB
    );

-- ─────────────────────────────────────────────────────────────
-- 4. 사용내역서
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statements (
    project_id, source_file_id, report_month, revision_no,
    document_written_date, cumulative_progress_rate, status_code
) VALUES
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0201'),
        (SELECT id FROM files WHERE storage_key = 'projects/yi-tunnel/statements/용인_터널_산안비_사용내역서_2026-05.xlsx'),
        '2026-05-01', 1, '2026-05-22', 41.50, 'review_completed'
    ),
    (
        (SELECT id FROM projects WHERE contract_no = '2026-0202'),
        (SELECT id FROM files WHERE storage_key = 'projects/ic-port/statements/인천_항만_산안비_사용내역서_2026-05.xlsx'),
        '2026-05-01', 1, '2026-05-23', 33.20, 'supplement_required'
    );

-- ─────────────────────────────────────────────────────────────
-- 5. 사용내역서 요약
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_summaries (
    usage_statement_id, category_code, previous_amount, current_amount, cumulative_amount
)
SELECT us.id, v.category_code, v.previous_amount, v.current_amount, v.cumulative_amount
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_01', 8400000::NUMERIC, 3200000::NUMERIC, 11600000::NUMERIC),
    ('CAT_02', 2600000::NUMERIC, 1850000::NUMERIC, 4450000::NUMERIC),
    ('CAT_05', 1200000::NUMERIC,  720000::NUMERIC,  1920000::NUMERIC),
    ('CAT_09',       0::NUMERIC,  950000::NUMERIC,   950000::NUMERIC)
) AS v(category_code, previous_amount, current_amount, cumulative_amount)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO usage_statement_summaries (
    usage_statement_id, category_code, previous_amount, current_amount, cumulative_amount
)
SELECT us.id, v.category_code, v.previous_amount, v.current_amount, v.cumulative_amount
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_02', 1250000::NUMERIC, 1450000::NUMERIC, 2700000::NUMERIC),
    ('CAT_03',  680000::NUMERIC,  760000::NUMERIC,  1440000::NUMERIC),
    ('CAT_05',  400000::NUMERIC,       0::NUMERIC,   400000::NUMERIC),
    ('CAT_09',       0::NUMERIC,  520000::NUMERIC,   520000::NUMERIC)
) AS v(category_code, previous_amount, current_amount, cumulative_amount)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

-- ─────────────────────────────────────────────────────────────
-- 6. 상세 항목
-- ─────────────────────────────────────────────────────────────
INSERT INTO usage_statement_items (
    usage_statement_id, category_code, used_on, item_name,
    unit, quantity, unit_price, total_amount, remark, page_no
)
SELECT us.id, v.category_code, v.used_on::DATE, v.item_name, v.unit,
       v.quantity, v.unit_price, v.total_amount, v.remark, v.page_no
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_01', '2026-05-31', '터널 안전관리자 임금 (5월)', '월', 1, 3200000.00, 3200000, '상주 안전관리자', 3),
    ('CAT_02', '2026-05-18', '터널 환기덕트 안전시설 설치', '식', 1, 1850000.00, 1850000, '분진 저감 및 환기 안전시설', 7),
    ('CAT_05', '2026-05-15', '신규 근로자 안전보건교육', '명', 18, 40000.00, 720000, '작업 전 특별교육', 10),
    ('CAT_09', '2026-05-20', '터널 굴착 위험성평가 컨설팅', '식', 1, 950000.00, 950000, '굴착구간 위험성평가', 14)
) AS v(category_code, used_on, item_name, unit, quantity, unit_price, total_amount, remark, page_no)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO usage_statement_items (
    usage_statement_id, category_code, used_on, item_name,
    unit, quantity, unit_price, total_amount, remark, page_no
)
SELECT us.id, v.category_code, v.used_on::DATE, v.item_name, v.unit,
       v.quantity, v.unit_price, v.total_amount, v.remark, v.page_no
FROM usage_statements us
CROSS JOIN (VALUES
    ('CAT_02', '2026-05-20', '야간 안전조명 설치', '식', 1, 1450000.00, 1450000, '항만 배후도로 야간 작업구간', 5),
    ('CAT_03', '2026-05-21', '고소작업 안전대 구입', '개', 8, 95000.00, 760000, '안전대 착용 증빙 보완 필요', 8),
    ('CAT_09', '2026-05-22', '항만 차량동선 위험성평가', '식', 1, 520000.00, 520000, '차량-보행자 동선 분리 검토', 12)
) AS v(category_code, used_on, item_name, unit, quantity, unit_price, total_amount, remark, page_no)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

-- ─────────────────────────────────────────────────────────────
-- 7. 증빙 연결
-- ─────────────────────────────────────────────────────────────
INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code, checked_at)
SELECT item.id, f.id, link.evidence_type_code, link.checked_at::TIMESTAMPTZ
FROM usage_statement_items item
JOIN usage_statements us ON us.id = item.usage_statement_id
JOIN files f ON f.project_id = us.project_id
JOIN (VALUES
    ('터널 안전관리자 임금 (5월)', '용인_안전관리자_5월_세금계산서.pdf', 'tax_invoice', '2026-05-23 13:10:00+09'),
    ('터널 안전관리자 임금 (5월)', '용인_안전관리자_5월_업무일지.pdf', 'work_log', '2026-05-23 13:10:00+09'),
    ('터널 환기덕트 안전시설 설치', '용인_터널_환기덕트_설치완료.jpg', 'site_photo', '2026-05-23 13:12:00+09'),
    ('신규 근로자 안전보건교육', '용인_신규근로자_교육참석부_5월.pdf', 'edu_attendance', '2026-05-23 13:15:00+09'),
    ('터널 굴착 위험성평가 컨설팅', '용인_터널_위험성평가_컨설팅_거래명세표.pdf', 'transaction_statement', '2026-05-23 13:18:00+09')
) AS link(item_name, original_filename, evidence_type_code, checked_at)
  ON item.item_name = link.item_name
 AND f.original_filename = link.original_filename
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO evidence_file_links (usage_statement_item_id, file_id, evidence_type_code)
SELECT item.id, f.id, link.evidence_type_code
FROM usage_statement_items item
JOIN usage_statements us ON us.id = item.usage_statement_id
JOIN files f ON f.project_id = us.project_id
JOIN (VALUES
    ('야간 안전조명 설치', '인천_야간안전조명_거래명세표.pdf', 'transaction_statement'),
    ('야간 안전조명 설치', '인천_야간안전조명_부분사진.jpg', 'site_photo'),
    ('고소작업 안전대 구입', '인천_안전대_착용사진_흐림.jpg', 'wearing_photo')
) AS link(item_name, original_filename, evidence_type_code)
  ON item.item_name = link.item_name
 AND f.original_filename = link.original_filename
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

-- ─────────────────────────────────────────────────────────────
-- 8. 증빙 요건
-- ─────────────────────────────────────────────────────────────
INSERT INTO evidence_requirements (usage_statement_item_id, evidence_type_code, is_satisfied)
SELECT item.id, req.evidence_type_code, req.is_satisfied
FROM usage_statement_items item
JOIN usage_statements us ON us.id = item.usage_statement_id
JOIN (VALUES
    ('터널 안전관리자 임금 (5월)', 'tax_invoice', true),
    ('터널 안전관리자 임금 (5월)', 'work_log', true),
    ('터널 환기덕트 안전시설 설치', 'site_photo', true),
    ('신규 근로자 안전보건교육', 'edu_attendance', true),
    ('터널 굴착 위험성평가 컨설팅', 'transaction_statement', true)
) AS req(item_name, evidence_type_code, is_satisfied)
  ON item.item_name = req.item_name
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO evidence_requirements (usage_statement_item_id, evidence_type_code, is_satisfied)
SELECT item.id, req.evidence_type_code, req.is_satisfied
FROM usage_statement_items item
JOIN usage_statements us ON us.id = item.usage_statement_id
JOIN (VALUES
    ('야간 안전조명 설치', 'transaction_statement', true),
    ('야간 안전조명 설치', 'site_photo', false),
    ('고소작업 안전대 구입', 'tax_invoice', false),
    ('고소작업 안전대 구입', 'wearing_photo', false),
    ('항만 차량동선 위험성평가', 'transaction_statement', false)
) AS req(item_name, evidence_type_code, is_satisfied)
  ON item.item_name = req.item_name
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

-- ─────────────────────────────────────────────────────────────
-- 9. Agent 로그
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_logs (
    project_id, usage_statement_id, usage_statement_item_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id, us.id, item.id,
    log.agent_type_code, 'success', log.result_code, log.reason,
    log.details::JSONB, 'claude-sonnet-4-20250514',
    log.token_current, log.token_current, log.token_cumulative,
    log.created_at::TIMESTAMPTZ
FROM usage_statements us
JOIN usage_statement_items item ON item.usage_statement_id = us.id
JOIN (VALUES
    ('터널 안전관리자 임금 (5월)', 'classi', 'success', 'CAT_01로 정상 분류', '{"payload":{"category_code":"CAT_01","confidence":0.97}}', 830, 830, '2026-05-23 09:05:00+09'),
    ('터널 환기덕트 안전시설 설치', 'vision', 'success', '설치 완료 사진 확인', '{"payload":{"files":[{"filename":"용인_터널_환기덕트_설치완료.jpg","matched":true}],"todos":[]}}', 1410, 1410, '2026-05-23 09:25:00+09'),
    ('신규 근로자 안전보건교육', 'safety-doc', 'success', '필수 교육 증빙 충족', '{"payload":{"todos":[],"requirements":[{"evidence_type_code":"edu_attendance","satisfied":true}]}}', 1180, 1180, '2026-05-23 09:32:00+09')
) AS log(item_name, agent_type_code, result_code, reason, details, token_current, token_cumulative, created_at)
  ON item.item_name = log.item_name
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO agent_logs (
    project_id, usage_statement_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id, us.id,
    log.agent_type_code, 'success', log.result_code, log.reason,
    log.details::JSONB, 'claude-sonnet-4-20250514',
    log.token_current, log.token_current, log.token_cumulative,
    log.created_at::TIMESTAMPTZ
FROM usage_statements us
CROSS JOIN (VALUES
    ('legal', 'success', '법령 기준 내 정산 적합', '{"payload":{"todos":[],"summary":"한도 및 사용 가능 항목 검토 완료"}}', 2460, 2460, '2026-05-23 10:10:00+09'),
    ('report', 'success', '최종 검토 보고서 생성 완료', '{"payload":{"report_title":"용인 반도체 클러스터 진입터널 공사 2026년 5월 검토보고서","generated_file_key":"projects/yi-tunnel/reports/2026-05-review-report.pdf"}}', 1980, 1980, '2026-05-23 10:30:00+09')
) AS log(agent_type_code, result_code, reason, details, token_current, token_cumulative, created_at)
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0201')
  AND us.report_month = '2026-05-01';

INSERT INTO agent_logs (
    project_id, usage_statement_id, usage_statement_item_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id, us.id, item.id,
    log.agent_type_code, 'success', log.result_code, log.reason,
    log.details::JSONB, 'claude-sonnet-4-20250514',
    log.token_current, log.token_current, log.token_cumulative,
    log.created_at::TIMESTAMPTZ
FROM usage_statements us
JOIN usage_statement_items item ON item.usage_statement_id = us.id
JOIN (VALUES
    ('야간 안전조명 설치', 'vision', 'hil', '설치 완료 범위가 사진에서 일부만 확인됩니다.', '{"payload":{"todos":[{"usage_statement_item_id":null,"reason":"전체 설치 구간 사진 추가 필요"}],"files":[{"filename":"인천_야간안전조명_부분사진.jpg","matched":false,"issue_type":"partial_view"}]}}', 1320, 1320, '2026-05-24 10:20:00+09'),
    ('고소작업 안전대 구입', 'safety-doc', 'hil', '세금계산서와 명확한 착용 사진이 부족합니다.', '{"payload":{"todos":[{"usage_statement_item_id":null,"reason":"세금계산서 및 체결부 확인 사진 제출 필요"}],"requirements":[{"evidence_type_code":"tax_invoice","satisfied":false},{"evidence_type_code":"wearing_photo","satisfied":false}]}}', 1510, 1510, '2026-05-24 10:27:00+09'),
    ('항만 차량동선 위험성평가', 'classi', 'success', 'CAT_09로 정상 분류', '{"payload":{"category_code":"CAT_09","confidence":0.93}}', 760, 760, '2026-05-24 10:35:00+09')
) AS log(item_name, agent_type_code, result_code, reason, details, token_current, token_cumulative, created_at)
  ON item.item_name = log.item_name
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

INSERT INTO agent_logs (
    project_id, usage_statement_id,
    agent_type_code, status_code, result_code, reason, details,
    model_name, token, token_current, token_cumulative, created_at
)
SELECT
    us.project_id, us.id,
    'legal', 'success', 'hil',
    '위험성평가 용역비 증빙이 부족해 보완 검토가 필요합니다.',
    '{"payload":{"todos":[{"usage_statement_item_id":null,"reason":"위험성평가 계약서 또는 거래명세표 제출 필요"}],"summary":"일부 항목 보완 필요"}}'::JSONB,
    'claude-sonnet-4-20250514',
    2210, 2210, 2210,
    '2026-05-24 11:00:00+09'
FROM usage_statements us
WHERE us.project_id = (SELECT id FROM projects WHERE contract_no = '2026-0202')
  AND us.report_month = '2026-05-01';

-- ─────────────────────────────────────────────────────────────
-- 10. Agent 토큰/비용 사용 이력
-- ─────────────────────────────────────────────────────────────
INSERT INTO agent_usage_records (
    user_id, project_id, usage_statement_id,
    agent_type_code, model_name, input_tokens, output_tokens, cost_usd, created_at
)
SELECT
    (SELECT id FROM users WHERE employee_no = usage.employee_no),
    us.project_id,
    us.id,
    usage.agent_type_code,
    'claude-sonnet-4-20250514',
    usage.input_tokens,
    usage.output_tokens,
    usage.cost_usd,
    usage.created_at::TIMESTAMPTZ
FROM usage_statements us
JOIN projects p ON p.id = us.project_id
JOIN (VALUES
    ('2026-0201', 'USER-001', 'classi',    620::BIGINT, 210::BIGINT, 0.00342000::NUMERIC, '2026-05-23 09:05:05+09'),
    ('2026-0201', 'USER-001', 'vision',    940::BIGINT, 470::BIGINT, 0.00686000::NUMERIC, '2026-05-23 09:25:10+09'),
    ('2026-0201', 'USER-001', 'safety-doc',820::BIGINT, 360::BIGINT, 0.00539000::NUMERIC, '2026-05-23 09:32:10+09'),
    ('2026-0201', 'USER-001', 'legal',    1780::BIGINT, 680::BIGINT, 0.01172000::NUMERIC, '2026-05-23 10:10:15+09'),
    ('2026-0201', 'USER-001', 'report',   1320::BIGINT, 660::BIGINT, 0.00946000::NUMERIC, '2026-05-23 10:30:15+09'),
    ('2026-0202', 'USER-003', 'vision',    910::BIGINT, 410::BIGINT, 0.00624000::NUMERIC, '2026-05-24 10:20:10+09'),
    ('2026-0202', 'USER-003', 'safety-doc',1080::BIGINT,430::BIGINT, 0.00713000::NUMERIC, '2026-05-24 10:27:10+09'),
    ('2026-0202', 'USER-003', 'classi',    560::BIGINT, 200::BIGINT, 0.00312000::NUMERIC, '2026-05-24 10:35:10+09'),
    ('2026-0202', 'USER-003', 'legal',    1590::BIGINT, 620::BIGINT, 0.01058000::NUMERIC, '2026-05-24 11:00:10+09')
) AS usage(contract_no, employee_no, agent_type_code, input_tokens, output_tokens, cost_usd, created_at)
  ON p.contract_no = usage.contract_no
WHERE us.report_month = '2026-05-01';
