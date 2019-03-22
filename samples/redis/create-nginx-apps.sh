#!/usr/bin/env bash

export DEFAULT_NAMESPACE=default

if [ "$DEFAULT_NAMESPACE" = "" ]; then
    echo 'IDEFAULT_NAMESPACE environment is not set. Assuming -n default'
    export DEFAULT_NAMESPACE=default
fi

# Create the Apps

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      containers:
      - name: master
        image: k8s.gcr.io/redis:e2e  # or just image: redis
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
EOF

while [ $(kubectl get pods -n $DEFAULT_NAMESPACE| grep -E 'redis-master' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n $DEFAULT_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -l app=redis -l tier=backend
  sleep 1
done

kubectl get pods
export POD=$(kubectl get pod -l app=redis -o jsonpath="{.items[0].metadata.name}")

kubectl logs $POD


kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-master
  labels:
    app: redis
    role: master
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
    role: master
    tier: backend
EOF

kubectl get service

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-slave
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
      role: slave
      tier: backend
  replicas: 2
  template:
    metadata:
      labels:
        app: redis
        role: slave
        tier: backend
    spec:
      containers:
      - name: slave
        image: gcr.io/google_samples/gb-redisslave:v1
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # Using `GET_HOSTS_FROM=dns` requires your cluster to
          # provide a dns service. As of Kubernetes 1.3, DNS is a built-in
          # service launched automatically. However, if the cluster you are using
          # does not have a built-in DNS service, you can instead
          # access an environment variable to find the master
          # service's host. To do so, comment out the 'value: dns' line above, and
          # uncomment the line below:
          # value: env
        ports:
        - containerPort: 6379
EOF


while [ $(kubectl get pods -n $DEFAULT_NAMESPACE| grep -E 'redis-slave' | grep 'Running' | wc -l) -lt 2 ]; do
  kubectl get pods -n $DEFAULT_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -l app=redis -l tier=backend
  sleep 1
done


kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-slave
  labels:
    app: redis
    role: slave
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis
    role: slave
    tier: backend
EOF

kubectl get service

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: guestbook
spec:
  selector:
    matchLabels:
      app: guestbook
      tier: frontend
  replicas: 3
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google-samples/gb-frontend:v4
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # Using `GET_HOSTS_FROM=dns` requires your cluster to
          # provide a dns service. As of Kubernetes 1.3, DNS is a built-in
          # service launched automatically. However, if the cluster you are using
          # does not have a built-in DNS service, you can instead
          # access an environment variable to find the master
          # service's host. To do so, comment out the 'value: dns' line above, and
          # uncomment the line below:
          # value: env
        ports:
        - containerPort: 80
EOF

while [ $(kubectl get pods -n $DEFAULT_NAMESPACE| grep -E 'frontend' | grep 'Running' | wc -l) -lt 3 ]; do
  kubectl get pods -n $DEFAULT_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -l app=guestbook -l tier=frontend
  sleep 1
done



kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # comment or delete the following line if you want to use a LoadBalancer
  type: NodePort
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  # type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: guestbook
    tier: frontend
EOF

kubectl get services

kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: frontend-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: frontend
          servicePort: 80
        path: /frontend
EOF

kubectl get ingress

kubectl get pods -o wide
