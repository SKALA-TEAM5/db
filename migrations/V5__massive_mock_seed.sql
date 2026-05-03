SET LOCAL search_path TO service, public;

-- -----------------------------------------------------------------------------
-- V5 massive mock seed
-- - Generates large-volume demo data across core service tables
-- - Idempotency guard: skips all inserts if marker log already exists
-- -----------------------------------------------------------------------------

-- 1) users: 300 mock users
INSERT INTO users (employee_no, real_name, password_hash, role_code)
SELECT
    format('MOCK-USER-%04s', g),
    format('테스터%04s', g),
    format('$2b$10$mockhash%04s', g),
    CASE
        WHEN g <= 15 THEN 'admin'
        WHEN g <= 60 THEN 'agent'
        ELSE 'user'
    END
FROM generate_series(1, 300) AS g
WHERE NOT EXISTS (
    SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
);

-- 2) projects: 900 mock projects
INSERT INTO projects (
    user_id,
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
SELECT
    u.id,
    format('CN-2026-%06s', g),
    format('목업건설%03s', ((g - 1) % 120) + 1),
    format('목업 안전개선 프로젝트 %04s', g),
    format('대한민국 산업단지 %03s 블록', ((g - 1) % 300) + 1),
    format('대표자%03s', ((g - 1) % 200) + 1),
    (350000000 + (g::bigint * 2750000))::numeric(18, 0),
    (DATE '2025-01-01' + ((g - 1) % 300)),
    (DATE '2025-01-01' + ((g - 1) % 300) + 240),
    format('발주처%03s', ((g - 1) % 150) + 1),
    (22000000 + (g * 180000))::numeric(18, 0),
    CASE
        WHEN (g % 10) = 0 THEN 'suspended'
        WHEN (g % 9) = 0 THEN 'completed'
        ELSE 'active'
    END
FROM generate_series(1, 900) AS g
JOIN LATERAL (
    SELECT id
    FROM users
    WHERE employee_no = format('MOCK-USER-%04s', ((g - 1) % 300) + 1)
) AS u ON true
WHERE NOT EXISTS (
    SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
);

-- 3) files: 6 files per mock project (5,400 rows)
INSERT INTO files (
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
SELECT
    p.id,
    p.user_id,
    CASE k.seq
        WHEN 1 THEN 'usage_statement'
        WHEN 2 THEN 'site_photo'
        WHEN 3 THEN 'tax_invoice'
        WHEN 4 THEN 'inspection_log'
        WHEN 5 THEN 'work_photo'
        ELSE 'purchase_detail'
    END,
    format('mock_%s_%s.%s', p.id, k.seq, CASE WHEN k.seq IN (2, 5) THEN 'jpg' ELSE 'pdf' END),
    format('mock/projects/%s/files/%s', p.id, k.seq),
    CASE WHEN k.seq IN (2, 5) THEN 'image/jpeg' ELSE 'application/pdf' END,
    (90000 + (p.id % 800000) + (k.seq * 1500))::bigint,
    CASE WHEN k.seq IN (2, 5) THEN (now() - ((p.id % 150) || ' days')::interval) ELSE NULL END,
    now() - ((p.id % 120) || ' days')::interval + ((k.seq * 13) || ' minutes')::interval
FROM projects p
CROSS JOIN (SELECT generate_series(1, 6) AS seq) AS k
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 4) usage_statements: 3 per mock project (2,700 rows)
INSERT INTO usage_statements (
    project_id,
    source_file_id,
    report_month,
    revision_no,
    document_written_date,
    cumulative_progress_rate
)
SELECT
    p.id,
    NULL,
    (date_trunc('month', DATE '2026-04-01' - (m.n || ' months')::interval))::date,
    1,
    ((date_trunc('month', DATE '2026-04-01' - (m.n || ' months')::interval))::date + 27),
    ((20 + ((p.id % 70) * 0.9) + (m.n * 3.5)) % 100)::numeric(5, 2)
FROM projects p
CROSS JOIN (SELECT generate_series(0, 2) AS n) AS m
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 5) usage_statement_summaries: 4 categories per statement (10,800 rows)
INSERT INTO usage_statement_summaries (
    usage_statement_id,
    category_code,
    previous_amount,
    current_amount,
    cumulative_amount
)
SELECT
    us.id,
    c.code,
    (1000000 + ((us.id % 500) * 17000))::numeric(18, 0),
    (300000 + ((us.id % 300) * 9000))::numeric(18, 0),
    (1300000 + ((us.id % 500) * 17000) + ((us.id % 300) * 9000))::numeric(18, 0)
