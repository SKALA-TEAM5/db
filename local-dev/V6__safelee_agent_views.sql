SET search_path TO service, public;

/*
AI가 item 1건의 필수 증빙을 판단할 때 필요한 조회용 뷰 초안.

- 실제 마이그레이션 전 초안 검토용이므로 `db/migrations`가 아니라 `db/sql-drafts`에 둔다.
- API 서버는 이 뷰를 읽어서 safety_doc_agent 입력 DTO를 만들 수 있다.
*/

CREATE OR REPLACE VIEW service.v_ai_evidence_requirement_item_context AS
SELECT
    p.id AS project_id,
    p.project_name,
    usi.id AS item_id,
    usi.usage_statement_id,
    us.report_month,
    us.revision_no,
    usi.category_code,
    uc.name AS category_name,
    usi.used_on,
    usi.item_name,
    usi.unit,
    usi.quantity,
    usi.unit_price,
    usi.total_amount,
    usi.remark,
    usi.page_no
FROM service.usage_statement_items usi
JOIN service.usage_statements us
  ON us.id = usi.usage_statement_id
JOIN service.projects p
  ON p.id = us.project_id
JOIN service.usage_categories uc
  ON uc.code = usi.category_code;


CREATE OR REPLACE VIEW service.v_ai_evidence_requirement_file_context AS
SELECT
    efl.usage_statement_item_id AS item_id,
    f.id AS file_id,
    f.original_filename,
    f.mime_type,
    f.uploaded_evidence_type_code,
    efl.evidence_type_code AS linked_evidence_type_code,
    f.storage_key,
    f.captured_at,
    f.uploaded_at
FROM service.evidence_file_links efl
JOIN service.files f
  ON f.id = efl.file_id;


CREATE OR REPLACE VIEW service.v_ai_evidence_requirement_targets AS
SELECT
    ctx.project_id,
    ctx.project_name,
    ctx.usage_statement_id,
    ctx.report_month,
    ctx.revision_no,
    ctx.item_id,
    ctx.category_code,
    ctx.category_name,
    ctx.item_name,
    ctx.used_on,
    ctx.total_amount,
    COALESCE(req.active_requirement_count, 0) AS active_requirement_count,
    COALESCE(linked.linked_file_count, 0) AS linked_file_count
    
FROM service.v_ai_evidence_requirement_item_context ctx
LEFT JOIN (
    SELECT
        usage_statement_item_id,
        COUNT(*) AS active_requirement_count
    FROM service.evidence_requirements
    WHERE is_active = true
    GROUP BY usage_statement_item_id
) req
  ON req.usage_statement_item_id = ctx.item_id
LEFT JOIN (
    SELECT
        usage_statement_item_id,
        COUNT(*) AS linked_file_count
    FROM service.evidence_file_links
    GROUP BY usage_statement_item_id
) linked
  ON linked.usage_statement_item_id = ctx.item_id;
