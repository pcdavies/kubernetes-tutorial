#!/bin/bash

echo 'Half second timeout on the review page will cause failure Book Details'

cat <<EOF | kubectl -n $DEFAULT_ISTIO_NAMESPACE apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF


