#!/usr/bin/env bash

kubectl delete deployment -l app=redis
kubectl delete service -l app=redis
kubectl delete deployment -l app=guestbook
kubectl delete service -l app=guestbook
kubectl delete ingress frontend-ingress

