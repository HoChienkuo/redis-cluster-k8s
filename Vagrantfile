Vagrant.configure("2") do |config|
  # 使用我们刚才添加的本地Box
  config.vm.box = "my-ubuntu"
  
  # 禁用默认的共享文件夹以提升性能（可选）
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # 定义Master节点
  config.vm.define "master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: "192.168.56.10"
    # VirtualBox特定配置
    master.vm.provider "virtualbox" do |vb|
      vb.memory = 2048   # 分配2GB内存
      vb.cpus = 2        # 分配1个CPU核心
      vb.name = "k8s-master"
    end
    # 提供脚本：修改主机名解析、安装基础工具
    master.vm.provision "shell", inline: <<-SHELL
      cat >> /etc/hosts <<EOF
192.168.56.10 k8s-master
192.168.56.11 k8s-node1
192.168.56.12 k8s-node2
EOF
      apt-get update
      apt-get install -y curl wget vim net-tools
    SHELL
  end
  
  # 定义Node1节点
  config.vm.define "node1" do |node|
    node.vm.hostname = "k8s-node1"
    node.vm.network "private_network", ip: "192.168.56.11"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 1
      vb.name = "k8s-node1"
    end
  end
  
  # 定义Node2节点
  config.vm.define "node2" do |node|
    node.vm.hostname = "k8s-node2"
    node.vm.network "private_network", ip: "192.168.56.12"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 1
      vb.name = "k8s-node2"
    end
  end
end