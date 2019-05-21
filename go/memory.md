# 内存管理
基于 go 1.12.3
## 特点
- 内存池：向系统申请大块内存，然后进行分配和管理
- 垃圾回收
- 大小切分：将对象分为 67 类，大对象以页分配，小对象以块分配，提高内存使用率，减少内存碎片
- 多线程管理：每个 P 有一个 cache，缓存申请的 span

## 内存概览
- 以64位操作系统为例，内存划分为 spans、bitmap、arena 三个部分。其中 spans 和 bitmap 是为了管理 arena 区而存在的

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-5-15/82582990.jpg)

- arena 为 512G，划分为一个个 8KB 的 page
- spans 存放 span 的指针，每个指针指向一个 page，故 spans 区大小为 (512G/8KB)*8byte = 512M
- bitmap 区域也通过 arena 区域计算，主要用于 GC，每个 slot 用2个 bit 表示，分别表示是否被标记（是否需要继续扫描）以及是否是指针

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-5-19/89946161.jpg)

## 内存数据结构
### class
- 根据对象大小划分一系列 class，一个 class 代表一种固定大小的对象。一共划分了 66 类（第 1 类 8byte~第 66 类 32768byte）
- 对于每种 class，都有固定的 span 大小，以及每个 span 可以存放的对象数目
- 对于超过 32K 的大对象，其 class ID 为0，每个 class 只包含一个对象

### span
- 内存管理的基本单位，一个 span 管理一类 class 对象
- 根据对象大小， span 将一个或多个页拆分成块进行管理，每个块的大小即该类对象的大小

### central
- 管理 span 的全局资源，每个 central 管理存储同一类 class 的 span 列表

### cache（参考 tcmalloc）
- 缓存从 central 申请的 span
- 保存一个 67*2 的数组，每个数组元素为一类 span 的列表头
- 对于每个 class，都有 scan 和 noscan 两个 span 列表，分别保存含有指针的对象和没有指针的对象。noscan 列表表示其中保存的是没有指针的对象，无需进行 GC 扫描（mark 阶段无需继续遍历）

### heap
- 存放 central 列表，是 67*2 的数组
- 存放 spans、bitmap 以及 arena

## 内存分配
1. object size > 32K，使用 heap 直接分配
2. object size < 16byte（可调节，目前来说是最好的，最多为 2x 的浪费。如果是 8byte，固然可以做到不浪费，但不能做对象合并；如果是 32byte，合并的机会多，但会有 4x 的浪费。见 runtime/malloc.go::mallocgc 关于 tiny allocator 的介绍）且为 noscan 对象，使用 cache 的 tiny 分配器分配（tiny 是 cache 中专门存放小对象的区域）；若对象包含指针，则同 3
3. object size 介于 16byte 和 32K 之间，先使用 cache 对象的 class span 分配；cache class 对应的 span 没有可用块时，向 central 申请；central 没有可用的 span 时，向 heap 申请；heap 没有可用的 span 时，向操作系统申请

## GC
### 触发条件
- gcTriggerAlways：强制触发 GC
- gcTriggerHeap：当前分配的内存达到一定值就触发 GC
- gcTriggerTime：当一定时间没有执行过 GC 就触发 GC
- gcTriggerCycle：要求启动新一轮的 GC，已启动则跳过，手动触发 GC 的 runtime.GC 会使用这个条件

### 三色标记算法
1. 最开始所有对象都是白色
2. 从 root 开始找到所有可达对象，标记为灰色，放入待处理队列
3. 遍历灰色对象队列，将其引用对象标记为灰色放入待处理队列，自身标记为黑色
4. 处理完灰色对象队列，执行清扫工作，即清理白色对象

### 具体过程
#### sweep termination
- runtime/mgc.go::gcStart ->
- runtime/mgc.go::gcBgMarkStartWorkers ->
- runtime/mgc.go::gcBgMarkWorker

#### mark
- runtime/mgcmark.go::gcDrain
  - 灰色对象被标记过且在 work 列表中，黑色对象被标记过且不在 work 列表中
  - 灰色对象存储于 p.gcw 中，它是 gcWork 结构体（其中存储了两个 work buffer 的灰色对象，设置两个 buffer 的目的在于分摊在全局 work 上 get/put buffer 的成本，减少全局 work 的争用）
    - 全局 work 中有两个列表，分别为 full 和 empty 的 work buffer，且这两个列表都是无锁的，通过 cas 操作

#### mark termination
- runtime/mgc.go::gcMarkDone ->
- runtime/mgc.go::gcMarkTermination ->
- runtime/mgc.go::gcMark

#### sweep
- runtime/mgc.go::gcSweep ->
- runtime/mgcsweep::sweepone ->
- runtime/mgcsweep::sweep
