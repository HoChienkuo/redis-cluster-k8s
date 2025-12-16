# kubectl常用命令

**几个常用命令**

```shell
# 常看Pod所在节点
kubectl get pods <pod-name> -n kube-system -o wide
# 查看Pod用的镜像
kubectl get pods <pod-name> -n kube-system -o yaml | grep image:
```

**命令大全**

```shell
# 查看所有 Pod
kubectl get pods --all-namespaces

# 查看指定命名空间的 Pod
kubectl get pods -n <namespace>

# 查看 Pod 详细信息
kubectl describe pod <pod-name> -n <namespace>

# 实时监控 Pod 状态
kubectl get pods -n <namespace> -w

# 查看所有节点
kubectl get nodes

# 查看节点详细信息
kubectl describe node <node-name>

# 查看节点资源使用情况
kubectl top nodes

# 查看所有服务
kubectl get services --all-namespaces

# 查看指定命名空间的服务
kubectl get services -n <namespace>

# 查看 Deployment 状态
kubectl get deployments -n <namespace>

# 查看 StatefulSet 状态
kubectl get statefulsets -n <namespace>

# 查看 DaemonSet 状态
kubectl get daemonsets --all-namespaces

# 查看 PersistentVolume
kubectl get pv

# 查看 PersistentVolumeClaim
kubectl get pvc --all-namespaces

# 查看 StorageClass
kubectl get storageclass

# 查看 ConfigMap
kubectl get configmaps -n <namespace>

# 查看 Secret
kubectl get secrets -n <namespace>

# 查看集群事件
kubectl get events --all-namespaces

# 查看 Pod 日志
kubectl logs <pod-name> -n <namespace>

# 实时跟踪日志
kubectl logs -f <pod-name> -n <namespace>
```