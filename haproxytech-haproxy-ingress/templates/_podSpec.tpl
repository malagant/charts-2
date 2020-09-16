{{- define "haproxytech-ingress.podSpec" -}}
      serviceAccountName: {{ template "haproxytech-ingress.serviceAccountName" . }}
      imagePullSecrets:
        - name: {{ .Values.controller.image.pullSecret }}
      containers:
      - name: haproxy-ingress
        image:  "{{ .Values.controller.image.repository }}:{{ template "haproxytech-ingress.tag" . }}"
        imagePullPolicy: "{{ .Values.controller.image.pullPolicy }}"
        args:
          - --default-ssl-certificate=default/tls-secret
          {{- if .Values.controller.config }}
          - --configmap={{ .Release.Namespace }}/{{ template "haproxytech-ingress.fullname" . }}
          {{- end }}
          - --ingress.class={{ .Values.controller.ingressClass }}
          - --default-backend-service={{ if .Values.defaultBackend.enabled }}{{ .Release.Namespace }}/{{ template "haproxytech-ingress.defaultBackend.fullname" . }}{{ else }}{{ .Values.controller.defaultBackendService }}{{ end }}
          {{- range $key, $value := .Values.controller.namespace.whitelist }}
          - --namespace-whitelist={{ $value }}
          {{- end }}
          {{- range $key, $value := .Values.controller.namespace.blacklist }}
          - --namespace-blacklist={{ $value }}
          {{- end }}
          {{- range $key, $value := .Values.controller.extraArgs }}
            {{- if $value }}
            - --{{ $key }}={{ $value }}
            {{- else }}
            - --{{ $key }}
            {{- end }}
          {{- end }}
        livenessProbe:
          httpGet:
            path: {{ .Values.controller.livenessProbe.path | quote }}
            port: {{ .Values.controller.livenessProbe.port }}
            scheme: HTTP
          initialDelaySeconds: {{ .Values.controller.livenessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.controller.livenessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.controller.livenessProbe.timeoutSeconds }}
          successThreshold: {{ .Values.controller.livenessProbe.successThreshold }}
          failureThreshold: {{ .Values.controller.livenessProbe.failureThreshold }}
        readinessProbe:
          httpGet:
            path: {{ .Values.controller.readinessProbe.path | quote }}
            port: {{ .Values.controller.readinessProbe.port }}
            scheme: HTTP
          initialDelaySeconds: {{ .Values.controller.readinessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.controller.readinessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.controller.readinessProbe.timeoutSeconds }}
          successThreshold: {{ .Values.controller.readinessProbe.successThreshold }}
          failureThreshold: {{ .Values.controller.readinessProbe.failureThreshold }}
        ports:
        - name: stat
          containerPort: 1024
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        resources:
{{ toYaml .Values.controller.resources | indent 10 }}
{{- if .Values.controller.nodeSelector }}
      nodeSelector:
{{ toYaml .Values.controller.nodeSelector | indent 8 }}
    {{- end }}
    {{- if .Values.controller.tolerations }}
      tolerations:
{{ toYaml .Values.controller.tolerations | indent 8 }}
    {{- end }}
    {{- if .Values.controller.affinity }}
      affinity:
{{ toYaml .Values.controller.affinity | indent 8 }}
    {{- end }}
{{- end -}}
