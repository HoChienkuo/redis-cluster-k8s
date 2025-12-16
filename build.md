# Windows 10 部署 Redis Cluster集群 + K8s

## 第一阶段：环境准备和配置

**确认你的环境：**

```
D:\virtualBox
D:\vagrant
D:\box\focal-server-cloudimg-amd64-vagrant.box
```

[Vagrant Box下载地址](https://mirror.sjtu.edu.cn/ubuntu-cloud-images/focal/current/)
[Vagrant的安装配置虚拟机超详细教程以及不安装在C盘的配置，配合VirtualBox使用](https://blog.csdn.net/qiujicai/article/details/140008635)

**设置环境变量（以管理员身份运行PowerShell）：**

```powershell
# 设置VirtualBox安装路径（如果未自动设置）
[Environment]::SetEnvironmentVariable("VBOX_INSTALL_PATH", "D:\virtualBox", "Machine")
[Environment]::SetEnvironmentVariable("VBOX_MSI_INSTALL_PATH", "D:\virtualBox", "Machine")
$env:Path += ";D:\virtualBox"

# 验证VirtualBox安装
VBoxManage --version
# 验证Vagrant安装
vagrant version
```

**配置vagrant**

1. 将本地 Box 文件添加到 Vagrant
    ```powershell
    vagrant box add my-ubuntu ./focal-server-cloudimg-amd64-vagrant.box
    ```
   验证是否添加成功
    ```powershell
    vagrant box list
    ```
2. 当前目录编辑Vagrantfile
3. 启动虚拟机
    ```powershell
    vagrant up
    ```

**配置K8s相关**

1. 登录Master节点执行K8s安装脚本setup-k8s-master.sh
    ```powershell
    # 从你的Windows主机，复制脚本到master虚拟机
    vagrant upload setup-k8s-master.sh /home/vagrant/ master

    # 登录master节点
    vagrant ssh master
    ```
    ```shell
    # 在master节点的SSH会话中，执行脚本
    cd /home/vagrant
    chmod +x setup-k8s-master.sh
    sudo ./setup-k8s-master.sh
    ```
2. 查看加入命令
    ```shell
    cat /home/vagrant/join-command.sh
    ```
3. 分别登录node节点执行K8s安装脚本setup-k8s-node.sh
    ```powershell
    # 从你的Windows主机，复制脚本到node虚拟机
    vagrant upload setup-k8s-node.sh /home/vagrant/ node1
    vagrant upload setup-k8s-node.sh /home/vagrant/ node2

    # 登录master节点
    vagrant ssh node1
    vagrant ssh node2
    ```
    ```shell
    cd /home/vagrant
    chmod +x setup-k8s-node.sh
    sudo ./setup-k8s-node.sh
    ```
4. 配置国内镜像源
    ```shell
    # /etc/containerd/config.toml
    sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.6"
   
    sudo systemctl restart containerd
    sudo systemctl restart kubelet
    ```

**安装Helm**

1. 进入control节点
    ```shell
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    # 验证安装
    helm version
   
    helm repo add stable https://charts.helm.sh/stable
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    ```

**安装Redis operator**

```shell
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
helm upgrade redis-operator ot-helm/redis-operator \
  --install --create-namespace --namespace redis-system

# 验证安装
kubectl get pod -n redis-system
```

创建secret

```shell
kubectl create secret generic redis-secret --from-literal=password=uestc@2025 -n redis-system
```

部署redis主从副本(哨兵)集群

```shell
 kubectl apply -f redis-sentinel.yaml 
```

**创建监控指标**

1. 安装Metrics Server
    ```shell
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    ```
2. 安装Prometheus(可选)
    ```shell
    # 使用Helm安装Prometheus Stack
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm install prometheus prometheus-community/kube-prometheus-stack
    ```
3. 创建自动伸缩策略
    ```shell
    kubectl apply -f redis-hpa-autoscale.yaml
    ```

**压测**
使用redis-benchmark进行压测
```shell
# 创建临时的benchmark pod

kubectl run redis-benchmark --image=registry.cn-hangzhou.aliyuncs.com/docker_mirror/redis:alpine --rm -it --restart=Never -- \
sh -c "apk add --no-cache curl && redis-benchmark -h redis-replication -p 6379 -c 50 -n 100000 -t set,get,lpush,lpop"

# 在另一个终端监控

watch -n 2 "kubectl get hpa -n redis-system && echo && kubectl get pods -l app=redis-replication -n redis-system"
```

## 问题排查

1. kubeadm init 失败
    ```shell
    cat > /etc/crictl.yaml <<EOF
    runtime-endpoint: unix:///var/run/containerd/containerd.sock
    image-endpoint: unix:///var/run/containerd/containerd.sock
    timeout: 0
    debug: false
    pull-image-on-create: false
    EOF
    ```
   执行clean-k8s.sh

2. /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
    ```shell
    # 1. 加载 br_netfilter 模块（关键！）
    sudo modprobe br_netfilter

    # 2. 加载 overlay 模块（也需要）
    sudo modprobe overlay

    # 3. 验证模块是否加载成功
    lsmod | grep -E "br_netfilter|overlay"

    # 4. 设置开机自动加载
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    br_netfilter
    overlay
    EOF
    ```
    ```shell
    # 1. 创建网络配置
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward = 1
    EOF

    # 2. 应用配置
    sudo sysctl --system

    # 3. 验证配置是否生效
    cat /proc/sys/net/bridge/bridge-nf-call-iptables
    cat /proc/sys/net/ipv4/ip_forward
    ```
3. 安装helm报错连接被拒绝
    ```shell
    # 应该是DNS被污染，修改/etc/hosts文件
   199.232.68.133 raw.githubusercontent.com
   ```
4. 安装Prometheus无法连接
    ```shell
    # 国内源
    helm repo add azure-china http://mirror.azure.cn/kubernetes/charts/
    helm repo add prometheus-community https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack   
    # 直接安装
    helm install prometheus kube-prometheus-stack-80.4.1.tgz --namespace monitoring --create-namespace
    ```
5. 安装Metrics Server显示RUNNING但是describe报错Readiness probe failed: HTTP probe failed with statuscode: 500
    ```yaml
    spec:
      containers:
          - args:
            - --kubelet-insecure-tls # 添加这行
    ```
   再重新安装components.yaml
    ```shell
    kubectl delete -f components.yaml
    kubectl apply -f components.yaml
    ```