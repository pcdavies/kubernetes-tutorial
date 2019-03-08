# port forward kiali
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001 &

# port forward grafana
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &

# port forward prometheus
kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &

# Service Graph
istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &

# use these URLs:
echo 'URL for Kiali: http://[::1]:20001'
echo 'URL for Product Demo: http://192.168.168.167:31380/productpage'
echo 'URL for Mesh Dashboard: http://[::1]:3000/dashboard/db/istio-mesh-dashboard'
echo 'URL for Mesh Dashboard: http://localhost:3000/dashboard/db/istio-workload-dashboard'
# echo 'URL for Jager - not working: http://[::1]:16686'
echo 'URL for service graph: http://localhost:8088/force/forcegraph.html'

echo ' '
echo 'Also loading kubectl proxy'
echo ' '
kubectl proxy &
