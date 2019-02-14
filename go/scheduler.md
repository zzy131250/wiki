# 调度器
## 调度器模型
### G - M 模型的问题
- 单一全局锁（Sched.Lock）和中心化状态管理。该锁保护所有和 goroutine 相关的操作：创建、完成和再次调度等
- goroutine 被传递。goroutine 经常在 M 间传递，这会增加延时，导致额外开销。每个 M 必须可以执行每个可执行的 goroutine，特别是在 M 刚创建 goroutine 的时候（又切换到另一个 M 执行）
- 每个 M 都有内存缓存（M.mcache），但是只有在 M 运行 go 代码时，才会使用（M 在执行系统调用时不需要 mcache）。这导致过多的资源占用和较低的数据局部性
- 由于系统调用导致 M 频繁阻塞和解除阻塞，增加了很多开销

### G - M - P 模型
#### 各概念的关系
- G - goroutine
  - G 在 P 的本地队列或全局队列中
  - G 在用户空间创建，保存任务状态并提供栈空间（初始为2KB）
  - G 可被重复使用，重用时重新分配栈空间，优先重用已分配过栈的 G
	```go
	// Create a new g running fn with narg bytes of arguments starting
	// at argp. callerpc is the address of the go statement that created
	// this. The new g is put on the queue of g's waiting to run.
	func newproc1(fn *funcval, argp *uint8, narg int32, callergp *g, callerpc uintptr) {
		...
		_p_ := _g_.m.p.ptr()
		// Get from gfree list. status == Gdead
		// If local list is empty, grab a batch from global list.
		newg := gfget(_p_)
		if newg == nil {
			newg = malg(_StackMin)
			casgstatus(newg, _Gidle, _Gdead)
			allgadd(newg) // publishes with a g->status of Gdead so GC scanner doesn't look at uninitialized stack.
		}
		...
	}
	```
- M - machine，操作系统的线程
  - M 必须关联一个 P 来执行 go 代码，不过它可以被阻塞，或者执行系统调用（此时不用关联 P）
- P - processor，处理器（虚拟概念），执行 go 代码需要的资源
  - 由 GOMAXPROCS 环境变量指定
  - 如果可能，最好不要在运行时调用 GOMAXPROCS 函数，会导致 stopTheWorld
	```go
	func GOMAXPROCS(n int) int {
		...
		stopTheWorld("GOMAXPROCS")

		// newprocs will be processed by startTheWorld
		newprocs = int32(n)

		startTheWorld()
		return ret
	}
	```

#### 流程关系
- 创建一个新的 goroutine
- 新的 goroutine 被放入 P 的本地队列，如果本地队列已满，则放入全局队列，并只能由该 P 执行
- 一个 M 被唤醒或创建以执行 goroutine
  - 进行调度循环
  - 从 P 的本地队列、全局队列、其他 P 的队列（work-stealing）或 netpoll 中获取 goroutine 执行
  - 清理并重新进入调度循环

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-2-13/82196733.jpg)

## work-stealing 算法
### work-sharing vs work-stealing
- work-sharing
  - 当一个处理器产生多个线程，调度器会把一些线程迁移到其他处理器
  - 希望把任务分给未充分利用的处理器
- work-stealing
  - 未充分利用的处理器占据主动
  - 需要任务的处理器从其他处理器“偷走”线程

## 栈管理
### 分段栈（go 1.3之前）
一种不连续但可以持续增长的栈。但会有**栈分裂**问题：当一个段即将耗尽，此时执行较多次消耗栈的操作，会导致扩容；在执行完成后，栈回收又会缩容，这样频繁操作，导致多次扩容和缩容，影响性能

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-2-13/40598926.jpg)

### go 连续栈
先分配一块固定大小的栈，在栈空间不足时，分配一块更大的栈，并把旧的栈全部拷贝到新栈中

## sysmon 函数
- go 程序启动时，runtime 启动 sysmon，无需绑定 P，每 20us~10ms 执行一次
- sysmon 的职责
  - 检查是否存在死锁，根据是否有正在运行的 M
  - 将长时间未处理的 netpoll 结果添加到任务队列
  - 收回因 syscall 长时间阻塞的 P
  - 向长时间运行的 G 任务发出抢占调度
  - 如果超过2分钟没有垃圾回收，强制执行
  - 释放闲置超过5分钟的堆内存（归还给操作系统）

## goroutine 生命周期
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-2-14/53166914.jpg)
