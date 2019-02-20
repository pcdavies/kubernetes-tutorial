#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Adding a database for Ratings'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo-db.yaml -n $DEFAULT_ISTIO_NAMESPACE

while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep -E 'mongodb' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
  echo 'Sleeping until the Database is ready...'
  sleep 4
done


kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml -n $DEFAULT_ISTIO_NAMESPACE

while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep -E 'ratings-v2' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
  echo 'Sleeping until the ratings-v2 is ready...'
  sleep 4
done

echo 'Create the Virtual Service'

# kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-db.yaml

# Modified the above virtual service

kubectl -n $DEFAULT_ISTIO_NAMESPACE apply -f -<<EOF
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
      weight: 30
    - destination:
        host: reviews
        subset: v3
      weight: 70
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
      weight: 70
    - destination:
        host: ratings
        subset: v1
      weight: 30
EOF

