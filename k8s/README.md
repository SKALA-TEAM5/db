# Team5 DB on Kubernetes

This directory deploys a team-owned PostgreSQL pod inside:

```text
skala3-finalproj-class2-team5
```

It does not create a namespace, LoadBalancer, ALB, node group, or Terraform-managed resource.

## Components

- `team5-postgres` StatefulSet: PostgreSQL 16
- `team5-postgres` Service: internal ClusterIP
- `team5-postgres-config` ConfigMap: non-secret DB settings
- `team5-postgres-secret` Secret: passwords and Flyway placeholders
- `team5-db-migrations` ConfigMap: generated from `../migrations`
- `team5-db-flyway-migrate` Job: applies Flyway migrations

## Management policy

- ArgoCD manages PostgreSQL resources in `k8s/postgres`.
- GitHub Actions runs Flyway migrations from `k8s/jobs/flyway-job.yaml`.
- Real Secrets are created directly in Kubernetes and are not committed.

## 1. Set namespace

```bash
kubectl config set-context --current --namespace=skala3-finalproj-class2-team5
```

## 2. Create DB Secret

Do not commit real passwords. Create the secret from literals:

```bash
kubectl create secret generic team5-postgres-secret \
  --from-literal=POSTGRES_PASSWORD='<postgres-admin-password>' \
  --from-literal=SERVICE_APP_USER='safety_service_app' \
  --from-literal=SERVICE_APP_PASSWORD='<service-app-password>' \
  --from-literal=LAW_APP_USER='safety_law_app' \
  --from-literal=LAW_APP_PASSWORD='<law-app-password>' \
  --from-literal=DEV_ADMIN_USER='dev_admin' \
  --from-literal=DEV_ADMIN_PASSWORD='<dev-admin-password>' \
  --dry-run=client \
  -o yaml | kubectl apply -f -
```

## 3. Deploy PostgreSQL

```bash
kubectl apply -k k8s/postgres
kubectl rollout status statefulset/team5-postgres
```

For ArgoCD, set the application path to:

```text
k8s/postgres
```

## 4. Create migrations ConfigMap

Apply all migrations, including mock data:

```bash
kubectl create configmap team5-db-migrations \
  --from-file=./migrations \
  --dry-run=client \
  -o yaml | kubectl apply -f -
```

If cluster DB should not include mock data, create the ConfigMap with only `V1` through `V5`:

```bash
kubectl create configmap team5-db-migrations \
  --from-file=./migrations/V1__schema_service.sql \
  --from-file=./migrations/V2__schema_legal_rag.sql \
  --from-file=./migrations/V3__roles_and_grants.sql \
  --from-file=./migrations/V4__seed_codes.sql \
  --from-file=./migrations/V5__views.sql \
  --dry-run=client \
  -o yaml | kubectl apply -f -
```

## 5. Run Flyway

```bash
kubectl delete job team5-db-flyway-migrate --ignore-not-found=true
kubectl apply -f k8s/jobs/flyway-job.yaml
kubectl wait --for=condition=complete job/team5-db-flyway-migrate --timeout=180s
kubectl logs job/team5-db-flyway-migrate
```

## 6. Connect from another pod

Internal host:

```text
team5-postgres.skala3-finalproj-class2-team5.svc.cluster.local
```

Same namespace short host:

```text
team5-postgres
```

Example psql test:

```bash
export PG_PASSWORD="$(kubectl get secret team5-postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode)"

kubectl run psql-client \
  --rm -it \
  --restart=Never \
  --image=postgres:16-alpine \
  --env PGPASSWORD="$PG_PASSWORD" \
  -- psql -h team5-postgres -U safety_user -d safety -c '\dt service.*'
```
