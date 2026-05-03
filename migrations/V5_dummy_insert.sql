SET LOCAL search_path TO service, public;

-- -----------------------------------------------------------------------------
-- Service schema dummy data (integration-level seed)
-- -----------------------------------------------------------------------------

-- 1) users
INSERT INTO users (id, employee_no, real_name, password_hash, role_code)
VALUES
    (1001, 'EMP-001', '김현우', '$2b$10$dummyhashforadmin', 'admin'),
    (1002, 'EMP-002', '박지민', '$2b$10$dummyhashformanager', 'manager'),
    (1003, 'EMP-003', '이서준', '$2b$10$dummyhashforuser', 'user')
ON CONFLICT (employee_no) DO UPDATE
SET
    real_name = EXCLUDED.real_name,
    password_hash = EXCLUDED.password_hash,
    role_code = EXCLUDED.role_code;

-- 2) projects
INSERT INTO projects (
    id,
    user_id,
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
    (
        2001,
        1001,
        '스칼라건설',
        '서울역 복합환승센터 안전보강공사',
        '서울특별시 중구 한강대로 405',
        '김대표',
        1200000000,
        DATE '2026-01-15',
        DATE '2026-12-31',
        '서울교통공사',
        98000000,
        'active'
    ),
    (
        2002,
        1002,
        '한빛토건',
        '부산 북항 재개발 현장 안전시설 개선공사',
        '부산광역시 동구 충장대로 206',
        '박대표',
        860000000,
        DATE '2025-09-01',
        DATE '2026-08-31',
        '부산항만공사',
        64000000,
        'suspended'
    )
ON CONFLICT (id) DO UPDATE
SET
    user_id = EXCLUDED.user_id,
    construction_company = EXCLUDED.construction_company,
    project_name = EXCLUDED.project_name,
    site_location = EXCLUDED.site_location,
    representative_name = EXCLUDED.representative_name,
    contract_amount = EXCLUDED.contract_amount,
    construction_start_date = EXCLUDED.construction_start_date,
    construction_end_date = EXCLUDED.construction_end_date,
    client_name = EXCLUDED.client_name,
    appropriated_amount = EXCLUDED.appropriated_amount,
    project_status_code = EXCLUDED.project_status_code;

-- 3) files
INSERT INTO files (
    id,
    project_id,
    uploaded_by_user_id,
    uploaded_evidence_type_code,
    original_filename,
    storage_key,
    mime_type,
    size_bytes,
    captured_at,
    uploaded_at
)
VALUES
    (
        3001,
        2001,
        1001,
        'usage_statement',
        '2026-03_사용내역서.pdf',
        'projects/2001/usage/2026-03_statement.pdf',
        'application/pdf',
        245678,
        NULL,
        TIMESTAMPTZ '2026-03-31 09:30:00+09'
    ),
    (
        3002,
        2001,
        1002,
        'site_photo',
        '가설난간_설치완료.jpg',
        'projects/2001/photos/rail_install_done.jpg',
        'image/jpeg',
        1024000,
        TIMESTAMPTZ '2026-03-25 14:12:00+09',
        TIMESTAMPTZ '2026-03-25 14:20:00+09'
    ),
    (
        3003,
        2001,
        1002,
        'tax_invoice',
        '세금계산서_안전모_202603.pdf',
        'projects/2001/invoices/tax_invoice_202603.pdf',
        'application/pdf',
        198732,
        NULL,
        TIMESTAMPTZ '2026-03-27 11:02:00+09'
    ),
    (
        3004,
        2002,
        1003,
        'work_photo',
        '안전관리자_순찰.jpg',
        'projects/2002/photos/safety_manager_patrol.jpg',
        'image/jpeg',
        875321,
        TIMESTAMPTZ '2026-02-20 10:35:00+09',
        TIMESTAMPTZ '2026-02-20 10:40:00+09'
    ),
    (
        3005,
        2002,
        1003,
        'inspection_log',
        '주간점검일지_2026W08.pdf',
        'projects/2002/logs/weekly_inspection_2026w08.pdf',
        'application/pdf',
        156420,
        NULL,
        TIMESTAMPTZ '2026-02-22 17:10:00+09'
    )
ON CONFLICT (storage_key) DO UPDATE
SET
    project_id = EXCLUDED.project_id,
    uploaded_by_user_id = EXCLUDED.uploaded_by_user_id,
    uploaded_evidence_type_code = EXCLUDED.uploaded_evidence_type_code,
    original_filename = EXCLUDED.original_filename,
    mime_type = EXCLUDED.mime_type,
    size_bytes = EXCLUDED.size_bytes,
    captured_at = EXCLUDED.captured_at,
    uploaded_at = EXCLUDED.uploaded_at;

