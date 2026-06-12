INSERT INTO service.evidence_types (code, name, description)
VALUES
    ('other_document', '기타 서류', '위 항목에 해당하지 않는 기타 증빙서류')
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;
