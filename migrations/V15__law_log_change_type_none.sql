-- =============================================================
-- Migration: V15__law_log_change_type_none.sql
-- law_log.change_type 제약에 'none' 추가
-- 변경 없는 배치 실행 시 sentinel 행 기록을 위해 필요
-- =============================================================

SET LOCAL search_path TO legal_rag, public;

ALTER TABLE legal_rag.law_log
    DROP CONSTRAINT chk_law_log_change_type;

ALTER TABLE legal_rag.law_log
    ADD CONSTRAINT chk_law_log_change_type
        CHECK (change_type IN ('added', 'updated', 'deleted', 'none'));
