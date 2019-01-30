#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi


kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/virtual-service-ratings-mysql.yaml

