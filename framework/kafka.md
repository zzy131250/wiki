# Kafka
2019.6.3 trunk

## 优势与特点
- 以时间复杂度为O(1)的方式提供消息持久化能力，即使对 TB 级以上数据也能保证常数时间复杂度的访问性能？？？
- 高吞吐率。即使在非常廉价的商用机器上也能做到单机支持每秒100K条以上消息的传输
- 支持 Broker 间的消息分区，及分布式消费，同时保证每个 Partition 内的消息顺序传输
- 支持多订阅者，失败时自动平衡消费者？？？
- 同时支持离线数据处理和实时数据处理？？？
- 支持在线水平扩展

## 架构
- Producer：消息生产者，使用 push 模式将消息发布到 Broker
- Broker：Kafka 集群的节点
- Consumer：消费者，使用 pull 模式从 Broker 订阅并消费消息
- Consumer Group：消费组，消息订阅者，每个 Consumer 属于一个 Consumer Group，一条消息可以发送到多个不同的 Consumer Group，但是一个 Consumer Group 中只能有一个 Consumer 能够消费该消息
- ZooKeeper：配置管理、选举 Leader以及消费者负载均衡

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-17/24232470.jpg)

## 消息
### Broker 中的 Topic 和 Partition
- Topic：主题，对消息进行归类
- Partition：一个 Topic 分为多个 Partition，每个 Partition 内部是有序的

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-17/31354481.jpg)

### Partition 中的 Segment
Partition 是物理概念，作为一个目录存放于 Broker 中，其中保存了若干个 Segment 文件。Segment 文件由一组 .index 和 .log 组成，文件名规则：Partition 全局第一个 Segment 从0开始，后续每个 Segment 文件名为上一个 Segment 文件最后一条消息的 offset 值，数值大小为64位，20位数字字符长度，没有数字用0填充。
如下图，展示了00000000000000170410 Segment 文件的 .index 和 .log内容。索引文件中的元数据指向对应数据文件中 message 的物理偏移地址。

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-17/24349750.jpg)

### 消息格式
[一文看懂Kafka消息格式的演变](http://www.uml.org.cn/bigdata/2018051731.asp)

### 消息复制
每个 Partition 都有一个 replica 为 Leader，负责处理读写请求，Follower 则负责被动复制 Leader 数据

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-18/71482997.jpg)

### 消息同步
当 Leader 所在 Broker 故障时，新的 Leader 将从 Follower 中选出并继续处理客户端请求

#### 同步副本 ISR（In-Sync Replicas）
Kafka 默认副本数配置为1，不具备容灾能力，在生产环境通常设置为大于1，比如3。所有副本统称为 AR（Assigned Replicas）。ISR 是 AR 的子集，由 Leader 维护，ISR 列表中的 Follower 与 Leader 保持同步（Leader 也包含在 ISR 中）。当 Follower 从 Leader 同步数据出现延迟（超过 replica.lag.time.max.ms 的值），则该 Follower 被移出 ISR，存入 OSR（Outof-Sync Replicas）。新加入的 Follower 也会先存放在 OSR 中。那么：AR = ISR + OSR

#### LEO（LogEndOffset）与 HW（HighWatermark）
- LEO：每个 Partition 的 log 最后一条消息的位置
- HW：高水位，取 Partition 对应的 ISR 中最小的 LEO 为 HW，Consumer 最多只能消费到 HW 位置。每个 replica 都有 HW，并各自负责更新自己的 HW

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-18/82693600.jpg)

#### 消息可靠性
通过 request.required.acks 参数可设置数据可靠性级别
- request.required.acks = 1
默认情况，Producer 发送数据到 Leader，Leader 写本地日志成功，返回成功。此时还没有同步到 ISR，如果此时 Leader 宕机，那么该消息将丢失
- request.required.acks = 0
Producer 不停向 Leader 发送消息，不需要 Leader 反馈结果。可靠性最低
- request.required.acks = -1
Producer 发送数据到 Leader，Leader 收到数据，并等到 ISR 列表中的所有副本都同步完成，再返回成功。如果 Producer 一直收不到成功信息，则会自动重发。可靠性最高，性能最低
  - min.insync.replicas
  设定 ISR 中的最小副本数

### Exactly Once实现？？？

## Leader 选举策略
- unclean.leader.election.enable=false
选举 ISR 中的成员作为 Leader。如果 ISR 所有成员都故障，则等待 ISR 中任意一个副本恢复，并选择它作为 Leader
- unclean.leader.election.enable=true
选择第一个恢复过来的副本（并不一定是在 ISR 中）作为 Leader，可能造成消息丢失

## ZooKeeper 的作用
- Broker 的注册及监控，Broker 在 ZooKeeper 上的临时节点路径为 /brokers/ids/{broker.id}
- Topic 的注册，Topic 和 Broker 的关系记录在 ZooKeeper 上，路径为 /brokers/topics/{topic_name}
- Consumer Group 的注册，路径为 /consumers/{group_id}，其节点下有三个子节点，分别为[ids, owners, offsets]
  - ids 节点：记录该消费组中当前正在消费的消费者
  - owners 节点：记录该消费组消费的 Topic 信息
  - offsets 节点：记录每个 Topic 的每个分区的 offset
- Consumer 的注册与监控，临时节点路径为 /consumers/{group_id}/ids/{consumer_id}。Kafka 保证一个 Consumer Group 中只能有一个 Consumer 能够消费某条消息，实际上，Kafka 保证的是**稳定状态下每一个 Consumer 实例只会消费某一个或多个特定的 Partition，而某个 Partition 的数据只会被某一个特定的 Consumer 实例所消费**，通过这种方式，也保证了 Partition 消息的**顺序消费**
- Producer 注册，监听 Broker 变化
- 记录消费进度 offset，/consumers/[group_id]/offsets/[topic]/[broker_id-partition_id]，节点内容为 offset 值。**注意**，Kafka 已推荐将 Consumer 的 offset 信息保存在 Kafka 内部的 Topic 中，路径为 /brokers/topics/__consumer_offsets
- 记录 Partition 与 Consumer 的关系，临时节点路径为 /consumers/[group_id]/owners/[topic]/[broker_id-partition_id]，节点内容为 consumer_id 值

## 消息发送过程
### Producer 发送消息

### Broker 存储消息

### Consumer 消费消息