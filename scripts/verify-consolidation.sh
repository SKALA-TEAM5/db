#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# verify-consolidation.sh
#   "기존 마이그레이션 체인(db/migrations)" 과
#   "통합 마이그레이션(db/_new)" 이 동일한 스키마/시드를 만드는지 검증한다.
#
#   일회용 postgres 컨테이너 2벌에 각각 flyway 를 적용한 뒤
#     1) pg_dump --schema-only 비교  → 구조·컬럼·제약·인덱스·코멘트 동등성
#     2) 시드 테이블 데이터 비교       → seed collapse 행 단위 동등성
#   둘 다 diff 0 이면 PASS. 현재 개발 DB(volumes/db)는 전혀 건드리지 않는다.
# =============================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
OLD_DIR="$ROOT_DIR/db/migrations"
NEW_DIR="$ROOT_DIR/db/_new"

PG_IMAGE="postgres:16-alpine"
FLYWAY_IMAGE="flyway/flyway:10-alpine"
FLYWAY_PLATFORM="${FLYWAY_PLATFORM:-linux/amd64}"

DB_NAME="safety"
DB_USER="safety_user"
DB_PASS="verify_pw"

NET="verify_consolidation_net_$$"
PG_OLD="verify_pg_old_$$"
PG_NEW="verify_pg_new_$$"
OUT_DIR="$(mktemp -d)"

# .env 의 flyway placeholder 값 로드 (V3 roles/grants 용)
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

cleanup() {
  docker rm -f "$PG_OLD" "$PG_NEW" >/dev/null 2>&1 || true
  docker network rm "$NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT

log() { printf '\n\033[1;36m[verify]\033[0m %s\n' "$*"; }

start_pg() {
  local name="$1"
  docker run -d --name "$name" --network "$NET" \
    -e POSTGRES_DB="$DB_NAME" \
    -e POSTGRES_USER="$DB_USER" \
    -e POSTGRES_PASSWORD="$DB_PASS" \
    "$PG_IMAGE" >/dev/null
  # readiness
  for _ in $(seq 1 30); do
    if docker exec "$name" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "postgres '$name' did not become ready" >&2
  docker logs "$name" >&2 || true
  exit 1
}

run_flyway() {
  local name="$1" dir="$2"
  docker run --rm --network "$NET" --platform "$FLYWAY_PLATFORM" \
    -v "$dir:/flyway/migrations:ro" \
    -e FLYWAY_URL="jdbc:postgresql://$name:5432/$DB_NAME" \
    -e FLYWAY_USER="$DB_USER" \
    -e FLYWAY_PASSWORD="$DB_PASS" \
    -e FLYWAY_PLACEHOLDERS_SERVICE_APP_USER="$SERVICE_APP_USER" \
    -e FLYWAY_PLACEHOLDERS_SERVICE_APP_PASSWORD="$SERVICE_APP_PASSWORD" \
    -e FLYWAY_PLACEHOLDERS_LAW_APP_USER="$LAW_APP_USER" \
    -e FLYWAY_PLACEHOLDERS_LAW_APP_PASSWORD="$LAW_APP_PASSWORD" \
    -e FLYWAY_PLACEHOLDERS_DEV_ADMIN_USER="$DEV_ADMIN_USER" \
    -e FLYWAY_PLACEHOLDERS_DEV_ADMIN_PASSWORD="$DEV_ADMIN_PASSWORD" \
    -e FLYWAY_LOCATIONS="filesystem:/flyway/migrations" \
    "$FLYWAY_IMAGE" migrate
}

# pg_dump 스키마 덤프 → SQL 주석/빈 줄 제거하여 노이즈 차단
dump_schema() {
  local name="$1" out="$2"
  docker exec "$name" pg_dump -U "$DB_USER" -d "$DB_NAME" \
    --schema-only --no-owner --no-privileges \
    -n service -n legal_rag \
    | grep -vE '^\s*--' | grep -vE '^\s*$' \
    | grep -vE '^\\(un)?restrict ' > "$out"
}

# 시드 테이블 데이터 — id/타임스탬프 제외, 비즈니스 키 기준 정렬
dump_data() {
  local name="$1" out="$2"
  docker exec -i "$name" psql -U "$DB_USER" -d "$DB_NAME" -At -F '|' >"$out" <<'SQL'
\echo == users ==
SELECT employee_no, real_name, role_code, password_hash
FROM service.users ORDER BY employee_no;
\echo == projects ==
SELECT contract_no, construction_company, project_name, site_location,
       representative_name, contract_amount, construction_start_date,
       construction_end_date, client_name, appropriated_amount, project_status_code
FROM service.projects ORDER BY contract_no;
\echo == assignments ==
SELECT p.contract_no, u.employee_no, ab.employee_no AS assigned_by
FROM service.project_user_assignments a
JOIN service.projects p ON p.id = a.project_id
JOIN service.users u    ON u.id = a.user_id
LEFT JOIN service.users ab ON ab.id = a.assigned_by_user_id
ORDER BY p.contract_no, u.employee_no;
\echo == usage_categories ==
SELECT code, name FROM service.usage_categories ORDER BY code;
\echo == evidence_types ==
SELECT code, name, description FROM service.evidence_types ORDER BY code;
SQL
}

log "docker network 생성: $NET"
docker network create "$NET" >/dev/null

log "[OLD] postgres 기동 + flyway(db/migrations) 적용"
start_pg "$PG_OLD"
run_flyway "$PG_OLD" "$OLD_DIR"

log "[NEW] postgres 기동 + flyway(db/_new) 적용"
start_pg "$PG_NEW"
run_flyway "$PG_NEW" "$NEW_DIR"

log "스키마 덤프 비교 (pg_dump --schema-only)"
dump_schema "$PG_OLD" "$OUT_DIR/old_schema.sql"
dump_schema "$PG_NEW" "$OUT_DIR/new_schema.sql"

log "시드 데이터 덤프 비교"
dump_data "$PG_OLD" "$OUT_DIR/old_data.txt"
dump_data "$PG_NEW" "$OUT_DIR/new_data.txt"

schema_ok=0
data_ok=0

echo ""
echo "──────────────────────────────────────────────"
if diff -u "$OUT_DIR/old_schema.sql" "$OUT_DIR/new_schema.sql" > "$OUT_DIR/schema.diff"; then
  echo "✅ SCHEMA: 동일 (구조·컬럼·제약·인덱스·코멘트 일치)"
  schema_ok=1
else
  echo "❌ SCHEMA: 차이 발견 → $OUT_DIR/schema.diff"
  sed -n '1,80p' "$OUT_DIR/schema.diff"
fi

if diff -u "$OUT_DIR/old_data.txt" "$OUT_DIR/new_data.txt" > "$OUT_DIR/data.diff"; then
  echo "✅ SEED DATA: 동일 (users/projects/assignments/categories/evidence_types)"
  data_ok=1
else
  echo "❌ SEED DATA: 차이 발견 → $OUT_DIR/data.diff"
  sed -n '1,80p' "$OUT_DIR/data.diff"
fi
echo "──────────────────────────────────────────────"
echo "덤프 산출물: $OUT_DIR"
echo ""

if [[ "$schema_ok" -eq 1 && "$data_ok" -eq 1 ]]; then
  echo "🎉 PASS — 통합 마이그레이션이 기존과 동일한 결과를 만듭니다."
  trap - EXIT
  cleanup
  exit 0
else
  echo "⚠️  FAIL — 위 diff 를 확인하세요. (컨테이너는 정리됨, 덤프는 $OUT_DIR 보존)"
  exit 1
fi
