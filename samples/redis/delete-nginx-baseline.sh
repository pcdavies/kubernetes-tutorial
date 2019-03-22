#!/usr/bin/env bash
## Use below if desire to install in separate namespace
# export DEFAULT_NAMESPACE=nginx
export DEFAULT_NAMESPACE=default

if [ "$DEFAULT_NAMESPACE" = "" ]; then
    echo 'IDEFAULT_NAMESPACE environment is not set. Assuming -n=default'
    export DEFAULT_NAMESPACE=default
fi

kubectl delete deployment default-backend -n=ingress

kubectl delete service default-backend -n=ingress

kubectl delete configmap nginx-ingress-controller-conf -n=ingress

kubectl delete serviceaccounts nginx -n=ingress

kubectl delete clusterrole nginx-role -n=ingress

kubectl delete serviceaccount nginx -n=ingress

kubectl delete ClusterRoleBinding nginx-role -n=ingress

kubectl delete deployment nginx-ingress-controller -n=ingress

kubectl delete ingress nginx-ingress -n=ingress

kubectl delete ingress app-ingress -n=$DEFAULT_NAMESPACE

kubectl delete service nginx-ingress -n=ingress
