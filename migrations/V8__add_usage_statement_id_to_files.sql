-- 증빙 파일에 소속 사용내역서 식별자를 추가한다.
--
-- 배경: files 는 project_id 로만 연결되어, 업로드된 증빙이 어느 사용내역서(usage_statements)에
-- 속한 것인지 알 수 없었다. 이로 인해 매칭(fastapi) 단계가 후보를 사용내역서 단위로 좁히지 못하고
-- 프로젝트 전체 증빙을 끌어와, 증빙 미업로드 사용내역서에 다른 월 증빙이 자동 매칭되는 버그가 있었다.
--
-- nullable: 사용내역서 원본 PDF 는 statement 생성 "전"에 업로드되므로 그 시점엔 값이 없다.
-- 매칭 후보 쿼리는 usage_statement_id IS NULL 인 파일(원본 PDF 등)을 자동 제외한다.

ALTER TABLE service.files ADD COLUMN usage_statement_id BIGINT NULL;

ALTER TABLE service.files
    ADD CONSTRAINT fk_files_usage_statement_id
    FOREIGN KEY (usage_statement_id) REFERENCES service.usage_statements (id);

CREATE INDEX idx_files_usage_statement_id
    ON service.files (usage_statement_id)
    WHERE deleted_at IS NULL;

COMMENT ON COLUMN service.files.usage_statement_id IS '소속 사용내역서ID (증빙 업로드 시 기록, 원본 PDF는 NULL)';

-- 기존 데이터 백필: 이미 항목에 연결된 파일은 링크 -> 항목 -> 사용내역서로 역추적해 채운다.
-- (한 파일이 서로 다른 사용내역서의 항목에 연결된 비정상 케이스는 DISTINCT 후 임의 1건이 아닌
--  단일 값일 때만 안전하므로, 단일 사용내역서로 귀속되는 파일만 백필한다.)
UPDATE service.files f
SET usage_statement_id = sub.usage_statement_id
FROM (
    SELECT efl.file_id, MIN(usi.usage_statement_id) AS usage_statement_id
    FROM service.evidence_file_links efl
    JOIN service.usage_statement_items usi ON usi.id = efl.usage_statement_item_id
    GROUP BY efl.file_id
    HAVING COUNT(DISTINCT usi.usage_statement_id) = 1
) sub
WHERE f.id = sub.file_id
  AND f.usage_statement_id IS NULL;
