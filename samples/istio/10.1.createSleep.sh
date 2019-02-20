#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Deploying sleep'

kubectl -n $DEFAULT_ISTIO_NAMESPACE apply -f $ISTIO_DIR/samples/sleep/sleep.yaml

while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep -E 'sleep' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
  echo 'Waiting until Sleep  ready...'
  sleep 4
done

export SOURCE_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=sleep -o jsonpath={.items..metadata.name})

echo ' '
echo 'Sleep Pod Name:'
echo $SOURCE_POD
echo ' '


