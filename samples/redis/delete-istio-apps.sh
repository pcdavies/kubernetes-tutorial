#!/usr/bin/env bash
export DEFAULT_ISTIO_NAMESPACE=istio-demos

kubectl delete deployment redis-master -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service redis-master -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment redis-slave -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service redis-slave -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment -l app=guestbook -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service -l app=guestbook -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete gateway guestbook-gateway -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete virtualservice guestbook -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete destinationrules guestbook -n $DEFAULT_ISTIO_NAMESPACE
