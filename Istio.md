# Istio Install and Config

***Note:*** Istio can be installed from anywhere that has Helm, Kubectl and access to the cluster. For this example, connect into the **kmaster** image and run the install from that image. Istio will be installed onto the **knode** in the cluster

### **Step 1**: On the **kmaster** image Download and install

- Instructions below are found on the [Istio Website](https://istio.io/docs/)

- Download Kubernetes Release

    Run all commands a the **$** prompt:
    ```
    curl -L https://git.io/getLatestIstio | sh -

    cd ist*
    ```

- Add the path of your current directory to your .bashrc, and source that file

    Run all commands a the **$** prompt:
    ```
    echo 'export PATH=/home/kubeuser/istio-1.0.4/bin:$PATH' >> ~/.bashrc

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

- Test the application - you should see are **200** return code

    Run all commands a the **$** prompt:
    ```
    curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
    ```
- Add destination Rules

    Run all commands a the **$** prompt:
    ```
    kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    ```
- Wait a minute or two

- See if it works in your browser. Use the URL provided in `$GATEWAY_URL` and append `/productpage` - For example:

    ```
    http://192.168.168.171:31380/productpage
    ```