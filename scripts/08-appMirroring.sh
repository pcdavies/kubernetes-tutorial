#!/bin/bash

#
# Clean up if application exists
#
kubectl delete virtualservice httpbin
kubectl delete destinationrule httpbin

kubectl delete deploy httpbin-v1 httpbin-v2 sleep
kubectl delete svc httpbin

kubectl get pods
while [ $(kubectl get pods | grep -E 'sleep|httpbin|NAME' | wc -l) -gt 1 ]; do
  kubectl get pods
  echo 'Sleeping until deleted...'
  sleep 4
done

echo 'Deploy httpbin-v1'

cat <<EOF | ~/istio-1.0.4/bin/istioctl kube-inject -f - | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: httpbin-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
        ports:
        - containerPort: 8080
EOF


echo 'Deploy httpbin-v2'

cat <<EOF | ~/istio-1.0.4/bin/istioctl kube-inject -f - | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: httpbin-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
        ports:
        - containerPort: 8080
EOF


echo 'create httpbin service'
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8080
  selector:
    app: httpbin
EOF

echo 'Create the sleep service'
cat <<EOF | ~/istio-1.0.4/bin/istioctl kube-inject -f - | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
EOF

#
# Routing Policy only to V1
#


cat <<EOF | kubectl apply -f -
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
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF


while [ $(kubectl get pods | grep -E 'sleep|httpbin' | grep 'Running' | wc -l) -lt 3 ]; do
  kubectl get pods
  echo 'Sleeping until Running...'
  sleep 4
done


export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
echo ' '
echo 'Calling URL from pod 4 times - curl  http://httpbin:8080/headers....'
# kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers' > /dev/null 2>&1

echo ' '
echo 'V1 Logs without mirroring:'
echo ' '
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
kubectl logs $V1_POD -c httpbin | grep GET

echo ' '
echo 'V2 Logs without mirroring:'
echo ' '
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
kubectl logs $V2_POD -c httpbin | grep GET
echo ' '

cat <<EOF | kubectl apply -f -
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
    mirror:
      host: httpbin
      subset: v2
EOF

echo ' '
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
echo $SLEEP_POD

echo ' '
echo 'Calling URL from pod 4 times - curl  http://httpbin:8080/headers....'
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'  > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'  > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'  > /dev/null 2>&1
kubectl exec $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'  > /dev/null 2>&1

echo ' '
echo 'V1 Logs after mirroring:'
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
kubectl logs $V1_POD -c httpbin | grep GET
echo ' '

echo 'V2 Logs after mirroring:'
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
kubectl logs $V2_POD -c httpbin | grep GET
echo ' '


