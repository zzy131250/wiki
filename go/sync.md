# Sync 包
## 读写锁 sync.RWMutex
### race 竞态检测
- 把 race 检测转换成 happens-before 的检测
- 通过把内存访问时间、内存地址、操作类型（读还是写）记录下来，再遍历检测其中访问同一块内存区域的操作间是否满足 happens-before，来确定是否存在 race

## 条件变量 sync.Cond
###  禁止拷贝，通过 noCopy 变量实现，可在 go vet 中进行检测
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