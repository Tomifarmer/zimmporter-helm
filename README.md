# Zimmporter Helm Chart

Deploys the Zimmporter stack on Kubernetes:

| Component | Description |
|---|---|
| **api** | FastAPI application — search, download orchestration, job management |
| **worker** | Celery worker — executes album/playlist downloads via yt-dlp |
| **frontend** | Next.js UI — search, job status, download management |
| **valkey** | Redis-compatible KV store — Celery broker & result backend |
| **mariadb** | SQL database — job and song metadata |

S3-compatible object storage is expected to be pre-provisioned
and configured via values — it is **not** deployed by this chart.

---

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- A default `StorageClass` (or set one explicitly for Valkey / MariaDB)
- An S3-compatible instance reachable from the cluster

---

## Quick start

```bash
# Add required values and install
helm install my-release ./ \
  --set images.api.repository=myregistry/zimmporter-api \
  --set images.frontend.repository=myregistry/zimmporter-front \
  --set s3.endpoint=s3.example.com:9000 \
  --set s3.accessKeyId=myAccessKey \
  --set s3.secretAccessKey=mySecretKey \
  --set s3.bucket=myBucket \
  --set database.rootPassword=strongRootPw \
  --set database.password=strongUserPw
```

After a few minutes, check that all pods are running:

```bash
kubectl get pods -l app.kubernetes.io/instance=my-release
```

Verify the API health endpoint:

```bash
kubectl port-forward svc/my-release-zimmporter-api 8000:8000
curl http://localhost:8000/health
```

---

## Configuration

### Global

