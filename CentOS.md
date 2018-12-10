# kubernetes-tutorial
In this tutorial we will install 2 VM Images. One will server as the Kubernetes master, and the other a Kubernetes Node. We'll configure Docker and Kubernetes on both Images. 

## Install the Master and Node 

### Download and setup CentOS 7
 - Download the DVD ISO from [CentOS Download Center](https://www.centos.org/download/)

 - Create a `k8master` and `k8node`

 - Start terminal windows

 - `sudo su`

 - set hostnames to `k8master` and `k8node` - use: 
 
    ```
    sudo set-hostname k8master
    ``` 

- Turn off Swap

    ```
    setenforce 0
    sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    swapoff -a
    ```

- Comment out the swap in fstab 

    ```
    vi /etc/fstab
    ```

- Turn off the firewall

    ```
    systemctl stop firewalld
    systemctl disable firewalld
    ```

- Allow Bridge/internet access over nat

    ```
    modprobe br_netfilter
    echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
    ```

- Make permanent but editing sysctl.conf

    ```
    vi /etc/sysctl.conf
    ```

- Add this to the bottom of the file and save:

    ```
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    ```

- End the host file in both images and add entries for `k8master` and `k8node`

- Setup yum to install kubernetes:

    ```
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    EOF
    ```

- Run yum to install kubernetes and docker:

    ```
    yum install -y kubelet kubeadm kubectl docker -y
    ```

- Update the kubernetes config file:

    ```
    sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    ```

- Enable docker and kubernetes

    ```
    systemctl enable docker && systemctl enable kubelet
    systemctl start docker && systemctl start kubelet
    ```

- ***Reboot***

### **Master only** install

- Setup Kubernetes

    ```
    sudo su
    kubeadm init --pod-network-cidr=10.244.0.0/16 -apiserver-advertise-address=REPLACE-WITH-YOUR-IP-ADDRESS
    ```

- **Copy the Join** message and store locall for later use

- Exit to **$** / kubeuser / non sudo user

    ```
    exit
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

- Wait for all to load

    ```
    kubectl get pods -o wide --all-namespaces
    ```

- Go to **Step 9** in the README.md file and continue with the Flannel install






