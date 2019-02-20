#!/bin/bash

if [ "$ISTIO_DIR" = "" ]; then
    echo 'ISTIO_DIR environment is not set. Example: /home/kubeuser/istio-1.0.5'
    exit
fi

kubectl get services -n $DEFAULT_ISTIO_NAMESPACE
kubectl get virtualservices -n $DEFAULT_ISTIO_NAMESPACE
kubectl get destinationrules -n $DEFAULT_ISTIO_NAMESPACE
kubectl get gateway -n $DEFAULT_ISTIO_NAMESPACE
kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE

export PATH=$ISTIO_DIR/bin:$PATH
export SCRIPTDIR=$ISTIO_DIR/samples/bookinfo/platform/kube/

echo "using NAMESPACE=${DEFAULT_ISTIO_NAMESPACE}"

protos=( destinationrules virtualservices gateways serviceentries)
for proto in "${protos[@]}"; do
  for resource in $(istioctl get -n ${DEFAULT_ISTIO_NAMESPACE} $proto | awk 'NR>1{print $1}'); do
    istioctl delete -n ${DEFAULT_ISTIO_NAMESPACE} $proto $resource;
  done
done
#istioctl delete mixer-rule ratings-ratelimit

export OUTPUT=$(mktemp)
echo "Application cleanup may take up to one minute"
kubectl delete -n ${DEFAULT_ISTIO_NAMESPACE} -f $SCRIPTDIR/bookinfo.yaml > ${OUTPUT} 2>&1
ret=$?
function cleanup() {
  rm -f ${OUTPUT}
}

kubectl delete service ratings -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service reviews -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service details -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service mongodb -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service mysqldb -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service mysqldb -n=vm
kubectl delete service productpage -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service ratings -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service sleep -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete service httpbin -n $DEFAULT_ISTIO_NAMESPACE

kubectl delete deployment httpbin-v1 -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment httpbin-v2 -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment sleep -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment nginx-server -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment mongodb-v1 -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment mysqldb-v1 -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment ratings-v2 -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment ratings-v2-mysql -n $DEFAULT_ISTIO_NAMESPACE
kubectl delete deployment ratings-v2-mysql-vm -n $DEFAULT_ISTIO_NAMESPACE

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

kubectl get virtualservices -n $DEFAULT_ISTIO_NAMESPACE
kubectl get destinationrules -n $DEFAULT_ISTIO_NAMESPACE
kubectl get gateway -n $DEFAULT_ISTIO_NAMESPACE
kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
while [ $(kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE | grep -E 'ratings|reviews|productpage|httpbin|sleep|nginx-server|sleep|mongodb|mysql|NAME' | wc -l) -gt 1 ]; do
  kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
  echo 'Sleeping until deleted...'
  sleep 8
done

kubectl get pods -n $DEFAULT_ISTIO_NAMESPACE
