# install grafana and wait
helm template --set grafana.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl apply -f $HOME/istio.yaml

# install trace jager 

helm template --set tracing.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl apply -f $HOME/istio.yaml

KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)
KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF

helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
kubectl apply -f $HOME/istio.yaml


helm template \
    --set kiali.enabled=true \
    --set "kiali.dashboard.jaegerURL=http://$(kubectl get svc tracing -n=istio-system -o jsonpath='{.spec.clusterIP}'):80" \
    --set "kiali.dashboard.grafanaURL=http://$(kubectl get svc grafana -n=istio-system -o jsonpath='{.spec.clusterIP}'):3000" \
    install/kubernetes/helm/istio \
    --name istio --namespace istio-system > $HOME/istio.yaml

kubectl apply -f $HOME/istio.yaml


# use this as the URL:

http://[::1]:20001

# other urls:

http://192.168.168.167:31380/productpage

# Prometheus
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
http://localhost:9090/graph

# grafana
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &

http://[::1]:3000/dashboard/db/istio-mesh-dashboard
http://localhost:3000/dashboard/db/istio-workload-dashboard

# Tracing

kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &

http://[::1]:16686




