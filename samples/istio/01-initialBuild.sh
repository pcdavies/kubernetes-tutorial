#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

echo 'Create Sample App pods and services in the cluster'

cat $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl get pods
kubectl get services


while [ $(kubectl get pods | grep -E 'details|ratings|reviews|productpage' | grep 'Running' | wc -l) -lt 6 ]; do
  kubectl get pods
  echo 'Sleeping until ready...'
  sleep 4
done

echo 'Create the Service Gateway'

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/bookinfo-gateway.yaml
sleep 4

kubectl get gateways

echo 'Create routing rules to access all version'

cat $ISTIO_DIR/samples/bookinfo/networking/destination-rule-all-mtls.yaml

kubectl apply -f $ISTIO_DIR/samples/bookinfo/networking/destination-rule-all-mtls.yaml
sleep 4

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo $GATEWAY_URL

echo 'Trying multiple times for an http return code of 200...'

while ((i<=6)) && [[ "$(curl -o /dev/null -s -w ''%{http_code}'' http://${GATEWAY_URL}/productpage)" != "200" ]]; do
  curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
  let i++
  sleep 5
done
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage

# numberlines=$( kubectl get pods | grep httpbin | grep Running | wc -l)
