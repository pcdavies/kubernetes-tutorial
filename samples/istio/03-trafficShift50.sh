#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Routing all request to Version 1'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml -n $DEFAULT_ISTIO_NAMESPACE

echo 'Shift 50 percent to V1 and 50 percent to V3'

cat $ISTIO_DIR/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml -n $DEFAULT_ISTIO_NAMESPACE

