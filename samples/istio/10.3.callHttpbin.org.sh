#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Creating ServiceEntry httpbin-ext'

kubectl -n $DEFAULT_ISTIO_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF

echo 'kubectl describe serviceentry httpbin-ext'
echo ' '
kubectl describe serviceentry httpbin-ext -n $DEFAULT_ISTIO_NAMESPACE
echo ' '


export SOURCE_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=sleep -o jsonpath={.items..metadata.name})

echo 'Connecting to pod....'
echo 'kubectl exec -it $SOURCE_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl http://httpbin.org/headers -I'
echo ' '
kubectl exec -it $SOURCE_POD  -n $DEFAULT_ISTIO_NAMESPACE -c sleep sh
