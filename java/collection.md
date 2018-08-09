# 集合
## WeakHashMap
key 与 entry 均为弱引用，在 key 置为 null 之后，entry 放入 ReferenceQueue，在调用 get、put、remove 等方法时通过 ReferenceQueue 删除 table 中的 value，帮助 gc

## ConcurrentHashMap
### JDK 7
![](http://osbdeld5c.bkt.clouddn.com/18-3-31/15470637.jpg)

### JDK 8
![](http://osbdeld5c.bkt.clouddn.com/18-3-31/82473966.jpg)