-- 4) usage_statements
INSERT INTO usage_statements (
    id,
    project_id,
    source_file_id,
    report_month,
    revision_no,
    document_written_date,
    statement_status_code,
    cumulative_progress_rate
)
VALUES
    (4001, 2001, 3001, DATE '2026-03-01', 1, DATE '2026-03-31', 'reviewing', 37.50),
    (4002, 2002, NULL, DATE '2026-02-01', 1, DATE '2026-02-28', 'draft', 58.20)
ON CONFLICT (project_id, report_month, revision_no) DO UPDATE
SET
    source_file_id = EXCLUDED.source_file_id,
    document_written_date = EXCLUDED.document_written_date,
    statement_status_code = EXCLUDED.statement_status_code,
    cumulative_progress_rate = EXCLUDED.cumulative_progress_rate;

-- 5) usage_statement_summaries
INSERT INTO usage_statement_summaries (
    id,
    usage_statement_id,
    category_code,
    previous_amount,
    current_amount,
    cumulative_amount
)
VALUES
    (5001, 4001, 'CAT_01', 8200000, 2100000, 10300000),
    (5002, 4001, 'CAT_02', 12500000, 3400000, 15900000),
    (5003, 4001, 'CAT_03', 4100000, 1250000, 5350000),
    (5004, 4002, 'CAT_01', 9100000, 1700000, 10800000),
    (5005, 4002, 'CAT_08', 2600000, 900000, 3500000)
ON CONFLICT (usage_statement_id, category_code) DO UPDATE
SET
    previous_amount = EXCLUDED.previous_amount,
    current_amount = EXCLUDED.current_amount,
    cumulative_amount = EXCLUDED.cumulative_amount;

-- 6) usage_statement_items
INSERT INTO usage_statement_items (
    id,
    usage_statement_id,
    category_code,
    used_on,
    item_name,
    unit,
    quantity,
    unit_price,
    total_amount,
    remark,
    page_no
)
VALUES
    (
        6001,
        4001,
        'CAT_02',
        DATE '2026-03-24',
        '가설난간 설치 자재',
        'set',
        5.000,
        480000.00,
        2400000,
        '동측 외벽 구간 우선 설치',
        2
    ),
    (
        6002,
        4001,
        'CAT_03',
        DATE '2026-03-26',
        '안전모 A형',
        'ea',
        50.000,
        25000.00,
        1250000,
        '신규 투입 인원 지급분',
        3
    ),
    (
        6003,
        4002,
        'CAT_01',
        DATE '2026-02-18',
        '안전관리자 급여(2월)',
        'month',
        1.000,
        1700000.00,
        1700000,
        '현장 상주 안전관리자 1인',
        1
    ),
    (
        6004,
        4002,
        'CAT_08',
        DATE '2026-02-21',
        '위험성평가 외부 자문',
        'case',
        1.000,
        900000.00,
        900000,
        '정기 위험성평가 개선안 도출',
        2
    )
ON CONFLICT (id) DO UPDATE
SET
    usage_statement_id = EXCLUDED.usage_statement_id,
    category_code = EXCLUDED.category_code,
    used_on = EXCLUDED.used_on,
    item_name = EXCLUDED.item_name,
    unit = EXCLUDED.unit,
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price,
    total_amount = EXCLUDED.total_amount,
    remark = EXCLUDED.remark,
    page_no = EXCLUDED.page_no;

-- 7) evidence_requirements
INSERT INTO evidence_requirements (
    id,
    usage_statement_item_id,
    evidence_type_code,
    is_satisfied,
    is_active
)
VALUES
    (7001, 6001, 'site_photo', true, true),
    (7002, 6001, 'transaction_statement', false, true),
    (7003, 6002, 'tax_invoice', true, true),
    (7004, 6002, 'item_photo', false, true),
    (7005, 6003, 'pay_stub', false, true),
    (7006, 6004, 'transfer_confirm', false, true)
ON CONFLICT (id) DO UPDATE
SET
    usage_statement_item_id = EXCLUDED.usage_statement_item_id,
    evidence_type_code = EXCLUDED.evidence_type_code,
    is_satisfied = EXCLUDED.is_satisfied,
    is_active = EXCLUDED.is_active;

