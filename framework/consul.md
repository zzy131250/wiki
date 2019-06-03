# Consul
2019.5.27
## 概述
Consul 是 HashiCorp 公司推出的开源工具，用于实现分布式系统的服务发现与配置共享

## 功能
- 服务的注册和发现
- KV 形式配置文件处理
- 健康检查
- 多数据中心

## 优势
- Server 间使用 Raft 算法来保证强一致性，所有节点使用 Gossip 协议实现最终一致性
- 支持多数据中心，内外网的服务采用不同的端口进行监听
- 支持健康检查
- 支持 HTTP 和 DNS 协议接口进行服务发现
- 官方提供 Web 管理界面

## 架构图
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-5-29/48220601.jpg)

## 组成部分
- Agent：每个节点上的守护进程，包含 Client 和 Server 两种模式，可以调用 DNS 或 HTTP API，并负责检查和维护服务同步
- Client：Client 模式的 Agent，负责转发请求给 Server；后台参与 LAN Gossip
  - 维护 Server 列表
  - 使用 rpcLimiter 限制 RPC 数目
  - 使用 serf 以实现 Gossip 协议
- Server：Server 模式的 Agent，参与 Raft 选举，维护集群状态，响应 RPC 请求，参与 LAN Gossip，与其他数据中心交互 WAN Gossip，转发查询到 Leader 或远程数据中心
  - 使用 Raft，它将数据存储到 FSM 状态机，实现强一致性
  - 维护不同数据中心的 Server 列表
  - 使用 serf 以实现 LAN 和 WAN 的 Gossip 协议

## Raft 及其 FSM 处理过程
### Leader 插入 log
- hashicorp/raft/api.go::Apply，向 applyCh 传入 log ->
- hashicorp/raft/raft.go::leaderLoop，循环，case applyCh，分发 log ->
- hashicorp/raft/raft.go::dispatchLogs，分发 log，将 log 插入 leaderState.inflight

### Leader 循环处理 log
- hashicorp/raft/raft.go::leaderLoop，循环，case leaderState.commitCh，从 leaderState.inflight 中取出 log ，并调用 processLogs 处理 ->
- hashicorp/raft/raft.go::processLog，将 log 传入 fsmMutateCh ->
- hashicorp/raft/fsm.go::runFSM，从 fsmMutateCh 取出 log 并 commit

### Leader 向 Follower 同步 log
- hashicorp/raft/raft.go::runLeader，startStopReplication 同步 log ->
- hashicorp/raft/raft.go::startStopReplication，调用 replicate 同步 log ->
- hashicorp/raft/replication.go::setupAppendEntries，组装新的 log ->
- hashicorp/raft/transport.go::AppendEntries，调用 RPC，给 Follower 同步 log

### Follower 接收 log
- hashicorp/raft/raft.go::runFollower，processRPC 处理请求 ->
- hashicorp/raft/raft.go::appendEntries，同步 log，注意，Leader 发送的 log 包含所有的 log 记录，需要根据本地 log 进行增量同步

## Serf 及 Gossip 处理过程
### Serf API，UserEvent 和 Query
- UserEvent：单向消息，不需要收集反馈
- Query：双向信息，需要注册 QueryResponse 来接收并处理反馈

### 消息处理
- hashicorp/serf/serf/serf.go::UserEvent 和 Query 方法都将 Event 传入 config.EventCh
- consul/agent/consul/client_serf.go::lanEventHandler，consul 中自行注册 Event 处理函数

### MemberList
维护 Serf 的成员关系，并进行错误检测；基于 Gossip 协议传播消息，该 Gossip 协议建立在 SWIM 协议之上

#### Gossip 相关函数
- hashicorp/memberlist/state.go::gossip，每过一定时间，随机挑选 k 个节点发送广播消息
- hashicorp/memberlist/state.go::pushPull，每过一定时间，随机挑选一个节点建立 TCP 连接，发送全量消息，然后接收全量消息，并在本地合并状态

#### Memberlist 状态（使用 SWIM 进行失效检测）
- hashicorp/memberlist/state.go::aliveNode，*alive*，新节点启动，广播 alive 消息
- hashicorp/memberlist/state.go::probeNode，发送探测消息，若探测失败，则随机选取 k 个节点发送 IndirectChecks（通知他们发送 ping 消息并告知结果），同时再直接发送 TCP 消息。如果探测超时之前，本节点没有收到任何一个要探测节点的 ACK 消息，且 TCP 消息也未回复，则标记要探测的节点状态为 suspect
- hashicorp/memberlist/state.go::suspectNode，*syspect*，标记 syspect ，然后启动一个定时器，并发出一个 suspect 广播，此期间内如果收到其他节点发来的相同的 suspect 信息时，将本地 suspect 的确认数加 1，当确认数达到要求，或定时器超时后，该节点信息仍然不是 alive 的，会将该节点标记为 dead；如果收到本节点的 suspect 消息，会广播 alive 消息，从而清除其他节点的 suspect 标记
- hashicorp/memberlist/state.go::deadNode，*dead*，标记 dead 并继续广播；如果收到本节点的 dead 消息，则广播 alive 消息进行修正

#### 回调函数
- hashicorp/memberlist/net.go::packetHandler，处理运输层接收的数据包
- hashicorp/memberlist/net.go::handleUser，调用 memberlist.Delegate 的 NotifyMsg 方法，处理消息
- hashicorp/serf/serf/delegate.go 实现了 memberlist.Delegate 的回调函数

### Vivaldi 算法
通过启发式的学习算法，在集群通信的过程中计算节点之间的 RTT

### LamportTime
逻辑时钟，确保分布式系统多节点事件的顺序性
