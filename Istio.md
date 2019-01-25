# Istio Install and Config

***Note:*** Istio can be installed from anywhere that has Helm, Kubectl and access to the cluster. For this example, connect into the **kmaster** image and run the install from that image. Istio will be installed onto the **knode** in the cluster

### **Step 0**: ***If running Windows*** on the cluster, follow instructions below:

- Taint the windows node so that istio will not attempt to install on the Windows node. ***NOTE***: Replace the Node Name **UseYourWindowsNodeName** with the name of the windows node. Note: **NoSchedule** will not put pods on the node unless the Deployment is **Tolerant** to the **Taint**. **NoExecute** would try to remove anything on the node currently running. You can remove a taint the command: `kubectl taint nodes UseYourWindowsNodeName my-taint-`

    ```
    kubectl taint nodes UseYourWindowsNodeName opsys-taint=windows:NoSchedule
    ```

- We will also create a Namespace on which we will deploy thing that is meant to go on the Windows node. Although we will specify in the deployment when deploying on a Windows node, we are going to set up the **default** namespace to install a side-car with every deployment, and Windows does not support side-cars. 

    ```
    kubectl create namespace windows
    ```

### **Step 1**: On the **kmaster** image Download and install

- Instructions below are found on the [Istio Website](https://istio.io/docs/)

- Download Kubernetes Release

    Run all commands a the **$** prompt:
    ```
    curl -L https://git.io/getLatestIstio | sh -

    cd ist*
    ```

- Add the path of your current directory to your .bashrc, and source that file ***Note***: The version (e.g. 1.0.5) shown below might not be correct - you ***MUST*** set the right verion for your path

    Run all commands a the **$** prompt:
    ```
    echo 'export PATH=$HOME/istio-1.0.5/bin:$PATH' >> ~/.bashrc

    . ~/.bashrc

    echo $PATH
    ```

### **Step 2**: Install Helm Client

- Download and install client from a script

    Run all commands a the **$** prompt:
    ```
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh

    chmod 700 get_helm.sh

    ./get_helm.sh

    helm init
    ```
### **Step 3**: Install Istio with Helm Template

- Render Istio's core componentes to a Kubernetes Manifest

    Run all commands a the **$** prompt:
    ```
    helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
    ```

- Install using the manifest

    Run all commands a the **$** prompt:
    ```
    kubectl create namespace istio-system

    kubectl apply -f $HOME/istio.yaml
    ```

- Verify Install

    Run all commands a the **$** prompt:
    ```
    kubectl get svc -n istio-system

    kubectl get pods -n istio-system -o wide
    ```

- Wait for **Running** and **Completed** status

### **Step 4**: Deploy the booking application

- The instructions can be found [Here](https://istio.io/docs/examples/bookinfo/)

- Since "Automatic Sidecar Injection" is possible, use this option

    Run all commands a the **$** prompt:
    ```
    kubectl label namespace default istio-injection=enabled

    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    ```

    Run all commands a the **$** prompt:
    ```
    kubectl get services

    kubectl get pods
    ```

- Set ingress gateway for applications

    Run all commands a the **$** prompt:
    ```
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    ```

- Check Gateway

    Run all commands a the **$** prompt:
    ```
    kubectl get gateway
    ```

- Determine IP and Port

    Run all commands a the **$** prompt:
    ```
    export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

    export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

    export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')

    export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    ```

- View IP and Port

    Run all commands a the **$** prompt:
    ```
    echo $GATEWAY_URL
    ```

- Wait until all pods are **Running**

- Add destination Rules

    Run all commands a the **$** prompt:
    ```
    kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    ```
- Test the application - you should see are **200** return code

    Run all commands a the **$** prompt:
    ```
    curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
    ```
    
- See if it works in your browser. Use the URL provided in `$GATEWAY_URL` and append `/productpage` - For example:

    ```
    http://192.168.168.171:31380/productpage
    ```

### **Step 5**: How to undeploy the Booking Application

- Display what will be removed

    ```
    kubectl get virtualservices
    kubectl get destinationrules
    kubectl get gateway
    kubectl get pods
    ```

- Run the script to delete the services - ***Run from istio directory***

    ```
    samples/bookinfo/platform/kube/cleanup.sh
    ```

- Make sure everythign was removed

    ```
    kubectl get virtualservices   #-- there should be no virtual services
    kubectl get destinationrules  #-- there should be no destination rules
    kubectl get gateway           #-- there should be no gateway
    kubectl get pods               #-- the Bookinfo pods should be deleted
    ```

## Installing Monitoring Tools

In these steps we will get Grafana, Tracing and Kiali running

### ***Step 6***: install Grafana

- Change to the ISTIO install director - e.g. `cd $HOME/istio-*`
- Using helm, add grafana to the istio.yaml, and then apply that yaml file:

    ```
    helm template --set grafana.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml

    kubectl apply -f $HOME/istio.yaml
    ```

- Look at the Pods and wait for **grafana-....** to show a running state

    ```
    kubectl get pods -n=istio-system
    ```
### ***Step 7***: install Tracing

- Using helm add Tracing to the istio.yaml and apply

    ```
    helm template --set tracing.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml

    kubectl apply -f $HOME/istio.yaml
    ```

- run get pods and look for **istio-tracing-....**

    ```
    kubectl get pods -n=istio-system
    ```

### ***Step 8***: Install Kiali

- Populate environment variables with the username and password for Kiali

    ```
    KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)

    KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)
    ```

- Create the Secret

    ```
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

    ```

- Using helm add Kiali to the istio.yaml and apply

    ```
    helm template --set kiali.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml

    kubectl apply -f $HOME/istio.yaml
    ```

- run get pods and look for **kiali....** and wait until it's **Running**

    ```
    kubectl get pods -n=istio-system
    ```

- Set some of the Kiali dashboard endpoints

    ```
    helm template \
        --set kiali.enabled=true \
        --set "kiali.dashboard.jaegerURL=http://$(kubectl get svc tracing -n=istio-system -o jsonpath='{.spec.clusterIP}'):80" \
        --set "kiali.dashboard.grafanaURL=http://$(kubectl get svc grafana -n=istio-system -o jsonpath='{.spec.clusterIP}'):3000" \
        install/kubernetes/helm/istio \
        --name istio --namespace istio-system > $HOME/istio.yaml

    kubectl apply -f $HOME/istio.yaml
    ```

### ***Step 9***: Install Service Graph

- Using helm add Service Graph to the istio.yaml and apply

    ```
    helm template --set servicegraph.enabled=true install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml

    kubectl apply -f $HOME/istio.yaml
    ```

- run get pods and look for **servicegraph-....**

    ```
    kubectl get pods -n=istio-system
    ```

### ***Step 10***: set up the port forwarding

You will run this from a host on which you have kubectl running. Wait for all these deployed pods to show a running state 

- Port forward Kiali

    ```
    kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001 &

    ```

- Port forward Grafana

    ```
    kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &

    ```

- Port forward Prometheus (note: Prometheus was loaded with the intial install)

    ```
    kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &

    ```

- Port forward the Service Graph

    ```
    kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
    ```

### URLs to access each of the applications:

- Go to these URLs
    ```
    # Kiali

    http://[::1]:20001

    # Grafana

    http://localhost:3000/d/1/istio-mesh-dashboard
    http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard

    # Prometheus

    http://localhost:9090/graph?g0.range_input=1h&g0.expr=istio_requests_total%7Bdestination_service%3D%22productpage.default.svc.cluster.local%22%7D&g0.tab=1

    # Service Graph

    http://localhost:8088/force/forcegraph.html

    ```


### ***Step 12***: Stop port forwarding

- When ready to stop port forwarding, run the kill all command

    ```
    killall kubectl
    ```