-- 8) evidence_file_links
INSERT INTO evidence_file_links (
    id,
    usage_statement_item_id,
    file_id,
    category_code,
    evidence_type_code
)
VALUES
    (8001, 6001, 3002, 'CAT_02', 'site_photo'),
    (8002, 6002, 3003, 'CAT_03', 'tax_invoice'),
    (8003, 6003, 3005, 'CAT_01', 'inspection_log')
ON CONFLICT (usage_statement_item_id, file_id) DO UPDATE
SET
    category_code = EXCLUDED.category_code,
    evidence_type_code = EXCLUDED.evidence_type_code;

-- 9) validation_logs
INSERT INTO validation_logs (
    id,
    project_id,
    usage_statement_id,
    usage_statement_item_id,
    validation_type_code,
    result_code,
    details,
    model_name,
    created_at
)
VALUES
    (
        9001,
        2001,
        4001,
        6001,
        'evidence_completeness',
        'pass',
        '{"required":2,"submitted":2,"missing":[]}'::jsonb,
        'gpt-4.1-mini',
        TIMESTAMPTZ '2026-03-31 18:20:00+09'
    ),
    (
        9002,
        2001,
        4001,
        6002,
        'amount_consistency',
        'warn',
        '{"message":"세금계산서 금액과 품목별 합계 검토 필요","delta":0}'::jsonb,
        'gpt-4.1-mini',
        TIMESTAMPTZ '2026-03-31 18:24:00+09'
    ),
    (
        9003,
        2002,
        4002,
        6003,
        'required_document',
        'fail',
        '{"missing":["pay_stub"],"note":"급여명세서 미첨부"}'::jsonb,
        'gpt-4.1-mini',
        TIMESTAMPTZ '2026-02-28 17:12:00+09'
    )
ON CONFLICT (id) DO UPDATE
SET
    project_id = EXCLUDED.project_id,
    usage_statement_id = EXCLUDED.usage_statement_id,
    usage_statement_item_id = EXCLUDED.usage_statement_item_id,
    validation_type_code = EXCLUDED.validation_type_code,
    result_code = EXCLUDED.result_code,
    details = EXCLUDED.details,
    model_name = EXCLUDED.model_name,
    created_at = EXCLUDED.created_at;

-- 10) action_requests
INSERT INTO action_requests (
    id,
    project_id,
    usage_statement_id,
    usage_statement_item_id,
    requested_by_user_id,
    assignee_user_id,
    title,
    reason,
    status_code,
    due_date,
    created_at,
    resolved_at
)
VALUES
    (
        10001,
        2002,
        4002,
        6003,
        1003,
        1002,
        '2월 급여명세서 보완 요청',
        'CAT_01 항목 증빙 필수 문서(pay_stub) 누락',
        'open',
        DATE '2026-03-05',
        TIMESTAMPTZ '2026-02-28 17:15:00+09',
        NULL
    ),
    (
        10002,
        2001,
        4001,
        6002,
        1002,
        1001,
        '안전모 구매 수량 교차검증 완료',
        '거래명세표 및 세금계산서 대조 완료',
        'resolved',
        DATE '2026-04-02',
        TIMESTAMPTZ '2026-04-01 09:10:00+09',
        TIMESTAMPTZ '2026-04-01 14:35:00+09'
    )
ON CONFLICT (id) DO UPDATE
SET
    project_id = EXCLUDED.project_id,
    usage_statement_id = EXCLUDED.usage_statement_id,
    usage_statement_item_id = EXCLUDED.usage_statement_item_id,
    requested_by_user_id = EXCLUDED.requested_by_user_id,
    assignee_user_id = EXCLUDED.assignee_user_id,
    title = EXCLUDED.title,
    reason = EXCLUDED.reason,
    status_code = EXCLUDED.status_code,
    due_date = EXCLUDED.due_date,
    created_at = EXCLUDED.created_at,
    resolved_at = EXCLUDED.resolved_at;

-- Keep sequence values ahead of fixed IDs.
SELECT setval('users_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM users), 1), true);
SELECT setval('projects_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM projects), 1), true);
SELECT setval('files_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM files), 1), true);
SELECT setval('usage_statements_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM usage_statements), 1), true);
SELECT setval('usage_statement_summaries_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM usage_statement_summaries), 1), true);
SELECT setval('usage_statement_items_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM usage_statement_items), 1), true);
SELECT setval('evidence_file_links_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM evidence_file_links), 1), true);
SELECT setval('evidence_requirements_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM evidence_requirements), 1), true);
SELECT setval('validation_logs_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM validation_logs), 1), true);
SELECT setval('action_requests_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM action_requests), 1), true);
