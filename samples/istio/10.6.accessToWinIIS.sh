#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

if [ "$IIS_HOST" = "" ]; then
    echo 'IIS_HOST environment is not set.'
    exit
fi

if [ "$IIS_PORT" = "" ]; then
    echo 'IIS_PORT is not set.'
    exit
fi

echo 'Creating ServiceEntry winiis'

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: winiis-ext
spec:
  hosts:
  - $IIS_HOST
  ports:
  - number: $IIS_PORT
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF

echo 'kubectl describe serviceentry winiis-ext'
echo ' '
kubectl describe serviceentry winiis-ext
echo ' '

export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})

echo 'Connecting to pod....'
echo 'kubectl exec -it $SOURCE_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl http://$IIS_HOST:$IIS_PORT -I'
echo ' '
kubectl exec -it $SOURCE_POD -c sleep sh
