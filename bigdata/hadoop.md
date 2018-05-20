# Hadoop
## HDFS
### HDFS 架构演变
#### HDFS v1
![](http://osbdeld5c.bkt.clouddn.com/18-4-1/69906855.jpg)

#### HDFS v2
![](http://osbdeld5c.bkt.clouddn.com/18-4-1/9319717.jpg)

### HDFS 文件租约
由租约管理器管理，实现 single-writer，默认租约为软限制 60s（写文件时规定的租约超时时间），硬限制 60min（考虑到文件 close 时未来得及释放 lease 的情况）

## MapReduce
### MapReduce 架构演变
#### MRv1
![](http://osbdeld5c.bkt.clouddn.com/18-4-1/68793576.jpg)

#### MRv2(YARN)
![](http://osbdeld5c.bkt.clouddn.com/18-4-1/5761065.jpg)

### MapReduce 流程
![](http://osbdeld5c.bkt.clouddn.com/18-4-1/18400203.jpg)

- partition()：把 mapper 节点的数据结果按照目标 reducer 分区
- combine()：在 mapper 节点预先合并数据