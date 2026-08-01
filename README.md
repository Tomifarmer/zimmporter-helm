# Zimmporter Helm Chart

Deploys the Zimmporter stack on Kubernetes:

| Component | Description |
|---|---|---|
| **api** | FastAPI application — search, download orchestration, job management |
| **worker** | Celery worker — executes album/playlist downloads via yt-dlp |
| **frontend** | Next.js UI — search, job status, download management |
| **valkey** | Redis-compatible KV store — Celery broker & result backend |
| **mariadb** | SQL database — job and song metadata |
| **bgutil-provider** | BgUtils yt-dlp POT provider — supplies PO tokens for age-restricted content |

S3-compatible object storage is expected to be pre-provisioned
and configured via values — it is **not** deployed by this chart.

---

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- A default `StorageClass` (or set one explicitly for Valkey / MariaDB / cookies)
- A `StorageClass` with `ReadWriteMany` access (or a provider that supports
  shared volumes) for the cookies volume — both the API and worker pods mount it
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
| `global.extraEnv` | `[]` | Additional env vars injected into **all** pods, including Valkey, MariaDB, and bgutil-provider (see [extraEnv docs](#extraenv)) |

### Images

| Name | Default | Description |
|---|---|---|
| `images.api.repository` | `"ghcr.io/tomifarmer/zimmporter-api"` | Docker image for the API |
| `images.api.tag` | `"latest"` | Image tag |
| `images.api.pullPolicy` | `IfNotPresent` | Image pull policy |
| `images.api.pullSecret` | `""` | Name of the imagePullSecret for the API |
| `images.worker.repository` | `"ghcr.io/tomifarmer/zimmporter-worker"` | Docker image for the Celery worker |
| `images.worker.tag` | `"latest"` | Image tag |
| `images.worker.pullPolicy` | `IfNotPresent` | Image pull policy |
| `images.worker.pullSecret` | `""` | Name of the imagePullSecret for the worker |
| `images.frontend.repository` | `"ghcr.io/tomifarmer/zimmporter-front"` | Docker image for the Next.js frontend |
| `images.frontend.tag` | `"latest"` | Image tag |
| `images.frontend.pullPolicy` | `IfNotPresent` | Image pull policy |
| `images.frontend.pullSecret` | `""` | Name of the imagePullSecret for the frontend |

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
| `api.env.OIDC_ISSUER_URL` | `""` | OIDC issuer URL |
| `api.env.API_PROXY_FETCH` | `"false"` | Proxy thumbnail fetches through the API; thumbnails embedded as base64 data URIs in search results |
| `api.indexSource` | `"s3"` | Which library sources feed the available-albums index (`INDEX_SOURCE`): `s3` (default), `navidrome`, or `both` |
| `api.indexIntervalMinutes` | `30` | How often (minutes) the API pod dispatches the periodic library index scan (`INDEX_INTERVAL_MINUTES`; min `1`) |
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

### Navidrome (optional index source)

When `api.indexSource` is `navidrome` or `both`, the worker queries
Navidrome's Subsonic API (`getAlbumList2`) to populate the available-albums
index — a tag-accurate view of the library.

| Name | Default | Description |
|---|---|---|
| `navidrome.url` | `""` | Navidrome base URL (worker `NAVIDROME_URL`) |
| `navidrome.user` | `""` | Subsonic API username (worker `NAVIDROME_USER`) |
| `navidrome.password` | `""` | Subsonic API password (worker `NAVIDROME_PASS`; ignored when `existingSecret` is set) |
| `navidrome.existingSecret` | `""` | Name of an existing Secret (skips chart-generated navidrome secret) |
| `navidrome.existingSecretKeyMapping.user` | `"user"` | Key for the username in the existing secret |
| `navidrome.existingSecretKeyMapping.password` | `"password"` | Key for the password in the existing secret |

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
| `mariadb.nodeSelector` | `{}` | Node selector |
| `mariadb.tolerations` | `[]` | Pod tolerations |
| `mariadb.affinity` | `{}` | Pod affinity/anti-affinity |

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
| `valkey.nodeSelector` | `{}` | Node selector |
| `valkey.tolerations` | `[]` | Pod tolerations |
| `valkey.affinity` | `{}` | Pod affinity/anti-affinity |

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
| `auth.oidcClientId` | `""` | OIDC client ID (injected into API + frontend from the oidc secret) |
| `auth.oidcClientSecret` | `""` | OIDC client secret for the frontend (injected only when `USE_SOCIAL_LOGIN=true`) |
| `auth.githubClientId` | `""` | GitHub client ID (injected into API + frontend from the github secret) |
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

### POT provider (bgutil-provider)

The chart deploys the [BgUtils yt-dlp POT provider](https://github.com/Brainicism/bgutil-ytdlp-pot-provider)
and injects its URL into the worker via `POT_PROVIDER_URL`, enabling
yt-dlp PO-token extraction for age-restricted content.

| Name | Default | Description |
|---|---|---|
| `potProvider.enabled` | `true` | Deploy the POT provider deployment + service |
| `potProvider.replicas` | `1` | Number of provider pods |
| `potProvider.image.repository` | `"brainicism/bgutil-ytdlp-pot-provider"` | Provider image |
| `potProvider.image.tag` | `"1.3.1"` | Provider image tag |
| `potProvider.image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `potProvider.port` | `4416` | HTTP port (service + container) |
| `potProvider.terminationGracePeriodSeconds` | `5` | Pod termination grace period (the provider doesn't exit gracefully on SIGTERM, so a short value avoids the default 30s hang) |
| `potProvider.probes.enabled` | `true` | Enable HTTP liveness/readiness probes on `/ping` |
| `potProvider.resources` | `{requests: {cpu: 50m, memory: 64Mi}, limits: {cpu: 200m, memory: 256Mi}}` | Container resource limits/requests |
| `potProvider.podSecurityContext` | `{runAsNonRoot: true}` | Pod-level security context |
| `potProvider.nodeSelector` | `{}` | Node selector |
| `potProvider.tolerations` | `[]` | Pod tolerations |
| `potProvider.affinity` | `{}` | Pod affinity/anti-affinity |
| `potProvider.extraEnv` | `[]` | Additional env vars for the provider pod |

### Cookies (YouTube auth)

Cookies uploaded through the UI (`POST /cookies` on the API) are stored in a
shared volume that both the API and worker mount. The API receives `COOKIE_DIR`
(the writable mount path) and the worker reads the file via `YTDLP_COOKIEFILE`
(`cookies.workerMountPath`/`cookies.filename`) for age-restricted download auth.

| Name | Default | Description |
|---|---|---|
| `cookies.dir` | `"/var/zimmporter/cookies"` | API-side mount path (writable, holds `cookies.txt`) |
| `cookies.workerMountPath` | `"/etc/zimmporter/cookies"` | Worker-side mount path (read-only) |
| `cookies.filename` | `"cookies.txt"` | Cookie file name inside the shared volume |
| `cookies.hostPath` | `""` | Host directory to use as a shared volume (single-node clusters without an RWX StorageClass); created with `DirectoryOrCreate` when set |
| `cookies.persistence.enabled` | `true` | Create a PVC for the shared cookies volume (ignored when `hostPath` is set) |
| `cookies.persistence.storageClass` | `""` | PVC storage class (default cluster `StorageClass` when empty) |
| `cookies.persistence.accessModes` | `["ReadWriteMany"]` | PVC access modes — must support shared mounts |
| `cookies.persistence.size` | `"1Gi"` | PVC size |

The default PVC backend requires a `StorageClass` with `ReadWriteMany` access
(or a provider supporting shared volumes). On single-node clusters that only
expose an RWO `StorageClass` (e.g. k3s `local-path`), set `cookies.hostPath`
and `cookies.persistence.enabled: false` instead — the API and worker pods run
on the same node and share the host directory.

### Private CA

| Name | Default | Description |
|---|---|---|
| `caCert.enabled` | `false` | Mount a custom CA certificate into the API and worker pods |
| `caCert.path` | `"/etc/ssl/certs/ca.crt"` | Path the certificate file is mounted at (also set via `CA_CERT`) |
| `caCert.existingConfigMap` | `""` | Name of an existing ConfigMap containing the CA cert (required when enabled; must contain `key`) |
| `caCert.key` | `"ca.crt"` | Key within the ConfigMap |

When `caCert.enabled`, the cert file from `caCert.existingConfigMap` is mounted
read-only at `caCert.path` in the API and worker containers and `CA_CERT` is
set to that path, so all HTTPS clients trust the private CA. A ConfigMap is
used because a CA bundle is public data and needs no secret protection.

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

`global.extraEnv` is also merged into the Valkey, MariaDB, and bgutil-provider
pods (the provider combines it with `potProvider.extraEnv`).

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

## Resources created

| Kind | Name pattern | Notes |
|---|---|---|
| `Deployment` | `{release}-zimmporter-api` | FastAPI, `/health` probe, writable cookies volume at `/var/zimmporter/cookies`; also runs the periodic library index dispatcher (`api.indexIntervalMinutes`) |
| `Deployment` | `{release}-zimmporter-worker` | Celery, `emptyDir` at `/data/zimmer/importer`, `inspect ping` probe, read-only cookies volume |
| `Deployment` (conditional) | `{release}-zimmporter-bgutil-provider` | POT provider, `/ping` probe; skipped when `potProvider.enabled=false` |
| `Deployment` | `{release}-zimmporter-frontend` | Next.js, HTTP probe on `/` |
| `StatefulSet` (conditional) | `{release}-zimmporter-valkey` | Skipped when `valkey.external.enabled=true` |
| `StatefulSet` (conditional) | `{release}-zimmporter-mariadb` | Skipped when `mariadb.external.enabled=true` |
| `Service` (×4–6) | ClusterIP for each component | Valkey + MariaDB skipped when external |
| `PersistentVolumeClaim` (conditional) | `{release}-zimmporter-cookies` | Shared RWX volume; skipped when `cookies.persistence.enabled=false` |
| `Ingress` (×2) | Only when enabled | Separate hostnames for API and frontend |
| `ConfigMap` (×3) | `*-api-config`, `*-worker-config`, `*-frontend-config` | Non-sensitive environment variables |
| `Secret` (conditional) | `*-database` | Skipped when `database.existingSecret` is set |
| `Secret` | `*-s3` | Always created |
| `Secret` (conditional) | `*-navidrome` | Created when `navidrome.password` is set and `navidrome.existingSecret` is empty |
| `Secret` | `*-api-and-front-auth` | Always created (holds api-key and auth-secret) |
| `Secret` (conditional) | `*-auth-oidc` | Skipped when `auth.oidc.existingSecret` is set |
| `Secret` (conditional) | `*-auth-github` | Skipped when `auth.github.existingSecret` is set |

---

## Health checks

- **API**: `GET /health` returns per-component status (Valkey, Celery, MariaDB).
- **Worker**: Liveness probe runs `celery -A tasks.celery_app inspect ping --timeout=5`.
- **Frontend**: Liveness and readiness probes hit `/` on port 3000.

The API and worker deployments use init containers to wait for MariaDB and
Valkey to be reachable before the main container starts.

## Config changes trigger pod rollouts

The API, worker, and frontend deployments carry a `checksum/config` annotation
computed over the ConfigMap file, so any change to the ConfigMaps (e.g. a new
`api.indexSource` or `navidrome.*` value) automatically rolls the affected pods
to pick up the new environment variables. No manual `kubectl rollout restart`
is needed after a `helm upgrade`.

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

navidrome:
  existingSecret: my-navidrome-creds
  # existingSecretKeyMapping:
  #   user: NAVIDROME_USER
  #   password: NAVIDROME_PASS
```

The expected keys in your existing secret (defaults):

| Secret | Required keys |
|---|---|
| `my-db-creds` | `root-password`, `user`, `password`, `name` |
| `my-api-key` | `api-key` |
| `my-oidc-creds` | `client-id`, `client-secret` |
| `my-github-creds` | `github-client-id`, `github-client-secret` |
| `my-navidrome-creds` | `user`, `password` |

When `database.existingSecret` or `auth.oidc.existingSecret` is set, the
chart skips creating its own Secret and uses yours directly.

---

## Uninstall

```bash
helm uninstall my-release
```

Persistent volume claims for Valkey, MariaDB, and cookies are **not** deleted by
default. Remove them manually if needed:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=my-release
```
