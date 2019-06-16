# 基础
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