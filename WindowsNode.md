# Setup the Windows Node


### **Step 1**: Join knode **(Windows)** to kmaster

- Follow these instructions **Joining the Windows Node**

    ```
    https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/joining-windows-workers
    ```

- Get Service Subnet/CIDR:

    ```
    kubectl cluster-info dump | grep -i service-cluster-ip-range
    ```

- Get Kube DNS

    ```
    kubectl get svc/kube-dns -n kube-system
    ```

- Using the correct Addresses discovered earlier, run this:

    ```
    cd c:\k
    
    .\start.ps1 -ManagementIP <Windows Node IP> -ClusterCIDR <Cluster CIDR> -ServiceCIDR <Service CIDR> -KubeDnsServiceIP <Kube-dns Service IP>
    ```

    ```
    cd c:\k
    
    .\start.ps1 -ManagementIP 172.31.0.35:6443 -ClusterCIDR 10.244.0.0/16 -ServiceCIDR 10.96.0.0/12 -KubeDnsServiceIP 10.96.0.10
    ```