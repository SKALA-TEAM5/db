#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-"$ROOT_DIR/.env"}"
MIGRATIONS_DIR="$ROOT_DIR/db/migrations"

LOCAL=false
K8S_NAMESPACE="${K8S_NAMESPACE:-skala3-finalproj-class2-team5}"
K8S_PG_SERVICE="${K8S_PG_SERVICE:-svc/team5-postgres}"
K8S_MINIO_SERVICE="${K8S_MINIO_SERVICE:-svc/team5-minio}"
K8S_PG_CONFIG="${K8S_PG_CONFIG:-team5-postgres-config}"
K8S_PG_SECRET="${K8S_PG_SECRET:-team5-postgres-secret}"
K8S_BACKEND_SECRET="${K8S_BACKEND_SECRET:-team5-backend-secret}"
K8S_MINIO_CONFIG="${K8S_MINIO_CONFIG:-team5-minio-config}"
K8S_MINIO_SECRET="${K8S_MINIO_SECRET:-team5-minio-secret}"
PG_LOCAL_PORT="${PG_LOCAL_PORT:-5433}"
MINIO_LOCAL_PORT="${MINIO_LOCAL_PORT:-9002}"

usage() {
  cat <<'EOF'
Usage:
  db/scripts/qa-reset.sh           # K8s 개발서버 초기화
  db/scripts/qa-reset.sh --local   # docker-compose 로컬 환경 초기화

Options:
  --local               docker-compose 로컬 환경 모드
  --namespace NAME      K8s 네임스페이스. Default: skala3-finalproj-class2-team5
  --pg-service NAME     K8s Postgres 서비스. Default: svc/team5-postgres
  --minio-service NAME  K8s MinIO 서비스.   Default: svc/team5-minio
  --env-file PATH       로컬 모드 환경변수 파일. Default: .env
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)           LOCAL=true;               shift ;;
    --namespace)       K8S_NAMESPACE="$2";       shift 2 ;;
    --pg-service)      K8S_PG_SERVICE="$2";      shift 2 ;;
    --minio-service)   K8S_MINIO_SERVICE="$2";   shift 2 ;;
    --env-file)        ENV_FILE="$2";            shift 2 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$LOCAL" == true ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Env file not found: $ENV_FILE" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
else
  echo "[qa-reset] Kubernetes ConfigMap/Secret에서 환경값을 불러옵니다."

  k8s_config_value() {
    kubectl get configmap "$1" -n "$K8S_NAMESPACE" \
      -o "jsonpath={.data.$2}"
  }

  k8s_secret_value() {
    kubectl get secret "$1" -n "$K8S_NAMESPACE" \
      -o "go-template={{ index .data \"$2\" | base64decode }}"
  }

  POSTGRES_DB="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_DB)"
  POSTGRES_USER="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_USER)"
  POSTGRES_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" POSTGRES_PASSWORD)"
  SERVICE_APP_USER="$(k8s_secret_value "$K8S_BACKEND_SECRET" SERVICE_APP_USER)"
  SERVICE_APP_PASSWORD="$(k8s_secret_value "$K8S_BACKEND_SECRET" SERVICE_APP_PASSWORD)"
  LAW_APP_USER="$(k8s_secret_value "$K8S_PG_SECRET" LAW_APP_USER)"
  LAW_APP_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" LAW_APP_PASSWORD)"
  DEV_ADMIN_USER="$(k8s_secret_value "$K8S_PG_SECRET" DEV_ADMIN_USER)"
  DEV_ADMIN_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" DEV_ADMIN_PASSWORD)"
  MINIO_ROOT_USER="$(k8s_secret_value "$K8S_MINIO_SECRET" MINIO_ROOT_USER)"
  MINIO_ROOT_PASSWORD="$(k8s_secret_value "$K8S_MINIO_SECRET" MINIO_ROOT_PASSWORD)"
  APP_MINIO_BUCKET="$(k8s_config_value "$K8S_MINIO_CONFIG" APP_MINIO_BUCKET)"
fi

required_vars=(
  POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD
  SERVICE_APP_USER SERVICE_APP_PASSWORD
  LAW_APP_USER LAW_APP_PASSWORD
  DEV_ADMIN_USER DEV_ADMIN_PASSWORD
  MINIO_ROOT_USER MINIO_ROOT_PASSWORD APP_MINIO_BUCKET
)
for name in "${required_vars[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env value: $name" >&2
    exit 1
  fi
