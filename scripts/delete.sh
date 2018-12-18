#!/bin/bash

kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
kubectl get pods

/home/pcdavies/istio-1.0.4/samples/bookinfo/platform/kube/defaultCleanup.sh

echo 'Wait for 5 seconds'

sleep 5

echo 'Check to see if all removed:'

kubectl get pods
kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
