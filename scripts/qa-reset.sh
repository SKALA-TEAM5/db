#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/migrations"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

K8S_NAMESPACE="${K8S_NAMESPACE:-skala3-finalproj-class2-team5}"
K8S_PG_SERVICE="${K8S_PG_SERVICE:-svc/team5-postgres}"
K8S_MINIO_SERVICE="${K8S_MINIO_SERVICE:-svc/team5-minio}"
K8S_PG_CONFIG="${K8S_PG_CONFIG:-team5-postgres-config}"
K8S_PG_SECRET="${K8S_PG_SECRET:-team5-postgres-secret}"
K8S_MINIO_CONFIG="${K8S_MINIO_CONFIG:-team5-minio-config}"
K8S_MINIO_SECRET="${K8S_MINIO_SECRET:-team5-minio-secret}"
PG_LOCAL_PORT="${PG_LOCAL_PORT:-5433}"
MINIO_LOCAL_PORT="${MINIO_LOCAL_PORT:-9002}"
DOCKER_PLATFORM="${FLYWAY_PLATFORM:-linux/amd64}"
DOCKER_HOST_GATEWAY_ARG=(--add-host=host.docker.internal:host-gateway)

MODE="port-forward"   # port-forward(K8s) | local
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage:
  scripts/qa-reset.sh [options]

service 스키마 + MinIO projects/ 를 최신 마이그레이션 상태로 초기화합니다.
legal_rag 스키마·데이터는 보존됩니다.

Options:
  --port-forward       K8s 배포 DB 를 port-forward 로 초기화 (기본). 환경값은 K8s ConfigMap/Secret 에서 읽음.
  --local              로컬 docker-compose DB 를 초기화. 환경값은 프로젝트 루트 .env 에서 읽음(port-forward 없음).
  --yes                확인 프롬프트 생략.
  --namespace NAME     K8s 네임스페이스.   Default: skala3-finalproj-class2-team5
  --pg-service NAME    K8s Postgres 서비스. Default: svc/team5-postgres
  --minio-service NAME K8s MinIO 서비스.    Default: svc/team5-minio
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port-forward)  MODE="port-forward";   shift ;;
    --local)         MODE="local";          shift ;;
    --yes)           ASSUME_YES=1;          shift ;;
    --namespace)     K8S_NAMESPACE="$2";    shift 2 ;;
    --pg-service)    K8S_PG_SERVICE="$2";   shift 2 ;;
    --minio-service) K8S_MINIO_SERVICE="$2";shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Required command not found: docker" >&2
  exit 1
fi
if [[ "$MODE" == "port-forward" ]] && ! command -v kubectl >/dev/null 2>&1; then
  echo "Required command not found: kubectl (--port-forward 모드)" >&2
  exit 1
fi

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  echo "Migrations directory not found: $MIGRATIONS_DIR" >&2
  exit 1
fi

k8s_config_value() {
  kubectl get configmap "$1" -n "$K8S_NAMESPACE" \
    -o "go-template={{ index .data \"$2\" }}"
}

k8s_secret_value() {
  kubectl get secret "$1" -n "$K8S_NAMESPACE" \
    -o "go-template={{ index .data \"$2\" | base64decode }}"
}

# ─────────────────────────────────────────────────────────────
# 환경값 로드 (모드별)
# ─────────────────────────────────────────────────────────────
if [[ "$MODE" == "local" ]]; then
  echo "[qa-reset] 로컬 .env 에서 환경값을 불러옵니다: $ENV_FILE"
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Env file not found: $ENV_FILE" >&2
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  APP_MINIO_BUCKET="${APP_MINIO_BUCKET:-}"
  TARGET_LABEL="로컬 docker-compose"
