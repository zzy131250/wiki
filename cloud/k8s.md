# Kubernetes
## Etcd
### 特点
- 基于 HTTP + JSON 的 api
- 可选 ssl 客户端认证
- 使用 [Raft 算法](http://thesecretlivesofdata.com/raft/) 实现一致性

### 架构
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/86096774.jpg)

## Flannel
k8s 的网络规划服务，功能是让集群中不同节点主机创建的容器具有集群唯一的虚拟 ip 地址

### 覆盖网络
运行在应用层的网络，不依靠 ip 来传递信息，而是采用一种映射机制，把 ip 和 identifiers 做映射来进行资源定位，例如 p2p 网络

### 实现过程
1. 数据从源容器经过源主机 docker0 网卡转发到 flannel0 网卡
2. flannel 通过 etcd 维护一张路由表
3. 源主机的 flanneld 服务根据路由表将数据经过 udp 封包后投递给目标主机的 flanneld 服务
4. 目标主机接收到数据，解包，转发给本主机上的容器

## k8s 整体架构
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/69111547.jpg)

## k8s 模块间的通信
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/7578567.jpg)

## k8s 组件
- API Server：提供了资源对象的唯一操作入口，其他所有的组件都必须通过它提供的 API 来操作资源对象
- Controller Manager: 集群内部的管理控制中心，主要目的是实现 Kubernetes 集群的故障检测和自动恢复等工作。它包含两个核心组件：Node Controller 和 Replication Controller。其中 Node Controller 负责计算节点的加入和退出，可以通过 Node Controller 实现计算节点的扩容和缩容。Replication Controller 用于 Kubernetes 资源对象 RC 的管理，应用的扩容、缩容以及滚动升级都是由 Replication Controller 来实现
- Scheduler: 集群中的调度器，负责 Pod 在集群的中的调度和分配
- Kubelet: 负责本 Node 节点上的 Pod 的创建、修改、监控、删除等 Pod 的全生命周期管理，Kubelet 实时向 API Server 发送所在计算节点（Node）的信息
- Kube-Proxy: 实现 Service 的抽象，为一组 Pod 抽象的服务（Service）提供统一接口并提供负载均衡功能