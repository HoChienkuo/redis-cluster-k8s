# 1. 停止所有服务
sudo systemctl stop kubelet
sudo systemctl stop containerd

# 2. 重置 kubeadm（清理 k8s 配置）
sudo kubeadm reset -f

# 3. 强制删除所有残留文件（关键！）
sudo rm -rf /etc/kubernetes/*
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf ~/.kube
sudo rm -rf /var/lib/etcd/

# 4. 清理网络配置
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -X

# 5. 重启 containerd
sudo systemctl start containerd
sudo systemctl enable containerd

echo "=== Node1 清理完成 ==="