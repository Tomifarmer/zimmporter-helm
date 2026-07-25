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

{{- define "zimmporter.authSecretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else }}
{{- include "zimmporter.fullname" . }}-api-auth
{{- end }}
{{- end }}

{{- define "zimmporter.dbHost" -}}
{{- .Values.database.host | default .Values.mariadb.external.host | default (printf "%s-mariadb" (include "zimmporter.fullname" .)) }}
{{- end }}

{{- define "zimmporter.dbPort" -}}
{{- .Values.database.port | default ( .Values.mariadb.external.port | toString ) | default "3306" }}
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
