# Linux工具
## ab
Apache Benchmark，进行压力测试的工具

## dig
DNS 查询命令
### dig +short
简化结果显示
### dig +trace
显示 DNS 分级查询过程
### dig 指定 DNS 记录类型
#### A
地址记录（Address），返回域名指向的 IP 地址
#### NS
域名服务器记录（Name Server），返回保存下一级域名信息的服务器地址。该记录只能设为域名，不能设为 IP 地址
#### MX
邮件记录（Mail eXchange），返回接收电子邮件的服务器地址
#### CNAME
规范名称记录（Canonical Name），返回另一个域名，即当前查询的域名是指向另一个域名的跳转
### PTR
逆向查询记录（Pointer Record），从 IP 地址查询域名

## traceroute
路由分析工具

## tcpdump
网络抓包工具

## bash 语法
### 变量内容的删除与替换
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-9/33519693.jpg)
### 变量测试与内容替换
![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-9/84104098.jpg)
