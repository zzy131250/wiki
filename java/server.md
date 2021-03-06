# Server
## Netty
### buffer
- CompositeByteBuf：由多个 ByteBuf 组合而成，可以看做一个整体读写。直接保存每个 component 的引用，而不是开辟新的内存，实现了“零拷贝”
- BufferBuf 的引用计数
  - 使用 retain() 方法增加引用计数
  - 对象的销毁：最后访问引用计数对象的部分负责对象的销毁
    - 如果一个发送组件要传递一个引用计数对象到另一个接收组件，发送组件通常不需要负责去销毁对象，而是将这个销毁的任务推延到接收组件
    - 如果一个组件消费了一个引用计数对象，并且不知道谁会再访问它（例如，不会再将引用发送到另一个组件），那么，这个组件负责销毁工作
    - 调用 ByteBuf.duplicate()、ByteBuf.slice()和ByteBuf.order(ByteOrder) 三个方法，会创建一个子缓冲区，子缓冲区共享父缓冲区的内存区域。子缓冲区没有自己的引用计数，而是共享父缓冲区的引用计数