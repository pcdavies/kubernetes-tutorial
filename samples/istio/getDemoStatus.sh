echo ''
echo 'Checking Virtual Services'
kubectl get virtualservices

echo ''
echo 'Checking Distination Rules'
kubectl get destinationrules

echo ''
echo 'Checking Service Entires'
kubectl get serviceentries

echo ''
echo 'Checking Gateways'
kubectl get gateway

echo ''
echo 'Checking Pods'
kubectl get pods -o wide

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo ' '
echo 'Gateway URL...'
echo $GATEWAY_URL

echo ''
echo 'Checking for 200 return code from URL'
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage

