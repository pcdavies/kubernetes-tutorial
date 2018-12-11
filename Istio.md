# Istio Install and Config

### **Step 1**: Download and install

- Instructions below are found on the [Istio Website](https://istio.io/docs/)

- Download Kubernetes Release

    ```
    $ curl -L https://git.io/getLatestIstio | sh -

    $ cd ist*
    ```

- Add the path of your current directory to your .bashrc, and source that file

    ```
    $ echo 'export PATH=/home/kubeuser/istio-1.0.4/bin:$PATH' >> ~/.bashrc

    $ . ~/.bashrc

    $ echo $PATH
    ```

### **Step 2**: Install Helm Client

- Download and install client from a script

    ```
    $ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh

    $ chmod 700 get_helm.sh

    $ ./get_helm.sh

    $ helm init
    ```
### **Step 3**: Install Istio with Helm Template

- Render Istio's core componentes to a Kubernetes Manifest

    ```
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
    ```

- Install using the manifest

    ```
    $ kubectl create namespace istio-system

    $ kubectl apply -f $HOME/istio.yaml
    ```

- Verify Install

    ```
    $ kubectl get svc -n istio-system

    $ kubectl get pods -n istio-system -o wide
    ```

- Wait for **Running** and **Completed** status

### **Step 4**: Deploy the booking application

- The instructions can be found [Here](https://istio.io/docs/examples/bookinfo/)

- Since "Automatic Sidecar Injection" is possible, use this option

    ```
    $ kubectl label namespace default istio-injection=enabled

    $ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    ```

    ```
    $ kubectl get services

    $ kubectl get pods
    ```

- Set ingress gateway for applications

    ```
    $ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    ```

- Check Gateway

    ```
    $ kubectl get gateway
    ```

- Determine IP and Port

    ```
    $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

    $ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')

    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    ```

- View IP and Port

    ```
    $ echo $GATEWAY_URL
    ```

- Test the application - you should see are **200** return code

    ```
    $ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
    ```
- Add destination Rules

    ```
    $ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    ```
