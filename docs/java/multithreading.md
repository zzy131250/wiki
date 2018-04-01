# 多线程
## Thread vs Runnable
- Thread 实现了 Runnable 接口
- Thread 只能单继承，而 Runnable 接口可以多实现
- Runnable 只定义了作业，可以实现松耦合，更符合面向对象的特点

## Java 线程间通信方式
- 共享变量(需要处理同步问题)
 - 实现 Runnable 接口
 - volatile 变量
- 管道流
 - 字节流：PipedInputStream 和 PipedOutputStream
 - 字符流：PipedReader 和 PipedWriter
- 轮询
- wait / notify 机制（锁）
 - synchronized + wait() / notify()
 - 显式锁 + 条件变量 Condition

## ThreadLocal
- 为每个线程都创建一个变量副本, 每个线程都可以修改自己所拥有的变量副本, 而不会影响其他线程的副本
- 在当前线程中有一个 ThreadLocalMap 引用（ThreadLocal 静态内部类，每个线程一个，类似于 WeakHashMap，key 跟 entry 都是弱引用），key 是 ThreadLocal 对象的弱引用，value 是实际存储的 object
- 适用于变量在线程间隔离而在方法或类间共享的场景
- get 和 set 的时候都会删除 key 为 null 的 entry，但是如果长时间不调用，或者线程不销毁，则会出现内存泄漏

## 伪共享
不同处理器上的线程对变量的修改依赖于相同的缓存行

## Thread 中的方法
### start() vs run()
- start()：启动新线程，真正的多线程执行
- run()：普通的方法调用，不启动新线程

### sleep() vs wait() vs yield()
#### sleep()
- Thread 类的静态方法，不释放对象锁
- 使线程停滞，让出cpu
- 休眠期满不一定立即执行

#### wait()
- Object 类的方法，释放对象锁
- 让出 cpu
- 使用 notify 或指定时间唤醒
- 必须放在 synchronized 中，最好放在 while 循环中，循环会在等待之前和之后测试条件

#### yield()
- Thread 类的静态方法，不释放对象锁
- 让出 cpu
- 暂停当前线程，让相同优先级的线程有机会执行；如果只有低优先级线程，则继续执行

### stop() vs suspend() vs interrupt()
- stop()：立即停止，解除线程的所有锁定；会使对象处于不连贯的状态
- suspend()：停止线程而不释放锁，容易产生死锁
- interrupt()：在线程中打一个中断标志，并在合适的时机中断