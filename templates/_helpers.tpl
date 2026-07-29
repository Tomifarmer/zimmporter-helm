{{- define "zimmporter.name" -}}
{{- default "zimmporter" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "zimmporter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "zimmporter" .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "zimmporter.labels" -}}
helm.sh/chart: {{ printf "%s-%s" (include "zimmporter.name" .) .Chart.Version | replace "+" "_" }}
{{ include "zimmporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "zimmporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zimmporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "zimmporter.apiSelectorLabels" -}}
{{ include "zimmporter.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{- define "zimmporter.workerSelectorLabels" -}}
{{ include "zimmporter.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{- define "zimmporter.frontendSelectorLabels" -}}
{{ include "zimmporter.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{- define "zimmporter.valkeySelectorLabels" -}}
{{ include "zimmporter.selectorLabels" . }}
app.kubernetes.io/component: valkey
{{- end }}

{{- define "zimmporter.mariadbSelectorLabels" -}}
{{ include "zimmporter.selectorLabels" . }}
app.kubernetes.io/component: mariadb
{{- end }}

{{- define "zimmporter.imagePullSecret" -}}
{{- if .Values.images.api.pullSecret }}
{"auths":{"https://index.docker.io/v1/":{"auth":"{{ .Values.images.api.pullSecret }}"}}}
{{- end }}
{{- end }}

{{- define "zimmporter.databaseSecretName" -}}
{{- if .Values.database.existingSecret }}
{{- .Values.database.existingSecret }}
{{- else }}
{{- include "zimmporter.fullname" . }}-database
{{- end }}
{{- end }}

{{- define "zimmporter.s3SecretName" -}}
{{- if .Values.s3.existingSecret }}
{{- .Values.s3.existingSecret }}
{{- else }}
{{- include "zimmporter.fullname" . }}-s3
{{- end }}
{{- end }}

{{- define "zimmporter.authSecretName" -}}
{{- include "zimmporter.fullname" . }}-api-and-front-auth
{{- end }}

{{- define "zimmporter.authOidcSecretName" -}}
{{- if .Values.auth.oidc.existingSecret }}
{{- .Values.auth.oidc.existingSecret }}
{{- else }}
{{- include "zimmporter.fullname" . }}-auth-oidc
{{- end }}
{{- end }}

{{- define "zimmporter.dbRootPassword" -}}
{{- if .Values.database.rootPassword }}
{{- .Values.database.rootPassword }}
{{- else }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "zimmporter.databaseSecretName" .)) }}
{{- if $secret }}
{{- index $secret.data "root-password" | b64dec }}
{{- else }}
{{- randAlphaNum 20 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "zimmporter.dbPassword" -}}
{{- if .Values.database.password }}
{{- .Values.database.password }}
{{- else }}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "zimmporter.databaseSecretName" .)) }}
{{- if $secret }}
{{- $secret.data.password | b64dec }}
{{- else }}
{{- randAlphaNum 20 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "zimmporter.dbHost" -}}
{{- .Values.database.host | default .Values.mariadb.external.host | default (printf "%s-mariadb" (include "zimmporter.fullname" .)) }}
{{- end }}

{{- define "zimmporter.dbPort" -}}
{{- .Values.database.port | default ( .Values.mariadb.external.port | toString ) | default "3306" }}
{{- end }}

{{- define "zimmporter.apiInternalUrl" -}}
{{- printf "http://%s-api:8000" (include "zimmporter.fullname" .) }}
{{- end }}

{{- define "zimmporter.valkeyAddress" -}}
{{- .Values.valkey.external.address | default (printf "%s-valkey" (include "zimmporter.fullname" .)) }}
{{- end }}

{{- define "zimmporter.valkeyPort" -}}
{{- .Values.valkey.external.port | toString | default "6379" }}
{{- end }}

{{- define "zimmporter.celeryBroker" -}}
{{- if .Values.celery.broker }}
{{- .Values.celery.broker }}
{{- else }}
{{- $addr := .Values.valkey.external.address | default (printf "%s-valkey" (include "zimmporter.fullname" .)) }}
{{- $port := .Values.valkey.external.port | toString | default "6379" }}
{{- printf "redis://%s:%s/0" $addr $port }}
{{- end }}
{{- end }}

{{- define "zimmporter.celeryBackend" -}}
{{- if .Values.celery.backend }}
{{- .Values.celery.backend }}
{{- else }}
{{- $addr := .Values.valkey.external.address | default (printf "%s-valkey" (include "zimmporter.fullname" .)) }}
{{- $port := .Values.valkey.external.port | toString | default "6379" }}
{{- printf "redis://%s:%s/1" $addr $port }}
{{- end }}
{{- end }}
