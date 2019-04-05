#!/usr/bin/env bash
## Use below if desire to install in separate namespace
# export DEFAULT_NAMESPACE=nginx
export DEFAULT_NAMESPACE=default

if [ "$DEFAULT_NAMESPACE" = "" ]; then
    echo 'IDEFAULT_NAMESPACE environment is not set. Assuming -n=default'
    export DEFAULT_NAMESPACE=default
fi

kubectl delete deployment app1 -n=$DEFAULT_NAMESPACE
kubectl delete deployment app2 -n=$DEFAULT_NAMESPACE

kubectl delete deployment iis-deploy -n=$DEFAULT_NAMESPACE

kubectl delete service appsvc1 -n=$DEFAULT_NAMESPACE
kubectl delete service appsvc2 -n=$DEFAULT_NAMESPACE

kubectl delete service iis-svc -n=$DEFAULT_NAMESPACE

kubectl delete ingress app-ingress -n=$DEFAULT_NAMESPACE