else
  echo "[qa-reset] Kubernetes ConfigMap/Secret에서 환경값을 불러옵니다."
  POSTGRES_DB="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_DB)"
  POSTGRES_USER="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_USER)"
  POSTGRES_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" POSTGRES_PASSWORD)"
  SERVICE_APP_USER="$(k8s_secret_value "$K8S_PG_SECRET" SERVICE_APP_USER)"
  SERVICE_APP_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" SERVICE_APP_PASSWORD)"
  LAW_APP_USER="$(k8s_secret_value "$K8S_PG_SECRET" LAW_APP_USER)"
  LAW_APP_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" LAW_APP_PASSWORD)"
  DEV_ADMIN_USER="$(k8s_secret_value "$K8S_PG_SECRET" DEV_ADMIN_USER)"
  DEV_ADMIN_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" DEV_ADMIN_PASSWORD)"
  MINIO_ROOT_USER="$(k8s_secret_value "$K8S_MINIO_SECRET" MINIO_ROOT_USER)"
  MINIO_ROOT_PASSWORD="$(k8s_secret_value "$K8S_MINIO_SECRET" MINIO_ROOT_PASSWORD)"
  APP_MINIO_BUCKET="$(k8s_config_value "$K8S_MINIO_CONFIG" APP_MINIO_BUCKET)"
  TARGET_LABEL="K8s 개발서버 (${K8S_NAMESPACE})"
fi

required_vars=(
  POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD
  SERVICE_APP_USER SERVICE_APP_PASSWORD
  LAW_APP_USER LAW_APP_PASSWORD
  DEV_ADMIN_USER DEV_ADMIN_PASSWORD
  MINIO_ROOT_USER MINIO_ROOT_PASSWORD APP_MINIO_BUCKET
)
for name in "${required_vars[@]}"; do
  if [[ -z "${!name:-}" || "${!name}" == "<no value>" ]]; then
    echo "Missing value: $name (모드: $MODE)" >&2
    exit 1
  fi
done

echo ""
echo "[${TARGET_LABEL}] DB(service 스키마)와 MinIO projects/ 폴더를 초기화합니다."
echo "legal_rag 스키마·데이터는 보존됩니다 (DROP 안 함)."
echo "Flyway 히스토리는 전체 초기화되며, V2는 legal_rag 에 멱등 no-op 으로 재적용됩니다."
echo "MinIO 버킷의 projects/ 외 데이터는 보존됩니다."
echo "전체 마이그레이션(V1~V6)을 재적용합니다."
echo ""
if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -rp "계속하시겠습니까? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
  fi
fi

# ─────────────────────────────────────────────────────────────
# 접속 설정 (모드별)
# ─────────────────────────────────────────────────────────────
DOCKER_DB_HOST="host.docker.internal"
DOCKER_MINIO_HOST="host.docker.internal"

if [[ "$MODE" == "local" ]]; then
  POSTGRES_HOST=localhost
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"
  MINIO_PORT="${MINIO_API_PORT:-9000}"
else
  POSTGRES_HOST=localhost
  POSTGRES_PORT="$PG_LOCAL_PORT"
  MINIO_PORT="$MINIO_LOCAL_PORT"

  PG_PF_LOG="/tmp/skala-qa-reset-pg-pf.log"
  MINIO_PF_LOG="/tmp/skala-qa-reset-minio-pf.log"

  echo ""
  echo "[qa-reset] port-forward 시작..."
  kubectl port-forward "$K8S_PG_SERVICE" "${PG_LOCAL_PORT}:5432" -n "$K8S_NAMESPACE" \
    >"$PG_PF_LOG" 2>&1 &
  PG_PF_PID=$!

  kubectl port-forward "$K8S_MINIO_SERVICE" "${MINIO_LOCAL_PORT}:9000" -n "$K8S_NAMESPACE" \
    >"$MINIO_PF_LOG" 2>&1 &
  MINIO_PF_PID=$!

  cleanup() {
    kill "$PG_PF_PID" "$MINIO_PF_PID" >/dev/null 2>&1 || true
  }
  trap cleanup EXIT

  wait_for_port_forward() {
    local pid="$1"
    local log_file="$2"
    local label="$3"

    for _ in {1..20}; do
      if ! kill -0 "$pid" >/dev/null 2>&1; then
        echo "${label} port-forward failed:" >&2
        cat "$log_file" >&2
        exit 1
      fi
      if grep -q "Forwarding from" "$log_file"; then
        return
      fi
      sleep 0.5
    done

    echo "${label} port-forward timed out:" >&2
    cat "$log_file" >&2
    exit 1
  }

  wait_for_port_forward "$PG_PF_PID" "$PG_PF_LOG" PostgreSQL
  wait_for_port_forward "$MINIO_PF_PID" "$MINIO_PF_LOG" MinIO
fi

echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│              QA Reset — 초기화 시작                   │"
echo "├─────────────────────────────────────────────────────┤"
echo "│  대상  : ${TARGET_LABEL}"
echo "│  DB    : ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "│  MinIO : http://localhost:${MINIO_PORT}  bucket=${APP_MINIO_BUCKET}"
echo "│  초기화 : service 스키마 + MinIO projects/ (legal_rag·그 외 데이터 보존)"
echo "└─────────────────────────────────────────────────────┘"
echo ""

echo "[qa-reset] Step 1/3  service 스키마 드롭 + Flyway 히스토리 전체 초기화 (legal_rag 스키마는 보존)"

# 통합(V1~V18 → V1~V6) 이후 V2 체크섬이 바뀌고 V15 가 V2 로 흡수되었으므로
# 히스토리 행을 부분 보존하면 검증 에러가 난다. 전체 비우고 V1~V6 을 재적용한다.
# legal_rag 스키마는 DROP 하지 않으므로 데이터는 그대로 남고, V2 는 CREATE ... IF NOT EXISTS
# 라 기존 legal_rag 에 멱등 no-op 으로만 재적용된다 (법령 데이터·Qdrant 미영향).
docker run --rm --platform "$DOCKER_PLATFORM" "${DOCKER_HOST_GATEWAY_ARG[@]}" \
  -e PGPASSWORD="$POSTGRES_PASSWORD" \
  postgres:16-alpine \
  psql \
    -h "$DOCKER_DB_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -v ON_ERROR_STOP=1 \
    -c "DROP SCHEMA IF EXISTS service CASCADE;
        DELETE FROM public.flyway_schema_history;"

echo "[qa-reset] Step 2/3  Flyway migrate (V1~V6 재적용 — legal_rag 는 멱등 no-op)"

docker run --rm --platform "$DOCKER_PLATFORM" "${DOCKER_HOST_GATEWAY_ARG[@]}" \
  -v "$MIGRATIONS_DIR:/flyway/migrations:ro" \
  -e FLYWAY_URL="jdbc:postgresql://${DOCKER_DB_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" \
  -e FLYWAY_USER="$POSTGRES_USER" \
  -e FLYWAY_PASSWORD="$POSTGRES_PASSWORD" \
  -e FLYWAY_PLACEHOLDERS_SERVICE_APP_USER="$SERVICE_APP_USER" \
  -e FLYWAY_PLACEHOLDERS_SERVICE_APP_PASSWORD="$SERVICE_APP_PASSWORD" \
  -e FLYWAY_PLACEHOLDERS_LAW_APP_USER="$LAW_APP_USER" \
  -e FLYWAY_PLACEHOLDERS_LAW_APP_PASSWORD="$LAW_APP_PASSWORD" \
  -e FLYWAY_PLACEHOLDERS_DEV_ADMIN_USER="$DEV_ADMIN_USER" \
  -e FLYWAY_PLACEHOLDERS_DEV_ADMIN_PASSWORD="$DEV_ADMIN_PASSWORD" \
  -e FLYWAY_CONNECT_RETRIES=30 \
  -e FLYWAY_BASELINE_ON_MIGRATE=false \
  -e FLYWAY_OUT_OF_ORDER=true \
  -e FLYWAY_LOCATIONS=filesystem:/flyway/migrations \
  flyway/flyway:10-alpine migrate

echo "[qa-reset] Step 3/3  MinIO projects/ 폴더 초기화 (${APP_MINIO_BUCKET}/projects)"

docker run --rm --platform "$DOCKER_PLATFORM" "${DOCKER_HOST_GATEWAY_ARG[@]}" \
  -e MINIO_ENDPOINT="http://${DOCKER_MINIO_HOST}:${MINIO_PORT}" \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  -e APP_MINIO_BUCKET="$APP_MINIO_BUCKET" \
  --entrypoint /bin/sh \
  minio/mc \
  -c '
    mc alias set target "$MINIO_ENDPOINT" \
      "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" --api S3v4 &&
    mc mb --ignore-existing "target/$APP_MINIO_BUCKET" &&
    { mc rm -r --force "target/$APP_MINIO_BUCKET/projects/" || true; }
  '

echo ""
echo "[qa-reset] 완료 — 최신 Flyway 마이그레이션 상태로 초기화되었습니다."