| Name | Default | Description |
|---|---|---|
| `nameOverride` | `""` | Overrides the `app.kubernetes.io/name` label |
| `fullnameOverride` | `""` | Overrides the full resource name prefix |
| `global.extraEnv` | `[]` | Additional env vars injected into **all** pods (see [extraEnv docs](#extraenv)) |

### Images

| Name | Default | Description |
|---|---|---|
| `images.api.repository` | `""` | Docker image for the API + worker (same image) |
| `images.api.tag` | `"latest"` | Image tag |
| `images.api.pullPolicy` | `IfNotPresent` | Image pull policy |
| `images.frontend.repository` | `""` | Docker image for the Next.js frontend |
| `images.frontend.tag` | `"latest"` | Image tag |
| `images.frontend.pullPolicy` | `IfNotPresent` | Image pull policy |

### Ingress

Both ingresses are **disabled by default**. Enable them per-component.

| Name | Default | Description |
|---|---|---|
| `ingress.api.enabled` | `false` | Enable ingress for the API |
| `ingress.api.host` | `api.example.com` | API hostname |
| `ingress.api.className` | `""` | Ingress class name |
| `ingress.api.annotations` | `{}` | Ingress annotations |
| `ingress.api.tls` | `[]` | TLS configuration |
| `ingress.frontend.enabled` | `false` | Enable ingress for the frontend |
| `ingress.frontend.host` | `app.example.com` | Frontend hostname |
| `ingress.frontend.className` | `""` | Ingress class name |
| `ingress.frontend.annotations` | `{}` | Ingress annotations |
| `ingress.frontend.tls` | `[]` | TLS configuration |

### API

| Name | Default | Description |
|---|---|---|
| `api.replicas` | `1` | Number of API pods |
| `api.podSecurityContext` | `{fsGroup: 51000}` | Pod-level security context |
| `api.resources` | `{}` | Container resource limits/requests |
| `api.nodeSelector` | `{}` | Node selector |
| `api.tolerations` | `[]` | Pod tolerations |
| `api.affinity` | `{}` | Pod affinity/anti-affinity |
| `api.env.USE_SIMPLE_AUTH` | `"false"` | Enable API key authentication |
| `api.env.USE_SOCIAL_LOGIN` | `"false"` | Enable social login (OIDC/GitHub) Bearer token authentication |
| `api.env.CORS_ALLOWED_ORIGINS` | `"*"` | CORS allowed origins |
| `api.extraEnv` | `[]` | Additional env vars for the API pod (see [extraEnv docs](#extraenv)) |

### Worker

| Name | Default | Description |
|---|---|---|
| `worker.replicas` | `1` | Number of worker pods |
| `worker.podSecurityContext` | `{fsGroup: 51000}` | Pod-level security context |
| `worker.resources` | `{}` | Container resource limits/requests |
| `worker.concurrency` | `4` | Celery worker concurrency |
| `worker.pool` | `"prefork"` | Celery worker pool type |
| `worker.nodeSelector` | `{}` | Node selector |
| `worker.tolerations` | `[]` | Pod tolerations |
| `worker.affinity` | `{}` | Pod affinity/anti-affinity |
| `worker.extraEnv` | `[]` | Additional env vars for the worker pod (see [extraEnv docs](#extraenv)) |


### Frontend

| Name | Default | Description |
|---|---|---|
| `frontend.replicas` | `1` | Number of frontend pods |
| `frontend.resources` | `{}` | Container resource limits/requests |
| `frontend.nodeSelector` | `{}` | Node selector |
| `frontend.tolerations` | `[]` | Pod tolerations |
| `frontend.affinity` | `{}` | Pod affinity/anti-affinity |
| `frontend.env.NEXT_PUBLIC_API_URL` | `"http://api:8000"` | Backend API URL (in-cluster) |
| `frontend.env.USE_SOCIAL_LOGIN` | `"false"` | Enable social login (OIDC/GitHub) authentication |
| `frontend.env.USE_SIMPLE_AUTH` | `"false"` | Enable API key authentication |
| `frontend.env.OIDC_NAME` | `"OIDC"` | OIDC provider display name |
| `frontend.env.OIDC_ISSUER_URL` | `""` | OIDC issuer URL |
| `frontend.env.OIDC_CLIENT_ID` | `""` | OIDC client ID |
| `frontend.extraEnv` | `[]` | Additional env vars for the frontend pod (see [extraEnv docs](#extraenv)) |

### S3 (external)

| Name | Default | Description |
|---|---|---|
| `s3.endpoint` | `""` | S3 endpoint host:port |
| `s3.accessKeyId` | `""` | S3 access key ID |
| `s3.secretAccessKey` | `""` | S3 secret access key |
| `s3.bucket` | `""` | S3 bucket name |
| `s3.useSSL` | `false` | Use HTTPS for S3 connections |

### MariaDB

| Name | Default | Description |
|---|---|---|
| `mariadb.image` | `"mariadb:11"` | MariaDB image (ignored when external) |
| `mariadb.external.enabled` | `false` | Use an external MariaDB instance |
| `mariadb.external.host` | `""` | External MariaDB hostname |
| `mariadb.external.port` | `3306` | External MariaDB port |
| `mariadb.storageClass` | `""` | PVC storage class (ignored when external) |
| `mariadb.persistence.size` | `"10Gi"` | PVC size (ignored when external) |
| `mariadb.resources` | `{}` | Container resource limits/requests |

### Valkey

| Name | Default | Description |
|---|---|---|
| `valkey.image` | `"valkey/valkey:latest"` | Valkey image (ignored when external) |
| `valkey.external.enabled` | `false` | Use an external Valkey/Redis instance |
| `valkey.external.address` | `""` | External Valkey hostname |
| `valkey.external.port` | `6379` | External Valkey port |
| `valkey.storageClass` | `""` | PVC storage class (ignored when external) |
| `valkey.persistence.size` | `"1Gi"` | PVC size (ignored when external) |
| `valkey.resources` | `{}` | Container resource limits/requests |

### Database

| Name | Default | Description |
|---|---|---|
| `database.host` | `""` | DB hostname (auto-resolves: external → `mariadb.external.host` → `"mariadb"`) |
| `database.port` | `""` | DB port (auto-resolves: external → `mariadb.external.port` → `"3306"`) |
| `database.rootPassword` | `""` | MariaDB root password (ignored when `existingSecret` is set) |
| `database.user` | `"zimmporter"` | Application database user (ignored when `existingSecret` is set) |
| `database.password` | `""` | Application database password (ignored when `existingSecret` is set) |
| `database.name` | `"zimmporter"` | Database name (ignored when `existingSecret` is set) |
| `database.existingSecret` | `""` | Name of an existing Secret (skips chart-generated database secret) |
| `database.existingSecretKeyMapping.rootPassword` | `"root-password"` | Key for root password in the existing secret |
| `database.existingSecretKeyMapping.user` | `"user"` | Key for database user in the existing secret |
| `database.existingSecretKeyMapping.password` | `"password"` | Key for database password in the existing secret |
| `database.existingSecretKeyMapping.name` | `"name"` | Key for database name in the existing secret |

### Authentication

| Name | Default | Description |
|---|---|---|
| `auth.apiKey` | `""` | API key for `X-API-Key` header (ignored when `existingSecret` is set) |
| `auth.oidcClientSecret` | `""` | OIDC client secret for the frontend |
| `auth.authSecret` | `"dev-secret-change-in-production"` | NextAuth encryption secret (generate with `openssl rand -base64 32`) |
| `auth.existingSecret` | `""` | Name of an existing Secret (skips chart-generated api-auth secret) |
| `auth.existingSecretKey` | `"api-key"` | Key for the API key value within the existing secret |

### Celery

| Name | Default | Description |
|---|---|---|
| `celery.broker` | `""` | Broker URL (auto-derived from in-cluster Valkey when empty) |
| `celery.backend` | `""` | Result backend URL (auto-derived from in-cluster Valkey when empty) |

### Private CA

| Name | Default | Description |
|---|---|---|
| `caCert.enabled` | `false` | Mount a custom CA certificate |
| `caCert.path` | `"/etc/ssl/certs/ca.crt"` | Mount path inside the container |
| `caCert.existingSecret` | `""` | Name of an existing Secret (must contain key named `ca.crt`) |
| `caCert.key` | `"ca.crt"` | Key within the secret |

### extraEnv

Each component (`api`, `worker`, `frontend`) accepts an `extraEnv` list of
Kubernetes env var entries. The `global.extraEnv` list is merged into
**all** pods before the component-specific list, so component vars take
precedence over global ones.

| Name | Default | Description |
|---|---|---|
| `global.extraEnv` | `[]` | Applied to every pod |
| `api.extraEnv` | `[]` | Applied to the API pod only |
| `worker.extraEnv` | `[]` | Applied to the worker pod only |
| `frontend.extraEnv` | `[]` | Applied to the frontend pod only |

Each entry follows the standard Kubernetes `env` schema:

```yaml
extraEnv:
  - name: MY_VAR
    value: "plain value"
  - name: SECRET_VAR
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: my-key
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
```

---

## Resources created

| Kind | Name pattern | Notes |
|---|---|---|
| `Deployment` | `{release}-zimmporter-api` | FastAPI, `/health` probe |
| `Deployment` | `{release}-zimmporter-worker` | Celery, `emptyDir` at `/data/zimmer/importer`, `inspect ping` probe |
| `Deployment` | `{release}-zimmporter-frontend` | Next.js, HTTP probe on `/` |
| `StatefulSet` (conditional) | `{release}-zimmporter-valkey` | Skipped when `valkey.external.enabled=true` |
| `StatefulSet` (conditional) | `{release}-zimmporter-mariadb` | Skipped when `mariadb.external.enabled=true` |
| `Service` (×3–5) | ClusterIP for each component | Valkey + MariaDB skipped when external |
| `Ingress` (×2) | Only when enabled | Separate hostnames for API and frontend |
| `ConfigMap` (×3) | `*-api-config`, `*-worker-config`, `*-frontend-config` | Non-sensitive environment variables |
| `Secret` (conditional) | `*-database` | Skipped when `database.existingSecret` is set |
| `Secret` | `*-s3` | Always created |
| `Secret` (conditional) | `*-api-auth` | Skipped when `auth.existingSecret` is set |

---

## Health checks

- **API**: `GET /health` returns per-component status (Valkey, Celery, MariaDB).
- **Worker**: Liveness probe runs `celery -A tasks.celery_app inspect ping --timeout=5`.
- **Frontend**: Liveness and readiness probes hit `/` on port 3000.

---

## Example: enable ingresses with TLS

```yaml
ingress:
  api:
    enabled: true
    host: api.zimmporter.example
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - hosts:
          - api.zimmporter.example
        secretName: api-tls
  frontend:
    enabled: true
    host: app.zimmporter.example
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - hosts:
          - app.zimmporter.example
        secretName: frontend-tls
```

---

---

## Example: use external Valkey and MariaDB

Skip deploying Valkey and MariaDB in-cluster and point to existing instances:

```yaml
valkey:
  external:
    enabled: true
    address: redis.external.svc.cluster.local
    port: 6379

mariadb:
  external:
    enabled: true
    host: mariadb.external.svc.cluster.local
    port: 3306
```

The chart will:
- Skip the `StatefulSet` and `Service` for both components
- Derive `CELERY_BROKER` / `CELERY_BACKEND` from `valkey.external.address`
- Derive `DB_HOST` / `DB_PORT` from `mariadb.external.host`

You can also override these explicitly via `database.host`/`port` or
`celery.broker`/`backend` if you need a custom URL scheme.

---

## Example: use a custom StorageClass

```yaml
valkey:
  storageClass: longhorn
  persistence:
    size: 2Gi

mariadb:
  storageClass: longhorn
  persistence:
    size: 20Gi
```

---

## Example: use existing secrets

Skip the chart-generated secrets and reference your own (managed by
SealedSecrets, External Secrets Operator, SOPS, etc.):

```yaml
database:
  existingSecret: my-db-creds
  # If your secret uses different key names:
  # existingSecretKeyMapping:
  #   rootPassword: MYSQL_ROOT_PASSWORD
  #   user: DB_USER
  #   password: DB_PASSWORD
  #   name: DB_NAME

auth:
  existingSecret: my-api-auth
  existingSecretKey: api-key
```

The expected keys in your existing secret (defaults):

| Secret | Required keys |
|---|---|
| `my-db-creds` | `root-password`, `user`, `password`, `name` |
| `my-api-auth` | `api-key` |

When `database.existingSecret` or `auth.existingSecret` is set, the
chart skips creating its own Secret and uses yours directly.

---

## Uninstall

```bash
helm uninstall my-release
```

Persistent volume claims for Valkey and MariaDB are **not** deleted by
default. Remove them manually if needed:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=my-release
```
