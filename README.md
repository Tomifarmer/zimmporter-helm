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
| `api.resources` | `{requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 500m, memory: 512Mi}}` | Container resource limits/requests |
| `api.nodeSelector` | `{}` | Node selector |
| `api.tolerations` | `[]` | Pod tolerations |
| `api.affinity` | `{}` | Pod affinity/anti-affinity |
| `api.env.USE_SIMPLE_AUTH` | `"false"` | Enable API key authentication |
| `api.env.USE_SOCIAL_LOGIN` | `"false"` | Enable social login (OIDC/GitHub) Bearer token authentication |
| `api.env.CORS_ALLOWED_ORIGINS` | `"*"` | CORS allowed origins |
| `api.env.OIDC_ISSUER_URL` | `""` | OIDC issuer URL (moved to a secret when `auth.oidcClientId` is set) |
| `api.extraEnv` | `[]` | Additional env vars for the API pod (see [extraEnv docs](#extraenv)) |
| `api.extraVolumes` | `[]` | Additional pod-level volumes (see [extraVolumes docs](#extravolumes--extravolumemounts)) |
| `api.extraVolumeMounts` | `[]` | Additional container volume mounts (see [extraVolumes docs](#extravolumes--extravolumemounts)) |

### Worker

| Name | Default | Description |
|---|---|---|
| `worker.replicas` | `1` | Number of worker pods |
| `worker.podSecurityContext` | `{fsGroup: 51000}` | Pod-level security context |
| `worker.resources` | `{requests: {cpu: 200m, memory: 256Mi}, limits: {cpu: 1, memory: 1Gi}}` | Container resource limits/requests |
| `worker.concurrency` | `4` | Celery worker concurrency |
| `worker.pool` | `"prefork"` | Celery worker pool type |
| `worker.nodeSelector` | `{}` | Node selector |
| `worker.tolerations` | `[]` | Pod tolerations |
| `worker.affinity` | `{}` | Pod affinity/anti-affinity |
| `worker.extraEnv` | `[]` | Additional env vars for the worker pod (see [extraEnv docs](#extraenv)) |
| `worker.extraVolumes` | `[]` | Additional pod-level volumes (see [extraVolumes docs](#extravolumes--extravolumemounts)) |
| `worker.extraVolumeMounts` | `[]` | Additional container volume mounts (see [extraVolumes docs](#extravolumes--extravolumemounts)) |


### Frontend

| Name | Default | Description |
|---|---|---|
| `frontend.replicas` | `1` | Number of frontend pods |
| `frontend.resources` | `{requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 500m, memory: 512Mi}}` | Container resource limits/requests |
| `frontend.nodeSelector` | `{}` | Node selector |
| `frontend.tolerations` | `[]` | Pod tolerations |
| `frontend.affinity` | `{}` | Pod affinity/anti-affinity |
| `frontend.env.API_URL` | `""` | Backend API URL (auto-derived from in-cluster service when empty; set to full `https://` URL when using TLS ingress) |
| `frontend.env.USE_SOCIAL_LOGIN` | `"false"` | Enable social login (OIDC/GitHub) authentication |
| `frontend.env.USE_SIMPLE_AUTH` | `"false"` | Enable API key authentication |
| `frontend.env.OIDC_NAME` | `"OIDC"` | OIDC provider display name |
| `frontend.env.OIDC_ISSUER_URL` | `""` | OIDC issuer URL |
| `frontend.extraEnv` | `[]` | Additional env vars for the frontend pod (see [extraEnv docs](#extraenv)) |
| `frontend.extraVolumes` | `[]` | Additional pod-level volumes (see [extraVolumes docs](#extravolumes--extravolumemounts)) |
| `frontend.extraVolumeMounts` | `[]` | Additional container volume mounts (see [extraVolumes docs](#extravolumes--extravolumemounts)) |

### S3 (external)

| Name | Default | Description |
|---|---|---|---|
| `s3.endpoint` | `""` | S3 endpoint host:port |
| `s3.accessKey` | `""` | S3 access key (ignored when `existingSecret` is set) |
| `s3.secretKey` | `""` | S3 secret key (ignored when `existingSecret` is set) |
| `s3.bucket` | `""` | S3 bucket name |
| `s3.useSSL` | `false` | Use HTTPS for S3 connections |
| `s3.existingSecret` | `""` | Name of an existing Secret (skips chart-generated s3 secret) |
| `s3.existingSecretKeyMapping.accessKey` | `"access-key"` | Key for S3 access key in the existing secret |
| `s3.existingSecretKeyMapping.secretKey` | `"secret-key"` | Key for S3 secret key in the existing secret |

### MariaDB

| Name | Default | Description |
|---|---|---|
| `mariadb.image` | `"mariadb:11"` | MariaDB image (ignored when external) |
| `mariadb.external.enabled` | `false` | Use an external MariaDB instance |
| `mariadb.external.host` | `""` | External MariaDB hostname |
| `mariadb.external.port` | `3306` | External MariaDB port |
| `mariadb.storageClass` | `""` | PVC storage class (ignored when external) |
| `mariadb.persistence.size` | `"10Gi"` | PVC size (ignored when external) |
| `mariadb.podSecurityContext` | `{runAsNonRoot: true, fsGroup: 999}` | Pod-level security context |
| `mariadb.resources` | `{requests: {cpu: 200m, memory: 512Mi}, limits: {cpu: 1, memory: 1Gi}}` | Container resource limits/requests |

### Valkey

| Name | Default | Description |
|---|---|---|
| `valkey.podSecurityContext` | `{runAsNonRoot: true, fsGroup: 999}` | Pod-level security context |
| `valkey.image` | `"valkey/valkey:latest"` | Valkey image (ignored when external) |
| `valkey.external.enabled` | `false` | Use an external Valkey/Redis instance |
| `valkey.external.address` | `""` | External Valkey hostname |
| `valkey.external.port` | `6379` | External Valkey port |
| `valkey.storageClass` | `""` | PVC storage class (ignored when external) |
| `valkey.persistence.size` | `"1Gi"` | PVC size (ignored when external) |
| `valkey.resources` | `{requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 500m, memory: 512Mi}}` | Container resource limits/requests |

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
| `auth.apiKey` | `""` | API key for `X-API-Key` header |
| `auth.oidcClientId` | `""` | OIDC client ID (injected into API + frontend; when set, overrides ConfigMap value via the oidc secret) |
| `auth.oidcClientSecret` | `""` | OIDC client secret for the frontend (injected only when `USE_SOCIAL_LOGIN=true`) |
| `auth.githubClientId` | `""` | GitHub client ID (injected into API + frontend; when set, overrides ConfigMap value via the github secret) |
| `auth.githubClientSecret` | `""` | GitHub OAuth client secret for the frontend (injected only when `USE_SOCIAL_LOGIN=true`) |
| `auth.authSecret` | `"dev-secret-change-in-production"` | NextAuth encryption key — signs JWTs and encrypts session cookies. Generate one with `openssl rand -base64 32` |
| `auth.apiKeyExistingSecret` | `""` | Name of an existing Secret containing the API key (overrides the chart-generated auth secret) |
| `auth.apiKeyExistingSecretKey` | `"api-key"` | Key for the API key within `apiKeyExistingSecret` |
| `auth.oidc.existingSecret` | `""` | Name of an existing Secret containing OIDC credentials (skips chart-generated auth-oidc secret) |
| `auth.oidc.existingSecretKeyMapping.clientId` | `"client-id"` | Key for the OIDC client ID in the existing secret |
| `auth.oidc.existingSecretKeyMapping.clientSecret` | `"client-secret"` | Key for the OIDC client secret in the existing secret |
| `auth.github.existingSecret` | `""` | Name of an existing Secret containing GitHub OAuth credentials (skips chart-generated auth-github secret) |
| `auth.github.existingSecretKeyMapping.clientId` | `"github-client-id"` | Key for the GitHub client ID in the existing secret |
| `auth.github.existingSecretKeyMapping.clientSecret` | `"github-client-secret"` | Key for the GitHub client secret in the existing secret |

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

### extraVolumes / extraVolumeMounts

Each component (`api`, `worker`, `frontend`) accepts `extraVolumes` and
`extraVolumeMounts` lists to mount additional volumes into the pod.

| Name | Default | Description |
|---|---|---|
| `api.extraVolumes` | `[]` | Applied to the API pod |
| `api.extraVolumeMounts` | `[]` | Applied to the API container |
| `worker.extraVolumes` | `[]` | Applied to the worker pod (in addition to the default `temp-data` / `tmp` volumes) |
| `worker.extraVolumeMounts` | `[]` | Applied to the worker container (in addition to the default mounts) |
| `frontend.extraVolumes` | `[]` | Applied to the frontend pod |
| `frontend.extraVolumeMounts` | `[]` | Applied to the frontend container |

Each entry follows the standard Kubernetes `volume` / `volumeMount` schema:

```yaml
frontend:
  extraVolumes:
    - name: config
      configMap:
        name: my-config
  extraVolumeMounts:
    - name: config
      mountPath: /etc/config
      readOnly: true
```

---

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
| `Secret` | `*-api-and-front-auth` | Always created (holds api-key and auth-secret) |
| `Secret` (conditional) | `*-auth-oidc` | Skipped when `auth.oidc.existingSecret` is set |
| `Secret` (conditional) | `*-auth-github` | Skipped when `auth.github.existingSecret` is set |

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
  # API key from a dedicated secret (override the chart-generated secret)
  apiKeyExistingSecret: my-api-key
  apiKeyExistingSecretKey: api-key

  # OIDC credentials from their own secret
  oidc:
    existingSecret: my-oidc-creds
    # existingSecretKeyMapping:
    #   clientId: OIDC_CLIENT_ID
    #   clientSecret: OIDC_CLIENT_SECRET

  # GitHub OAuth credentials from their own secret
  github:
    existingSecret: my-github-creds
    # existingSecretKeyMapping:
    #   clientId: GITHUB_CLIENT_ID
    #   clientSecret: GITHUB_CLIENT_SECRET
```

The expected keys in your existing secret (defaults):

| Secret | Required keys |
|---|---|
| `my-db-creds` | `root-password`, `user`, `password`, `name` |
| `my-api-key` | `api-key` |
| `my-oidc-creds` | `client-id`, `client-secret` |
| `my-github-creds` | `github-client-id`, `github-client-secret` |

When `database.existingSecret` or `auth.oidc.existingSecret` is set, the
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
