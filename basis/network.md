# 计算机网络
## HTTP 1.1 新特性
- 断点续传：Content-Range
- 默认长连接：Keep-Alive

## HTTPS 通信过程
![](http://osbdeld5c.bkt.clouddn.com/18-4-4/94376821.jpg)

## OAuth 2.0 授权过程
![](http://osbdeld5c.bkt.clouddn.com/18-4-4/43825620.jpg)

## 跨域的方式
- 降域
- jsonp：利用 script 标签的 src 属性实现，将前端方法作为参数传递到服务器端，然后由服务器端注入参数之后再返回，实现服务器端向客户端通信
- CORS 跨域资源共享：浏览器发现 AJAX 请求跨源，就会自动添加一些附加的头信息，有时还会多出一次附加的请求，只要服务器实现了 CORS 接口，就可以跨源通信
- HTML5 postMessage