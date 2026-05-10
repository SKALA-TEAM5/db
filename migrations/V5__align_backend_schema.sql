SET LOCAL search_path TO service, public;

-- Project access is enforced by the Spring backend, not by PostgreSQL RLS.
DROP POLICY IF EXISTS p_projects_select_by_role ON service.projects;
ALTER TABLE service.projects DISABLE ROW LEVEL SECURITY;

-- Roles used by the backend.
ALTER TABLE service.users
    DROP CONSTRAINT IF EXISTS chk_users_role_code;

ALTER TABLE service.users
    ADD CONSTRAINT chk_users_role_code
    CHECK (role_code IN ('system_admin', 'admin', 'user', 'agent'));

-- Refresh tokens used by auth.
CREATE TABLE IF NOT EXISTS service.refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_refresh_tokens_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_refresh_tokens_user_id
        FOREIGN KEY (user_id) REFERENCES service.users (id)
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
    ON service.refresh_tokens (user_id);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_active_user
    ON service.refresh_tokens (user_id, expires_at)
    WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS service.project_user_assignments (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    assigned_by_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_project_user_assignments_project_user UNIQUE (project_id, user_id),
    CONSTRAINT fk_project_user_assignments_project_id
        FOREIGN KEY (project_id) REFERENCES service.projects (id),
    CONSTRAINT fk_project_user_assignments_user_id
        FOREIGN KEY (user_id) REFERENCES service.users (id),
    CONSTRAINT fk_project_user_assignments_assigned_by_user_id
        FOREIGN KEY (assigned_by_user_id) REFERENCES service.users (id)
);

-- Preserve existing project ownership as an assignment before removing projects.user_id.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'service'
          AND table_name = 'projects'
          AND column_name = 'user_id'
    ) THEN
        INSERT INTO service.project_user_assignments (project_id, user_id)
        SELECT id, user_id
        FROM service.projects
        WHERE user_id IS NOT NULL
        ON CONFLICT (project_id, user_id) DO NOTHING;
    END IF;
END
$$;

-- Projects use many-to-many assignees instead of projects.user_id.
ALTER TABLE service.projects
    DROP CONSTRAINT IF EXISTS fk_projects_user_id;

ALTER TABLE service.projects
    DROP COLUMN IF EXISTS user_id;

CREATE INDEX IF NOT EXISTS idx_project_user_assignments_user_project
    ON service.project_user_assignments (user_id, project_id);

CREATE INDEX IF NOT EXISTS idx_project_user_assignments_project_id
    ON service.project_user_assignments (project_id);

CREATE INDEX IF NOT EXISTS idx_project_user_assignments_assigned_by_user_id
    ON service.project_user_assignments (assigned_by_user_id)
    WHERE assigned_by_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_projects_status_created_at
    ON service.projects (project_status_code, created_at DESC);

DROP INDEX IF EXISTS service.idx_projects_user_status;

-- File soft delete support.
ALTER TABLE service.files
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS deleted_by_user_id BIGINT;

ALTER TABLE service.files
    DROP CONSTRAINT IF EXISTS fk_files_deleted_by_user_id;

ALTER TABLE service.files
    ADD CONSTRAINT fk_files_deleted_by_user_id
    FOREIGN KEY (deleted_by_user_id) REFERENCES service.users (id);

CREATE INDEX IF NOT EXISTS idx_files_project_active_uploaded_at
    ON service.files (project_id, uploaded_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_files_deleted_by_user_id
    ON service.files (deleted_by_user_id)
    WHERE deleted_by_user_id IS NOT NULL;

-- Evidence link review support.
ALTER TABLE service.evidence_file_links
    ADD COLUMN IF NOT EXISTS checked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS checked_by_user_id BIGINT;

ALTER TABLE service.evidence_file_links
    DROP CONSTRAINT IF EXISTS fk_evidence_file_links_checked_by_user_id;

ALTER TABLE service.evidence_file_links
    ADD CONSTRAINT fk_evidence_file_links_checked_by_user_id
    FOREIGN KEY (checked_by_user_id) REFERENCES service.users (id);

CREATE INDEX IF NOT EXISTS idx_evidence_file_links_checked_at
    ON service.evidence_file_links (checked_at)
    WHERE checked_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_evidence_file_links_unchecked
    ON service.evidence_file_links (usage_statement_item_id, file_id)
    WHERE checked_at IS NULL;

-- Validation logs stay, but ai_agent_run linkage is removed.
ALTER TABLE service.validation_logs
    DROP COLUMN IF EXISTS ai_agent_run_id,
    ADD COLUMN IF NOT EXISTS agent_type_code VARCHAR(50),
    ADD COLUMN IF NOT EXISTS log_type_code VARCHAR(50),
    ADD COLUMN IF NOT EXISTS severity_code VARCHAR(30) NOT NULL DEFAULT 'info';

ALTER TABLE service.validation_logs
    ALTER COLUMN result_code DROP NOT NULL;
