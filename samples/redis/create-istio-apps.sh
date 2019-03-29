#!/usr/bin/env bash

export DEFAULT_ISTIO_NAMESPACE=istio-demos

kubectl create namespace $DEFAULT_ISTIO_NAMESPACE
kubectl label namespace $DEFAULT_ISTIO_NAMESPACE istio-injection=enabled


# Create the Apps

kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
  labels:
    app: redis-m
spec:
  selector:
    matchLabels:
      app: redis-m
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis-m
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

while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE| grep -E 'redis-master' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE -l app=redis -l tier=backend
  sleep 1
done

kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
export POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=redis -o jsonpath="{.items[0].metadata.name}")

kubectl logs $POD -n $DEFAULT_ISTIO_NAMESPACE --container master


kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-master
  labels:
    app: redis-m
    role: master
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis-m
    role: master
    tier: backend
EOF

kubectl get service -n $DEFAULT_ISTIO_NAMESPACE

kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-slave
  labels:
    app: redis-s
spec:
  selector:
    matchLabels:
      app: redis-s
      role: slave
      tier: backend
  replicas: 2
  template:
    metadata:
      labels:
        app: redis-s
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


while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE| grep -E 'redis-slave' | grep 'Running' | wc -l) -lt 2 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE -l app=redis -l tier=backend
  sleep 1
done


kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-slave
  labels:
    app: redis-s
    role: slave
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis-s
    role: slave
    tier: backend
EOF

kubectl get service -n $DEFAULT_ISTIO_NAMESPACE

kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
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

while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE| grep -E 'frontend' | grep 'Running' | wc -l) -lt 3 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep app
  echo 'Sleeping until ready...'
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE -l app=guestbook -l tier=frontend
  sleep 1
done



kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
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

kubectl get services -n $DEFAULT_ISTIO_NAMESPACE

# Create The Gateways


kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: guestbook-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF

kubectl get gateways -n $DEFAULT_ISTIO_NAMESPACE

kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: guestbook
spec:
  hosts:
  - "*"
  gateways:
  - guestbook-gateway
  http:
  - match:
    - uri:
        prefix: /guestbook
    rewrite:
      uri: /
    route:
    - destination:
        host: frontend
        # subset: v1
        port:
          number: 80
EOF


kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: guestbook
spec:
  host: guestbook
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
EOF


kubectl get pods -o wide -n $DEFAULT_ISTIO_NAMESPACE
