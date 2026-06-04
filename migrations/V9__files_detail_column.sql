SET search_path TO service, public;

ALTER TABLE files
    ADD COLUMN detail JSONB;

COMMENT ON COLUMN files.detail IS '파일 부가 정보 (현장사진 EXIF, AI 분석 결과 등) — FastAPI가 기록';
