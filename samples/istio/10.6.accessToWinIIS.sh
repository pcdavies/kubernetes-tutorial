#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
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
  - vdc-devappren01.stormwind.local
  ports:
  - number: 31699
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
echo 'curl http://vdc-devappren01.stormwind.local:31699 -I'
echo ' '
kubectl exec -it $SOURCE_POD -c sleep sh
