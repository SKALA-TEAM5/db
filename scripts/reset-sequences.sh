#!/usr/bin/env bash
set -euo pipefail

# service 스키마의 모든 id 시퀀스를 현재 데이터의 MAX(id)+1 에 맞춰 정렬한다.
# 부하테스트로 부풀려진 시퀀스 값을 되돌리는 용도. 데이터는 건드리지 않는다.
# qa-reset.sh 와 동일하게 K8s Secret/ConfigMap 에서만 자격증명을 읽는다.

K8S_NAMESPACE="${K8S_NAMESPACE:-skala3-finalproj-class2-team5}"
K8S_PG_SERVICE="${K8S_PG_SERVICE:-svc/team5-postgres}"
K8S_PG_CONFIG="${K8S_PG_CONFIG:-team5-postgres-config}"
K8S_PG_SECRET="${K8S_PG_SECRET:-team5-postgres-secret}"
PG_LOCAL_PORT="${PG_LOCAL_PORT:-5433}"
DOCKER_PLATFORM="${FLYWAY_PLATFORM:-linux/amd64}"
DOCKER_HOST_GATEWAY_ARG=(--add-host=host.docker.internal:host-gateway)
TARGET_SCHEMA="${TARGET_SCHEMA:-service}"

usage() {
  cat <<'EOF'
Usage:
  scripts/reset-sequences.sh

Options:
  --namespace NAME   K8s 네임스페이스. Default: skala3-finalproj-class2-team5
  --pg-service NAME  K8s Postgres 서비스. Default: svc/team5-postgres
  --schema NAME      대상 스키마. Default: service
  -h, --help

service 스키마 각 테이블의 id 시퀀스를 MAX(id)+1 로 재설정합니다.
데이터는 변경하지 않으며, 환경값은 K8s ConfigMap/Secret 에서만 읽습니다.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)  K8S_NAMESPACE="$2";  shift 2 ;;
    --pg-service) K8S_PG_SERVICE="$2"; shift 2 ;;
    --schema)     TARGET_SCHEMA="$2";  shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for command in kubectl docker; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

k8s_config_value() {
  kubectl get configmap "$1" -n "$K8S_NAMESPACE" \
    -o "go-template={{ index .data \"$2\" }}"
}

k8s_secret_value() {
  kubectl get secret "$1" -n "$K8S_NAMESPACE" \
    -o "go-template={{ index .data \"$2\" | base64decode }}"
}

echo "[reset-sequences] Kubernetes ConfigMap/Secret 에서 환경값을 불러옵니다."

POSTGRES_DB="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_DB)"
POSTGRES_USER="$(k8s_config_value "$K8S_PG_CONFIG" POSTGRES_USER)"
POSTGRES_PASSWORD="$(k8s_secret_value "$K8S_PG_SECRET" POSTGRES_PASSWORD)"

for name in POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD; do
  if [[ -z "${!name:-}" || "${!name}" == "<no value>" ]]; then
    echo "Missing Kubernetes value: $name" >&2
    exit 1
  fi
done

echo ""
echo "[K8s 개발서버] ${TARGET_SCHEMA} 스키마의 id 시퀀스를 MAX(id)+1 로 정렬합니다."
echo "데이터는 변경하지 않습니다. (시퀀스 카운터만 조정)"
echo ""
read -rp "계속하시겠습니까? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "취소되었습니다."
  exit 0
fi

POSTGRES_PORT="$PG_LOCAL_PORT"
DOCKER_DB_HOST="host.docker.internal"
PG_PF_LOG="/tmp/skala-reset-seq-pg-pf.log"

echo ""
echo "[reset-sequences] port-forward 시작..."
kubectl port-forward "$K8S_PG_SERVICE" "${PG_LOCAL_PORT}:5432" -n "$K8S_NAMESPACE" \
  >"$PG_PF_LOG" 2>&1 &
PG_PF_PID=$!

cleanup() {
  kill "$PG_PF_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in {1..20}; do
  if ! kill -0 "$PG_PF_PID" >/dev/null 2>&1; then
    echo "PostgreSQL port-forward failed:" >&2
    cat "$PG_PF_LOG" >&2
    exit 1
  fi
  if grep -q "Forwarding from" "$PG_PF_LOG"; then
    break
  fi
  sleep 0.5
done

echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│         Reset Sequences — 시퀀스 정렬 시작           │"
echo "├─────────────────────────────────────────────────────┤"
echo "│  대상   : K8s 개발서버 (${K8S_NAMESPACE})"
echo "│  DB     : ${POSTGRES_USER}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}"
echo "│  스키마 : ${TARGET_SCHEMA}"
echo "└─────────────────────────────────────────────────────┘"
echo ""

run_psql() {
  docker run --rm -i --platform "$DOCKER_PLATFORM" "${DOCKER_HOST_GATEWAY_ARG[@]}" \
    -e PGPASSWORD="$POSTGRES_PASSWORD" \
    postgres:16-alpine \
    psql \
      -h "$DOCKER_DB_HOST" \
      -p "$POSTGRES_PORT" \
      -U "$POSTGRES_USER" \
      -d "$POSTGRES_DB" \
      -v ON_ERROR_STOP=1 \
      -v schema="$TARGET_SCHEMA" \
      "$@"
}

echo "[reset-sequences] 시퀀스 재설정 중..."
run_psql <<'SQL'
-- psql 변수는 달러쿼트 안에서 치환되지 않으므로 세션 설정으로 전달한다.
SELECT set_config('reset_seq.schema', :'schema', false);
DO $$
DECLARE
  target_schema text := current_setting('reset_seq.schema');
  r record;
  seq text;
BEGIN
  FOR r IN
    SELECT c.relname AS tbl
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
                       AND a.attname = 'id'
                       AND a.attnum > 0
                       AND NOT a.attisdropped
    WHERE n.nspname = target_schema AND c.relkind = 'r'
  LOOP
    seq := pg_get_serial_sequence(format('%I.%I', target_schema, r.tbl), 'id');
    IF seq IS NOT NULL THEN
      EXECUTE format(
        'SELECT setval(%L, COALESCE((SELECT MAX(id) FROM %I.%I), 1))',
        seq, target_schema, r.tbl
      );
      RAISE NOTICE 'reset %.% -> %', target_schema, r.tbl, seq;
    END IF;
  END LOOP;
END $$;
SQL

echo ""
echo "[reset-sequences] 결과 확인:"
run_psql -P pager=off -c \
  "SELECT sequencename, last_value
   FROM pg_sequences
   WHERE schemaname = '${TARGET_SCHEMA}'
   ORDER BY sequencename;"

echo ""
echo "[reset-sequences] 완료 — ${TARGET_SCHEMA} 스키마 시퀀스가 MAX(id)+1 로 정렬되었습니다."
