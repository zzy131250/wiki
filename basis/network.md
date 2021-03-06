# 计算机网络
## HTTP
### HTTP 状态码
- 1xx：信息，服务器收到请求，需要请求者继续执行操作
- 2xx：成功，操作被成功接收并处理
- 3xx：重定向，需要进一步的操作以完成请求
- 4xx：客户端错误，请求包含语法错误或无法完成请求
- 5xx：服务器错误，服务器在处理请求的过程中发生了错误

### HTTP 1.1 新特性
- 断点续传
  - 请求头：Range: bytes=0-499
  - 响应头：Content-Range: bytes 0-499/22400，并使用 HTTP/1.1 206 Partial Content
- 默认长连接：Connection: keep-alive

### HTTPS 通信过程
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/4710422.jpg)

## OAuth 2.0 授权过程
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/33675492.jpg)

## 跨域的方式
- jsonp：利用 script 标签的 src 属性实现，将前端方法作为参数传递到服务器端，然后由服务器端注入参数之后再返回，实现服务器端向客户端通信
- CORS 跨域资源共享：浏览器发现 AJAX 请求跨源，就会自动添加一些附加的头信息，有时还会多出一次附加的请求，只要服务器实现了 CORS 接口，就可以跨源通信

## TCP
### TCP/IP 握手过程
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/22850149.jpg)

### 多进程共享监听 Socket 的方式
1. 由 master 进程监听端口，并把请求派发给 worker 进程（子进程通过 fd 继承共享，获得 socket）
2. Linux 3.9 添加了 SO_REUSEPORT 的 socket 选项，支持同一用户的多个进程监听相同的 socket（这些进程都需要开启 SO_REUSEPORT 选项），同时，内核还会自动做负载均衡，见[StackOverflow](https://stackoverflow.com/questions/14388706/how-do-so-reuseaddr-and-so-reuseport-differ)。Nginx 1.9.1 的 Socket Sharding 特性在 Linux 上就是基于内核的 SO_REUSEPORT 实现的

## Nginx 负载均衡策略
- 加权轮询
- ip 哈希

## 正向代理 vs 反向代理
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/42325861.jpg)

## SSH
### 用户名密码登录
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/38206059.jpg)

### 公私钥登录
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/64365374.jpg)