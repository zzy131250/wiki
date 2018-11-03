# Spark
## 整体框架
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/44945704.jpg)

## 核心组件
### RDD
#### 属性
- 一组分片（Partition）：数据集的最基本单位
- 一个计算每个分片的函数
- 依赖：描述 RDD 的依赖关系
- preferredLocations（可选）：data partition 的位置偏好
- partitioner（可选）：对于计算出来的数据结果如何分发

#### 操作
- Transformation：从现有的数据集创建⼀个新的数据集，惰性，不会提交任务
- Action：在数据集上运⾏计算后，返回⼀个值给驱动程序

#### 依赖关系
- 窄依赖：⼀个⽗ RDD 最多被⼀个⼦ RDD ⽤
- 宽依赖：指⼦ RDD 的分区依赖于⽗ RDD 的所有分区，这是因为 shuffle 类操作要求所有⽗分区可⽤；是 spark 划分 stage 的边界

### Scheduler
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/62602135.jpg)

### Storage
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/165389.jpg)

### Shuffle
#### Hash Shuffle v1
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/37954478.jpg)

#### Hash Shuffle v2
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/22882906.jpg)

#### Sort Shuffle