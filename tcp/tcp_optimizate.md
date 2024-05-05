# TCP 优化

## 三次握手

服务端:

当服务端收到 SYN 包后, 服务端会立马回复 SYN+ACK 包, 表明确认收到客户端的序列号, 同时将自己的序列号发给对方.

此时, 服务端出现了新连接, 状态是 `SYN_RCV`. 在这个状态下, **Linux 内核就会建立一个 "半连接队列" 来维护 "未完成" 的
握手信息, 当半连接队列溢出后, 服务端就无法再建立新的连接**.

![image](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost/计算机网络/TCP-参数/9.jpg)

SYN 攻击, 攻击的就是这个半连接队列.

> 查看由于 SYN 半连接队列已满, 而被丢弃连接的情况?
> `netstat -s` 当中在 Tcp 当中出现了 `SYNs to LISTEN`, 并且持续增长, 说明当前存在半连接队列溢出的现场.


> 调整 SYN 半连接队列大小?

增加半连接队列, 就要同时去调整 `net.ipv4.tcp_max_syn_backlog` 和 `net.core.somaxconn`, Listen 时 `backlog`
(也就是 accept 队列) 的值. 修改完上述的参数后, 需要重启服务.

> 如果 SYN 半连接队列已满, 只能丢弃连接吗?

首先答案是未必. **在开启 syccookies (参数 `net.ipv4.tcp_syncookies` ) 功能状况下, 就可以使用 SYN 半连接队列的情况下成功建立连接**

syccookies 原理: 在服务器收到 SYN 包并返回 SYN+ACK 包时, 不分配一个专门的数据区, 而是根据这个 SYN 包计算出一个
cookie 值. 这个 cookie 作为将要返回的 SYN+ACK 包的初始序列号. 在收到 ACK 包时, TCP服务器在根据那个 cookie 值
检查这个ACK包的合法性. 如果合法, 再分配专门的数据区进行处理未来的TCP连接.

syncookies 参数三个值:
- 0 表示关闭该功能
- 1 表示当 SYN 半连接队列放不下时, 再启用它
- 2 表示无条件开启功能

## TCP 相关的内核配置参数

// 内存映射
```
net.ipv4.tcp_mem = 34809    46415    69618

确定 TCP 栈应该如何反映内存使用, 每个值的单位都是内存页(通常是4kb). 
第一个值是内存使用的下限; 
第二个值是内存压力模式开始对缓冲区使用应用压力的上限; 
第三个值是内存使用的上限; 在这个层次上可以将报文丢弃, 从而减少对内存的使用.
```

// socket 发送缓冲区 
```
net.ipv4.tcp_wmem = 4096    16384    4194304

为自动调优定义socket使用的内存. 
第一个值是为socket发送缓冲区分配的最少字节数; 
第二个值是默认值(该值会被wmem_default覆盖), 缓冲区在系统负载不重的情况下可以增长到这个值; 
第三个值是发送缓冲区空间的最大字节数(该值会被wmem_max覆盖)

net.core.wmem_default = 212992
net.core.wmem_max = 212992

socket发送缓冲区默认和最大大小.
```

// socket 接收缓冲区
```
net.ipv4.tcp_rmem = 4096    87380    6291456

为自动调优定义socket使用的内存. 
第一个值是为socket接收缓冲区分配的最少字节数; 
第二个值是默认值(该值会被rmem_default覆盖), 缓冲区在系统负载不重的情况下可以增长到这个值; 
第三个值是接收缓冲区空间的最大字节数(该值会被rmem_max覆盖)

net.core.rmem_default = 212992
net.core.rmem_max = 212992

socket发送缓冲区默认和最大大小.
```
