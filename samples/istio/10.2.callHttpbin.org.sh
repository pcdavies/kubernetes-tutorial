#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})

echo 'Connecting to pod....'
echo 'kubectl exec -it $SOURCE_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl http://httpbin.org/headers'
echo ' '
kubectl exec -it $SOURCE_POD -c sleep sh
