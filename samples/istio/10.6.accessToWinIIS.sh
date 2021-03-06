#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

if [ "$IIS_HOST" = "" ]; then
    echo 'IIS_HOST environment is not set.'
    kubectl get nodes
    echo ' '
    exit
fi

if [ "$IIS_PORT" = "" ]; then
    echo 'IIS_PORT is not set.'
    kubectl get services -n=windows
    exit
fi

echo 'Creating ServiceEntry winiis'

kubectl -n $DEFAULT_ISTIO_NAMESPACE apply -f - <<EOF
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
kubectl describe serviceentry winiis-ext -n $DEFAULT_ISTIO_NAMESPACE
echo ' '

export SOURCE_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=sleep -o jsonpath={.items..metadata.name})


echo '--------------------'
kubectl get nodes
echo '--------------------'
kubectl get services -n=windows
echo '--------------------'
echo 'Use the list above to to curl the iis-svc'
echo ' '
echo 'Connecting to pod....'
echo 'kubectl exec -it $SOURCE_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl http://'$IIS_HOST':'$IIS_PORT' -I'
echo ' '
kubectl exec -it $SOURCE_POD -n $DEFAULT_ISTIO_NAMESPACE -c sleep sh
