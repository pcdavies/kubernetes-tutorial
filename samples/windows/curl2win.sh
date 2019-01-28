#!/bin/bash 
kubectl apply -f ./curl2win.yaml

while [ $(kubectl get pods -n=windows | grep -E 'curl2win' | grep 'Running' | wc -l) -lt 1 ]; do
  kubectl get pods -n=windows
  echo 'Waiting until curl2win is  ready...'
  sleep 4
done

export CURL_POD=$(kubectl get pod -n=windows -l app=curl2win -o jsonpath={.items..metadata.name}) 
echo ' '
echo 'CURL_POD Pod Name:'
echo $CURL_POD
echo ' '



echo 'Connecting to pod....'
echo 'kubectl exec -it $CURL_POD -c sleep sh'
echo ' '
echo 'Once Connected, Enter this command:'
echo 'curl http://httpbin.org/headers -I'
echo ' '

kubectl exec -it -n=windows $CURL_POD -c curl2win sh

