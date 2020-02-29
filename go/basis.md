# 基础
go 1.12.6
## Go 的优势
1. 数据结构紧凑，避免不必要的不连续
2. 小函数自动内联
3. 自动的逃逸分析，对于没有逃逸的值，直接分配在栈上，减少 GC 开销
4. 高效的 Goroutine
5. 分段栈与栈拷贝
  - 普通线程的栈与保护页面![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-13/14022457.jpg)
  - Goroutine 的栈
    - 不使用保护页面，而在函数调用中插入一个检查，如果栈不够，则请求分配更多栈空间
    - Go 1.2 的栈管理![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-13/48074288.jpg)
    - 热分裂问题：当 G 调用 H 的时候，没有足够的栈空间来让 H 运行，这时候 Go 运行环境就会从**堆**里分配一个新的栈内存块去让 H 运行。如果在循环或者递归中，这将导致多次堆空间的分配与释放![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-13/37511611.jpg)
    - Go 1.3 的栈管理（栈拷贝）：如果栈空间太小了，直接分配一块更大的栈空间并拷贝现有栈空间数据，而不是分配和释放堆空间![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-6-13/24523749.jpg)

## defer 语句
将 defer 语句后的函数放入一个栈，等到外层函数返回之后，按序执行栈中的函数

### 规则
1. defer 函数的参数在 defer 语句执行的时候被赋值
```go
func a() {
    i := 0
    defer fmt.Println(i) // print 0
    i++
    return
}
```
2. defer 函数按照后进先出的顺序执行
```go
// print 3210
func b() {
    for i := 0; i < 4; i++ {
        defer fmt.Print(i)
    }
}
```
3. defer 函数可以对函数返回值进行读取和修改
```go
// return 2
func c() (i int) {
    defer func() { i++ }()
    return 1
}
```

### defer 作用的时机
函数返回过程（return i）：
1. 将 i 存入栈作为返回值
2. 执行 defer 函数
3. 执行跳转程序（return 代理汇编指令 ret）

### defer 的实现原理
#### 数据结构
每个 goroutine 都有 _defer 字段，用于设置 defer 函数。
```go
// src/runtime/runtime2.go
type g struct {
    ...
    _defer *_defer // innermost defer
    ...
}
```
_defer 结构体可以组成链表。
```go
// src/runtime/runtime2.go
type _defer struct {
    ...
    link *_defer
}
```
#### 函数执行
defer 关键字在编译阶段被转成 deferproc 函数调用，并在业务函数返回之前插入 deferreturn 指令。
##### 创建 defer
```go
// src/runtime/panic.go
func deferproc(siz int32, fn *funcval) {
    ...
	d := newdefer(siz)
	if d._panic != nil {
		throw("deferproc: d.panic != nil after newdefer")
	}
	d.fn = fn
	d.pc = callerpc
	d.sp = sp
	...
    // 使用 return0，避免在返回时又触发 deferreturn 函数的执行
    return0()
}

// src/runtime/panic.go
func newdefer(siz int32) *_defer {
    ...
    // 将 _defer 结构体关联到 goroutine 并放到 _defer 链表最前面
    d.siz = siz
	d.link = gp._defer
	gp._defer = d
	return d
}
```
##### 执行 defer
```go
// src/runtime/panic.go
func deferreturn(arg0 uintptr) {
    ...
	fn := d.fn
	d.fn = nil
    gp._defer = d.link
    // 释放 defer 函数
    freedefer(d)
    // 执行 defer 函数中定义的 fn
	jmpdefer(fn, uintptr(unsafe.Pointer(&arg0)))
}
```

## channel
### channel 结构
由 buf 存储实际数据，sendx、recvx 指向发送、接收的索引位置，配合 qcount、dataqsiz，组成一个 RingBuffer。buf 中保存的任务采用内存拷贝，不共享内存。
```go
type hchan struct {
	qcount   uint           // total data in the queue
	dataqsiz uint           // size of the circular queue
	buf      unsafe.Pointer // points to an array of dataqsiz elements
	elemsize uint16
	closed   uint32
	elemtype *_type // element type
	sendx    uint   // send index
	recvx    uint   // receive index
	recvq    waitq  // list of recv waiters
	sendq    waitq  // list of send waiters
	lock mutex // 对于 buf 和 sendq、recvq 的访问控制
}
```
### 创建 channel
```go
ch := make(chan Task, 3) // 在堆上分配并初始化一个 hchan 结构，返回 chan 的一个指针
```
### goroutine 读写 channel
#### sudog 结构
sudog 结构包含一个 goroutine 和它需要向 channel 发送/接收的数据。
type sudog struct {
    g        *g             // 一个G
    ...
    elem     unsafe.Pointer // data element
}
#### 写 channel
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/20-2-29/23138877.jpg)

#### 读 channel
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/20-2-29/27147568.jpg)

#### 关闭 channel
1. 把 recvq 中的 G 全部唤醒，本该写入 G 的数据置为 nil
2. 把 sendq 中的 G 全部唤醒，这些 G 会 panic

## select
实现 IO 多路复用。select 语句由 case 语句和执行函数组成。

### scase 结构
```go
type scase struct {
	c           *hchan         // chan
	elem        unsafe.Pointer // 读写地址
	kind        uint16 // case 类型，包括 default、传值写（chan<-）、取值读（<-chan）
	pc          uintptr // race pc (for race detector / msan)
	releasetime int64
}
```

### 执行函数
select 语句，实际上调用了 selectgo 函数。在实现上，调用过程为：
```go
func Select(cases []SelectCase) (chosen int, recv Value, recvOK bool)
func rselect([]runtimeSelect) (chosen int, recvOK bool)
func selectgo(cas0 *scase, order0 *uint16, ncases int) (int, bool)
```
selectgo 函数实现：
```go
func selectgo(cas0 *scase, order0 *uint16, ncases int) (int, bool) {
	...
	// 把 nil channel 替换成空的 scase
	for i := range scases {
		cas := &scases[i]
		if cas.c == nil && cas.kind != caseDefault {
			*cas = scase{}
		}
	}
	...
	// 使用堆排序，根据 HChan 地址排列 scase
	// 锁定所有 channel
	sellock(scases, lockorder)
	// 遍历所有 scase，若已有 channel 可读或可写，或有 default 语句，则直接操作对应 channel（或 default），并解锁所有 channel
	// pass 1 - look for something already waiting
	// 若无 channel 可读写，且无 default 语句，则阻塞当前 goroutine，加入到所有 channel 的等待队列中，并解锁所有 channel
	// pass 2 - enqueue on all chans
	// 有 channel 可读或可写，则被唤醒。锁定所有 channel，找到可读或可写的那个 channel，进行对应操作，并将其他 channel 中对应没有成功的 G 从等待队列中删除
}
```