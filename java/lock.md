# 锁
## AQS 及其子类
### AQS (AbstractQueuedSynchronizer)
内部维护一个 volatile state 变量，以及一个等待的 Node 队列，每个 Node 节点会标志是独占还是共享的。AQS 提供了 ConditionObject 条件队列，方便 Condition 的使用。

- 独占模式：只唤醒等待队列头节点
- 共享模式：按顺序唤醒等待队列的共享节点

![](http://osbdeld5c.bkt.clouddn.com/18-3-30/94992631.jpg)
### ReentrantLock
使用继承自 AQS 的 Sync ，实现独占功能， state 表示重入次数
### CountDownLatch
使用继承自 AQS 的 Sync ，实现共享功能， state 表示还需等待的线程数
### Semaphone
使用继承自 AQS 的 Sync ，实现共享功能， state 表示可用资源数
### ReentrantReadWriteLock
使用一个共享读锁和一个独占写锁，并使用继承自 AQS 的 Sync ，它的 state 高16位记录读锁获取次数，低16位记录写锁获取次数

## FutureTask 特例
JDK 8 中不使用 AQS，改为使用 Treiber stack（基于 CAS），用于存储需要得到结果（调用了 get()）的线程

## CyclicBarrier
使用一个 ReentrantLock 和一个 Condition

## ArrayBlockingQueue
使用一个 ReentrantLock 和两个 Condition（notEmpty 和 notFull）

## 锁降级
遵循获取写锁、获取读锁在释放写锁的次序，写锁能够降级成为读锁

## 公平性
- 非公平锁：直接尝试获取锁
- 公平锁：先判断当前线程是否是等待队列的头，再尝试获取锁