#!/bin/bash

# 禁用Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 安装容器运行时（containerd）
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 安装 kubeadm, kubelet, kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
# 锁定版本
sudo apt-mark hold kubelet kubeadm kubectl

# 初始化Kubernetes集群
sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all --image-repository registry.aliyuncs.com/google_containers

# 配置kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装Flannel网络插件
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 允许Master节点调度Pod（单节点或测试环境）
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# 生成加入集群的命令
sudo kubeadm token create --print-join-command > /home/vagrant/join-command.sh
chmod +x /home/vagrant/join-command.sh
echo "=== Master节点初始化完成！==="
echo "加入集群命令保存在：/home/vagrant/join-command.sh"