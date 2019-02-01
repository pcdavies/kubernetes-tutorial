#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Registering MySQL Host - using this IP: '$MYSQL_HOST
istioctl register mysqldb $MYSQL_HOST 3306

echo 'Adding a database for Ratings'

# kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml
# Changed above file to below

kubectl apply -f -<<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ratings-v2-mysql-vm
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ratings
        version: v2-mysql-vm
    spec:
      containers:
      - name: ratings
        image: istio/examples-bookinfo-ratings-v2:1.8.0
        imagePullPolicy: IfNotPresent
        env:
          # This assumes you registered your mysql vm as
          # istioctl register -n vm mysqldb 1.2.3.4 3306
          - name: DB_TYPE
            value: "mysql"
          - name: MYSQL_DB_HOST
            value: mysqldb.vm.svc.cluster.local
          - name: MYSQL_DB_PORT
            value: "3306"
          - name: MYSQL_DB_USER
            value: $MYSQL_USER
          - name: MYSQL_DB_PASSWORD
            value: $MYSQL_PASSWORD
        ports:
        - containerPort: 9080
EOF

while [ $(kubectl get pods | grep -E 'ratings-v2' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods
  echo 'Sleeping until the ratings-v2 is ready...'
  sleep 4
done

echo 'Create the Virtual Service'

# kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml

kubectl apply -f -<<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
      weight: 20
    - destination:
        host: reviews
        subset: v3
      weight: 80
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v2
      weight: 50
    - destination:
        host: ratings
        subset: v2-mysql-vm
      weight: 50
EOF

