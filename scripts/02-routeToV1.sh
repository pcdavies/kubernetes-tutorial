#!/bin/bash

echo 'Routing all request to Version 1'

cat ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-all-v1.yaml

kubectl apply -f ~/istio-1.0.4/samples/bookinfo/networking/virtual-service-all-v1.yaml

#kubectl get virtualservices -o yaml

#kubectl get destinationrules -o yaml


