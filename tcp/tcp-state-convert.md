## TCP 链接的状态转换

TCP的状态转换图:

![img](./resouces/tcp-state.png)


TCP 状态转换的两条主线:

对客户端(也可以是服务器, 客户端主动打开链接, 服务器被动打开):

```
CLOSED -> SYN_SENT -> ESTABLISHED -> FIN_WAIT_1 -> FIN_WAIT_2 -> TIME_WAIT -> CLOSED
```

> 注: 若客户端到达 FIN_WAIT_1, 它同时接收到服务器的FIN, ACK, 则它会直接跳过FIN_WAIT_2而到达
TIME_WAIT状态

对服务端:

```
CLOSED -> LISTEN -> SYN_RECEIVED -> ESTABLISHED -> CLOSE_WAIT -> LAST_ACK -> CLOSED
```

>注: 客户端和服务器端可能同时打开连接或同时关闭连接(很少), 这时处理稍微不大一样.


状态说明:

CLOSED - 初始状态, 表示 TCP 连接是"关闭着的"或"未打开的".

LISTEN - 表示服务器端的某个 SOCKET 处于监听状态, 可以接受客户端的连接.

SYN-SENT - 这个状态与 SYN_RCVD 状态相呼应, 当客户端 SOCKET 执行 connect() 进行连接时, 它首先发送 SYN 报文, 然后
随即进入到 SYN_SENT 状态, 并等待服务端的发送三次握手中的第 2 个报文. SYN_SENT 状态表示客户端已发送 SYN 报文.

SYN-RCVD - 表示接收到了 SYN 报文. 在正常情况下, 这个状态是服务器端的 SOCKET 在建立 TCP 连接时的三次握手会话过程中的
一个中间状态, 很短暂, 基本上用 netstat 很难看到这种状态(除非故意写一个监测程序, 将三次 TCP 握手过程中最后一个 ACK 报
文不予发送). 当 TCP 连接处于此状态时, 再收到客户端的 ACK 报文, 它就会进入到 ESTABLISHED 状态.

ESTABLISHED - 表示 TCP 连接已经成功建立, 数据可以传送给用户;


**FIN-WAIT-1** - 这个状态得好好解释一下, 其实 FIN_WAIT_1 和 FIN_WAIT_2 两种状态的真正含义都是表示等待对方的 FIN 
报文. 而这两种状态的区别是: FIN_WAIT_1 状态实际上是当 SOCKET 在 ESTABLISHED 状态时, 它想主动关闭连接, 向对方发送了 
FIN 报文, 此时该 SOCKET 进入到 FIN_WAIT_1 状态. 而当对方回应 ACK 报文后, 则进入到 FIN_WAIT_2 状态.
当然在实际的正常情况下, 无论对方处于任何种情况下, 都应该马上回应 ACK 报文, 所以 FIN_WAIT_1 状态一般是比较难见到的, 而 
FIN_WAIT_2 状态有时仍可以用 netstat 看到.


**FIN-WAIT-2** - 上面已经解释了这种状态的由来, 实际上 FIN_WAIT_2 状态下的 SOCKET 表示半连接, 即有一方调用close() 
主动要求关闭连接. 注意: FIN_WAIT_2 是没有超时的 (不像 TIME_WAIT 状态), 这种状态下如果对方不关闭(不配合完成 4 次挥手
过程), 那这个 FIN_WAIT_2 状态将一直保持到系统重启, 越来越多的 FIN_WAIT_2 状态会导致内核崩溃.


**CLOSE-WAIT** - 表示正在等待关闭. 当对方 close() 一个 SOCKET 后发送 FIN 报文给自己, 你的系统毫无疑问地将会回应一
个 ACK 报文给对方, 此时 TCP 连接则进入到 CLOSE_WAIT 状态. 接下来呢, 你需要检查自己是否还有数据要发送给对方, 如果没有
的话, 那你也就可以 close() 这个 SOCKET 并发送 FIN 报文给对方, 即关闭自己到对方这个方向的连接. 有数据的话则看程序的策
略, 继续发送或丢弃. 简单地说, 当你处于 CLOSE_WAIT 状态下, 需要完成的事情是等待你去关闭连接.


**CLOSING** - 这种状态在实际情况中应该很少见, 属于一种比较罕见的例外状态. 正常情况下, 当一方发送 FIN 报文后, 按理来说
是应该先收到(或同时收到)对方的 ACK 报文, 再收到对方的 FIN 报文. 但是 CLOSING 状态表示一方发送 FIN 报文后, 并没有收到
对方的 ACK 报文, 反而却也收到了对方的 FIN 报文. 什么情况下会出现此种情况呢? 那就是当双方几乎在同时 close() 一个 SOCKET 
的话, 就出现了双方同时发送 FIN 报文的情况, 这时就会出现 CLOSING 状态, 表示双方都正在关闭 SOCKET 连接.


**LAST-ACK** - 当被动关闭的一方在发送 FIN 报文后, 等待对方的 ACK 报文的时候, 就处于 LAST_ACK 状态. 当收到对方的 
ACK 报文后, 也就可以进入到 CLOSED 可用状态了.


**TIME-WAIT** - 等待足够的时间以确保远程 TCP 接收到连接中断请求的确认; 表示收到了对方的 FIN 报文, 并发送出了 ACK 报文.
TIME_WAIT 状态下的 TCP 连接会等待 2*MSL (Max Segment Lifetime, 最大分段生存期, 指一个 TCP 报文在 Internet 上的
最长生存时间. 每个具体的 TCP 协议实现都必须选择一个确定的 MSL 值, RFC 1122 建议是 2 分钟, 但 BSD 传统实现采用了 30 秒,
Linux 可以 cat /proc/sys/net/ipv4/tcp_fin_timeout 看到本机的这个值), 然后即可回到 CLOSED 可用状态了. 
如果 FIN_WAIT_1 状态下, 收到了对方同时带 FIN 标志和 ACK 标志的报文时, 可以直接进入到 TIME_WAIT 状态, 而无须经过 
FIN_WAIT_2 状态.



