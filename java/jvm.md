# JVM
## JVM 常用参数
| 参数名称 | 含义 | 默认值  |
| :----- | :----- | :----- |
| -Xms | 初始堆大小 | 物理内存的1/64(<1GB) |
| -Xmx | 最大堆大小 | 物理内存的1/4(<1GB) |
| -Xmn | 年轻代大小(>1.4) | |
| -XX:PermSize | 设置持久代(perm gen)初始值 | 物理内存的1/64 |
| -XX:NewRatio | 年轻代(包括Eden和Survivor)与年老代的比值(除持久代) | |
| -XX:SurvivorRatio | Eden区与Survivor区的大小比值 | |
| -Xss | 每个线程的堆栈大小 | |
| -XX:+UseConcMarkSweepGC | 使用CMS内存收集 | |
| -XX:MaxTenuringThreshold | 垃圾最大年龄 | |
| -Xnoclassgc | 禁用垃圾回收 | |
| -XX:+PrintGC | 显示gc信息 | |
| -XX:+PrintGCDetails | 显示详细gc信息 | |
| -XX:+PrintGCTimeStamps | 显示gc时间 | |
| -XX:+PrintHeapAtGC | 打印GC前后的详细堆栈信息 | |
| -XX:+UseCompressedOops | 指针压缩 | |

## JVM 性能监控工具
- jps：（JVM Process Status Tool，虚拟机进程监控工具），列出正在运行的虚拟机进程，并显示虚拟机执行主类名称，以及这些进程的本地虚拟机唯一ID
- jinfo：（Configuration Info for Java，配置信息工具），实时地查看和调整虚拟机各项参数
- jhat：（虚拟机堆转储快照分析工具），用来分析jmap dump出来的文件
- jmap：（Memory Map for Java，内存映像工具），用于生成堆转存的快照，一般是heapdump或者dump文件
- jstat：（JVM Statistics Monitoring Tool，虚拟机统计信息监视工具），用于监视虚拟机各种运行状态信息
- jstack：（Java Stack Trace，Java堆栈跟踪工具），用于查看虚拟机当前时刻的线程快照（一般是threaddump 或者 javacore文件）
- jconsole：一个java GUI监视工具，可以以图表化的形式显示各种数据。并可通过远程连接监视远程的服务器VM

## 内存屏障
- LoadLoad屏障：对于这样的语句Load1; LoadLoad; Load2，在Load2及后续读取操作要读取的数据被访问前，保证Load1要读取的数据被读取完毕
- StoreStore屏障：对于这样的语句Store1; StoreStore; Store2，在Store2及后续写入操作执行前，保证Store1的写入操作对其它处理器可见
- LoadStore屏障：对于这样的语句Load1; LoadStore; Store2，在Store2及后续写入操作被刷出前，保证Load1要读取的数据被读取完毕
- StoreLoad屏障：对于这样的语句Store1; StoreLoad; Load2，在Load2及后续所有读取操作执行前，保证Store1的写入对所有处理器可见。它的开销是四种屏障中最大的。在大多数处理器的实现中，这个屏障是个万能屏障，兼具其它三种内存屏障的功能