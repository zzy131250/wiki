# Channel
## 定义 channel
- 双向 channel：make(chan int)
- 发送 channel：make(chan<- int)
- 接收 channel：make(<-chan int)

## channel 值的读写
| channel 类型 | 读取 | 写入 | 关闭后读取 | 关闭后写入 |
| ----- | ----- | ----- | ----- | ----- |
| 无缓存 channel | 阻塞直到有数据写入 | 阻塞直到有接收者读取 | 返回 channel 值类型的零值 | 引发panic |
| 有缓存 channel | 如果有缓存数据，则直接读取，否则阻塞直到有数据写入 | 如果未满，则可以直接写入，否则阻塞直到有接收者读取 | 先将缓存数据读完，而后都返回 channel 值类型的零值 | 引发 panic |
| nil channel | 阻塞 | 阻塞 | 关闭时引发 panic | 关闭时引发 panic |
