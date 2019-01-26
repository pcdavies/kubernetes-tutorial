#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})


kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: google
spec:
  hosts:
  - www.google.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: google
spec:
  hosts:
  - www.google.com
  tls:
  - match:
    - port: 443
      sni_hosts:
      - www.google.com
    route:
    - destination:
        host: www.google.com
        port:
          number: 443
      weight: 100
EOF

echo 'Created Google Service Entry and Virtual Services...'
echo ' '
echo 'kubectl describe serviceentry google'
kubectl describe serviceentry google
echo ' '
echo 'kubectl describe virtualservice google'
kubectl describe virtualservice google
echo ' '

echo 'Connecting to pod....'
echo 'kubectl exec -it $SOURCE_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl https://www.google.com'
echo ' '
kubectl exec -it $SOURCE_POD -c sleep sh
