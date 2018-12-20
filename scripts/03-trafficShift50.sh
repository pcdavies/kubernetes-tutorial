#!/bin/bash

echo 'Routing all request to Version 1'

kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-all-v1.yaml

echo 'Shift 50 percent to V1 and 50 percent to V3'

cat ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml

