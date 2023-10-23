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

