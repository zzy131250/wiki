# Spring
## web 容器初始化
- web容器读取 web.xml 的 listener 和 context-param
- 容器创建 ServletContext ，它是 web 的上下文
- 将 context-param 节点值转化为键值对，传给 ServletContext
- 容器中创建 listener。listener 必须实现 ServletContextListener
- 容器加载 filter、servlet
- 调用 ServletContextListener 的 contextInitialized() 方法，其中包含 spring 容器的创建和初始化

## 容器启动过程图
![](http://osbdeld5c.bkt.clouddn.com/18-4-2/75402683.jpg)

## IOC 容器视图
![](http://osbdeld5c.bkt.clouddn.com/18-4-2/25341818.jpg)