# kubernetes-tutorial
Test tutorial

## Install the Master and Minion 
### Download Ubuntu 18.0.4 Desktop ISO

- From this URL [Ubuntu Destop Downloads](https://www.ubuntu.com/download/desktop), get the iso image
- Select the latest (LTM) image. I'm using 18.04.1 LTS

    ![](images/img-01.png)

- Select the Latest (LTS) 

### **Step 1**: Create a Virtual Box **kmaster** node/image

- Load VirtualBox and click on **New**

    ![](images/img02.png)

- Enter the following, and click on **Commit**:
    - Name: `kubernetes`
    - Type: `Linux`
    - Version: `Ubuntu (64-bit)`
    - Hard disk: **Create a virtual hard disk now**

    ![](images/img03.png)

- Enter the following Disk Information and click on **Commit**
    - File Location: `kmaster`
    - File Size: `30GB`
    - Hard disk file type: `VDI (VirtualBox Disk Image)

    ![](images/img04.png)

- With **kmaster** selected, click on **settings**

    ![](images/img05.png)

- Update the System Settings:
    - Select **System** and **Processor**
    - Set the number of CPUs to at least `2`

    ![](images/img06.png)

- Add a second network
    - Click on **Network** and **Adapter 2** in the tool bar
    - Click on **Enable Network Adapter**
    - For Attached to, select **Host-only Adapter**
    - Click on **OK**

    ![](images/img07.png)

- Attach the Ubuntu ISO
    - Click on the **Storage** menu option
    - Click on the **Empty** icon below the IDE Controller
    - Click on the **Optical Drive** CD Icon
    - Select **Choose Virtual Optical Disk Drive** from the drop down menu

    ![](images/img08.png)

- Navigate to and select the ubuntu iso you downloaded. Click on **OK**

    ![](images/img09.png)

- Click on **Start** to start the kmaster image

    ![](images/img10.png)

### **Step 2**: Install Ubuntu

- Once the image starts, click on **Install Ubuntu**

    ![](images/img11.png)

- Select your keyboard layout and click on Continue
- I selected the **Minimal installation**, but the normal installation will also work
- Click on Continue

    ![](images/img12.png)

- Keep the **Erase disk and install Ubuntu** defaults, and click on **Install Now**

    ![](images/img13.png)

- Click on **Continue** when asked about Writing changes to disk.
- Select your timezone
- Configure the username and hostname:
    - Your Name: `kubeuser`
    - Your Computer: `kmaster`
    - Pick a username: `kubeuser`
    - I selected **Log in automatically**

    ![](images/img14.png)

- When prompted, click on **Restart Now**

- When prompted with **Please remove the installation medium, then press ENTER:**, press the **Enter Key** in the image. Note: you can generally just press enter, as VBox will have automatically removed the ubuntu ISO during the installation process. If not, you can remove it using the **Settings**


### **Step 3**: Create a **knode** Ubuntu image

- Repeat **Steps 1 and 2** to create a kubernetes slave image, with the following **modifications**:
    - Changes any references of `kmaster` to `knode` 
    - Set the RAM to 3GB

- You should now have both the **kmaster** and **knode** images running:

    ![](images/img15.png)

    ![](images/img16.png)

- If is a good idea to install the VBox tools

    ![](images/img37.png)

    ![](images/img38.png)

- Reboot your images for VBox tools to work

- On both images, you may want to share the clipboard to allow for command copy and paste:

    ![](images/img17.png)


### **Step 4**: Perform package installations on **BOTH** images

- The following tasks are to be **run on both** the master and node images:

- Login as 'sudo' and run the following commands :

    ```
    sudo su
    apt-get update
    ```

    ![](images/img18.png)

- Kubernetes will throw errors if the swap space is not turned off. The following commands will turn swap off (Still as sudo user):

    ```
    swapoff -a
    nano /etc/fstab
    ```

- Comment out the line that references the **swapfile**. Then hit **Ctrl+X**, press **Y** and hit **Enter** to save the file.

    ![](images/img19.png)

- As sudo, check to ensure that the host file contains `kmaster` and `knode` on the respective images

    ```
    nano /etc/hostname
    ```

    ![](images/img20.png)

- As sudo, install net-tools

    ```
    apt-get install net-tools
    ```

    ![](images/img21.png)

- As sudo, on each image run ifconfig, and note the **network name and ip address** for the Host only network adapter for both kmaster and knode

    ```
    ifconfig
    ```

    In my example, here is **KMASTER**:

    ![](images/img22.png)

    Here is **KNODE**:

    ![](images/img23.png)

- As sudo, set the host file in both images to reference the **kmaster** and **knode** ip addresses

    ```
    nano /etc/hosts
    ```

    ![](images/img24.png)

- As sudo, install open ssh server

    ```
    apt-get install openssh-server
    ```

    ![](images/img25.png)

### **Step 5**: Install Docker on **BOTH** images

- As sudo, run the following commands to install docker

    ```
    sudo su
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker.service
    ```

### **Step 6**: Install Kubernetes on **BOTH** images

- As sudo, run the following command to install kubernetes

    ```
    apt-get update && apt-get install -y apt-transport-https curl

    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
    EOF

    apt-get update
    ```

- As sudo, install **Kubelet, kubeadmn, and kubectl**

    ```
    apt-get install -y kubelet kubeadm kubectl 
    ```

- Update the Kubernetes config file

    ```
    nano /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    ```

- Add the following **Environment** entry to the config file

    ```
    Environment="cgroup-driver=systemd/cgroup-driver=cgroupfs"
    ```

    ![](images/img26.png)

- At this point, I'd recommend shuting down each image, taking a snapshot, and restarting

### **Step 6**: Configure Kubernetes Master - Run **ONLY on kmaster** image

- Start the kubernetes cluster. **Note**: We will be using a Flannel network, so we are using 10.244.0.0/16 for the pod-network-cidr. **Replace \<ip-address-of-kmaster-vm\>** with your kmaster's host address. In our example that is 192.168.99.100

    ```
    kubeadm init --apiserver-advertise-address=<ip-address-of-kmaster-vm> --pod-network-cidr=10.244.0.0/16
    ```

    ![](images/img27.png)

- When the kubeadm init command completes, copy the **kubeadm join** command and save it, as this command will later be used to join **knode** to the cluster

    ![](images/img28.png)

- You will **NOT** run the next command from the sudo user **#** promot, so ensure that you exit the sudo user and the **$** prompt is visible

    ![](images/img30.png)

    ```
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

    ![](images/img31.png)

- Ensure that kubectl is working

    ```
    kubectl get pods -o wide --all-namespaces
    ```

    ![](images/img32.png)

- Notice that not all pods are working. We will resolve this by installing the pod network. In our example we are going to use a **Flannel** network. 

    ```
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    ```

    ![](images/img33.png)

- Now that the flannel network is install, you shoudl see that the **coredns...** pods are now in a **running** status

    ```
    kubectl get pods -o wide --all-namespaces
    ```

    ![](images/img34.png)

    ```
    kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
    ```
    ![](images/img35.png)

    ```
    kubectl proxy
    ```

    ![](images/img36.png)

    ```
    kubectl create serviceaccount dashboard -n default
    ```

    ![](images/img39.png)

    ```
    kubectl create clusterrolebinding dashboard-admin -n default \
    --clusterrole=cluster-admin \
    --serviceaccount=default:dashboard
    ```

    ![](images/img40.png)

    ```
    kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode
    ```

    ![](images/img41.png)

    ![](images/img42.png)

    ![](images/img43.png)

- Holder

### **Step xxx**: Join other image

- Holder
    
    ```
    sudo su
    < use the kubeadmin join command you coppied earlier for example: >
    kubeadm join 192.168.99.100:6443 --token 7f8vt2.axlyzylzkj6m66cq --discovery-token-ca-cert-hash sha256:6d6ef81f7053fafdef1c585c1ab27f7bc1de389b756cfead18587b81f6abaf25
    ```
    
### back on the master

- Holder

    ```
    kubectl get nodes
    ```

    ![](images/img44.png)

### Install a pod

- Holder

    ```
    kubectl run --image=nginx nginx-server --port=80 --env="DOMAIN=cluster"
    kubectl expose deployment nginx-server --port=80 --name=nginx-http
    ```

- run until ready

    ```
    kubectl get pods -o wide --all-namespaces
    ```

    ![](images/img45.png)
