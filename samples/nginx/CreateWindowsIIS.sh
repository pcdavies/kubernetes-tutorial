#!/usr/bin/env bash

kubectl create namespace windows

kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-deploy
  namespace: windows
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      containers:
      - name: iis
        image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019
        resources:
          limits:
            memory: "128Mi"
            cpu: 2
        ports:
        - containerPort: 80
      nodeSelector:
        beta.kubernetes.io/os: windows
      tolerations:
      - key: "opsys-taint"
        operator: Equal
        value: "windows"
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: iis
  name: iis-svc
  namespace: windows
spec:
  type: NodePort
  ports:
    - port: 80
  selector:
    app: iis
EOF


kubectl apply -n windows -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: iis-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: iis-svc
          servicePort: 80
        path: /iis
EOF
