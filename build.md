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