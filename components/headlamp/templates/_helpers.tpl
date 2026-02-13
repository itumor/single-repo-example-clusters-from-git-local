{{/*
Standard Helm release labels (app.kubernetes.io/*) for resource ownership.
*/}}
{{- define "headlamp.labels" -}}
app.kubernetes.io/name: headlamp
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app: headlamp
{{- end -}}

{{- define "headlamp.selectorLabels" -}}
app.kubernetes.io/name: headlamp
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app: headlamp
{{- end -}}
