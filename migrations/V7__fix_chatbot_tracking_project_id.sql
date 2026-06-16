-- =============================================================
-- V7__fix_chatbot_tracking_project_id.sql
-- 챗봇 사용량 추적용 프로젝트의 PK를 999로 고정한다.
--
-- 배경:
--   FastAPI(chatbot_service.py)는 챗봇 사용량을 기록할 때
--   agent_usage_records.project_id 에 999 를 하드코딩한다.
--   그러나 V6 시드는 챗봇 프로젝트를 contract_no='999' 로만 넣고
--   id 는 BIGSERIAL 자동값이라 실제 projects.id ≠ 999 였다.
--   → agent_usage_records.project_id(=999) 가 projects(id) FK 를 위반,
--     INSERT 가 예외로 실패(FastAPI 측 fire-and-forget 로 무시됨) →
--     챗봇 사용량이 DB 에 적재되지 않았다.
--
-- 조치:
--   contract_no='999' 인 챗봇 프로젝트를 id=999 로 재배치한다.
--   PK 이전은 자식 테이블 FK(RESTRICT) 때문에 직접 UPDATE 불가하므로,
--   id=999 행을 먼저 만들고 자식 행을 repoint 한 뒤 기존 행을 제거한다.
--
--   멱등: id=999 가 이미 존재하면 아무 것도 하지 않는다.
-- =============================================================
SET LOCAL search_path TO service, public;

DO $$
DECLARE
    old_id BIGINT;
BEGIN
    -- 이미 보정됨 → 멱등 종료
    IF EXISTS (SELECT 1 FROM service.projects WHERE id = 999) THEN
        RETURN;
    END IF;

    SELECT id INTO old_id FROM service.projects WHERE contract_no = '999';

    IF old_id IS NULL THEN
        -- 챗봇 프로젝트가 없으면 id=999 로 신규 생성
        INSERT INTO service.projects (
            id, contract_no, construction_company, project_name, site_location,
            representative_name, contract_amount,
            construction_start_date, construction_end_date,
            client_name, appropriated_amount, project_status_code
        )
        VALUES (
            999, '999', 'CHATBOT-999', '챗봇', '챗봇 사용량 추적용',
            '시스템', 0,
            DATE '2026-01-01', DATE '2099-12-31',
            '내부 시스템', 0, 'active'
        );
    ELSE
        -- 기존 챗봇 프로젝트(old_id)를 id=999 로 이전
        -- 1) 고유 제약(contract_no, project_name)을 비우기 위해 임시 값으로 변경
        UPDATE service.projects
           SET contract_no = '999-legacy', project_name = '챗봇-legacy'
         WHERE id = old_id;

        -- 2) id=999 정규 행 생성 (unique 컬럼은 정규 값으로 고정, 나머지는 복사)
        INSERT INTO service.projects (
            id, contract_no, construction_company, project_name, site_location,
            representative_name, contract_amount,
            construction_start_date, construction_end_date,
            client_name, appropriated_amount, project_status_code,
            created_at, updated_at
        )
        SELECT
            999, '999', construction_company, '챗봇', site_location,
            representative_name, contract_amount,
            construction_start_date, construction_end_date,
            client_name, appropriated_amount, project_status_code,
            created_at, now()
        FROM service.projects WHERE id = old_id;

        -- 3) 자식 행 repoint (projects(id) 를 참조하는 모든 테이블)
        UPDATE service.project_user_assignments SET project_id = 999 WHERE project_id = old_id;
        UPDATE service.files                    SET project_id = 999 WHERE project_id = old_id;
        UPDATE service.usage_statements         SET project_id = 999 WHERE project_id = old_id;
        UPDATE service.agent_logs               SET project_id = 999 WHERE project_id = old_id;
        UPDATE service.agent_usage_records      SET project_id = 999 WHERE project_id = old_id;

        -- 4) 기존 행 제거 (자식이 모두 옮겨졌으므로 FK 위반 없음)
        DELETE FROM service.projects WHERE id = old_id;
    END IF;

    -- serial 시퀀스는 999 미만의 최대 id 기준으로 유지 → 앱 신규 프로젝트가
    -- 1000 으로 점프하지 않고 작은 id 를 계속 사용하도록 한다.
    PERFORM setval(
        pg_get_serial_sequence('service.projects', 'id'),
        GREATEST((SELECT COALESCE(MAX(id), 0) FROM service.projects WHERE id < 999), 1),
        true
    );
END $$;
