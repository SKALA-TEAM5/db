SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- todos.evidence_type_code
--   safety-doc TODO가 가리키는 증빙 유형 코드(evidence_types.code)를 구조화해 보관한다.
--   기존에는 코드가 reason 문자열 안에만 박혀 있어, 표시명(한글) 변환을 프론트가
--   하드코딩 매핑으로 처리했다. 코드를 별도 컬럼으로 분리해 조회 시 evidence_types와
--   조인하여 한글 표시명을 함께 내려준다(파일 API의 uploaded_evidence_type_name과 동일 기준).
--
--   값 출처: agent_logs.details payload.todos[].evidence_type_codes[] (코드별 분할 시 각 코드,
--            단일 코드면 그 코드). evidence_type_codes 가 없는 노드(link/vision/legal 등)는 NULL.
--   FK는 걸지 않는다 — todos 는 파생 읽기 모델이고, code 미해석 시 reason fallback 으로 충분하다.
-- ─────────────────────────────────────────────────────────────

ALTER TABLE service.todos
    ADD COLUMN evidence_type_code VARCHAR(50);

COMMENT ON COLUMN service.todos.evidence_type_code IS 'safety-doc TODO가 가리키는 증빙 유형 코드(evidence_types.code). 조회 시 한글 표시명으로 변환. 해당 없으면 NULL';
