#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Routing to v1 and v2 for Reviews - v2 Reviews will have a delay failure if logged in as Jason'

cat $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml

cat $ISTIO_DIR/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml

cat $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
