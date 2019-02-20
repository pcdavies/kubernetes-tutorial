#!/bin/bash

#
# Clean up if application exists
#
kubectl delete virtualservice httpbin -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete destinationrule httpbin -n $DEFAULT_ISTIO_NAMESPACE

kubectl delete deploy httpbin-v1 httpbin-v2 sleep -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete svc httpbin -n $DEFAULT_ISTIO_NAMESPACE

kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep -E 'sleep|httpbin|NAME' | wc -l) -gt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
  echo 'Sleeping until deleted...'
  sleep 4
done

