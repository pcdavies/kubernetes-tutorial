#!/bin/bash
if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Routing all request to Version 1'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml -n $DEFAULT_ISTIO_NAMESPACE

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-reviews-v3.yaml -n $DEFAULT_ISTIO_NAMESPACE

