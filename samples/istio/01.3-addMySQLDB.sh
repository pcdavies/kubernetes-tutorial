#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Adding a database for Ratings'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo-mysql.yaml

kubectl get pods
kubectl get services


while [ $(kubectl get pods | grep -E 'mysqldb' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods
  echo 'Sleeping until the Database is ready...'
  sleep 4
done

echo 'Create the Virtual Service'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-mysql.yaml

