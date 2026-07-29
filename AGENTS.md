# Zimmporter Helm Chart — Agent Guide

## Commands

| Action | Command |
|--------|---------|
| Lint | `helm lint .` |
| Render (debug) | `helm template . --debug` |
| Package | `helm package . --version X --app-version X` |
| Push OCI | `helm push zimmporter-*.tgz oci://ghcr.io/$OWNER` |

No test suite exists (no `helm test` templates, no chart-testing framework).

## CI

- `.github/workflows/helm.yml` — lints, templates, runs Trivy (critical/high config), packages, and pushes to GHCR OCI on push to `main` or `v*` tags.
- `.github/workflows/check-chart-version.yaml` — on `v*` tags, verifies `Chart.yaml version` matches the tag (stripped of `v`).

## Architecture

Single v2 chart. 14 templates, one `_helpers.tpl`, one `values.yaml`.

| Component | Kind | Conditional |
|-----------|------|-------------|
| api | Deployment | always |
| worker | Deployment | always |
| frontend | Deployment | always |
| valkey | StatefulSet | skipped when `valkey.external.enabled` |
| mariadb | StatefulSet | skipped when `mariadb.external.enabled` |

External service pattern: `<component>.external.enabled` + `.host`/`.address` + `.port` (used by valkey and mariadb).

## Security Context Pattern

- **Pod level**: configurable via `values.yaml` → `<component>.podSecurityContext`, rendered with `{{- with .Values.X.podSecurityContext }}`.
- **Container level**: hardcoded in templates (runAsNonRoot, runAsUser, readOnlyRootFilesystem, allowPrivilegeEscalation, capabilities, seccompProfile).
- Valkey follows the same pattern (podSecurityContext in values, container security context hardcoded — recently changed).

## Helpers (`_helpers.tpl`)

Key named templates used across resources:
- `zimmporter.fullname` — resource name prefix
- `zimmporter.labels` / `zimmporter.<component>SelectorLabels` — label blocks
- `zimmporter.dbHost` / `zimmporter.dbPort` — resolves external vs in-cluster DB
- `zimmporter.databaseSecretName` / `zimmporter.authSecretName` — secret name resolution

## Values Conventions

- `global.extraEnv` is merged into all pods before component-specific `extraEnv`
- `extraVolumes` / `extraVolumeMounts` lists available on api, worker, frontend
- Image settings under `images.<component>.repository` + `.tag` (not inline)
- `existingSecret` + `existingSecretKeyMapping` pattern for DB, auth, S3 secrets
