# Channel
## 定义 channel
- 双向 channel：make(chan int)
- 发送 channel：make(chan<- int)
- 接收 channel：make(<-chan int)

## channel 关闭后值的读取
- 无缓存 channel：channel 关闭后，接收的值为该 channel 值类型的零值
- 有缓存 channel：channel 关闭后，先将缓存数据读完，而后都返回 channel 值类型的零值
- range 语句：必须在 channel 关闭后再开始读取，否则会出现死锁