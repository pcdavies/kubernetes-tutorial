#!/bin/bash

kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
kubectl get pods

NAMESPACE=default

export PATH=~/istio-1.0.4/bin:$PATH
export SCRIPTDIR=~/istio-1.0.4/samples/bookinfo/platform/kube/

echo "using NAMESPACE=${NAMESPACE}"

protos=( destinationrules virtualservices gateways )
for proto in "${protos[@]}"; do
  for resource in $(istioctl get -n ${NAMESPACE} $proto | awk 'NR>1{print $1}'); do
    istioctl delete -n ${NAMESPACE} $proto $resource;
  done
done
#istioctl delete mixer-rule ratings-ratelimit

export OUTPUT=$(mktemp)
echo "Application cleanup may take up to one minute"
kubectl delete -n ${NAMESPACE} -f $SCRIPTDIR/bookinfo.yaml > ${OUTPUT} 2>&1
ret=$?
function cleanup() {
  rm -f ${OUTPUT}
}

trap cleanup EXIT

if [[ ${ret} -eq 0 ]];then
  cat ${OUTPUT}
else
  # ignore NotFound errors
  OUT2=$(grep -v NotFound ${OUTPUT})
  if [[ ! -z ${OUT2} ]];then
    cat ${OUTPUT}
    exit ${ret}
  fi
fi

echo "Application cleanup successful"

echo 'Wait for 5 seconds'

sleep 5

echo 'Check to see if all removed:'

kubectl get pods
kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
