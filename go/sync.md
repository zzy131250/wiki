# Sync 包
基于 go 1.11.1
## 读写锁 sync.RWMutex
### race 竞态检测
- 把 race 检测转换成 happens-before 的检测
- 通过把内存访问时间、内存地址、操作类型（读还是写）记录下来，再遍历检测其中访问同一块内存区域的操作间是否满足 happens-before，来确定是否存在 race

## 条件变量 sync.Cond
### 禁止拷贝
通过 noCopy 变量实现，可在 go vet 中进行检测
```go
type Cond struct {
	noCopy noCopy
	...
	checker copyChecker
}
```
禁止在第一次初始化之后进行对象拷贝，实现：
```go
func (c *copyChecker) check() {
    if uintptr(*c) != uintptr(unsafe.Pointer(c)) && // 不懂？？
        !atomic.CompareAndSwapUintptr((*uintptr)(c), 0, uintptr(unsafe.Pointer(c))) && // 初始化时，*c == 0，所以第一次可以赋值成功
        uintptr(*c) != uintptr(unsafe.Pointer(c)) {
		panic("sync.Cond is copied")
	}
}
```

## 原子操作 sync/atomic
### atomic.Value 类型
- 可原子地存储和加载任意值，不过也有类型限制，只能存储和第一次存储进去的值同类型的值
- 是值类型，不能被复制
- 不能用来存储 nil

## sync.Once
调用 Do(f func()) 方法，对首次传入的函数执行一次，使用一个 Mutex 互斥锁和一个 done 字段组成，done 只能取0或1

### Do 方法的特点
- 由于采用双检锁实现，在多个 goroutine 同时调用 Do 方法时，在第一个调用该方法的 goroutine 返回之前，其他 goroutine 都会阻塞在获取 Mutex 的代码上
- 由于对 done 字段的修改使用原子操作，并放在 defer 语句中，所以不论函数执行结果如何（是否引发 panic），都只能执行一次

## 临时对象池 sync.Pool
- 存储独立、平等、可重用的对象，适合作为较长生命周期的缓存使用
- sync 包初始化时，向 Go 运行时注册清理函数 poolCleanup，在每次垃圾回收开始时进行对象池清理，清理就是把本地池和共享池对象都置为 nil
- Put 和 Get 对共享池操作时，都是操作末尾对象（Put 将对象放到共享池末尾，Get 从共享池尾部获取对象）

### 结构
每个 Pool 在 每个P 中都包含一个本地池和一个共享池，与 P 关联的 G 总是先尝试从本地池存取对象

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-3-24/51301775.jpg)

### 获取临时对象的步骤

![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-3-24/87723265.jpg)

## 并发安全字典 sync.Map
- 包含一个只读的 map，名为 read，类型为 sync/atomic.Value，可被看做是一个快照
  - 不允许增减键，但允许改变值，值的改变使用原子操作
  - 保存的键值对可能不全
- 包含一个读写的 map，名为 dirty，对它的访问需要锁
  - 保存全部键值对，且不包含已被逻辑删除的键值对
- 数据存取都是先尝试 read，再尝试 dirty
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/19-3-26/16785228.jpg)
- read 和 dirty 在一定条件下会互转
  - read -> dirty：有新的键值对存入（Store 和 LoadOrStore），转换时会将 read 中 nil 的键逻辑删除
  - dirty -> read：misses 达到 dirty 的长度，表明从 dirty 查询的次数足够多（Load 和 LoadOrStore）
