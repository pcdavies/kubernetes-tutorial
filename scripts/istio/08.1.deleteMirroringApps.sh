#!/bin/bash

#
# Clean up if application exists
#
kubectl delete virtualservice httpbin
kubectl delete destinationrule httpbin

kubectl delete deploy httpbin-v1 httpbin-v2 sleep
kubectl delete svc httpbin

kubectl get pods
while [ $(kubectl get pods | grep -E 'sleep|httpbin|NAME' | wc -l) -gt 1 ]; do
  kubectl get pods
  echo 'Sleeping until deleted...'
  sleep 4
done

