#!/bin/bash

cat <<EOF | kubectl apply -n $DEFAULT_ISTIO_NAMESPACE -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
EOF

kubectl get virtualServices -n $DEFAULT_ISTIO_NAMESPACE

