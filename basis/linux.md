# Linux
## unlink
unlink 用于删除文件名，并不一定会删除文件内容。
只有在文件链接数为1，即当前文件名是文件的最后一个链接并且没有进程打开此文件的时候，unlink 才会真正删除文件内容；如果文件链接数为1，但仍有进程打开该文件，那么 unlink 只删除文件名，等到所有进程都关闭 fd 之后，系统才会删除文件内容。
对于符号链接，unlink 删除的是符号链接本身，而不是其指向的文件。
对于 socket、fifo 或者设备文件，unlink 删除了文件名，但是拥有该对象的进程仍能使用它。

## rm
rm = 权限检查 + unlink

## [rename](https://linux.die.net/man/3/rename)
如果目标文件名存在，目标文件名被删除时，文件链接数变为0，且没有进程打开文件，那么文件内容将被删除；而如果这时有进程打开文件，目标文件名会被删除，但文件内容会在所有进程关闭文件后删除。
### 可见性
> If the link named by the *new* argument exists, it shall be removed and *old* renamed to *new*. In this case, a link named *new* shall remain visible to other processes throughout the renaming operation and refer either to the file referred to by *new* or *old* before the operation began.

## mv
mv = 权限检查 + rename

## 文件系统 VFS
### 目录项
管理文件路径，存储目录下所有文件的 inode 和文件名等信息。比如一个路径 /home/foo/hello.txt，那么目录项有 home，foo，hello.txt。
### inode
管理一个具体的文件，是文件的唯一标志，一个文件对应一个 inode。通过 inode 可找到文件所在磁盘扇区，以及文件在 address_space 模块的缓存。
### 打开文件列表
包含内核已经打开的所有文件，列表中的文件对象也叫文件句柄，通过 open 系统调用生成。文件句柄包含一个打开文件的各种状态参数，其中维护的 f_dentry 指针指向了对应的目录项，f_op 指针指向对这个文件可以进行的操作函数集合 file_operations。
### address_space
表示一个文件在页缓存中已经缓存的物理页，是页缓存和外部设备文件的桥梁，关联了内存系统和文件系统。

## 进程、文件关系
![](https://zia-wiki.oss-cn-hangzhou.aliyuncs.com/20-2-29/65390054.jpg)

## 文件读写流程
### 读文件
1. 进程调用库函数向内核发起读文件请求
2. 内核通过检查进程的文件描述符定位到虚拟文件系统的打开文件列表表项
3. 调用该文件可用的系统调用函数 read()
4. read() 函数通过打开文件列表表项链接到目录项模块，根据传入的文件路径，在目录项模块中检索，找到该文件的inode
5. 在 inode 中，通过文件内容偏移量计算出要读取的页
6. 通过 inode 找到文件对应的 address_space
7. 在 address_space 中访问该文件的页缓存树，查找对应的页缓存结点
   - 如果页缓存命中，那么直接返回文件内容
   - 如果页缓存缺失，那么产生一个页缺失异常，创建一个页缓存页，同时通过 inode 找到文件该页的磁盘地址，读取相应的页填充该缓存页；重新进行第7步查找页缓存
8. 文件内容读取成功

### 写文件
前6步与读文件一致，找到 address_space。

7. 如果页缓存命中，直接把文件内容修改更新在页缓存的页中，写文件就结束了。这时候文件修改位于页缓存，并没有写回到磁盘文件中去
8. 如果页缓存缺失，那么产生一个页缺失异常，创建一个页缓存页，同时通过inode找到文件该页的磁盘地址，读取相应的页填充该缓存页。此时缓存页命中，进行第7步。
9. 一个页缓存中的页如果被修改，那么会被标记成脏页，脏页需要写回到磁盘中的文件块。同时注意，脏页不能被置换出内存，如果脏页正在被写回，那么会被设置写回标记，这时候该页就被上锁，其他写请求被阻塞直到锁释放。有两种方式可以把脏页写回磁盘：
   - 手动调用 sync() 或者 fsync() 系统调用把脏页写回
   - pdflush 进程会定时把脏页写回到磁盘

## 文件锁 flock vs fcntl
flock 和 fcntl 互不影响。

| 函数名 | flock | fcntl |
| ----- | ----- | ----- |
| 锁标志 | FL_FLOCK | FL_POSIX |
| 加锁位置 | 打开文件表项 | 打开文件表项，并标记进程？？？ |
| 锁类型 | 劝告锁 | 强制锁+劝告锁 |
| 解锁时机 | 显式调用任意一个关联 fd 的 LOCK_UN，或所有关联 fd 都已关闭 | 任一 fd 关闭，或进程退出 |
