#!/bin/bash
echo "=== 彻底清理 Kubernetes 环境 ==="

# 1. 停止所有相关服务
sudo systemctl stop kubelet 2>/dev/null
sudo systemctl stop containerd 2>/dev/null
sudo systemctl disable kubelet 2>/dev/null

# 2. 杀死相关进程
sudo pkill -9 kubelet 2>/dev/null
sudo pkill -9 kube-apiserver 2>/dev/null
sudo pkill -9 kube-controller-manager 2>/dev/null
sudo pkill -9 kube-scheduler 2>/dev/null
sudo pkill -9 etcd 2>/dev/null

# 3. 彻底删除所有 Kubernetes 文件
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni/net.d
sudo rm -rf /run/flannel/

# 4. 清理 Docker/containerd 中的 Kubernetes 容器和镜像
sudo crictl rm -fa 2>/dev/null || true
sudo ctr containers ls -q | xargs -r sudo ctr containers delete 2>/dev/null || true

# 5. 清理网络接口和 iptables
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete docker0 2>/dev/null || true

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo iptables -t nat -X
sudo iptables -t mangle -X

# 6. 释放 10250 端口
sudo fuser -k 10250/tcp 2>/dev/null || true

# 7. 重启 containerd
sudo systemctl start containerd
sudo systemctl enable containerd

echo "=== 清理完成 ==="