done

DOCKER_PLATFORM="${FLYWAY_PLATFORM:-linux/amd64}"
DOCKER_HOST_GATEWAY_ARG=(--add-host=host.docker.internal:host-gateway)

# ── 확인 프롬프트 ──────────────────────────────────────────────────────────────

TARGET=$([[ "$LOCAL" == true ]] && echo "로컬 docker-compose" || echo "K8s 개발서버")
echo ""
echo "[${TARGET}] DB(service 스키마)와 MinIO projects/ 폴더를 V6 목업 상태로 초기화합니다."
echo "legal_rag 스키마는 보존됩니다."
echo "MinIO 버킷의 projects/ 외 데이터는 보존됩니다."
echo ""
read -rp "계속하시겠습니까? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "취소되었습니다."
  exit 0
fi

# ── 모드별 접속 정보 설정 ─────────────────────────────────────────────────────

if [[ "$LOCAL" == false ]]; then
  POSTGRES_HOST=localhost
  POSTGRES_PORT="$PG_LOCAL_PORT"
  MINIO_PORT="$MINIO_LOCAL_PORT"

  echo ""
  echo "[qa-reset] port-forward 시작..."
  kubectl port-forward "$K8S_PG_SERVICE" "${PG_LOCAL_PORT}:5432" -n "$K8S_NAMESPACE" \
    >/tmp/skala-qa-reset-pg-pf.log 2>&1 &
  PG_PF_PID=$!

  kubectl port-forward "$K8S_MINIO_SERVICE" "${MINIO_LOCAL_PORT}:9000" -n "$K8S_NAMESPACE" \
    >/tmp/skala-qa-reset-minio-pf.log 2>&1 &
  MINIO_PF_PID=$!

  trap 'kill "$PG_PF_PID" "$MINIO_PF_PID" >/dev/null 2>&1 || true' EXIT
  sleep 3

  DOCKER_DB_HOST="host.docker.internal"
  DOCKER_MINIO_HOST="host.docker.internal"

else
  POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"
  MINIO_PORT="${MINIO_API_PORT:-9000}"

  if [[ "$POSTGRES_HOST" == "localhost" || "$POSTGRES_HOST" == "127.0.0.1" ]]; then
    DOCKER_DB_HOST="host.docker.internal"
  else
    DOCKER_DB_HOST="$POSTGRES_HOST"
  fi
  DOCKER_MINIO_HOST="host.docker.internal"
fi

echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│              QA Reset — 초기화 시작                   │"
echo "├─────────────────────────────────────────────────────┤"
echo "│  대상  : ${TARGET}"
echo "│  DB    : ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "│  MinIO : http://localhost:${MINIO_PORT}  bucket=${APP_MINIO_BUCKET}"
echo "│  초기화 : service 스키마 + MinIO projects/ (그 외 데이터 보존)"
echo "└─────────────────────────────────────────────────────┘"
echo ""

# ── Step 1. service 스키마 드롭 + Flyway 히스토리 정리 ──────────────────────

echo "[qa-reset] Step 1/3  service 스키마 드롭 + flyway 히스토리 정리"

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
        DELETE FROM public.flyway_schema_history WHERE version IN ('1','3','4','5','6');"

# ── Step 2. Flyway migrate (V1, V3~V6 재적용 / V2 skip) ──────────────────────

echo "[qa-reset] Step 2/3  Flyway migrate (V1, V3~V6)"

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

# ── Step 3. MinIO projects/ 폴더 초기화 ─────────────────────────────────────

echo "[qa-reset] Step 3/3  MinIO projects/ 폴더 초기화 (${APP_MINIO_BUCKET}/projects)"

docker run --rm --platform "$DOCKER_PLATFORM" "${DOCKER_HOST_GATEWAY_ARG[@]}" \
  --entrypoint /bin/sh \
  minio/mc \
  -c "
    mc alias set target http://${DOCKER_MINIO_HOST}:${MINIO_PORT} \
      '${MINIO_ROOT_USER}' '${MINIO_ROOT_PASSWORD}' --api S3v4 &&
    mc mb --ignore-existing target/${APP_MINIO_BUCKET} &&
    { mc rm -r --force target/${APP_MINIO_BUCKET}/projects/ || true; }
  "

echo ""
echo "[qa-reset] 완료 — V6 목업 상태로 초기화되었습니다."
