#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

export SOURCE_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=sleep -o jsonpath={.items..metadata.name})

kubectl get serviceentries -n $DEFAULT_ISTIO_NAMESPACE
kubectl get virtualservices -n $DEFAULT_ISTIO_NAMESPACE

kubectl delete serviceentry httpbin-ext  -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete serviceentry google  -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete serviceentry winiis-ext -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete virtualservice google -n $DEFAULT_ISTIO_NAMESPACE

kubectl get serviceentries -n $DEFAULT_ISTIO_NAMESPACE
kubectl get virtualservices -n $DEFAULT_ISTIO_NAMESPACE
