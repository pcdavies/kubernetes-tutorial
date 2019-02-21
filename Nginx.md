# Installing Nginx

Note: The following example configuration for Nginx came from [this article by Alan Komljen](https://akomljen.com/kubernetes-nginx-ingress-controller/)

## Create Sample Applications

### ***Step 1***: Create Namespace

Although not required, we are going to create a namespace **nginx** for all applications we create in this example. We'll also create a namespace **ingress** to hold the nginx pods. If you also installed istio following the documentation in this repository, the **default** namespace will be setup to auto install a sidecar for istio. To avoid the sidecar installation for Nginx, we'll use different namespaces. 

- Use the command below to set the **DEFAULT_NAMESPACE** environment varibable used when deployment the sample applications. 

    ```
    export DEFAULT_NAMESPACE=nginx
    ```

- Create the namespaces

    ```
    kubectl create namespace $DEFAULT_NAMESPACE

    kubectl create namespace ingress
    ``` 

- Create the default **App1** and **App2** Deployments

```yaml
kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app1
        ports:
        - containerPort: 80
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: dockersamples/static-site
        env:
        - name: AUTHOR
          value: app2
        ports:
        - containerPort: 80
EOF

```

- Create the App Services

```yaml
kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: appsvc1
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app1
---
apiVersion: v1
kind: Service
metadata:
  name: appsvc2
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
EOF
```

- Ingress for Apps1/2

```yaml
kubectl apply -n $DEFAULT_NAMESPACE -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: app-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: appsvc1
          servicePort: 80
        path: /app1
      - backend:
          serviceName: appsvc2
          servicePort: 80
        path: /app2
EOF
```

### ***Step 2***: Create the default backend that will return errors when needed

- Create the **backend** deployment

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-backend
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: default-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-backend
        image: gcr.io/google_containers/defaultbackend:1.0
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
EOF
```

- Create the **backend** Service

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: default-backend
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: default-backend
EOF
```

### **Step 3**: Create the nginx ConfigMap and RBAC

- ConfigMap

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-controller-conf
  labels:
    app: nginx-ingress-lb
data:
  enable-vts-status: 'true'
EOF
```

- ClusterRole and ClusterRoleBinding

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: nginx-role
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - nodes
  - pods
  - secrets
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - update
  - watch
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - extensions
  resources:
  - ingresses/status
  verbs:
  - update
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: nginx-role
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-role
subjects:
- kind: ServiceAccount
  name: nginx
  namespace: ingress
EOF
```

### **Step 4**: Create the Nginx controller

- Nginx Ingress Controller

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
spec:
  replicas: 2
  revisionHistoryLimit: 3
  template:
    metadata:
      labels:
        app: nginx-ingress-lb
    spec:
      terminationGracePeriodSeconds: 60
      serviceAccount: nginx
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.9.0
          imagePullPolicy: Always
          readinessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
          livenessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            timeoutSeconds: 5
          args:
            - /nginx-ingress-controller
            - --default-backend-service=\$(POD_NAMESPACE)/default-backend
            - --configmap=\$(POD_NAMESPACE)/nginx-ingress-controller-conf
            - --v=2
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - containerPort: 80
            - containerPort: 18080
EOF
```

- Ingress for nginx

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: nginx-ingress
          servicePort: 18080
        path: /nginx_status
EOF
```

### **Step 5**: Create the Ingress and Service

- Nginx Ingress Service

```yaml
kubectl apply -n ingress -f -<<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: 30000
      name: http
    - port: 18080
      nodePort: 32000
      name: http-mgmt
  selector:
    app: nginx-ingress-lb
EOF
```

- Configure Port Forwarding

    If running on VBox or Vmware Fusion, you'll need to set up port forwarding so traffic for 30000 and 32000 is routed into the appropriate VM image. 

    Also, set up the host file to route test.example.com to 127.0.0.1

    You can now access these URLs:

    ```
    http://test.example.com:30000/app1
    http://test.example.com:30000/app2
    http://test.example.com:32000/nginx_status
    ```

### **Step 6**: Optional Configure Windows IIS Server and access from Nginx

Note: This example assumes that you are running Windows 1809/2019 and you have tained the Windows node as documented in the Windows Node configuration section of this documentation

- Create a windows namespace to hold all windows Pods

    ```
    kubectl create namespace windows
    ```

- Deploy Windows IIS Server

```yaml
kubectl apply -n windows -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      containers:
      - name: iis
        image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019
        resources:
          limits:
            memory: "128Mi"
            cpu: 2
        ports:
        - containerPort: 80
      nodeSelector:
        beta.kubernetes.io/os: windows
      tolerations:
      - key: "opsys-taint"
        operator: Equal
        value: "windows"
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: iis
  name: iis-svc
spec:
  type: NodePort
  ports:
    - port: 80
  selector:
    app: iis
EOF
```

- Create the Access to the Service from Nginx

```yaml
kubectl apply -n windows -f -<<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: iis-ingress
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - backend:
          serviceName: iis-svc
          servicePort: 80
        path: /iis
EOF
```

- You can access the IIS server from this url - note the trailing backslash `\` 

    ```
    http://test.example.com/iis/
    ```