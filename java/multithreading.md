# 多线程
## Thread vs Runnable
- Thread 实现了 Runnable 接口
- Thread 只能单继承，而 Runnable 接口可以多实现
- Runnable 只定义了作业，可以实现松耦合，更符合面向对象的特点

## Java 线程状态及切换
![](http://osbdeld5c.bkt.clouddn.com/18-7-26/72656135.jpg)

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
- 每个线程都有一个 ThreadLocalMap 实例（ThreadLocal 静态内部类，类似于 WeakHashMap，key 跟 entry 都是弱引用），key 是 ThreadLocal 对象实例的弱引用，value 是实际存储的 object
- 适用于变量在线程间隔离而在方法或类间共享的场景
- get 和 set 的时候都会删除 key 为 null（threadlocal 实例已被回收）的 entry，但是如果长时间不调用，或者线程不销毁，则会出现内存泄漏

![](http://osbdeld5c.bkt.clouddn.com/18-4-16/25253514.jpg)

## 死锁 vs 活锁 vs 饥饿
### 死锁
多个线程相互占用对方资源的锁，而又互相等待对方释放锁，导致线程都得不到执行

### 活锁
多个线程相互谦让，都主动释放资源给别的线程使用，导致线程都得不到执行

### 饥饿
一个线程所需的资源一直被强占，从而一直得不到执行

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

### join()
循环判断当前线程是否存活，若存活，则在该线程对象上 wait()，挂起主线程，等待当前线程结束

### holdsLock(Object obj)
检测当前线程是否拥有某个对象的锁

## Thread 状态 blocked vs waiting
- blocked：当前线程在等待一个 monitor lock，比如等待执行 synchronized 代码块或者使用 synchronized 标记的方法
- waiting：调用下列方法之一
 - 调用 Object 对象的 wait 方法，但没有指定超时值
 - 调用 Thread 对象的 join 方法，但没有指定超时值
 - 调用 LockSupport 对象的 park 方法

## 线程池
### 线程池处理流程
![](http://osbdeld5c.bkt.clouddn.com/18-4-2/6345546.jpg)

### 线程池种类
- FixedThreadPool：使用 LinkedBlockingQueue 无界队列，corePool 和 maximumPool 都是一个固定值
- SingleThreadExecutor：使用 LinkedBlockingQueue 无界队列，corePool 和 maximumPool 都是1
- CachedThreadPool：使用 SynchronousQueue 队列（没有容量），corePool 为0，maximumPool 无界
- ScheduledThreadPool：使用 DelayQueue 无界队列，内封装了优先队列，对任务按照执行时间先后排序

### execute() vs submit()
submit() 有返回值 future，execute() 无返回值

### shutdown() vs shutdownNow()
- 都是遍历线程池中的工作线程，逐个调用 interrupt 方法中断线程
- shutdown() 将线程池状态置为 SHUTDOWN，然后中断所有没有执行任务的线程；shutdownNow() 将线程池状态置为 STOP，然后尝试停止正在执行或暂停任务的线程，并返回等待执行的任务列表

### 线程数估算
最佳线程数目 = （线程等待时间与线程CPU时间之比 + 1）* CPU数目

### 线程池的选择
- 高并发、耗时短的任务：线程数尽可能少，减少线程切换
- 低并发、耗时长的任务：线程数尽可能多，充分利用 cpu