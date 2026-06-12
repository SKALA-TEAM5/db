-- =============================================================
-- V13__seed_development_projects.sql
-- 개발 환경 프로젝트 목업 및 챗봇 사용량 추적용 프로젝트 등록
-- =============================================================
SET LOCAL search_path TO service, public;

INSERT INTO projects (
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
VALUES
    (
        '2026-0107',
        '(주)한국종합건설',
        '부산 해운대구 주상복합 신축공사',
        '부산광역시 해운대구 마린시티로 45',
        '이건설',
        2200000000,
        DATE '2025-05-01',
        DATE '2026-12-31',
        '해운대구청',
        51810000,
        'active'
    ),
    (
        '2026-0106',
        '(주)스칼라 건설',
        '서울 강남구 사무용 빌딩 신축공사',
        '서울특별시 강남구 테헤란로 123',
        '김스칼라',
        1500000000,
        DATE '2025-03-04',
        DATE '2026-07-03',
        '강남구청',
        35349000,
        'active'
    ),
    (
        '2026-0108',
        '(주)대한토건',
        '인천 연수구 물류센터 신축공사',
        '인천광역시 연수구 송도과학로 87',
        '박토건',
        980000000,
        DATE '2025-06-15',
        DATE '2026-09-30',
        '연수구청',
        23079000,
        'active'
    ),
    (
        '2026-0109',
        '(주)미래건설',
        '대전 유성구 연구소 리모델링공사',
        '대전광역시 유성구 대학로 291',
        '최미래',
        670000000,
        DATE '2025-08-01',
        DATE '2026-05-31',
        '유성구청',
        15307500,
        'active'
    ),
    (
        '999',
        'CHATBOT-999',
        '챗봇',
        '챗봇 사용량 추적용',
        '시스템',
        0,
        DATE '2026-01-01',
        DATE '2099-12-31',
        '내부 시스템',
        0,
        'active'
    )
ON CONFLICT (contract_no) DO UPDATE
SET
    construction_company = EXCLUDED.construction_company,
    project_name = EXCLUDED.project_name,
    site_location = EXCLUDED.site_location,
    representative_name = EXCLUDED.representative_name,
    contract_amount = EXCLUDED.contract_amount,
    construction_start_date = EXCLUDED.construction_start_date,
    construction_end_date = EXCLUDED.construction_end_date,
    client_name = EXCLUDED.client_name,
    appropriated_amount = EXCLUDED.appropriated_amount,
    project_status_code = EXCLUDED.project_status_code,
    updated_at = now();
