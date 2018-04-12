# Hbase
## 聚合查找
查询时只读取查询中用到的所有列值，而不是按行读取

## 优势
- 行自动扩展
- 动态列
- 高并发访问
- 强一致性
- 可压缩
- 自动故障转移

## 劣势
- 扫描查询时只有行键有索引
- 没有事务和 join
- HMaster 单点故障

## 客户端访问过程
- 访问 Zookeeper，获取存储 META table 的 RegionServer 位置
- 访问 META server，获取要查询的 key 值保存在哪个 RegionServer
- 把 META server 位置和目标 RegionServer 位置缓存下来
- 从目标 RegionServer 获取数据行

## Region 分割
按照 rowkey 范围水平分割

## 架构图
![](http://osbdeld5c.bkt.clouddn.com/18-4-10/11715688.jpg)

### Zookeeper
服务器状态监控，故障检测

### HMaster
- 协调、分配、监控 RegionServer
- 提供增、删、改函数接口

### HRegionServer
- WAL：预写式日志，用于数据恢复
 - 数据恢复过程：Zookeeper 未收到心跳，通知 HMaster 进行恢复；读取 WAL 重演，写入 MemStore ，再刷入 HFile
- BlockCache：读缓存，使用 LRU 算法保存数据
 - 读数据时，先访问 MemStore，写缓存未命中的话再到读缓存中查找，读缓存还未命中才会到 HFile 文件中查找，最终返回 merged 的一个结果给用户
- MemStore：写缓存
 - 是内存中的有序键值
 - 每个列族一个 MemStore
- HFile：磁盘中的有序键值
 - 使用顺序写入，写入很快速
 - 结构
![](http://osbdeld5c.bkt.clouddn.com/18-4-12/12285315.jpg)
 
### 列族
![](http://osbdeld5c.bkt.clouddn.com/18-4-12/86797257.jpg)

## 数据写入过程（LSM 架构）
1. 写入 WAL 持久化，存在磁盘上，顺序增加行
2. 写入 WAL 完成后即可查询，同时从 WAL 写入 MemStore
3. 达到指定大小时，把 MemStore 中的数据按序写到 HFile 中（一个 MemStore 可能对应多个 HFile），并记录最后一个写入的序列号
4. HFile Compaction：分为 Minor Compaction（多个小的 HFile 合并成几个大的 HFile）和 Major Compaction（多个小的 HFile 合并成一个大的 HFile，同时清理无意义的数据：被删除的数据、过期数据）
