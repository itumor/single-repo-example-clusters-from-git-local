{{/*
Standard Helm release labels (app.kubernetes.io/*) for resource ownership.
*/}}
{{- define "gen-dashboard.labels" -}}
app.kubernetes.io/name: gen-dashboard
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app: gen-dashboard
{{- end -}}

{{- define "gen-dashboard.selectorLabels" -}}
app.kubernetes.io/name: gen-dashboard
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app: gen-dashboard
{{- end -}}
