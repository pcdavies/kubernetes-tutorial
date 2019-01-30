#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

kubectl get services
kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
kubectl get pods

NAMESPACE=default

export PATH=$ISTIO_DIR/bin:$PATH
export SCRIPTDIR=$ISTIO_DIR/samples/bookinfo/platform/kube/

echo "using NAMESPACE=${NAMESPACE}"

protos=( destinationrules virtualservices gateways serviceentries)
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

kubectl delete services ratings
kubectl delete services reviews
kubectl delete services details
kubectl delete services mongodb
kubectl delete services mysqldb
kubectl delete services productpage
kubectl delete services ratings

kubectl delete deployment httpbin-v1
kubectl delete deployment httpbin-v2
kubectl delete deployment sleep
kubectl delete deployment nginx-server
kubectl delete deployment mongodb-v1
kubectl delete deployment mysqldb-v1
kubectl delete deployment ratings-v2
kubectl delete deployment ratings-v2-mysql

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

kubectl get virtualservices
kubectl get destinationrules
kubectl get gateway
kubectl get pods
while [ $(kubectl get pods | grep -E 'ratings|reviews|productpage|httpbin|sleep|nginx-server|sleep|mongodb|mysql|NAME' | wc -l) -gt 1 ]; do
  kubectl get pods
  echo 'Sleeping until deleted...'
  sleep 8
done

kubectl get pods
