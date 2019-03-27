#!/usr/bin/env bash

## Use below if desire to install in separate namespace
#kubectl create namespace nginx
#export DEFAULT_NAMESPACE=nginx

export DEFAULT_NAMESPACE=default

if [ "$DEFAULT_NAMESPACE" = "" ]; then
    echo 'IDEFAULT_NAMESPACE environment is not set. Assuming -n default'
    export DEFAULT_NAMESPACE=default
fi

# Create the Apps

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app1
        ports:
        - containerPort: 80
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app2
        ports:
        - containerPort: 80
EOF


while [ $(kubectl get pods -n $DEFAULT_NAMESPACE| grep -E 'app' | grep 'Running' | wc -l) -lt 4 ]; do
  kubectl get pods -n $DEFAULT_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  sleep 1
done


# create the Services for the apps
kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: appsvc1
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app1
---
apiVersion: v1
kind: Service
metadata:
  name: appsvc2
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
EOF

sleep 1

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: appsvc1
          servicePort: 80
        path: /app1
      - backend:
          serviceName: appsvc2
          servicePort: 80
        path: /app2
EOF
