#!/bin/bash


kubectl describe virtualservice httpbin

export SLEEP_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=sleep -o jsonpath={.items..metadata.name})
echo ' '
echo 'Calling URL from pod 4 times - curl  http://httpbin:8080/headers....'
# kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'
kubectl exec $SLEEP_POD -n $DEFAULT_ISTIO_NAMESPACE -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -n $DEFAULT_ISTIO_NAMESPACE -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -n $DEFAULT_ISTIO_NAMESPACE -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -n $DEFAULT_ISTIO_NAMESPACE -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1

echo ' '
echo 'V1 Logs without mirroring:'
export V1_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})

echo '$ kubectl logs '"$V1_POD"
kubectl logs $V1_POD -n $DEFAULT_ISTIO_NAMESPACE -c httpbin | grep GET
CNT=$(kubectl logs $V1_POD -n $DEFAULT_ISTIO_NAMESPACE -c httpbin | grep GET | wc -l)
echo 'Returned '"$CNT"' Records'

echo ' '
echo 'V2 Logs without mirroring:'
export V2_POD=$(kubectl get pod -n $DEFAULT_ISTIO_NAMESPACE -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
echo '$ kubectl logs '"$V2_POD"
kubectl logs $V2_POD -n $DEFAULT_ISTIO_NAMESPACE -c httpbin | grep GET
CNT=$(kubectl logs $V2_POD -n $DEFAULT_ISTIO_NAMESPACE -c httpbin | grep GET | wc -l)
echo 'Returned '"$CNT"' Records'
echo ' '

