-- =============================================================
-- V10__additional_mockup_workflows.sql
-- 업무 플로우 확인용 추가 목업 데이터
-- 시나리오 2개:
--   1. 용인 터널공사: 검토 완료 + 보고서 생성 완료
--   2. 인천 항만정비: 보완 요청 + 사용자 수정 대기
-- =============================================================
SET LOCAL search_path TO service, public;

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
    );

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
    ('CAT_05', 1200000::NUMERIC, 720000::NUMERIC, 1920000::NUMERIC),
    ('CAT_09',       0::NUMERIC, 950000::NUMERIC,  950000::NUMERIC)
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
    ('CAT_03',  680000::NUMERIC,  760000::NUMERIC, 1440000::NUMERIC),
    ('CAT_05',  400000::NUMERIC,       0::NUMERIC,  400000::NUMERIC),
    ('CAT_09',       0::NUMERIC,  520000::NUMERIC,  520000::NUMERIC)
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
    ('2026-0201', 'USER-001', 'classi', 620::BIGINT, 210::BIGINT, 0.00342000::NUMERIC, '2026-05-23 09:05:05+09'),
    ('2026-0201', 'USER-001', 'vision', 940::BIGINT, 470::BIGINT, 0.00686000::NUMERIC, '2026-05-23 09:25:10+09'),
    ('2026-0201', 'USER-001', 'safety-doc', 820::BIGINT, 360::BIGINT, 0.00539000::NUMERIC, '2026-05-23 09:32:10+09'),
    ('2026-0201', 'USER-001', 'legal', 1780::BIGINT, 680::BIGINT, 0.01172000::NUMERIC, '2026-05-23 10:10:15+09'),
    ('2026-0201', 'USER-001', 'report', 1320::BIGINT, 660::BIGINT, 0.00946000::NUMERIC, '2026-05-23 10:30:15+09'),
    ('2026-0202', 'USER-003', 'vision', 910::BIGINT, 410::BIGINT, 0.00624000::NUMERIC, '2026-05-24 10:20:10+09'),
    ('2026-0202', 'USER-003', 'safety-doc', 1080::BIGINT, 430::BIGINT, 0.00713000::NUMERIC, '2026-05-24 10:27:10+09'),
    ('2026-0202', 'USER-003', 'classi', 560::BIGINT, 200::BIGINT, 0.00312000::NUMERIC, '2026-05-24 10:35:10+09'),
    ('2026-0202', 'USER-003', 'legal', 1590::BIGINT, 620::BIGINT, 0.01058000::NUMERIC, '2026-05-24 11:00:10+09')
) AS usage(contract_no, employee_no, agent_type_code, input_tokens, output_tokens, cost_usd, created_at)
  ON p.contract_no = usage.contract_no
WHERE us.report_month = '2026-05-01';
