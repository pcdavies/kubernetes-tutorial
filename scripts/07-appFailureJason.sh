#!/bin/bash

echo 'Routing to v1 and v2 for Reviews - v2 Reviews will have a delay failure if logged in as Jason'

cat ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-all-v1.yaml

cat ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml

cat ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
