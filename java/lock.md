# 锁
## AQS 及其子类
### AQS (AbstractQueuedSynchronizer)
内部维护一个 volatile state 变量，以及一个 Node 同步队列，每个 Node 节点会标志是独占还是共享的。AQS 提供了 ConditionObject 等待队列，方便 Condition 的使用。

- 独占模式：只唤醒等待队列头节点
- 共享模式：按顺序唤醒等待队列的共享节点

#### 节点状态

- SIGNAL：本节点的一个后继节点被阻塞（或将要被阻塞），所以当本节点释放或取消时，它必须唤起后继节点。后继节点在 acquire 失败后会在本节点注册一个 signal，等待重试 acquire 方法（见 shouldParkAfterFailedAcquire 方法）。
- CANCELLED：本节点由于超时或中断而被取消。处于该状态的节点不再改变状态。特别的，在 CANCELLED 节点上的线程永远不会再次阻塞。
- CONDITION：本节点在条件队列上。它不会被用在同步队列上，除非被转换（被设置为0）过后。该值与其他值均无关联，在此处使用仅为了简化流程。
- PROPAGATE：共享模式的节点释放应该被传播到其他节点。该值在 doReleaseShared 方法中被设置（仅在 head 节点中）来确保会继续传播，即使其他操作已被阻塞。
- 0：不是上面的任何一个值。

![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/22602143.jpg)
### ReentrantLock
使用继承自 AQS 的 Sync ，实现独占功能， state 表示重入次数
### CountDownLatch
使用继承自 AQS 的 Sync ，实现共享功能， state 表示还需等待的线程数
### Semaphone
使用继承自 AQS 的 Sync ，实现共享功能， state 表示可用资源数
### ReentrantReadWriteLock
使用一个共享读锁和一个独占写锁，并使用继承自 AQS 的 Sync ，它的 state 高16位记录读锁获取次数，低16位记录写锁获取次数

## FutureTask 特例
JDK 8 中不使用 AQS，改为使用 Treiber stack（基于 CAS），为了在需要竞争时保留中断状态。等待队列用于存储需要得到结果（调用了 get()）的线程

## CyclicBarrier
使用一个 ReentrantLock 和一个 Condition

## ArrayBlockingQueue
使用一个 ReentrantLock 和两个 Condition（notEmpty 和 notFull）

## DelayQueue
使用一个 ReentrantLock 和一个 PriorityQueue

## 锁降级
遵循获取写锁、获取读锁在释放写锁的次序，写锁能够降级成为读锁

## 公平性
- 非公平锁：直接尝试获取锁
- 公平锁：先判断当前线程是否是等待队列的头，再尝试获取锁