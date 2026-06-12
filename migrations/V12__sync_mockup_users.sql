-- =============================================================
-- V12__sync_mockup_users.sql
-- 개발 사용자 목업을 운영 개발 DB의 계정 구성과 동기화
--
-- 기존 계정:
--   비밀번호 해시는 유지하고 이름과 역할만 갱신한다.
-- 신규 계정:
--   ADMIN-* 기본 비밀번호 Admin1234!
--   USER-*  기본 비밀번호 User1234!
-- =============================================================
SET LOCAL search_path TO service, public;

INSERT INTO users (employee_no, real_name, password_hash, role_code)
VALUES
    (
        'SYS-001',
        '이베리',
        '$2y$12$joImXqDiNtrBwXV6wbDo8uoEsKzYfQjD4n6flnTzs8vR6vg9cfV6m',
        'system_admin'
    ),
    (
        'ADMIN-001',
        '김동우',
        '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu',
        'admin'
    ),
    (
        'ADMIN-002',
        '한채윤',
        '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu',
        'admin'
    ),
    (
        'ADMIN-003',
        '차현주',
        '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu',
        'admin'
    ),
    (
        'ADMIN-004',
        '송상민',
        '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu',
        'admin'
    ),
    (
        'ADMIN-005',
        '이현수',
        '$2y$12$fu40qSD1PjbzuaBTuhs4LONH3xgoXCNimu8Q/9b.OknMpRBruyQDu',
        'admin'
    ),
    (
        'USER-001',
        '김소연',
        '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2',
        'user'
    ),
    (
        'USER-002',
        '한준수',
        '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2',
        'user'
    ),
    (
        'USER-003',
        '차태현',
        '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2',
        'user'
    ),
    (
        'USER-004',
        '송지효',
        '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2',
        'user'
    ),
    (
        'USER-005',
        '이재성',
        '$2y$12$GvLF2ME1SyQh/UCcMBzb.Ogv2dTpsx8BqsWxQJbIekauTDauICKj2',
        'user'
    )
ON CONFLICT (employee_no) DO UPDATE
SET
    real_name = EXCLUDED.real_name,
    role_code = EXCLUDED.role_code,
    updated_at = now();

-- V6에서 사용하던 레거시 목업 계정은 참조가 없을 때만 제거한다.
-- 운영 중 생성된 데이터가 연결돼 있다면 계정을 보존해 FK 무결성을 유지한다.
DELETE FROM users legacy
WHERE legacy.employee_no IN (
    'SHE-001',
    'SHE-002',
    'SHE-003',
    'USR-101',
    'USR-201',
    'USR-202',
    'USR-301',
    'USR-302'
)
  AND NOT EXISTS (
      SELECT 1
      FROM refresh_tokens rt
      WHERE rt.user_id = legacy.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM project_user_assignments pua
      WHERE pua.user_id = legacy.id
         OR pua.assigned_by_user_id = legacy.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM files f
      WHERE f.uploaded_by_user_id = legacy.id
         OR f.deleted_by_user_id = legacy.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM agent_usage_records aur
      WHERE aur.user_id = legacy.id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM todos t
      WHERE t.confirmed_by = legacy.id
  );
