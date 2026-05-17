SET LOCAL search_path TO service, public;

-- ─────────────────────────────────────────────────────────────
-- D-01. agent_logs에 run_id 추가
--   유효성 검증 실행 시 vision / safety_doc / link 3개 agent를
--   동일한 run_id(UUID)로 묶어 한 배치로 추적한다.
--   기존 rows는 run_id 없이 동작하므로 nullable로 추가한다.
-- ─────────────────────────────────────────────────────────────

ALTER TABLE agent_logs
    ADD COLUMN run_id UUID;

CREATE INDEX idx_agent_logs_run_id
    ON agent_logs (run_id)
    WHERE run_id IS NOT NULL;

COMMENT ON COLUMN agent_logs.run_id IS '유효성 검증 배치 실행 단위 ID — 같은 세트의 agent_logs끼리 동일한 UUID를 공유한다';

-- ─────────────────────────────────────────────────────────────
-- D-02. files.status_code 초기값 변경: 'uploaded' → 'draft'
--   draft     : 업로드 직후, 아직 agent 미처리
--   matched   : agent 처리 완료, 이상 없음
--              (vision: 안전시설 확인 / link: 금액·품목 일치)
--   unmatched : agent 처리 완료, 문제 있음
--              (vision: 안전시설 미확인·부족 / link: 금액·품목 불일치)
-- ─────────────────────────────────────────────────────────────

UPDATE files
    SET status_code = 'draft'
    WHERE status_code = 'uploaded';

ALTER TABLE files
    DROP CONSTRAINT chk_files_status_code;

ALTER TABLE files
    ADD CONSTRAINT chk_files_status_code
        CHECK (status_code IN ('draft', 'matched', 'unmatched'));

ALTER TABLE files
    ALTER COLUMN status_code SET DEFAULT 'draft';

-- ─────────────────────────────────────────────────────────────
-- D-03. evidence_file_links.category_code 컬럼 제거
--   이 컬럼은 usage_statement_items.category_code의 복사본으로,
--   코드 전수 조사 결과 WHERE 조건으로 쓰이는 곳이 없다.
--   evidence_file_links는 usage_statement_item_id를 통해
--   JOIN 한 번으로 항상 정확한 category를 얻을 수 있으므로 제거한다.
-- ─────────────────────────────────────────────────────────────

DROP INDEX idx_evidence_file_links_file_category;
DROP INDEX idx_evidence_file_links_category_code;

ALTER TABLE evidence_file_links
    DROP COLUMN category_code;

-- ─────────────────────────────────────────────────────────────
-- D-05. usage_statements.status_code 추가
--   사용내역서 제출·검토 플로우를 월별 단위로 추적한다.
--   draft             : 작성 중 (세부항목 편집, 파일 업로드 단계)
--   upload_completed  : user가 제출 버튼 클릭, SHE에 알림 발송됨
--   supplement_required: SHE가 조치 요청 발송, user 보완 필요
--   review_completed  : SHE 최종 승인 완료
--   기존 rows는 draft로 초기화한다.
-- ─────────────────────────────────────────────────────────────

ALTER TABLE usage_statements
    ADD COLUMN status_code VARCHAR(30) NOT NULL DEFAULT 'draft';

ALTER TABLE usage_statements
    ADD CONSTRAINT chk_usage_statements_status_code
        CHECK (status_code IN ('draft', 'upload_completed', 'supplement_required', 'review_completed'));

CREATE INDEX idx_usage_statements_status_code
    ON usage_statements (status_code);

COMMENT ON COLUMN usage_statements.status_code IS '사용내역서 제출·검토 단계 (draft → upload_completed → supplement_required → review_completed)';