FROM usage_statements us
CROSS JOIN (VALUES ('CAT_01'), ('CAT_02'), ('CAT_03'), ('CAT_08')) AS c(code)
JOIN projects p ON p.id = us.project_id
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 6) usage_statement_items: 8 items per statement (21,600 rows)
INSERT INTO usage_statement_items (
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
SELECT
    us.id,
    CASE ((i.n - 1) % 4)
        WHEN 0 THEN 'CAT_01'
        WHEN 1 THEN 'CAT_02'
        WHEN 2 THEN 'CAT_03'
        ELSE 'CAT_08'
    END,
    (us.report_month + ((i.n * 3) % 25)),
    format('목업 지출 항목 %s-%s', us.id, i.n),
    CASE WHEN (i.n % 2) = 0 THEN '식' ELSE '개' END,
    (1 + ((us.id + i.n) % 12))::numeric(14, 3),
    (12000 + ((us.id + i.n) % 35) * 4200)::numeric(18, 2),
    ((1 + ((us.id + i.n) % 12)) * (12000 + ((us.id + i.n) % 35) * 4200))::numeric(18, 0),
    CASE WHEN (i.n % 3) = 0 THEN '현장 확인 필요' ELSE NULL END,
    i.n
FROM usage_statements us
JOIN projects p ON p.id = us.project_id
CROSS JOIN (SELECT generate_series(1, 8) AS n) AS i
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 7) evidence_requirements: 2 requirements per item (43,200 rows)
INSERT INTO evidence_requirements (
    usage_statement_item_id,
    evidence_type_code,
    is_satisfied,
    is_active
)
SELECT
    it.id,
    et.code,
    ((it.id + et.ord) % 5) <> 0,
    true
FROM usage_statement_items it
JOIN usage_statements us ON us.id = it.usage_statement_id
JOIN projects p ON p.id = us.project_id
CROSS JOIN (VALUES (1, 'tax_invoice'), (2, 'site_photo')) AS et(ord, code)
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 8) evidence_file_links: 1 linked file per item
INSERT INTO evidence_file_links (
    usage_statement_item_id,
    file_id,
    category_code,
    evidence_type_code
)
SELECT
    it.id,
    f.id,
    it.category_code,
    CASE WHEN (it.id % 2) = 0 THEN 'site_photo' ELSE 'tax_invoice' END
FROM usage_statement_items it
JOIN usage_statements us ON us.id = it.usage_statement_id
JOIN projects p ON p.id = us.project_id
JOIN LATERAL (
    SELECT id
    FROM files
    WHERE project_id = p.id
    ORDER BY id
    OFFSET (it.id % 6)
    LIMIT 1
) AS f ON true
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 9) action_requests: create for ~30% of items (about 6,480 rows)
INSERT INTO action_requests (
    project_id,
    usage_statement_id,
    usage_statement_item_id,
    requested_by_user_id,
    assignee_user_id,
    title,
    reason,
    status_code,
    due_date,
    resolved_at
)
SELECT
    p.id,
    us.id,
    it.id,
    p.user_id,
    CASE WHEN (it.id % 4) = 0 THEN NULL ELSE p.user_id END,
    format('조치요청-%s', it.id),
    CASE
        WHEN (it.id % 5) = 0 THEN '증빙 불충분'
        WHEN (it.id % 5) = 1 THEN '금액 검토 필요'
        WHEN (it.id % 5) = 2 THEN '항목 분류 재확인'
        WHEN (it.id % 5) = 3 THEN '사진 누락'
        ELSE '기타 검토 필요'
    END,
    CASE
        WHEN (it.id % 7) IN (0, 1, 2) THEN 'open'
        WHEN (it.id % 7) IN (3, 4) THEN 'in_progress'
        WHEN (it.id % 7) = 5 THEN 'resolved'
        ELSE 'closed'
    END,
    (CURRENT_DATE + (((it.id % 21) + 1)::integer)),
    CASE
        WHEN (it.id % 7) IN (5, 6)
            THEN (now() - ((it.id % 30) || ' days')::interval)
        ELSE NULL
    END
FROM usage_statement_items it
JOIN usage_statements us ON us.id = it.usage_statement_id
JOIN projects p ON p.id = us.project_id
WHERE p.contract_no LIKE 'CN-2026-%'
  AND (it.id % 10) < 3
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

-- 10) validation_logs: sample logs + seed marker
INSERT INTO validation_logs (
    project_id,
    usage_statement_id,
    usage_statement_item_id,
    validation_type_code,
    result_code,
    details,
    model_name
)
SELECT
    p.id,
    us.id,
    it.id,
    'rule_check',
    CASE WHEN (it.id % 6) = 0 THEN 'fail' ELSE 'pass' END,
    jsonb_build_object(
        'message', CASE WHEN (it.id % 6) = 0 THEN '항목 검증 실패' ELSE '항목 검증 통과' END,
        'score', ((it.id % 100) / 100.0)
    ),
    'mock-validator-v1'
FROM usage_statement_items it
JOIN usage_statements us ON us.id = it.usage_statement_id
JOIN projects p ON p.id = us.project_id
WHERE p.contract_no LIKE 'CN-2026-%'
  AND (it.id % 8) = 0
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  );

INSERT INTO validation_logs (
    project_id,
    validation_type_code,
    result_code,
    details,
    model_name
)
SELECT
    p.id,
    'seed',
    'ok',
    jsonb_build_object('seed', 'V5 massive mock seed applied'),
    'MOCK_V5_SEEDED'
FROM projects p
WHERE p.contract_no LIKE 'CN-2026-%'
  AND NOT EXISTS (
      SELECT 1 FROM validation_logs WHERE model_name = 'MOCK_V5_SEEDED'
  )
ORDER BY p.id
LIMIT 1;
