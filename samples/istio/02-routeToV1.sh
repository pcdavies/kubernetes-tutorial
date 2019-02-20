#!/bin/bash
if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Routing all request to Version 1'

cat $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-all-v1.yaml -n $DEFAULT_ISTIO_NAMESPACE

#kubectl get virtualservices -o yaml

#kubectl get destinationrules -o yaml


